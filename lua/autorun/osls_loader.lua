---------------------------------------
---------------------------------------
--      Open Source Light Sabers     --
--                                   --
--            Created by             --
--       Jan 'Oninoni' Ziegler       --
--                                   --
-- This software can be used freely, --
--    but only distributed by me.    --
--                                   --
--    Copyright © 2023 Jan Ziegler   --
---------------------------------------
---------------------------------------

---------------------------------------
-- Open Source Light Sabers | Loader --
---------------------------------------

OSLS = OSLS or {}
OSLS.Modules = OSLS.Modules or {}
OSLS.LoadedModules = OSLS.LoadedModules or {}

function OSLS:Message(msg)
	if msg then
		MsgC(Color(0, 255, 255), "[OSLS] " .. msg .. "\n")
	end
end

function OSLS:LoadModule(name)
	if OSLS.LoadedModules[name] then return end

	local moduleDirectory = "osls/" .. name .. "/"

	if SERVER then
		AddCSLuaFile(moduleDirectory .. "sh_index.lua")
	end
	include(moduleDirectory .. "sh_index.lua")

	local entityDirectory = moduleDirectory .. "entities/"
	local _, entityDirectories = file.Find(entityDirectory .. "*", "LUA")
	for _, entityName in pairs(entityDirectories) do
		local entDirectory = entityDirectory .. entityName .. "/"

		local oldEnt = ENT
		ENT = {
			ClassName = entityName,
			Folder = "entities/" .. entityName,
		}

		if SERVER then
			AddCSLuaFile(entDirectory .. "shared.lua")
			AddCSLuaFile(entDirectory .. "cl_init.lua")

			include(entDirectory .. "shared.lua")
			include(entDirectory .. "init.lua")
		end

		if CLIENT then
			include(entDirectory .. "shared.lua")
			include(entDirectory .. "cl_init.lua")
		end

		scripted_ents.Register(ENT, entityName)
		ENT = oldEnt

		OSLS:Message("Loaded Entity \"" .. entityName .. "\"")
	end

	local weaponDirectory = moduleDirectory .. "weapons/"
	local _, weaponDirectories = file.Find(weaponDirectory .. "*", "LUA")
	for _, weaponName in pairs(weaponDirectories) do
		local wepDirectory = weaponDirectory .. weaponName .. "/"

		local oldSWEP = SWEP
		SWEP = {
			ClassName = weaponName,
			Folder = "weapons/" .. weaponName,
			Primary = {},
			Secondary = {},
		}

		if SERVER then
			AddCSLuaFile(wepDirectory .. "shared.lua")
			AddCSLuaFile(wepDirectory .. "cl_init.lua")

			include(wepDirectory .. "shared.lua")
			include(wepDirectory .. "init.lua")
		end

		if CLIENT then
			include(wepDirectory .. "shared.lua")
			include(wepDirectory .. "cl_init.lua")
		end

		weapons.Register(SWEP, weaponName)
		SWEP = oldSWEP

		OSLS:Message("Loaded Weapon \"" .. weaponName .. "\"")
	end

	local stoolsDirectory = moduleDirectory .. "stools/"
	local _, stoolsDirectories = file.Find(stoolsDirectory .. "*", "LUA")
	for _, stoolName in pairs(stoolsDirectories) do
		local stoolDirectory = stoolsDirectory .. stoolName .. "/"

		local oldTOOL = TOOL

		local ToolObj = getmetatable(weapons.Get("gmod_tool").Tool["remover"])
		TOOL = ToolObj:Create()
		TOOL.Mode = stoolName

		if SERVER then
			AddCSLuaFile(stoolDirectory .. "shared.lua")

			include(stoolDirectory .. "shared.lua")
		end

		if CLIENT then
			include(stoolDirectory .. "shared.lua")
		end

		TOOL:CreateConVars()

		weapons.GetStored("gmod_tool").Tool[stoolName] = TOOL

		TOOL = oldTOOL
	end

	if CLIENT then
		timer.Create("OSLS.ReloadSpawnmenu", 1, 1, function()
			RunConsoleCommand("spawnmenu_reload")
		end)
	end

	hook.Run("OSLS.ModuleLoaded", name, moduleDirectory)

	OSLS.LoadedModules[name] = true

	OSLS:Message("Loaded Module \"" .. name .. "\"")
end

function OSLS:RequireModules(...)
	for _, moduleName in pairs({...}) do
		if OSLS.Modules[moduleName] then
			self:LoadModule(moduleName)
		else
			self:Message("Module \"" .. moduleName .. "\" is required! Please enable it!")
		end
	end
end

function OSLS:LoadAllModules()
	if self.LoadingActive then
		self:Message("Loading all Modules in Recursion! Please Report Immediatly!")
		debug.Trace()
	end

	if SERVER then
		AddCSLuaFile("osls/config.lua")
	end
	include("osls/config.lua")

	if SERVER then
		print("\n")
		self:Message("Loading Serverside...")
	end

	if CLIENT then
		print("\n")
		self:Message("Loading Clientside...")
	end

	self.LoadedModules = {}
	self.LoadingActive = true

	for moduleName, enabled in pairs(self.Modules) do
		if enabled then
			self:LoadModule(moduleName)
		end
	end

	hook.Run("OSLS.ModulesLoaded")

	self.LoadingActive = nil
end

hook.Add("PostGamemodeLoaded", "OSLS.Load", function()
	OSLS:LoadAllModules()
end)