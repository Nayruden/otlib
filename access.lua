--- File: Access

--- Module: otlib
module( "otlib", package.seeall )


--[[
    Object: InvalidCondition
]]
InvalidCondition = object:Clone( true )

--[[
    Variables: Denied Levels
    
    This is used by a return from <group.CheckAccess> to specify what part of the access level an
    access check failed on.
        
    DeniedLevel.NoAccess - The user has no access to this command at all.
    DeniedLevel.Access - The specified arguments did not meet the requirements for the access being 
        used.
    DeniedLevel.User - The specified arguments met the requirements for the access being used, but 
        not this particular user's access to the command.
]]
InvalidCondition.DeniedLevel = {
    NoAccess = 1,
    Access = 2,
    User = 3,
}

function InvalidCondition:Init( ... )
    -- Dual purpose, can define the base with the unformatted string, or if we've already defined
    -- the base, the arguments must be the format.
    if self.unformatted then
        self.message = self.unformatted:format( ... )
    else
        self.unformatted = (...)
    end
end

function InvalidCondition:SetLevel( level )
    self.level = level
    
    return self
end

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
    
    --if not registered_tags[ tag ] then
        for i, group in ipairs( { ... } ) do
            group.allow[ new ] = true
        end
    --end
    
    registered_tags[ tag ] = true
    -- TODO: Persist registered_tags
    
    return new
end

function access:AddParam( param )
    table.insert( self.params, param )
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
groups.user = group -- Register root group by hand
user = group -- User group is root group

function group:RegisterClonedGroup( name )
	local new = self:Clone()
    groups[ name ] = new
    new.allow = self.allow:Clone()
    
    return new
end

--- Group: User Access

local alias_to_user = {}

function group:RegisterUser( ... )
    local new = self:Clone()
    new.allow = self.allow:Clone()
    new.aliases = {}
    for i, v in ipairs( { ... } ) do
        table.insert( new, v )
        alias_to_user[ v ] = new
    end
    
    return new
end

-- Future note:
-- Args are already parsed at this point... this makes it easy to do something like
-- checking if someone has access to physgun another player, since you already have
-- the parsed objects. Find a place to put parsing logic that makes sense!

AccessDenied = InvalidCondition( "access denied" )

--[[
    Function: CheckAccess
]]
function group:CheckAccess( access, ... )
    local permission = self.allow[ access ]
    if not permission then
        return false, AccessDenied():SetLevel( InvalidCondition.DeniedLevel.NoAccess )
    end
    
    local args = { ... }
    for i, v in ipairs( access.params ) do
        local status, err = v:IsValid( self, args[ i ] )
        if not status then
            return false, err:SetLevel( InvalidCondition.DeniedLevel.Access )
        end
        
        -- If the permission isn't true it must be a table
        if permission ~= true and permission[ i ] then
            status, err = permission[ i ]:IsValid( self, args[ i ] )
            if not status then
                return false, err:SetLevel( InvalidCondition.DeniedLevel.User )
            end
        end
    end
    
    return true
end

--- Module: otlib

--[[
    Function: UserFromID
]]
function UserFromID( id )
    return alias_to_user[ id ]
end

--[[
    Function: CheckAccess
]]
function CheckAccess( id, access, ... )
    return UserFromID( id ):CheckAccess( access, ... )
end
