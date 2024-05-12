# Kangaroo.nvim
## What can Kangaroo.nvim do?
- Display a visual reference ID to each window in the current tabpage
- Prompt the user which referenced window they would like to jump to

In other words, this plugin brings the basic functionality of tmux display-pane into Neovim.

## Installation
Kangaroo.nvim can be installed with any package manager and requires no dependencies. Make sure to call `require("kangaroo").setup{}` before using the plugin.

## Setup
Kangaroo.nvim comes with the defaults listed below
```Lua
require("kangaroo").setup { 
    referencing_method = "decimal", -- Can be "decimal" (0-9), hexadecimal (0-F), or alphabetical (A-Z)

    -- NOTE: This does not affect the numbering of alphabetical referencing (always starts at 1)
    start_at_zero = false, -- If true, then decimal/hexadecimal will start at 0 instead of 1

    -- If 'input_wait' is false, then Kangaroo.nvim will immediately switch to another window IF all windows
    -- can be referenced by a single character (depending on the numbering scheme)
    -- NOTE: If there are more windows than single character combinations (e.g., 10 windows while using decimal
    -- referencing), then Kangaroo.nvim will wait for the full response from the user
    input_wait = true,

    -- Colors for the statusline
    statusline = {
        active_win = { -- Refers to the window where Kangaroo was called from
            ctermfg = "White",
            ctermbg = "Red",
            fg = "White",
            bg = "Red"
        },
        inactive_win = { -- All other inactive windows
            ctermfg = "White",
            ctermbg = "Blue",
            fg = "White",
            bg = "Blue"
        }
    },
    -- Colors for the popup window (similar to tmux display-pane)
    popup = {
        active_win = {
            ctermfg = "Red",
            ctermbg = "None",
            fg = "Red",
            bg = "None"
        },
        inactive_win = {
            ctermfg = "Blue",
            ctermbg = "None",
            fg = "Blue",
            bg = "None"
        },
    }
}
```

Once the `setup` method has been called, you can then map either `use_popup()` or `use_statusline()` to a keybinding.
```Lua
-- Displays a popup window in the center of each visible window of the current tabpage
vim.keymap.set("n", "<leader>s", require("kangaroo").use_popup)
-- Displays a statusline in each visible window of the current tabpage
vim.keymap.set("n", "<leader>p", require("kangaroo").use_statusline)
```
