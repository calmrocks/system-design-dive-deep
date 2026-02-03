#!/bin/bash

# Test script for PDF generation using Pandoc
# Run this locally to test before pushing to GitHub

# Change to the script's directory
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

# Find a test file
TEST_FILE=""
if [ -f "Design/Stage1.md" ]; then
    TEST_FILE="Design/Stage1.md"
elif [ -f "Sessions/Cache/Cache.md" ]; then
    TEST_FILE="Sessions/Cache/Cache.md"
else
    TEST_FILE=$(find Sessions Design -name "*.md" -type f 2>/dev/null | head -1)
fi

if [ -n "$TEST_FILE" ] && [ -f "$TEST_FILE" ]; then
    echo "🧪 Testing with $TEST_FILE..."
    pandoc "$TEST_FILE" \
      -o "output/test-conversion.pdf" \
      $PDF_ENGINE \
      -V geometry:margin=1in \
      -V colorlinks=true \
      --highlight-style=tango \
      --standalone
    
    if [ $? -eq 0 ]; then
        echo "✅ Test conversion successful! Check output/test-conversion.pdf"
        echo ""
        echo "🚀 Converting all markdown files..."
        
        # Convert all markdown files in Sessions and Design
        for dir in Sessions Design; do
            if [ -d "$dir" ]; then
                find "$dir" -name "*.md" -type f | while read file; do
                    rel_path="$file"
                    dir_path=$(dirname "$rel_path")
                    filename=$(basename "$file" .md)
                    
                    mkdir -p "output/$dir_path"
                    
                    echo "  Converting: $file"
                    pandoc "$file" \
                      -o "output/$dir_path/$filename.pdf" \
                      $PDF_ENGINE \
                      -V geometry:margin=1in \
                      -V colorlinks=true \
                      --highlight-style=tango \
                      --standalone \
                      2>/dev/null || echo "  ⚠️  Failed: $file"
                done
            fi
        done
        
        echo ""
        echo "✨ Done! Check the output/ folder for PDFs"
        echo "📊 Generated files:"
        find output -name "*.pdf" -type f | wc -l | xargs echo "   Total PDFs:"
    else
        echo "❌ Test conversion failed. Check the error above."
    fi
else
    echo "❌ No test file found"
    echo "   Looking for markdown files..."
    find Sessions Design -name "*.md" -type f 2>/dev/null | head -5
fi
