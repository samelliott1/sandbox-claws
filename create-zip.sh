#!/bin/bash

# Create zip file with all Sandbox Claws project files
# Run this from the sandbox-claws directory

echo "Creating sandbox-claws-for-ai.zip..."

zip -r sandbox-claws-for-ai.zip \
  *.md \
  *.html \
  *.sh \
  *.yml \
  .env.example \
  .env.openclaw.example \
  .gitignore \
  LICENSE \
  css/ \
  js/ \
  docker/ \
  docs/ \
  scripts/ \
  security/ \
  -x "*.git*" -x "*node_modules*" -x "*.DS_Store" -x "*.zip"

echo "✓ Done! Created sandbox-claws-for-ai.zip"
echo ""
echo "This zip contains all project files ready to give to another AI model."
echo "File size:"
ls -lh sandbox-claws-for-ai.zip
