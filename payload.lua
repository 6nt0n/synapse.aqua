local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LP = Players.LocalPlayer
while not LP do
    task.wait(0.1)
    LP = Players.LocalPlayer
end
print("[payload] LP:", LP.Name)

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
if not MODS then warn("[payload] no main game"); return end
print("[payload] main game confirmed")

local _req = require

local function null()
    return setmetatable({}, {
        __index    = function() return nil end,
        __newindex = function() end,
        __call     = function() return nil end,
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
    if is_ac(t) then return null() end
    return _req(t, unpack(args))
end)
print("[payload] require hook installed")

if not LP.Character then
    LP.CharacterAdded:Wait()
end
task.wait(0.5)

local AQUA = "https://raw.githubusercontent.com/6nt0n/synapse.aqua/refs/heads/main/aqua?v=" .. tostring(os.time())
local body = game:HttpGet(AQUA, true)
print("[payload] aqua fetched:", #body)

local ok, err = xpcall(function()
    loadstring(body)()
end, function(e) return tostring(e) .. "\n" .. debug.traceback("", 2) end)
if not ok then
    warn("aqua boot fail:\n" .. err)
end
