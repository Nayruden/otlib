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
    
        * Save to flatfile (readable text), SQLite, or MySQL.
        * Convert between formats on the fly.
        * Caching of retrieved data.
        * Can flush the cache on the fly, or disable the caching entirely.
        * Automatically and instantly saves changes.
        * Can do transactions. This means several changes are pushed at once.
        * Optional comments are added to MySQL and the flatfile to describe your data.
]]

--- Module: otlib
module( "otlib", package.seeall )

--[[
-- Copied from defines.lua, but the 'official' one is in that file.
DatabaseTypes = {
    Flatfile = 'Flatfile',
    SQLite = 'SQLite',
    MySQL = 'MySQL',
}
]]

--- Variable: preferred_database_type
--- The *<DatabaseTypes>* to use by default.
preferred_database_type = DatabaseTypes.Flatfile
local error_key_not_registered = "tried to pass in key '%s' to table '%s', but key was not registered"
local unknown_database_type = "unknown database type '%s' for table name '%s'"

local DataTable
local datatable_cache = {}

-- Normalize a type and pass back the sql type and the lua type.
local function normalizeType( typ )
    if typ == "number" then
        return "REAL", typ
    elseif typ:find( "string%s*%(?%d*%)?") then
        return typ:gsub( "string", "CHAR" ):gsub( " ", "" ):upper(), "string"
    else
        return error( "unrecognized type in simpledata '" .. typ .. "'", 2 )
    end
end

--[[
    Function: CreateDataTable

    Creates a new data table for use.

    Parameters:

        table_name - The unique *string* of the table name. IE, "users" for data about users.
        primary_key_name - The *string* of the name for the primary key of the table. IE, 
            "ip_address". For more information see <DataTable.AddKey>.
        primary_key_type - The *string* of the type for the primary key of the table. For more
            information see <DataTable.AddKey>.
        comment - The *optional string* of the comment to use for the primary key.
        database_type - The *optional <otlib.DatabaseTypes>* to use for this table. Defaults to the 
            value of _<preferred_database_type>_.

    Returns:

        The newly created <DataTable>.

    Revisions:

        v1.00 - Initial.
]]
function CreateDataTable( table_name, primary_key_name, primary_key_type, comment, database_type )
    if datatable_cache[ table_name ] then
        return error( "table named '" .. table_name .. "' has already been created" )
    elseif DataEqualsAnyOf( primary_key_name, "key", "value" ) then
        return error( "cannot have a primary key name of 'key' or 'value', these names are reserved", 2 )
    end
    
    local new_data_table = DataTable:Clone()
    new_data_table.table_name = table_name
    new_data_table.primary_key_name = primary_key_name
    new_data_table.primary_key_type = normalizeType( primary_key_type )
    new_data_table.table_comment = comment
    new_data_table.database_type = database_type or preferred_database_type
    
    -- Setup cache entry
    datatable_cache[ table_name ] = {}
    
    -- Key info
    new_data_table.keys = {}
    new_data_table.key_lua_types = { [primary_key_name]="string" }
    new_data_table.lists = {}
    new_data_table.comments = {}
    
    return new_data_table
end

--- Object: otlib.DataTable
DataTable = object:Clone()

--[[
    Function: AddKey

    Adds a key to the data table. To help understand this, imagine that you couldn't just do 
    my_table.my_key = some_value in lua, that you had to define my_key first before you were able
    to assign to it. That's basically what this function is for. You'll need to define any keys you
    want to use before you use them.
    
    This function must be used directly after you create the table using <CreateDataTable> and
    before you use functions such as <Insert> or <Fetch>.

    Parameters:

        key_name - The *string* of a key name for the table. IE, "group". This name is what you'll
            use to refer to the data later.
        key_type - The *string* of the type for this key in the table. Valid strings to pass in are
            "string(<max_length_of_string)" or "number".
        comment - The *optional string* of the comment to use for this key. The comment will show
            up in flatfiles and in MySQL.

    Returns:

        *Self*.

    Revisions:

        v1.00 - Initial.
]]
function DataTable:AddKey( key_name, key_type, comment )
    if self.created then
        return error( "datatable has already been finalized", 2 )
    elseif self.lists[ key_name ] then
        return error( "that name is already being used by a list of key values", 2 )
    end
    
    local sql_type, lua_type = normalizeType( key_type )
    self.keys[ key_name ] = {
        sql_type = sql_type,
        comment = comment,
    }
    
    self.key_lua_types[ key_name ] = lua_type
    
    return self
