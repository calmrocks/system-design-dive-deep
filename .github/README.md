# GitHub Actions

## Markdown to PDF Conversion

This workflow automatically converts all markdown files in `SystemDesign/SystemDesign/` to PDFs and saves them in the `output/` folder with the same directory structure.

### How It Works

1. **Trigger**: Runs on push to `main`/`master` when markdown files change, or manually via workflow dispatch
2. **Process**: 
   - Finds all `.md` files in `SystemDesign/SystemDesign/`
   - Converts each to PDF using `md-to-pdf` with GitHub styling
   - Preserves folder structure in `output/` directory
   - Auto-commits generated PDFs with `[skip ci]` flag
3. **Features**:
   - GitHub markdown styling
   - Mermaid diagram support
   - Page numbers in footer
   - A4 format with proper margins

### Testing Locally

Before pushing to GitHub, test the PDF generation locally:

```bash
cd system-design-dive-deep
./test-pdf-generation.sh
```

This will:
- Install `md-to-pdf` if needed
- Convert all markdown files to PDFs
- Save them in `output/` folder
- Show you any conversion errors

### Configuration

PDF styling and options are configured in `.github/md-to-pdf-config.json`:
- Page format: A4
- Margins: 20mm all sides
- Styling: GitHub markdown CSS
- Mermaid: Enabled for diagrams

### Troubleshooting

**Mermaid diagrams not rendering?**
- Ensure diagrams use proper Mermaid syntax
- Check that code blocks are marked with `mermaid` language identifier

**PDFs look wrong?**
- Adjust CSS in `md-to-pdf-config.json`
- Modify margins in `pdf_options`

**Workflow not triggering?**
- Check that changes are in `SystemDesign/SystemDesign/**/*.md`
- Verify branch name is `main` or `master`
- Use "Actions" tab → "Convert Markdown to PDF" → "Run workflow" for manual trigger
