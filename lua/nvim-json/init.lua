local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local jq = require("nvim-json.jq")
local execute_jq = jq.jq

local M = {
    successful_queries = {".", "keys"}
}

-- Create namespace only once
local ns_id = vim.api.nvim_create_namespace("jq_error")
 
-- Function to get current buffer content
local function get_current_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

function M:jq_telescope()
  local json_input = get_current_buffer_content()
  local original_bufnr = vim.api.nvim_get_current_buf()
  local this = self

  pickers.new({}, {
    prompt_title = "jq Query",
    finder = finders.new_dynamic({
      fn = function(prompt)
        if prompt == "" then
          return this.successful_queries
        else
          return {prompt} -- Return whatever was typed
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
       
				local success_writer = function(lines)	
				     vim.api.nvim_buf_set_lines(original_bufnr, 0, -1, false, lines)
			   end
				 execute_jq(selection.value, json_input, success_writer)
      end)
      return true
    end,
    previewer = previewers.new_buffer_previewer({
      title = "jq Result",
      define_preview = function(self, entry)
        -- Clear previous content and highlights
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {})
        vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns_id, 0, -1)

				local success_writer = function(lines)	
				  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				end
				execute_jq(entry.value, json_input, success_writer)
      end,
    }),
  }):find()
end

function M:setup()
    vim.api.nvim_create_user_command("JqTelescope", function()
        M:jq_telescope()
    end, {})
end


return M
