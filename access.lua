--- File: Access
-- TODO: Create... something... to allow consoles full access no matter what permissions are

--- Module: otlib
module( "otlib", package.seeall )


--[[
    Object: otlib.InvalidCondition
]]
InvalidCondition = object:Clone( true )


--[[
    Variables: Denied Levels
    
    This is used in <InvalidCondition>, a return from <otlib.group.CheckAccess> to specify what 
    part of the access level an access check failed on.
        
    DeniedLevel.NoAccess - The user has no access to this command at all.
    DeniedLevel.Parameters - The specified arguments did not meet the requirements for the access
        being used.
    DeniedLevel.UserParameters - The specified arguments met the hard requirements for the access 
        being used, but not this particular user's access to the command.
]]
InvalidCondition.DeniedLevel = {
    NoAccess = 1,
    Parameters = 2,
    UserParameters = 3,
}


--[[
    Function: Init
    
    Called when a new InvalidCondition object is created by using the prototype as a functor.
    
    Parameters:
    
        ... - If this immediate parent of this new object is <InvalidCondition> (setuping up a new
            invalid condition), this value should be a single *string* specifying the unformatted 
            message for the condition. Otherwise, if the condition is already setup, the values 
            should be any number of *any type* which is directly passed into format on the 
            unformatted string.
        
    Revisions:

        v1.00 - Initial.
]]
function InvalidCondition:Init( ... )
    -- Dual purpose, can define the base with the unformatted string, or if we've already defined
    -- the base, the arguments must be the format.
    if self.unformatted then
        self.message = self.unformatted:format( ... )
    else
        self.unformatted = (...)
    end
end


--[[
    Function: SetLevel
    
    Sets the level for this invalid condition, see <Denied Levels>.
    
    Parameters:
    
        level - The *level* to set to.
        
    Returns:
    
        *Self*.
        
    Revisions:

        v1.00 - Initial.
]]
function InvalidCondition:SetLevel( level )
    self.level = level
    
    return self
end


--[[
    Function: GetLevel
    
    Gets the level for the invalid condition, see <Denied Levels>.
    
    Returns:
    
        The *level*.
        
    Revisions:
    
        v1.00 - Initial.
]]
function InvalidCondition:GetLevel()
    return self.level
end


--[[
    Function: SetParameterNum
    
    Sets the parameter number the invalid condition occured on.
    
    Parameters:
    
        num - The parameter *number*.
        
    Returns:
    
        *Self*.
        
    Revisions:

        v1.00 - Initial.
]]
function InvalidCondition:SetParameterNum( num )
    self.param_num = num
    
    return self
end


--[[
    Function: GetParameterNum
    
    Gets the parameter number the invalid condition occured on, if applicable.
    
    Returns:
    
        The parameter *number* or *nil*. Nil is used when a parameter number is not applicable.
        
    Revisions:
    
        v1.00 - Initial.
]]
function InvalidCondition:GetParameterNum()
    return self.param_num
end


--[[
    Function: GetMessage
    
    Gets the message for the invalid condition, if one has been created yet.
    
    Returns:
    
        The *string* of the formatted message or *nil* if one has yet to be created.
        
    Revisions:
    
        v1.00 - Initial.
]]
function InvalidCondition:GetMessage()
    return self.message
end

--[[
    Variables: InvalidConditions
    
    AccessDenied - Given when the user has no permission to the access at all.
    NotSpecified - Given when there is no specified value and the argument is not optional.
    TooHigh - Given when the specified value is too high.
    TooLow - Given when the specified value is too low.
    Invalid - Given when the specified value is not a number.
]]
InvalidCondition.AccessDenied           = InvalidCondition( "access denied" )
InvalidCondition.MissingRequiredParam   = InvalidCondition( "argument is required and was left unspecified" )
InvalidCondition.TooManyParams          = InvalidCondition( "too many arguments specified" )
InvalidCondition.TooHigh                = InvalidCondition( "specified number %i is above your allowed maximum of %i" )
InvalidCondition.TooLow                 = InvalidCondition( "specified number %i is below your allowed minimum of %i" )
InvalidCondition.InvalidNumber          = InvalidCondition( "invalid number \"%s\" specified" )
InvalidCondition.InvalidString          = InvalidCondition( "invalid string \"%s\" specified" )

--- Section: Access Registration

local registered_tags = {}

--[[
    Object: otlib.access
    
    Each registered access represents a single permission. For example, you would want to register
    a separate access for each command, and you'd want to register a separate access for special
    actions such as the ability to hear admins' private chat.
]]
access = object:Clone()


