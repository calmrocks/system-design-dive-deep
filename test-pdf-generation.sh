#!/bin/bash

# Test script for PDF generation using Pandoc
# Run this locally to test before pushing to GitHub

# Change to the script's directory (system-design-dive-deep)
cd "$(dirname "$0")"

echo "🔍 Testing PDF generation locally with Pandoc..."
echo "📂 Working directory: $(pwd)"

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "❌ Pandoc not found. Install it first:"
    echo "   macOS: brew install pandoc"
    echo "   Ubuntu: sudo apt-get install pandoc"
    exit 1
fi

# Check for PDF engine
if ! command -v xelatex &> /dev/null; then
    echo "⚠️  XeLaTeX not found. Install for best results:"
    echo "   macOS: brew install --cask mactex-no-gui"
    echo "   Ubuntu: sudo apt-get install texlive-xetex"
    echo ""
    echo "Trying with default PDF engine..."
    PDF_ENGINE=""
else
    PDF_ENGINE="--pdf-engine=xelatex"
fi

# Create output directory
echo "📁 Creating output directory..."
mkdir -p output

# Convert a single test file first
TEST_FILE="SystemDesign/SystemDesign/README.md"
if [ -f "$TEST_FILE" ]; then
    echo "🧪 Testing with $TEST_FILE..."
    pandoc "$TEST_FILE" \
      -o "output/test-README.pdf" \
      $PDF_ENGINE \
      -V geometry:margin=1in \
      -V colorlinks=true \
      --highlight-style=github \
      --standalone
    
    if [ $? -eq 0 ]; then
        echo "✅ Test conversion successful! Check output/test-README.pdf"
        echo ""
        echo "🚀 Converting all markdown files..."
        
        # Convert all markdown files
        find SystemDesign/SystemDesign -name "*.md" -type f | while read file; do
            rel_path="${file#SystemDesign/SystemDesign/}"
            dir_path=$(dirname "$rel_path")
            filename=$(basename "$file" .md)
            
            mkdir -p "output/$dir_path"
            
            echo "  Converting: $file"
            pandoc "$file" \
              -o "output/$dir_path/$filename.pdf" \
              $PDF_ENGINE \
              -V geometry:margin=1in \
              -V colorlinks=true \
              --highlight-style=github \
              --standalone \
              2>/dev/null || echo "  ⚠️  Failed: $file"
        done
        
        echo ""
        echo "✨ Done! Check the output/ folder for PDFs"
        echo "📊 Generated files:"
        find output -name "*.pdf" -type f | wc -l | xargs echo "   Total PDFs:"
    else
        echo "❌ Test conversion failed. Check the error above."
    fi
else
    echo "❌ Test file not found: $TEST_FILE"
    echo "   Looking for markdown files..."
    find SystemDesign -name "*.md" -type f | head -5
fi
