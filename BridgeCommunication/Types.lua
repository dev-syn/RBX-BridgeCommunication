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
    _BridgeComms: Map<BridgeComm,boolean?>,
    Comm: {
        Create: "Create" | string,
        Destroy: "Destroy" | string,
        Ping: "Ping" | string
    },

    WaitForBridgeComm: (bridgeName: string,timeOut: number?) -> BridgeComm?,
    EstablishConnection : (remote: RemoteEvent,player: Player,timeOut: number?) -> boolean,
    new: (name: string) -> BridgeComm,
    SetCommBridge: (self: BridgeComm,bridgeKey: string,bridgeFn: (any...) -> ()) -> (),
    FireServer: (self: BridgeComm,bridgeKey: string,...any) -> (),
    FireClient: (self: BridgeComm,player: Player,bridgeKey: string,...any) -> (),
    Destroy: (self: BridgeComm) -> (),
    _FormatOut: (message: string) -> string
};

export type BridgeComm = Object_BridgeCommunication & Schema_BridgeCommunication;


return true;