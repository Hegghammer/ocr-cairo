
#!/usr/bin/env python3
"""
layout_parser.py

Detects layout elements (e.g., paragraphs, titles, tables) in PDFs or images
using the DocLING layout RT-DETR model from Hugging Face.

🔧 Features:
- Automatically converts PDFs to images using pdftoppm.
- Uses Hugging Face RT-DETR with preprocessor + model config.
- Draws predicted bounding boxes:
  - Red box outline
  - Green label (top-left)
  - Blue index number (top-right)
- Supports JSON export with bounding boxes, scores, and labels.

📦 Requirements:
- Python 3.8–3.11 (⚠️ Python 3.13 may cause compatibility issues)

To install in GH codespace:
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-distutils
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
python3.11 -m pip install transformers huggingface_hub pillow opencv-python
python3.11 -m pip install torch --index-url https://download.pytorch.org/whl/cpu

🧪 Example usage:
python heron_parse.py --input file.pdf --outdir outdir
python heron_parse.py --input image.png --outdir outdir

"""
import os
import json
import argparse
import subprocess
import tempfile
from pathlib import Path
from typing import Iterator

import torch
import numpy as np
import cv2
from PIL import Image
from transformers import RTDetrImageProcessor, RTDetrV2ForObjectDetection


# === Load processor and model ===
model_name = "ds4sd/docling-layout-heron"
processor = RTDetrImageProcessor.from_pretrained(model_name)
model = RTDetrV2ForObjectDetection.from_pretrained(model_name)
width = processor.size["width"]
height = processor.size["height"]
threshold = 0.6

# === Use explicit class map ===
classes_map = {
    0: "Caption",
    1: "Footnote",
    2: "Formula",
    3: "List-item",
    4: "Page-footer",
    5: "Page-header",
    6: "Picture",
    7: "Section-header",
    8: "Table",
    9: "Text",
    10: "Title",
    11: "Document Index",
    12: "Code",
    13: "Checkbox-Selected",
    14: "Checkbox-Unselected",
    15: "Form",
    16: "Key-Value Region",
}


def popple(path: Path, width: int, height: int) -> Iterator[Image.Image]:
    """Convert PDF pages to PIL images using pdftoppm."""
    with tempfile.TemporaryDirectory() as tempdir:
        out_base = Path(tempdir) / "page"
        subprocess.run(
            ["pdftoppm", "-png", "-scale-to-x", str(width), "-scale-to-y", "-1", str(path), str(out_base)],
            check=True
        )
        for img in sorted(Path(tempdir).glob("*.png")):
            yield Image.open(img).convert("RGB")


def parse_layout(input_path: Path, outdir: Path,
                 save_images: bool = True, save_json: bool = True):
    input_path = Path(input_path)
    outdir.mkdir(parents=True, exist_ok=True)
    basename = input_path.stem

    if input_path.suffix.lower() == ".pdf":
        images = list(popple(input_path, width, height))
    else:
        images = [Image.open(input_path).convert("RGB")]

    with torch.inference_mode():
        for i, img in enumerate(images, 1):
            # Resize only for inference
            resized = img.resize((width, height))
            inputs = processor(images=resized, return_tensors="pt")
            outputs = model(**inputs)

            results = processor.post_process_object_detection(
                outputs, target_sizes=[(img.height, img.width)], threshold=threshold
            )[0]

            # Convert original image to OpenCV format
            cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
            json_output = {"boxes": [], "labels": [], "scores": []}

            for idx, (label_tensor, box, score) in enumerate(zip(results["labels"], results["boxes"], results["scores"])):
                label_id = label_tensor.item()
                label_text = classes_map.get(label_id, f"Unknown_{label_id}")
                x1, y1, x2, y2 = map(int, box.tolist())

                # Draw on image
                cv2.rectangle(cv_img, (x1, y1), (x2, y2), (0, 0, 255), 2)
                cv2.putText(cv_img, label_text, (x1, y1 - 5),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 100, 0), 2)
                cv2.putText(cv_img, str(idx), (x2, y1),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 0, 0), 2)

                json_output["boxes"].append([x1, y1, x2, y2])
                json_output["labels"].append(label_text)
                json_output["scores"].append(float(score))

            base_name = f"{basename}_boxes_{i:03}"
            if save_images:
                cv2.imwrite(str(outdir / f"{base_name}.png"), cv_img)
                print(f"✅ Saved image: {outdir / f'{base_name}.png'}")
            if save_json:
                with open(outdir / f"{base_name}.json", "w") as f:
                    json.dump(json_output, f, indent=2)
                print(f"✅ Saved JSON: {outdir / f'{base_name}.json'}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", "-i", type=Path, required=True, help="PDF or image file")
    parser.add_argument("--outdir", "-o", type=Path, default=Path("output"), help="Where to save outputs")
    parser.add_argument("--no-save-images", action="store_false", dest="save_images", help="Skip PNG saving")
    parser.add_argument("--no-save-json", action="store_false", dest="save_json", help="Skip JSON saving")
    args = parser.parse_args()

    parse_layout(args.input, args.outdir, save_images=args.save_images, save_json=args.save_json)


if __name__ == "__main__":
    main()
