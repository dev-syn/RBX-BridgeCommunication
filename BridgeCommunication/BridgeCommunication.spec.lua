local isServer: boolean = game:GetService("RunService"):IsServer();
--- @module BridgeCommunication/Types
local Types = require(script.Parent:FindFirstChild("Types"));
type BridgeCommunication = Types.BridgeCommunication;

return function()
    local BridgeCommunication: Types.Schema_BridgeCommunication = require(script.Parent);

    if isServer then
        describe("BridgeCommunication Server Tests",function()
            it("Should be able to create a BridgeCommunication",function()
                local testBridgeComm: BridgeCommunication = BridgeCommunication.new("TestBridgeComm");
            end);
        end);
    else
        describe("BridgeCommunication Client Tests",function()
            it("Should be able to wait for a BridgeCommunication",function()
                
            end);
        end);
    end
end