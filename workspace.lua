local wezterm = require("wezterm")

local Workspace = {}

--- Retrieves the current workspace data from the active window.
-- @return table or nil: The workspace data table or nil if no active window is found.
function Workspace.retrieve(window)
	local workspace_name = window:active_workspace()
	local workspace_data = {
		name = workspace_name,
		tabs = {},
	}

	-- Iterate over tabs in the current window
	for _, tab in ipairs(window:mux_window():tabs()) do
		local tab_data = {
			tab_id = tostring(tab:tab_id()),
			panes = {},
		}

		-- Iterate over panes in the current tab
		for _, pane_info in ipairs(tab:panes_with_info()) do
			-- Collect pane details, including layout and process information
			table.insert(tab_data.panes, {
				pane_id = tostring(pane_info.pane:pane_id()),
				index = pane_info.index,
				is_active = pane_info.is_active,
				is_zoomed = pane_info.is_zoomed,
				left = pane_info.left,
				top = pane_info.top,
				width = pane_info.width,
				height = pane_info.height,
				pixel_width = pane_info.pixel_width,
				pixel_height = pane_info.pixel_height,
				cwd = tostring(pane_info.pane:get_current_working_dir()),
				tty = tostring(pane_info.pane:get_foreground_process_name()),
			})
		end

		table.insert(workspace_data.tabs, tab_data)
	end

	return workspace_data
end

--- Recreates the workspace based on the provided data.
-- @param workspace_data table: The data structure containing the saved workspace state.
function Workspace.recreate(window, workspace_data)
	if not workspace_data or not workspace_data.tabs then
		wezterm.log_info("Invalid or empty workspace data provided.")
		return
	end

	local tabs = window:mux_window():tabs()

	if #tabs ~= 1 or #tabs[1]:panes() ~= 1 then
		wezterm.log_info(
			"Restoration can only be performed in a window with a single tab and a single pane, to prevent accidental data loss."
		)
		return
	end

	local initial_pane = window:active_pane()
	local foreground_process = initial_pane:get_foreground_process_name()

	-- Check if the foreground process is a shell
	if
		foreground_process:find("sh")
		or foreground_process:find("cmd.exe")
		or foreground_process:find("powershell.exe")
		or foreground_process:find("pwsh.exe")
	then
		-- Safe to close
		initial_pane:send_text("exit\r")
	else
		wezterm.log_info("Active program detected. Skipping exit command for initial pane.")
	end

	-- Recreate tabs and panes from the saved state
	-- should work for windows and linux
	local is_windows = wezterm.target_triple:find("windows") ~= nil

	for i, tab_data in ipairs(workspace_data.tabs) do
		local cwd_uri = tab_data.panes[1].cwd
		local cwd_path

		if is_windows then
			-- On Windows, transform 'file:///C:/path/to/dir' to 'C:/path/to/dir'
			cwd_path = cwd_uri:gsub("file:///", "")
		else
			-- On Linux, transform 'file:///path/to/dir' to '/path/to/dir'
			cwd_path = cwd_uri:gsub("file://", "")
		end

		local new_tab = window:mux_window():spawn_tab({ cwd = cwd_path })

		if not new_tab then
			wezterm.log_info("Failed to create a new tab.")
			break
		end

		-- Activate the new tab before creating panes
		new_tab:activate()

		-- Recreate panes within this tab
		for j, pane_data in ipairs(tab_data.panes) do
			local new_pane
			if j == 1 then
				new_pane = new_tab:active_pane()
			else
				local direction = "Right"
				if pane_data.left == tab_data.panes[j - 1].left then
					direction = "Bottom"
				end

				new_pane =
					new_tab:active_pane():split({ direction = direction, cwd = pane_data.cwd:gsub("file:///", "") })
			end

			if not new_pane then
				wezterm.log_info("Failed to create a new pane.")
				break
			end

			-- Restore TTY for Neovim on Linux
			-- NOTE: cwd is handled differently on windows. maybe extend functionality for windows later
			-- This could probably be handled better in general
			if not is_windows and pane_data.tty == "/usr/bin/nvim" then
				new_pane:send_text(pane_data.tty .. " ." .. "\n")
			end
		end
	end

	wezterm.log_info("Workspace recreated with new tabs and panes based on saved state.")
	return true
end

return Workspace
