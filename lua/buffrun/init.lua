local base_pattern = "^buffrun<?[wcoCs]*>?: "

local M = {

  confirmed_buffers = {},
  pattern = base_pattern,
  pattern_pipe = base_pattern .. "|"

}

local api = vim.api

function M.buffrun_run_and_output(line, full_command)
  local stdout_data = {}
  local stderr_data = {}

  -- Run the command asynchronously and capture stdout, stderr, and exit code
  vim.fn.jobstart(full_command, {
    stdout_buffered = true,  -- Buffer stdout
    stderr_buffered = true,  -- Buffer stderr
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          table.insert(stdout_data, line)  -- Collect stdout lines
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          table.insert(stderr_data, line)  -- Collect stderr lines
        end
      end
    end,
      on_exit = function(_, exit_code, _)
        local output = ""
        if #stdout_data > 0 then
          output = table.concat(stdout_data, "\n")
        end
        if #stderr_data > 0 then
          output = output .. "\n" .. table.concat(stderr_data, "\n")
        end
        if M.line_contains_option(line, "s") and exit_code == 0 then
          print("buffrun successful")
        else
          if M.line_contains_option(line, "w") then
            M.open_output_window(output)
          else
            print("\n")
            print(output)
          end
        end
      end,
    })
end

function M.buffrun_file(buf, file_path, line)
  local file_path = api.nvim_buf_get_name(buf)
  local command = line:gsub(M.pattern, ""):gsub("${file_path}", file_path)
  M.buffrun_run_and_output(line, command)
end

function M.open_output_window(output)
  -- print the output in a floating window
  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(output, "\n"))
  local win = api.nvim_open_win(bufnr, true, {
      title = "BuffRun Output",
      relative = "editor",
      width = 80,
      height = 10,
      row = 10,
      col = 10,
      border = "rounded"
    })
  api.nvim_set_current_win(win)
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
  local full_command = "echo '" ..  quoted_lines .. "' | " .. command
  M.buffrun_run_and_output(line, full_command)
end


function M.line_contains_option(line, option_char)
  -- get the part between < > in line
  local options = line:match("<(.*)>")
  return options and options:find(option_char)
end

function M.check_confirm(line, buf)
  local confirm = false
  if M.line_contains_option(line, "c") then
    confirm = true
  end
  local confirm_once = false
  if M.line_contains_option(line, "C") then
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
      if M.line_contains_option(line, "o")
      then
        vim.cmd('autocmd! BufWritePost <buffer> BuffRun')
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
