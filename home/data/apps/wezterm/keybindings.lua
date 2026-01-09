local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Leader: doesn't use Super/Alt, so it's WM-safe
M.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1200 }

-- Keys that are “always available”
M.keys = {
  -- (7) Search history / scrollback search overlay
  { key = "F", mods = "CTRL|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },

  -- (8) Copy / (9) Paste
  { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

  -- (12) Show tab navigator
  { key = "t", mods = "LEADER", action = act.ShowTabNavigator },

  -- (3) Open tab
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },

  -- (2) Close focused tab
  { key = "x", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },

  -- (1) Switch tabs using vim binds (h/l)
  { key = "h", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "l", mods = "LEADER", action = act.ActivateTabRelative(1) },

  -- (6) Move focused tab left/right
  { key = "H", mods = "LEADER|SHIFT", action = act.MoveTabRelative(-1) },
  { key = "L", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },

  -- (4) Split focused pane vertically  (i.e., left/right panes)
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- (5) Split focused pane horizontally (i.e., top/bottom panes)
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

  -- Enter copy mode quickly (14)
  { key = "y", mods = "LEADER", action = act.ActivateCopyMode },

  -- Enter search mode while in copy mode (we also bind a direct one for convenience)
  -- This opens the search overlay immediately.
  { key = "/", mods = "LEADER", action = act.Search("CurrentSelectionOrEmptyString") },

-- Direct pane switching (no leader; vim-style)
{ key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
{ key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
{ key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
{ key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") },

  -- (11) Rename tab
  {
    key = "E",
    mods = "LEADER|SHIFT",
    action = act.PromptInputLine({
      description = "Enter new name for tab",
      action = wezterm.action_callback(function(window, pane, line)
        if line then window:active_tab():set_title(line) end
      end),
    }),
  },

  -- (13/14) A real “mode”: resize pane key table
  {
    key = "r",
    mods = "LEADER",
    action = act.ActivateKeyTable({
      name = "resize_pane",
      one_shot = false,
      timeout_milliseconds = 3000,
      replace_current = false,
    }),
  },
}

-- Key tables (modes)
M.key_tables = {
  resize_pane = {
    { key = "h", action = act.AdjustPaneSize({ "Left",  1 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up",    1 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down",  1 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "q",      action = "PopKeyTable" },
  },

  -- Copy mode: vi-like navigation + selection + yank
  copy_mode = {
    -- exit
    { key = "Escape", mods = "NONE", action = act.Multiple({ act.ClearSelection, act.CopyMode("Close") }) },
    { key = "q",      mods = "NONE", action = act.CopyMode("Close") },

    -- move
    { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
    { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
    { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
    { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },

    -- scrollback extremes
    { key = "g", mods = "NONE",  action = act.CopyMode("MoveToScrollbackTop") },
    { key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },

    -- selection
    { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
    { key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },

    -- copy/yank selection and exit
    {
      key = "y",
      mods = "NONE",
      action = act.Multiple({
        act.CopyTo("ClipboardAndPrimarySelection"),
        act.CopyMode("Close"),
      }),
    },

    -- search within copy mode
    { key = "/", mods = "NONE", action = act.Search("CurrentSelectionOrEmptyString") },
    { key = "n", mods = "NONE", action = act.CopyMode("NextMatch") },
    { key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") },
  },

  -- Search mode tweaks are optional; leaving a minimal set
  search_mode = {
    { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
    { key = "Enter",  mods = "NONE", action = act.ActivateCopyMode },
    { key = "n",      mods = "CTRL", action = act.CopyMode("NextMatch") },
    { key = "p",      mods = "CTRL", action = act.CopyMode("PriorMatch") },
  },
}


return M
