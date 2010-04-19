dofile( "../prototype.lua" )
dofile( "../utils.lua" )
dofile( "../access.lua" )

user1 = otlib.admin:RegisterUser( "123" )

user2 = otlib.operator:RegisterUser( "321" )

print( otlib.CheckAccess( "123", otlib.slap, 6 ) )
print( otlib.CheckAccess( "321", otlib.slap, 6 ) )