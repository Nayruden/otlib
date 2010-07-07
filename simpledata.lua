--[[
    File: Simple Data
    
    Offers a wrapper around file or database I/O for _simple_ data needs. You'll be able to access
    the data without caring what the backend is (SQL or flat-file), but each row in the database
    will need to have a unique key and only four operations are supported on the data. The four
    operations are fetch all rows, retrieve row by key, delete row by key, and update row (which 
    will happen automatically unless you turn that off). In other words, there's no searching on
    anything other than the unique key unless you're willing to grab all the data and search
    yourself.
    
    Major features:
    
        * Save to flat-file, SQLite, or MySQL.
        * Convert between formats on the fly.
        * Can flush any caches on the fly without developers having to re-request the data.
        * Automatically saves changes.
]]

-- Temp
dofile( "init.lua" )
dofile( "utils.lua" )
dofile( "table_utils.lua" )
dofile( "prototype.lua" )
dofile( "access.lua" )
dofile( "debug.lua" )
dofile( "parameters.lua" )
dofile( "wrappers.lua" )
package.cpath = package.cpath .. ";/Users/zoot/.luarocks/lib/lua/5.1/?.so"
require( "luasql.sqlite3" )
require( "luasql.mysql" )
-- sqlite3 = assert( luasql.sqlite3() )
-- conn = assert( sqlite3:connect( "test.db" ) )
mysql = assert( luasql.mysql() )
conn = assert( mysql:connect( "test" ) )

-- I make no promises that this properly escapes data, it's only for testing.
function otlib.wrappers.FormatAndEscapeData( data )
    if type( data ) == "string" then
        data = string.format( '"%s"', data:gsub( '"', '""' ) )
    elseif type( data ) == "nil" then
        data = "NULL"
    end
    
    return data
end

-- TODO: Document and copy wrappers over...
function otlib.wrappers.BeginTransaction()
    conn:setautocommit( false )
end

function otlib.wrappers.EndTransaction()
    conn:commit()
    conn:setautocommit( true )
end

local affected_count = 0
function otlib.wrappers.Execute( database_type, statement )
    if type( statement ) ~= "string" then error( "Not a string!", 2 ) end
    print( statement .. ";" )
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
-- End temp

--- Module: otlib.simpledata
module( "otlib", package.seeall )

--[[
-- Copied from wrappers.lua, but the 'official' one is in that file.
DatabaseTypes = {
    Flatfile = 'Flatfile',
    SQLite = 'SQLite',
    MySQL = 'MySQL',
}
]]

-- local preferred_database_type = DatabaseTypes.SQLite
local preferred_database_type = DatabaseTypes.Flatfile
-- local preferred_database_type = DatabaseTypes.MySQL
local error_key_not_registered = "tried to pass in key '%s' to table '%s', but key was not registered"
local unknown_database_type = "unknown database type '%s' for table name '%s'"

local function NormalizeType( typ )
    return typ:gsub( "string", "CHAR" ):gsub( " ", "" ):upper()
end

--- Object: DataTable
local DataTable = object:Clone()
local datatable_cache = {}

function CreateDataTable( table_name, primary_key_name, primary_key_type, comment, database_type )
    if DataEqualsAnyOf( primary_key_name, "key", "value" ) then
        return error( "cannot have a primary key name of 'key' or 'value', these names are reserved", 2 )
    end
    
    local new_data_table = DataTable:Clone()
    new_data_table.table_name = table_name
    new_data_table.primary_key_name = primary_key_name
    new_data_table.primary_key_type = NormalizeType( primary_key_type )
    new_data_table.table_comment = comment
    new_data_table.database_type = database_type or preferred_database_type
    
    -- Setup cache entry
    datatable_cache[ table_name ] = {}
    
    -- Key info
    new_data_table.keys = {}
    new_data_table.lists = {}
    new_data_table.comments = {}
    
    return new_data_table
end

function DataTable:AddKey( key_name, value_type, comment )
    self.keys[ key_name ] = {
        value_type = NormalizeType( value_type ),
        comment = comment,
    }
    
    return self
