---Runtime fixes for Avante + Cursor ACP integration.
local M = {}

local api = vim.api
local PLANS_DIR = vim.fs.joinpath(vim.env.HOME, ".cursor", "plans")

local function yaml_quote(value)
  if value == nil then
    return "\"\""
  end
  return '"' .. tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function normalize_cursor_todo_status(status)
  if status == "in_progress" or status == "doing" then
    return "in_progress"
  end
  if status == "completed" or status == "done" then
    return "completed"
  end
  return "pending"
end

local function collect_plan_todos(params)
  local todos = {}
  for _, todo in ipairs(params.todos or {}) do
    table.insert(todos, todo)
  end
  for _, phase in ipairs(params.phases or {}) do
    for _, todo in ipairs(phase.todos or {}) do
      table.insert(todos, todo)
    end
  end
  return todos
end

local function build_plan_markdown(params)
  local name = params.name or "Plan"
  local overview = params.overview or ""
  local plan_body = params.plan or ""
  local is_project = params.isProject == true

  local lines = {
    "---",
    "name: " .. yaml_quote(name),
    "overview: " .. yaml_quote(overview),
    "todos:",
  }

  local todos = collect_plan_todos(params)
  for _, todo in ipairs(todos) do
    table.insert(lines, "  - id: " .. yaml_quote(todo.id or "todo"))
    table.insert(lines, "    content: " .. yaml_quote(todo.content or ""))
    table.insert(lines, "    status: " .. normalize_cursor_todo_status(todo.status))
  end

  table.insert(lines, "isProject: " .. (is_project and "true" or "false"))
  table.insert(lines, "---")
  table.insert(lines, "")
  table.insert(lines, "# " .. name)
  table.insert(lines, "")
  table.insert(lines, plan_body)

  return table.concat(lines, "\n")
end

local function make_plan_filename(params)
  local name = params.name or "plan"
  local sanitized = name:gsub("[/\\:*?\"<>|]", ""):match("^%s*(.-)%s*$") or "plan"
  local short_id = string.format("%08x", math.random(0, 0xffffffff))
  return sanitized .. "-" .. short_id .. ".plan.md"
end

local function write_cursor_plan_file(params)
  vim.fn.mkdir(PLANS_DIR, "p")
  local path = vim.fs.joinpath(PLANS_DIR, make_plan_filename(params))
  local content = build_plan_markdown(params)
  local ok, err = pcall(function()
    local file = io.open(path, "w")
    if not file then
      error("failed to open plan file for writing")
    end
    file:write(content)
    file:close()
  end)
  if not ok then
    return nil, err
  end
  return path
end

local function get_code_winid(sidebar)
  if sidebar and sidebar.code.winid and sidebar.code.winid ~= 0 and api.nvim_win_is_valid(sidebar.code.winid) then
    return sidebar.code.winid
  end
  if sidebar then
    for _, winid in ipairs(api.nvim_tabpage_list_wins(0)) do
      if api.nvim_win_is_valid(winid) and not sidebar:is_sidebar_winid(winid) then
        return winid
      end
    end
  end
  return api.nvim_get_current_win()
end

local function open_plan_file(path)
  vim.schedule(function()
    local abs_path = vim.fn.fnamemodify(path, ":p")
    if vim.fn.filereadable(abs_path) ~= 1 then
      return
    end

    local avante = require("avante")
    local sidebar = avante.get()
    local code_winid = get_code_winid(sidebar)

    api.nvim_win_call(code_winid, function()
      vim.cmd("vsplit " .. vim.fn.fnameescape(abs_path))
    end)

    local bufnr = vim.fn.bufnr(abs_path, false)
    if bufnr ~= -1 then
      pcall(function()
        require("render-markdown").enable(true, bufnr)
      end)
    end
  end)
end

local function map_cursor_todos(params)
  local todos = {}
  for idx, todo in ipairs(params.todos or {}) do
    local status = "todo"
    if todo.status == "in_progress" then
      status = "doing"
    elseif todo.status == "completed" then
      status = "done"
    end
    table.insert(todos, {
      id = todo.id or tostring(idx),
      content = todo.content,
      status = status,
    })
  end
  return todos
