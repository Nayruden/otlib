dofile( "../prototype.lua" )
dofile( "../utils.lua" )
dofile( "../access.lua" )

user1 = otlib.user:Clone()
user1:AddAliases( "123" )

user2 = otlib.user:Clone()
user2:AddAliases( "321" )

otlib.CheckAccess( "123", "slap", 6 )