




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
end

init()