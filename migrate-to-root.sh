#!/bin/bash

# Safe migration script to move Obsidian vault to root
# This script moves content from SystemDesign/SystemDesign/ to root

set -e  # Exit on error

echo "🚀 Starting migration to root-level Obsidian vault..."
echo ""

# Change to script directory
cd "$(dirname "$0")"

# Verify we're in the right place
if [ ! -d "SystemDesign/SystemDesign" ]; then
    echo "❌ Error: SystemDesign/SystemDesign directory not found"
    exit 1
fi

# Check git status
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Warning: You have uncommitted changes"
    echo "   Please commit or stash them first"
    exit 1
fi

echo "📋 Migration Plan:"
echo "   1. Move content from SystemDesign/SystemDesign/ to root"
echo "   2. Move .obsidian config to root"
echo "   3. Keep output/ folder as-is"
echo "   4. Remove empty SystemDesign/ directory"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration cancelled"
    exit 1
fi

echo ""
echo "📦 Step 1: Moving content directories..."

# Move Sessions and Design folders
if [ -d "SystemDesign/SystemDesign/Sessions" ]; then
    echo "   Moving Sessions/"
    git mv SystemDesign/SystemDesign/Sessions ./
fi

if [ -d "SystemDesign/SystemDesign/Design" ]; then
    echo "   Moving Design/"
    git mv SystemDesign/SystemDesign/Design ./
fi

# Move any other directories except .obsidian
for dir in SystemDesign/SystemDesign/*/; do
    dirname=$(basename "$dir")
    if [ "$dirname" != ".obsidian" ] && [ "$dirname" != ".DS_Store" ]; then
        if [ -d "$dir" ]; then
            echo "   Moving $dirname/"
            git mv "$dir" ./
        fi
    fi
done

echo ""
echo "📝 Step 2: Moving README and other files..."

# Move README if it exists and is different from root README
if [ -f "SystemDesign/SystemDesign/README.md" ]; then
    if [ -f "README.md" ]; then
        echo "   README.md exists in both locations"
        echo "   Keeping root README.md, backing up nested one as README-obsidian.md"
        cp SystemDesign/SystemDesign/README.md README-obsidian.md
        git add README-obsidian.md
    else
        echo "   Moving README.md"
        git mv SystemDesign/SystemDesign/README.md ./
    fi
fi

# Move any other markdown files
for file in SystemDesign/SystemDesign/*.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if [ "$filename" != "README.md" ]; then
            echo "   Moving $filename"
            git mv "$file" ./
        fi
    fi
done

echo ""
echo "⚙️  Step 3: Moving .obsidian configuration..."

# Move .obsidian folder
if [ -d "SystemDesign/SystemDesign/.obsidian" ]; then
    if [ -d ".obsidian" ]; then
        echo "   .obsidian already exists in root, backing up nested one"
        cp -r SystemDesign/SystemDesign/.obsidian .obsidian-backup
        git add .obsidian-backup
    else
        echo "   Moving .obsidian/"
        git mv SystemDesign/SystemDesign/.obsidian ./
    fi
fi

echo ""
echo "🧹 Step 4: Cleaning up empty directories..."

# Remove .DS_Store files
find SystemDesign -name ".DS_Store" -type f -delete 2>/dev/null || true

# Remove empty SystemDesign directories
if [ -d "SystemDesign/SystemDesign" ]; then
    rmdir SystemDesign/SystemDesign 2>/dev/null || echo "   SystemDesign/SystemDesign not empty, keeping it"
fi

if [ -d "SystemDesign" ]; then
    rmdir SystemDesign 2>/dev/null || echo "   SystemDesign not empty, keeping it"
fi

echo ""
echo "✅ Migration complete!"
echo ""
echo "📊 Summary:"
echo "   - Content moved to root"
echo "   - .obsidian config moved to root"
echo "   - output/ folder unchanged"
echo ""
echo "⚠️  Next steps:"
echo "   1. Review changes: git status"
echo "   2. Update scripts and configs (run update-configs.sh)"
echo "   3. Test locally before committing"
echo "   4. Commit: git commit -m 'refactor: Move Obsidian vault to root'"
echo ""
