# hj

A shell script that provides z jump-like directory history jumping functionality. 
It allows quick directory navigation with interactive selection using fzf.

## Requirements

- [fzf](https://github.com/junegunn/fzf)

## Installation

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

## History File

History is saved to `~/.hj_history`. This file:

- Appends the latest visited directories to the end
- Automatically removes duplicate paths
- Limited to maximum 1000 lines
- Automatically removes non-existent directories

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
