## config 

-- starts enabled or not?
local isEnabled = true

-- filter all assisters or not?
local filterAssisters = true

-- filter by domain or not?
local filterDomains = true
local domainCategories = { "NAVAL", "LAND", "AIR" }

-- filter by exotics or not?
local filterExotics = true
local exoticBlueprintIds = { 

	"xrl0302", -- fire beetle

	"ual0304", -- Serenity
	"url0304", -- Trebuchet
	"xsl0304", -- Suthanus
	"uel0304", -- Demolisher
	"dal0310", -- Absolver
	"xel0306", -- Spearhead

	"xal0305", -- Sprite Striker
	"xsl0305", -- Usha-Ah

	"dra0202", -- Corsair
	"daa0206", -- Mercy

	-- torp bombers
	"uaa0204", -- Skimmer
	"ura0204", -- Cormorant
	"xsa0204", -- Uosioz
	"uea0204", -- Stork
	"xaa0306", -- Solace

	-- strat bombers
	"uaa0304", -- Shocker
	"ura0304", -- Revenant
	"xsa0304", -- Sinntha
	"uea0304", -- Ambassador

	-- aircraft carriers
	"uas0303", -- Keefer Class
	"urs0303", -- Command Class
	"xss0303", -- Iavish

	-- strat subs
	"uas0304", -- Silencer
	"urs0304", -- Plan B
	"ues0304", -- Ace

	-- missile ship
	"xas0306", -- Torrent Class

	-- t3 sonar
	"uas0305", -- aeon
	"urs0305", -- Flood XR
	"ues0305" -- SP3 - 3000
 } 

 local exoticAssistBlueprintIds = { 
    -- t1 scouts
	"ual0101", --Spirit
	"url0101", --Mole
	"xsl0101", --Selen
	"uel0101", --Snoop
	
    -- mobile shields
    "xsl0307", --Athanah
	"uel0307", --Parashield
	"ual0307", --Asylum
	
	"url0306" --Deceiver
 } 
 
## end config





local logEnabled = false
function Log(msg)
	if logEnabled then
		LOG(msg)
	end
end


Log("Selection Deprioriziter Initializing..")

function ToggleEnabled()
	isEnabled = not isEnabled

	if isEnabled then
		print("Selection Deprioriziter - ENABLED")
	else
		print("Selection Deprioriziter - DISABLED")
	end
end
 

function arrayContains(arr, val)
	for i, v in ipairs(arr) do
		if v == val then 
			return true
		end
	end
	return false
end


function isExotic(unit)
	local blueprintId = unit:GetBlueprint().BlueprintId
	local isEx = arrayContains(exoticBlueprintIds, blueprintId)
	Log(blueprintId .. " = " .. tostring(isEx))
	return isEx
end


function isExoticAssist(unit)
	local blueprintId = unit:GetBlueprint().BlueprintId
	local isExAs = arrayContains(exoticAssistBlueprintIds, blueprintId)
	Log(blueprintId .. " = " .. tostring(isExAs))
	return isExAs
end


function isMixedExoticness(units)
	local exoticFound
	local regularFound
	for entityid, unit in units do
		local isEx = isExotic(unit)
		local isExAs = isExoticAssist(unit) 
		if isEx or isExAs then
			exoticFound = true
		else
			regularFound = true
		end
	end

	return exoticFound and regularFound
end


function isAssisting(unit)
	local guardedUnits = unit:GetGuardedEntity()
	return guardedUnits ~= nil
end


function filterToRegulars(units)
	local filtered = {}
	local changed = false
	for id, unit in units do
		local isEx = isExotic(unit)
		local isExAs = isExoticAssist(unit)
		if isExAs then
			isExAs = isAssisting(unit)
		end
		
		if not isEx and not isExAs then
			table.insert(filtered, unit)
		else
			changed = true
		end
	end
	return filtered, changed
end


function getDomain(unit)	
	for i, domain in ipairs(domainCategories) do
		if unit:IsInCategory(domain) then 
			return domain
		end
	end
end


function getDomains(units)
	local domains = {}
	for entityid, unit in units do
		local domain = getDomain(unit)		
		if domain ~= nil then 
			domains[domain] = true
		end
	end

	domains.count = 0
	for i, domain in ipairs(domainCategories) do
		if domains[domain] ~= nil then 
			domains.count = domains.count + 1
		end
	end

	domains.isMixed = domains.count > 1

	return domains
end


function getFirstDomain(domains)
	for i, domain in ipairs(domainCategories) do
		if domains[domain] ~= nil then 
			return domain
		end
	end
	return nil
end


function filterToDomain(units, requiredDomain)
	local filtered = {}
	local changed = false
	for id, unit in units do
		local domain = getDomain(unit)
		if domain == requiredDomain then
			table.insert(filtered, unit)
		else
			changed = true
		end
	end
	return filtered, changed
end


local dblClickStart = false
local dblClickUnit = nil
function isDoubleclick(selection)
	-- a double click is if
	--   the first click is just one unit
	--   and the second click contains the same unit

	local result = false
	if dblClickStart then
		dblClickStart = false
		for index, unit in selection do
			if unit == dblClickUnit then
				Log("Double Click")
				result = true
			end
		end
	end

	dblClickStart = table.getn(selection) == 1
	if dblClickStart then
		Log("Double Click start?")
		for index, unit in selection do
			dblClickUnit = unit
		end
	end

	return result
end


function filterToNonAssisters(selection)
	local changed = false
	local filtered = {}

	-- if its a double click on an assister, select all fellow assisters
	if isDoubleclick(selection) and dblClickUnit:GetGuardedEntity() then
		Log("-- double click detected")

		for index, unit in selection do
			local isSame = unit:GetGuardedEntity() == dblClickUnit:GetGuardedEntity()

			if isSame then
				Log("found a brother")
				table.insert(filtered,unit)
			else
				changed = true
				Log("didnt find brother")
			end
		end
	else
		if selection and table.getn(selection) > 1 then
			local guardedUnit = selection[1]:GetGuardedEntity()
			local allSame = true
			for index, unit in selection do
				if unit:GetGuardedEntity() then
					Log("found assister")
					if unit:GetGuardedEntity() != guardedUnit then
						allSame = false
					end
					changed = true
				else
					allSame = false
					Log("not an assister")
					table.insert(filtered,unit)
				end
			end

			if allSame then
				changed = false
			end
		end
	end

	if changed then
		return filtered, changed
	else
		return selection, false
	end
end



function Deselect(selection)

	if IsKeyDown('Shift') then
		return selection, false
	end

	local changed, domainChanged, exoticChanged, assistersChanged

	if filterDomains then 
		local domains = getDomains(selection)
		if domains.isMixed then
			Log("Mixed Domains")
			domain = getFirstDomain(domains)
			if domain ~= nil then 
				Log("limit to " .. domain)
				selection, domainChanged = filterToDomain(selection, domain)
			end
		else
			Log("Not Mixed Domains")
		end
	end


	if filterExotics then
		local isMixedExotic = isMixedExoticness(selection)
		if isMixedExotic then
			Log("Mixed Exotic")
			selection, exoticChanged = filterToRegulars(selection)
		else
			Log("Not Mixed Exotic")
		end
	end

	if filterAssisters then
		Log("Filter Assisters")
		selection, assistersChanged = filterToNonAssisters(selection)
	end

	changed = domainChanged or exoticChanged or assistersChanged

	return selection, changed
end


-- if shift do nothing
-- selection contains mixed domains - filter to one domain
-- selection contains mix of exotics and regulars - filter to regulars