end

function DataTable:AddKeyValueList( list_name, key_type, value_type, comment )
    self.lists[ list_name ] = {
        list_table_name = self.table_name .. "_" .. list_name, -- Only relevant for SQL
        key_type = NormalizeType( key_type ),
        value_type = NormalizeType( value_type ),
        comment = comment,
    }
end

local function saveFlatfile( datatable )
    if not datatable.in_transaction then
        print( "writing!" )
        wrappers.FileWrite( datatable.table_name .. ".txt", datatable.file_header .. "\n" .. datatable.file_cache .. "\n" )
    end
end

local function findInFlatfile( datatable, primary_key )
    -- We can use the following pattern because we're sure that the cache will always be in standard format.
    -- Normally I'd want to use %b{}, but that won't work here since the data may contain braces.
    return datatable.file_cache:find( ("%q"):format( primary_key ) .. "\n{.-\n}" )
end

local function insertOrReplaceIntoFlatfile( datatable, data )
    local keyvalues = MakeKeyValues{ [data[ datatable.primary_key_name ]] = data }
    
    local start, stop = findInFlatfile( datatable, data[ datatable.primary_key_name ] )
    if start then
        datatable.file_cache = datatable.file_cache:sub( 1, start-1 ) .. keyvalues .. datatable.file_cache:sub( stop+1 )
    else
        datatable.file_cache = datatable.file_cache .. (datatable.file_cache ~= '' and "\n" or '') .. keyvalues
    end

    saveFlatfile( datatable )
end

function DataTable:BeginTransaction()
    self.in_transaction = true
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        wrappers.BeginTransaction()

    elseif self.database_type == DatabaseTypes.Flatfile then
        -- Do nothing

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

function DataTable:EndTransaction()
    self.in_transaction = nil
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        wrappers.EndTransaction()

    elseif self.database_type == DatabaseTypes.Flatfile then
        saveFlatfile( self )

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

