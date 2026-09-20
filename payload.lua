local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Run     = game:GetService("RunService")
local LP      = Players.LocalPlayer

local MODS = RS:WaitForChild("Modules", 30)

local _req = require

local function null()
    local proxy
    proxy = setmetatable({}, {
        __index    = function(self) return self end,
        __newindex = function() end,
        __call     = function(self) return self end,
        __len      = function() return 0 end,
        __tostring = function() return "" end,
        __eq       = function() return false end,
        __metatable = false,
        __type     = "table",
    })
    return proxy
end

local ac_names = { Kz = true, UoEx = true, uili = true, Cyz = true }

local function is_ac(m)
    if typeof(m) ~= "Instance" then return false end
    if not m:IsA("ModuleScript") then return false end
    if not ac_names[m.Name] then return false end
    return m:IsDescendantOf(MODS)
end

require = newcclosure(function(t, ...)
    local args = {...}
    if is_ac(t) then
        return null()
    end
    return _req(t, unpack(args))
end)

pcall(function() getrenv().require = require end)
if syn and syn.require then syn.require = require end

local _gc = getgc
local hidden = setmetatable({}, { __mode = "k" })

getgc = newcclosure(function(pass)
    local g = _gc(pass)
    if type(g) ~= "table" then return g end
    local out, n = {}, 0
    for i = 1, #g do
        local v = g[i]
        if not hidden[v] then n = n + 1; out[n] = v end
    end
    return out
end)

local mt      = getrawmetatable(game)
local old_nc  = mt.__namecall
local old_idx = mt.__index

local function from_ac()
    local tb = debug.traceback()
    if type(tb) ~= "string" then return false end
    return tb:find("Kz", 1, true) or tb:find("UoEx", 1, true)
        or tb:find("Cyz", 1, true) or tb:find("uili", 1, true)
        or tb:find("Luraph", 1, true)
end

local banned = {
    Kick = 1, Ban = 1, Report = 1, Flag = 1, Punish = 1,
    ClientKick = 1, ServerKick = 1, ac_report = 1,
    anticheat = 1, cheat_detected = 1,
}

local burst = {}
local function pace(key)
    local now = tick()
    local b = burst[key]
    if not b then b = {}; burst[key] = b end
    for i = #b, 1, -1 do
        if now - b[i] > 1.0 then table.remove(b, i) end
    end
    if #b >= 25 then return false end
    b[#b + 1] = now
    return true
end

setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local m = getnamecallmethod()
    local a = {...}

    if (m == "Kick" or m == "Disconnect") and self == LP then
        return
    end

    if m == "FireServer" and typeof(self) == "Instance" then
        if banned[self.Name] and from_ac() then return end
        if from_ac() and not pace(self) then return end
    end

    return old_nc(self, ...)
end)

mt.__index = newcclosure(function(self, p)
    local v = old_idx(self, p)
    if LP.Character and self == LP.Character
       and p == "AssemblyLinearVelocity" and typeof(v) == "Vector3" then
        if v.Magnitude > 100 then return v.Unit * 100 end
    end
    return v
end)

setreadonly(mt, true)

local function reap_threads()
    local ok, reg = pcall(getreg)
    if not ok or type(reg) ~= "table" then return end
    for _, v in pairs(reg) do
        if type(v) == "thread" and coroutine.status(v) == "suspended" then
            local ok2, tb = pcall(debug.traceback, v)
            if ok2 and type(tb) == "string" then
                if tb:find("UoEx", 1, true) or tb:find("Kz", 1, true)
                   or tb:find("Cyz", 1, true) then
                    pcall(coroutine.close, v)
                end
            end
        end
    end
end

local function reap_conns()
    local sigs = {
        Run.Heartbeat, Run.RenderStepped,
        Run.PreSimulation, Run.PostSimulation, Run.Stepped,
        Players.PlayerAdded, Players.PlayerRemoving,
        LP.CharacterAdded, LP.CharacterRemoving, LP.Idled,
    }
    for _, s in ipairs(sigs) do
        local ok, conns = pcall(getconnections, s)
        if ok and type(conns) == "table" then
            for _, c in ipairs(conns) do
                local fn = c.Function
                if fn then
                    local info = debug.getinfo(fn)
                    local src = tostring(info and info.source or ""):lower()
                    if src:find("uoex", 1, true) or src:find("kz", 1, true)
                       or src:find("cyz", 1, true) or src:find("luraph", 1, true) then
                        pcall(function() c:Disconnect() end)
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.35) do
        pcall(reap_threads)
        pcall(reap_conns)
    end
end)

local AQUA = "https://raw.githubusercontent.com/6nt0n/synapse.aqua/refs/heads/main/aqua.lua"

-- wait for the local player to actually exist — we fired so early the engine
-- hadn't populated Players.LocalPlayer yet when aqua tried to read it
local Players = game:GetService("Players")
if not Players.LocalPlayer then
    print("[aqua] waiting for LocalPlayer...")
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local lp = Players.LocalPlayer
if not lp.Character then
    print("[aqua] waiting for character...")
    lp.CharacterAdded:Wait()
end

task.wait(0.5)

local ok, err = pcall(function()
    loadstring(game:HttpGet(AQUA, true))()
end)
if not ok then
    warn("aqua boot fail:", err)
end
