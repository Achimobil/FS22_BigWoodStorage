SpawnPalletsAtSiloEvent = {}
local SpawnPalletsAtSiloEvent_mt = Class(SpawnPalletsAtSiloEvent, Event)
InitEventClass(SpawnPalletsAtSiloEvent, "SpawnPalletsAtSiloEvent")

---
function SpawnPalletsAtSiloEvent.emptyNew()
    local self = Event.new(SpawnPalletsAtSiloEvent_mt)
    return self
end

---
function SpawnPalletsAtSiloEvent.new(aPalletSilo, ownerFarmId, fillUnitIndex, pendingLiters, fillTypeIndex, isBale, isRoundbale, width, height, length, diameter, capacity, wrapState)
    local self = SpawnPalletsAtSiloEvent.emptyNew()
    
    self.aPalletSilo = aPalletSilo
    self.ownerFarmId = ownerFarmId
    self.fillUnitIndex = fillUnitIndex
    self.pendingLiters = pendingLiters
    self.fillTypeIndex = fillTypeIndex
    self.isBale = isBale
    self.isRoundbale = isRoundbale
    self.width = width
    self.height = height
    self.length = length
    self.diameter = diameter
    self.capacity = capacity
    self.wrapState = wrapState

    return self
end

---
function SpawnPalletsAtSiloEvent:readStream(streamId, connection)
    self.aPalletSilo = NetworkUtil.readNodeObject(streamId)
    self.ownerFarmId = streamReadInt32(streamId)
    self.fillUnitIndex = streamReadInt32(streamId)
    self.pendingLiters = streamReadFloat32(streamId)
    self.fillTypeIndex = streamReadInt32(streamId)
    self.isBale = streamReadBool(streamId)
    self.isRoundbale = streamReadBool(streamId)
    self.width = streamReadFloat32(streamId)
    self.height = streamReadFloat32(streamId)
    self.length = streamReadFloat32(streamId)
    self.diameter = streamReadFloat32(streamId)
    self.capacity = streamReadFloat32(streamId)
    self.wrapState = streamReadBool(streamId)
    
    self:run(connection)
end

---
function SpawnPalletsAtSiloEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.aPalletSilo) 
    streamWriteInt32(streamId, self.ownerFarmId)
    streamWriteInt32(streamId, self.fillUnitIndex)
    streamWriteFloat32(streamId, self.pendingLiters)
    streamWriteInt32(streamId, self.fillTypeIndex)
    streamWriteBool(streamId, self.isBale)
    streamWriteBool(streamId, self.isRoundbale)
    streamWriteFloat32(streamId, self.width)
    streamWriteFloat32(streamId, self.height)
    streamWriteFloat32(streamId, self.length)
    streamWriteFloat32(streamId, self.diameter)
    streamWriteFloat32(streamId, self.capacity)
    streamWriteBool(streamId, self.wrapState)
end

---
function SpawnPalletsAtSiloEvent:run(connection)
    assert(not connection:getIsServer(), "SpawnPalletsAtSiloEvent is client to server only")

    -- eintragen was vom client gebraucht wird in die spec
    local spec = self.aPalletSilo.spec_aPalletSilo
    spec.fillUnitIndex = self.fillUnitIndex;
    spec.pendingLiters = self.pendingLiters;
    spec.fillTypeIndex = self.fillTypeIndex;
    spec.isBale = self.isBale;
    spec.isRoundbale = self.isRoundbale;
    spec.width = self.width;
    spec.height = self.height;
    spec.length = self.length;
    spec.diameter = self.diameter;
    spec.capacity = self.capacity;
    spec.wrapState = self.wrapState;

        -- local delta = pallet:addFillUnitFillLevel(self.placable.ownerFarmId, spec.fillUnitIndex, spec.pendingLiters, fillTypeIndex, ToolType.UNDEFINED)

    spec.palletSpawner:spawnPallet(self.ownerFarmId, self.fillTypeIndex, spec.activatable.getPalletCallback, spec.activatable, self.isBale, self.isRoundbale, self.width, self.height, self.length, self.diameter, self.capacity, self.wrapState)
end

function SpawnPalletsAtSiloEvent.sendEvent(aPalletSilo, ownerFarmId, fillUnitIndex, pendingLiters, fillTypeIndex, isBale, isRoundbale, width, height, length, diameter, capacity, wrapState)
    g_client:getServerConnection():sendEvent(SpawnPalletsAtSiloEvent.new(aPalletSilo, ownerFarmId, fillUnitIndex, pendingLiters, fillTypeIndex, isBale, isRoundbale, width, height, length, diameter, capacity, wrapState))
end