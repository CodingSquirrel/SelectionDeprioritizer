local SelectionDeprioritizer = import('/mods/SelectionDeprioritizer/modules/SelectionDeprioritizer.lua')
local Selection = import('/lua/ui/game/selection.lua')


local oldDeselectSelens = DeselectSelens
function DeselectSelens(selection)

	local oldChanged, changed = false, false
	local newSelection = selection
	newSelection, oldChanged = oldDeselectSelens(newSelection)

	newSelection, changed = SelectionDeprioritizer.Deselect(newSelection)

	--[[
		Do selection in here because the SelectUnits in FAF's OnSelectionChanged makes no noise. If that
		gets fixed, remove the call here.
	]]
	if oldChanged or changed then
		SelectUnits(newSelection)
		return newSelection, oldChanged or changed
	end

	return selection, false

end


local oldCreateUI = CreateUI
function CreateUI(isReplay) 
	oldCreateUI(isReplay)
	import('/mods/SelectionDeprioritizer/modules/SelectionDeprioritizerConfig.lua').init()
end
