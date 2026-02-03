#!/bin/bash

# Update all configuration files after migration to root

set -e

echo "🔧 Updating configuration files..."
echo ""

cd "$(dirname "$0")"

# Update GitHub Actions config
echo "📝 Updating .github/config/md-to-pdf-config.yml..."
cat > .github/config/md-to-pdf-config.yml << 'EOF'
# .github/md-to-pdf-config.yml
# Configuration for Markdown to PDF conversion

# Global settings
output_dir: output
css_file: .github/config/styles/print.css
# Build mode: 
#   true  = only convert changed files (faster)
#   false = convert all files (consistent)
incremental: true

# Source definitions
sources:
  # Convert all markdown files in Sessions and Design folders
  - glob: "Sessions/**/*.md"
    preserve_full_path: true

  - glob: "Design/**/*.md"
    preserve_full_path: true

  # Add other top-level markdown files if needed
  # - glob: "*.md"
  #   preserve_full_path: false
EOF

# Update test script
echo "📝 Updating test-pdf-generation.sh..."
cat > test-pdf-generation.sh << 'EOF'
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
EOF

chmod +x test-pdf-generation.sh

# Update ActionsSetup.md
echo "📝 Updating .github/ActionsSetup.md..."
cat > .github/ActionsSetup.md << 'EOF'
# GitHub Actions

## Markdown to PDF Conversion

Converts all markdown files in `Sessions/` and `Design/` to PDFs using Pandoc.

### How It Works

1. **Trigger**: Push to `main`/`master` when markdown files change, or manual dispatch
2. **Process**: 
   - Uses Pandoc with WeasyPrint for high-quality PDF output
   - Mermaid diagrams rendered as PNG images
   - Obsidian syntax preprocessing (wiki links, callouts, etc.)
   - Preserves folder structure in `output/` directory
   - Auto-commits generated PDFs

### Obsidian Vault Structure

The repository root is now an Obsidian vault:

```
system-design-dive-deep/
├── .obsidian/           # Obsidian configuration
├── Sessions/            # Topic-based learning sessions
├── Design/              # Design documents
├── output/              # Generated PDFs (auto-generated)
├── diagrams/            # PlantUML diagrams
├── templates/           # Document templates
└── README.md
```

### Testing Locally

```bash
cd system-design-dive-deep
./test-pdf-generation.sh
```

**Prerequisites**:
- Pandoc: `brew install pandoc`
- XeLaTeX (optional, for best results): `brew install --cask mactex-no-gui`

### Troubleshooting

**Mermaid diagrams not rendering?**
- Install mermaid-cli: `npm install -g @mermaid-js/mermaid-cli`
- Diagrams are rendered as PNG images for better compatibility

**Missing fonts?**
- Install Noto fonts: `brew install font-noto-sans font-noto-serif`

**Obsidian syntax not converting?**
- Wiki links `[[link]]` are converted to bold text
- Callouts `> [!note]` are converted to emoji-prefixed blockquotes
- Comments `%%comment%%` are removed
EOF

echo ""
echo "✅ Configuration files updated!"
echo ""
echo "📋 Updated files:"
echo "   - .github/config/md-to-pdf-config.yml"
echo "   - test-pdf-generation.sh"
echo "   - .github/ActionsSetup.md"
echo ""
