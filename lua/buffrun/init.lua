local M = {}

function M.run_buffrun_command()
  local api = vim.api
  local buf = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

  local pattern = "^buffrun<?c?o?>?: "
  local pattern_pipe = pattern .. "|"

  for _, line in ipairs(lines) do
    if line:match(pattern) then
      local confirm = false
      if line:match("<c>") then
        confirm = true
      end
      local autorun = false
      if line:match("<o>") then
        autorun = true
      end
      if confirm then
        local answer = vim.fn.input("Do you want to buffrun? [y/N]: ")
        if answer ~= "y" then
          return
        end
      end
      if line:match(pattern_pipe) then
        local lines2 = api.nvim_buf_get_lines(buf, 0, -1, false)
        local escaped_lines = {}
        for _, line2 in ipairs(lines2) do
          if not line2:match(pattern_pipe) then
            line2 = line2:gsub("'", "'\"\'\"'")
            table.insert(escaped_lines, line2)
          end
        end

        local command = line:gsub(pattern_pipe, "")
        local quoted_lines = table.concat(escaped_lines, '\n')
        local pipe = io.popen("echo '" ..  quoted_lines .. "' | " .. command, "r")
        pipe:close()
      else
        local file_path = api.nvim_buf_get_name(buf)
        local command = line:gsub(pattern, ""):gsub("${file_path}", file_path)
        vim.cmd('! ' .. command)
      end
    end
  end
end

function M.reload_plugin()
    package.loaded["buffrun"] = nil
    local r = require("buffrun")
    r.setup()
    return r
end

function M.setup()
  local api = vim.api
  api.nvim_create_user_command('BuffRun', M.run_buffrun_command, {})
  api.nvim_create_user_command('ReloadBuffrun', M.reload_plugin, {})
end

return M
