# Shell Subsystem (bsh)

`bsh` operates as the frontend interface for interaction. Rather than writing monolithic logic, `bsh` passes all input parsing and expansion into the `/lib/sh/` system libraries.

## Supported Syntax

The shell robustly models a typical POSIX-like interaction flow, customized for the Lua and SXOS environment.

```bash
echo "Hello World"
cat output.log > error.log
grep "panic" < system.log
ls -la &
export TARGET_DIR="/usr/bin"
source ~/.config/init.lua
```

### Syntax Feature Support

| Feature | Support Mechanism |
|---------|--------------------|
| Single and Double Quotes | Interpreted securely |
| Backslash Escaping | Interpreted securely |
| Variables | `$VAR` and `${VAR}` |
| Tilde Expansion `~` | Maps to user home directory |
| Pipe Chains `\|` | Passes stdout streams sequentially |
| Redirect Out `>`, `>>` | Replaces or appends target file |
| Redirect In `<` | Feeds target file into stdin stream |
| Backgrounding `&` | Detaches the process |
| Command Sequencing `;`| Evaluated sequentially |
| Comments `#` | Ignores subsequent string context |

## Shell Theming

Administrators and users can customize shell colors by providing a theme definition at `/home/<user>/.config/bsh/theme.lua`.

```lua
return {
    userColor    = colors.lime,
    pathColor    = colors.cyan,
    commandColor = colors.yellow,
    errorColor   = colors.red,
}
```
