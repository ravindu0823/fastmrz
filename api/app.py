# api/app.py
import io
import base64
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from fastmrz.fastmrz import FastMRZ

app = FastAPI(title="FastMRZ Service", version="1.0.0")

# CORS (tighten in prod)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # change to your Next.js origin(s) in prod
    allow_credentials=True,
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)

# Load once on startup (model + tessdata)
mrz_engine = FastMRZ()  # uses fastmrz/model/mrz_seg.onnx & tessdata/mrz.traineddata

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.get("/readyz")
def readyz():
    # If you later add async warmup checks, report readiness here
    return {"ready": True}

@app.post("/api/mrz")
async def extract_mrz(
    file: Optional[UploadFile] = File(None, description="JPEG/PNG image"),
    base64_image: Optional[str] = Form(None, description="Base64-encoded image"),
    mrz_text: Optional[str] = Form(None, description="Raw MRZ text"),
    include_checkdigit: bool = Form(True),
    ignore_parse: bool = Form(False),
):
    """
    Accepts one of:
    - file (multipart)
    - base64_image (form field)
    - mrz_text (form field)  -> parsed/validated only
    """
    try:
        if file:
            content = await file.read()
            b64 = base64.b64encode(content).decode("utf-8")
            result = mrz_engine.get_details(b64, input_type="base64",
                                            ignore_parse=ignore_parse,
                                            include_checkdigit=include_checkdigit)
            return JSONResponse(result if not ignore_parse else {"mrz_text": result})

        if base64_image:
            result = mrz_engine.get_details(base64_image, input_type="base64",
                                            ignore_parse=ignore_parse,
                                            include_checkdigit=include_checkdigit)
            return JSONResponse(result if not ignore_parse else {"mrz_text": result})

        if mrz_text:
            result = mrz_engine.get_details(mrz_text, input_type="text",
                                            ignore_parse=ignore_parse,
                                            include_checkdigit=include_checkdigit)
            return JSONResponse(result if not ignore_parse else {"mrz_text": result})

        raise HTTPException(status_code=400, detail="Provide 'file' or 'base64_image' or 'mrz_text'")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))