end

local function get_acp_mode_label(sidebar)
  local Config = require("avante.config")
  if not Config.acp_providers[Config.provider] then
    return nil
  end

  local acp_client = sidebar.acp_client
  if not acp_client or not acp_client.config_options then
    return nil
  end

  for _, opt in ipairs(acp_client.config_options) do
    if opt.category == "mode" then
      local current = opt.currentValue
      for _, val in ipairs(opt.options or {}) do
        if val.value == current then
          return val.name or current
        end
      end
      return current
    end
  end

  return nil
end

local function refresh_sidebar_headers(sidebar)
  if not sidebar or not sidebar:is_open() then
    return
  end
  sidebar:render_result()
  sidebar:render_input()
end

local ACTIVE_STREAM_STATES = {
  generating = true,
  thinking = true,
  ["tool calling"] = true,
  compacting = true,
}

local function clear_active_state_if_idle(sidebar)
  if not sidebar or sidebar._avante_stream_active then
    return
  end
  if sidebar.current_state and ACTIVE_STREAM_STATES[sidebar.current_state] then
    sidebar.current_state = nil
    sidebar:clear_state()
  end
end

local function patch_stream_lifecycle()
  local Llm = require("avante.llm")
  if Llm._cursor_stream_patched then
    return
  end
  Llm._cursor_stream_patched = true

  local orig_stream = Llm.stream
  Llm.stream = function(opts)
    local sidebar = require("avante").get()

    local orig_on_state = opts.on_state_change
    opts.on_state_change = function(state)
      if sidebar then
        sidebar._avante_stream_active = ACTIVE_STREAM_STATES[state] == true
      end
      if orig_on_state then
        orig_on_state(state)
      end
    end

    local orig_on_stop = opts.on_stop
    opts.on_stop = function(stop_opts)
      if orig_on_stop then
        orig_on_stop(stop_opts)
      end
      if sidebar then
        sidebar._avante_stream_active = false
        sidebar.current_state = nil
        sidebar:clear_state()
      end
    end

    return orig_stream(opts)
  end
end

local function patch_history_state()
  local Sidebar = require("avante.sidebar")
  if Sidebar._cursor_history_state_patched then
    return
  end
  Sidebar._cursor_history_state_patched = true

  local orig_add = Sidebar.add_history_messages
  Sidebar.add_history_messages = function(self, messages, opts)
    orig_add(self, messages, opts)
    clear_active_state_if_idle(self)
  end
end

local function patch_render_state()
  local Sidebar = require("avante.sidebar")
  if Sidebar._cursor_render_state_patched then
    return
  end
  Sidebar._cursor_render_state_patched = true

  local orig_render_state = Sidebar.render_state
  Sidebar.render_state = function(self)
    if not self._avante_stream_active then
      if self.current_state == "compacting" then
        return orig_render_state(self)
      end
      if self.current_state then
        self.current_state = nil
        self:clear_state()
      end
      return
    end
    return orig_render_state(self)
  end
end

