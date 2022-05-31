--[[
Copyright (C) Achimobil & braeven, 2022

Author: Achimobil (Base and pallets) / braeven (bales)
Date: 10.05.2022
Version: 2.2.0.0

Contact:
https://forum.giants-software.com
https://discord.gg/Va7JNnEkcW

History:
V 1.0.0.0 @ 15.01.2022 - Release Version.
V 1.1.0.0 @ 17.01.2022 - Make pallet string translatable in mod
V 2.0.0.0 @ 07.02.2022 - Add possibility to export Bales.
V 2.1.0.0 @ 09.05.2022 - Add total amount of selected quantity in dialog
V 2.1.1.0 @ 10.05.2022 - Add Version and Name for main.lua
V 2.2.0.0 @ 10.05.2022 - Add name and filllevel to next dialogs

Important:
Free for use in other mods - no permission needed, only provide my name.
No changes are to be made to this script without permission from Achimobil.

Frei verwendbar - keine erlaubnis nötig, Namensnennung im Mod erforderlich.
An diesem Skript dürfen ohne Genehmigung von Achimobil keine Änderungen vorgenommen werden.
]]



APalletSilo = {
    Version = "2.2.0.0",
    Name = "APalletSilo"
}

PalletSiloActivatable = {}

local PalletSiloActivatable_mt = Class(PalletSiloActivatable, Object)

---Creates a new instance of the class
-- @param bool isServer true if we are server
-- @param bool isClient true if we are client
-- @param table customMt meta table
-- @return table self returns the instance
function PalletSiloActivatable.new(placable, isServer, customMt)
    local self = Object.new(isServer, isClient, customMt or PalletSiloActivatable_mt)

    self.placable = placable
    self.activateText = g_i18n:getText("ExtractPallets");

    return self
end

---Called when press activate. In the test cases there were no parameters
function PalletSiloActivatable:run()    
    local spec = self.placable.spec_aPalletSilo
    
    local availableItemsInStorages = {};
    
    -- was liegt im Lager?
    for _, storage in pairs (self.placable.spec_silo.storages) do
        for fillTypeIndex, fillLevel in pairs (storage.fillLevels) do
            if (fillLevel > 1) then
                if availableItemsInStorages[fillTypeIndex] == nil then
                    availableItemsInStorages[fillTypeIndex] = {};
                    availableItemsInStorages[fillTypeIndex].fillTypeIndex = fillTypeIndex;
                    availableItemsInStorages[fillTypeIndex].fillLevel = 0;
                    
                    -- name in meiner Sprache holen
                    availableItemsInStorages[fillTypeIndex].title = g_currentMission.fillTypeManager.fillTypes[fillTypeIndex].title
                end
                
                local currentAvailableItem = availableItemsInStorages[fillTypeIndex];
                currentAvailableItem.fillLevel = currentAvailableItem.fillLevel + fillLevel;
            end
        end
    end
    
    -- umsortieren, damit die beiden listen den gleichen index haben
    local selectableOptions = {}
    local options = {};
    
    for _, availableItem in pairs (availableItemsInStorages) do
        table.insert(selectableOptions, availableItem);
        table.insert(options, availableItem.title .. " (" .. math.floor(availableItem.fillLevel) .. " l)");
    end
    
    
    -- Wählen was ausgelagert werden soll aus dem was da ist
    local dialogArguments = {
        text = g_i18n:getText("ChooseWhatToPutOut"),
        title = self.placable:getName(),
        options = options,
        target = self,
        args = selectableOptions,
        callback = self.fillTypeSelected
    }
    
    --TODO: hack to reset the "remembered" option (i.e. solve a bug in the game engine)
    local dialog = g_gui.guis["OptionDialog"]
    if dialog ~= nil then
        dialog.target:setOptions({""}) -- Add fake option to force a "reset"
    end

    g_gui:showOptionDialog(dialogArguments)
end

