local PLUGIN = otlib.CreatePlugin( "Test Plugin", "Just a test", "Nayruden" )

local function test( ply, num )
    print( ply, num )
end

local test_access = otlib.access:Register( "test", otlib.GetGroup( "admin" ) )
test_access:AddParam( otlib.NumParam():Min( 0 ):Max( 100 ) )
PLUGIN:AddCommand( "test", "!test", test, test_access )