local function patch_acp_client()
  local ACPClient = require("avante.libs.acp_client")
  if ACPClient._cursor_acp_patched then
    return
  end
  ACPClient._cursor_acp_patched = true

  local orig_handle_message = ACPClient._handle_message
  local orig_handle_notification = ACPClient._handle_notification
  local orig_handle_session_update = ACPClient._handle_session_update

  function ACPClient:_handle_cursor_ask_question(message_id, params)
    local questions = params.questions or {}
    if #questions == 0 then
      self:_send_result(message_id, { outcome = { outcome = "skipped", reason = "no questions" } })
      return
    end

    local avante = require("avante")
    if not avante.is_sidebar_open() then
      avante.open_sidebar({ ask = false })
    end

    local answers = {}
    local cancelled = false

    local function finish()
      if cancelled then
        self:_send_result(message_id, { outcome = { outcome = "cancelled" } })
      else
        self:_send_result(message_id, {
          outcome = { outcome = "answered", answers = answers },
        })
      end
    end

    local function ask_next(index)
      if cancelled or index > #questions then
        finish()
        return
      end

      local question = questions[index]
      local options = question.options or {}
      local labels = {}
      for _, opt in ipairs(options) do
        table.insert(labels, opt.label or opt.id or "")
      end

      if #labels == 0 then
        ask_next(index + 1)
        return
      end

      vim.ui.select(labels, {
        prompt = question.prompt or params.title or "Cursor agent question",
      }, function(_, idx)
        if idx == nil then
          cancelled = true
          finish()
          return
        end

        local selected = { options[idx].id }
        if question.allowMultiple then
          vim.notify(
            "Avante: multi-select question answered with one option; use Cursor IDE for full multi-select.",
            vim.log.levels.INFO,
            { title = "Avante" }
          )
        end

        table.insert(answers, {
          questionId = question.id,
          selectedOptionIds = selected,
        })
        ask_next(index + 1)
      end)
    end

    ask_next(1)
  end

  function ACPClient:_handle_cursor_create_plan(message_id, params)
    local avante = require("avante")
    if not avante.is_sidebar_open() then
      avante.open_sidebar({ ask = false })
    end

    local path, err = write_cursor_plan_file(params)
    if not path then
      vim.notify("Avante: failed to write plan file: " .. tostring(err), vim.log.levels.ERROR, { title = "Avante" })
      self:_send_result(message_id, {
        outcome = { outcome = "rejected", reason = "Failed to write plan file" },
      })
      return
    end

    local plan_uri = vim.uri_from_fname(path)
    local todos = map_cursor_todos({ todos = collect_plan_todos(params) })
    local sidebar = avante.get()
    if sidebar and #todos > 0 then
      vim.schedule(function()
        sidebar:update_todos(todos)
      end)
    end

    open_plan_file(path)
    vim.notify("Plan saved: " .. path, vim.log.levels.INFO, { title = "Avante" })

    self:_send_result(message_id, {
      outcome = {
        outcome = "accepted",
        planUri = plan_uri,
      },
    })
  end

  function ACPClient:_handle_server_request(message_id, method, params)
    if method == "cursor/ask_question" then
      self:_handle_cursor_ask_question(message_id, params)
    elseif method == "cursor/create_plan" then
      self:_handle_cursor_create_plan(message_id, params)
    elseif method == "session/request_permission" then
      self:_handle_request_permission(message_id, params)
    elseif method == "fs/read_text_file" then
      self:_handle_read_text_file(message_id, params)
    elseif method == "fs/write_text_file" then
      self:_handle_write_text_file(message_id, params)
    elseif method == "cursor/update_todos" or method == "cursor/task" or method == "cursor/generate_image" then
      self:_send_result(message_id, vim.NIL)
    else
      self:_send_error(
        message_id,
        "Method not implemented: " .. method,
        ACPClient.ERROR_CODES.METHOD_NOT_FOUND
      )
    end
  end

  function ACPClient:_handle_message(message)
    if message.method and message.id and not message.result and not message.error then
      self:_handle_server_request(message.id, message.method, message.params or {})
      return
    end
    return orig_handle_message(self, message)
  end

  function ACPClient:_handle_notification(message_id, method, params)
    if method == "cursor/update_todos" then
      local sidebar = require("avante").get()
      if sidebar and params.todos then
        vim.schedule(function()
          sidebar:update_todos(map_cursor_todos(params))
        end)
      end
      return
    end

    if method == "cursor/task" or method == "cursor/generate_image" then
      return
    end

    return orig_handle_notification(self, message_id, method, params)
  end

  function ACPClient:_handle_session_update(params)
    orig_handle_session_update(self, params)
    local update = params and params.update
    if
      update
      and (
        update.sessionUpdate == "config_option_update"
        or update.sessionUpdate == "current_mode_update"
      )
    then
      vim.schedule(function()
        refresh_sidebar_headers(require("avante").get())
      end)
    end
  end
end

