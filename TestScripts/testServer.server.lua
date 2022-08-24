local BridgeCommunicationModule: ModuleScript? = game:GetService("ReplicatedStorage"):FindFirstChild("BridgeCommunication");
local DevDependencies: Folder? = BridgeCommunicationModule:FindFirstChild("DevDependencies");
local TestEZ = require(DevDependencies:FindFirstChild("testez"));
TestEZ.TestBootstrap:run({BridgeCommunicationModule});