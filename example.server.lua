local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Bootstrap = require(ReplicatedStorage.Packages.Bootstrap)
Bootstrap.ServicesDirectory = ServerScriptService.Services
Bootstrap.Services = {
    ["ClientBanService"] = {
        ["LOAD_SERVICE"] = true,
        ["REJECT_ON_MISSING"] = true,
        ["REJECT_ON_INITIALIZE_ERROR"] = true,
        ["REJECT_ON_START_ERROR"] = true,
        ["INITIALIZE_PRIORITY"] = 100,
        ["START_PRIORITY"] = 100,
    },
    ["ClientDataService"] = {
        ["LOAD_SERVICE"] = true,
        ["REJECT_ON_MISSING"] = true,
        ["REJECT_ON_INITIALIZE_ERROR"] = true,
        ["REJECT_ON_START_ERROR"] = true,
        ["INITIALIZE_PRIORITY"] = 99,
        ["START_PRIORITY"] = 99,
    },
    ["TestEnvironmentService"] = {
        ["LOAD_SERVICE"] = false,
        ["REJECT_ON_MISSING"] = false,
        ["REJECT_ON_INITIALIZE_ERROR"] = false,
        ["REJECT_ON_START_ERROR"] = false,
        ["INITIALIZE_PRIORITY"] = 1,
        ["START_PRIORITY"] = 1
    },
    ["AnalyticsService"] = {
        ["LOAD_SERVICE"] = true,
        ["REJECT_ON_MISSING"] = false,
        ["REJECT_ON_INITIALIZE_ERROR"] = false,
        ["REJECT_ON_START_ERROR"] = false,
        ["INITIALIZE_PRIORITY"] = 0,
        ["START_PRIORITY"] = 0
    }
}

Bootstrap.Start():andThen(function(services)
    print("Server has started", services)
end):catch(function(errorResponse)
    warn("Server failed to start:", errorResponse)
    
    -- close server in case of critical error
    Players.PlayerAdded:Connect(function(player)
        player:Kick("CRITICAL // Game failed to load, please rejoin the experience. If this issue persists, please contact a staff member.")
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        player:Kick("CRITICAL // Game failed to load, please rejoin the experience. If this issue persists, please contact a staff member.")
    end
end)