end


--[[
    Function: AddListOfKeyValues

    Adds a key to the data table, whose value is going to be a table. To help understand this, 
    imagine that you couldn't just do my_table.my_key = {} in lua, that you had to define my_key 
    first before you were able to assign a table to it. That's basically what this function is for.
    You'll need to define any keys you want to use before you use them.
    
    In this case, the value of the key defined here is a table that can contain anything, as long
    as each key and value in the table conform to the types given, below.
    
    This function must be used directly after you create the table using <CreateDataTable> and
    before you use functions such as <Insert> or <Fetch>.

    Parameters:

        list_name - The *string* of a list name for the table. IE, "allow". This name is what 
            you'll use to refer to the data later.
        key_type - The *string* of the type for the keys in the list. See <AddKey> for more 
            information.
        value_type - The *string* of the type for the values in the list. See <AddKey> for more 
            information.
        comment - The *optional string* of the comment to use for this key. The comment will show
            up in flatfiles and in MySQL.

    Returns:

        *Self*.

    Revisions:

        v1.00 - Initial.
]]
function DataTable:AddListOfKeyValues( list_name, key_type, value_type, comment )
    if self.created then
        return error( "datatable has already been finalized", 2 )
    elseif self.keys[ list_name ] then
        return error( "that name is already being used by a key", 2 )
    end
    
    local key_sql_type, key_lua_type = normalizeType( key_type )
    local value_sql_type, value_lua_type = normalizeType( value_type )
    
    self.lists[ list_name ] = {
        list_table_name = self.table_name .. "_" .. list_name, -- Only relevant for SQL
        key_sql_type = key_sql_type,
        value_sql_type = value_sql_type,
        key_lua_types = { [self.primary_key_name]="string", key=key_lua_type, value=value_lua_type },
        comment = comment,
    }
    
    return self
end

-- Read the header and data sections of a flat file into our cache
local function readFlatfile( datatable )
    local file = wrappers.FileRead( datatable.table_name .. ".txt" )
    datatable.file_header, datatable.file_cache = SplitCommentHeader( file )
end

-- Saves the flatfile from cache
local function saveFlatfile( datatable )
    if not datatable.in_transaction then
        wrappers.FileWrite( datatable.table_name .. ".txt", datatable.file_header .. "\n" .. datatable.file_cache .. "\n" )
    end
end

-- Just a little utility that's almost like SELECT for flat files (just returning location in file though)
local function findInFlatfile( datatable, primary_key )
    -- Normally I'd want to use %b{}, but that won't work here since the data may contain braces.
    local start, end_chunk = datatable.file_cache:find( ("%q"):format( primary_key ) .. "%s-\n%s*{" )
    if not start then return nil, nil end
    
    local dummy, matched
    local depth = 1 -- We read past the first brace
    while depth ~= 0 do
        dummy, end_chunk, matched = datatable.file_cache:find( "\n%s*([{}])", end_chunk+1 )
        if not matched then
            return error( "data table for '" .. datatable.table_name .. "' corrupt" )
        elseif matched == "{" then
            depth = depth + 1
        elseif matched == "}" then
            depth = depth - 1
        else
            return error( "logical failure" )
        end
        
        if depth == 3 then
            return error( "data table for '" .. datatable.table_name .. "'corrupt" )
        end
    end
    
    return start, end_chunk+1
end

-- Pretty much the equivalent of REPLACE for flat files
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


--[[
    Function: BeginTransaction

    Begins a transaction. Between beginning and ending a transaction, data is basically built up in
    a buffer before getting sent off. This is especially useful for flatfiles since it means that
    we won't have to save the file (which is slow) a thousand times when data is initialized if the
    initialization takes advantage of transactions.

    You should note that not all implementations support transactions though, so this function
    might be silently ignored.

    Revisions:

        v1.00 - Initial.
]]
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


