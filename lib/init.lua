--#region Types
export type Map<K,V> = {[K]: V};
export type Dictionary<T> = Map<string,T>
export type Object = Dictionary<any>

export type Object_BridgeCommunication = {
    Name: string,
    _BridgeFunctions: Dictionary<(player: Player,self: BridgeComm,...any) -> ()>,
    _RemoteEvent: RemoteEvent?,
};

export type Schema_BridgeCommunication = {
    ClassName: "BridgeCommunication" | string,
    __index: Object,
    _EstablishedConnections: Map<Player,Dictionary<boolean?>>?,
    _BridgeComms: Dictionary<BridgeComm>,
    Comm: {
        Create: "BridgeCommunication-Create" | string,
        Destroy: "BridgeCommunication-Destroy" | string,
        Ping: "BridgeCommunication-Ping" | string
    },

    WaitForBridgeComm: (bridgeName: string,timeOut: number?) -> BridgeComm?,
    EstablishConnection : (remote: RemoteEvent,player: Player,timeOut: number?) -> boolean,
    new: (name: string) -> BridgeComm,
    SetCommBridge: (self: BridgeComm,bridgeKey: string,bridgeFn: (player: Player,any...) -> ()) -> (),
    FireServer: (self: BridgeComm,bridgeKey: string,...any) -> (),
    FireClient: (self: BridgeComm,player: Player,bridgeKey: string,...any) -> (),
    Destroy: (self: BridgeComm) -> (),
    _FormatOut: (message: string) -> string
};

export type BridgeComm = Object_BridgeCommunication & Schema_BridgeCommunication;
--#endregion

local isServer: boolean = game:GetService("RunService"):IsServer();

local NAME_BRIDGE_COMM = "BridgeCommunicationEvent"

local ERROR_INVALID_PARAM = "Invalid type passed for '%s' expected '%s' but got '%s'";
local ERROR_INVALID_ENV = "'%s' can only be called from the '%s' env";

--- @class BridgeCommunication
--- This class is designed to automate communication between the server and client it uses RemoteEvents internally.

local BridgeCommunication: Schema_BridgeCommunication = {} :: Schema_BridgeCommunication;
--[=[
    @prop ClassName "BridgeCommunication"
    @within BridgeCommunication
    The ClassName of this class.
]=]
BridgeCommunication.ClassName = "BridgeCommunication";
BridgeCommunication.__index = BridgeCommunication;
BridgeCommunication._EstablishedConnections = isServer and {} or nil;
BridgeCommunication._BridgeComms = {};

BridgeCommunication.Comm = {
    Create = "BridgeCommunication-Create",
    Destroy = "BridgeCommunication-Destroy",
    Ping = "BridgeCommunication-Ping"
};

local function FireWithConnection(remote: RemoteEvent,player: Player,...: any)
    local hasConnection: boolean = BridgeCommunication.EstablishConnection(remote,player,30);
    if hasConnection then
        remote:FireClient(player,...);
    end
end

local BridgeEvents: Folder;
local BridgeCommunicationEvent: RemoteEvent;

if isServer then
    BridgeEvents = script:FindFirstChild("BridgeEvents") or Instance.new("Folder");
    BridgeEvents.Name = "BridgeEvents";
    BridgeEvents.Parent = script;

    BridgeCommunicationEvent = script:FindFirstChild(NAME_BRIDGE_COMM) or Instance.new("RemoteEvent");
    BridgeCommunicationEvent.Name = NAME_BRIDGE_COMM;
    if not BridgeCommunicationEvent.Parent then BridgeCommunicationEvent.Parent = script; end

    BridgeCommunicationEvent.OnServerEvent:Connect(function(player: Player,bridgeKey: string,bridgeName: string,...: any)
        if not BridgeCommunication._EstablishedConnections[player] then
            BridgeCommunication._EstablishedConnections[player] = {};
        end
        if bridgeKey == BridgeCommunication.Comm.Ping and not BridgeCommunication._EstablishedConnections[player][bridgeName] then
              BridgeCommunication._EstablishedConnections[player][bridgeName] = true;
        end
    end);

    -- Create BridgeCommunications on joining clients.
    game.Players.PlayerAdded:Connect(function(player: Player)
        for commName: string,bridgeComm: BridgeComm in pairs(BridgeCommunication._BridgeComms) do
            task.spawn(FireWithConnection,BridgeCommunicationEvent,player,BridgeCommunication.Comm.Create,bridgeComm.Name);
        end
    end);

    -- Remove clients from _EstablishedConnections when leaving.
    game.Players.PlayerRemoving:Connect(function(player: Player)
        BridgeCommunication._EstablishedConnections[player] = nil;
    end);
