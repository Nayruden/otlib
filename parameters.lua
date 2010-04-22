--- File: Parameters

--- Module: otlib
module( "otlib", package.seeall )

BaseParam = object:Clone()
BaseParam.optional = false

function BaseParam:Parse( str )
    error( ErrorMessages.NotImplemented, 2 )
end

function BaseParam:IsValid( user, arg )
    if arg == nil then
        if not self.optional then
            return false, InvalidCondition.NotSpecified()
        end
    end
    
    return true
end

function BaseParam:Autocomplete( user, cmd, arg )
    error( ErrorMessages.NotImplemented, 2 )
end

function BaseParam:Usage()
    error( ErrorMessages.NotImplemented, 2 )
end

function BaseParam:Optional( is_optional )
    self.optional = is_optional
    return self
end

function BaseParam:Default( default )
    self.default = default
    return self
end

NumParam = BaseParam:Clone( true )
NumParam.min = -math.huge
NumParam.max = math.huge
NumParam.default = 0


function NumParam:IsValid( user, arg )
    local ex = StoredExpression()
    if not ex( self:Parent():IsValid( user, arg ) ) then
        return ex.unpack()
    end
    
    if arg == nil then
        arg = self.default
    end
    
    if arg < self.min then
        return false, InvalidCondition.TooLow( arg, self.min )
    elseif arg > self.max then
        return false, InvalidCondition.TooHigh( arg, self.max )
    end
    
    return true
end

function NumParam:Autocomplete( user, cmd, arg )
    error( ErrorMessages.NotImplemented, 2 )
end

function NumParam:Usage()
    error( ErrorMessages.NotImplemented, 2 )
end

function NumParam:Min( min )
    self.min = min
    return self
end

function NumParam:Max( max )
    self.max = max
    return self
end
