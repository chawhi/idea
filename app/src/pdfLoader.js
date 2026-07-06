import * as pdfjsLib from "../vendor/pdfjs/pdf.min.mjs";

pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
  "../vendor/pdfjs/pdf.worker.min.mjs",
  import.meta.url,
).href;

const MAX_DIMENSION = 1600;

function loadImageElement(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = src;
  });
}

function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

/** Renders every page of a PDF file to a JPEG image capped at MAX_DIMENSION. */
export async function pdfFileToImages(file) {
  const buffer = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: buffer }).promise;
  const images = [];
  for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
    const page = await pdf.getPage(pageNum);
    const baseViewport = page.getViewport({ scale: 1 });
    const scale = Math.min(
      2,
      MAX_DIMENSION / Math.max(baseViewport.width, baseViewport.height),
    );
    const viewport = page.getViewport({ scale });
    const canvas = document.createElement("canvas");
    canvas.width = Math.ceil(viewport.width);
    canvas.height = Math.ceil(viewport.height);
    const ctx = canvas.getContext("2d");
    await page.render({ canvasContext: ctx, viewport }).promise;
    images.push({
      src: canvas.toDataURL("image/jpeg", 0.9),
      width: canvas.width,
      height: canvas.height,
    });
  }
  return images;
}

/** Loads a raster image file, downscaling it to MAX_DIMENSION if needed. */
export async function imageFileToImage(file) {
  const dataUrl = await readFileAsDataUrl(file);
  const img = await loadImageElement(dataUrl);
  const scale = Math.min(1, MAX_DIMENSION / Math.max(img.width, img.height));

  if (scale >= 1) {
    return { src: dataUrl, width: img.naturalWidth, height: img.naturalHeight };
  }

  const canvas = document.createElement("canvas");
  canvas.width = Math.round(img.width * scale);
  canvas.height = Math.round(img.height * scale);
  const ctx = canvas.getContext("2d");
  ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
  return {
    src: canvas.toDataURL("image/jpeg", 0.9),
    width: canvas.width,
    height: canvas.height,
  };
}
