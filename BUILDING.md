# Building & Maintenance

This document contains commands and instructions for building, testing, and maintaining the ChainLetter package.

## Building

```bash
# Debug build
swift build

# Release build (optimized)
swift build -c release

# Clean build artifacts
swift package clean
```

## Testing

```bash
# Run all tests
swift test

# Run a specific test suite
swift test --filter ChainTests
swift test --filter SplittersTests
swift test --filter MarkovTextTests
swift test --filter CombineTests

# Run a single test
swift test --filter "SplittersTests/InitialismTests/usaInitialism"

# Run tests with verbose output
swift test --verbose
```

## Documentation

### Generate Documentation

```bash
# Build documentation archive
swift package generate-documentation --target ChainLetter

# Output location:
# .build/plugins/Swift-DocC/outputs/ChainLetter.doccarchive
```

### Preview Documentation in Browser

```bash
swift package --disable-sandbox preview-documentation --target ChainLetter
```

This starts a local server (usually at `http://localhost:8080/documentation/chainletter`).

### Export Static Documentation

```bash
# Generate static HTML site
swift package --disable-sandbox generate-documentation \
    --target ChainLetter \
    --output-path ./docs \
    --transform-for-static-hosting \
    --hosting-base-path ChainLetter
```

### Publish Documentation to `docc` Branch

This publishes the documentation to a `docc` branch in an `html` folder for GitHub Pages.

**Important:** The `--hosting-base-path` must include both the repo name AND the html folder path (e.g., `ChainLetter/html`) for GitHub Pages to work correctly.

```bash
# 1. Generate the static documentation
swift package --disable-sandbox generate-documentation \
    --target ChainLetter \
    --output-path /tmp/chainletter-docs \
    --transform-for-static-hosting \
    --hosting-base-path ChainLetter/html

# 2. Save current branch name
CURRENT_BRANCH=$(git branch --show-current)

# 3. Stash any uncommitted changes
git stash --include-untracked

# 4. Switch to docc branch (create orphan if it doesn't exist)
git checkout docc 2>/dev/null || git checkout --orphan docc

# 5. Remove existing content (if updating)
git rm -rf . 2>/dev/null || true
rm -rf *

# 6. Copy documentation into html folder
mkdir -p html
cp -R /tmp/chainletter-docs/* html/

# 7. Add an index redirect (optional, for convenience)
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0; url=html/documentation/chainletter/">
    <title>Redirecting to ChainLetter Documentation</title>
</head>
<body>
    <p>Redirecting to <a href="html/documentation/chainletter/">ChainLetter Documentation</a>...</p>
</body>
</html>
EOF

# 8. Commit and push
git add .
git commit -m "Update documentation"
git push origin docc

# 9. Return to original branch
git checkout $CURRENT_BRANCH
git stash pop 2>/dev/null || true

# 10. Clean up
rm -rf /tmp/chainletter-docs
```

**One-liner version** (after initial setup):

```bash
swift package --disable-sandbox generate-documentation --target ChainLetter --output-path /tmp/chainletter-docs --transform-for-static-hosting --hosting-base-path ChainLetter/html && BRANCH=$(git branch --show-current) && git stash --include-untracked && git checkout docc && rm -rf html && mkdir html && cp -R /tmp/chainletter-docs/* html/ && git add . && git commit -m "Update documentation" && git push origin docc && git checkout $BRANCH && git stash pop 2>/dev/null; rm -rf /tmp/chainletter-docs
```

**GitHub Pages Setup:**

1. Go to repository Settings > Pages
2. Set Source to "Deploy from a branch"
3. Select `docc` branch and `/ (root)` folder
4. Documentation will be available at: `https://yourusername.github.io/ChainLetter/`

## Package Management

### Update Dependencies

```bash
# Update to latest compatible versions
swift package update

# Show current dependency versions
swift package show-dependencies
```

### Resolve Dependencies

```bash
# Resolve and fetch dependencies
swift package resolve
```

### Reset Package State

```bash
# Full reset (removes .build directory)
swift package reset
```

## Platform Support

The package supports:

| Platform | Minimum Version |
|----------|-----------------|
| macOS | 13.0 |
| iOS | 16.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| visionOS | 1.0 |

These minimums are determined by the use of `RegexBuilder`.

## Release Checklist

Before releasing a new version:

1. **Run all tests**
   ```bash
   swift test
   ```

2. **Build in release mode**
   ```bash
   swift build -c release
   ```

3. **Generate documentation and check for warnings**
   ```bash
   swift package generate-documentation --target ChainLetter 2>&1 | grep -E "(warning|error)"
   ```

4. **Update version in README if needed**

5. **Tag the release**
   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0
   ```

## Project Structure

```
ChainLetter/
├── Package.swift                 # Package manifest
├── README.md                     # User-facing documentation
├── BUILDING.md                   # This file
├── Sources/
│   └── ChainLetter/
│       ├── State.swift           # Markov chain state type
│       ├── Chain.swift           # Core Markov chain implementation
│       ├── Splitters.swift       # Sentence boundary detection
│       ├── MarkovText.swift      # High-level text generation API
│       └── Documentation.docc/   # DocC documentation catalog
│           ├── ChainLetter.md
│           ├── GettingStarted.md
│           ├── TextGeneration.md
│           ├── CustomizingSentenceSplitting.md
│           ├── CombiningModels.md
│           └── PersistingModels.md
└── Tests/
    └── ChainLetterTests/
        ├── StateTests.swift      # (in ChainTests.swift)
        ├── ChainTests.swift
        ├── SplittersTests.swift
        ├── MarkovTextTests.swift
        └── CombineTests.swift
```

## Xcode

### Open in Xcode

```bash
open Package.swift
```

Or use File > Open and select the `ChainLetter` directory.

### Generate Xcode Project (if needed)

```bash
swift package generate-xcodeproj
```

Note: This is generally not recommended. Opening `Package.swift` directly is preferred.

## Troubleshooting

### Build Errors After Xcode Update

```bash
swift package reset
swift package resolve
swift build
```

### Documentation Not Updating

```bash
swift package clean
swift package generate-documentation --target ChainLetter
```

### Tests Failing with Concurrency Errors

Ensure all public types conform to `Sendable`:
- `State` ✓
- `Chain` ✓
- `MarkovText` ✓

### "No such module" Error

```bash
swift package resolve
swift build
```
