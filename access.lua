--- File: Access

--- Module: otlib
module( "otlib", package.seeall )

--- Group: Access Registration

local tag_to_access = {}
local registered_tags = {}

access = object:Clone()

function access:Register( tag, ... )
    local new = self:Clone()
    tag_to_access[ tag ] = new
    if not registered_tags[ tag ] then
        for i, group in ipairs( { ... } ) do
            group.allow[ new ] = true
        end
    end
    
    return new
end

function access:AddParam( details )
end

--- Group: Group Access

local groups = {}

user = object:Clone()
user.allow = object:Clone()
groups.user = user -- Register root by hand

function user:RegisterClonedGroup( name )
	local new = self:Clone()
    groups[ name ] = new
    new.allow = self.allow:Clone()
    
    return new
end

admin = user:RegisterClonedGroup( "admin" )
superadmin = admin:RegisterClonedGroup( "superadmin" )

slap = access:Register( "slap", admin )
slap:AddParam{ type=NumberType, optional, min=0, max=100, default=0 }
-- access_obj = otlib.RegisterAccess( access_tag, group1, group2, ... )
-- access_obj:AddParam{ type=otlib.PlayersType, otlib.optional, default=otlib.target.self }
-- access_obj:AddParam{ type=otlib.NumberType, otlib.optional, min=-10, max=10, default=0 }

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
    if self.allow[ access ] then
        return true
    end
    
    return false
end

function CheckAccess( id, access, ... )
    return alias_to_user[ id ]:CheckAccess( access, ... )
end