--[[
    Function: Register
    
    Registers a new access object.

    Parameters:

        tag - The unique *string* name for this permission.
        ... - *Optional*, any number of *<groups>* to give this permission to by default.

    Returns:

        The newly registered *<access>*.

    Revisions:

        v1.00 - Initial.
]]
function access:Register( tag, ... )
    local new = self:Clone()
    new.params = {}
    
    local groups = { ... }
    for i=1, #groups do
        groups[ i ].allow[ new ] = true
    end
    
    registered_tags[ tag ] = true
    -- TODO: Persist registered_tags
    
    return new
end

function access:AddParam( param )
    table.insert( self.params, param )
end

function access:ModifyParam( param_num )
    if not self.params[ param_num ] then return nil end
    self.params[ param_num ] = self.params[ param_num ]:Clone()
    
    return self.params[ param_num ]
end

function access:Clone( ... )
    local new = Clone( self, ... )
    new.params = Clone( self.params )
    
    return new
end

--- Section: Group Access

local groups = {}


--[[
    Function: GetGroup
]]
function GetGroup( group )
    return groups[ group ]
end

--[[
    Object: otlib.group
]]
group = object:Clone()
group.allow = object:Clone()
group.deny = object:Clone()

function group:CreateClonedGroup( name )
    local new = self:Clone()
    groups[ name ] = new
    new.allow = self.allow:Clone()
    new.deny = self.deny:Clone()
    
    return new
end

--- Group: User Access

function group:CreateClonedUser( ... )
    local new = self:Clone()
    new.allow = self.allow:Clone()
    new.deny = self.deny:Clone()
    new.aliases = {}
    local aliases = { ... }
    for i=1, #aliases do
        new:RegisterAlias( aliases[ i ] )
    end
    
    return new
end

function group:RegisterAlias( alias )
    if not HasValueI( self.aliases, alias ) then        
        table.insert( self.aliases, alias )
    end
    
    return self
end

function group:Allow( access )
    local new = access:Clone()
    self.allow[ access ] = new
    
    return new
end

function group:Deny( access )
    self.deny[ access ] = true
end


--[[
    Function: CheckAccess
    
    Checks if a user or group can use an access with specified, possibly parsed arguments. 
    'Possibly parsed arguments' simply means that numbers should come in as number or string types,
    bools as bools or strings, etc.

    Parameters:

        access - The *<access> object* to check permission against.
        ... - *Optional*, any number of arguments of *any type* to check the permission against.

    Returns:

        1 - A *boolean* of whether or not they have permission to the <access> object taking the
            specified parameters into account.
        2 - An *<InvalidCondition> object* if they don't have permission, a *list table* of the
            parsed arguments if they do.
            
    Notes:
    
        * It's very important to remember that this function takes arguments into account. They
            might have permission under certain circumstances, but if you don't pass appropriate
            arguments in, it will still deny the access. If you want to know if they'd have access
            under any circumstances, check the second return value.

    Revisions:

        v1.00 - Initial.
]]
function group:CheckAccess( access, ... )
    local permission = self.allow[ access ]
    if not permission or self.deny[ access ] then
        return false, InvalidCondition.AccessDenied():SetLevel( InvalidCondition.DeniedLevel.NoAccess )
    end
    
    local argv = { ... }
    local parsed_argv = {}
    local num_access_params = #access.params
    for i=1, math.max( #argv, num_access_params ) do
        local arg = argv[ i ]
        local access_index
        if access.params[ i ] then -- Standard
            access_index = i
            
            if access.params[ access_index ]:GetTakesRestOfLine() and #argv > i then
                local new_argv = { select( i, unpack( argv ) ) }
                arg = table.concat( new_argv, " " )
            end
        elseif access.params[ num_access_params ]:GetMaxRepeats() > 1 + i - num_access_params then -- Repeating
            access_index = num_access_params
        else -- Too many!
            return false, InvalidCondition.TooManyParams():SetLevel( InvalidCondition.DeniedLevel.Parameters ):SetParameterNum( i )
        end
        
        local parsed_arg, err = access.params[ access_index ]:Parse( self, arg )
        if err then
            return false, err:SetLevel( InvalidCondition.DeniedLevel.Parameters ):SetParameterNum( i )
        end
        
        -- Test against the hard-programmed limits
        local status, err = access.params[ access_index ]:IsValid( self, parsed_arg )
        if not status then
            return false, err:SetLevel( InvalidCondition.DeniedLevel.Parameters ):SetParameterNum( i )
        end
        
        -- If the permission isn't true it must be a derived permission
        if permission ~= true then
            status, err = permission.params[ access_index ]:IsValid( self, parsed_arg )
            if not status then
                return false, err:SetLevel( InvalidCondition.DeniedLevel.UserParameters ):SetParameterNum( i )
            end
        end
        
        table.insert( parsed_argv, parsed_arg )
        
        if access.params[ access_index ]:GetTakesRestOfLine() then
            break -- That's all, folks
        end
    end
    
    return true, parsed_argv
end