local function patch_render_input()
  local Sidebar = require("avante.sidebar")
  if Sidebar._cursor_input_mode_patched then
    return
  end
  Sidebar._cursor_input_mode_patched = true

  local Config = require("avante.config")
  local Utils = require("avante.utils")
  local Highlights = require("avante.highlights")

  function Sidebar:render_input(ask)
    if ask == nil then
      ask = true
    end
    if not Utils.is_valid_container(self.containers.input) then
      return
    end

    local label = get_acp_mode_label(self)
    if not label then
      label = ask and "Ask" or "Chat with"
    end

    local header_text = string.format(
      "%s%s (" .. Config.mappings.sidebar.switch_windows .. ": switch focus)",
      Utils.icon("󱜸 "),
      label
    )

    if self.code.selection ~= nil then
      header_text = string.format(
        "%s%s (%d:%d) (%s: switch focus)",
        Utils.icon("󱜸 "),
        label,
        self.code.selection.range.start.lnum,
        self.code.selection.range.finish.lnum,
        Config.mappings.sidebar.switch_windows
      )
    end

    self:render_header(
      self.containers.input.winid,
      self.containers.input.bufnr,
      header_text,
      Highlights.THIRD_TITLE,
      Highlights.REVERSED_THIRD_TITLE
    )
  end
end

local function patch_acp_config_selector()
  local selector = require("avante.acp_config_selector")
  if selector._cursor_mode_refresh_patched then
    return
  end
  selector._cursor_mode_refresh_patched = true

  local orig_open = selector.open
  selector.open = function(category, prompt_label)
    orig_open(category, prompt_label)
    vim.defer_fn(function()
      refresh_sidebar_headers(require("avante").get())
    end, 300)
  end
end

local function patch_sidebar_extmarks()
  local Sidebar = require("avante.sidebar")
  if Sidebar._cursor_extmark_patched then
    return
  end
  Sidebar._cursor_extmark_patched = true

  local Config = require("avante.config")
  local Utils = require("avante.utils")
  local api = vim.api
  local TOOL_NS = api.nvim_create_namespace("AVANTE_TOOL_MESSAGE_KEYBINDING")
  local PRIORITY = (vim.hl or vim.highlight).priorities.user

  function Sidebar:render_tool_use_control_buttons()
    if not Utils.is_valid_container(self.containers.result) then
      return
    end

    local function show_current_tool_use_control_buttons()
      local bufnr = self.containers.result.bufnr

      if self.current_tool_use_extmark_id then
        pcall(api.nvim_buf_del_extmark, bufnr, TOOL_NS, self.current_tool_use_extmark_id)
      end

      local message_uuid, positions = self:get_current_tool_use_message_uuid()
      if not message_uuid or not positions then
        return
      end

      local expanded = self.expanded_message_uuids[message_uuid]
      local skip_line_count = self.skip_line_count or 0
      local line_num = skip_line_count + positions[1] + 2
      local max_line = math.max(0, api.nvim_buf_line_count(bufnr) - 1)
      if line_num < 0 or line_num > max_line then
        return
      end

      local ok, extmark_id = pcall(api.nvim_buf_set_extmark, bufnr, TOOL_NS, line_num, -1, {
        virt_text = {
          {
            string.format(
              " [%s: %s] ",
              Config.mappings.sidebar.expand_tool_use,
              expanded and "Collapse" or "Expand"
            ),
            "AvanteInlineHint",
          },
        },
        virt_text_pos = "right_align",
        hl_group = "AvanteInlineHint",
        priority = PRIORITY,
      })

      if ok then
        self.current_tool_use_extmark_id = extmark_id
      end
    end

    local current_tool_use_message_uuid = self:get_current_tool_use_message_uuid()
    if current_tool_use_message_uuid then
      show_current_tool_use_control_buttons()
      self:bind_expand_tool_use_key(current_tool_use_message_uuid)
    else
      api.nvim_buf_clear_namespace(self.containers.result.bufnr, TOOL_NS, 0, -1)
      self:unbind_expand_tool_use_key()
    end
  end
end

function M.apply()
  patch_stream_lifecycle()
  patch_history_state()
  patch_render_state()
  patch_acp_client()
  patch_render_input()
  patch_acp_config_selector()
  patch_sidebar_extmarks()
end

return M
