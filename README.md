# Services Bootstrap
A Promise-based, anti-race condition-based, configuration-based service bootstrap

# Documentation
TODO. Read `ServiceBootstrap.lua`/`init.lua` for documentation.

# Installation
wally:
```
Bootstrap = "uiscript/services-bootstrap@1.0.0"
```

# Example Usage
Server:
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Bootstrap = require(ReplicatedStorage.Packages.ServiceBootstrap)
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
```

Client:
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local StarterPlayer = Player:WaitForChild("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local Bootstrap = require(ReplicatedStorage.Packages.ServiceBootstrap)
Bootstrap.ServicesDirectory = StarterPlayerScripts:WaitForChild("Services")
Bootstrap.Services = {
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

Bootstrap.Start():andThen(function(modules)
    print("Client has started", modules)
end):catch(function(errorResponse)
    warn("Client failed to start:", errorResponse)

    -- send failed response to server to kick player
end)
```

# License
MIT License

Copyright (c) 2023 UISCript

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
