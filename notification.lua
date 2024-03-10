local wezterm = require("wezterm")

local Notification = {}

--- Displays a notification in WezTerm.
-- @param message string: The notification message to be displayed.
function Notification.display(window, message)
	wezterm.log_info(message)
	window:toast_notification("WezTerm Session Manager", message, nil, 5000)
	-- Additional code to display a GUI notification can be added here if needed
end

return Notification
