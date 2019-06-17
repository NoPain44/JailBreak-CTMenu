#if defined _ctmenu_included_
  #endinput
#endif
#define _ctmenu_included_

stock SetClientGod( int client, int mode )
{
	SetEntProp( client, Prop_Data, "m_takedamage", mode ? 0 : 2, 1 );
}
stock bool GetClientGod( int client )
{
	int value = GetEntProp( client, Prop_Data, "m_takedamage", 1 );
	return value ? false : true;
}
stock bool IsPlayerStuck( int client )
{
	float vecMin[ 3 ], vecMax[ 3 ], vecOrigin[ 3 ];
	GetClientMins( client, vecMin );
	GetClientMaxs( client, vecMax );
	GetClientAbsOrigin( client, vecOrigin );
	TR_TraceHullFilter( vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayDontHitPlayerAndWorld );
	return TR_DidHit( );
}
stock bool TraceRayDontHitPlayerAndWorld( int entityhit, int mask ) 
{
    return entityhit > MaxClients;
}
stock PlayerBury( int client )
{
	float origin[ 3 ];
	GetClientAbsOrigin( client, origin );
	origin[ 2 ] -= 30.0
	TeleportEntity( client, origin, NULL_VECTOR, NULL_VECTOR );
}
stock PlayerUnbury( int client )
{
	float origin[ 3 ];
	GetClientAbsOrigin( client, origin );
	origin[ 2 ] += 30.0
	TeleportEntity( client, origin, NULL_VECTOR, NULL_VECTOR );
}
stock bool IsValidClient( int client )
{
	if( 1 <= client <= MaxClients )
	{
		return true;
	}
	else
	{
		return false;
	}
}