module( "TestAccess", package.seeall )

-- Setup a simple group ladder
operator    = otlib.user:CreateClonedGroup( "operator" )
admin       = operator:CreateClonedGroup( "admin" )
superadmin  = admin:CreateClonedGroup( "superadmin" )

-- Simple permission
slap = otlib.access:Register( "slap", otlib.admin )
slap:AddParam( otlib.NumParam():Min( 0 ):Max( 100 ) )

-- A user
user1 = admin:CreateClonedUser( "123" )
local access = user1:Allow( slap )
access:ModifyParam( 1 ):Min( -50 ):Max( 50 )

-- Another user
user2 = operator:CreateClonedUser( "321" )

function TestBasicAccess()
    local has_access, condition
    has_access, condition = user1:CheckAccess( slap, 0 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )

    has_access, condition = otlib.CheckAccess( "123", slap, 50 )
    AssertEquals( has_access, true )
    AssertEquals( condition, nil )

    has_access, condition = otlib.CheckAccess( "123", slap )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.MissingRequiredParam ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Access )
    AssertEquals( condition:GetParameterNum(), 1 )

    has_access, condition = otlib.CheckAccess( "123", slap, 51 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooHigh ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.User )
    AssertEquals( condition:GetParameterNum(), 1 )

    has_access, condition = otlib.CheckAccess( "123", slap, -1 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.TooLow ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.Access )
    AssertEquals( condition:GetParameterNum(), 1 )

    has_access, condition = otlib.CheckAccess( "321", slap, 6 )
    AssertEquals( has_access, false )
    AssertEquals( condition:IsA( otlib.InvalidCondition.AccessDenied ), true )
    AssertEquals( condition:GetLevel(), otlib.InvalidCondition.DeniedLevel.NoAccess )
    AssertEquals( condition:GetParameterNum(), nil )
end
