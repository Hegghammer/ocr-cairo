## -----------------------
#| label: diag-tess1
install.packages("tidyverse")
library(tesseract)
library(xml2)
library(tidyverse)
library(magick)

# Setup
engine <- tesseract("ara")
dir <- "example_docs/columns/orig"
files <- list.files(dir, full.names = TRUE)
infile <- files[1]

# OCR
xml <- ocr(infile, engine, HOCR = TRUE)

# Function to get coordinates and build dataframe
extract_boxes <- function(xml) {
  doc <- read_xml(xml)
  element_types <- list(
    page = "div[@class='ocr_page']",
    carea = "div[@class='ocr_carea']",
    paragraph = "p[@class='ocr_par']",
    line = "span[@class='ocr_line']",
    word = "span[@class='ocrx_word']"
  )
  map_dfr(names(element_types), \(type) {
    nodes <- xml_find_all(doc, paste0(".//", element_types[[type]]))
    tibble(type = type, id = xml_attr(nodes, "id"), title = xml_attr(nodes, "title"), text = xml_text(nodes)) |>
      mutate(bbox = str_extract(title, "bbox [0-9 ]+")) |>
      separate(bbox, into = c("junk", "x1", "y1", "x2", "y2"), sep = " ", convert = TRUE) |>
      select(-junk)
  })
}
# Create dataframe
block_data <- extract_boxes(xml):::

::: {.column width='50%'}

## -----------------------
#| label: diag-tess2
# Function to draw boxes
draw_boxes <- function(infile, data, elem_type, colour, outfile) {
  img <- image_read(infile) |> image_draw()
  boxes <- data |> filter(type == elem_type)
  for (i in 1:nrow(boxes)) {
    box <- boxes[i, ]
    rect(box$x1, box$y1, box$x2, box$y2, border = colour, lwd = 2)
    text(x = box$x2, y = box$y1, labels = i, col = "red", cex = 1)
  }
  dev.off()
  image_write(img, outfile)
}

draw_boxes(infile, block_data, "word", "darkgreen", "words.png")


## -----------------------
#| label: diag-dai
library(daiR)
dir <- "example_docs/columns/orig"
files <- list.files(dir, full.names = TRUE)
infile <- files[1]

# Process
resp <- dai_sync(infile, proc_v = "rc")

# Draw up
draw_blocks(resp, fontsize = 2)
draw_tokens(resp, linewd = 1, fontsize = 1)


## -----------------------
#| label: math
df_words <- block_data |> filter(type == "word")

# Method 1: Manual cutoff point
cutoff_x <- 300
left_column <- df_words |> filter(x1 < cutoff_x)
right_column <- df_words |> filter(x1 >= cutoff_x)

# Method 2: Automatic cutoff using median
cutoff_x <- median(word_boxes$x1)
left_column <- df_words |> filter(x1 < cutoff_x)
right_column <- df_words |> filter(x1 >= cutoff_x)

# Method 3: Find natural gap (most robust for two-column layouts)
find_cutoff <- function(df) {
  # Sort x1 values and find largest gap
  x_sorted <- sort(df$x1)
  gaps <- diff(x_sorted)
  max_gap_idx <- which.max(gaps)
  cutoff <- (x_sorted[max_gap_idx] + x_sorted[max_gap_idx + 1]) / 2
  return(cutoff)
}

cutoff_x <- find_cutoff(word_boxes)

left_text <- paste(left_column$text, collapse = " ")


## -----------------------
#| label: run
python3.11 heron_parse.py --input ocr-cairo/example_docs/columns/orig/001.png --outdir heron_out


## -----------------------
#| label: cut
import json
from PIL import Image
from pathlib import Path

# input files
json_file = "heron_out/001_boxes_001.json"
image_file = "ocr-cairo/example_docs/columns/orig/001.png"

# load json
with open(json_file, "r") as f:
    data = json.load(f)

# open image
img = Image.open(image_file)

outdir = "cutouts"
base_name = Path(image_file).stem

# loop through boxes
for i, box in enumerate(data["boxes"], start=1):
    x_min, y_min, x_max, y_max = box
    cropped = img.crop((x_min, y_min, x_max, y_max))
    out_filename = f"{outdir}/{base_name}_box_{i:02d}.png"
    cropped.save(out_filename)
    print(f"Saved {out_filename}")


## # pip install scikit-learn
## import json
## import numpy as np
## from sklearn.cluster import KMeans
## 
## def reorder_boxes(data, num_columns=2):
##     boxes = data["boxes"]
##     labels = data["labels"]
##     scores = data["scores"]
##     # Build structured list
##     items = []
##     for i, box in enumerate(boxes):
##         x1, y1, x2, y2 = box
##         cx = (x1 + x2) / 2
##         cy = (y1 + y2) / 2
##         items.append({
##             "id": i,
##             "box": box,
##             "label": labels[i],
##             "score": scores[i],
##             "cx": cx,
##             "cy": cy,
##         })
##     # Cluster x-centers into `num_columns`
##     X = np.array([[it["cx"]] for it in items])
##     kmeans = KMeans(n_clusters=num_columns, random_state=0, n_init="auto").fit(X)
##     col_assignments = kmeans.labels_
##     # Store column assignment
##     for item, col in zip(items, col_assignments):
##         item["col"] = col
##     # Sort columns left-to-right based on cluster centers
##     col_order = np.argsort(kmeans.cluster_centers_.ravel())
##     col_mapping = {old: new for new, old in enumerate(col_order)}
## 
##     for item in items:
##         item["col"] = col_mapping[item["col"]]
## 
##     # Sort inside each column top-to-bottom
##     ordered = []
##     for col in range(num_columns):
##         col_items = sorted(
##             [it for it in items if it["col"] == col],
##             key=lambda it: it["cy"]
##         )
##         ordered.extend(col_items)
## 
##     return ordered

## -----------------------
#| label: order2
json_file = "heron_out/001_boxes_001.json"

with open(json_file) as f:
    data = json.load(f)

ordered = reorder_boxes(data, num_columns=2)


## import os
## import glob
## 
## # Example: folder with cutout images
## cutout_folder = "cutouts"
## page_prefix = "001" # adjust depending on original filename
## 
## # Make a lookup for all files
## all_files = glob.glob(os.path.join(cutout_folder, f"{page_prefix}_box_*.png"))
## 
## # Build mapping from index to filename
## index_to_file = {}
## for f in all_files:
##     idx_str = os.path.splitext(f)[0].split("_box_")[-1]
##     idx = int(idx_str)  # convert '01' → 1
##     index_to_file[idx] = f
## 
## # Build ordered list, skip if file not found
## ordered_files = []
## for item in ordered:
##     idx = item["id"]
##     if idx in index_to_file:
##         ordered_files.append(index_to_file[idx])
##     else:
##         print(f"⚠️ Warning: no cutout file for index {idx}")
## 
## # Check
## ordered_files[:10]
