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
    you need to, but you should modify them through their appropriate functions, <Optional> and
    <Default>.
    
    optional - A *boolean* of whether or not the argument is optional. Defaults to _false_.
    default - A variable of *any type* specifying the value to use if the parameter is optional and
        left unspecified. Defaults to _nil_.
]]
BaseParam.optional = false
BaseParam.default = nil


--[[
    Function: Parse
    
    Parses a string into the appropriate type for this parameter. This function should be
    overridden in each parameter implementation, since the <BaseParam> version throws an error.
    
    Parameters:
    
        user - The *<otlib.group> object* that we're running on behalf of.
        str - The *string* to parse.
        
    Returns:
    
        The parsed argument of *any type* (but will be a type specific to each parameter type).
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:Parse( user, str )
    error( ErrorMessages.NotImplemented, 2 )
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
    if arg == nil then
        if not self.optional then
            return false, InvalidCondition.MissingRequiredParam()
        end
    end
    
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
    Function: Optional
    
    Set this parameter as optional or not.
    
    Parameters:
    
        is_optional - A *boolean* of whether or not this parameter is optional. If optional and the
            parameter is left unspecified, a default value will be used, see <Default>.
        
    Returns:
    
        *Self*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function BaseParam:Optional( is_optional )
    self.optional = is_optional
    return self
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

NumParam = BaseParam:Clone( true )
NumParam.min = nil
NumParam.max = nil
NumParam:Default( 0 )


function NumParam:IsValid( user, arg )
    local ex = StoredExpression()
    if not ex( self:Parent():IsValid( user, arg ) ) then
        return ex.unpack()
    end
    
    if arg == nil then
        arg = self.default
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
