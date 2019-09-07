## config 

-- starts enabled or not?
local isEnabled = true

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
	for id, unit in units do
		local isEx = isExotic(unit)
		local isExAs = isExoticAssist(unit)
		if isExAs then
		  isExAs = isAssisting(unit)
	  end
		
		if not isEx and not isExAs then
				table.insert(filtered, unit)
		end
	end
	return filtered
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
	for id, unit in units do
		local domain = getDomain(unit)
		if domain == requiredDomain then
			table.insert(filtered, unit)
		end
	end
	return filtered
end


local suppress = false
function OnSelectionChanged(oldSelection, newSelection, added, removed)

	if not isEnabled then 
		return false
	end

	if IsKeyDown('Shift') then
		return false
	end

	-- prevent inifite recursion
	if suppress then 
		Log("--OnSelectionChanged supressed")
		return false
	end

	Log("--OnSelectionChanged")

	local changesMade = false

	if filterDomains then 
		local domains = getDomains(newSelection)
		if domains.isMixed then
			Log("Mixed")
			domain = getFirstDomain(domains)
			if domain ~= nil then 
				Log("limit to " .. domain)
				newSelection = filterToDomain(newSelection, domain)
				changesMade = true
			end
		else
			Log("notmixed")
		end
	end


	if filterExotics then
		local isMixedExotic = isMixedExoticness(newSelection)
		if isMixedExotic then 
			newSelection = filterToRegulars(newSelection)
			changesMade = true
		end
	end
	
	if changesMade then 
		ForkThread(function() 
			suppress = true
			Log("--changing")
			SelectUnits(oldSelection)
			SelectUnits(newSelection)
			suppress = false
		end)	
	end

	return changesMade
end


-- if shift do nothing
-- selection contains mixed domains - filter to one domain
-- selection contains mix of exotics and regulars - filter to regulars