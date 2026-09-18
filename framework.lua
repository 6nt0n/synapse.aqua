local framework = {
    instances = {};
    services = setmetatable({}, {
        __index = function(self, service)
            local string = service:gsub("_%l", string.upper):gsub("_", ""):gsub("^%l", string.upper)
            local instance = cloneref(game:GetService(string))
            rawset(self, service, instance)
            return instance
        end
    }),
    connections = {},
    modules = {}
};

framework.unload = function()
    for _, module in pairs(framework.modules) do
        if module.unload then
            module.unload()
        end
    end
    framework.services = nil
end

local modules = framework.modules;

do -- functions
    local instance_manager = {}
    local signals = {}

    do -- instance manager
        instance_manager.new = function(class, properties)
            local _instance = Instance.new(class)
            for _property, _value in next, properties do
                _instance[_property] = _value
            end
            table.insert(framework.instances, _instance)
            return _instance
        end

        instance_manager.unload = function()
            for _, instance in pairs(framework.instances) do
                instance:Destroy()
            end
        end

        modules.instance_manager = instance_manager
    end

    do -- connections
        signals.connection = function(signal, callback)
            local connection1 = signal:Connect(callback)
            table.insert(framework.connections, connection1)
            return connection1;
        end;

        signals.lerp = function(a, b, t)
            return a + (b - a) * t
        end

        signals.unload = function()
            for _, instance in pairs(framework.connections) do
                instance:Disconnect()
            end;
        end;

        modules.signals = signals;
    end;
end;

return framework;
