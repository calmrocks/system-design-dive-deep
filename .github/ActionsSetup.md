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
