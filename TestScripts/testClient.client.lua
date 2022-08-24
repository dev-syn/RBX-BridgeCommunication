local BridgeCommunicationModule: ModuleScript? = game:GetService("ReplicatedStorage"):FindFirstChild("BridgeCommunication");
local Dependencies: Folder? = BridgeCommunicationModule:FindFirstChild("Dependencies") :: Folder?;
local TestEZ = require(Dependencies:FindFirstChild("testez"));
TestEZ.TestBootstrap:run({BridgeCommunicationModule});