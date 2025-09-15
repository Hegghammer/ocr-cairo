## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: r-objects
# Create scalar
my_text <- "Here is some text"

# Create vectors
texts <- c("Some text", 
           "Some more text", 
           "Even more"
           )
n_words <- c(2, 3, 2)

# Create dataframe
df <- data.frame(texts, n_words)

# Access second element of vector
texts[2]

# Access third row in n_words column
texts$n_words[3]


# Create object
my_text = "Here is some text"

# Create lists
texts = ["Some text", "Some more text", "Even more"]
n_words = [2, 3, 2]

# Create dataframe
import pandas as pd
df = pd.DataFrame({
    "Text": texts,
    "Length": n_words
})

# Access second element of list
texts[1]

# Access third row in Length column
df["Length"].iloc[2]

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: r-files

# Create a directory and some files
dir.create("test")
file.create(c("test/notes1.txt", "test/notes2.txt"))

# Get content
contents <- list.files("test")

# Get full paths of content
contents_full <- list.files("test", full.names = TRUE)

# NB: Output of list.files is vector of paths, 
# not files themselves


## import os
## 
## # Create a directory and some files
## os.makedirs("test", exist_ok=True)
## open("test/notes1.txt", "w").close()
## open("test/notes2.txt", "w").close()
## 
## # Get content
## contents = os.listdir("test")
## 
## # Get full paths
## import glob
## contents_full = glob.glob("test/*")
## 
## # Move file
## import shutil
## shutil.move("test/notes1.txt", ".")

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: r-iteration
# Basic loop
for (i in texts) {
  print(i)
}

# Loop over indices
for (i in seq_along(texts)) {
  print(texts[i])
}

# Indices let you do more things
for (i in seq_along(texts)) {
  message("Processing text", i, " of ", length(texts))
  new_name <- paste0("text_", i)
  write(texts[i], new_name)
}



## # Basic loop
## for t in texts:
##     print(t)
## 
## # Loop over indices
## for i in range(len(texts)):
##     print(texts[i])
## 
## # Indices let us do more things
## for i, t in enumerate(texts):
##     print(f"Processing text {i+1} of {len(texts)}")
##     new_name = f"text_{i}.txt"
##     with open(new_name, "w") as f:
##         f.write(t)

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: r-functions
# Basic function
say_hello <- function() {
  print("hello!")
}
say_hello()

# One parameter
greet <- function(name) {
  greeting <- paste0("Hello, ", name, "!")
  print(greeting)
}
greet("Rami")

# Two parameters
greet_n <- function(name, n_times) {
  greeting <- paste0("Hello, ", name, "!")
  rep(greeting, n_times)
}
greet_n("Nada", 5)


## # Basic function
## def say_hello():
##     print("hello!")
## 
## say_hello()
## 
## # One param
## def greet(name):
##     greeting = f"Hello, {name}!"
##     print(greeting)
## 
## greet("Rami")
## 
## # Two params
## def greet_n(name, n_times):
##     greeting = f"Hello, {name}!"
##     return [greeting] * n_times
## 
## print(greet_n("Nada", 5))

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: r-text
library(lorem)
library(readr)
library(stringr)
library(tokenizers)

# Create random content
text <- as.character(ipsum(3))

# Save to file
write(text, "sample.txt")

# Load from file
same_text <- read_file("sample.txt")

# Do things with it
count_words(same_text)
smileys <- str_replace_all(same_text, "\\.", " 🙂")
write(smileys, "smileys.txt")


## import lorem
## import re
## 
## # Create random content
## text = lorem.paragraph() * 3
## 
## # Save to file
## with open("sample.txt", "w") as f:
##     f.write(text)
## 
## # Load from file
## with open("sample.txt", "r") as f:
##     same_text = f.read()
## 
## # Do things with it
## word_count = len(same_text.split())
## 
## smileys = re.sub(r"\.", " 🙂", same_text)
## 
## with open("smileys.txt", "w", encoding="utf-8") as f:
##     f.write(smileys)

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: r-images
library(magick)

# Load an example jpeg
files <- list.files("example_docs/columns/orig",
  full.names = TRUE
)
img <- image_read(files[1])
image_info(img)

# Get specific page of a PDF
img2 <- image_read_pdf(files[2], pages = 1)

# Make greyscale
img2_grey <- image_convert(img2, type = "Grayscale")

# crop a 200x150 region starting at (50, 100)
img2_crop <- image_crop(img2, "200x150+50+100")

# Save (use this to convert)
image_write(img2_crop, "test.png", format = "png")


## import glob
## from PIL import Image
## 
## # Load an example jpeg
## files = glob.glob("example_docs/columns/orig/*")
## img = Image.open(files[0])
## 
## # Make greyscale
## img_grey = img.convert("L")
## 
## # Crop a 200x150 region starting at (50, 100)
## # PIL crop uses coordinates
## # (left, top, right, bottom)
## img_crop = img.crop((50, 100, 250, 250))
## 
## # Save (use this to convert)
## img_crop.save("test.png", format="PNG")

## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: r-ocr-eval

## WER
command <- "jiwer -g -r sample.txt -h smileys.txt"
wer <- as.numeric(system(command, intern = TRUE))
wer
# Inspect
system("jiwer -g -a -r sample.txt -h smileys.txt")

# CER (add -c)
command <- "jiwer -g -c -r sample.txt -h smileys.txt"
cer <- as.numeric(system(command, intern = TRUE))
cer
# Inspect
system("jiwer -g -a -c -r sample.txt -h smileys.txt")


## import jiwer
## 
## # Read the files
## with open("sample.txt", "r") as f:
##     ref = f.read()
## with open("smileys.txt", "r") as f:
##     hyp = f.read()
## 
## ## WER
## wer = jiwer.wer(ref, hyp)
## wer
## 
## # Inspect
## jiwer.process_words(ref, hyp)
## 
## # CER
## cer = jiwer.cer(ref, hyp)
## cer
## 
## # Inspect
## jiwer.process_characters(ref, hyp)
