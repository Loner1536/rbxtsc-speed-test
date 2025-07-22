-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local Flamework = TS.import(script, game:GetService("ReplicatedStorage"), "rbxts_include", "node_modules", "@flamework", "core", "out").Flamework
-- Base
Flamework._addPaths({ { "ReplicatedStorage", "base", "client", "controllers" } })
-- Lobby
Flamework._addPaths({ { "ReplicatedStorage", "lobby", "client", "controllers" } })
Flamework.ignite()
