#!/bin/bash

# Find all markdown files in _posts directory
find _posts -name "*.md" | while read post; do
  # Extract image path from front matter using sed
  image=$(sed -n '/^---$/,/^---$/ {
    /^image:/ {
      s/^image:[[:space:]]*//
      p
    }
  }' "$post")
  
  # Remove leading slash if present
  image="${image#/}"
  
  # If image path exists, process it
  if [ ! -z "$image" ]; then
    echo "Processing image from $post: $image"
    ./resize-featured-images.sh "$image"
  fi
done
