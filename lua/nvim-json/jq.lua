local function execute_jq(query, input)
  local command = string.format("echo '%s' | jq '%s' 2>&1", input, query)
  local handle = io.popen(command, "r")

  local result = handle:read("*a")
  local success, _, code = handle:close()
  
  if success then
    return result, nil
  else
    return nil, result
  end
end

return {
  execute_jq = execute_jq
}
