#include < sourcemod >
#include < smlib >
#include < sdkhooks >
#include < sdktools >
#include < multicolors >
#include < cstrike >
#include < ctmenu >
#include < autoexecconfig >
#include < menu-stocks >

int g_freeze[ MAXPLAYERS + 1 ], g_menumode[ MAXPLAYERS + 1 ], g_countdown, g_game;
char FREEZE_SOUND[ ] = "physics/glass/glass_impact_bullet4.wav";
bool blockweapon, lastchance;
float g_Min = 300.0;
Handle g_DoorList;
public Plugin myinfo =
{
	name = "Ctmenu",
	author = "Anil Can",
	description = "JB Serverlerde Ctye Ozel Menu",
	version = "1.0",
	url = "https://forum.webdiyo.com/"
}
ConVar mp_friendlyfire, sv_infinite_ammo, sv_gravity, game_hidefirst, game_hidelast, weapon_accuracy_nospread, weapon_recoil_cooldown, 
weapon_recoil_decay1_exp, weapon_recoil_decay2_exp, weapon_recoil_decay2_lin, weapon_recoil_scale, weapon_recoil_suppression_shots, 
weapon_recoil_view_punch_extra, mp_teammates_are_enemies, sv_airaccelerate, sm_parachute_enabled;
public void OnPluginStart( )
{
	RegConsoleCmd( "sm_ctmenu", Ctmenu );
	
	HookEvent( "player_spawn", Event_PlayerSpawn );
	HookEvent( "round_start", Event_RoundStart );
	AddNormalSoundHook( FootstepCheck );
	
	AutoExecConfig_SetFile( "ctmenu" );
	AutoExecConfig_SetCreateFile( true );
	
	mp_friendlyfire = FindConVar( "mp_friendlyfire" );
	sv_infinite_ammo = FindConVar( "sv_infinite_ammo" );
	sv_gravity = FindConVar( "sv_gravity" );
	weapon_accuracy_nospread = FindConVar( "weapon_accuracy_nospread" );
	weapon_recoil_cooldown = FindConVar( "weapon_recoil_cooldown" );
	weapon_recoil_decay1_exp = FindConVar( "weapon_recoil_decay1_exp" );
	weapon_recoil_decay2_exp = FindConVar( "weapon_recoil_decay2_exp" );
	weapon_recoil_decay2_lin = FindConVar( "weapon_recoil_decay2_lin"  );
	weapon_recoil_scale = FindConVar( "weapon_recoil_scale" );
	weapon_recoil_suppression_shots = FindConVar( "weapon_recoil_suppression_shots" );
	weapon_recoil_view_punch_extra = FindConVar( "weapon_recoil_view_punch_extra" );
	sv_airaccelerate = FindConVar( "sv_airaccelerate" ); 
	mp_teammates_are_enemies = FindConVar( "mp_teammates_are_enemies" );
	sm_parachute_enabled = FindConVar( "sm_parachute_enabled" );
	
	game_hidefirst = AutoExecConfig_CreateConVar( "game_hidefirst", "60", "Saklanbacta mahkumların kac saniye sonra gomulecegini ayarlar" );
	game_hidelast = AutoExecConfig_CreateConVar( "game_hidelast", "20", "Saklanbacta eger komutcu 2. sans verirse mahkumların kac saniye sonra gomulecegini ayarlar" );
	AutoExecConfig_ExecuteFile( );
	AutoExecConfig_CleanFile( );
	g_DoorList = CreateArray( );
}

public Action FootstepCheck( int clients[ 64 ], int &numClients, char sample[ PLATFORM_MAX_PATH ], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags )
{
	if( 0 < entity <= MaxClients )
	{
		if( StrContains( sample, "footsteps") != -1 )
		{	
			return g_freeze[ entity ] ? Plugin_Handled : Plugin_Continue;
		}
	}
	return Plugin_Continue;
}  
public void OnMapStart( )
{
	PrecacheSound( FREEZE_SOUND, true );
	CacheDoors( );
}
public void OnMapEnd( )
{
	ClearArray( g_DoorList );
}

public Action Event_PlayerSpawn( Event event, const char[ ] name, bool dontbroadcast )
{
	int client = GetClientOfUserId( event.GetInt( "userid" ) );
	if( blockweapon )
	{
		SDKHook( client, SDKHook_WeaponCanUse, WeaponUse );
	}
	else
	{
		SDKUnhook( client, SDKHook_WeaponCanUse, WeaponUse );
	}
}
public Action Event_RoundStart( Event event, const char[ ] name, bool dontbroadcast )
{
	SettingsReset( );
}

