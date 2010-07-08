module( "TestSimpleData", package.seeall )

local function setupTable( database_type )
    local users = otlib.CreateDataTable( "users_" .. database_type, "id", "string(32)", "The id of the user", database_type )
    users:AddKey( "group", "string(16)", "The group the user belongs to" )
    users:AddKey( "name", "string(32)", "The name the player was last seen with" )
    users:AddListOfKeyValues( "allow", "string(16)", "string(128)", "The allows for the user" )
    users:AddListOfKeyValues( "deny", "number", "string(128)", "The denies for the user" )
    return users
end

local usera = { name="F}oo\"", id="id_a", group="admin", allow={ ["ot slap"]="usera_slap", ["ot kick"]="usera_kick" }, deny={ "ban", "slay", "bar" } }
local userb = { name="B{\"ar", id="id_b", group="operator", allow={ ["ot slap"]="*", ["ot kick"]="*cccccc*" } }
local userc = { name="Bo{b\"¡•∞¢£ƒ˙∫ç∂∆", id="id_c", deny={ "pi", "soda", "cheesecake" }, allow={} }
local userd = { name="!@#$%^&*()", id="id_d", group="superadmin" }

local function runBasicTest( users )
    local usera_db = users:Insert( usera.id, otlib.DeepCopy( usera ) )
    
    usera_db.group = nil -- Can this be removed alright?
    usera_db.group = "superadmin" -- And set again?
    usera_db.group = "superadmin" -- And again to the same value?
    AssertError( function() usera_db.allow = {} end ) -- This would break things if it didn't throw an error
    AssertError( function() usera_db.id = "newid" end ) -- This would also break things
    AssertError( function() usera_db.nonexistant = "foobar" end ) -- Don't allow data that's not defined
    usera_db.allow[ "ot slap" ] = nil -- Can it be removed?
    usera_db.allow[ "ot slap" ] = "*b*" -- And set?
    usera_db.allow[ "ot slap" ] = "*b*" -- And set again?
    usera_db.allow[ "ot kick" ] = "**"
    usera_db.deny[ 1 ] = "celery"
    usera_db.deny[ 2 ] = "broccoli"
    usera_db.deny[ 3 ] = "carrots"
    AssertEquals( usera_db, users:Fetch( usera.id ) ) -- Should be from the cache
    users:ClearCache()
    AssertNotEquals( usera_db, users:Fetch( usera.id ) ) -- Should regen
    AssertTablesEqual( users:UntrackedCopy( usera_db ), users:UntrackedCopy( users:Fetch( usera.id ) ) ) -- But be equal
    
    users:BeginTransaction()
    local userb_db = users:Insert( userb.id, otlib.DeepCopy( userb ) )
    local userc_db = users:Insert( userc.id, otlib.DeepCopy( userc ) )
    local userd_db = users:Insert( userd.id )
    userd_db.name = userd.name
    userd_db.group = userd.group
    users:EndTransaction()
    AssertEquals( userd_db, users:Fetch( userd.id ) ) -- Should be from the cache
    users:DisableCache()
    AssertNotEquals( userd_db, users:Fetch( userd.id ) ) -- Should regen
    AssertTablesEqual( users:UntrackedCopy( userd_db ), users:UntrackedCopy( users:Fetch( userd.id ) ) ) -- But be equal
    AssertNotEquals( userd_db, users:Fetch( userd.id ) ) -- Should regen
    AssertTablesEqual( users:UntrackedCopy( userd_db ), users:UntrackedCopy( users:Fetch( userd.id ) ) ) -- But be equal
    users:EnableCache()

    AssertEquals( users:Fetch( "id_f" ), nil )
    AssertEquals( users:Remove( "id_f" ), false )
    AssertEquals( users:Remove( userb.id ), true )

    all_data = users:GetAll()
    AssertEquals( all_data[ userb.id ], nil )
    AssertTablesEqual( all_data[ userc.id ], userc )
    return all_data
end

function TestSQLite3()
    local users = setupTable( otlib.DatabaseTypes.SQLite )
    users:Empty()
    local all_data = runBasicTest( users )
    
    users:ConvertTo( otlib.DatabaseTypes.MySQL )
    AssertTablesEqual( all_data, users:GetAll() )
end

function TestMySQL()
    local users = setupTable( otlib.DatabaseTypes.MySQL )
    users:Empty()
    runBasicTest( users )
    
    users:ConvertTo( otlib.DatabaseTypes.Flatfile )
    AssertTablesEqual( all_data, users:GetAll() )
end

function TestFlatfile()
    local users = setupTable( otlib.DatabaseTypes.Flatfile )
    users:Empty()
    runBasicTest( users )
    
    users:ConvertTo( otlib.DatabaseTypes.SQLite )
    AssertTablesEqual( all_data, users:GetAll() )
end
