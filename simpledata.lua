--[[
    File: Simple Data
    
    Offers a wrapper around file or database I/O for _simple_ data needs. You'll be able to access
    the data without caring what the backend is (SQL or flat-file), but each row in the table will
    need to have an unique, primary key and only four operations are supported on the data. The 
    four operations are fetch all rows (<otlib.DataTable.GetAll>), retrieve row by key 
    (<otlib.DataTable.Fetch), delete row by key (<otlib.DataTable.Remove), and update row (which
    will happen automatically unless you're doing transactions). In other words, there's no 
    searching on anything other than the unique, primary key unless you're willing to grab all the
    data (<otlib.DataTable.GetAll>) and search yourself (but that would be extremely slow).
    
    Major features:
    
        * Save to flat-file, SQLite, or MySQL.
        * Convert between formats on the fly.
        * Caching of retrieved data.
        * Can flush the cache on the fly, or disable the caching entirely.
        * Automatically and instantly saves changes.
        * Can do transactions. This means several changes are pushed at once.
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

-- TODO: Document and copy wrappers over...
-- I make no promises that this properly escapes data, it's only for testing.
function otlib.wrappers.FormatAndEscapeData( data )
    local data_typ = type( data )
    if data_typ == "string" then
        return string.format( '"%s"', data:gsub( '"', '""' ) )
    elseif data_typ == "nil" then
        return "NULL"
    elseif data_typ == "number" then
        return data
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

function otlib.wrappers.Execute( database_type, statement )
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
    if otlib.wrappers.FileExists( file_name ) then 
        io.popen( "rm " .. file_name )
    end
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
    return typ:gsub( "string", "CHAR" ):gsub( "number", "REAL" ):gsub( " ", "" ):upper()
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

function DataTable:AddListOfKeyValues( list_name, key_type, value_type, comment )
    self.lists[ list_name ] = {
        list_table_name = self.table_name .. "_" .. list_name, -- Only relevant for SQL
        key_type = NormalizeType( key_type ),
        value_type = NormalizeType( value_type ),
        comment = comment,
    }
end

local function readFlatfile( datatable )
    local data = wrappers.FileRead( datatable.table_name .. ".txt" )
    local comment, data = SplitCommentHeader( data )
    datatable.file_header = comment
    
    -- We parse this and then convert back to keyvalues to ensure that it's in a standardized format (and valid).
    local parsed, err = ParseKeyValues( data )
    if not parsed then
        error( "could not read database, possible corruption. error is: " .. err )
    end
    datatable.file_cache = MakeKeyValues( parsed )
end

local function saveFlatfile( datatable )
    if not datatable.in_transaction then
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
        datatable.file_cache = datatable.file_cache .. (datatable.file_cache ~= "" and "\n" or "") .. keyvalues
    end

    saveFlatfile( datatable )
end

function DataTable:BeginTransaction()
    self.in_transaction = true
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        wrappers.BeginTransaction( self.database_type )

    elseif self.database_type == DatabaseTypes.Flatfile then
        -- Do nothing

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

function DataTable:EndTransaction()
    self.in_transaction = nil
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        wrappers.EndTransaction( self.database_type )

    elseif self.database_type == DatabaseTypes.Flatfile then
        saveFlatfile( self )

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

function DataTable:ClearCache()
    if self.database_type == DatabaseTypes.Flatfile then
        readFlatfile( self )
    end
    
    datatable_cache[ self.table_name ] = {}
end

-- Doc special case: flatfiles
function DataTable:DisableCache()
    self:ClearCache()
    self.no_caching = true
end

function DataTable:EnableCache()
    self.no_caching = nil
end

function createTableIfNeeded( datatable )
    if datatable.created then return end
    datatable.created = true
    
    if DataEqualsAnyOf( datatable.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement_template = "CREATE TABLE IF NOT EXISTS `%s` (%s)"
        local comment_template = " COMMENT '%s'"
        local column_template = "`%s` %s"
    
        -- Normally primary key implies not null, but sqlite3 doesn't follow the standard, so we explicitly state it
        local column_definitions = { column_template:format( datatable.primary_key_name, datatable.primary_key_type ) .. " PRIMARY KEY NOT NULL" } -- Prepopulate with primary key column definition
        for key_name, key_data in pairs( datatable.keys ) do
            table.insert( column_definitions, column_template:format( key_name, key_data.value_type ) )
            if datatable.database_type == DatabaseTypes.MySQL and datatable.keys[ key_name ].comment then -- Add comment if necessary
                column_definitions[ #column_definitions ] = column_definitions[ #column_definitions ] .. comment_template:format( datatable.keys[ key_name ].comment )
            end
        end
    
        if datatable.database_type == DatabaseTypes.MySQL and datatable.table_comment then -- Add comment if necessary
            column_definitions[ 1 ] = column_definitions[ 1 ] .. comment_template:format( datatable.table_comment )
        end
    
        wrappers.Execute( datatable.database_type, statement_template:format( datatable.table_name, table.concat( column_definitions, ", " ) ) )

        for list_name, list_data in pairs( datatable.lists ) do
            column_definitions = {
                column_template:format( datatable.primary_key_name, datatable.primary_key_type ) .. " NOT NULL",
                column_template:format( "key", list_data.key_type ) .. " NOT NULL",
                column_template:format( "value", list_data.value_type ) .. " NOT NULL",
                "PRIMARY KEY(`" .. datatable.primary_key_name .. "`, `key`)", -- Composite primary key of self's primary key and the key of this table.
            }
            wrappers.Execute( datatable.database_type, statement_template:format( datatable.table_name .. "_" .. list_name, table.concat( column_definitions, ", " ) ) )
        end
    
    elseif datatable.database_type == DatabaseTypes.Flatfile then
        if not wrappers.FileExists( datatable.table_name .. ".txt" ) then
            local comment_lines = { "; Format:" }
            local comment_template = " <-- %s"
            table.insert( comment_lines, ('"<%s>"%s'):format( datatable.primary_key_name, (datatable.table_comment and comment_template:format( datatable.table_comment ) or "") ) )
            table.insert( comment_lines, "{" )
            table.insert( comment_lines, ('    "%s"  "<%s>"%s'):format( datatable.primary_key_name, datatable.primary_key_name, comment_template:format( "A repeat of the value above, must exist and must be the same" ) ) )
            for key_name, key_data in pairs( datatable.keys ) do
                table.insert( comment_lines, ('    "%s"  "<%s>"%s'):format( key_name, key_name, (key_data.comment and comment_template:format( key_data.comment ) or "") ) )
            end
            for list_name, list_data in pairs( datatable.lists ) do
                table.insert( comment_lines, ('    "%s"%s'):format( list_name, (list_data.comment and comment_template:format( list_data.comment ) or "") ) )
                table.insert( comment_lines, '    {' )
                table.insert( comment_lines, '        ...' )
                table.insert( comment_lines, '    }' )
            end
            table.insert( comment_lines, "}" )
            
            datatable.file_header = table.concat( comment_lines, "\n; " )
            datatable.file_cache = ""
            saveFlatfile( datatable )
        else
            readFlatfile( datatable )
        end
        
    else
        return error( unknown_database_type:format( tostring( datatable.database_type ), datatable.table_name ) )
    end
end

function DataTable:UntrackedCopy( data )
    local root = Copy( getmetatable( data ).__index )
    for list_name, list_info in pairs( self.lists ) do
        root[ list_name ] = Copy( getmetatable( data[ list_name ] ).__index )
    end
    
    return root
end

function DataTable:ConvertTo( database_type )
    if self.database_type == database_type then return end
    
    local all = self:GetAll()
    self.database_type = database_type
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement = ("DROP TABLE IF EXISTS `%s`"):format( self.table_name )
        wrappers.Execute( self.database_type, statement )
        
        for list_name, list_data in pairs( self.lists ) do
            statement = ("DROP TABLE IF EXISTS `%s`"):format( list_data.list_table_name )
            wrappers.Execute( self.database_type, statement )
        end
    
    elseif self.database_type == DatabaseTypes.Flatfile then
        wrappers.FileDelete( self.table_name .. ".txt" )
        
    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
    
    -- Force re-creation
    self.created = nil
    createTableIfNeeded( self )
    
    for key, value in pairs( all ) do
        self:Insert( key, value )
    end
end

local function newindex( t, key, value )
    if t[ key ] == value then return end -- No action needed
    
    local meta = getmetatable( t )
    
    if meta.table.lists[ key ] then
        return error( "cannot set list keys, table in question is '" .. meta.table.table_name .. "'", 2 )
    elseif key == meta.table.primary_key_name then
        return error( ("cannot set primary key '%s' in table '%s', remove and insert instead"):format( key, meta.table.table_name ), 2 )
    elseif not meta.list_info and not meta.table.keys[ key ] then -- It's data that doesn't belong
        return error( error_key_not_registered:format( key, meta.table.table_name ), 2 )
    end
    
    meta.__index[ key ] = value
    
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
        local data = meta.table:Fetch( meta.primary_key )
        if not data then
            return error( ("data for '%s' in '%s' was removed, perhaps a row was held for too long?"):format( meta.primary_key, meta.table.table_name ) )
        end
        local row = meta.table:UntrackedCopy( data )
        insertOrReplaceIntoFlatfile( meta.table, row )

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end

local function trackRow( datatable, data )
    data = data or {}
    local primary_key = data[ datatable.primary_key_name ]
    local ret = setmetatable( {}, { table=datatable, primary_key=primary_key, __index=data, __newindex=newindex } )
    if not datatable.no_caching then
        datatable_cache[ datatable.table_name ][ primary_key ] = ret
    end
    
    for list_name, list_info in pairs( datatable.lists ) do
        data[ list_name ] = setmetatable( {}, { table=datatable, primary_key=primary_key, list_info=list_info, __index=(data[ list_name ] or {}), __newindex=newindex } )
    end
    
    return ret
end

function DataTable:Insert( primary_key, data )
    createTableIfNeeded( self )
    
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
    createTableIfNeeded( self )
    
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
    createTableIfNeeded( self )
    
    datatable_cache[ self.table_name ][ primary_key ] = nil
    
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
    createTableIfNeeded( self )
    
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

function DataTable:Empty()
    createTableIfNeeded( self )
    self:ClearCache()
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement = ("DELETE FROM `%s`"):format( self.table_name )
        wrappers.Execute( self.database_type, statement )
        
        for list_name, list_data in pairs( self.lists ) do
            statement = ("DELETE FROM `%s`"):format( list_data.list_table_name )
            wrappers.Execute( self.database_type, statement )
        end
    
    elseif self.database_type == DatabaseTypes.Flatfile then
        self.file_cache = ""
        saveFlatfile( self )
        
    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
end
