from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas as pdfcanvas
from reportlab.lib.utils import ImageReader
from io import BytesIO
import base64

app = FastAPI()

app.mount("/static", StaticFiles(directory="app/static"), name="static")
templates = Jinja2Templates(directory="app/templates")

def mm_to_pt(mm: float) -> float:
    # 1 inch = 25.4 mm; 1 inch = 72 pt
    return mm * 72.0 / 25.4

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/generate", response_class=HTMLResponse)
async def generate(
    request: Request,
    image_data: str = Form(...),
    diameter_mm: float = Form(...)
):
    # image_data is a data URL like: "data:image/png;base64,......"
    if "," in image_data:
        image_data = image_data.split(",", 1)[1]
    try:
        raw = base64.b64decode(image_data)
    except Exception:
        return templates.TemplateResponse(
            "index.html",
            {"request": request, "error": "Could not decode image data. Try again."},
            status_code=400,
        )

    # Prepare PDF in memory
    buf = BytesIO()
    page_w, page_h = A4
    diameter_pt = mm_to_pt(diameter_mm)
    if diameter_pt <= 0:
        return templates.TemplateResponse(
            "index.html",
            {"request": request, "error": "Diameter must be greater than 0."},
            status_code=400,
        )

    # Build PDF
    pdf = pdfcanvas.Canvas(buf, pagesize=A4)

    # Use the PNG (already circular with transparent corners) and let transparency pass through
    img_reader = ImageReader(BytesIO(raw))

    import math
    cols = max(1, int(page_w // diameter_pt))
    rows = max(1, int(page_h // diameter_pt))

    # Center the grid
    total_w = cols * diameter_pt
    total_h = rows * diameter_pt
    margin_x = (page_w - total_w) / 2.0
    margin_y = (page_h - total_h) / 2.0

    # Tile images
    # ReportLab coordinates: origin (0,0) is bottom-left
    for r in range(rows):
        for c in range(cols):
            x = margin_x + c * diameter_pt
            y = margin_y + r * diameter_pt
            pdf.drawImage(img_reader, x, y, width=diameter_pt, height=diameter_pt, mask='auto')

    pdf.showPage()
    pdf.save()
    buf.seek(0)

    headers = {
        "Content-Disposition": 'attachment; filename="stickers_A4.pdf"'
    }
    return StreamingResponse(buf, media_type="application/pdf", headers=headers)
