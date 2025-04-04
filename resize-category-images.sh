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

# Convert original image to WebP (no resizing)
echo "Converting original to WebP..."
magick "$input" -define webp:lossless=true "$base.webp"

# Array of sizes
sizes=("278x379" "414x173" "768x320" "1440x600")

# Loop through sizes
for size in "${sizes[@]}"; do
  echo "Converting to $size..."
  magick "$input" -resize "$size^" -gravity center -crop "$size+0+0" -define webp:lossless=true "$base-$size.webp"
done

echo "Conversion complete!"
