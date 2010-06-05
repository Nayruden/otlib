operator    = otlib.user:CreateClonedGroup( "operator" )
admin       = operator:CreateClonedGroup( "admin" )
superadmin  = admin:CreateClonedGroup( "superadmin" )

slap = otlib.access:Register( "slap", otlib.admin )
slap:AddParam( otlib.NumParam():Min( 0 ):Max( 100 ) )

user1 = admin:CreateClonedUser( "123" )
local access = user1:Allow( slap )
access:ModifyParam( 1 ):Min( -50 ):Max( 50 )

user2 = operator:CreateClonedUser( "321" )

local has_access, condition
has_access, condition = otlib.CheckAccess( "123", slap, 0 )
assert( has_access )
assert( condition == nil )

has_access, condition = otlib.CheckAccess( "123", slap, 50 )
assert( has_access )
assert( condition == nil )

has_access, condition = otlib.CheckAccess( "123", slap )
assert( not has_access )
assert( condition:IsA( otlib.InvalidCondition.MissingRequiredParam ) )
assert( condition:GetLevel() == otlib.InvalidCondition.DeniedLevel.Access )
assert( condition:GetParameterNum() == 1 )

has_access, condition = otlib.CheckAccess( "123", slap, 51 )
assert( not has_access )
assert( condition:IsA( otlib.InvalidCondition.TooHigh ) )
assert( condition:GetLevel() == otlib.InvalidCondition.DeniedLevel.User )
assert( condition:GetParameterNum() == 1 )

has_access, condition = otlib.CheckAccess( "123", slap, -1 )
assert( not has_access )
assert( condition:IsA( otlib.InvalidCondition.TooLow ) )
assert( condition:GetLevel() == otlib.InvalidCondition.DeniedLevel.Access )
assert( condition:GetParameterNum() == 1 )

has_access, condition = otlib.CheckAccess( "321", slap, 6 )
assert( not has_access )
assert( condition:IsA( otlib.InvalidCondition.AccessDenied ) )
assert( condition:GetLevel() == otlib.InvalidCondition.DeniedLevel.NoAccess )
assert( condition:GetParameterNum() == nil )
