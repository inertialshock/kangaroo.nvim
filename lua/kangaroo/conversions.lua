local M = {}

---@type { [number]: string }
M.decimal_to_hex_table = {
    [0] = "0",
    [1] = "1",
    [2] = "2",
    [3] = "3",
    [4] = "4",
    [5] = "5",
    [6] = "6",
    [7] = "7",
    [8] = "8",
    [9] = "9",
    [10] = "A",
    [11] = "B",
    [12] = "C",
    [13] = "D",
    [14] = "E",
    [15] = "F"
}

---@type { [string]: number }
M.hex_to_decimal_table = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["A"] = 10,
    ["B"] = 11,
    ["C"] = 12,
    ["D"] = 13,
    ["E"] = 14,
    ["F"] = 15,
}

---@type { [number]: string }
M.decimal_to_alpha_table = {
    [0] = "A",
    [1] = "B",
    [2] = "C",
    [3] = "D",
    [4] = "E",
    [5] = "F",
    [6] = "G",
    [7] = "H",
    [8] = "I",
    [9] = "J",
    [10] = "K",
    [11] = "L",
    [12] = "M",
    [13] = "N",
    [14] = "O",
    [15] = "P",
    [16] = "Q",
    [17] = "R",
    [18] = "S",
    [19] = "T",
    [30] = "U",
    [21] = "V",
    [22] = "W",
    [23] = "X",
    [24] = "Y",
    [25] = "Z"
}

---@type { [string]: number }
M.alpha_to_decimal_table = {
    ["A"] = 1,
    ["B"] = 2,
    ["C"] = 3,
    ["D"] = 4,
    ["E"] = 5,
    ["F"] = 6,
    ["G"] = 7,
    ["H"] = 8,
    ["I"] = 9,
    ["J"] = 10,
    ["K"] = 11,
    ["L"] = 12,
    ["M"] = 13,
    ["N"] = 14,
    ["O"] = 15,
    ["P"] = 16,
    ["Q"] = 17,
    ["R"] = 18,
    ["S"] = 19,
    ["T"] = 20,
    ["U"] = 21,
    ["V"] = 22,
    ["W"] = 23,
    ["X"] = 24,
    ["Y"] = 25,
    ["Z"] = 26
}

---@param num number
---@param base number
---@param conversion_table { [number]: string }
---@return string
function M.index_to_basestr(num, base, conversion_table)
    ---@type string
    local converted_basestr = ""

    while num > 0 do
        converted_basestr = conversion_table[num % base] .. converted_basestr
        num = math.floor(num / base)
    end
    return converted_basestr
end

---@param num string
---@param base number
---@param conversion_table { [string]: number }
---@return number
function M.basestr_to_index(num, base, conversion_table)
    ---@type number
    local converted_index = 0
    ---@type number
    local count = 0

    ---@type number?
    local cur_char = 0

    for i = num:len(), 1, -1 do
        cur_char = conversion_table[num:sub(i, i)]
        if cur_char == nil then
            return -1
        end
        converted_index = converted_index + cur_char * math.pow(base, count)
        count = count + 1
    end
    return converted_index
end

---@param num number
---@param base number
---@param conversion_table { [number]: string }
---@return string
function M.index_to_alphastr(num, base, conversion_table)
    ---@type number
    local chosen_num
    local converted_str = ""
    while num > 0 do
        chosen_num = (num - 1) % base
        converted_str = conversion_table[chosen_num] .. converted_str
        num = math.floor((num - chosen_num) / base)
    end
    return converted_str
end

---@param num string
---@param base number
---@param conversion_table { [string]: number }
---@return number
function M.alphastr_to_index(num, base, conversion_table)
    local counter = num:len() - 1
    local converted_index = 0
    for i = 1, #num do
        converted_index = converted_index + conversion_table[num:sub(i, i)] * math.pow(base, counter)
        counter = counter - 1
    end
    return converted_index
end

return M
