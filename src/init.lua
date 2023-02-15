--[[
    A Promise-based, anti-race condition-based, configuration-based service bootstrap

    15/02/2023, UIScript

    Documentation:
        Usage:
            local Bootstrap = require(ReplicatedStorage.Packages.ServicesBootstrap)
            Bootstrap.ServicesDirectory = <path to services>
            Bootstrap.Services = {<list of service configurations>} -- see below

            Bootstrap.Start():andThen(function(services)
                print("Game loaded", services)
            end):catch(function(errorMessage)
                warn("Game failed to load:", errorMessage)
            end)
            
        Service Requirements:
            Services requires an Initialize and Start function **unless** Bootstrap.REJECT_ON_INITIALIZE_ERROR == false and/or Bootstrap.REJECT_ON_START_ERROR == false respectively
                Service.Initialize = <function>
                Service.Start = <function>

        Global Configuration:
            REQUIRED: Bootstrap.ServicesDirectory = <path to services> -- the path to folder/directory containing ModuleScripts in which StartServices will loop through
            REQUIRED: Bootstrap.Services = <table> -- the services' configurations (see below for documentation)
            OPTIONAL: Bootstrap.Promise = <path to evaera/promise*> -- the path to evaera's Promise module *(or other Promise modules, but remember to modify methods if necessary).
                default = require(ReplicatedStorage.Packages.Promise)
            OPTIONAL: Bootstrap.ASYNC_INITIALIZE_SERVICES = true | false -- determines whether initializing should be ran asynchronously or in order by priority
                default = false
            OPTIONAL: Bootstrap.ASYNC_START_SERVICES = true | false -- determines whether starting should be ran asynchronously or in order by priority
                default = true
        
        Service Configuration (root Bootstrap.Services):
            IMPORTANT: No checks are made on any service configuration, so double-check your tables

            ["ExampleService"] = {
                ["LOAD_SERVICE"] = true | false,  -- determines whether a service should be initialized and started
                ["REJECT_ON_MISSING] = true | false, -- determines whether the entire StartServices promise should reject if the service is missing
                ["REJECT_ON_INITIALIZE_ERROR"] = true | false, -- determines whether the entire StartServices promise should reject if the service fails to initialize
                ["REJECT_ON_START_ERROR"] = true | false, -- determines whether the entire StartServices promise should reject if the service fails to start
                ["INITIALIZE_PRIORITY"] = 100, -- determines the order in which services initialize. higher number = higher priority (ignored if Bootstrap.ASYNC_INITIALIZE_SERVICES == true)
                ["START_PRIORITY"] = 100 -- determines the order in which services initialize. higher number = higher priority (ignored if Bootstrap.ASYNC_START_SERVICES == true)
            }
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = {}
Bootstrap.ServicesDirectory = nil
Bootstrap.Services = {}
Bootstrap.Promise = require(ReplicatedStorage.Packages.Promise) -- default path to evaera/promise
Bootstrap.ASYNC_INITIALIZE_SERVICES = false -- ignores INITIALIZE_PRIORITY and START_PRIORITY
Bootstrap.ASYNC_START_SERVICES = true -- ignores INITIALIZE_PRIORITY and START_PRIORITY

local function StartServices()
    local Promise = Bootstrap.Promise

    -- sort modules
    local sortedModules = {}

    for serviceName, _ in pairs(Bootstrap.Services) do
        if Bootstrap.Services[serviceName]["LOAD_SERVICE"] == false then
            continue
        end

        local moduleScript = Bootstrap.ServicesDirectory:FindFirstChild(serviceName)
        
        if moduleScript ~= nil then
            if moduleScript:IsA("ModuleScript") == true then
                table.insert(sortedModules, {InitializePriority = Bootstrap.Services[serviceName]["INITIALIZE_PRIORITY"], StartPriority = Bootstrap.Services[serviceName]["START_PRIORITY"], ServiceName = serviceName, ModuleScript = moduleScript})
            else
                if moduleScript == nil and Bootstrap.Services[serviceName]["REJECT_ON_MISSING"] == true then
                    return Promise.reject(serviceName.. " is not a valid module")
                end
            end
        elseif moduleScript == nil and Bootstrap.Services[serviceName]["REJECT_ON_MISSING"] == true then
            return Promise.reject(serviceName.. " is not a valid module")
        end
    end

    -- sort function
    local function sort(by)
        table.sort(sortedModules, function(newModuleData, oldModuleData)
            return newModuleData[by] > oldModuleData[by]
        end)
    end

    -- require()[method]() promise
    local function try(moduleScript, method)
        return Promise.try(function()
            local service = require(moduleScript)
            service[method]()
            service[method] = nil
        end)
    end

    -- run initialize/start promise
    local function run(method)
        return Promise.try(function()
            if method == "Initialize" then
                sort("InitializePriority")
            elseif method == "Start" then
                sort("StartPriority")
            end
            local servicePromises = {}

            for moduleIndex = #sortedModules, 1, -1 do
                local serviceName = sortedModules[moduleIndex].ServiceName
                local moduleScript = sortedModules[moduleIndex].ModuleScript
                
                if (method == "Initialize" and Bootstrap.ASYNC_INITIALIZE_SERVICES == true) or (method == "Start" and Bootstrap.ASYNC_START_SERVICES == true) then
                    table.insert(servicePromises, (function()
                        return Promise.new(function(resolve, reject)
                            local runServiceSuccess, runServiceResponse = try(moduleScript, method):await()

                            if runServiceSuccess == false then
                                table.remove(sortedModules, moduleIndex)
    
                                if (method == "Initialize" and Bootstrap.Services[serviceName]["REJECT_ON_INITIALIZE_ERROR"] == true) or (method == "Start" and Bootstrap.Services[serviceName]["REJECT_ON_START_ERROR"] == true) then
                                    reject(runServiceResponse)
                                    return
                                end
                            end

                            resolve()
                        end)
                    end)())
                else
                    local runServiceSuccess, runServiceResponse = try(moduleScript, method):await()
                    
                    if runServiceSuccess == false then
                        table.remove(sortedModules, moduleIndex)
                        
                        if (method == "Initialize" and Bootstrap.Services[serviceName]["REJECT_ON_INITIALIZE_ERROR"] == true) or (method == "Start" and Bootstrap.Services[serviceName]["REJECT_ON_START_ERROR"] == true) then
                            return Promise.reject(runServiceResponse)
                        end
                    elseif runServiceSuccess == true then
                        table.insert(servicePromises, Promise.resolve())
                    end
                end
            end

            return Promise.all(servicePromises):await()
        end)
    end

    -- main promise
    local function startServices()
        return Promise.try(function()
            local initializedAllSuccess, initializedAllResponse = run("Initialize"):await()
            
            if initializedAllSuccess == true then
                local startedAllSuccess, startedAllResponse = run("Start"):await()

                if startedAllSuccess == true then
                    return Promise.resolve()
                else
                    return Promise.reject(startedAllResponse)
                end
            else
                return Promise.reject(initializedAllResponse)
            end
        end)
    end

    local finalSuccess, finalResponse = startServices():await()
    
    if finalSuccess == true then
        return Promise.resolve(sortedModules)
    else
        return Promise.reject(finalResponse)
    end
end

-- server starter
Bootstrap.Start = function()
    assert(typeof(Bootstrap.ServicesDirectory) == "Instance", "Failed to start services bootstrap (Bootstrap.ServicesDirectory is not a valid Instance, got " ..typeof(Bootstrap.ServicesDirectory).. ")")
    assert(typeof(Bootstrap.Services) == "table", "Failed to start services bootstrap (Bootstrap.Services is not a valid table, got " ..typeof(Bootstrap.Services).. ")")
    assert(typeof(Bootstrap.Promise) == "Instance" or typeof(Bootstrap.Promise) == "table", "Failed to start services bootstrap (Bootstrap.Promise is not a valid Instance, got " ..typeof(Bootstrap.Promise).. ")")
    if typeof(Bootstrap.Promise) == "Instance" then
        Bootstrap.Promise = require(Bootstrap.Promise)
    end
    assert(typeof(Bootstrap.ASYNC_INITIALIZE_SERVICES) == "boolean", "Failed to start services bootstrap (Bootstrap.ASYNC_INITIALIZE_SERVICES is not a valid boolean, got " ..typeof(Bootstrap.ASYNC_INITIALIZE_SERVICES).. ")")
    assert(typeof(Bootstrap.ASYNC_START_SERVICES) == "boolean", "Failed to start services bootstrap (Bootstrap.ASYNC_START_SERVICES is not a valid boolean, got " ..typeof(Bootstrap.ASYNC_START_SERVICES).. ")")

    return StartServices()
end

return Bootstrap