function PalletSiloActivatable:LoadBaleTypes()
      local baleTypes = { }
    
	  -- Ballenliste erstellen in Abhängig vom Filltype, mögliche Ballen werden in Size hinterlegt als weitere Liste
      for index, baleType in ipairs(g_baleManager.bales) do
	  
		  --Sollte ein Ballen den Flag isAvaible auf false haben ist er für eine Karte deaktiviert, wie z.B. der packedsquareBale120/Multibale
          if baleType.isAvailable then
              for index, baleFillType in ipairs(baleType.fillTypes) do
                  local fillType = g_fillTypeManager:getFillTypeByIndex(baleFillType.fillTypeIndex)
                  local fillTypeName = fillType.name
                
				  --BallenTypen in Abhängigkeit vom Filltype
                  baleTypes[fillTypeName] = baleTypes[fillTypeName] or {
                      fillTypeIndex = baleFillType.fillTypeIndex,
                      fillTypeTitle = fillType.title,
                      fillTypeName = fillTypeName,
                      sizes = {},
                  }

                  local baleSizes = baleTypes[fillTypeName].sizes
  
                  --Mögliche Ballenformate
                  baleSizes[#baleSizes + 1] = {
                      isRoundbale = baleType.isRoundbale,
                      diameter = baleType.diameter,
                      width = baleType.width,
                      height = baleType.height,
                      length = baleType.length,
                      capacity = baleFillType.capacity,
                      wrapState = true and (fillTypeName:upper() == "SILAGE")
                  }
              end
         end
      end
      self.baleTypes = baleTypes
  end

---
function PalletSiloActivatable:fillTypeSelected(selectedOption, args)
    local spec = self.placable.spec_aPalletSilo

    -- parameter auswerten
    local selectedArg = args[selectedOption];
    if selectedArg == nil then return end
    local fillTypeIndex = selectedArg.fillTypeIndex;
    
	-- Ballen Übersicht laden falls noch nicht geladen
    if self.baleTypes == nil then
        self:LoadBaleTypes()
		-- print("loaded Bales")
    end	
	
	-- Liste Überprüfen ob ein Filltype in der Ballen-Liste auftaucht
	-- Sollte kein Ballen vorhanden sein, wie Palette behandeln, ansonsten Ballenliste weiter auswerten
	local currentFillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        
	if self.baleTypes[currentFillType.name] == nil then
	  -- Werte für Spawner definieren
      spec.fillTypeIndex = fillTypeIndex;
      spec.fillUnitIndex = 1;
      spec.pendingLiters = selectedArg.fillLevel;
	
      -- Berechnen der maximalen Palettenanzahl
      local amountPerPallet = spec.palletSpawner.fillTypeIdToPallet[fillTypeIndex].capacity;
      local maxPallets = math.floor(selectedArg.fillLevel / amountPerPallet)
      if ((selectedArg.fillLevel - (maxPallets*amountPerPallet)) >= 1) then
          maxPallets = maxPallets + 1;
      end
    
      if(maxPallets == 0) then return end
    
      -- auswählbare palettenanzahl in liste eintragen
      local selectableOptions = {}
      local options = {};
      for i=1, maxPallets do
          table.insert(selectableOptions, {amount=i, amountPerPallet=amountPerPallet});
          table.insert(options, i .. " " .. g_i18n:getText("PalletSiloItem") .. " (" ..g_i18n:formatVolume(amountPerPallet * i, 0) .. ")");
      end
    
          -- Wählen wieviel ausgelagert werden soll.
      local dialogArguments = {
          text = g_i18n:getText("ChooseAmountToPutOut") .. " - " .. currentFillType.title .. " (" .. g_i18n:formatVolume(selectedArg.fillLevel, 0) .. ")",
          title = self.placable:getName(),
          options = options,
          target = self,
          args = selectableOptions,
          callback = self.amountSelected
      }
    
      --TODO: hack to reset the "remembered" option (i.e. solve a bug in the game engine)
      local dialog = g_gui.guis["OptionDialog"]
      if dialog ~= nil then
          dialog.target:setOptions({""}) -- Add fake option to force a "reset"
      end
	  
	  g_gui:showOptionDialog(dialogArguments)
      
	else
	  baleType = self.baleTypes[currentFillType.name]
      local selectableOptions = {}
      local options = {};
	  
	  -- BallenVarianten in Optionsliste eintragen mit den entsprechenden Daten, Options = AnzeigeName, selectableObtion = Übermittelte Werte
      for index, baleSize in ipairs(baleType.sizes) do
          local title
          if baleSize.isRoundbale then
              title = g_i18n:getText("fillType_roundBale") .. " " .. tostring(baleSize.diameter) .. "m (" .. tostring(baleSize.capacity) .. "L)"
          else
              title = g_i18n:getText("fillType_squareBale") .. " " .. tostring(baleSize.length) .. "m (" .. tostring(baleSize.capacity) .. "L)"
          end
		  table.insert(selectableOptions, {fillTypeIndex=fillTypeIndex, baleSize=baleSize, fillLevel=selectedArg.fillLevel});
		  table.insert(options, title);
      end
	  
      -- Dialogbox erstellen welcher Ballen ausgelagert werden soll
      local dialogArguments = {
          text = g_i18n:getText("ChooseBaleType") .. " - " .. currentFillType.title .. " (" .. g_i18n:formatVolume(selectedArg.fillLevel, 0) .. ")",
          title = self.placable:getName(),
          options = options,
          target = self,
          args = selectableOptions,
          callback = self.baleSelected
      }
    
      --TODO: hack to reset the "remembered" option (i.e. solve a bug in the game engine)
      local dialog = g_gui.guis["OptionDialog"]
      if dialog ~= nil then
          dialog.target:setOptions({""}) -- Add fake option to force a "reset"
      end
	  
	  g_gui:showOptionDialog(dialogArguments)
	  
	end
	  
  end

