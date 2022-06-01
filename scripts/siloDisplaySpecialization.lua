--[[
Copyright (C) Achimobil & braeven, 2022

Author: Achimobil
Date: 01.06.2022
Version: 0.1.2.0

Contact:
https://forum.giants-software.com
https://discord.gg/Va7JNnEkcW

History:
V 0.1.0.0 @ 24.04.2022 - First Version.
V 0.1.1.0 @ 16.05.2022 - Add Version and Name for main.lua
V 0.1.2.0 @ 01.06.2022 - Change Name and output on init

Important:
Free for use in other mods - no permission needed, only provide my name.
No changes are to be made to this script without permission from Achimobil.

Frei verwendbar - keine erlaubnis nötig, Namensnennung im Mod erforderlich.
An diesem Skript dürfen ohne Genehmigung von Achimobil keine Änderungen vorgenommen werden.
]]

SiloDisplaySpecialization = {
    Version = "0.1.2.0",
    Name = "SiloDisplaySpecialization"
}
print(g_currentModName .. " - init " .. SiloDisplaySpecialization.Name .. "(Version: " .. SiloDisplaySpecialization.Version .. ")");

function SiloDisplaySpecialization.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableSilo, specializations);
end

function SiloDisplaySpecialization.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", SiloDisplaySpecialization);
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", SiloDisplaySpecialization);
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", SiloDisplaySpecialization);
end

function SiloDisplaySpecialization.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateDisplays", SiloDisplaySpecialization.updateDisplays);
end

function SiloDisplaySpecialization.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SiloDisplay");
    
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".silo.siloDisplays.siloDisplay(?)#node", "Display start node");
	schema:register(XMLValueType.STRING, basePath .. ".silo.siloDisplays.siloDisplay(?)#font", "Display font name");
	schema:register(XMLValueType.STRING, basePath .. ".silo.siloDisplays.siloDisplay(?)#alignment", "Display text alignment");
	schema:register(XMLValueType.FLOAT, basePath .. ".silo.siloDisplays.siloDisplay(?)#size", "Display text size");
	schema:register(XMLValueType.FLOAT, basePath .. ".silo.siloDisplays.siloDisplay(?)#scaleX", "Display text x scale");
	schema:register(XMLValueType.FLOAT, basePath .. ".silo.siloDisplays.siloDisplay(?)#scaleY", "Display text y scale");
	schema:register(XMLValueType.STRING, basePath .. ".silo.siloDisplays.siloDisplay(?)#mask", "Display text mask");
	schema:register(XMLValueType.FLOAT, basePath .. ".silo.siloDisplays.siloDisplay(?)#emissiveScale", "Display emissive scale");
	schema:register(XMLValueType.COLOR, basePath .. ".silo.siloDisplays.siloDisplay(?)#color", "Display text color");
	schema:register(XMLValueType.COLOR, basePath .. ".silo.siloDisplays.siloDisplay(?)#hiddenColor", "Display text hidden color");
	schema:register(XMLValueType.STRING, basePath .. ".silo.siloDisplays.siloDisplay(?)#fillType", "Filltype name for the Display to show amount");
    
	schema:setXMLSpecializationType();
end

function SiloDisplaySpecialization:onLoad(savegame)
    self.spec_siloDisplay = {};
	local spec = self.spec_siloDisplay;
	local xmlFile = self.xmlFile;

	spec.siloDisplays = {};
	local i = 0;

	while true do
		local siloDisplayKey = string.format("placeable.silo.siloDisplays.siloDisplay(%d)", i);

		if not xmlFile:hasProperty(siloDisplayKey) then
			break;
		end
        
		local displayNode = self.xmlFile:getValue(siloDisplayKey .. "#node", nil, self.components, self.i3dMappings);
        
        local fontName = self.xmlFile:getValue(siloDisplayKey .. "#font", "DIGIT"):upper();
        local fontMaterial = g_materialManager:getFontMaterial(fontName, self.customEnvironment);
            
        local display = {};
        local alignmentStr = self.xmlFile:getValue(siloDisplayKey .. "#alignment", "RIGHT");
        local alignment = RenderText["ALIGN_" .. alignmentStr:upper()] or RenderText.ALIGN_RIGHT;
        local size = self.xmlFile:getValue(siloDisplayKey .. "#size", 0.13);
        local scaleX = self.xmlFile:getValue(siloDisplayKey .. "#scaleX", 1);
        local scaleY = self.xmlFile:getValue(siloDisplayKey .. "#scaleY", 1);
        local mask = self.xmlFile:getValue(siloDisplayKey .. "#mask", "000000");
        local emissiveScale = self.xmlFile:getValue(siloDisplayKey .. "#emissiveScale", 0.2);
        local color = self.xmlFile:getValue(siloDisplayKey .. "#color", {
            0.9,
            0.9,
            0.9,
            1
        }, true);
        local hiddenColor = self.xmlFile:getValue(siloDisplayKey .. "#hiddenColor", nil, true);
        display.displayNode = displayNode;
        display.formatStr, display.formatPrecision = string.maskToFormat(mask);
        display.fontMaterial = fontMaterial;
        display.characterLine = fontMaterial:createCharacterLine(display.displayNode, mask:len(), size, color, hiddenColor, emissiveScale, scaleX, scaleY, alignment);
        
        local fillTypeName = xmlFile:getValue(siloDisplayKey .. "#fillType");
        display.fillTypeId = g_fillTypeManager:getFillTypeIndexByName(fillTypeName);
        
        table.insert(spec.siloDisplays, display);

		i = i + 1;
	end
    
	function spec.fillLevelChangedCallback(fillType, delta)
        self:updateDisplays();
	end    
end

function SiloDisplaySpecialization:onFinalizePlacement(savegame)
	local spec = self.spec_siloDisplay;
	for _, sourceStorage in pairs(self.spec_silo.loadingStation:getSourceStorages()) do
        sourceStorage:addFillLevelChangedListeners(spec.fillLevelChangedCallback);
    end
end

function SiloDisplaySpecialization:onPostFinalizePlacement(savegame)
    self:updateDisplays();
end


function SiloDisplaySpecialization:updateDisplays()
	local spec = self.spec_siloDisplay;
	local farmId = self:getOwnerFarmId();
    
	for _, display in pairs(spec.siloDisplays) do
		local fillLevel = self.spec_silo.loadingStation:getFillLevel(display.fillTypeId, farmId);
		local int, floatPart = math.modf(fillLevel);
		local value = string.format(display.formatStr, int, math.abs(math.floor(floatPart * 10^display.formatPrecision)))
		display.fontMaterial:updateCharacterLine(display.characterLine, value);
	end
end