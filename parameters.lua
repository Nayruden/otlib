--- File: Parameters

--- Module: otlib
module( "otlib", package.seeall )

BaseParam = object:Clone()
BaseParam.optional = false

--[[
    Variables: Messages
    
    Messages.NotSpecified - Message given when there is no specified value and the argument is not
        optional.
]]
BaseParam.Messages = {
    NotSpecified = InvalidCondition( "argument is required and was left unspecified" )
}

function BaseParam:Autocomplete( user, cmd, arg )
    error( ErrorMessages.NotImplemented, 2 )
end

function BaseParam:IsValid( user, arg )
    if arg == nil then
        if not self.optional then
            return false, BaseParam.Messages.NotSpecified()
        end
    end
    
    return true
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

--[[
    Variables: Messages
    
    Messages.TooHigh - Message given when the specified value is too high.
    Messages.TooLow - Message given when the specified value is too low.
    Messages.Invalid - Message given when the specified value is not a number.
]]
NumParam.Messages = {
    TooHigh = InvalidCondition( "specified number %i is above your allowed maximum of %i" ),
    TooLow  = InvalidCondition( "specified number %i is below your allowed minimum of %i" ),
    Invalid = InvalidCondition( "invalid number \"%s\" specified" ),
}

function NumParam:Autocomplete( user, cmd, arg )
    error( ErrorMessages.NotImplemented, 2 )
end

function NumParam:IsValid( user, arg )
    local ex = StoredExpression()
    if not ex( self:Parent():IsValid( user, arg ) ) then
        return ex.unpack()
    end
    
    if arg == nil then
        arg = self.default
    end
    
    if arg < self.min then
        return false, NumParam.Messages.TooLow( arg, self.min )
    elseif arg > self.max then
        return false, NumParam.Messages.TooHigh( arg, self.max )
    end
    
    return true
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
