local function jq(query, input, on_success, on_err)
	local result, err_result = {}, {"Error: "}
  local job_id = vim.fn.jobstart({'jq', query}, {
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        table.insert(result, line)
      end
    end,
    on_stderr = function(_, data, _)
      if data and data[1] and table.getn(data) > 1 then
				for _, line in ipairs(data) do
					table.insert(err_result, line)
				end
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
      	if on_err then
					on_err(err_result)
				end
			elseif on_success then
				on_success(result)
      end
    end,
    stdout_buffered = true,  -- Ensure output is sent in full chunks
    stderr_buffered = true,  -- Ensure error output is sent in full chunks
  })

  vim.fn.chansend(job_id, input)
  vim.fn.chanclose(job_id, 'stdin')
end

return {
  jq = jq,
}
