dofile( "../prototype.lua" )
dofile( "../utils.lua" )
dofile( "../access.lua" )

user1 = otlib.admin:RegisterUser( "123" )

user2 = otlib.superadmin:RegisterUser( "321" )

print( otlib.CheckAccess( "123", otlib.slap, 6 ) )