--- File: Parameters

--- Module: otlib
module( "otlib", package.seeall )

--[[
    Object: otlib.BaseParam
    
    The base parameter in the parameter system. Provides skeleton functions and the behavior for
    optional and default arguments.
]]
BaseParam = object:Clone()

--[[
    Variables: BaseParam Variables
    
    These variables help provide BaseParam's meager feature set. Feel free to read these values if
    you need to, but you should modify them through their appropriate functions, <Default>, 
    <MinRepeats>, and <MaxRepeats>.
    
    default - A variable of *any type* specifying the value to use if the parameter is optional
        (min repeats is 0) and left unspecified. Defaults to _nil_.
    max_repeats - The maximum *number* of times this parameter is allowed to repeat. Defaults to 
        _1_.
    min_repeats - The minimum *number* of times this parameter must repeat. Defaults to _1_. If set
        to 0 (via <MinRepeats>), this parameter becomes optional and <default> will be used if the
        parameter is left unspecified.
]]
BaseParam.default = nil
BaseParam.max_repeats = 1
BaseParam.min_repeats = 1
BaseParam.takes_rest_of_line = false


--[[
    Function: Parse
    
    Parses a string into the appropriate type for this parameter. All parameter implementations 
    should be sure to call the <BaseParam> implementation, since it defines some necessary 
    behavior.
    
    Parameters:
    
        user - The *<otlib.group> object* that we're running on behalf of.
        arg - The value of *any type* to parse from.
        
    Returns:
    
        The parsed argument of *any type* (but will be a type specific to each parameter type).
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:Parse( user, arg )
    if arg == nil then
        if self:GetMinRepeats() > 0 then
            return nil, InvalidCondition.MissingRequiredParam()
        end
        return self.default
    end
    
    return arg
end


--[[
    Function: IsValid
    
    Checks if the given argument is valid within the context of what's allowable. All parameter
    implementations should be sure to call the <BaseParam> implementation, since it defines some
    necessary behavior.
    
    Parameters:
    
        user - The *<otlib.group> object* that we're running on behalf of.
        arg - The argument of *any type* to validate (but the types will be specific to each
            parameter type).
        
    Returns:
    
        1 - A *boolean* that's true if the user can use this parameter in this context, false
            otherwise.
        2 - *Nil* if the above return is true, an *<otlib.InvalidCondition> object* explaining why
            they don't have access otherwise.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:IsValid( user, arg )    
    return true
end


--[[
    Function: Autocomplete
    
    Used to give autocomplete information for this parameter. This function should be overridden in
    each parameter implementation, since the <BaseParam> version throws an error.
    
    Parameters:
    
        user - The *<otlib.group> object* that we're running on behalf of.
        str - A *string* that represents a partial argument. Will probably need to go through a
            special form of parsing to be useful (IE, get all players whose names contain str for
            a player parameter).
        
    Returns:
    
        *Nil* or a *list table* of options the user has to autocomplete this parameter with. Nil is
            returned when the list of completes is too large or when it just doesn't make sense to
            have autocompletion.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:Autocomplete( user, str )
    error( ErrorMessages.NotImplemented, 2 )
end


--[[
    Function: ShortUsage
    
    Used to give information about the usage on this parameter as concisely as possible. This 
    function should be overridden in each parameter implementation, since the <BaseParam> version 
    throws an error.
    
    Parameters:
    
        user - The *<otlib.group> object* that we're running on behalf of.
        
    Returns:
    
        A concise *string* explaining this parameter usage.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:ShortUsage( user )
    error( ErrorMessages.NotImplemented, 2 )
end


--[[
    Function: LongUsage
    
    Used to give information about the usage on this parameter when screen space is not an issue.
    This function should be overridden in each parameter implementation, since the <BaseParam> 
    version throws an error.
    
    Parameters:
    
        user - The *<otlib.group> object* that we're running on behalf of.
        
    Returns:
    
        A *string* explaining this parameter usage.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:LongUsage( user )
    error( ErrorMessages.NotImplemented, 2 )
end


--[[
    Function: Default
    
    Set the default value of this parameter. This value is only significant if the parameter is
    optional, see <Optional>.
    
    Parameters:
    
        default - *Any type*, the value to use when the parameter is optional and unspecified.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:Default( default )
    self.default = default
    return self
end


--[[
    Function: MinRepeats
    
    Set the minimum number of times this argument must repeat. See <min_repeats>.
    
    A repeating parameter (min repeats > 1) MUST be the last parameter in an access.
    
    Parameters:
    
        min_repeats - The *number* of times to repeat, at minimum.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:MinRepeats( min_repeats )
    self.min_repeats = min_repeats
    return self
end


--[[
    Function: MaxRepeats
    
    Set the maximum number of times this argument is allowed to repeat. See <max_repeats>.
    
    A repeating parameter (max repeats > 1) MUST be the last parameter in an access.
    
    Parameters:
    
        max_repeats - The *number* of times to repeat, at maximum.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:MaxRepeats( max_repeats )
    self.max_repeats = max_repeats
    return self
end

function BaseParam:TakesRestOfLine( takes_rest_of_line )
    self.takes_rest_of_line = takes_rest_of_line
    return self
end

function BaseParam:GetDefault()
    return self.default
end

function BaseParam:GetMinRepeats()
    return self.min_repeats
end

function BaseParam:GetMaxRepeats()
    return self.max_repeats
end

function BaseParam:GetTakesRestOfLine()
    return self.takes_rest_of_line
end

NumParam = BaseParam:Clone( true )
NumParam.min = nil
NumParam.max = nil
NumParam:Default( 0 )

function NumParam:Parse( user, arg )
    local err
    arg, err = BaseParam.Parse( self, user, arg )
    if err then
        return arg, err
    end
    
    local parsed_arg = tonumber( arg )
    if not parsed_arg then
        return nil, InvalidCondition.InvalidNumber( tostring( arg ) )
    end
    
    return parsed_arg
end

function NumParam:IsValid( user, arg )
    CheckArg( 2, "NumParam:IsValid", "number", arg )
    
    local status, err = BaseParam.IsValid( self, user, arg )
    if not status then
        return status, err
    end
    
    if self.min and arg < self.min then
        return false, InvalidCondition.TooLow( arg, self.min )
    elseif self.max and arg > self.max then
        return false, InvalidCondition.TooHigh( arg, self.max )
    end
    
    return true
end

function NumParam:Autocomplete( user, cmd, arg )
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


StringParam = BaseParam:Clone( true )
StringParam:Default( "" )

function StringParam:Parse( user, arg )
    local err
    arg, err = BaseParam.Parse( self, user, arg )
    if err then
        return arg, err
    end
    
    -- This'll *probably* never happen
    if type( arg ) ~= "string" then
        return nil, InvalidCondition.InvalidString( tostring( arg ) )
    end
    
    return arg
end

function StringParam:IsValid( user, arg )
    CheckArg( 2, "StringParam:IsValid", "string", arg )
    
    local status, err = BaseParam.IsValid( self, user, arg )
    if not status then
        return status, err
    end
    
    -- TODO string restrictions
    
    return true
end

function StringParam:Autocomplete( user, cmd, arg )
    error( ErrorMessages.NotImplemented, 2 )
end
