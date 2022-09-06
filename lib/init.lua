--#region Types
export type Map<K,V> = {[K]: V};
export type Dictionary<T> = Map<string,T>
export type Object = Dictionary<any>

export type ConnectionStatus = "TIMEOUT" | "ESTABLISHED" | "QUEUED";

export type E_ConnectionStatus = {
    TIMEOUT: "TIMEOUT",
    ESTABLISHED: "ESTABLISHED",
    QUEUED: "QUEUED"
};

export type Object_BridgeCommunication = {
    Name: string,
    _BridgeFunctions: Dictionary<(player: Player,self: BridgeComm,...any) -> ()>,
    _RemoteEvent: RemoteEvent?
};

export type Schema_BridgeCommunication = {
    ClassName: "BridgeCommunication" | string,
    __index: Object,
    _EstablishedConnections: Map<Player,Map<RemoteEvent,boolean?>>?,
    _BridgeComms: Dictionary<BridgeComm>,
    _QueuedComms: Map<Player,Map<RemoteEvent,{any}>>,
    Comm: {
        Create: "BridgeCommunication-Create" | string,
        Destroy: "BridgeCommunication-Destroy" | string,
        Ping: "BridgeCommunication-Ping" | string
    },

    Init: () -> Schema_BridgeCommunication,
    WaitForBridgeComm: (bridgeName: string,timeOut: number?) -> BridgeComm?,
    EstablishConnection : (remote: RemoteEvent,player: Player,timeOut: number?,...any) -> ConnectionStatus,
    new: (name: string) -> BridgeComm,
    SetCommBridge: (self: BridgeComm,bridgeKey: string,bridgeFn: (player: Player,any...) -> ()) -> (),
    FireServer: (self: BridgeComm,bridgeKey: string,...any) -> (),
    FireClient: (self: BridgeComm,player: Player,bridgeKey: string,...any) -> (),
    _FireWithConnection: (self: BridgeComm,player: Player,...any) -> (),
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

-- Per player, Per Remote
BridgeCommunication._QueuedComms = {};

BridgeCommunication.Comm = {
    Create = "BridgeCommunication-Create",
    Destroy = "BridgeCommunication-Destroy",
    Ping = "BridgeCommunication-Ping"
};

-- Enum ConnectionStatus
local ConnectionStatus: E_ConnectionStatus = {
    TIMEOUT = "TIMEOUT",
    ESTABLISHED = "ESTABLISHED",
    QUEUED = "QUEUED"
};

local BridgeEvents: Folder;
local BridgeCommunicationEvent: RemoteEvent;

local function fireWithConnection(remote: RemoteEvent,player: Player,...: any)
    local connStatus: ConnectionStatus = BridgeCommunication.EstablishConnection(remote,player,30);
    if connStatus == ConnectionStatus.ESTABLISHED then
        remote:FireClient(player,...);
    elseif connStatus == ConnectionStatus.QUEUED then
        if not BridgeCommunication._QueuedComms[player] then
            BridgeCommunication._QueuedComms[player] = {};
        end
        if not BridgeCommunication._QueuedComms[player][remote] then
            BridgeCommunication._QueuedComms[player][remote] = {};
        end
        table.insert(BridgeCommunication._QueuedComms[player][remote],table.pack(...));
    end
end

function BridgeCommunication.Init() : Schema_BridgeCommunication
    if isServer then
        -- Setup BridgeCommunicationEvent
        BridgeCommunicationEvent = script:FindFirstChild(NAME_BRIDGE_COMM) or Instance.new("RemoteEvent");
        BridgeCommunicationEvent.Name = NAME_BRIDGE_COMM;
        if not BridgeCommunicationEvent.Parent then BridgeCommunicationEvent.Parent = script; end
    
        BridgeCommunicationEvent.OnServerEvent:Connect(function(player: Player,bridgeKey: string)
			if BridgeCommunication._EstablishedConnections then
				if not BridgeCommunication._EstablishedConnections[player] then
					BridgeCommunication._EstablishedConnections[player] = {};
				end
				if bridgeKey == BridgeCommunication.Comm.Ping and not BridgeCommunication._EstablishedConnections[player][BridgeCommunicationEvent] then
                    BridgeCommunication._EstablishedConnections[player][BridgeCommunicationEvent] = true;
                end
			end
        end);

        BridgeEvents = script:FindFirstChild("BridgeEvents") or Instance.new("Folder");
        BridgeEvents.Name = "BridgeEvents";
        BridgeEvents.Parent = script;
    
        -- Create BridgeCommunications on joining clients.
        game.Players.PlayerAdded:Connect(function(player: Player)
            for _,bridgeComm: BridgeComm in pairs(BridgeCommunication._BridgeComms) do
                task.spawn(fireWithConnection,BridgeCommunicationEvent,player,BridgeCommunication.Comm.Create,bridgeComm.Name);
            end
        end);
    
        -- Remove clients from _EstablishedConnections when leaving.
        game.Players.PlayerRemoving:Connect(function(player: Player)
            if BridgeCommunication._EstablishedConnections then
                BridgeCommunication._EstablishedConnections[player] = nil;
            end
        end);
    else
        -- Setup BridgeCommunicationEvent
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

        BridgeEvents = script:WaitForChild("BridgeEvents",30);
        if not BridgeEvents then
            error(BridgeCommunication._FormatOut("BridgeEvents folder was not created, make sure BridgeCommunication was required on the server."),2);
        end
    end
    return BridgeCommunication;
end

function BridgeCommunication.WaitForBridgeComm(bridgeName: string,timeOut: number?) : BridgeComm?
    if isServer then error(BridgeCommunication._FormatOut(ERROR_INVALID_ENV:format(".WaitForBridgeComm","client")),3); end
    if typeof(bridgeName) ~= "string" then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("bridgeName","string",typeof(bridgeName))),3);
    end
    if typeof(timeOut) ~= "number" and timeOut ~= nil then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("timeOut","number?",typeof(timeOut))),3);
    end
    if timeOut and (timeOut < (1 / 60) or timeOut == math.huge) then timeOut = 1 / 60; end
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

