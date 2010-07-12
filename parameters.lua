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
    CheckArg( 1, "BaseParam:MinRepeats", "number", min_repeats )
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
    CheckArg( 1, "BaseParam:MaxRepeats", "number", max_repeats )
    self.max_repeats = max_repeats
    return self
end


--[[
    Function: TakesRestOfLine
    
    Set the argument to take the rest of whatever arguments are available. Really only useful for a
    <otlib.StringParam>, but defined here anyways just in case.
    
    A parameter that takes the rest of the line MUST be the last parameter in an access and cannot
    be a repeating parameter.
    
    Parameters:
    
        takes_rest_of_line - The *boolean* stating whether or not the argument takes the rest of
            argument line.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:TakesRestOfLine( takes_rest_of_line )
    CheckArg( 1, "BaseParam:TakesRestOfLine", "boolean", takes_rest_of_line )
    self.takes_rest_of_line = takes_rest_of_line
    return self
end


--[[
    Function: GetDefault
    
    Gets the default for this parameter. See <Default>.
        
    Returns:
    
        The variable of *any type* that represents the default.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:GetDefault()
    return self.default
end


--[[
    Function: GetMinRepeats
    
    Gets the min repeats for this parameter. See <MinRepeats>.
        
    Returns:
    
        The *number* of minimum repititions for this parameter.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:GetMinRepeats()
    return self.min_repeats
end


--[[
    Function: GetMaxRepeats
    
    Gets the max repeats for this parameter. See <MaxRepeats>.
        
    Returns:
    
        The *number* of maximum repititions for this parameter.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:GetMaxRepeats()
    return self.max_repeats
end


--[[
    Function: GetTakesRestOfLine
    
    Gets whether or not this parameter takes the rest of the line. See <TakesRestOfLine>.
        
    Returns:
    
        The *boolean* stating whether or not this argument takes the rest of the line.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:GetTakesRestOfLine()
    return self.takes_rest_of_line
end


--[[
    Function: ToString
    
    Converts any options on this parameter that would be used for user permissions to a string that
    can be read in again later using <FromString>. IE, you'd use this function to save permissions.
            
    Returns:
    
        The serialized permission *string*. Implementations return "*" if anything is allowed.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:ToString()
    error( ErrorMessages.NotImplemented, 2 )
end


--[[
    Function: FromString
    
    Loads in user permissions from a string produced by <ToString> for this parameter.
            
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:FromString( str )
    error( ErrorMessages.NotImplemented, 2 )
end


--[[
    Object: otlib.NumParam
    
    The number parameter. Provides a way to read in numbers from the user.
]]
NumParam = BaseParam:Clone( true )
NumParam.min = nil
NumParam.max = nil
NumParam.round_to = nil
NumParam:Default( 0 )


--[[
    Function: Parse
    
    See <otlib.BaseParam.Parse>.
            
    Returns:
    
        The parsed *number*.
        
    Revisions:
    
        v1.00 - Initial.
]]
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
    
    if self.round_to then
        parsed_arg = Round( parsed_arg, self.round_to )
    end
    
    return parsed_arg
end


--[[
    Function: IsValid
    
    See <otlib.BaseParam.IsValid>.
        
    Revisions:
    
        v1.00 - Initial.
]]
function NumParam:IsValid( user, arg )
    -- TODO, check user?
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


--[[
    Function: Autocomplete
    
    See <otlib.BaseParam.Autocomplete>.
        
    Revisions:
    
        v1.00 - Initial.
]]
function NumParam:Autocomplete( user, cmd, arg )
    error( ErrorMessages.NotImplemented, 2 )
end


--[[
    Function: Min
    
    Sets the minimum number for this argument.
    
    Parameters:
    
        min - The minimum *number* allowed on this argument.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function NumParam:Min( min )
    CheckArg( 1, "NumParam:Min", "number", min )    
    self.min = min
    return self
end


--[[
    Function: Max
    
    Sets the maximum number for this argument.
    
    Parameters:
    
        min - The maximum *number* allowed on this argument.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function NumParam:Max( max )
    CheckArg( 1, "NumParam:Max", "number", max )
    self.max = max
    return self
end


--[[
    Function: RoundTo
    
    Sets what to round this argument too during <Parse>.
    
    Parameters:
    
        round_to - The *number* of the place to round this number to (see <otlib.Round>) or *nil*.
            If nil, no rounding is performed, which is the default behavior.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function NumParam:RoundTo( round_to )
    CheckArg( 1, "NumParam:Round", {"nil", "number"}, round_to )
    self.round_to = round_to
    return self
end


--[[
    Function: ToString
    
    See <otlib.BaseParam.ToString>.
    
    Returns:
    
        A *string* in the format "[<min>]:[<max>]" or "*" if there is no min or max.
        
    Revisions:
    
        v1.00 - Initial.
]]
function NumParam:ToString()
    local str = ""
    if self.min then
        str = str .. tostring( self.min )
    end
    if self.min or self.max then -- Has either
        str = str .. ":"
    else
        str = "*"
    end
    if self.max then
        str = str .. tostring( self.max )
    end
    
    return str
end


--[[
    Function: FromString
    
    See <otlib.BaseParam.FromString> and <ToString>.
        
    Revisions:
    
        v1.00 - Initial.
]]
function NumParam:FromString( str )
    CheckArg( 1, "NumParam:FromString", "string", str )
    
    local min, max = unpack( Explode( str, ":" ) )
    if tonumber( min ) then
        self.min = tonumber( min )
    end
    if tonumber( max ) then
        self.max = tonumber( max )
    end
    
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
