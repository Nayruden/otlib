module( "TestAccess", package.seeall )

-- Setup a simple group ladder
user        = otlib.group:CreateClonedGroup( "user" ) -- Root group
operator    = user:CreateClonedGroup( "operator" )
admin       = operator:CreateClonedGroup( "admin" )
superadmin  = admin:CreateClonedGroup( "superadmin" )

-- Simple permission
slap = otlib.access:Register( "slap", admin )
slap:AddParam( otlib.NumParam():Min( 0 ):Max( 100 ) )
slap:AddParam( otlib.NumParam():Min( 0 ):Max( 10 ):MinRepeats( 0 ):Default( 1 ) )

say = otlib.access:Register( "say", admin )
say:AddParam( otlib.StringParam():TakesRestOfLine( true ) )

-- A user with access
user1 = admin:CreateClonedUser( "123" )

-- Another user with no access
user2 = operator:CreateClonedUser( "321" )

-- Another user with modified access
user3 = superadmin:CreateClonedUser( "213" )
local access = user3:Allow( slap )
access:ModifyParam( 1 ):Min( -50 ):Max( 50 )

-- Another user with denied access
user4 = superadmin:CreateClonedUser( "user4" )
user4:Deny( slap )

local function ensureAccess( user, access, should_ret, ... )
    local has_access, ret = user:CheckAccess( access, ... )
    AssertEquals( has_access, true )
    AssertTablesEqual( should_ret, ret )
end

local function ensureNoAccess( user, access, typ, level, param_num, ... )
    local has_access, condition = user:CheckAccess( access, ... )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( typ ), true )
    AssertEquals( condition:GetLevel(), level )
    AssertEquals( condition:GetParameterNum(), param_num )
end

local function runFullSlapTest( user, low, low_level, high, high_level )    
    local access = slap
    ensureAccess( user, access, { low, 1 }, low )
    ensureAccess( user, access, { low, 1 }, tostring( low ) )
    
    local mid = math.ceil( (high + low) / 2 )
    ensureAccess( user, access, { mid, 1 }, mid )
    ensureAccess( user, access, { mid, 1 }, tostring( mid ) )
    
    ensureAccess( user, access, { high, 1 }, high )
    ensureAccess( user, access, { high, 1 }, tostring( high ) )
    
    ensureAccess( user, access, { high, 5 }, high, 5 )

    -- Missing required arg
    ensureNoAccess( user, access, otlib.InvalidCondition.MissingRequiredParam, otlib.InvalidCondition.DeniedLevel.Parameters, 1 )
    
    -- Too many args
    ensureNoAccess( user, access, otlib.InvalidCondition.TooManyParams, otlib.InvalidCondition.DeniedLevel.Parameters, 3, 10, 5, 30 )

    -- Too high
    ensureNoAccess( user, access, otlib.InvalidCondition.TooHigh, high_level, 1, high+1 )
    ensureNoAccess( user, access, otlib.InvalidCondition.TooHigh, high_level, 1, tostring( high+1 ) )

    -- Too low
    ensureNoAccess( user, access, otlib.InvalidCondition.TooLow, low_level, 1, low-1 )
    ensureNoAccess( user, access, otlib.InvalidCondition.TooLow, low_level, 1, tostring( low-1 ) )
end

local function runFullSayTest( user )
    local access = say
    local word = "word"
    local sentence = "This is a sentence"
    ensureAccess( user, access, { word }, word )
    ensureAccess( user, access, { sentence }, sentence )
end

function TestNoAccess()
    ensureNoAccess( user2, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil )
    ensureNoAccess( user2, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, 10 )
    ensureNoAccess( user2, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, "10" )
    ensureNoAccess( user2, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, 101 )
    ensureNoAccess( user2, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, "101" )
    
    ensureNoAccess( user4, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil )
    ensureNoAccess( user4, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, 10 )
    ensureNoAccess( user4, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, "10" )
    ensureNoAccess( user4, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, 101 )
    ensureNoAccess( user4, slap, otlib.InvalidCondition.AccessDenied, otlib.InvalidCondition.DeniedLevel.NoAccess, nil, "101" )
end

function TestBasicAccess()
    runFullSlapTest( user1, 0, otlib.InvalidCondition.DeniedLevel.Parameters, 100, otlib.InvalidCondition.DeniedLevel.Parameters )
    runFullSayTest( user1 )
end

function TestOverriddenAccess()
    runFullSlapTest( user3, 0, otlib.InvalidCondition.DeniedLevel.Parameters, 50, otlib.InvalidCondition.DeniedLevel.UserParameters )
    runFullSayTest( user3 )
end
