## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tess-r

# Set up tesseract
install.packages(tesseract)
library(tesseract)
engine <- tesseract("ara")

# Process
infile <- "example_docs/plain/orig/001.jpg"
text <- ocr(infile, engine)
write(text, "tess_out_plain.txt")

# Evaluate
## WER
command <- "jiwer -g -r example_docs/plain/gt/001.txt -h tess_out_plain.txt"
as.numeric(system(command, intern = TRUE))

# CER
command <- "jiwer -g -c -r example_docs/plain/gt/001.txt -h tess_out_plain.txt"
as.numeric(system(command, intern = TRUE))


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tess-r1
# Store image paths in vectors
plain <- list.files("example_docs/plain/orig",
  full.names = TRUE
)

# Create variable for output dir to create
tess_plaindir <- "tesseract/out/plain"

# Create it
dir.create(tess_plaindir, recursive = TRUE)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tess-r2
library(stringr)

# Create function
ocr_tess <- function(input, output) {
  text <- ocr(input, engine)
  write(text, output)
}

# Loop over vector
for (i in seq_along(plain)) {
  inpath <- plain[i]
  outfile <- str_replace(
    basename(inpath), "jpg", "txt"
    )
  outpath <- file.path(tess_plaindir, outfile)
  ocr_tess(inpath, outpath)
}
# Now check "tesseract/out/plain" directory


## # pip install pytesseract pillow
## import pytesseract
## from PIL import Image
## 
## # Load the image
## infile = "example_docs/plain/orig/001.jpg"
## image = Image.open(infile)
## 
## # Process
## text = pytesseract.image_to_string(image, lang='ara')
## 
## # Write to file
## with open("tess_out_plain.txt", "w", encoding="utf-8") as f:
##     f.write(text)

## # Store image paths in list
## plain = glob.glob("example_docs/plain/orig/*")
## 
## # Create variable for output dir to create
## tess_plaindir = "tesseract/out/plain"
## 
## # Create it
## os.makedirs(tess_plaindir, exist_ok=True)
## 
## # Create function
## def ocr_tess(input_path, output_path):
##     image = Image.open(input_path)
##     text = pytesseract.image_to_string(image, lang='ara')
##     with open(output_path, "w", encoding="utf-8") as f:
##         f.write(text)
## 
## # Loop over list
## for i, inpath in enumerate(plain):
##     outfile = os.path.basename(inpath).replace(".jpg", ".txt")
##     outpath = os.path.join(tess_plaindir, outfile)
##     ocr_tess(inpath, outpath)

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: kraken
library(stringr)
infile <- "example_docs/plain/orig/001.jpg"
outfile <- "kraken_out_plain.txt"
command <- str_glue("kraken -i '{infile}' '{outfile}' binarize segment -bl ocr -m arabic_best.mlmodel")
system(command, intern = TRUE)
# Slow without GPU

# Evaluate
## WER
command <- "jiwer -g -r example_docs/plain/gt/001.txt -h kraken_out_plain.txt"
as.numeric(system(command, intern = TRUE))

# CER
command <- "jiwer -g -c -r example_docs/plain/gt/001.txt -h kraken_out_plain.txt"
as.numeric(system(command, intern = TRUE))



## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: kraken-python
import subprocess

infile = "example_docs/plain/orig/001.jpg"
outfile = "kraken_out_plain.txt"

command = [
    "kraken",
    "-i", infile, outfile,
    "binarize", "segment", "-bl", "ocr",
    "-m", "arabic_best.mlmodel"
]

# Run and capture stdout
result = subprocess.run(command, capture_output=True, text=True)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: surya-r
library(stringr)
infile <- "example_docs/plain/orig/001.jpg"
command <- str_glue("surya_ocr {infile}")
system(command, intern = TRUE)


## import subprocess
## 
## infile = "example_docs/plain/orig/001.jpg"
## command = ["surya_ocr", infile]
## result = subprocess.run(command, capture_output=True, text=True)

