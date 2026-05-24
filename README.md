# gen-ia-custom-instructions

Personal customizations and configurations for AI tools.

## Files

- `instructions.md` — System instructions for AI CLIs (Gemini, etc.)
- `statusline-command.sh` — Claude Code statusline: context window + rate-limit progress bars

---

## How to Use

### Gemini CLI (Linux / Windows)
Pass the raw file URL or local path to your CLI configuration:
```bash
# Example loading directly from GitHub Raw
gemini-cli --system-instruction="$(curl -s https://raw.githubusercontent.com/imdoamaral/gen-ia-customized-instructions/master/instructions.md)"
```

### Claude Code Statusline

`statusline-command.sh` displays colored progress bars in the Claude Code terminal UI:

```
ctx [████████░░░░░░░░░░░░] 42%  5h [██░░░░░░░░] 18%  7d [█░░░░░░░░░] 9%
```

To activate it, add the following to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh /path/to/statusline-command.sh"
  }
}
```

The script reads context window usage and rate limits (5h/7d) from the JSON piped by Claude Code and renders color-coded bars (green → yellow → red).

> **Note:** Rate-limit bars only appear for paid Claude.ai subscribers after the first API response.