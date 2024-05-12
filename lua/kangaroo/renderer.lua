local fonts = require("kangaroo.fonts")
local conversions = require("kangaroo.conversions")
local M = {}

---@type number
local base
---@type number
local starting_index
---@type boolean
local is_alpha
---@type boolean
local input_wait

---@param radix number
---@param start_at_zero boolean
---@param alpha boolean
---@param prompt boolean
function M.setup(radix, start_at_zero, alpha, prompt)
    base = radix
    starting_index = start_at_zero and 0 or 1
    is_alpha = alpha
    input_wait = prompt
end

---@param str string
---@return string[]
---@return number
local function str_to_popup(str)
    local converted_str = { "", "", "", "", "" }
    local multiplier = 1
    if str:len() == 1 then
        return fonts.font_table[str], multiplier
    end
    for i = 1, #str do
        converted_str[1] = converted_str[1] .. fonts.font_table[str:sub(i, i)][1]
        converted_str[2] = converted_str[2] .. fonts.font_table[str:sub(i, i)][2]
        converted_str[3] = converted_str[3] .. fonts.font_table[str:sub(i, i)][3]
        converted_str[4] = converted_str[4] .. fonts.font_table[str:sub(i, i)][4]
        converted_str[5] = converted_str[5] .. fonts.font_table[str:sub(i, i)][5]
        if i ~= #str then
            converted_str[1] = converted_str[1] .. " "
            converted_str[2] = converted_str[2] .. " "
            converted_str[3] = converted_str[3] .. " "
            converted_str[4] = converted_str[4] .. " "
            converted_str[5] = converted_str[5] .. " "
        end
        multiplier = multiplier + 1
    end
    return converted_str, multiplier
end

---@param table_size number
---@param index_to_handler_map { [number]: number }
---@return boolean
---@return string
local function handle_user_input(table_size, index_to_handler_map)
    ---@type string
    local user_input
    ---@type number
    local unvalidated_index
    ---@type number?
    local chosen_index
    ---@type boolean
    local ok = true
    local str_res = ""

    if table_size >= base or input_wait then
        vim.cmd(":set ei=all")
        user_input = string.upper(vim.fn.input("Which window to switch to? ")):gsub("%s+", "")
        vim.cmd(":set ei=")
        if user_input == nil or user_input == "" then
            return ok, str_res
        end
    else
        vim.print("Which window to switch to? ")
        user_input = vim.fn.getchar()
        if type(user_input) == "string" or user_input == 27 then
            return ok, str_res
        end
        user_input = string.upper(string.char(user_input))
        vim.print(user_input)
    end
    if is_alpha then
        ok, unvalidated_index = pcall(conversions.alphastr_to_index, user_input, base, conversions
            .alpha_to_decimal_table)
    else
        ok, unvalidated_index = pcall(conversions.basestr_to_index, user_input, base, conversions.hex_to_decimal_table)
    end
    if not ok then
        return ok, "Invalid Window Selection"
    end
    chosen_index = index_to_handler_map[unvalidated_index]
    if chosen_index ~= nil then
        local response, _ = pcall(vim.api.nvim_set_current_win, chosen_index)
        if not response then
            str_res = "Could not jump to specified window"
            ok = false
        end
    else
        str_res = "Invalid Window Selection"
        ok = false
    end
    return ok, str_res
end

