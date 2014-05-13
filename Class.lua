-- Import
local type = type
local error = error
local pairs = pairs
local getmetatable = getmetatable
local setmetatable = setmetatable

local Class = {}
setfenv(1, Class)

local function copyProperties(target, copy)
    setmetatable(copy, getmetatable(target))
    for key, val in pairs(target) do
        if type(val) == "table" then
            copy[key] = {}
            copyProperties(val, copy[key])
        else
            copy[key] = val
        end
    end
end

local function clone(self)
    local copy = {}
    copyProperties(self, copy)
    return copy
end

local function new(class, parent)
    local classMetatable = getmetatable (class) or {}

    if parent then
        if type(parent) ~= "table" then
            error ("Parent class provided is not a table")
        else
            if classMetatable and classMetatable.__index then
                error ("Argument class already inherits from another class")
            else
                classMetatable.__index = parent
            end
        end
    end

    class.init = class.init or function () end
    class.clone = class.clone or clone

    classMetatable.__call = function (_, ...)
        local instance = setmetatable ({}, {
            __index = class
        })
        instance:init(...)
        return instance
    end


    return setmetatable (class, classMetatable)
end

setmetatable(Class,
{
    __call = function (_, class, parent)
        return new(class, parent)
    end
})

return Class
