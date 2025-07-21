# hj

A shell script that provides z jump-like directory history jumping functionality. 
It allows quick directory navigation with interactive selection using fzf.

## Requirements

- [fzf](https://github.com/junegunn/fzf)

## Installation

### Using Homebrew (Recommended)

```bash
brew tap yasukotelin/tap
brew install yasukotelin/tap/hj
```

To use hj, add this to your shell profile:
```bash
echo 'source $(brew --prefix)/bin/hj' >> ~/.bashrc
# or
echo 'source $(brew --prefix)/bin/hj' >> ~/.zshrc
```

Then restart your shell or run:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Manual Installation

1. Download `hj.sh`

```bash
curl -o /path/to/hj.sh https://github.com/yasukotelin/hj/blob/main/hj.sh
```

2. Add the following to your shell configuration file (`.bashrc`, `.zshrc`, etc.):

```bash
source /path/to/hj.sh
```

## Usage

### Basic Commands

```bash
# Jump interactively by selecting from history
hj

# Show history list
hj --list
hj -l

# Show help
hj --help
hj -h
```

### Select and Jump from History

```bash
hj
```

This launches fzf and `cd`s to the selected directory.

### Automatic History Saving

History is automatically saved when using the `cd` command:

```bash
cd /path/to/project
cd ~/Documents
cd /var/log
# These paths are saved to ~/.hj_history
```

## History Management

### Frecency Algorithm

hj uses a "frecency" (frequency + recency) algorithm inspired by [z](https://github.com/rupa/z) to intelligently rank directories. This means frequently visited and recently accessed directories appear higher in the selection list.

### History File Format

History is saved to `~/.hj_history` with the following format:

```
/path/to/directory|rank|last_access_time
```

Example:
```
/Users/user/projects/webapp|15.5|1672531200
/Users/user/Documents|8.2|1672530800
/Users/user/Downloads|3.1|1672525400
```

### Ranking System

- **Initial Access**: New directories start with rank 1.0
- **Repeated Access**: Each visit increases the rank by 1.0
- **Time Decay**: Recent access gets higher priority based on time factors:
  - Within 1 hour: 4x multiplier
  - Within 1 day: 2x multiplier  
  - Within 1 week: 1x multiplier
  - Older than 1 week: 0.5x multiplier
- **Frecency Score**: `rank × time_factor` determines display order

### Automatic Maintenance

- **Aging**: When history exceeds 1000 lines, all ranks are multiplied by 0.99
- **Cleanup**: Entries with rank < 1.0 are automatically removed
- **Validation**: Non-existent directories are filtered out during display
- **Deduplication**: Duplicate paths are automatically handled

### How It Works

1. **Directory Visit**: When you `cd` to a directory:
   - If it's new → rank = 1.0
   - If it exists → rank = old_rank + 1.0
   - Update last access time

2. **Selection Display**: When you run `hj`:
   - Calculate frecency score for each entry
   - Sort by score (highest first)
   - Display in fzf for selection

This ensures that your most frequently used and recently accessed directories appear at the top of the list, making navigation more efficient over time.

## Usage Examples

```bash
# Navigate to project directories
cd ~/projects/myapp
cd ~/projects/webapp
cd /etc/nginx

# Check history list
hj --list
```

## License

MIT License
