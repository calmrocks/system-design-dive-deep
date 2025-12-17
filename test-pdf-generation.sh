#!/bin/bash

# Test script for PDF generation
# Run this locally to test before pushing to GitHub

echo "🔍 Testing PDF generation locally..."

# Check if md-to-pdf is installed
if ! command -v md-to-pdf &> /dev/null; then
    echo "📦 Installing md-to-pdf..."
    npm install -g md-to-pdf
fi

# Create output directory
echo "📁 Creating output directory..."
mkdir -p output

# Convert a single test file first
TEST_FILE="SystemDesign/SystemDesign/README.md"
if [ -f "$TEST_FILE" ]; then
    echo "🧪 Testing with $TEST_FILE..."
    md-to-pdf "$TEST_FILE" \
      --config-file .github/md-to-pdf-config.json \
      --dest "output/test-README.pdf"
    
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
            md-to-pdf "$file" \
              --config-file .github/md-to-pdf-config.json \
              --dest "output/$dir_path/$filename.pdf" 2>/dev/null || echo "  ⚠️  Failed: $file"
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
fi
