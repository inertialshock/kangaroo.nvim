local renderer = require("kangaroo.renderer")
local M = {}

---@alias ordering
---| '"hexadecimal"' # Start from 1-9 then A-F then A0 etc.
---| '"decimal"' # Use only numbers (1-9 then 10-19 etc.)
---| '"alpha"' # Use only alphabet (A-Z then AA-AZ etc.)

---@class Config
---@field referencing_method ordering
---@field start_at_zero boolean
---@field statusline WindowColors
---@field popup WindowColors

---@class WindowColors
---@field active_win Colors
---@field inactive_win Colors

---@class Colors
---@field ctermfg string
---@field ctermbg string
---@field fg string
---@field bg string

---@class PartialConfig
---@field referencing_method ordering?
---@field start_at_zero boolean?
---@field statusline WindowColors?
---@field popup WindowColors?

---@class PartialWindowColors
---@field active_win Colors?
---@field inactive_win Colors?

---@class PartialColors
---@field ctermfg string?
---@field ctermbg string?
---@field fg string?
---@field bg string?

---@param opts PartialConfig
function M.setup(opts)
    ---@type Config
    local default_config = {
        referencing_method = "decimal",
        start_at_zero = false,
        input_wait = true,
        statusline = {
            active_win = {
                ctermfg = "White",
                ctermbg = "Red",
                fg = "White",
                bg = "Red"
            },
            inactive_win = {
                ctermfg = "White",
                ctermbg = "Blue",
                fg = "White",
                bg = "Blue"
            },
        },
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
    for key, val in pairs(opts) do
        default_config[key] = val
    end
    if default_config.referencing_method == "decimal" then
        renderer.setup(10, default_config.start_at_zero, false, default_config.input_wait)
    elseif default_config.referencing_method == "alpha" then
        renderer.setup(26, false, true, default_config.input_wait)
    elseif default_config.referencing_method == "hexadecimal" then
        renderer.setup(16, default_config.start_at_zero, true, default_config.input_wait)
    else
        error("Invalid referencing_method " .. default_config.referencing_method)
    end
    M.use_popup = renderer.use_popup
    M.use_statusline = renderer.use_statusline
    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = '*',
        callback = function(_)
            vim.api.nvim_set_hl(0, "KangarooStatusLine", default_config.statusline.active_win)
            vim.api.nvim_set_hl(0, "KangarooStatusLineNC", default_config.statusline.inactive_win)
            vim.api.nvim_set_hl(0, "KangarooPopup", default_config.popup.active_win)
            vim.api.nvim_set_hl(0, "KangarooPopupNC", default_config.popup.inactive_win)
        end
    })
end

return M
