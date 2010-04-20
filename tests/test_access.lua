operator    = otlib.user:RegisterClonedGroup( "operator" )
admin       = operator:RegisterClonedGroup( "admin" )
superadmin  = admin:RegisterClonedGroup( "superadmin" )

slap = otlib.access:Register( "slap", otlib.admin )
slap:AddParam( otlib.NumParam():Optional( true ):Min( 0 ):Max( 100 ) )

user1 = admin:RegisterUser( "123" )
user1.allow[ slap ] = { -- TODO better way of setting this
    slap.params[ 1 ]():Min( -50 ):Max( 50 )
}

user2 = operator:RegisterUser( "321" )

print( otlib.CheckAccess( "123", slap, 60 ) )
print( otlib.CheckAccess( "321", slap, 6 ) )

print( otlib.CheckAccess( "123", slap, -6 ) )
print( otlib.CheckAccess( "321", slap, 6 ) )