function BridgeCommunication.EstablishConnection(remote: RemoteEvent,player: Player,timeOut: number?) : ConnectionStatus
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
	if not BridgeCommunication._EstablishedConnections then return ConnectionStatus.TIMEOUT; end
	
	local estaConnections: Map<Player,Map<RemoteEvent,boolean?>> = BridgeCommunication._EstablishedConnections :: Map<Player,Map<RemoteEvent,boolean?>>;
	if not estaConnections[player] then
		estaConnections[player] = {};
	end
	-- Check if a connection is already being established
	if estaConnections[player][remote] == false then
		return ConnectionStatus.QUEUED;
	end
	-- Start trying to establish a connection with the client
	estaConnections[player][remote] = false;
	local startTime: number = DateTime.now().UnixTimestampMillis;
	local timeInMS: number = timeOut and timeOut * 1000 or 0;
	repeat
		remote:FireClient(player,BridgeCommunication.Comm.Ping);
		task.wait(0.15);
	until not estaConnections[player] or estaConnections[player][remote] or timeOut and DateTime.now().UnixTimestampMillis - startTime >= timeInMS;
	
	-- If no established connection then the connection TimedOut
	if not estaConnections[player] or not estaConnections[player][remote] then
		return ConnectionStatus.TIMEOUT;
	end
	-- Call the queued args
	if BridgeCommunication._QueuedComms[player] and BridgeCommunication._QueuedComms[player][remote] then
		for _,args: {any} in ipairs(BridgeCommunication._QueuedComms[player][remote]) do
            print("args: ",table.unpack(args));
			remote:FireClient(player,table.unpack(args));
		end
	end
	return ConnectionStatus.ESTABLISHED;
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
        -- Setup the RemoteEvent
		local remote: RemoteEvent = Instance.new("RemoteEvent");
		remote = Instance.new("RemoteEvent") :: RemoteEvent;
		remote.Name = name;
		remote.Parent = BridgeEvents;
		remote.OnServerEvent:Connect(function(player: Player,bridgeComm: string,...: any)
			if bridgeComm == BridgeCommunication.Comm.Ping and BridgeCommunication._EstablishedConnections and BridgeCommunication._EstablishedConnections[player] then
				BridgeCommunication._EstablishedConnections[player][remote] = true;
				return;
			end
			if not self._BridgeFunctions[bridgeComm] then
				local startTime: number = DateTime.now().UnixTimestamp;
				repeat task.wait(0.15) until self._BridgeFunctions[bridgeComm] or DateTime.now().UnixTimestamp - startTime >= 7;
			end
			if typeof(self._BridgeFunctions[bridgeComm]) == "function" then
				self._BridgeFunctions[bridgeComm](player,...);
			end
		end);
		self._RemoteEvent = remote;

		-- Create this BridgeComm on the client
		for _: number,player: Player in ipairs(game.Players:GetPlayers()) do
            task.spawn(fireWithConnection,BridgeCommunicationEvent,player,BridgeCommunication.Comm.Create,self.Name);
		end
    else
        -- Setup the RemoteEvent
        self._RemoteEvent = BridgeEvents:WaitForChild(name,60) :: RemoteEvent;
        if self._RemoteEvent then
            self._RemoteEvent.OnClientEvent:Connect(function(bridgeComm: string,...: any)
                if bridgeComm == BridgeCommunication.Comm.Ping then
                    self._RemoteEvent:FireServer(BridgeCommunication.Comm.Ping);
                    return;
                end
                if not self._BridgeFunctions[bridgeComm] then
                    local startTime: number = DateTime.now().UnixTimestamp;
                    repeat task.wait(0.15) until self._BridgeFunctions[bridgeComm] or DateTime.now().UnixTimestamp - startTime >= 7;
                end
                if typeof(self._BridgeFunctions[bridgeComm]) == "function" then
                    self._BridgeFunctions[bridgeComm](game.Players.LocalPlayer,...);
                end
            end);
        end
    end
    setmetatable(self,BridgeCommunication);
    BridgeCommunication._BridgeComms[self.Name] = self :: BridgeComm;
    return self :: BridgeComm;
