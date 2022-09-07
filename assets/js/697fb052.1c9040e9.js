"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[314],{49277:e=>{e.exports=JSON.parse('{"functions":[{"name":"Init","desc":"This method is for initializing the BridgeCommunication Module this function **must** be called on both the **server & client**.\\nThis returns the BridgeCommunication class allowing to call Init on the same line while retaining the class required.\\n```lua\\n    local BridgeCommunication = require(BridgeCommunicationModule).Init();\\n    -- BridgeCommunication is the class\\n    BridgeCommunication.new(\\"Test\\");\\n```","params":[],"returns":[{"desc":"","lua_type":"Schema_BridgeCommunication\\r\\n"}],"function_type":"static","source":{"line":154,"path":"lib/init.lua"}},{"name":"WaitForBridgeComm","desc":"This function waits for a BridgeCommunication by it\'s name to exists or will time out if timeOut is specified then returns nil.","params":[{"name":"bridgeName","desc":"Name of the BridgeCommunication","lua_type":"string"},{"name":"timeOut","desc":"The time out in seconds or nil for no time out.","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"BridgeComm?"}],"function_type":"static","yields":true,"source":{"line":223,"path":"lib/init.lua"}},{"name":"EstablishConnection","desc":"This method takes a remote and a player and returns a ConnectionStatus ([BridgeCommunication.T_ConnectionStatus])\\nthis is only meant to be used for internal remotes.","params":[{"name":"remote","desc":"","lua_type":"RemoteEvent"},{"name":"player","desc":"","lua_type":"Player"},{"name":"timeOut","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"T_ConnectionStatus"}],"function_type":"static","realm":["Server"],"source":{"line":256,"path":"lib/init.lua"}},{"name":"new","desc":"This methods creates a new BridgeCommunication object replicating it to the client.","params":[{"name":"name","desc":"The unique name that will be used to identify this BridgeCommunication","lua_type":"string"}],"returns":[{"desc":"","lua_type":"BridgeComm"}],"function_type":"static","source":{"line":327,"path":"lib/init.lua"}},{"name":"SetCommBridge","desc":"This method sets a function to a bridgeKey that when fired will call the function.","params":[{"name":"self","desc":"","lua_type":"BridgeComm"},{"name":"bridgeKey","desc":"The bridgeKey that will be fired to","lua_type":"string"},{"name":"bridgeFn","desc":"The function that will be called when fired","lua_type":"(player: Player,...any) -> ()"}],"returns":[],"function_type":"method","source":{"line":396,"path":"lib/init.lua"}},{"name":"FireServer","desc":"This method fires the server with a bridgeKey calling any CommBridge function on the server.","params":[{"name":"self","desc":"","lua_type":"BridgeComm"},{"name":"bridgeKey","desc":"The bridgeKey that will be fired to","lua_type":"string"},{"name":"...","desc":"The tuple of arguments to fire","lua_type":"any"}],"returns":[],"function_type":"method","realm":["Client"],"source":{"line":419,"path":"lib/init.lua"}},{"name":"FireClient","desc":"This method fires the client with a bridgeKey calling any CommBridge function on the server.","params":[{"name":"self","desc":"","lua_type":"BridgeComm"},{"name":"player","desc":"The client to fire the remote to","lua_type":"Player"},{"name":"bridgeKey","desc":"The bridgeKey that will be fired to","lua_type":"string"},{"name":"...","desc":"The tuple of arguments to fire","lua_type":"any"}],"returns":[],"function_type":"method","realm":["Server"],"source":{"line":440,"path":"lib/init.lua"}},{"name":"_FireWithConnection","desc":"This method is for internally firing through a remote on the client ensuring a connection or a timeOut.","params":[{"name":"self","desc":"","lua_type":"BridgeComm"},{"name":"player","desc":"The player to fire with a connection to","lua_type":"Player"},{"name":"...","desc":"The arguments to fire","lua_type":"any"}],"returns":[],"function_type":"method","private":true,"source":{"line":461,"path":"lib/init.lua"}},{"name":"Destroy","desc":"This methods destroys the BridgeComm object also relaying the destruction to the client.","params":[{"name":"self","desc":"The BridgeComm that will be destroyed","lua_type":"BridgeComm"}],"returns":[],"function_type":"method","source":{"line":477,"path":"lib/init.lua"}}],"properties":[{"name":"ClassName","desc":"The class name of this class.","lua_type":"\\"BridgeCommunication\\"","source":{"line":66,"path":"lib/init.lua"}},{"name":"_EstablishedConnections","desc":"The internal tracking of established connections with clients.","lua_type":"Map<Player,Map<RemoteEvent,boolean?>>","private":true,"source":{"line":73,"path":"lib/init.lua"}},{"name":"_BridgeComms","desc":"The internal stored BridgeCommunications that were created.","lua_type":"Dictionary<BridgeComm>","private":true,"source":{"line":80,"path":"lib/init.lua"}},{"name":"_QueuedComms","desc":"The internal queued BridgeCommunications that were fired with those arguments.","lua_type":"Map<Player,Map<RemoteEvent,{any}>>","private":true,"source":{"line":89,"path":"lib/init.lua"}},{"name":"ConnectionStatus","desc":"This is a enum table used for the ConnectionStatus of [BridgeCommunication.T_ConnectionStatus]","lua_type":"I_ConnectionStatus","source":{"line":118,"path":"lib/init.lua"}},{"name":"Name","desc":"The name of the BridgeCommunication object.","lua_type":"string","source":{"line":306,"path":"lib/init.lua"}},{"name":"_BridgeFunctions","desc":"The internal function that get associated to a bridgeKey and the function called when that bridgeKey is fired.","lua_type":"Dictionary<(player: Player, ...any) -> ()>","private":true,"source":{"line":313,"path":"lib/init.lua"}},{"name":"_RemoteEvent","desc":"The RemoteEvent used internally for the BridgeCommunication object.","lua_type":"RemoteEvent","private":true,"source":{"line":320,"path":"lib/init.lua"}}],"types":[{"name":"I_ConnectionStatus","desc":"","fields":[{"name":"TIMEOUT","lua_type":"\\"TIMEOUT\\",","desc":""},{"name":"ESTABLISHED","lua_type":"\\"ESTABLISHED\\",","desc":""},{"name":"QUEUED","lua_type":"\\"QUEUED\\"","desc":""}],"source":{"line":106,"path":"lib/init.lua"}},{"name":"T_ConnectionStatus","desc":"The ConnectionStatus is returned from [BridgeCommunication.EstablishConnection]","lua_type":"\\"TIMEOUT\\" | \\"ESTABLISHED\\" | \\"QUEUED\\"","source":{"line":112,"path":"lib/init.lua"}}],"name":"BridgeCommunication","desc":"This class is designed to automate communication between the server and client it uses RemoteEvents internally.","source":{"line":57,"path":"lib/init.lua"}}')}}]);