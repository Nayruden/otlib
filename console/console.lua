dofile( "init.lua" )
dofile( "console/wrappers.lua" )
dofile( "console/lib.lua" )

module( "otlib", package.seeall )

commands = {}

-- Initialize

do
    -- Setup a simple group ladder
    user            = otlib.group:CreateClonedGroup( "user" ) -- Root group
    operator        = user:CreateClonedGroup( "operator" )
    admin           = operator:CreateClonedGroup( "admin" )
    superadmin      = admin:CreateClonedGroup( "superadmin" )
    
    console_user    = superadmin:CreateClonedUser( "console" )
    
    local plugin_files = FilesInDir( "console/plugins" )
    for i=1, #plugin_files do
        PLUGIN_PATH = "console/plugins/" .. plugin_files[ i ]
        dofile( PLUGIN_PATH )
    end
    PLUGIN_PATH = nil
    otlib.InitPlugins()
end

-- Main logic loop
local line = io.read()
while line do
    local argv = otlib.ParseArgs( line )
    local command = table.remove( argv, 1 )
    if commands[ command ] then
        commands[ command ]( console_user, command, argv )
    else
        print( "unknown command: " .. command )
    end
    line = io.read()
end
