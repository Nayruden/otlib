dofile( "init.lua" )
dofile( "console/wrappers.lua" )

local commands = {}

local line = io.read()
while line do
    local argv = otlib.ParseArgs( line )
    local command = table.remove( argv, 1 )
    if commands[ command ] then
        commands[ command ]( nil, command, argv )
    else
        print( "unknown command: " .. command )
    end
    line = io.read()
end