public Action Ctmenu( int client, int args )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		if( g_game == 5 )
		{
			BuryDies_Menu( client );
			return Plugin_Handled;
		}
		char szgod[ 32 ];
		Format( szgod, sizeof( szgod ), "God Mod %s", GetClientGod( client ) ? "Kapa" : "Aç" );
		Menu menu = new Menu( Ctmenu_Handler );
		menu.SetTitle( "JailBreak Ctmenu" );
		menu.AddItem( "God", szgod );
		menu.AddItem( "Ayar", "Ayar Menuleri" );
		menu.AddItem( "Menuler", "Menüler" );
		menu.AddItem( "OyunMenu", "Oyun Menüsü" );
		menu.AddItem( "Reset", "Ayarları Sıfırla" );
		menu.AddItem( "Hucre", "Hücre Kapısı" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
	return Plugin_Handled;
}
public int Ctmenu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				if( GetClientGod( param1 ) )
				{
					for( int i = 1; i <= MaxClients; i++ )
					{
						if( IsClientConnected( i ) && GetClientTeam( i ) == 3 && IsPlayerAlive( i ) )
						{
							SetClientGod( i, 0 ); 
						}
					}
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan CT takımının {darkblue}[ {darkred}GOD MODUNU {darkblue}] {green}kapadı", param1 );
					Ctmenu( param1, 2 );
				}
				else
				{
					for( int i = 1; i <= MaxClients; i++ )
					{
						if( IsClientConnected( i ) && GetClientTeam( i ) == 3 && IsPlayerAlive( i ) )
						{
							SetClientGod( i, 1 ); 
						}
					}
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan CT takımına {darkblue}[ {darkred}GOD MOD {darkblue}] {green}açtı", param1 );
					Ctmenu( param1, 2 );
				}
			}
			case 1 :
			{
				CTSettings( param1 );
			}
			case 2 :
			{
				CTMenuler( param1 );
			}
			case 3 :
			{
				Game_Menu( param1 );
			}
			case 4 :
			{
				SettingsReset( );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan ayarları sıfırladı.", param1 );
				Ctmenu( param1, 2 );
			}
			case 5 :
			{
				Cell_Menu( param1 );
			}
		}
	}
	
}
public Action Cell_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( Cell_Menu_Handler );
		menu.SetTitle( "Hücre Kapısı" );
		menu.AddItem( "open", "Hücre Kapısını Aç" );
		menu.AddItem( "close", "Hücre Kapısını Kapa" );
		menu.AddItem( "amenu", "Ana Menüye Dön" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int Cell_Menu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				for( int i = 0; i < GetArraySize( g_DoorList ); i++ )
				{
					int door = GetArrayCell( g_DoorList, i );
			
					AcceptEntityInput( door, "Open" );
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan hücre kapısını açtı", param1 );
				Cell_Menu( param1 );
			}
			case 1:
			{
				for( int i = 0; i < GetArraySize( g_DoorList ); i++ )
				{
					int door = GetArrayCell( g_DoorList, i );
			
					AcceptEntityInput( door, "Close" );
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan hücre kapısını kapadı", param1 );
				Cell_Menu( param1 );
			}
			case 2:
			{
				Ctmenu( param1, 2 );
			}
		}
	}
}
public Action CTSettings( client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( CTSettings_Handler );
		menu.SetTitle( "CTMenu Ayarlar Menusu" );
		AddMenuItemFormat( menu, "0", _, "FF %s", GetConVarInt( mp_friendlyfire ) ? "Kapa" : "Aç" );
		menu.AddItem( "1", "Mahkumların Silahlarına El Koy" );
		AddMenuItemFormat( menu, "2", _, "Silah Almayı %s", blockweapon ? "Aç" : "Yasakla" );
		AddMenuItemFormat( menu, "3", _, "Unammo %s", GetConVarInt( sv_infinite_ammo ) ? "Kapa" : "Aç" );
		AddMenuItemFormat( menu, "4", _, "Mermi Sekmemeyi %s", GetConVarInt( weapon_accuracy_nospread ) ? "Kapa" : "Aç" );
		if( sm_parachute_enabled != null )
		{
			AddMenuItemFormat( menu, "5", _, "Paraşütü %s", GetConVarInt( sm_parachute_enabled ) ? "Kapa" : "Aç" );
		}
		menu.AddItem( "6", "Gravity" );
		menu.AddItem( "7", "Ana Menüye Dön" );
		SetMenuPagination( menu, MENU_NO_PAGINATION );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int CTSettings_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int secti = StringToInt( info );
		switch( secti )
		{
			case 0:
			{
				FFOnOff( GetConVarInt( mp_friendlyfire ) ? 0 : 1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}FF {darkblue}] {green}%s", param1, GetConVarInt( mp_friendlyfire ) ? "açtı" : "kapadı" );
				CTSettings( param1 );
			}
			case 1:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsClientConnected( i ) && GetClientTeam( i ) == 2 )
					{
						Client_RemoveAllWeapons( i, "weapon_knife" );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan mahkumların silahlarını aldı.", param1 );
				CTSettings( param1 );
			}
			case 2:
			{
				if( blockweapon )
				{
					for( int i = 1; i <= MaxClients; i++ )
					{
						if( IsClientConnected( i ) )
						{
							SDKUnhook( i, SDKHook_WeaponCanUse, WeaponUse );
						}
					}
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}YERDEN {darkblue}] {green}veya {darkblue}[ {darkred}E {darkblue}] {green}tuşuna basarak silah almayı açtı.", param1 );
					blockweapon = false;
					CTSettings( param1 );
				}
				else
				{
					for( int i = 1; i <= MaxClients; i++ )
					{
						if( IsClientConnected( i ) )
						{
							SDKHook( i, SDKHook_WeaponCanUse, WeaponUse );
						}
					}
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}YERDEN {darkblue}] {green}veya {darkblue}[ {darkred}E {darkblue}] {green}tuşuna basarak silah almayı yasakladı.", param1 );
					blockweapon = true;
					CTSettings( param1 );
				}
			}
			case 3:
			{
				SetConVarInt( sv_infinite_ammo, GetConVarInt( sv_infinite_ammo ) ? 0 : 1 )
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}UNAMMO {darkblue}] {green}%s", param1,GetConVarInt( sv_infinite_ammo ) ? "açtı" : "kapadı" );
				CTSettings( param1 );
			}
			case 4:
			{
				NoSpreadOnOff( GetConVarInt( weapon_accuracy_nospread ) ? 0 : 1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}MERMİ SEKMEMEYİ {darkblue}] {green}%s", param1, GetConVarInt( weapon_accuracy_nospread ) ? "açtı" : "kapadı" );
				CTSettings( param1 );
			}
			case 5:
			{
				if( sm_parachute_enabled != null )
				{
					SetConVarInt( sm_parachute_enabled, ( GetConVarInt( sm_parachute_enabled ) ) ? 0 : 1 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}PARAŞÜTÜ {darkblue}] {green}%s", param1, GetConVarInt( sm_parachute_enabled ) ? "açtı" : "kapadı" );
					CTSettings( param1 );
				}
			}
			case 6:
			{
				CTGravity( param1 );
			}
			case 7:
			{
				Ctmenu( param1, 2 );
			}
		}
	}
}
public CTGravity( client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( CTGravity_Handler );
		menu.SetTitle( "Gravity Ayar Menusu" );
		menu.AddItem( "100", "200 Gravity" );
		menu.AddItem( "200", "300 Gravity" );
		menu.AddItem( "400", "400 Gravity" );
		menu.AddItem( "500", "500 Gravity" );
		menu.AddItem( "600", "600 Gravity" );
		menu.AddItem( "800", "800 Gravity" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int CTGravity_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int gravity_value = StringToInt( info );
		SetConVarInt( sv_gravity, gravity_value );
		CTGravity( param1 );
		CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan gravity ayarını {darkblue}[ {darkred}%i {darkblue}] {green}yaptı.", param1, gravity_value );
	}
}
public Action CTMenuler( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( CTMenuler_Handler );
		menu.SetTitle( "Menuler" );
		menu.AddItem( "Freeze", "Dondurma Menüsü" );
		menu.AddItem( "Bury", "Gömme Menüsü" );
		menu.AddItem( "Teleport", "Teleport Menüsü" );
		menu.AddItem( "Revive", "RevMenü" );
		menu.AddItem( "amenu", "Ana Menüye Dön" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int CTMenuler_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				Freeze_Menu( param1 );
			}
			case 1:
			{
				Bury_Menu( param1 );
			}
			case 2:
			{
				Teleport_Menu( param1 );
			}
			case 3:
			{
				Rev_Menu( param1 );
			}
			case 4:
			{
				Ctmenu( param1, 2 );
			}
		}
	}
}
public Action Freeze_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( Freeze_Menu_Handler );
		menu.SetTitle( "Dondurma Menüsü" );
		menu.AddItem( "allfreeze", "Tüm Mahkumlari Dondur" );
		menu.AddItem( "allunfreeze", "Tüm Mahkumlari Çöz" );
		menu.AddItem( "listfreeze", "Listeden Sectiğin Mahkumları Dondur" );
		menu.AddItem( "listunfreeze", "Listeden Sectiğin Mahkumları Çöz" );
		menu.AddItem( "aimfreeze", "Aimin Önündeki Mahkumları Dondur" );
		menu.AddItem( "aimunfreeze", "Aimin Önündeki Mahkumları Çöz" );
		menu.AddItem( "amenu", "Bir Önceki Menüye Dön" );
		SetMenuPagination( menu, MENU_NO_PAGINATION );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int Freeze_Menu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
					{
						ListMenuMode( param1, i, 1 );
					}
				}
				Freeze_Menu( param1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan tüm mahkumları {darkblue}[ {darkred}DONDURDU {darkblue}]", param1 );
			}
			case 1:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
					{
						ListMenuMode( param1, i, 0 );
					}
				}
				Freeze_Menu( param1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan tüm mahkumları {darkblue}[ {darkred}ÇÖZDÜ {darkblue}]", param1 );
			}
			case 2:
			{
				g_menumode[ param1 ] = 1;
				ListPlayer( param1 );
			}
			case 3:
			{
				g_menumode[ param1 ] = 0;
				ListPlayer( param1 );
			}
			case 4:
			{
				int target = GetClientAimTarget( param1 );
				if( target == -1 && !IsValidClient( target ) )
				{
					CReplyToCommand( param1, "{green}Oyuncu bulunamadi" );
				}
				else
				{
					ListMenuMode( param1, target, 1 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}DONDURDU. {darkblue}]", param1, target );
				}
				Freeze_Menu( param1 );
			}
			case 5:
			{
				int target = GetClientAimTarget( param1 );
				if( target == -1 && !IsValidClient( target ) )
				{
					CReplyToCommand( param1, "{green}Oyuncu bulunamadi" );
				}
				else
				{
					ListMenuMode( param1, target, 0 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}ÇÖZDÜ {darkblue}]", param1, target );
				}
				Freeze_Menu( param1 );
			}
			case 6:
			{
				CTMenuler( param1 );
			}
		}
	}
}
public Action Bury_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( Bury_Menu_Handler );
		menu.SetTitle( "Gömme Menüsü" );
		menu.AddItem( "allbury", "Gömülmeyen Tüm Mahkumları Göm" );
		menu.AddItem( "allunbury", "Gömülen Tüm Mahkumları Çıkar" );
		menu.AddItem( "listbury", "Listeden Gömülmeyen Mahkumu Göm" );
		menu.AddItem( "listunbury", "Listeden Gömülen Mahkumları Çıkar" );
		menu.AddItem( "aimbury", "Aimin Önündeki Mahkumları Göm" );
		menu.AddItem( "aimunbury", "Aimin Önündeki Mahkumları Çıkar" );
		SetMenuPagination( menu, MENU_NO_PAGINATION );
		menu.AddItem( "amenu", "Bir Önceki Menüye Dön" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int Bury_Menu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 && !IsPlayerStuck( i ) )
					{
						ListMenuMode( param1, i, 2 );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan gömülmeyen tüm mahkumları {darkblue}[ {darkred}GÖMDÜ {darkblue}]", param1 );
				Bury_Menu( param1 );
			}
			case 1:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 && IsPlayerStuck( i ) )
					{
						ListMenuMode( param1, i, 3 );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan gömülen tüm mahkumları {darkblue}[ {darkred}ÇIKARDI {darkblue}]", param1 );
				Bury_Menu( param1 );
			}
			case 2:
			{
				g_menumode[ param1 ] = 2;
				ListPlayer( param1 );
			}
			case 3:
			{
				g_menumode[ param1 ] = 3;
				ListPlayer( param1 );
			}
			case 4:
			{
				int target = GetClientAimTarget( param1 );
				if( target == -1 && !IsValidClient( target ) )
				{
					CReplyToCommand( param1, "{green}Oyuncu bulunamadi" );
					Bury_Menu( param1 );
					return;
				}
				else
				{
					if( IsPlayerStuck( target ) )
					{
						CPrintToChat( param1, "{darkblue}[ {orange}%N {darkblue}] {green}adli oyuncu zaten gömülü", target );
						Bury_Menu( param1 );
						return;
					}
					ListMenuMode( param1, target, 2 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}GÖMDÜ. {darkblue}]", param1, target );
				}
				Bury_Menu( param1 );
			}
			case 5:
			{
				int target = GetClientAimTarget( param1 );
				if( target == -1 && !IsValidClient( target ) )
				{
					CReplyToCommand( param1, "{green}Oyuncu bulunamadi" );
					Bury_Menu( param1 );
					return;
				}
				else
				{
					if( !IsPlayerStuck( target ) )
					{
						CPrintToChat( param1, "{darkblue}[ {orange}%N {darkblue}] {green}adli oyuncu zaten gömülü değil", target );
						Bury_Menu( param1 );
						return;
					}
					ListMenuMode( param1, target, 3 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}ÇIKARDI. {darkblue}]", param1, target );
				}
				Bury_Menu( param1 );
			}
			case 6:
			{
				CTMenuler( param1 );
			}
		}
	}
}
public Action Teleport_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( Teleport_Menu_Handler );
		menu.SetTitle( "Teleport Menüsü" );
		menu.AddItem( "alltel", "Tüm Mahkumları Yanına Çek" );
		menu.AddItem( "listtel", "Listeden Sectiğin Mahkumları Yanına Çek" );
		menu.AddItem( "amenu", "Bir Önceki Menüye Dön" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int Teleport_Menu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
					{
						ListMenuMode( param1, i, 4 );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan tüm mahkumlari yanına {darkblue}[ {darkred}ÇEKTİ {darkblue}]", param1 );
			}
			case 1:
			{
				g_menumode[ param1 ] = 4;
				ListPlayer( param1 );
			}
			case 2:
			{
				CTMenuler( param1 );
			}
		}
	}
}
public Action Rev_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( Rev_Menu_Handler );
		menu.SetTitle( "Revleme Menüsü" );
		menu.AddItem( "allrevivet", "Ölmüş Tüm Mahkumlari Canlandır" );
		menu.AddItem( "allrevivect", "Ölmüş Tüm Gardiyanlari Canlandır" );
		menu.AddItem( "allrevive", "Listeden Sectiğin Oyuncuları Canlandır" );
		menu.AddItem( "amenu", "Bir Önceki Menüye Dön" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int Rev_Menu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && !IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
					{
						CS_RespawnPlayer( i );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan ölmüş olan tüm mahkumları {darkblue}[ {darkred}CANLANDIRDI {darkblue}]", param1 );
				Rev_Menu( param1 );
			}
			case 1:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && !IsPlayerAlive( i ) && GetClientTeam( i ) == 3 )
					{
						CS_RespawnPlayer( i );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan ölmüş olan tüm gardiyanlari {darkblue}[ {darkred}CANLANDIRDI {darkblue}]", param1 );
				Rev_Menu( param1 );
			}
			case 2:
			{
				g_menumode[ param1 ] = 5;
				ListPlayer( param1 );
			}
			case 3:
			{
				CTMenuler( param1 );
			}
		}
	}
}
public Action ListPlayer( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( ListPlayer_Handler );
		menu.SetTitle( "Oyuncu Sec" );
		char name[ MAX_NAME_LENGTH ], list[ 32 ];
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( g_menumode[ client ] != 5 )
			{
				if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
				{
					GetClientName( i, name, sizeof( name ) );
					Format( list, sizeof( list ), "%i", i );
					menu.AddItem( list, name );
				}
			}
			if( g_menumode[ client ] == 5 )
			{
				if( IsClientConnected( i ) && !IsPlayerAlive( i ) )
				{
					GetClientName( i, name, sizeof( name ) );
					Format( list, sizeof( list ), "%i", i );
					menu.AddItem( list, name );
				}
			}
		}
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int ListPlayer_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int target = StringToInt( info );
		if( target != 0 )
		{
			switch( g_menumode[ param1 ] )
			{
				case 0:
				{
					ListMenuMode( param1, target, 0 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}ÇÖZDÜ {darkblue}]", param1, target );
					ListPlayer( param1 );
				}
				case 1:
				{
					ListMenuMode( param1, target, 1 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}DONDURDU {darkblue}]", param1, target );
					ListPlayer( param1 );
				}
				case 2:
				{
					if( IsPlayerStuck( target ) )
					{
						CPrintToChat( param1, "{darkblue}[ {orange}%N {darkblue}] {green}adli oyuncu zaten gömülü", target );
						ListPlayer( param1 );
						return;
					}
					ListMenuMode( param1, target, 2 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}GÖMDÜ {darkblue}]", param1, target );
					ListPlayer( param1 );
				}
				case 3:
				{
					if( !IsPlayerStuck( target ) )
					{
						CPrintToChat( param1, "{darkblue}[ {orange}%N {darkblue}] {green}adli oyuncu zaten gömülü değil", target );
						ListPlayer( param1 );
						return;
					}
					ListMenuMode( param1, target, 3 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu {darkblue}[ {darkred}ÇIKARDI {darkblue}]", param1, target );
					ListPlayer( param1 );
				}
				case 4:
				{
					ListMenuMode( param1, target, 4 );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı mahkumu yanına {darkblue}[ {darkred}ÇEKTİ {darkblue}]", param1, target );
					ListPlayer( param1 );
				}
				case 5:
				{
					CS_RespawnPlayer( target );
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}%N {darkblue}] {green}adlı oyuncuyu {darkblue}[ {darkred}CANLANDIRDI {darkblue}]", param1, target );
					ListPlayer( param1 );
				}
			}
		}
	}
}
public Action ListMenuMode( int owner, int client, int mode )
{
	switch( mode )
	{
		case 0:
		{
			float vec[ 3 ];
			GetClientEyePosition( client , vec );
			EmitAmbientSound( FREEZE_SOUND, vec,client, SNDLEVEL_RAIDSIREN );
			g_freeze[ client ] = 0;
			SetEntityMoveType( client, MOVETYPE_WALK );
			SetEntityRenderMode( client, RENDER_NORMAL );
			SetEntityRenderColor( client, 255, 255, 255, 255 );
		}
		case 1:
		{
			float vec[ 3 ];
			GetClientEyePosition( client , vec );
			EmitAmbientSound( FREEZE_SOUND, vec,client, SNDLEVEL_RAIDSIREN );
			g_freeze[ client ] = 1;
			SetEntityRenderMode( client, RENDER_GLOW );
			SetEntityRenderColor( client, 0, 255, 255, 255 )
			SetEntityMoveType( client, MOVETYPE_NONE );
		}
		case 2:
		{
			PlayerBury( client );
		}
		case 3:
		{
			PlayerUnbury( client );
		}
		case 4:
		{
			float origin[ 3 ];
			GetClientAbsOrigin( owner, origin );
			origin[ 0 ] += 40.0;
			TeleportEntity( client, origin, NULL_VECTOR, NULL_VECTOR );
		}
	}
}
public Action Game_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( Game_Menu_Handler );
		menu.SetTitle( "Oyun Menüsü" );
		AddMenuItemFormat( menu, "0", _, "Saklambaç ( Mahkumlar %i saniye Sonra Gömülür )", game_hidefirst.IntValue );
		menu.AddItem( "1", "Kuş Avı" );
		menu.AddItem( "2", "Çatışma" );
		menu.AddItem( "3", "FF Oyunları" );
		menu.AddItem( "4", "Zombi" );
		menu.AddItem( "5", "Gömülen Ölür" );
		if( sm_parachute_enabled != null )
		{
			menu.AddItem( "6", "Kamikaze" );
		}
		menu.AddItem( "7", "Körebe" );
		menu.AddItem( "8", "Uçan Pipi" );
		menu.AddItem( "9", "Hayalet" ); 
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int Game_Menu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int secilen = StringToInt( info );
		g_game = param2;
		switch( secilen )
		{
			case 0:
			{
				CTGodVer( );
				lastchance = false;
				g_countdown = game_hidefirst.IntValue;
				PrintHintTextToAll( "<b><font color='#ff0000'>Mahkumların gömülmesine %i saniye kaldi.</font></b>", g_countdown );
				CreateTimer( 1.0, CountDown, _, TIMER_REPEAT );
				CreateTimer( game_hidefirst.FloatValue + 1.0, NeYapilsin, GetClientUserId( param1 ) );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}SAKLANBAÇ {darkblue}] {green}oyununu başlatti", param1 );
			}
			case 1:
			{
				CTGodVer( );
				SetConVarInt( sv_infinite_ammo, 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) )
					{
						if( GetClientTeam( i ) == 2 )
						{
							SetEntityRenderMode( i, RENDER_GLOW );
							SetEntityRenderColor( i, 255, 0, 0, 255 );
						}
						if( GetClientTeam( i ) == 3 )
						{
							Client_RemoveAllWeapons( i, "weapon_knife" );
							GivePlayerItem( i, "weapon_ssg08" );
						}
					}
				}
				AskNoSpread( param1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}KUŞ AVI {darkblue}] {green}oyununu başlatti", param1 );
			}
			case 2:
			{
				CTHP( param1 );
				SetConVarInt( sv_infinite_ammo, 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
					{
						ChooseWeapon( i );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}ÇATIŞMA {darkblue}] {green}oyununu başlatti", param1 );
			}
			case 3:
			{
				FF_Menu( param1 );
			}
			case 4:
			{
				CTHP( param1 );
				SetConVarInt( sv_infinite_ammo, 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) )
					{
						if( GetClientTeam( i ) == 3 )
						{
							SetEntityRenderMode( i, RENDER_GLOW );
							SetEntityRenderColor( i, 0, 255, 0, 255 );
							Client_RemoveAllWeapons( i, "weapon_knife" );
						}
						if( GetClientTeam( i ) == 2 )
						{
							Client_RemoveAllWeapons( i, "weapon_knife" );
							GivePlayerItem( i, "weapon_negev" );
						}
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}ZOMBİ {darkblue}] {green}oyununu başlatti", param1 );
			}
			case 5:
			{
				CTGravity( param1 );
				CreateTimer( 4.0, BuryDies, GetClientUserId( param1 ) );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}GÖMÜLEN ÖLÜR {darkblue}] {green}oyununu başlatti", param1 );
			}
			case 6:
			{
				if( sm_parachute_enabled != null )
				{
					SetConVarInt( sm_parachute_enabled, 0 );
					SetConVarInt( sv_airaccelerate, -50 );
					CTGodVer( );
					for( int i = 1; i <= MaxClients; i++ )
					{
						if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
						{
							SetEntityRenderMode( i, RENDER_GLOW );
							SetEntityRenderColor( i, 0, 0, 255, 255 )
						}
					}
					CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}KAMİKAZE {darkblue}] {green}oyununu başlatti", param1 );
				}
				
			}
			case 7:
			{
				SetConVarInt( sv_infinite_ammo, 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 3 )
					{
						SDKHook( i, SDKHook_SetTransmit, OnSetTransmit );
						SetEntityHealth( i, 300 );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}KÖREBE {darkblue}] {green}oyununu başlatti", param1 );
				
			}
			case 8:
			{
				SetConVarInt( sv_infinite_ammo, 1 );
				CTGodVer( );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 )
					{
						SetEntityRenderMode( i, RENDER_GLOW );
						SetEntityRenderColor( i, 0, 255, 255, 255 )
					}
				}
				CTGravity( param1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}UÇAN PİPİ {darkblue}] {green}oyununu başlatti", param1 );
			}
			case 9:
			{
				SetConVarInt( sv_infinite_ammo, 1 );
				CTHP( param1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i )  )
					{
						if( GetClientTeam( i ) == 3 ) 
						{
							SetEntityRenderMode( i, RENDER_GLOW );
							SetEntityRenderColor( i, 255, 255, 0, 255 );
							Client_RemoveAllWeapons( i, "weapon_knife" );
							SetEntityMoveType( i, MOVETYPE_NOCLIP );
						}
						if( GetClientTeam( i ) == 2 ) 
						{
							Client_RemoveAllWeapons( i, "weapon_knife" );
							GivePlayerItem( i, "weapon_negev" );
						}
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {orange}HAYALET {darkblue}] {green}oyununu başlatti", param1 );
				
			}
		}
	}
}

