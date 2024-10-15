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
	-- get current buffer content or the selected text	
	-- local json_input = vim.fn.getreg("*")
	-- if json_input == "" then
  local json_input = get_current_buffer_content()
	-- end

  local original_bufnr = vim.api.nvim_get_current_buf()
  local this = self

  pickers.new({}, {
    prompt_title = "jq Query",
    finder = finders.new_dynamic({
      fn = function(prompt)
        if prompt == "" then
          return this.successful_queries
        else
					-- build a table from all this.successful_queries, along with prompt
					local queries = {prompt}
					for _, query in ipairs(this.successful_queries) do
						table.insert(queries, query)
					end
					return queries
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
				-- set json_query to entry.value trimmed from leading and trailing whitespaces
				-- TODO: This is still not a canonical way to represent a jq query. i.e: 'keys  |length' will not
				-- canonicalize to 'keys | length'. This is a limitation of the current implementation.
				local json_query = entry.value
				json_query = json_query:gsub("^%s*(.-)%s*$", "%1")

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {})
        vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns_id, 0, -1)

				-- Our success handler will both write the output to the buffer and add the query to successful_queries
				-- for further suggestions
				local success_writer = function(lines)	
				  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			    -- if successful_queries doesn't contain json_query, add it  
					if not vim.tbl_contains(this.successful_queries, json_query) then
						table.insert(this.successful_queries, json_query)
					end
				end

				local err_writer = function(lines)	
				  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				end

				execute_jq(json_query, json_input, success_writer, err_writer)
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
