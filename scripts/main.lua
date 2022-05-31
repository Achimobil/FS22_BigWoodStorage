




---@type string directory of the mod.
local modDirectory = g_currentModDirectory or ""
---@type string name of the mod.
local modName = g_currentModName or "unknown"

---Init the mod.
local function init()
    g_placeableSpecializationManager:addSpecialization("aPalletSilo", "APalletSilo", modDirectory .. "scripts/aPalletSilo.lua", nil)
    print(modName .. " - init " .. APalletSilo.Name .. "(Version: " .. APalletSilo.Version .. ")");
    
    -- load event
    local path = modDirectory .. "scripts/SpawnPalletsAtSiloEvent.lua";
    source(path)
    
    g_placeableSpecializationManager:addSpecialization("siloObjectFillLevelSpezialisation", "SiloObjectFillLevelSpezialisation", modDirectory .. "scripts/siloObjectFillLevelSpezialisation.lua", nil)
    print(modName .. " - init " .. SiloObjectFillLevelSpezialisation.Name .. "(Version: " .. SiloObjectFillLevelSpezialisation.Version .. ")");
    
    g_placeableSpecializationManager:addSpecialization("siloDisplaySpezialisation", "SiloDisplaySpezialisation", modDirectory .. "scripts/siloDisplaySpezialisation.lua", nil)
    print(modName .. " - init " .. SiloDisplaySpezialisation.Name .. "(Version: " .. SiloDisplaySpezialisation.Version .. ")");
end

init()