function DataTable:CreateTableIfNeeded()
    if self.created then return end
    self.created = true
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement_template = "CREATE TABLE IF NOT EXISTS `%s` (%s)"
        local comment_template = " COMMENT '%s'"
        local column_template = "`%s` %s"
    
        -- Normally primary key implies not null, but sqlite3 doesn't follow the standard, so we explicitly state it
        local column_definitions = { column_template:format( self.primary_key_name, self.primary_key_type ) .. " PRIMARY KEY NOT NULL" } -- Prepopulate with primary key column definition
        for key_name, key_data in pairs( self.keys ) do
            table.insert( column_definitions, column_template:format( key_name, key_data.value_type ) )
            if self.database_type == DatabaseTypes.MySQL and self.keys[ key_name ].comment then -- Add comment if necessary
                column_definitions[ #column_definitions ] = column_definitions[ #column_definitions ] .. comment_template:format( self.keys[ key_name ].comment )
            end
        end
    
        if self.database_type == DatabaseTypes.MySQL and self.table_comment then -- Add comment if necessary
            column_definitions[ 1 ] = column_definitions[ 1 ] .. comment_template:format( self.table_comment )
        end
    
        wrappers.Execute( self.database_type, statement_template:format( self.table_name, table.concat( column_definitions, ", " ) ) )

        for list_name, list_data in pairs( self.lists ) do
            column_definitions = {
                column_template:format( self.primary_key_name, self.primary_key_type ) .. " NOT NULL",
                column_template:format( "key", list_data.key_type ) .. " NOT NULL",
                column_template:format( "value", list_data.value_type ) .. " NOT NULL",
                "PRIMARY KEY(`" .. self.primary_key_name .. "`, `key`)", -- Composite primary key of self's primary key and the key of this table.
            }
            wrappers.Execute( self.database_type, statement_template:format( self.table_name .. "_" .. list_name, table.concat( column_definitions, ", " ) ) )
        end
    
    elseif self.database_type == DatabaseTypes.Flatfile then
        if not wrappers.FileExists( self.table_name .. ".txt" ) then
            local comment_lines = { "; Format:" }
            local comment_template = " <-- %s"
            table.insert( comment_lines, ('"<%s>"%s'):format( self.primary_key_name, (self.table_comment and comment_template:format( self.table_comment ) or "") ) )
            table.insert( comment_lines, "{" )
            table.insert( comment_lines, ('    "%s"  "<%s>"%s'):format( self.primary_key_name, self.primary_key_name, "A repeat of the value above, must exist and must be the same" ) )
            for key_name, key_data in pairs( self.keys ) do
                table.insert( comment_lines, ('    "%s"  "<%s>"%s'):format( key_name, key_name, (key_data.comment and comment_template:format( key_data.comment ) or "") ) )
            end
            for list_name, list_data in pairs( self.lists ) do
                table.insert( comment_lines, ('    "%s"%s'):format( list_name, (list_data.comment and comment_template:format( list_data.comment ) or "") ) )
                table.insert( comment_lines, '    {' )
                table.insert( comment_lines, '        ...' )
                table.insert( comment_lines, '    }' )
            end
            table.insert( comment_lines, "}" )
            
            self.file_header = table.concat( comment_lines, '\n; ' )
            self.file_cache = ''
            saveFlatfile( self )
        else
            local data = wrappers.FileRead( self.table_name .. ".txt" )
            local comment, data = SplitCommentHeader( data )
            self.file_header = comment
            
            -- We parse this and then convert back to keyvalues to ensure that it's in a standardized format (and valid).
            local parsed, err = ParseKeyValues( data )
            if not parsed then
                error( "could not read database, possible corruption. error is: " .. err )
            end
            self.file_cache = MakeKeyValues( parsed )
        end
        
    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

function DataTable:UntrackedCopy( data )
    local root = Copy( getmetatable( data ).__index )
    for list_name, list_info in pairs( self.lists ) do
        root[ list_name ] = Copy( getmetatable( data[ list_name ] ).__index )
    end
    
    return root
end

local function newindex( t, key, value )
    if t[ key ] == value then return end -- No action needed
    
    local meta = getmetatable( t )
    meta.__index[ key ] = value
    
    if meta.table.lists[ key ] then
        return error( "cannot set list keys, table in question is '" .. meta.table.table_name .. "'", 2 )
    end
    
    if not meta.list_info and key ~= meta.table.primary_key_name and not meta.table.keys[ key ] then -- It's data that doesn't belong
        return error( error_key_not_registered:format( key, meta.table.table_name ), 2 )
    end
    
    if DataEqualsAnyOf( meta.table.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement
        if not meta.list_info then -- It's a regular row
            statement = ("UPDATE `%s` SET `%s`=%s WHERE `%s`=%s")
                         :format( meta.table.table_name, key, wrappers.FormatAndEscapeData( value ), 
                                  meta.table.primary_key_name, wrappers.FormatAndEscapeData( meta.primary_key ) )
        elseif value ~= nil then -- It's a list row and we're not deleting it
            statement = ("REPLACE INTO `%s` (`%s`, `key`, `value`) VALUES (%s, %s, %s)")
                         :format( meta.list_info.list_table_name, meta.table.primary_key_name, 
                                  wrappers.FormatAndEscapeData( meta.primary_key ), 
                                  wrappers.FormatAndEscapeData( key ), wrappers.FormatAndEscapeData( value ) )
        else -- It's a list row and we're deleting it
            statement = ("DELETE FROM `%s` WHERE `%s`=%s AND `key`=%s")
                         :format( meta.list_info.list_table_name, meta.table.primary_key_name,
                                  wrappers.FormatAndEscapeData( meta.primary_key ),
                                  wrappers.FormatAndEscapeData( key ) )
        end
        wrappers.Execute( meta.table.database_type, statement )
        
    elseif meta.table.database_type == DatabaseTypes.Flatfile then
        local row = meta.table:UntrackedCopy( datatable_cache[ meta.table.table_name ][ meta.primary_key ] )
        insertOrReplaceIntoFlatfile( meta.table, row )

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

local function trackRow( datatable, data )
    data = data or {}
    local primary_key = data[ datatable.primary_key_name ]
    local ret = setmetatable( {}, { table=datatable, primary_key=primary_key, __index=data, __newindex=newindex } )
    datatable_cache[ datatable.table_name ][ primary_key ] = ret
    
    for list_name, list_info in pairs( datatable.lists ) do
        data[ list_name ] = setmetatable( {}, { table=datatable, primary_key=primary_key, list_info=list_info, __index=(data[ list_name ] or {}), __newindex=newindex } )
    end
    
    return ret
end

function DataTable:Insert( primary_key, data )
    self:CreateTableIfNeeded()
    
    -- Process possibly passed in data
    data = data or {}
    data[ self.primary_key_name ] = primary_key
    
    for key, value in pairs( data ) do
        if key ~= self.primary_key_name and not self.keys[ key ] and not self.lists[ key ] then -- It's data that doesn't belong
            return error( error_key_not_registered:format( key, self.table_name ), 2 )
        end
    end
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement_template = "REPLACE INTO `%s` (%s) VALUES (%s)"
        local keys = {}
        local values = {}
        for key, value in pairs( data ) do
            if key == self.primary_key_name or self.keys[ key ] then -- If it's one of the table's keys
                table.insert( keys, "`" .. key .. "`" )
                table.insert( values, wrappers.FormatAndEscapeData( value ) )
            end
        end
        wrappers.Execute( self.database_type, statement_template:format( self.table_name, table.concat( keys, ", " ), table.concat( values, ", " ) ) )
        
        -- Any list data that may exist in the passed in param should be handled
        local statement_template = "REPLACE INTO `%s` (`%s`, `key`, `value`) VALUES (%s, %s, %s)"
        for list_name, list_info in pairs( self.lists ) do
            for list_key, list_value in pairs( data[ list_name ] or {} ) do
                local statement = statement_template:format( list_info.list_table_name, self.primary_key_name, wrappers.FormatAndEscapeData( primary_key ), 
                                                             wrappers.FormatAndEscapeData( list_key ), wrappers.FormatAndEscapeData( list_value ) )
                wrappers.Execute( self.database_type, statement )
            end
        end
        
    elseif self.database_type == DatabaseTypes.Flatfile then
        insertOrReplaceIntoFlatfile( self, data )

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
    
    -- Stuff to do on any database type
    return trackRow( self, data )
end

function DataTable:Fetch( primary_key )
    self:CreateTableIfNeeded()
    
    if datatable_cache[ self.table_name ][ primary_key ] then
        return datatable_cache[ self.table_name ][ primary_key ]
    end
    
    local data
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        primary_key = wrappers.FormatAndEscapeData( primary_key )
        local statement = ("SELECT * FROM `%s` WHERE `%s`=%s"):format( self.table_name, self.primary_key_name, primary_key )
        local raw = wrappers.Execute( self.database_type, statement )
        if #raw == 0 then return nil end
        assert( #raw == 1 )
        data = raw[ 1 ]
        
        for list_name, list_info in pairs( self.lists ) do
            statement = ("SELECT * FROM `%s` WHERE `%s`=%s"):format( list_info.list_table_name, self.primary_key_name, primary_key )
            raw = wrappers.Execute( self.database_type, statement )
            local t = {}
            data[ list_name ] = t
            for i=1, #raw do
                t[ raw[ i ].key ] = raw[ i ].value
            end
        end

    elseif self.database_type == DatabaseTypes.Flatfile then
        local start, stop = findInFlatfile( self, primary_key )
        if not start then return nil end
        data = ParseKeyValues( self.file_cache:sub( start, stop ) )
        assert( Count( data ) == 1 )
        data = data[ primary_key ]

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
    
    return trackRow( self, data )
end

function DataTable:Remove( primary_key )
    self:CreateTableIfNeeded()
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        primary_key = wrappers.FormatAndEscapeData( primary_key )
        local statement = ("DELETE FROM `%s` WHERE `%s`=%s"):format( self.table_name, self.primary_key_name, primary_key )
        wrappers.Execute( self.database_type, statement )
        local affected = wrappers.AffectedRows()
        
        for list_name, list_info in pairs( self.lists ) do
            statement = ("DELETE FROM `%s` WHERE `%s`=%s"):format( list_info.list_table_name, self.primary_key_name, primary_key )
            wrappers.Execute( self.database_type, statement )
            affected = affected + wrappers.AffectedRows()
        end                
               
        return affected > 0
        
    elseif self.database_type == DatabaseTypes.Flatfile then
        local start, stop = findInFlatfile( self, primary_key )
        if not start then return false end
        self.file_cache = self.file_cache:sub( 1, start-1 ) .. self.file_cache:sub( stop+1 )
        saveFlatfile( self )
        return true

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

function DataTable:GetAll()
    self:CreateTableIfNeeded()
    
    local data
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement = ("SELECT * FROM `%s`"):format( self.table_name )
        local raw = wrappers.Execute( self.database_type, statement )
        if #raw == 0 then return {} end
        
        data = {}
        for i=1, #raw do
            for list_name, list_info in pairs( self.lists ) do
                raw[ i ][ list_name ] = {}
            end
            data[ raw[ i ][ self.primary_key_name ] ] = raw[ i ]
        end
    
        for list_name, list_info in pairs( self.lists ) do
            statement = ("SELECT * FROM `%s`"):format( list_info.list_table_name )
            raw = wrappers.Execute( self.database_type, statement )
            for i=1, #raw do
                local t = data[ raw[ i ][ self.primary_key_name ] ]
                if t then -- We should never have a case where this isn't a table... but just to make sure
                    t[ list_name ][ raw[ i ].key ] = raw[ i ].value
                end
            end
        end

    elseif self.database_type == DatabaseTypes.Flatfile then
        local err
        data, err = ParseKeyValues( self.file_cache )
        if not data then
            return error( "could not parse file for '" .. self.table_name .. "' error is: " .. err )
        end

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
    
    return data
end

local users = CreateDataTable( "users", "steamid", "string(32)", "The steamid of the user" )
users:AddKey( "group", "string(16)", "The group the user belongs to" )
users:AddKey( "name", "string(32)", "The name the player was last seen with" )
users:AddKeyValueList( "allow", "string(16)", "string(128)", "The allows for the user" )

users:BeginTransaction()
user1 = users:Insert( "steamid1", { name="B}lob\"", group="operator5", allow={ ["ulx slap"]="*", ["ulx kick"]="*b*" } } )
user1 = users:Insert( "steamid3", { name="B}\"ob", group="operator5", allow={ ["ulx slap"]="*", ["ulx kick"]="*cccccc*" } } )
user1 = users:Insert( "steamid5", { name="Bo{b\"¡•∞¢£ƒ˙∫ç∂∆˚¨ƒ˜≤", group="operator5", allow={ ["ulx slap"]="*", ["ulx kick"]="*b*" } } )
-- user1.name = "Bob3"
user1.group = nil
user1.group = "operator"
user1.allow[ "ulx slap" ] = "*b*"
user1.allow[ "ulx slap" ] = "*b*"
user1.allow[ "ulx kick" ] = "**"

--[[user2 = users:Insert( "steamid2" )
user2.name = "Bob2"
user2.group = "operator2"
user2.allow[ "ulx slap" ] = "*c*"
user2.allow[ "ulx kick" ] = "*kkk"
user2.allow[ "ulx kick" ] = nil]]
users:EndTransaction()

user3 = users:Fetch( "steamid30" )
print( "user3", user3 )

-- user2 = users:Fetch( "steamid2" )
-- print( "user2", user2 )
-- print( Vardump( users:UntrackedCopy( user2 ) ) )

print( users:Remove( "steamid50" ) )

all_data = users:GetAll()
print( Vardump( all_data ) )

--[[ Main table: users
"steamid1"
{
    "name" "bob"
    "allow" -- New table: users_allow
    {
        "ulx slap" "*"
        "ulx kick" "*"
    }
}
]]
