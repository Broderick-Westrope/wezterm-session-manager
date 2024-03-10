local wezterm = require("wezterm")
local notification = require("wezterm-session-manager.notification")
local filesystem = require("wezterm-session-manager.filesystem")
local workspace = require("wezterm-session-manager.workspace")
local session_manager = {}

--- Loads the saved json file matching the current workspace.
function session_manager.restore_state(window)
	wezterm.log_info("Restoring session state")

	local workspace_name = window:active_workspace()
	local file_path = wezterm.home_dir
		.. "/.config/wezterm/wezterm-session-manager/wezterm_state_"
		.. workspace_name
		.. ".json"

	local workspace_data = filesystem.load_from_json_file(file_path)
	if not workspace_data then
		notification.display(window, "Workspace state file not found for workspace: " .. workspace_name)
		return
	end

	if workspace.recreate(window, workspace_data) then
		notification.display(window, "Workspace state loaded for workspace: " .. workspace_name)
	else
		notification.display(window, "Workspace state loading failed for workspace: " .. workspace_name)
	end
end

--- Allows to select which workspace to load
function session_manager.load_state(window)
	wezterm.log_info("Coming soon: Loading session state")
	-- TODO: Implement
	-- Placeholder for user selection logic
	-- ...
	-- TODO: Call the function recreate_workspace(workspace_data) to recreate the workspace
	-- Placeholder for recreation logic...
end

--- Orchestrator function to save the current workspace state.
-- Collects workspace data, saves it to a JSON file, and displays a notification.
function session_manager.save_state(window)
	wezterm.log_info("Saving session state")

	local data = workspace.retrieve(window)

	-- Construct the file path based on the workspace name
	local file_path = wezterm.home_dir
		.. "/.config/wezterm/wezterm-session-manager/wezterm_state_"
		.. data.name
		.. ".json"

	-- Save the workspace data to a JSON file and display the appropriate notification
	if filesystem.save_to_json_file(data, file_path) then
		notification.display(window, "Workspace state saved successfully.")
	else
		notification.display(window, "Failed to save workspace state.")
	end
end

return session_manager
