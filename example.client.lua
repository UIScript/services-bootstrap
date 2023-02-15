local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local StarterPlayer = Player:WaitForChild("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local Bootstrap = require(ReplicatedStorage.Packages.ServiceBootstrap)
local BootstrapSettings = {
    ServicesDirectory = StarterPlayerScripts:WaitForChild("Services"),
    Services = {
        ["ClientDataReceiverService"] = {
            ["LOAD_SERVICE"] = true,
            ["REJECT_ON_MISSING"] = true,
            ["REJECT_ON_INITIALIZE_ERROR"] = true,
            ["REJECT_ON_START_ERROR"] = true,
            ["INITIALIZE_PRIORITY"] = 100,
            ["START_PRIORITY"] = 100,
        },
        ["UIService"] = {
            ["LOAD_SERVICE"] = true,
            ["REJECT_ON_MISSING"] = true,
            ["REJECT_ON_INITIALIZE_ERROR"] = true,
            ["REJECT_ON_START_ERROR"] = true,
            ["INITIALIZE_PRIORITY"] = 10,
            ["START_PRIORITY"] = 10,
        },
        ["SFXService"] = {
            ["LOAD_SERVICE"] = true,
            ["REJECT_ON_MISSING"] = false,
            ["REJECT_ON_INITIALIZE_ERROR"] = false,
            ["REJECT_ON_START_ERROR"] = false,
            ["INITIALIZE_PRIORITY"] = 2,
            ["START_PRIORITY"] = 2
        }
    }
}


Bootstrap.Start(BootstrapSettings):andThen(function(modules)
    print("Client has started", modules)
end):catch(function(errorResponse)
    warn("Client failed to start:", errorResponse)

    -- send failed response to server to kick player
end)