public Action CountDown( Handle timer )
{
	g_countdown -= 1;
	if( g_countdown == 0 )
	{
		DoAction( );
		return Plugin_Stop;
	}
	PrintHintTextToAll( "<b><font color='#ff0000'>Mahkumların gömülmesine %i saniye kaldi.</font></b>", g_countdown );
	return Plugin_Continue;
}
void DoAction( )
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 && !IsPlayerStuck( i ) )
		{
			PlayerBury( i );
		}
		if( IsClientConnected( i ) && !IsPlayerStuck( i ) && lastchance && GetClientTeam( i ) == 2 )
		{
			ForcePlayerSuicide( i );
			CPrintToChat( i,"{green}Verilen ek süreye rağmen gömülmediğin için öldürüldün");
		}
	}
	if( lastchance )
	{
		lastchance = false;
	}
	CPrintToChatAll( "{green}Geri sayım sona erdi.Gömülmeyen tüm mahkumlar {darkblue}[ {darkred}GÖMÜLDÜ {darkblue}]" );
}
public Action NeYapilsin( Handle timer, int userid )
{
	int nonstuck = 0;
	int client = GetClientOfUserId( userid );
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 && !IsPlayerStuck( i ) )
		{
			nonstuck += 1;
		}
	}
	if( nonstuck == 0 )
	{
		CPrintToChatAll( "{green}Gömülmeyen mahkum yoktur." );
	}
	else
	{
		if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
		{
			Menu menu = new Menu( NeYapilsin_Handler );
			menu.SetTitle( "Gömülmeyen Mahkumlara Ne Olsun ?" );
			AddMenuItemFormat( menu, "1", _, "%i Saniye Sonra Mahkumlar Gömülür", game_hidelast.IntValue );
			menu.AddItem( "2", "Gömülmeyen Mahkumlari Slayla" );
			menu.Display( client, MENU_TIME_FOREVER );
		}
	}
}
public int NeYapilsin_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				lastchance = true;
				g_countdown = game_hidelast.IntValue;
				PrintHintTextToAll( "<b><font color='#ff0000'>Mahkumların gömülmesine %i saniye kaldi.</font></b>", g_countdown );
				CreateTimer( 1.0, CountDown, _, TIMER_REPEAT );
			}
			case 1:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 2 && !IsPlayerStuck( i ) )
					{
						ForcePlayerSuicide( i );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan gömülmeyen mahkumları {darkblue}[ {darkred}SLAYLADI {darkblue}]", param1 );
			}
		}
	}
}
public AskNoSpread( client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( AskNoSpread_Handler );
		menu.SetTitle( "Mermi Sekmeme( NoSpread ) ?" );
		menu.AddItem( "on", "Açık" );
		menu.AddItem( "off", "Kapalı" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int AskNoSpread_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				NoSpreadOnOff( 1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}mermi sekmeme( nospread ) {darkblue}] {green}açtı.", param1 );
			}
			case 1:
			{
				NoSpreadOnOff( 0 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}mermi sekmeme( nospread ) {darkblue}] {green}kapadı.", param1 );
			}
		}
		CTGravity( param1 );
	}
}
public CTHP( client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( CTHP_Handler );
		menu.SetTitle( "Gardiyan HP Belirle" );
		AddMenuItemFormat( menu, "500", _, "%i HP", g_game == 4 ? 500*20 : 500 );
		AddMenuItemFormat( menu, "1000", _, "%i HP", g_game == 4 ? 1000*20 : 1000 );
		AddMenuItemFormat( menu, "1500", _, "%i HP", g_game == 4 ? 1500*20 : 1500 );
		AddMenuItemFormat( menu, "2000", _, "%i HP", g_game == 4 ? 2000*20 : 2000 );
		AddMenuItemFormat( menu, "2500", _, "%i HP", g_game == 4 ? 2500*20 : 2500 );
		AddMenuItemFormat( menu, "3000", _, "%i HP", g_game == 4 ? 3000*20 : 3000 );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int CTHP_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int hp_value = StringToInt( info );
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientConnected( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 3 )
			{
				SetEntityHealth( i, g_game == 4 ? hp_value*20 : hp_value );
			}
		}
		CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan CT takımının canının {darkblue}[ {darkred}%i {darkblue}] {green}yaptı.", param1, g_game == 4 ? hp_value*10 : hp_value );
	}
}
public ChooseWeapon( client )
{
	Menu menu = new Menu( ChooseWeapon_Handler );
	menu.SetTitle( "Silah Seç" );
	menu.AddItem( "weapon_ak47", "AK47 + DEAGLE" );
	menu.AddItem( "weapon_awp", "AWP + DEAGLE" );
	menu.AddItem( "weapon_aug", "AUG + DEAGLE" );
	menu.AddItem( "weapon_m4a1", "M4A1 + DEAGLE" );
	menu.AddItem( "weapon_m4a1_silencer", "M4A1-S + DEAGLE" );
	menu.AddItem( "weapon_sg556", "SG556 + DEAGLE" );
	menu.Display( client, MENU_TIME_FOREVER );
}
public int ChooseWeapon_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		GivePlayerItem( param1, info );
		GivePlayerItem( param1, "weapon_deagle" );
	}
}
public Action FF_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( FF_Menu_Handler );
		menu.SetTitle( "FF Menüsü" );
		menu.AddItem( "1", "Düz FF" );
		menu.AddItem( "2", "AK47 FF" );
		menu.AddItem( "3", "AWP FF" );
		menu.AddItem( "4", "Nova FF" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int FF_Menu_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				FFOnOff( 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) &&  GetClientTeam( i ) == 2 )
					{
						SetEntityHealth( i, 100 );
						Client_RemoveAllWeapons( i, "weapon_knife" );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}DUZ FF {darkblue}] {green}başlattı.", param1 );
			}
			case 1:
			{
				FFOnOff( 1 );
				SetConVarInt( sv_infinite_ammo, 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) &&  GetClientTeam( i ) == 2 )
					{
						SetEntityHealth( i, 300 );
						Client_RemoveAllWeapons( i, "weapon_knife" );
						GivePlayerItem( i, "weapon_ak47" );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}AK47 FF {darkblue}] {green}başlattı.", param1 );
			}
			case 2:
			{
				FFOnOff( 1 );
				SetConVarInt( sv_infinite_ammo, 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) &&  GetClientTeam( i ) == 2 )
					{
						SetEntityHealth( i, 250 );
						Client_RemoveAllWeapons( i, "weapon_knife" );
						GivePlayerItem( i, "weapon_awp" );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}AWP FF {darkblue}] {green}başlattı.", param1 );
			}
			case 3:
			{
				FFOnOff( 1 );
				SetConVarInt( sv_infinite_ammo, 1 );
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) &&  GetClientTeam( i ) == 2 )
					{
						SetEntityHealth( i, 200 );
						Client_RemoveAllWeapons( i, "weapon_knife" );
						GivePlayerItem( i, "weapon_nova" );
					}
				}
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan {darkblue}[ {darkred}NOVA FF {darkblue}] {green}başlattı.", param1 );
			}
		}
	}
}
public Action BuryDies( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	BuryDies_Menu( client );
}
public Action BuryDies_Menu( int client )
{
	if( IsClientConnected( client ) && GetClientTeam( client ) == 3 )
	{
		Menu menu = new Menu( BuryDies_Handler );
		menu.SetTitle( "Gömülmeyen Ölür Oyunu" );
		menu.AddItem( "1", "Mahkumları Göm" );
		menu.AddItem( "2", "Gömülen Mahkumları Öldür" );
		menu.AddItem( "3", "Oyunu Bitir ve Ayarları Sıfırla" );
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int BuryDies_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		switch( param2 )
		{
			case 0:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) &&  GetClientTeam( i ) == 2 && !IsPlayerStuck( i ) )
					{
						PlayerBury( i );
					}
				}
				BuryDies_Menu( param1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan mahkumları {darkblue}[ {darkred}GÖMDÜ {darkblue}]", param1 );
			}
			case 1:
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientConnected( i ) && IsPlayerAlive( i ) &&  GetClientTeam( i ) == 2 && IsPlayerStuck( i ) )
					{
						ForcePlayerSuicide( i );
					}
				}
				BuryDies_Menu( param1 );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan gömülen mahkumları {darkblue}[ {darkred}ÖLDÜRDÜ {darkblue}]", param1 );
			}
			case 2:
			{
				SettingsReset( );
				CPrintToChatAll( "{darkblue}[ {orange}%N {darkblue}] {green}adli gardiyan oyunu bitirdi.", param1 );
			}
		}
	}
}
				