function PalletSiloActivatable:baleSelected(selectedOption, args)
    local spec = self.placable.spec_aPalletSilo

    --Parameter auslesen
    local selectedArg = args[selectedOption];
    if selectedArg == nil then return end
    local fillTypeIndex = selectedArg.fillTypeIndex;
	local baleSize = selectedArg.baleSize;
	local size = selectedArg.baleSize;
	local amountPerBale = size.capacity
	
					  
    -- Werte für spawner definieren
    spec.fillTypeIndex = fillTypeIndex;
    spec.fillUnitIndex = 1;
    spec.pendingLiters = selectedArg.fillLevel;
    
    -- Berechnen der maximalen Ballenanzahl
    local maxBales = math.floor(selectedArg.fillLevel / amountPerBale)
    if ((selectedArg.fillLevel - (maxBales*amountPerBale)) >= 1) then
        maxBales = maxBales + 1;
    end
    
    if(maxBales == 0) then return end
    
    -- Auswählbare Ballenanzahl in Liste eintragen
    local selectableOptions = {}
    local options = {};
    for i=1, maxBales do
        table.insert(selectableOptions, {amount=i, amountPerPallet=amountPerBale, fillTypeIndex=fillTypeIndex, baleSize=baleSize});
        table.insert(options, i .. " " .. g_i18n:getText("BaleSiloItem") .. " (" ..g_i18n:formatVolume(amountPerBale*i, 0) .. ")");
    end
    
    local currentFillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    
    -- Dialog Optionen Anlegen
    local dialogArguments = {
        text = g_i18n:getText("ChooseAmountToPutOut") .. " - " .. currentFillType.title .. " (" .. g_i18n:formatVolume(selectedArg.fillLevel, 0) .. ")",
        title = self.placable:getName(),
        options = options,
        target = self,
        args = selectableOptions,
        callback = self.spawnBales
    }
    
    --TODO: hack to reset the "remembered" option (i.e. solve a bug in the game engine)
    local dialog = g_gui.guis["OptionDialog"]
    if dialog ~= nil then
        dialog.target:setOptions({""}) -- Add fake option to force a "reset"
    end

    g_gui:showOptionDialog(dialogArguments)
