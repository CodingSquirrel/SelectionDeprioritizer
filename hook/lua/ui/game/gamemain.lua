local SelectionLock = import('/mods/SelectionDeprioritizer/modules/SelectionDeprioritizer.lua')

local oldOnSelectionChanged = OnSelectionChanged
function OnSelectionChanged(oldSelection, newSelection, added, removed)

	local selectionChanged = SelectionLock.OnSelectionChanged(oldSelection, newSelection, added, removed)
	if not selectionChanged then
		oldOnSelectionChanged(oldSelection, newSelection, added, removed)
	end

end


local KeyMapper = import('/lua/keymap/keymapper.lua')
KeyMapper.SetUserKeyAction('Toggle Selection Deprioritizer', {action = "UI_Lua import('/mods/SelectionDeprioritizer/modules/SelectionDeprioritizer.lua').ToggleEnabled()", category = 'Mods', order = 1,})
 