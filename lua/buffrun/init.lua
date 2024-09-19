local base_pattern = "^buffrun<?c?C?o?>?: "

local M = {

  confirmed_buffers = {},
  pattern = base_pattern,
  pattern_pipe = base_pattern .. "|"

}

local api = vim.api

function M.buffrun_file(buf, file_path, line)
  local file_path = api.nvim_buf_get_name(buf)
  local command = line:gsub(M.pattern, ""):gsub("${file_path}", file_path)
  vim.cmd('! ' .. command)
end

function M.buffrun_buffer(buf, line)
  local lines2 = api.nvim_buf_get_lines(buf, 0, -1, false)
  local escaped_lines = {}
  for _, line2 in ipairs(lines2) do
    if not line2:match(M.pattern_pipe) then
      line2 = line2:gsub("'", "'\"\'\"'")
      table.insert(escaped_lines, line2)
    end
  end

  local command = line:gsub(M.pattern_pipe, "")
  local quoted_lines = table.concat(escaped_lines, '\n')
  local pipe = io.popen("echo '" ..  quoted_lines .. "' | " .. command, "r")
  print(pipe:read("*a"))
  pipe:close()
end

function M.check_confirm(line, buf)
  local confirm = false
  if line:match("<c>") then
    confirm = true
  end
  local confirm_once = false
  if line:match("<C>") then
    confirm_once = true
    if M.confirmed_buffers[buf] ~= nil then
      confirm = false
    else
      confirm = true
    end
  end
  if confirm then
    local answer = vim.fn.input("Do you want to buffrun? [y/N]: ")
    if answer ~= "y" then
      return false
    else
      if confirm_once then
        M.confirmed_buffers[buf] = true
      end
    end
  end
  return true
end

function M.run_buffrun_command()
  local buf = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

  for _, line in ipairs(lines) do
    if line:match(M.pattern) then
      if M.check_confirm(line, buf)
        then
        if line:match(M.pattern_pipe) then
          M.buffrun_buffer(buf, line)
        else
          M.buffrun_file(buf, file_path, line)
        end
      end
    end
  end
end

function M.load_auto_buffrun()
  local buf = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

  for _, line in ipairs(lines) do
    if line:match(M.pattern) then
      if line:match("<o>")
      then
        vim.cmd('autocmd BufWritePost <buffer> BuffRun')
        print("Auto BuffRun enabled")
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
  api.nvim_create_user_command('AutoBuffRun', M.load_auto_buffrun, {})
end

return M
