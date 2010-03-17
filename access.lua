--- File: Access

--- Module: otlib
module( "otlib", package.seeall )

--- Group: Access registration

local tag_to_access = {}

access = object:Clone()

function access:Register( tag, ... )
    tag_to_access[ tag ] = self
end

function access:AddParam( details )
end

access_obj = otlib.RegisterAccess( access_tag, group1, group2, ... )
access_obj:AddParam{ type=otlib.PlayersType, otlib.optional, default=otlib.target.self }
access_obj:AddParam{ type=otlib.NumberType, otlib.optional, min=-10, max=10, default=0 }

--- Group: User access

local alias_to_user = {}

user = object:Clone()

function user:AddAliases( ... )
    self.aliases = self.aliases or {}
    for i, v in ipairs( { ... } ) do
        table.insert( self.aliases, v )
        alias_to_user[ v ] = self
    end
end

function user:CheckAccess( access, ... )
    if ids[ id ][ access_tag ] then
        return true
    end
    
    return false
end

function CheckAccess( id, access_tag, ... )
    alias_to_user[ id ]:CheckAccess( tag_to_access[ access_tag ], ... )
end