--[[
    Function: EndTransaction

    See <BeginTransaction>.

    Revisions:

        v1.00 - Initial.
]]
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


--[[
    Function: ClearCache

    Clears any cache that may be built up in this datatable. This is a good function to use when
    you know the external data has changed. For flatfiles this forces the file to be re-read.

    Revisions:

        v1.00 - Initial.
]]
function DataTable:ClearCache()
    if self.database_type == DatabaseTypes.Flatfile then
        readFlatfile( self )
    end
    
    datatable_cache[ self.table_name ] = {}
end

--[[
    Function: DisableCache

    First clears the cache with <ClearCache> and disables further caching until re-enabled with
    <EnableCache>. Flatfiles are a bit of a special case in that disabling the cache won't force 
    the file to be re-read every time we need to fetch data.
    
    Revisions:

        v1.00 - Initial.
]]
function DataTable:DisableCache()
    self:ClearCache()
    self.no_caching = true
end


--[[
    Function: EnableCache

    See <DisableCache>.

    Revisions:

        v1.00 - Initial.
]]
function DataTable:EnableCache()
    self.no_caching = nil
end

-- Setup the table if it needs to be setup.
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
            table.insert( column_definitions, column_template:format( key_name, key_data.sql_type ) )
            if datatable.database_type == DatabaseTypes.MySQL and datatable.keys[ key_name ].comment then -- Add comment if necessary
                column_definitions[ #column_definitions ] = column_definitions[ #column_definitions ] .. comment_template:format( datatable.keys[ key_name ].comment )
            end
        end
    
        if datatable.database_type == DatabaseTypes.MySQL and datatable.table_comment then -- Add comment if necessary
            column_definitions[ 1 ] = column_definitions[ 1 ] .. comment_template:format( datatable.table_comment )
        end
    
        local statement = statement_template:format( datatable.table_name, table.concat( column_definitions, ", " ) )
        wrappers.Execute( datatable.database_type, statement )

        for list_name, list_data in pairs( datatable.lists ) do
            column_definitions = {
                column_template:format( datatable.primary_key_name, datatable.primary_key_type ) .. " NOT NULL",
                column_template:format( "key", list_data.key_sql_type ) .. " NOT NULL",
                column_template:format( "value", list_data.value_sql_type ) .. " NOT NULL",
                "PRIMARY KEY(`" .. datatable.primary_key_name .. "`, `key`)", -- Composite primary key of self's primary key and the key of this table.
            }
            
            statement = statement_template:format( datatable.table_name .. "_" .. list_name, table.concat( column_definitions, ", " ) )
            wrappers.Execute( datatable.database_type, statement )
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


--[[
    Function: UntrackedCopy

    One of the downsides of using <DataTable> is that data you get out of it (except <GetAll>) 
    can't be thrown throw an iterator like pairs because of the way we track changes to the table. 
    To help alleviate this problem, you can create an untracked copy of the data using this 
    function.

    Parameters:

        data - The *table* of the data you want to get an untracked copy of. Must directly be the 
            table you got from <Insert> or <Fetch>. Don't pass anything else in here.

    Returns:

        The copied, untracked *table*.

    Revisions:

        v1.00 - Initial.
]]
function DataTable:UntrackedCopy( data )
    local root = Copy( getmetatable( data ).__index )
    for list_name, list_info in pairs( self.lists ) do
        root[ list_name ] = Copy( getmetatable( data[ list_name ] ).__index )
    end
    
    return root
end


--[[
    Function: ConvertTo

    Convert the <DataTable> from using one database type to another. Before converting the data to
    the new database type, it completely wipes whatever information was in the destination database
    type, so make sure you're okay with losing whatever information may be there.

    Parameters:

        database_type - The destination *<otlib.DatabaseTypes>*.

    Returns:

        *Self*.

    Revisions:

        v1.00 - Initial.
]]
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
    
    local was_in_transaction = self.in_transaction
    if not was_in_transaction then
        self:BeginTransaction()
    end
    
    for key, value in pairs( all ) do
        self:Insert( key, value )
    end
    
    if not was_in_transaction then
        self:EndTransaction()
    end
    
    return self
end

-- Called when new information is assigned to our tracked table
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

-- Track a row...
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


--[[
    Function: Insert

    Insert (or replace existing with) a new row.

    Parameters:

        primary_key - The primary key for the new row, should be the same type as you declared it
            to be in <CreateDataTable>.
        data - An *optional table* of data to constitute this row. Whatever information is required
            that isn't present in this table will be added by the function. Defaults to _{}_.

    Returns:

        The *table* that constitutes the tracked, inserted row. Use this new value to modify data.

    Revisions:

        v1.00 - Initial.
]]
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


--[[
    Function: Fetch

    Fetch a row from the database.

    Parameters:

        primary_key - The primary key for the new row, should be the same type as you declared it
            to be in <CreateDataTable>.

    Returns:

        The *table* that constitutes the tracked, inserted row if it exists, *nil* if it doesn't.

    Revisions:

        v1.00 - Initial.
]]
function DataTable:Fetch( primary_key )
    createTableIfNeeded( self )
    
    if datatable_cache[ self.table_name ][ primary_key ] then
        return datatable_cache[ self.table_name ][ primary_key ]
    end
    
    local data
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        primary_key = wrappers.FormatAndEscapeData( primary_key )
        local statement = ("SELECT * FROM `%s` WHERE `%s`=%s"):format( self.table_name, self.primary_key_name, primary_key )
        local raw = wrappers.Execute( self.database_type, statement, self.key_lua_types )
        if #raw == 0 then return nil end
        assert( #raw == 1 )
        data = raw[ 1 ]
        
        for list_name, list_info in pairs( self.lists ) do
            statement = ("SELECT * FROM `%s` WHERE `%s`=%s"):format( list_info.list_table_name, self.primary_key_name, primary_key )
            raw = wrappers.Execute( self.database_type, statement, list_info.key_lua_types )
            local t = {}
            data[ list_name ] = t
            for i=1, #raw do
                t[ raw[ i ].key ] = raw[ i ].value
            end
        end

    elseif self.database_type == DatabaseTypes.Flatfile then
        local start, stop = findInFlatfile( self, primary_key )
        if not start then return nil end
        local err
        data, err = ParseKeyValues( self.file_cache:sub( start, stop ) )
        if not data or Count( data ) ~= 1 then
            if err then
                return error( "data table for '" .. datatable.table_name .. "' corrupt, error is: " .. err )
            else
                return error( "data table for '" .. datatable.table_name .. "' corrupt" )
            end
        end
        data = data[ primary_key ]

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
    
    return trackRow( self, data )
end


--[[
    Function: Remove

    Delets a row from the database.

    Parameters:

        primary_key - The primary key for the new row, should be the same type as you declared it
            to be in <CreateDataTable>.

    Returns:

        A *boolean*, true if it existed and was removed, *false* if the row didn't exist.

    Revisions:

        v1.00 - Initial.
]]
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


--[[
    Function: GetAll

    Fetchs all rows from the database. This is similar to <Fetch>, except that it fetches all rows
    in the entire database, and all returned data is untracked. This obviously pretty slow and 
    should only be used if absolutely necessary.

    Returns:

        The *table* that constitutes the entire database.

    Revisions:

        v1.00 - Initial.
]]
function DataTable:GetAll()
    createTableIfNeeded( self )
    
    local data
    
    if DataEqualsAnyOf( self.database_type, DatabaseTypes.SQLite, DatabaseTypes.MySQL ) then
        local statement = ("SELECT * FROM `%s`"):format( self.table_name )
        local raw = wrappers.Execute( self.database_type, statement, self.key_lua_types )
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
            raw = wrappers.Execute( self.database_type, statement, list_info.key_lua_types )
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
            return error( "data table for '" .. datatable.table_name .. "' corrupt, error is: " .. err )
        end

    else
        return error( unknown_database_type:format( self.database_type, self.table_name ) )
    end
    
    return data
end


--[[
    Function: Empty

    Empties all existing data for this database and clears any caches.

    Revisions:

        v1.00 - Initial.
]]
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
