local PLUGIN = otlib.CreatePlugin( "Test Plugin", "Just a test", "Nayruden" )

function PLUGIN:Test( ply, num )
    print( "test4:", ply, num )
end

local test_access = otlib.access:Register( "test", otlib.GetGroup( "admin" ) )
test_access:AddParam( otlib.NumParam():Min( 0 ):Max( 100 ) )
PLUGIN:AddCommand( "test", "!test", PLUGIN.Test, test_access )
