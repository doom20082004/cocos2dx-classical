function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local CC_INHERITED_FROM_NATIVE_CLASS = 1
local CC_INHERITED_FROM_LUA = 2
function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == CC_INHERITED_FROM_NATIVE_CLASS) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
        end

        cls.ctor = function() end
        cls.dtor = function() end
        cls.__cname = classname
        cls.__ctype = CC_INHERITED_FROM_NATIVE_CLASS

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = clone(super)
            cls.super = super
        end

        cls.ctor = function() end
        cls.dtor = function() end
        cls.__cname = classname
        cls.__ctype = CC_INHERITED_FROM_LUA
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

function ripairs(t)
    local max = 1
    while t[max] ~= nil do
        max = max + 1
    end
    local function ripairs_it(t, i)
        i = i-1
        local v = t[i]
        if v ~= nil then
            return i,v
            else
            return nil
        end
    end
    return ripairs_it, t, max
end

function len(t)
    if type(t) == "table" then
        local c = 0
        for _,v in pairs(t) do
            c = c + 1
        end
        return c
    else
        return #t
    end
end

function const(const_table)
    local function const_meta(const_table)
        local mt = {
            __index = function (t, k)
                if type(const_table[k]) == "table" then
                    const_table[k] = const(const_table[k])
                end
                return const_table[k]
            end,
            __newindex = function (t,k,v)
                print("can't update " .. tostring(const_table) .. "[" .. tostring(k) .. "] = " .. tostring(v))
            end
        }
        return mt
    end
    
    local t = {}
    setmetatable(t, const_meta(const_table))
    return t
end