end

-- Fires with (Player,...any)
function BridgeCommunication.SetCommBridge(self: BridgeComm,bridgeKey: string,bridgeFn: (player: Player,...any) -> ())
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
    if self._RemoteEvent then
        self._RemoteEvent:FireServer(bridgeKey,...);
    end
end

function BridgeCommunication.FireClient(self: BridgeComm,player: Player,bridgeKey: string,...: any)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        error(BridgeCommunication._FormatOut(ERROR_INVALID_PARAM:format("player","Player",typeof(player))),3);
    end
    if not self._BridgeFunctions[bridgeKey] then
        warn(BridgeCommunication._FormatOut("No CommBridge has been created for bridgeKey: "..bridgeKey.." in "..self.Name));
        return;
    end
    task.spawn(BridgeCommunication._FireWithConnection,self,player,bridgeKey,...);
end

function BridgeCommunication._FireWithConnection(self: BridgeComm,player: Player,...: any)
    if self._RemoteEvent then
        fireWithConnection(self._RemoteEvent,player,...);
    end
end

function BridgeCommunication.Destroy(self: BridgeComm)
	if isServer then
		for _: number,player: Player in ipairs(game.Players:GetPlayers()) do
            task.spawn(fireWithConnection,BridgeCommunicationEvent,player,BridgeCommunication.Comm.Destroy,self.Name);
			if BridgeCommunication._EstablishedConnections and BridgeCommunication._EstablishedConnections[player] and self._RemoteEvent then
				BridgeCommunication._EstablishedConnections[player][self._RemoteEvent] = nil;
			end
		end
		-- Clear any queued BridgeCommunications to send
		for _,player: Player in ipairs(game.Players:GetPlayers()) do
			if self._RemoteEvent then
				if BridgeCommunication._QueuedComms[player] and BridgeCommunication._QueuedComms[player][self._RemoteEvent] then
					BridgeCommunication._QueuedComms[player][self._RemoteEvent] = nil;
				end
			end
		end
	end
	if self._RemoteEvent then
		self._RemoteEvent:Destroy();
		self._RemoteEvent = nil;
	end
	BridgeCommunication._BridgeComms[self.Name] = nil;
end

function BridgeCommunication._FormatOut(message: string) : string return string.format("[BridgeCommunication]: %s",message); end

return BridgeCommunication;