function M.use_statusline()
    ---@type number
    local prev_laststatus = vim.api.nvim_get_option("laststatus")
    ---@type number[]
    local cur_winhandle_list = vim.api.nvim_tabpage_list_wins(0)
    ---@type number
    local index = starting_index
    ---@type { [number]: number }
    local index_to_handler_map = {}
    ---@type number
    local table_size = 0

    ---@class win_info
    ---@field statusline string
    ---@field winhl string
    ---@type { [number]: win_info }
    local winhandler_info_list = {}

    vim.api.nvim_set_option("laststatus", 2)

    for _, win_handle in pairs(cur_winhandle_list) do
        local res, win_config = pcall(vim.api.nvim_win_get_config, win_handle)
        if not res or not win_config.focusable then
            goto continue
        end
        index_to_handler_map[index] = win_handle
        winhandler_info_list[win_handle] = {
            statusline = vim.api.nvim_win_get_option(win_handle, "statusline"),
            winhl = vim.api.nvim_win_get_option(win_handle, "winhl")
        }
        vim.api.nvim_win_set_option(win_handle, "winhl",
            "StatusLine:KangarooStatusLine,StatusLineNC:KangarooStatusLineNC")
        if is_alpha then
            vim.api.nvim_win_set_option(win_handle, "statusline", "%=" ..
                conversions.index_to_alphastr(index, base, conversions.decimal_to_alpha_table)
                .. "%=")
        else
            vim.api.nvim_win_set_option(win_handle, "statusline", "%=" ..
                conversions.index_to_basestr(index, base, conversions.decimal_to_hex_table)
                .. "%=")
        end
        index = index + 1
        table_size = table_size + 1
        ::continue::
    end

    vim.cmd("redraw")

    if table_size == 0 then
        vim.print("No jumpable windows")
        return
    end

    local res, err_msg = handle_user_input(table_size, index_to_handler_map)

    vim.api.nvim_set_option("laststatus", prev_laststatus)
    for win_handle, val in pairs(winhandler_info_list) do
        if vim.api.nvim_win_is_valid(win_handle) then
            vim.api.nvim_win_set_option(win_handle, "statusline", val.statusline)
            vim.api.nvim_win_set_option(win_handle, "winhl", val.winhl)
        end
    end

    vim.cmd("redraw")

    if not res then
        vim.print(err_msg)
    else
        vim.cmd("echon ' '")
    end
end

function M.use_popup()
    ---@type number[]
    local cur_winhandle_list = vim.api.nvim_tabpage_list_wins(0)
    ---@type number
    local index = starting_index
    ---@type { [number]: number }
    local index_to_handler_map = {}
    ---@type number
    local table_size = 0

    ---@class popup_info
    ---@field scratch_bufnum number
    ---@field popup_winnum number
    ---@type { [number]: popup_info }
    local winhandler_info_list = {}

    ---@type number, number
    local temp_bufnum, temp_winnum

    local temp_pos

    local cur_win = vim.api.nvim_get_current_win()

    for _, win_handle in pairs(cur_winhandle_list) do
        local res, win_config = pcall(vim.api.nvim_win_get_config, win_handle)
        if not res or not win_config.focusable then
            goto continue
        end
        index_to_handler_map[index] = win_handle
        temp_bufnum = vim.api.nvim_create_buf(false, true)
        temp_winnum = vim.api.nvim_open_win(temp_bufnum, false, {
            focusable = false,
            style = "minimal",
            width = 1,
            height = 1,
            relative = "editor",
            row = 0,
            col = 0
        })
        if win_handle == cur_win then
            vim.api.nvim_win_set_option(temp_winnum, "winhighlight", "NormalFloat:KangarooPopup")
        else
            vim.api.nvim_win_set_option(temp_winnum, "winhighlight", "NormalFloat:KangarooPopupNC")
        end
        local str, multiplier
        if is_alpha then
            str, multiplier = str_to_popup(conversions.index_to_alphastr(index, base, conversions.decimal_to_alpha_table))
        else
            str, multiplier = str_to_popup(conversions.index_to_basestr(index, base, conversions.decimal_to_hex_table))
        end
        temp_pos = vim.api.nvim_win_get_position(win_handle)
        vim.api.nvim_win_set_config(temp_winnum, {
            relative = "editor",
            width = multiplier * 5,
            height = 5,
            row = math.floor(vim.api.nvim_win_get_height(win_handle) / 2) - 2 + temp_pos[1],
            col = math.floor(vim.api.nvim_win_get_width(win_handle) / 2) - math.floor(multiplier * 5 / 2) + temp_pos[2]
        })
        vim.api.nvim_buf_set_lines(temp_bufnum, 0, -1, true, str)
        winhandler_info_list[win_handle] = {
            scratch_bufnum = temp_bufnum,
            popup_winnum = temp_winnum
        }
        table_size = table_size + 1
        index = index + 1
        ::continue::
    end

    vim.cmd("redraw")

    if table_size == 0 then
        vim.print("No jumpable windows")
        return
    end

    local res, err_msg = handle_user_input(table_size, index_to_handler_map)

    for win_handle, val in pairs(winhandler_info_list) do
        if vim.api.nvim_win_is_valid(win_handle) then
            vim.api.nvim_win_close(val.popup_winnum, true)
            vim.api.nvim_buf_delete(val.scratch_bufnum, { force = true })
        end
    end

    vim.cmd("redraw")

    if not res then
        vim.print(err_msg)
    else
        vim.cmd("echon ' '")
    end
end

return M
