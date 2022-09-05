local isServer: boolean = game:GetService("RunService"):IsServer();

return function()
    --- @module lib/init
    local BridgeCommunication = require(script.Parent);
    BridgeCommunication.Init();
    type BridgeComm = BridgeCommunication.BridgeComm;

    if isServer then
        describe("BridgeCommunication Server Tests",function()
            local testBridgeComm: BridgeComm;
            it("Should be able to create a BridgeCommunication",function()
                testBridgeComm = BridgeCommunication.new("BridgeCommunication-TestBridgeComm");
                expect(testBridgeComm).to.be.ok();
            end);
            it("Should be able to SetCommBridge",function()
                    testBridgeComm:SetCommBridge("Message",function(player: Player,...: any)
                    warn("Server recieved message from client: ",...);
                end);
            end);
            it("Should be able to fire the client",function()
                local player: Player = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait();
                print("Player: ",player);
                testBridgeComm:FireClient(player,"Message","This is a message sent from the server.");
            end);
        end);
    else
        describe("BridgeCommunication Client Tests",function()
            local testBridgeComm: BridgeComm;
            it("Should be able to wait for a BridgeCommunication",function()
                testBridgeComm = BridgeCommunication.WaitForBridgeComm("BridgeCommunication-TestBridgeComm") :: BridgeComm;
                expect(testBridgeComm).to.be.ok();
            end);
            it("Should be able to SetCommBridge",function()
                testBridgeComm:SetCommBridge("Message",function(player: Player,...: any)
                    warn("Client recieved message from server: ",...);
                end);
            end);
            it("Should be able to fire the server",function()
                testBridgeComm:FireServer("Message","This is a message sent from the client.");
            end);
        end);
    end
end