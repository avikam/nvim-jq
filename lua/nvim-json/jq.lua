local function execute_jq(query, input, successful_queries)
  local command = string.format("echo '%s' | jq '%s' 2>&1", input, query)
  local handle = io.popen(command, "r")

  local result = handle:read("*a")
  local success, code = handle:close()
 
  print("q", query, "s", success, "c", code, "r", result)
  if success then
    print("adding...")
    -- table.insert(successful_queries, 1, query)
    return result, nil
  else
    return nil, result
  end
end

local function execute_jq_2(query, input)
  local job_id = vim.fn.jobstart({'jq', query}, {
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        table.insert(result, line)
      end
      print(table.concat(result, "\n"))      
    end,
    on_stderr = function(_, data, _)
      if data and data[1] and table.getn(data) > 1 then
        print("Error: " .. table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        print("jq failed with exit code: " .. exit_code)
      end
    end,
    stdout_buffered = true,  -- Ensure output is sent in full chunks
    stderr_buffered = true,  -- Ensure error output is sent in full chunks
  })

  -- Send the JSON input to jq's stdin
  vim.fn.chansend(job_id, input)

  -- Close jq's stdin to signal that no more input will be sent
  vim.fn.chanclose(job_id, 'stdin')
end

-- Example usage
-- execute_jq_2('ke', '{"name": "Neovim", "version": "0.8"}')

return {
  execute_jq = execute_jq,
  jq = jq,
}
