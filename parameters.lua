--- File: Parameters

--- Module: otlib
module( "otlib", package.seeall )

NumParam = object:Clone()
NumParam.optional = false
NumParam.min = -math.huge
NumParam.max = math.huge
NumParam.default = 0

local meta = getmetatable( NumParam )
function meta:__call()
    return self:Clone()
end

function NumParam:Autocomplete( user, cmd, arg )
    error( ErrorMessages.NotImplemented, 2 )
end

function NumParam:IsValid( user, arg )
    if arg == nil then
        if not self.optional then
            return false, "some message"
        else
            arg = self.default
        end
    end
    
    if arg < self.min then
        return false, "some message"
    elseif arg > self.max then
        return false, "some message"
    end
    
    return true
end

function NumParam:Usage()
    error( ErrorMessages.NotImplemented, 2 )
end

function NumParam:Optional( is_optional )
    self.optional = is_optional
    return self
end

function NumParam:Min( min )
    self.min = min
    return self
end

function NumParam:Max( max )
    self.max = max
    return self
end

function NumParam:Default( default )
    self.default = default
    return self
end
