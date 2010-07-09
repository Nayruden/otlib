module( "TestAccess", package.seeall )

-- Setup a simple group ladder
user        = otlib.group:CreateClonedGroup( "user" ) -- Root group
operator    = user:CreateClonedGroup( "operator" )
admin       = operator:CreateClonedGroup( "admin" )
superadmin  = admin:CreateClonedGroup( "superadmin" )

-- Simple permission
slap = otlib.access:Register( "slap", admin )
slap:AddParam( otlib.NumParam():Min( 0 ):Max( 100 ) )
slap:AddParam( otlib.NumParam():Min( 0 ):Max( 10 ):MinRepeats( 0 ) )

-- A user with access
user1 = admin:CreateClonedUser( "123" )

-- Another user with no access
user2 = operator:CreateClonedUser( "321" )

-- Another user with modified access
user3 = superadmin:CreateClonedUser( "213" )
local access = user3:Allow( slap )
access:ModifyParam( 1 ):Min( -50 ):Max( 50 )

function TestNoAccess()
    local has_access, condition
    
    -- Make sure the access fails first on just 'no access' for this user
    has_access, condition = user2:CheckAccess( slap, 600 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.AccessDenied ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.NoAccess )
    AssertEquals( condition:GetParameterNum(), nil )
    
    has_access, condition = user2:CheckAccess( slap )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.AccessDenied ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.NoAccess )
    AssertEquals( condition:GetParameterNum(), nil )
end

function TestBasicAccess()
    local has_access, condition
    
    has_access, condition = user1:CheckAccess( slap, 0 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )
    
    has_access, condition = user1:CheckAccess( slap, "0" )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )
    
    has_access, condition = user1:CheckAccess( slap, 41 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )

    has_access, condition = user1:CheckAccess( slap, 100 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )

    -- Missing required arg
    has_access, condition = user1:CheckAccess( slap )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.MissingRequiredParam ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 1 )
    
    -- Too many args
    has_access, condition = user1:CheckAccess( slap, 10, 10, 5 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooManyParams ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 3 )

    -- Too high
    has_access, condition = user1:CheckAccess( slap, 101 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooHigh ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 1 )
    
    has_access, condition = user1:CheckAccess( slap, "101" )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooHigh ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 1 )

    -- Too low
    has_access, condition = user1:CheckAccess( slap, -1 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooLow ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 1 )
end

function TestOverriddenAccess()
    local has_access, condition
    
    has_access, condition = user3:CheckAccess( slap, 0 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )
    
    has_access, condition = user3:CheckAccess( slap, 41 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )

    has_access, condition = user3:CheckAccess( slap, 50 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )

    -- Missing required arg
    has_access, condition = user3:CheckAccess( slap )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.MissingRequiredParam ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 1 )
    
    -- Too many args
    has_access, condition = user3:CheckAccess( slap, 10, 10, 5 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooManyParams ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 3 )

    -- Too high
    has_access, condition = user3:CheckAccess( slap, 51 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooHigh ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.UserParameters )
    AssertEquals( condition:GetParameterNum(), 1 )

    -- Too low
    has_access, condition = user3:CheckAccess( slap, -1 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooLow ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Parameters )
    AssertEquals( condition:GetParameterNum(), 1 )
end
