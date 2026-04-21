# Circle Tiler (FastAPI, SSR)

A tiny FastAPI web app that lets you easily generate print-ready A4 sticker sheets from your images.

## Features

- **Upload & Crop:** Upload any image and crop a 1:1 **circle** directly in your browser.
- **Client-Side Processing:** Cropping is handled efficiently client-side using an HTML canvas.
- **Custom Sizing:** Choose the exact **circle diameter (mm)** for your stickers.
- **PDF Generation:** The server receives a transparent PNG of your crop and tiles it on an A4 page using ReportLab, ensuring accurate physical dimensions.
- **Print to Scale:** The generated PDF is perfectly scaled to your requested diameter, making it easy to print exact-size circular stickers.

## Requirements

- Python 3.8+
- `fastapi`
- `uvicorn`
- `jinja2`
- `pillow`
- `reportlab`
- `python-multipart`

## Quick Start

1. **Clone the repository** (if you haven't already).
2. **Set up a virtual environment**:
   ```bash
   python -m venv .venv
   source .venv/bin/activate   # On Windows use: .venv\Scripts\activate
   ```
3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```
4. **Run the application**:
   ```bash
   uvicorn app.main:app --reload
   ```
5. **Access the web app**:
   Open http://127.0.0.1:8000 in your browser.

## Deployment

A deployment script (`deploy.sh`) is provided for deploying the app to a remote server.
It uses `rsync` to sync files and restarts a systemd service.

```bash
./deploy.sh <service-name> [host]
```

To run the app directly, you can also use `run.sh` which handles virtual environment creation, dependency installation, and starts the server.

```bash
./run.sh <service-name>
```

## Project Structure

- `app/main.py`: The main FastAPI application logic, including the PDF generation endpoint.
- `app/templates/index.html`: The frontend UI with the client-side cropper.
- `app/static/`: Directory for static assets (CSS, JS, etc.).
- `deploy.sh`: Script to deploy the application to a remote server.
- `run.sh`: Script to run the application (creates venv, installs requirements, starts uvicorn).
- `requirements.txt`: Python dependencies.

## Technical Details

- **A4 Sizing:** A4 is 210 × 297 mm. We use 72 points per inch for PDF sizing (1 in = 25.4 mm).
- **Quality:** For best print quality, use high-resolution source images.
