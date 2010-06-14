--- File: Simple Data

-- Temp
dofile( "init.lua" )
dofile( "utils.lua" )
dofile( "table_utils.lua" )
dofile( "prototype.lua" )
dofile( "access.lua" )
dofile( "debug.lua" )
dofile( "parameters.lua" )
package.cpath = package.cpath .. ";/Users/zoot/.luarocks/lib/lua/5.1/?.so"
require( "luasql.sqlite3" )
sqlite3 = assert( luasql.sqlite3() )
conn = assert( sqlite3:connect( "test.db" ) )

--[[
    Module: otlib.simpledata
    
    Offers a wrapper around file or database I/O for _simple_ data needs. You'll be able to access
    the data without caring what the backend is (SQL or flat-file), but each row in the database
    will need to have a unique key and only four operations are supported on the data. The four
    operations are fetch all rows, retrieve row by key, delete row by key, and update row (which 
    will happen automatically unless you turn that off). In other words, there's no searching on
    anything other than the unique key unless you're willing to grab all the data and search
    yourself.
]]--
module( "otlib", package.seeall )

local use_sql = true
local Table = object:Clone()

local function FormatData( data )
    if type( data ) == "string" then
        data = string.format( "%q", data )
    end
    
    return data
end

local function NormalizeType( typ )
    return typ:gsub( "string", "CHAR" ):upper()
end

local function Execute( statement )
    print( statement )
    return conn:execute( statement )
end

local function DoTableCreation( t )
    -- We could do foreign constraints here (and it would make sense), but SQLite doesn't really support it so we'll just do it by hand.
    if t.creation_run then return end
    t.creation_run = true
    
    local statement = "CREATE TABLE IF NOT EXISTS `" .. t.table_name .. "` ("
    local def_template = "`%s` %s"
    local column_defs = { def_template:format( t.primary_key, NormalizeType( t.primary_key_type ) ) .. " PRIMARY KEY NOT NULL" }
    for k, v in pairs( t.columns ) do
        table.insert( column_defs, def_template:format( k, NormalizeType( v ) ) )
    end
    statement = statement .. table.concat( column_defs, ", " ) .. ");"
    Execute( statement )
    
    for name, data in pairs( t.lists ) do
        statement = "CREATE TABLE IF NOT EXISTS `" .. t.table_name .. "_" .. name .. "` ("
        column_defs = { 
            def_template:format( t.primary_key, NormalizeType( t.primary_key_type ) ) .. " NOT NULL",
            def_template:format( "key", NormalizeType( data.key_type ) ) .. " NOT NULL",
            def_template:format( "value", NormalizeType( data.value_type ) ) .. " NOT NULL"
        }
        statement = statement .. table.concat( column_defs, ", " ) .. ", PRIMARY KEY(`" .. t.primary_key .. "`, `key`));"
        Execute( statement )
    end
end

function CreateTable( table_name, primary_key, primary_key_type, comment )
    local new_table = Table:Clone()
    new_table.table_name = table_name
    new_table.primary_key_type = primary_key_type
    new_table.primary_key = primary_key
    new_table.columns = {}
    new_table.lists = {}
    new_table.creation_run = false
    
    return new_table
end

local function newindex( t, key, value )
    local statement 
    if not t.is_list then
        statement = "UPDATE `" .. t.table_name .. "` SET `" .. key .. "`=" .. FormatData( value ) .. " WHERE `" .. t.primary_key .. "`=" .. FormatData( t[ t.primary_key ] ) .. ";"
    else
        statement = "INSERT OR REPLACE INTO `" .. t.table_name .. "` (`" .. t.primary_key .. "`, `key`, `value`) VALUES (" .. FormatData( t[ t.primary_key ] ) .. ", " .. FormatData( key ) .. ", " .. FormatData( value ) .. ");"
    end
    Execute( statement )
end
local meta = { __newindex=newindex }

function Table:Add( column_name, column_type, comment )
    self.columns[ column_name ] = column_type
    
    return self
end

function Table:AddKeyValueList( list_name, key_type, value_type, comment )
    self.lists[ list_name ] = {
        key_type=key_type,
        value_type=value_type,
    }
    
    return self
end

function Table:Insert( key )
    DoTableCreation( self )
    local statement = "INSERT OR REPLACE INTO `" .. self.table_name .. "` (`" .. self.primary_key .. "`) VALUES (" .. FormatData( key ) .. ");"
    local new_table = {}
    new_table.table_name = self.table_name
    new_table.primary_key = self.primary_key
    new_table[ self.primary_key ] = key
    Execute( statement )
    
    for name, data in pairs( self.lists ) do -- TODO massive cleanup... maybe an cloned metatable?
        new_table[ name ] = {}
        new_table[ name ].table_name = self.table_name .. "_" .. name
        new_table[ name ].primary_key = self.primary_key
        new_table[ name ][ self.primary_key ] = key
        new_table[ name ].is_list = true
        setmetatable( new_table[ name ], meta )
    end
    
    setmetatable( new_table, meta )
    return new_table
end

function Table:Fetch( key )
    DoTableCreation( self )
    local statement = "SELECT * FROM `" .. self.table_name .. "` WHERE `" .. self.primary_key .. "`=" .. FormatData( key ) .. ";"
    local cursor = Execute( statement )
    result = cursor:fetch( {}, "a" ) -- TODO meta
    
    for name, data in pairs( self.lists ) do
        result[ name ] = {}
        statement = "SELECT * FROM `" .. self.table_name .. "_" .. name .. "` WHERE `" .. self.primary_key .. "`=" .. FormatData( key ) .. ";"
        cursor = Execute( statement )
        local tmp = cursor:fetch( {}, "a" ) -- TODO meta
        while tmp do
            result[ name ][ tmp.key ] = tmp.value
            tmp = cursor:fetch( tmp, "a" )
        end
    end
    
    return result
end

function Table:Remove( key )
    DoTableCreation( self )
    local statement = "DELETE FROM `" .. self.table_name .. "` WHERE `" .. self.primary_key .. "`=" .. FormatData( key ) .. ";"
    Execute( statement )
    
    for name, data in pairs( self.lists ) do
        statement = "DELETE FROM `" .. self.table_name .. "_" .. name .. "` WHERE `" .. self.primary_key .. "`=" .. FormatData( key ) .. ";"
        Execute( statement )
    end
end

function Table:GetAll()
    DoTableCreation( self )
    local statement = "SELECT * FROM `" .. self.table_name .. "`;"
    -- Get data, meta
    Execute( statement )
    for name, data in pairs( self.lists ) do
        statement = "SELECT * FROM `" .. self.table_name .. "_" .. name .. "`;"
        -- Get data, meta
        Execute( statement )
    end
end

local users = CreateTable( "users", "steamid", "string(32)", "The steamid of the user" )
users:Add( "group", "string(16)", "The group the user belongs to" )
users:Add( "name", "string(32)", "The name the player was last seen with" )
users:AddKeyValueList( "allow", "string(16)", "string(128)", "The allows for the user" )

user1 = users:Insert( "steamid1" )
user1.name = "Bob"
user1.group = "operator"
user1.allow[ "ulx slap" ] = "*b*"
user1.allow[ "ulx kick" ] = "*"

user1 = users:Insert( "steamid2" )
user1.name = "Bob2"
user1.group = "operator2"
user1.allow[ "ulx slap" ] = "*c*"
user1.allow[ "ulx kick" ] = "*kkk"

user2 = users:Fetch( "steamid2" )
print( otlib.Vardump( user2 ) )

users:Remove( "steamid3" )

all_data = users:GetAll()

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
