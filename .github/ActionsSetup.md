# GitHub Actions

## Markdown to PDF Conversion

Converts all markdown files in `SystemDesign/SystemDesign/` to PDFs using Pandoc.

### How It Works

1. **Trigger**: Push to `main`/`master` when markdown files change, or manual dispatch
2. **Process**: 
   - Uses Pandoc with XeLaTeX for high-quality PDF output
   - Mermaid filter for diagram rendering
   - Preserves folder structure in `output/` directory
   - Auto-commits generated PDFs

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
- Install mermaid-filter: `npm install -g mermaid-filter`
- Add `-F mermaid-filter` to pandoc command

**Missing fonts?**
- Install texlive fonts: `brew install --cask mactex-no-gui`
