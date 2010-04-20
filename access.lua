--- File: Access

--- Module: otlib
module( "otlib", package.seeall )

--- Group: Access Registration

local registered_tags = {}

access = object:Clone()

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
    if not self.allow[ access ] then
        return false, "access denied"
    end
    
    local args = { ... }
    local ex = StoredExpression()
    for i, v in ipairs( access.params ) do
        if not ex( v:IsValid( self, args[ i ] ) ) then
            return false, ex[ 2 ]
        end
    end
    
    return true
end

function UserFromID( id )
    return alias_to_user[ id ]
end

function CheckAccess( id, access, ... )
    return UserFromID( id ):CheckAccess( access, ... )
end
