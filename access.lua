--- File: Access

--- Module: otlib
module( "otlib", package.seeall )

--- Group: Access Registration

local registered_tags = {}

access = object:Clone()

function access:Register( tag, ... )
    local new = self:Clone()
    if not registered_tags[ tag ] then
        for i, group in ipairs( { ... } ) do
            group.allow[ new ] = true
        end
    end
    
    -- TODO: Persist registered_tags
    
    return new
end

function access:AddParam( param )
    -- TODO
end

--- Group: Group Access

local groups = {}

user = object:Clone()
user.allow = object:Clone()
groups.user = user -- Register root group by hand

function user:RegisterClonedGroup( name )
	local new = self:Clone()
    groups[ name ] = new
    new.allow = self.allow:Clone()
    
    return new
end

operator = user:RegisterClonedGroup( "operator" )
admin = operator:RegisterClonedGroup( "admin" )
superadmin = admin:RegisterClonedGroup( "superadmin" )

slap = access:Register( "slap", admin )
-- slap:AddParam{ NumberType():Optional( true ):Min( 0 ):Max( 100 ):Default( 0 ) }

--- Group: User Access

local alias_to_user = {}

function user:RegisterUser( ... )
    local new = self:Clone()
    new.allow = self.allow:Clone()
    new.aliases = {}
    for i, v in ipairs( { ... } ) do
        table.insert( new, v )
        alias_to_user[ v ] = new
    end
end

function user:CheckAccess( access, ... )
    -- TODO: Handle params
    if self.allow[ access ] then
        return true
    end
    
    return false
end

function UserFromID( id )
    return alias_to_user[ id ]
end

function CheckAccess( id, access, ... )
    return UserFromID( id ):CheckAccess( access, ... )
end
