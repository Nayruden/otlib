module( "otlib", package.seeall )

-- I make no promises that this properly escapes data, it's only for testing.
function wrappers.FormatAndEscapeData( data )
    local data_typ = type( data )
    if data_typ == "string" then
        return string.format( '"%s"', data:gsub( '"', '""' ) )
    elseif data_typ == "nil" then
        return "NULL"
    elseif data_typ == "number" then
        return tostring( data )
    else
        return error( "don't know how to escape data type '" .. data_typ .. "'", 2 )
    end
end

local affected_count = 0
local sqlite3_env
local mysql_env
local sqlite3_conn
local mysql_conn
local function getConnection( database_type )
    if database_type == DatabaseTypes.MySQL then
        if not mysql_conn then
            if mysql_env then
                mysql_env:close()
            else
                require( "luasql.mysql" )
            end
            mysql_env = assert( luasql.mysql() )
            mysql_conn = assert( mysql_env:connect( "simpledata", "root" ) )
        end
        return mysql_conn
    elseif database_type == DatabaseTypes.SQLite then
        if not sqlite3_conn then
            if sqlite3_env then
                sqlite3_env:close()
            else          
                require( "luasql.sqlite3" )
            end
            sqlite3_env = assert( luasql.sqlite3() )
            sqlite3_conn = assert( sqlite3_env:connect( "simpledata.db" ) )
        end
        return sqlite3_conn
    else
        return error( ("unknown database type '%s'"):format( tostring( database_type ) ) )
    end
end

function wrappers.BeginTransaction( database_type )
    getConnection( database_type ):setautocommit( false )
end

function wrappers.EndTransaction( database_type )
    local conn = getConnection( database_type )
    conn:commit()
    conn:setautocommit( true )
end

function wrappers.Execute( database_type, statement, key_types )
    local conn = getConnection( database_type )
    
    local ret = assert( conn:execute( statement ) )
    if type( ret ) == "number" then
        affected_count = ret
        return nil
    else
        local tbl = {}
        local row = ret:fetch( {}, "a" )
        while row do
            table.insert( tbl, row )
            row = ret:fetch( {}, "a" )
        end
        ret:close()
        
        if key_types and #tbl > 0 and database_type == DatabaseTypes.MySQL then
            for key_name, key_type in pairs( key_types ) do
                if key_type == "number" then
                    for i=1, #tbl do
                        tbl[ i ][ key_name ] = tonumber( tbl[ i ][ key_name ] )
                    end
                end
            end
        end
        
        return tbl
    end
end

function wrappers.AffectedRows()
    return affected_count
end

require( "lfs" )
function wrappers.FileExists( file_path )
    local f = io.open( file_path )
    if f ~= nil then
        io.close( f )
        return true
    else
        return false
    end
end

function wrappers.FileRead( file_path )
    local f = io.open( file_path )
    assert( f )
    local str = f:read( "*a" )
    io.close( f )
    return str
end

function wrappers.FileWrite( file_path, data )
    local f = io.open( file_path, "w+" )
    assert( f )
    f:write( data )
    io.close( f )
end

function wrappers.FileDelete( file_path )
    os.remove( file_path )
end

function wrappers.FilesInDir( dir_path )
    local files = {}
    for file in lfs.dir( dir_path ) do
        if not DataEqualsAnyOf( file, ".", ".." ) then
            table.insert( files, file )
        end
    end
    
    return files
end

local to_route = {}

local function callback_router( user, command, argv )
    assert( to_route[ command ] )
    local data = to_route[ command ]
    local has_access, ret = user:CheckAccess( data.access, unpack( argv ) )
    if not has_access then
        print( ('Command %q, argument #%i: %s'):format( command, ret:GetParameterNum(), ret:GetMessage() ) )
    else
        params = Append( data.extra_data, ret )
        data.callback( unpack( params ) )
    end
end

function wrappers.AddConsoleCommand( command_name, callback, access, ... )
    to_route[ command_name ] = { callback=callback, access=access, extra_data={ ... } }
    commands[ command_name ] = callback_router
end

function wrappers.AddSayCommand( command_name, callback, access, ... )
    print( "ignoring say command '" .. command_name .. "'" )
end