else
    BridgeEvents = script:WaitForChild("BridgeEvents",30);
    if not BridgeEvents then
        error(BridgeCommunication._FormatOut("BridgeEvents folder was not created, make sure BridgeCommunication was required on the server."),2);
    end
    BridgeCommunicationEvent = script:WaitForChild(NAME_BRIDGE_COMM,30);
    if not BridgeCommunicationEvent then
        error(BridgeCommunication._FormatOut("BridgeCommunication event was not created, make sure BridgeCommunication was required on the server."),2);
    end

    BridgeCommunicationEvent.OnClientEvent:Connect(function(bridgeKey: string,bridgeName: string,...: any)
        local bridgeComm: BridgeComm? = BridgeCommunication._BridgeComms[bridgeName] :: BridgeComm?;
        if bridgeKey == BridgeCommunication.Comm.Create and not bridgeComm then
            BridgeCommunication.new(bridgeName);
        elseif bridgeKey == BridgeCommunication.Comm.Destroy and bridgeComm then
            (bridgeComm::BridgeComm):Destroy();
        elseif bridgeKey == BridgeCommunication.Comm.Ping then
            BridgeCommunicationEvent:FireServer(bridgeKey,bridgeName);
        end
    end);
end

function BridgeCommunication.WaitForBridgeComm(bridgeName: string,timeOut: number?) : BridgeComm?
    if isServer then error(BridgeCommunication._FormatOut(ERROR_INVALID_ENV:format(".WaitForBridgeComm","client")),3); end
    if typeof(bridgeName) ~= "string" then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("bridgeName","string",typeof(bridgeName))),3);
    end
    if typeof(timeOut) ~= "number" and timeOut ~= nil then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("timeOut","number?",typeof(timeOut))),3);
    end
    if timeOut and timeOut < (1 / 60) or timeOut == math.huge then timeOut = 1 / 60; end
    local startTime: number = DateTime.now().UnixTimestampMillis;
    local timeInMS: number = timeOut and timeOut * 1000 or 0;
    local toWarn: boolean = not timeOut;
    repeat
        if toWarn and DateTime.now().UnixTimestampMillis - startTime >= 10000 then
            toWarn = false;
            warn(BridgeCommunication._FormatOut("Infinite yield possible waiting for BridgeCommunication named: "..bridgeName));
        end
        task.wait(0.15);
    until BridgeCommunication._BridgeComms[bridgeName] or timeOut and DateTime.now().UnixTimestampMillis - startTime >= timeInMS;
    return BridgeCommunication._BridgeComms[bridgeName] or nil;
end

function BridgeCommunication.EstablishConnection(remote: RemoteEvent,player: Player,timeOut: number?) : boolean
    if not isServer then error(BridgeCommunication._FormatOut(ERROR_INVALID_ENV:format(".WaitForConnection","server")),2); end
    if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("remote","RemoteEvent",typeof(remote))),3);
    end
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("player","Player",typeof(player))),3);
    end
    if typeof(timeOut) ~= "number" and timeOut ~= nil then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("timeOut","number?",typeof(timeOut))),3);
    end
    if timeOut and timeOut < (1 / 60) or timeOut == math.huge then timeOut = 1 / 60; end
    if not BridgeCommunication._EstablishedConnections[player] then
        BridgeCommunication._EstablishedConnections[player] = {};
    end
    -- Start trying to establish a connection with the client
    BridgeCommunication._EstablishedConnections[player][remote.Name] = false;
    local startTime: number = DateTime.now().UnixTimestampMillis;
    local timeInMS: number = timeOut and timeOut * 1000 or 0;
    repeat
        remote:FireClient(player,BridgeCommunication.Comm.Ping,remote.Name);
        task.wait(0.15);
    until not BridgeCommunication._EstablishedConnections[player] or BridgeCommunication._EstablishedConnections[player][remote.Name] or timeOut and DateTime.now().UnixTimestampMillis - startTime >= timeInMS;
    if not BridgeCommunication._EstablishedConnections[player] or not BridgeCommunication._EstablishedConnections[player][remote.Name] then
        return false;
    end
    return true;
end

