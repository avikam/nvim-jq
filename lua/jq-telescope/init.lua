local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local M = {}

-- Function to execute jq command
local function execute_jq(query, input)
  local command = string.format("echo '%s' | jq '%s'", input, query)
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Function to get current buffer content
local function get_current_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Custom previewer
local jq_previewer = previewers.new_buffer_previewer({
  title = "jq Result",
  define_preview = function(self, entry)
    local result = execute_jq(entry.value, entry.json_input)
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(result, "\n"))
  end,
})

function M.jq_telescope()
  local json_input = get_current_buffer_content()
  local original_bufnr = vim.api.nvim_get_current_buf()
  
  pickers.new({}, {
    prompt_title = "jq Query",
    finder = finders.new_dynamic({
      fn = function(prompt)
        if prompt == "" then
          return {".", "keys"} -- Default suggestion
        else
          return {prompt}
        end
      end,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
          json_input = json_input,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        
        -- Execute jq and replace buffer content
        local result = execute_jq(selection.value, json_input)
        vim.api.nvim_buf_set_lines(original_bufnr, 0, -1, false, vim.split(result, "\n"))
        
        -- Optionally, print a message to confirm the action
        vim.api.nvim_echo({{string.format("Applied jq query: %s", selection.value), "Normal"}}, true, {})
      end)
      return true
    end,
    previewer = jq_previewer,
  }):find()
end

return M
