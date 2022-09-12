local BridgeCommunicationModule: ModuleScript? = game:GetService("ReplicatedStorage"):FindFirstChild("BridgeCommunication");
local Dependencies: Folder? = BridgeCommunicationModule:FindFirstChild("Dependencies") :: Folder?;
local TestEZ = require(Dependencies:FindFirstChild("TestEZ"));
TestEZ.TestBootstrap:run({BridgeCommunicationModule});