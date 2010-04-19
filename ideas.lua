-- Anti-swear mod
function called_when_user_talks( ply, text )
    if contains_swear( text ) then
        if otlib.CheckAccess( ply, "swear_access", swear_word_from_text ) then
            allow_swear()
        else
            disallow_swear()
        end
    end
end

otlib.CheckAccess(
    ply, -- Any lua type accepted here. The AME.CheckAccess function will attempt
         -- to convert the type using a lookup table defined by the implentation.
         -- IE, in gmod, it would look up from the "Player" type to get the User
         -- class, below.

    access_tag, -- A string of an "access tag" to refer to this particular type
                -- of access. Should there be a central storage for these? Or a
                -- help system attached to them?

    ... -- Any number of extra parameters representing additional things to check
        -- for access. In this case, you can specify what swear words a user is
        -- allowed to say.
)

otlib.target.self = "^"
otlib.target.not = "!"
otlib.target.all = "*"
otlib.target.group = "%"

access_obj = otlib.RegisterAccess( access_tag, group1, group2, ... )
access_obj:AddParam{ type=otlib.PlayersType, otlib.optional, default=otlib.target.self }
access_obj:AddParam{ type=otlib.NumberType, otlib.optional, min=-10, max=10, default=0 }

local not_self = PlayersArg( "!^" )

access_obj = otlib.RegisterAccess( access_tag, group1, group2, ... )
access_obj:AddParam( Copy( not_self ):Max( 10 ) )


--[[
Ze list:
    * Make keywords changable for other keyboard layouts (^ sucks for polish apparently)
    * ULib and ULX built and distributed together?
]]
