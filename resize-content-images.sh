#!/bin/bash

# Check if an argument was provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <image-filepath>"
    exit 1
fi

# Store the input filepath
input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found"
    exit 1
fi

# Get the directory and filename without extension
dir=$(dirname "$input_file")
base=$(basename "$input_file" | sed 's/\.[^.]*$//')
ext="${input_file##*.}"

# Run magick commands with different sizes
magick "$input_file" -resize 320x -quality 80 -strip "${dir}/${base}-320.${ext}"
magick "$input_file" -resize 480x -quality 80 -strip "${dir}/${base}-480.${ext}"
magick "$input_file" -resize 665x -quality 80 -strip "${dir}/${base}-665.${ext}"

# Get the height of the 665px image
height=$(magick identify -format "%h" "${dir}/${base}-665.${ext}")
dir=$(dirname "$input_file" | sed 's/^\.//') 

# Construct the img tag
echo "<img"
echo "  src=\"${dir}/${base}-665.${ext}\""
echo "  srcset=\"${dir}/${base}-320.${ext} 320w,"
echo "          ${dir}/${base}-480.${ext} 480w,"
echo "          ${dir}/${base}-665.${ext} 665w\""
echo "  sizes=\"(max-width: 665px) 100vw, 665px\""
echo "  alt=\"\""
echo "  width=\"665\""
echo "  height=\"${height}\""
echo "  loading=\"lazy\""
echo "/>"

echo "Image processing complete!"