public Action WeaponUse( int client, int weapon )
{
	return Plugin_Handled;
}
public Action OnSetTransmit( int client, int others )
{
    if( client == others ) 
        return Plugin_Continue; 
    return Plugin_Handled;
} 
void FFOnOff( int mode )
{
	SetConVarInt( mp_teammates_are_enemies, mode == 1 ? 1 : 0 );
	SetConVarInt( mp_friendlyfire, mode == 1 ? 1 : 0 );
}
void CTGodVer( )
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientConnected( i ) && GetClientTeam( i ) == 3 && IsPlayerAlive( i ) )
		{
			SetClientGod( i, 1 );
		}
	}
			
}
void SettingsReset( )
{
	g_game = -1;
	lastchance = false;
	blockweapon = false;
	FFOnOff( 0 );
	NoSpreadOnOff( 0 );
	SetConVarInt( sv_infinite_ammo, 0 );
	SetConVarInt( sv_gravity, 800 );
	SetConVarInt( sv_airaccelerate, 9999 );
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientConnected( i ) )
		{
			g_freeze[ i ] = 0;
			SDKUnhook( i, SDKHook_WeaponCanUse, WeaponUse );
			SDKUnhook( i, SDKHook_SetTransmit, OnSetTransmit );
			if( IsPlayerAlive( i ) )
			{
				SetEntityMoveType( i, MOVETYPE_WALK );
				SetEntityRenderMode( i, RENDER_NORMAL );
				SetEntityRenderColor( i, 255, 255, 255, 255 );
				SetClientGod( i, 0 );
				SetEntityHealth( i, 100 );
				if( GetClientTeam( i ) == 2 )
				{
					Client_RemoveAllWeapons( i, "weapon_knife" );
				}
			}
		}
	}
	if( sm_parachute_enabled != null )
	{
		SetConVarInt( sm_parachute_enabled, 1 );
	}
}
void NoSpreadOnOff( int mode )
{
	if( mode == 1 )
	{
		SetConVarInt( weapon_accuracy_nospread, 1 );
		SetConVarFloat( weapon_recoil_cooldown, 0.0 );
		SetConVarFloat( weapon_recoil_decay1_exp, 9999.0 );
		SetConVarFloat( weapon_recoil_decay2_exp, 9999.0 );
		SetConVarFloat( weapon_recoil_decay2_lin, 9999.0 );
		SetConVarFloat( weapon_recoil_scale, 0.0 );
		SetConVarInt( weapon_recoil_suppression_shots, 500 );
		SetConVarFloat( weapon_recoil_view_punch_extra, 0.0 );
	}
	if( mode == 0 )
	{
		SetConVarInt( weapon_accuracy_nospread, 0 );
		SetConVarFloat( weapon_recoil_cooldown, 0.55 );
		SetConVarFloat( weapon_recoil_decay1_exp, 3.5 );
		SetConVarFloat( weapon_recoil_decay2_exp, 8.0 );
		SetConVarFloat( weapon_recoil_decay2_lin, 18.0 );
		SetConVarFloat( weapon_recoil_scale, 2.0 );
		SetConVarInt( weapon_recoil_suppression_shots, 4 );
		SetConVarFloat( weapon_recoil_view_punch_extra, 0.055 );
		
	}
}
void CacheDoors( )
{
	int ent = -1;
	int door = -1;
	
	while( ( ent = FindEntityByClassname( ent, "info_player_terrorist" ) ) != -1 )
	{
		float prisoner_pos[ 3 ];
		GetEntPropVector( ent, Prop_Data, "m_vecOrigin", prisoner_pos );
		
		while((door = FindEntityByClassname(door, "func_door")) != -1)
		{
			float door_pos[ 3 ];
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if(GetVectorDistance(door_pos, prisoner_pos) <= g_Min)
			{
				g_Min = GetVectorDistance( door_pos, prisoner_pos );
			}
		}
		
		while((door = FindEntityByClassname(door, "func_door_rotating")) != -1)
		{
			float door_pos[ 3 ];
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if(GetVectorDistance( door_pos, prisoner_pos) <= g_Min )
			{
				g_Min = GetVectorDistance( door_pos, prisoner_pos );
			}
		}
		
		while((door = FindEntityByClassname(door, "func_movelinear")) != -1)
		{
			float door_pos[ 3 ];
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if(GetVectorDistance( door_pos, prisoner_pos) <= g_Min )
			{
				g_Min = GetVectorDistance( door_pos, prisoner_pos );
			}
		}
		
		while((door = FindEntityByClassname(door, "prop_door_rotating")) != -1)
		{
			float door_pos[ 3 ]
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if(GetVectorDistance( door_pos, prisoner_pos) <= g_Min )
			{
				g_Min = GetVectorDistance( door_pos, prisoner_pos );
			}
		}
	}
	
	g_Min += 100;
	
	while( ( ent = FindEntityByClassname( ent, "info_player_terrorist" ) ) != -1 )
	{
		float prisoner_pos[ 3 ];
		GetEntPropVector( ent, Prop_Data, "m_vecOrigin", prisoner_pos );
		
		while( ( door = FindEntityByClassname( door, "func_door" ) ) != -1 )
		{
			float door_pos[ 3 ];
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if( GetVectorDistance( door_pos, prisoner_pos) <= g_Min )
			{
				PushArrayCell( g_DoorList, door );
			}
		}
		
		while( ( door = FindEntityByClassname( door, "func_door_rotating") ) != -1 )
		{
			float door_pos[ 3 ];
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if(GetVectorDistance( door_pos, prisoner_pos ) <= g_Min )
			{
				PushArrayCell( g_DoorList, door );
			}
		}
		
		while( ( door = FindEntityByClassname( door, "func_movelinear" ) ) != -1 )
		{
			float door_pos[ 3 ];
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if(GetVectorDistance( door_pos, prisoner_pos ) <= g_Min )
			{
				PushArrayCell( g_DoorList, door );
			}
		}
		
		while( ( door = FindEntityByClassname( door, "prop_door_rotating" ) ) != -1 )
		{
			float door_pos[ 3 ];
			GetEntPropVector( door, Prop_Data, "m_vecOrigin", door_pos );
			
			if( GetVectorDistance( door_pos, prisoner_pos ) <= g_Min )
			{
				PushArrayCell( g_DoorList, door );
			}
		}
	}
}
