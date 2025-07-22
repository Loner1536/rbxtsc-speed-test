-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local Flamework = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@flamework", "core", "out").Flamework
-- Base
Flamework._addPaths({ { "ServerScriptService", "base", "server", "services" } })
-- Lobby
Flamework._addPaths({ { "ServerScriptService", "lobby", "server", "services" } })
Flamework.ignite()
