--
-- KITTY RUNNER
--

local config = require("kitty-runner.config")
local fn = vim.fn
local loop = vim.loop

local M = {}

local whole_command
local runner_is_open = false

local function send_kitty_command(cmd_args, command)
      local args = {"@", 'send-text', '-m', 'title:' .. config['runner_name'], command}
--      table.insert(args, 'send-text')
--      table.insert(args, '-m')
--      table.insert(args,'title:' .. config['runner_name'])
--      table.insert(args, command)
      loop.spawn('kitty' , {
        args = args
      }, function(code, signal) -- on exit
              print("send exit code", code)
              print("send exit signal", signal)
          end)
    print(vim.inspect(args))
end

local function open_and_or_send(command)
  if runner_is_open == true then
    send_kitty_command(config['run_cmd'], command)
  else
    M.open_runner()
    -- TODO: fix this hack
    os.execute("sleep 0.5")
    send_kitty_command(config['run_cmd'], command)
  end
end

local function prepare_command(region)
  local lines
  if region[1] == 0 then
    lines = vim.api.nvim_buf_get_lines(0, vim.api.nvim_win_get_cursor(0)[1]-1, vim.api.nvim_win_get_cursor(0)[1], true)
  else
    lines = vim.api.nvim_buf_get_lines(0, region[1]-1, region[2], true)
  end
  local command = table.concat(lines, '\r') .. '\r'
  return command
end

function M.open_runner()
  if runner_is_open == false then
    loop.spawn('kitty', {
      args = {'@', 'new-window', '--keep-focus', '--title=' .. config['runner_name']}},
        function(code, signal) -- on exit
          print("exit code", code)
          print("exit signal", signal)
      end)
    runner_is_open = true
    end
end

function M.run_command(region)
  whole_command = prepare_command(region)
  -- delete visual selection marks
  vim.cmd([[delm <>]])
  open_and_or_send(whole_command)
end

function M.re_run_command()
  if whole_command then
    open_and_or_send(whole_command)
  end
end

function M.prompt_run_command()
  fn.inputsave()
  local command = fn.input("Command: ")
  fn.inputrestore()
  whole_command = command .. '\r'
  open_and_or_send(whole_command)
end

function M.kill_runner()
  if runner_is_open == true then
    send_kitty_command(config['kill_cmd'], nil)
    runner_is_open = false
  end
end

function M.clear_runner()
  if runner_is_open == true then
    send_kitty_command(config['run_cmd'], '')
  end
end


return M
