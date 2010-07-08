
-- I make no promises that this properly escapes data, it's only for testing.
function otlib.wrappers.FormatAndEscapeData( data )
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
    -- TODO remove the otlib after move
    if database_type == otlib.DatabaseTypes.MySQL then
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
    elseif database_type == otlib.DatabaseTypes.SQLite then
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

function otlib.wrappers.BeginTransaction( database_type )
    getConnection( database_type ):setautocommit( false )
end

function otlib.wrappers.EndTransaction( database_type )
    local conn = getConnection( database_type )
    conn:commit()
    conn:setautocommit( true )
end

function otlib.wrappers.Execute( database_type, statement, key_types )
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
        
        -- TODO: Remove otlib after move
        if key_types and #tbl > 0 and database_type == otlib.DatabaseTypes.MySQL then
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

function otlib.wrappers.AffectedRows()
    return affected_count
end

function otlib.wrappers.FileExists( file_name )
    local f = io.open( file_name )
    if f ~= nil then
        io.close( f )
        return true
    else
        return false
    end
end

function otlib.wrappers.FileRead( file_name )
    local f = io.open( file_name )
    assert( f )
    local str = f:read( "*a" )
    io.close( f )
    return str
end

function otlib.wrappers.FileWrite( file_name, data )
    local f = io.open( file_name, "w+" )
    assert( f )
    f:write( data )
    io.close( f )
end

function otlib.wrappers.FileDelete( file_name )
    os.remove( file_name )
end