end

function PalletSiloActivatable:amountSelected(selectedOption, args)
    local spec = self.placable.spec_aPalletSilo

    -- anzahl möglicher palleten für eine neue Auswahl
    local selectedArg = args[selectedOption];
    if selectedArg == nil then return end
    local totalAmount = selectedArg.amount * selectedArg.amountPerPallet;
    
    -- todo: Anzahl paletten wählen
    spec.pendingLiters = math.min(spec.pendingLiters, totalAmount);
    
    SpawnPalletsAtSiloEvent.sendEvent(self.placable, self.placable.ownerFarmId, spec.fillUnitIndex, spec.pendingLiters, spec.fillTypeIndex, false, false, 0, 0, 0, 0, 0, false)
    
end

function PalletSiloActivatable:spawnBales(selectedOption, args)
    local spec = self.placable.spec_aPalletSilo

    -- Anzahl möglicher Ballen für eine neue Auswahl
    local selectedArg = args[selectedOption];
    if selectedArg == nil then return end

    --EntnahmeMenge berechnen
    local totalAmount = selectedArg.amount * selectedArg.baleSize.capacity;
    
    spec.pendingLiters = math.min(spec.pendingLiters, totalAmount);
	
	--BallenDaten hinterlegen für sendevent
    spec.isBale = true
	spec.isRoundbale = selectedArg.baleSize.isRoundbale
	spec.width = selectedArg.baleSize.width
	spec.height = selectedArg.baleSize.height
	spec.length = selectedArg.baleSize.length
	spec.diameter = selectedArg.baleSize.diameter
	
	--Damit das gesammt FillVolume ausgelager werden kann, überprüfen ob der Ballen größer ist als der restliche Inhalt und anpassen
    if spec.pendingLiters < selectedArg.baleSize.capacity then
	  spec.capacity = spec.pendingLiters
	else
	  spec.capacity = selectedArg.baleSize.capacity
    end
	spec.wrapState = selectedArg.baleSize.wrapState

    SpawnPalletsAtSiloEvent.sendEvent(self.placable, self.placable.ownerFarmId, spec.fillUnitIndex, spec.pendingLiters, spec.fillTypeIndex, spec.isBale, spec.isRoundbale, spec.width, spec.height, spec.length, spec.diameter, spec.capacity, spec.wrapState)
    
end

---
function PalletSiloActivatable:getPalletCallback(pallet, result, fillTypeIndex)
    local spec = self.placable.spec_aPalletSilo
    spec.spawnPending = false
    if pallet ~= nil then
		local delta = 0
		--Nur ausführen sollte es eine Palette sein
		if pallet.isBale == nil then
          if result == PalletSpawner.RESULT_SUCCESS then
              pallet:emptyAllFillUnits(true)
          end

          delta = pallet:addFillUnitFillLevel(self.placable.ownerFarmId, spec.fillUnitIndex, spec.pendingLiters, fillTypeIndex, ToolType.UNDEFINED)
          spec.pendingLiters = math.max(spec.pendingLiters - delta, 0)
		else
		  --Ausführen um FillVolume aus Silo entfernen zu können
		  delta = pallet.capacity
		  spec.pendingLiters = math.max(spec.pendingLiters - delta, 0)
		end
        
        -- Filllevel aus Silo abziehen
        for _, storage in ipairs(self.placable.spec_silo.storages) do
            local available = storage.fillLevels[fillTypeIndex];
            if available ~= null and available > 0 then
                local moved = math.min(delta, available)
                storage:setFillLevel(available - moved, fillTypeIndex)

                delta = delta - moved
            end

            if delta <= 0.001 then
                break
            end
        end
        
        if spec.pendingLiters > 5 then
		    --Damit das gesammt FillVolume ausgelager werden kann, überprüfen ob der Ballen größer ist als der restliche Inhalt und anpassen
			if pallet.isBale and spec.pendingLiters < pallet.capacity then
			  pallet.capacity = spec.pendingLiters
			end
            self:updatePallets(pallet)
        end
    end