function BridgeCommunication.new(name: string) : BridgeComm
    if typeof(name) ~= "string" then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("name","string",typeof(name))),2);
    end
    if BridgeCommunication._BridgeComms[name] then
       error(BridgeCommunication._FormatOut("BridgeCommunication with name: '"..name.." already exists."));
    end
    local self: Object_BridgeCommunication = {} :: Object_BridgeCommunication;
    self.Name = name;
    self._BridgeFunctions = {};
    if isServer then
        self._RemoteEvent = Instance.new("RemoteEvent");
        self._RemoteEvent.Name = name;
        self._RemoteEvent.Parent = BridgeEvents;
        self._RemoteEvent.OnServerEvent:Connect(function(player: Player,bridgeComm: string,...: any)
            if bridgeComm == BridgeCommunication.Comm.Ping then
                BridgeCommunication._EstablishedConnections[player][self._RemoteEvent.Name] = true;
                return;
            end
            if not typeof(self._BridgeFunctions[bridgeComm]) == "function" then
                local startTime: number = DateTime.now().UnixTimestamp;
                repeat task.wait(0.15) until self._BridgeFunctions[bridgeComm] or DateTime.now().UnixTimestamp - startTime >= 7;
            end
            self._BridgeFunctions[bridgeComm](player,...);
        end);
        -- Create this on the client
        for _: number,player: Player in ipairs(game.Players:GetPlayers()) do
            task.spawn(FireWithConnection,BridgeCommunicationEvent,player,BridgeCommunication.Comm.Create,self.Name);
        end
    else
        self._RemoteEvent = BridgeEvents:WaitForChild(name) :: RemoteEvent?;
        self._RemoteEvent.OnClientEvent:Connect(function(bridgeComm: string,...: any)
            if bridgeComm == BridgeCommunication.Comm.Ping then
                self._RemoteEvent:FireServer(BridgeCommunication.Comm.Ping);
                return;
            end
            if not typeof(self._BridgeFunctions[bridgeComm]) == "function" then
                local startTime: number = DateTime.now().UnixTimestamp;
                repeat task.wait(0.15) until self._BridgeFunctions[bridgeComm] or DateTime.now().UnixTimestamp - startTime >= 7;
            end
            self._BridgeFunctions[bridgeComm](game.Players.LocalPlayer,...);
        end);
    end
    BridgeCommunication._BridgeComms[self.Name] = self :: BridgeComm;
    return setmetatable(self,BridgeCommunication) :: BridgeComm;
end

-- Fires with (Player,...any)
function BridgeCommunication.SetCommBridge(self: BridgeComm,bridgeKey: string,bridgeFn: (player: Player,any...) -> ())
    if typeof(bridgeKey) ~= "string" then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("bridgeKey","string",typeof(bridgeKey))),2);
    end
    if typeof(bridgeFn) ~= "function" then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("bridgeFn","function",typeof(bridgeFn))),2);
    end
    if not self._BridgeFunctions[bridgeKey] then
        self._BridgeFunctions[bridgeKey] = bridgeFn;
    else
        warn(BridgeCommunication._FormatOut("This CommBridge already exists in BridgeCommunication with name: "),self.Name);
    end
end

function BridgeCommunication.FireServer(self: BridgeComm,bridgeKey: string,...: any)
    if not self._BridgeFunctions[bridgeKey] then
        warn(BridgeCommunication._FormatOut("No CommBridge has been created for bridgeKey: "..bridgeKey.." in "..self.Name));
        return;
    end
    self._RemoteEvent:FireServer(bridgeKey,...);
end

function BridgeCommunication.FireClient(self: BridgeComm,player: Player,bridgeKey: string,...: any)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("player","Player",typeof(player))),3);
    end
    if not self._BridgeFunctions[bridgeKey] then
        warn(BridgeCommunication._FormatOut("No CommBridge has been created for bridgeKey: "..bridgeKey.." in "..self.Name));
        return;
    end
    task.spawn(FireWithConnection,self._RemoteEvent,player,bridgeKey,...);
end

function BridgeCommunication.Destroy(self: BridgeComm)
    if isServer then
        for _: number,player: Player in ipairs(game.Players:GetPlayers()) do
            task.spawn(FireWithConnection,BridgeCommunicationEvent,player,BridgeCommunication.Comm.Destroy,self.Name);
            if BridgeCommunication._EstablishedConnections[player] then
                BridgeCommunication._EstablishedConnections[player][self.Name] = nil;
            end
        end
    end
    self._RemoteEvent:Destroy();
    BridgeCommunication._BridgeComms[self.Name] = nil;
end

function BridgeCommunication._FormatOut(message: string) : string return string.format("[BridgeCommunication]: %s",message); end

return BridgeCommunication;