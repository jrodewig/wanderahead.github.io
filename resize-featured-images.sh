#!/bin/bash

# Check if an input argument is provided
if [ -z "$1" ]; then
  echo "Error: Please provide an input image path as an argument."
  echo "Usage: $0 <input-image-path>"
  exit 1
fi

# Check if the input file exists
if [ ! -f "$1" ]; then
  echo "Error: Input file '$1' does not exist."
  exit 1
fi

# Input file from argument
input="$1"

# Derive base name by removing the extension
base="${input%.*}"

# Strip EXIF data in-place
echo "Stripping EXIF data from original image..."
magick "$input" -strip "$input"


# Convert original image to WebP
echo "Converting original to WebP..."
magick "$input" -strip -quality 75 -define webp:method=6 "$base.webp"

# Array of sizes
sizes=("180x180" "270x270" "384x256" "588x396" "414x173" "768x512" "1440x600")

# Loop through sizes
for size in "${sizes[@]}"; do
  echo "Converting to $size..."
  magick "$input"  -strip -resize "$size^" -gravity center -crop "$size+0+0" -quality 75 -define webp:method=6 "$base-$size.webp"
done

echo "Conversion complete!"