end

---
function PalletSiloActivatable:updatePallets(bale)
    if self.isServer then
        local spec = self.placable.spec_aPalletSilo
        if not spec.spawnPending and spec.pendingLiters > 5 then
            spec.spawnPending = true
            if bale.isBale == nil then
              spec.palletSpawner:spawnPallet(self.placable.ownerFarmId, spec.fillTypeIndex, self.getPalletCallback, self)
			else
			  spec.palletSpawner:spawnPallet(self.placable.ownerFarmId, spec.fillTypeIndex, self.getPalletCallback, self, bale.isBale, bale.isRoundbale, bale.width, bale.height, bale.length, bale.diameter, bale.capacity, bale.wrapState)
			end
        end
    end
end

---
function APalletSilo.prerequisitesPresent(specializations)
    return true
end

---
function APalletSilo.initSpecialization()    
    local schema = Placeable.xmlSchema
    schema:setXMLSpecializationType("APalletSilo")
    
    local baseXmlPath = "placeable.aPalletSilo"
    
    schema:register(XMLValueType.NODE_INDEX, baseXmlPath .. "#triggerNode", "Trigger node for access menu")
    PalletSpawner.registerXMLPaths(schema, baseXmlPath .. ".palletSpawner")

    schema:setXMLSpecializationType()
    
    PlaceableSilo.INFO_TRIGGER_NUM_DISPLAYED_FILLTYPES = 25;
end

---
function APalletSilo.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onTriggerNodeCallback", APalletSilo.onTriggerNodeCallback)
end

---
function APalletSilo.registerOverwrittenFunctions(placeableType)
end

---
function APalletSilo.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", APalletSilo)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", APalletSilo)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", APalletSilo)
    SpecializationUtil.registerEventListener(placeableType, "onRegisterActionEvents", APalletSilo)
end

---
function APalletSilo:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
end