## # pip install python-dotenv
## import os
## from dotenv import load_dotenv
## load_dotenv(dotenv_path="/home/thomas/.Renviron")
## # To store specific env vars in objects:
## api_key = os.getenv("MISTRAL_API_KEY")

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: dair
install.packages(daiR)
library(daiR)

infile <- "example_docs/plain/orig/001.jpg"
outfile <- "dai_out.txt"
resp <- dai_sync(infile, proc_v = "rc")
text <- get_text(resp)
write(text, outfile)


## # pip install google-cloud-documentai
## 
## from google.cloud import documentai_v1 as documentai
## 
## os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = PATH_TO_KEYFILE
## project_id = YOUR_PROJECT
## location = YOUR_REGION
## processor_id = YOUR_PROCESSOR_ID
## 
## def process_dai(
##     project_id: str,
##     location: str,
##     processor_id: str,
##     file_path: str,
##     mime_type: str = "application/pdf",
## ):
##     client_options = {"api_endpoint": f"{location}-documentai.googleapis.com"}
##     client = documentai.DocumentProcessorServiceClient(client_options=client_options)
##     name = client.processor_path(project_id, location, processor_id)
## 
##     # Read file into memory
##     with open(file_path, "rb") as f:
##         file_content = f.read()
##     raw_document = documentai.RawDocument(content=file_content, mime_type=mime_type)
##     request = documentai.ProcessRequest(name=name, raw_document=raw_document)
##     result = client.process_document(request=request)
##     document = result.document
##     return document
## 
## infile = "example_docs/plain/orig/001.jpg"
## outfile = "dai_python_out.txt"
## 
## doc = process_document_sample(project_id, location, processor_id, file_path = infile)
## 
## with open(outfile, "w") as f:
##     f.write(doc.text)

## import base64
## import os
## import glob
## from mistralai import Mistral
## from dotenv import load_dotenv
## load_dotenv(dotenv_path="/home/vscode/.Renviron")
## 
## def encode_image(image_path):
##     with open(image_path, "rb") as image_file:
##         return base64.b64encode(image_file.read()).decode('utf-8')
## 
## infile = "example_docs/plain/orig/001.jpg"
## 
## # Getting the base64 string
## base64_image = encode_image(infile)
## 
## api_key = os.environ["MISTRAL_API_KEY"]
## client = Mistral(api_key=api_key)
## 
## response = client.ocr.process(
##     model="mistral-ocr-latest",
##     document={
##         "type": "image_url",
##         "image_url": f"data:image/jpeg;base64,{base64_image}"
##     },
##     include_image_base64=True
## )
## 
## text = response.page[0].markdown

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: post-r
library(ellmer)
library(tidyverse)

# Activate
mistral <- chat_mistral()
# uses mistral-large by default

# Get text from files
preprocess_prompt <- read_file("postprocess_prompt.md")
text_to_clean <- read_file("tesseract_out.txt")

# Build prompt
prompt <- paste(preprocess_prompt, text_to_clean)

# Make call
cleaned_text <- mistral$chat(prompt)

# Save
write(cleaned_text, "tesseract_out_cleaned.txt")


## import os
## from mistralai import Mistral
## from dotenv import load_dotenv
## load_dotenv(dotenv_path="/home/vscode/.Renviron")
## 
## api_key = os.getenv("MISTRAL_API_KEY")  # or put it here as string
## model = "mistral-large-latest"
## 
## # Activate client
## client = Mistral(api_key=api_key)
## 
## # Get text from files
## with open("postprocess_prompt.md", "r", encoding="utf-8") as f:
##     preprocess_prompt = f.read()
## with open("tesseract_out.txt", "r", encoding="utf-8") as f:
##     text_to_clean = f.read()
## 
## # Build prompt
## prompt = preprocess_prompt + text_to_clean
## 
## # Make call
## response = client.chat.complete(
##     model=model,
##     messages=[{"role": "user", "content": prompt}]
## )
## 
## text = response.choices[0].message.content
