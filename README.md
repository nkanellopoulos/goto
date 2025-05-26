# ![rocket](images/rocket-vecteezy.com.png)

# goto - Ultra fast directory switching for Your Shell

A lightweight, intuitive directory bookmarking system for bash and zsh that helps you navigate your filesystem with ease.

## Features

- 📌 **Named Bookmarks** - Save directories with memorable names
- 🔢 **Quick Access** - Use numbers (1-9) or names to jump to bookmarks
- 🚀 **Ultra-fast Navigation** - Shortcuts `g1` through `g9` for instant access
- 📝 **Smart Tab Completion** - **See all bookmarks with paths before jumping**
- 🔗 **Path Variables** - Access bookmarks 1-9 via `$g1` to `$g9` variables
- 💾 **Persistent Storage** - Bookmarks survive shell restarts
- 🎯 **Zero Dependencies** - Pure shell script, no external tools needed
- 📊 **Clean Formatting** - Formatted output, easy to scan

## Installation

1. Clone or download `goto.sh` to your preferred location:

```bash
git clone https://github.com/nkanellopoulos/goto.git ~/goto
```

2. Add to your shell configuration:

For **bash** (`~/.bashrc`):

```bash
source ~/goto/goto.sh
```

For **zsh** (`~/.zshrc`):

```bash
source ~/goto/goto.sh
```

3. Reload your shell or run:

```bash
source ~/.bashrc  # or ~/.zshrc
```

## Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `mk` | Bookmark current directory |
| `mk <name>` | Bookmark current directory with a name |
| `gt` | List all bookmarks |
| `gt <number>` | Go to bookmark by number |
| `gt <name>` | Go to bookmark by name |
| `g1`...`g9` | Quick shortcuts for bookmarks 1-9 |
| `ml` | List all bookmarks (alias for `gt`) |
| `mkr <number/name>` | Remove a bookmark |
| `mkc` | Clear all bookmarks |

### Examples

```bash
# Navigate to your projects directory
cd ~/Projects/my-awesome-project

# Bookmark it with a name
mk awesome
✓ Marked 'awesome'

# Go to your downloads folder and bookmark it
cd ~/Downloads
mk
✓ Marked

# See all your bookmarks
gt
  1  awesome     ~/Projects/my-awesome-project
  2  ----------  ~/Downloads

# Jump using the name
gt awesome
/Users/you/Projects/my-awesome-project

# Or use the number
gt 2
/Users/you/Downloads

# Even faster with shortcuts
g1  # Goes to bookmark 1 instantly

# Tab completion shows your bookmarks
gt <TAB>
  1  awesome     ~/Projects/my-awesome-project
  2  ----------  ~/Downloads
```

### Advanced Usage

```bash
# Bookmark with spaces in names (use quotes)
mk "client work"

# Update an existing bookmark name
cd /new/path
mk awesome  # Updates the 'awesome' bookmark to current directory
✓ Updated 'awesome'

# Remove bookmarks
mkr awesome  # Remove by name
mkr 2        # Remove by number
✓ Removed

# If you try to bookmark the same directory twice
mk
Already bookmarked: 3) ~/Projects/my-awesome-project

# Use bookmark paths in other commands
echo $g1  # Prints the path of bookmark 1
cp file.txt $g2/  # Copy file to bookmark 2
ls -la $g3  # List contents of bookmark 3
```

## Tips & Tricks

1. **Project Organization** - Bookmark your active projects:

   ```bash
   mk frontend
   mk backend
   mk docs
   ```

2. **Quick Switching** - Use `g1`, `g2`, etc. for your most-used directories

3. **Temporary Bookmarks** - Use numbers for temporary bookmarks, names for permanent ones

4. **Manual Organization** - You can carefully edit `~/.goto_bookmarks` to reorganize your bookmarks' order

## Shell Integration

You can add the current bookmark name to your shell prompt. You can either copy the function from `prompt_integration.sh` or source it directly:

```bash
# Add this to your .bashrc or .zshrc
source ~/goto/prompt_integration.sh
```

Then modify your prompt:

**For bash:**

```bash
PS1='$(_get_bookmark_name)\u@\h:\w\$ '
```

**For zsh:**

```bash
setopt PROMPT_SUBST
PROMPT='$(_get_bookmark_name)%n@%m:%~%# '
```

This will show `[awesome]` when you're in a named bookmark, `[2]` for unnamed bookmarks (showing the bookmark number), or nothing if not bookmarked.

**Note:** If you have an existing custom prompt, you can prepend the bookmark indicator:

```bash
# For bash
PS1='$(_get_bookmark_name)'$PS1

# For zsh
PROMPT='$(_get_bookmark_name)'$PROMPT
```

## Configuration

Bookmarks are stored in `~/.goto_bookmarks` as a simple text file. Format:

```
name|/full/path/to/directory
|/path/without/name
```

## Compatibility

- ✅ **bash** 4.0+
- ✅ **zsh** 5.0+
- ✅ **macOS** Terminal, iTerm2
- ✅ **Linux** All distributions
- ✅ **WSL** Windows Subsystem for Linux

## License

MIT License - feel free to use in personal and commercial projects.

## Why goto?

### Advantages over cd

- **Memory** - No need to remember long paths
- **Speed** - Jump anywhere in 2-3 keystrokes
- **Persistence** - Bookmarks survive terminal restarts

### Advantages over pushd/popd

- **Named References** - Use meaningful names, not just stack positions
- **Persistence** - Stack doesn't survive shell exit
- **Visibility** - See all bookmarks at once

### Advantages over CDPATH

- **Explicit Control** - Bookmark exactly what you want
- **Names** - Reference by meaningful names
- **Portability** - Works the same everywhere

### Advantages over z/autojump

- **Predictable** - No surprises from frequency-based algorithms
- **Immediate** - Works right after bookmarking, no "learning" period
- **Transparent** - You control what's bookmarked

## Contributing

Contributions are welcome! Feel free to submit issues and enhancement requests.

## Author

**Nikos Kanellopoulos**  

Created with frustration from typing long paths too many times. 🚀