---Called on loading
-- @param table savegame savegame
function APalletSilo:onLoad(savegame)

    local baseXmlPath = "placeable.aPalletSilo"
            
    -- hier für server und client
    self.spec_aPalletSilo = {}
    local spec = self.spec_aPalletSilo
    spec.available = false;
    
    spec.triggerNode = self.xmlFile:getValue(baseXmlPath.."#triggerNode", nil, self.components, self.i3dMappings);
    if spec.triggerNode ~= nil then
        if not CollisionFlag.getHasFlagSet(spec.triggerNode, CollisionFlag.TRIGGER_PLAYER) then
            Logging.xmlWarning(self.xmlFile, "Info trigger collison mask is missing bit 'TRIGGER_PLAYER' (%d)", CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER))
        end
    end
    
        spec.activatable = PalletSiloActivatable.new(self, self.isServer)
        
    spec.palletSpawner = PalletSpawner.new()
    spec.palletSpawner:load(self.components, self.xmlFile, baseXmlPath .. ".palletSpawner", self.customEnvironment, self.i3dMappings)
        
    function spec.palletSpawner:spawnPallet(farmId, fillTypeId, callback, callbackTarget, isBale, isRoundbale, width, height, length, diameter, capacity, wrapState)
        local pallet = nil
        if isBale then
          --Ballen Daten laden
          local baleXMLFilename = g_baleManager:getBaleXMLFilename(fillTypeId, isRoundbale, width, height, length, diameter)

          --Ballen Abmessung hinterlegen für Spawncheck
          local size = {}
          local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeId)
          size.height = height
          if isRoundbale then
            --Maße vom Rundballen hinterlegen
            size.width = diameter
            size.length = diameter
          elseif fillType.name == "COTTON" then
            --Maße vom Cotton Quaderballen drehen für den Spawnbereich, damit dieser Spawnen kann
            size.width = length
            size.length = width
          else
            --Maße von Quaderballen hinterlegen
            size.width = width
            size.length = length	    
          end
          
          --Fake Palette anlegen, damit der Spawner weiterhin funktioniert
          pallet = {}
          pallet.filename = baleXMLFilename
          pallet.size = size
          pallet.capacity = capacity
          pallet.isBale = true
          pallet.isRoundbale = isRoundbale
          pallet.wrapState = wrapState
          pallet.width = width
          pallet.height = height
          pallet.length = length
          pallet.diameter = diameter
          
        else
          pallet = spec.palletSpawner.fillTypeIdToPallet[fillTypeId]
        end

        if pallet ~= nil then
            table.insert(spec.palletSpawner.spawnQueue, {
                pallet = pallet,
                fillType = fillTypeId,
                farmId = farmId,
                callback = callback,
                callbackTarget = callbackTarget
            })
            g_currentMission:addUpdateable(spec.palletSpawner)

        else
            Logging.devError("PalletSpawner: no pallet for fillTypeId", fillTypeId)
            callback(callbackTarget, nil, PalletSpawner.NO_PALLET_FOR_FILLTYPE, fillTypeId)
        end
    end
    
    function spec.palletSpawner:onSpawnSearchFinished(location)
        local objectToSpawn = spec.palletSpawner.currentObjectToSpawn
        if location ~= nil then
            location.y = location.y + 0.25
            if objectToSpawn.pallet.isBale == nil then
              --Normaler PalettenSpawner
              VehicleLoadingUtil.loadVehicle(objectToSpawn.pallet.filename, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, objectToSpawn.farmId, nil, nil, spec.palletSpawner.onFinishLoadingPallet, spec.palletSpawner)
            else
              --Ballen Spawner
              local baleObject = Bale.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
              if objectToSpawn.pallet.isRoundbale then
                --Rundballen auf die Seite drehen, damit diese nicht wegrollen
                location.xRot = location.xRot + (3.1415927 / 2)
              end
              local fillType = g_fillTypeManager:getFillTypeByIndex(objectToSpawn.fillType)
              if fillType.name == "COTTON" then
                --Cotton Quaderballen drehen, damit diese in den Spawnbereich passen
                location.yRot = location.yRot + (3.1415927 / 2)
                --Cotton Quaderballen zusätzliche 0,25m nach oben verschieben
                location.y = location.y + 1.30
              end
                if baleObject:loadFromConfigXML(objectToSpawn.pallet.filename, location.x, location.y, location.z, location.xRot, location.yRot, location.zRot) then
                    baleObject:setFillType(objectToSpawn.fillType, true)
                    baleObject:setOwnerFarmId(objectToSpawn.farmId, true)
                    baleObject:setFillLevel(objectToSpawn.pallet.capacity, true)
                    if objectToSpawn.pallet.wrapState then
                      --SilageBallen eingewickelt Spawnen
                      baleObject:setWrappingState(1)
                    end
                    baleObject:register()
                    --Manueller Callback
                    objectToSpawn.callback(objectToSpawn.callbackTarget, objectToSpawn.pallet, PalletSpawner.RESULT_SUCCESS, objectToSpawn.fillType)
                    spec.palletSpawner.currentObjectToSpawn = nil
                    table.remove(spec.palletSpawner.spawnQueue, 1)
                else
                    print("Could not spawn bale object")
                end
            end
        else
            objectToSpawn.callback(objectToSpawn.callbackTarget, nil, PalletSpawner.RESULT_NO_SPACE)

            spec.palletSpawner.currentObjectToSpawn = nil

            table.remove(spec.palletSpawner.spawnQueue, 1)
        end
    end
    
    spec.initialized = true;
end

---
function APalletSilo:onDelete()
    local spec = self.spec_aPalletSilo

    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
        spec.triggerNode = nil
    end
end
---
function APalletSilo:onFinalizePlacement()
    local spec = self.spec_aPalletSilo
    if spec.triggerNode ~= nil then
        addTrigger(spec.triggerNode, "onTriggerNodeCallback", self)
    end
end

---
function APalletSilo:onTriggerNodeCallback(triggerId, otherId, onEnter, onLeave, onStay)
    local spec = self.spec_aPalletSilo
    if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then

        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end