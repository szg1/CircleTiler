# Circle Tiler (FastAPI, SSR)

A tiny FastAPI web app that lets you:
1) Upload an image
2) Crop a 1:1 **circle** from it (client-side in the browser)
3) Choose the **circle diameter (mm)**
4) Generate an **A4 PDF** tiled with your circular stickers

## Quick start

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open http://127.0.0.1:8000 in your browser.

## Notes

- Cropping is done **client-side** with an HTML canvas.
- The server receives a transparent PNG of your circular crop and tiles it on an A4 page using ReportLab.
- A4 is 210 × 297 mm. We use 72 points per inch for PDF sizing (1 in = 25.4 mm).
- The image is scaled to your requested diameter in **mm**, so you can print to scale.
- For best print quality, use high-resolution source images.
