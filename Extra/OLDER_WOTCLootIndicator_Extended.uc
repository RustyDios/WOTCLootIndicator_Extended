//=============================================================
//  FILE:   WOTCLootIndicator_Extended                                    
//  
//	File created by RustyDios	04/11/20    02:20
//	LAST UPDATED				22/08/21	03:20
//
//=============================================================
class WOTCLootIndicator_Extended extends UIUnitFlag	dependson(XComGameState_Unit) config(WOTCLootIndicator_Extended);

var UIIcon LootIcon, DamageIcon, AimIcon, DefIcon, MobIcon, WillIcon, HackIcon, DodgeIcon, PsiIcon, HPIcon, ShieldIcon, ArmorIcon, HudHeadIcon;
var UIText DamageText, AimText, DefText, MobText, WillText, HackText, DodgeText, PsiText, HPText, ShieldText, ArmorText, NameText;

var config EWidgetColor eColour_WillBar;

var config bool bRustyUIFlagLog;
var config bool NAME_COLOR_BYTEAM, HPBAR_COLOR_BYTEAM, SHIELDBAR_COLOR_BYTEAM_FRIENDLIES, SHIELDBAR_COLOR_BYTEAM_ENEMIES, SHIELDBAR_COLOR_FROSTLEGION;
var config bool SHOW_LOOT, REQUIRE_SCANNING, SHOW_STATS_ON_FRIENDLY, SHOW_BARS_ON_FRIENDLY, SHOW_MAX_HP, SHOW_FRIENDLY_NAME, SHOW_ENEMY_NAME;
var config bool SHOW_DAMAGE, SHOW_AIM, SHOW_DEF, SHOW_MOB, SHOW_WILL, SHOW_HACK, SHOW_DODGE, SHOW_PSI, SHOW_HP, SHOW_ARMOR, SHOW_SHIELD, SHOW_WILL_BAR, SHOW_HUDHEAD, SHOW_MOB_AS_TILES;
var config string DAMAGE_COLOR, AIM_COLOR, DEF_COLOR, MOB_COLOR, WILL_COLOR, HACK_COLOR, DODGE_COLOR, PSI_COLOR, HP_COLOR, ARMOR_COLOR, SHIELD_COLOR, NAME_COLOR, STAT_COLOR;

var config string HPBAR_COLORHEX_RULER_VIPER, HPBAR_COLORHEX_RULER_ZERKER, HPBAR_COLORHEX_RULER_ARCHON, HPBAR_COLORHEX_RULER_HIVE, SHIELDBAR_COLORHEX_FROSTLEGION;

var config int SHIELD_SHIFT_Y, ALIENRULER_SHIFT_Y, WILLBAR_SHIFT_Y, FOCUS_SHIFT_Y, HIDDENBARS_SHIFT_Y;

var config int LOOT_OFFSET_X, STAT_OFFSET_X, NAME_OFFSET_X; 
var config int LOOT_OFFSET_Y, STAT_OFFSET_Y, NAME_OFFSET_Y;

var config int INFO_FONT_SIZE, NAME_FONT_SIZE, INFO_ICON_SIZE, SIZE_OFPADDING;

var int ActiveStats, IconPadding, StatAnchorX, StatAnchorY;

var CachedInt  m_BreakthroughBonuses;
var CachedBool	m_BreakthroughBonusesFound, m_bThisIsAnObject, m_bObfuscate;

//var config int WILL_BAR_OFFSET_X, WILL_BAR_OFFSET_Y, WILL_BAR_ALPHA, WILL_BAR_LENGTH, WILL_BAR_HEIGHT;
//var UIBGBox RustyWillBar;

//=============================================================
// kUnit, the unit this flag is associated with. HAD TO OVERWRITE FOR NEW CACHED INTS
//=============================================================

simulated function InitFlag(StateObjectReference ObjectRef)
{
	local XComDestructibleActor DestructibleActor;

	m_bIsFriendly = new class'CachedBool';
	m_bIsActive = new class'CachedBool';
	m_currentHitPoints = new class'CachedInt';
	m_maxHitPoints = new class'CachedInt';
	m_armorPoints = new class'CachedInt';
	m_shieldPoints = new class'CachedInt';
	m_maxShieldPoints = new class'CachedInt';
	m_shieldPointsPreview = new class'CachedInt';
	m_nUnitMoves = new class'CachedInt';
	m_bIsCriticallyWounded = new class'CachedBool';
	m_nCriticallyWoundedTurns = new class'CachedInt';

	// NEW CACHES FOR STUFF
	m_BreakthroughBonuses = new class'CachedInt';
	m_BreakthroughBonusesFound = new class'CachedBool';
	m_bThisIsAnObject = new class'CachedBool';
	m_bObfuscate = new class'CachedBool';

	InitPanel();

	History = `XCOMHISTORY;
	
	StoredObjectID = ObjectRef.ObjectID; 

	UpdateFriendlyStatus();

	m_bIsDead = false;
	m_iMovePipsTouched = 0;

	// Destructible hit points are stored on the actor and updated by environment damage effects
	DestructibleActor = XComDestructibleActor(History.GetVisualizer(StoredObjectID));

	if( XComGameState_Destructible(History.GetGameStateForObjectID(StoredObjectID)) != none
	 	&& History.GetGameStateComponentForObjectID(StoredObjectID, class'XComGameState_ObjectiveInfo') == none 
		&& DestructibleActor != none && DestructibleActor.TotalHealth <= 1)
	{
		Hide();
		`LOG("OBJECT WAS DESTRUCTIBLE WITH <=1 HEALTH",default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}
}

//=============================================================
//	MAIN PART OF THE MOD -- THE HEALTH BAR AND ALL DISPLAYED STATS
//=============================================================
simulated function SetHitPoints( int _currentHP, int _maxHP )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentHP, maxHP, iMultiplier;//iPip, WillBarLength;
	local XComGameState_Unit UnitState;
	local XComDestructibleActor DestructibleActor;

	local LWTuple	Tuple;

	iMultiplier = `GAMECORE.HP_PER_TICK;

	//check if this is an environmental object
	DestructibleActor = XComDestructibleActor(History.GetVisualizer(StoredObjectID));
	if (DestructibleActor != none)
	{
		m_bThisIsAnObject.SetValue(true);
		`LOG("OBJECT WAS A DESTRUCTIBLE",default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	// DEAD - REMOVE HITPOINTS
	if ( _currentHP < 1 )
	{
		m_bIsDead = true;
		`LOG("UNIT WAS DEAD UNIT FLAG REMOVED",default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
		Remove();
	}
	else
	{
		//set up intial values
		ActiveStats = 0;
		IconPadding = default.SIZE_OFPADDING;
		StatAnchorX = default.STAT_OFFSET_X;
		StatAnchorY = default.STAT_OFFSET_Y;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));

		//start checking for values
		if( !m_bIsFriendly.GetValue() && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth ) // Profile is set to hide enemy health 
		{			
			myValue.Type = AS_Number;
			myValue.n = 0;
			myArray.AddItem( myValue );
			myValue.n = 0;
			myArray.AddItem( myValue );

			`LOG("UNIT WAS ENEMY && HIDE OPTION SET ::" @UnitState.GetFullName(), default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
		}
		else if ( m_bIsFriendly.GetValue() && !default.SHOW_BARS_ON_FRIENDLY) // Profile is set to hide friendly health
		{
			myValue.Type = AS_Number;
			myValue.n = 0;
			myArray.AddItem( myValue );
			myValue.n = 0;
			myArray.AddItem( myValue );

			`LOG("UNIT WAS FRIEND && HIDE OPTION SET ::" @UnitState.GetFullName(), default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
		}
		else
		{
			//Always round up for display when using the gamecore multiplier, per Jake's request. 
			if( iMultiplier > 0 )
			{
				currentHP = FCeil(float(_currentHP) / float(iMultiplier)); 
				maxHP = FCeil(float(_maxHP) / float(iMultiplier)); 
			}
		
			myValue.Type = AS_Number;
			myValue.n = currentHP;
			myArray.AddItem( myValue );
			myValue.n = maxHP;
			myArray.AddItem( myValue );

			`LOG("UNIT IS SHOWING UNIT FLAG ::" @UnitState.GetFullName(), default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');

			//=====================================//
			// ===== STATS BLOCK STARTS HERE ===== //
			//=====================================//

			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			// allow mods to change the show/hide behavior	
			//	SENT FROM WOTCLootIndicator_Extended.UC
			//		UI Unit Flag Extended
			Tuple = new class'LWTuple';
			Tuple.Id = 'UIUnitFlag_OverrideShowInfo';
			Tuple.Data.Add(2);

				// The targeted unit.
			Tuple.Data[0].kind = LWTVObject;
			Tuple.Data[0].o = UnitState;
				// Whether the info should be available.
			Tuple.Data[1].kind = LWTVBool;
			Tuple.Data[1].b = true;

			`XEVENTMGR.TriggerEvent('UIUnitFlag_OverrideShowInfo', Tuple);

			//a HIDE return should set the data false, we flip it here, so that m_bObfuscate = true
			//thus a query to !m_bObfuscate will be true later
			//stats obfuscated actually get the text filled in as ##
			//obfuscated stats are the same ones hidden in YAF1 -- damage, aim, mobility, will, hack, dodge, psi ... leaving HP, DEF, Shields and Armor
			m_bObfuscate.SetValue(!Tuple.Data[1].b);	
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			`LOG("IS UNIT FLAG OBFUSCATED ::" @m_bObfuscate, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');

			//show the loot indicator if it is an enemy AND does not require scanning OR scanned, battlescanned or reaper targeted
			if ( default.SHOW_LOOT && !m_bIsFriendly.GetValue() && !m_bThisIsAnObject.GetValue() &&
				( !default.REQUIRE_SCANNING || UnitState.IsUnitAffectedByEffectName('ScanningProtocol') || UnitState.IsUnitAffectedByEffectName('TargetDefinition')
				) )
			{
				if ( LootIcon == none )
				{
					LootIcon = Spawn(class'UIIcon', self).InitIcon('RustyLootIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Loot",false,false,default.INFO_ICON_SIZE);
					LootIcon.SetX(default.LOOT_OFFSET_X);
					LootIcon.SetY(default.LOOT_OFFSET_Y + GetYShift());
					LootIcon.Hide();
				}

				//hide if the unit actually has no loot
				if ( LootIcon != none && UnitState.PendingLoot.LootToBeCreated.Length > 0 )
				{
					LootIcon.Show();
				}
				else
				{
					LootIcon.Hide();
				}
			}
			
			//SHOW STATS IF IT IS AN ENEMY OR WE WANT FRIENDLY'S SHOWN
			if ( !m_bIsFriendly.GetValue() || default.SHOW_STATS_ON_FRIENDLY )
			{
				// ===== DAMAGE =====
				if ( default.SHOW_DAMAGE && !m_bThisIsAnObject.GetValue() )
				{
					if ( DamageIcon == none )
					{
						DamageIcon = Spawn(class'UIIcon', self).InitIcon('RustyDamageIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Damage",false,false,default.INFO_ICON_SIZE);
						DamageIcon.SetX(StatAnchorX);
						DamageIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //1
					}

					if ( DamageText == none ) 
					{
						DamageText = Spawn(class'UIText', self).InitText('RustyDamageText');
						DamageText.SetX(StatAnchorX + (IconPadding * ActiveStats) );
						DamageText.SetY(StatAnchorY + GetYShift());
						DamageText.SetColor(default.DAMAGE_COLOR);
						ActiveStats+=2; //3
					}

					if ( DamageText != none  ) 
					{
						if (!m_bObfuscate.GetValue() )
						{
							//damage text returns as max damage if min-max is equal, --- if both are 0 and x-y if a range
							//respects weapon breakthrough bonuses
							DamageText.SetText(class'UIUtilities_Text'.static.AddFontInfo(GetDamageString(UnitState),false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							DamageText.SetText(class'UIUtilities_Text'.static.AddFontInfo("#-#",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				// ===== AIM =====
				if ( default.SHOW_AIM && !m_bThisIsAnObject.GetValue() )
				{
					if ( AimIcon == none )
					{
						AimIcon = Spawn(class'UIIcon', self).InitIcon('RustyAimIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Aim",false,false,default.INFO_ICON_SIZE);
						AimIcon.SetX(StatAnchorX + (IconPadding * ActiveStats) );
						AimIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //4
					}

					if ( AimText == none ) 
					{
						AimText = Spawn(class'UIText', self).InitText('RustyAimText');
						AimText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						AimText.SetY(StatAnchorY + GetYShift());
						AimText.SetColor(default.AIM_COLOR);
						ActiveStats++; //5
					}

					if ( AimText != none ) 
					{
						if (!m_bObfuscate.GetValue() )
						{
							AimText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_Offense))),false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							AimText.SetText(class'UIUtilities_Text'.static.AddFontInfo("##",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				// ===== DEFENCE =====
				if ( default.SHOW_DEF && !m_bThisIsAnObject.GetValue() )
				{
					if ( DefIcon == none )
					{
						DefIcon = Spawn(class'UIIcon', self).InitIcon('RustyDefIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Def",false,false,default.INFO_ICON_SIZE);
						DefIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						DefIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //6
					}

					if ( DefText == none ) 
					{
						DefText = Spawn(class'UIText', self).InitText('RustyDefText');
						DefText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						DefText.SetY(StatAnchorY + GetYShift());
						DefText.SetColor(default.DEF_COLOR);
						ActiveStats++; //7
					}

					if ( DefText != none ) // && !m_bObfuscate.GetValue() )
					{
						DefText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_Defense))),false,false,false,default.INFO_FONT_SIZE) );
					}
				}

				// ===== MOBILITY =====
				if ( default.SHOW_MOB && !m_bThisIsAnObject.GetValue() )
				{
					if ( MobIcon == none )
					{
						MobIcon = Spawn(class'UIIcon', self).InitIcon('RustyMobIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Mob",false,false,default.INFO_ICON_SIZE);
						MobIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						MobIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //8
					}

					if ( MobText == none ) 
					{
						MobText = Spawn(class'UIText', self).InitText('RustyMobText');
						MobText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						MobText.SetY(StatAnchorY + GetYShift());
						MobText.SetColor(default.MOB_COLOR);
						ActiveStats++; //9
					}

					if ( MobText != none ) 
					{
						if (default.SHOW_MOB_AS_TILES && !m_bObfuscate.GetValue() )
						{
							MobText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_Mobility) / 1.5)),false,false,false,default.INFO_FONT_SIZE) );
						}
						else if (!default.SHOW_MOB_AS_TILES && !m_bObfuscate.GetValue() )
						{
							MobText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_Mobility))),false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							MobText.SetText(class'UIUtilities_Text'.static.AddFontInfo("##",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				// ===== DODGE =====
				if ( default.SHOW_DODGE && !m_bThisIsAnObject.GetValue() )
				{
					if ( DodgeIcon == none )
					{
						DodgeIcon = Spawn(class'UIIcon', self).InitIcon('RustyDodgeIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Dodge",false,false,default.INFO_ICON_SIZE);
						DodgeIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						DodgeIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //10
					}

					if ( DodgeText == none ) 
					{
						DodgeText = Spawn(class'UIText', self).InitText('RustyDodgeText');
						DodgeText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						DodgeText.SetY(StatAnchorY + GetYShift());
						DodgeText.SetColor(default.DODGE_COLOR);
						ActiveStats++; //11
					}

					if ( DodgeText != none  ) 
					{
						if (!m_bObfuscate.GetValue() )
						{
							DodgeText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_Dodge))),false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							DodgeText.SetText(class'UIUtilities_Text'.static.AddFontInfo("##",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				// ===== HACK =====
				if ( default.SHOW_HACK && !m_bThisIsAnObject.GetValue() )
				{
					if ( HackIcon == none )
					{
						HackIcon = Spawn(class'UIIcon', self).InitIcon('RustyHackIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Hack",false,false,default.INFO_ICON_SIZE);
						HackIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						HackIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //12
					}

					if ( HackText == none ) 
					{
						HackText = Spawn(class'UIText', self).InitText('RustyHackText');
						HackText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						HackText.SetY(StatAnchorY + GetYShift());
						HackText.SetColor(default.HACK_COLOR);
						ActiveStats++; //13
					}

					if ( HackText != none ) 
					{
						if (!m_bObfuscate.GetValue() )
						{
							HackText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_Hacking))),false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							HackText.SetText(class'UIUtilities_Text'.static.AddFontInfo("##",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				// ===== WILL =====
				if ( default.SHOW_WILL && !m_bThisIsAnObject.GetValue() )
				{
					if ( WillIcon == none )
					{
						WillIcon = Spawn(class'UIIcon', self).InitIcon('RustyWillIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Will",false,false,default.INFO_ICON_SIZE);
						WillIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						WillIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //14
					}

					if ( WillText == none ) 
					{
						WillText = Spawn(class'UIText', self).InitText('RustyWillText');
						WillText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						WillText.SetY(StatAnchorY + GetYShift());
						WillText.SetColor(default.WILL_COLOR);
						ActiveStats++; //15
					}

					if ( WillText != none ) 
					{
						if (!m_bObfuscate.GetValue() )
						{
							WillText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_Will))),false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							WillText.SetText(class'UIUtilities_Text'.static.AddFontInfo("##",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				// ===== PSI OFFENCE =====
				if ( default.SHOW_PSI && !m_bThisIsAnObject.GetValue() )
				{
					if ( PsiIcon == none )
					{
						PsiIcon = Spawn(class'UIIcon', self).InitIcon('RustyPsiIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Psi",false,false,default.INFO_ICON_SIZE);
						PsiIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						PsiIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //16
					}

					if ( PsiText == none ) 
					{
						PsiText = Spawn(class'UIText', self).InitText('RustyPsiText');
						PsiText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						PsiText.SetY(StatAnchorY + GetYShift());
						PsiText.SetColor(default.PSI_COLOR);
						ActiveStats++; //17
					}

					if ( PsiText != none ) 
					{
						if (!m_bObfuscate.GetValue() )
						{
							PsiText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(int(UnitState.GetCurrentStat(eStat_PsiOffense))),false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							PsiText.SetText(class'UIUtilities_Text'.static.AddFontInfo("##",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				// ===== HEALTH =====
				if ( default.SHOW_HP )
				{
					if ( HPIcon == none ) 
					{
						HPIcon = Spawn(class'UIIcon', self).InitIcon('RustyHPIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Health",false,false,default.INFO_ICON_SIZE);
						HPIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						HPIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //18
					}

					if ( HPText == none ) 
					{
						HPText = Spawn(class'UIText', self).InitText('RustyHPText');
						HPText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						HPText.SetY(StatAnchorY + GetYShift());
						HPText.SetColor(default.HP_COLOR);
						ActiveStats+=2; //20
					}

					if ( HPText != none ) 
					{
						if (default.SHOW_MAX_HP) 
						{
							HPText.SetText(class'UIUtilities_Text'.static.AddFontInfo(_currentHP $ "/" $ _maxHP,false,false,false,default.INFO_FONT_SIZE) );
						}
						else 
						{
							HPText.SetText(class'UIUtilities_Text'.static.AddFontInfo(_currentHP $ "",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}

				/*	// ===== LEGACY WILL BAR =====
					// ===== LEGEACY CODE, WOTC NOW HANDLES THIS BY ITSELF, SEE BELOW ===== //
				if ( default.SHOW_WILL_BAR && !m_bThisIsAnObject.GetValue() )
				{
					if ( RustyWillBar == none ) 
					{
						RustyWillBar = Spawn(class'UIBGBox', self);
						RustyWillBar.InitBG('RustyWillBar').SetBGColor("gray");
						RustyWillBar.SetColor(default.WILL_BAR_COLOR);
						RustyWillBar.SetAlpha(default.WILL_BAR_ALPHA);
						RustyWillBar.SetHighlighed(true);
					}

					RustyWillBar.SetPosition(default.WILL_BAR_OFFSET_X,default.WILL_BAR_OFFSET_Y);

					if ( UnitState.GetMaxStat(eStat_Will) <= 0.0 )
					{
						RustyWillBar.SetSize(1.0,default.WILL_BAR_HEIGHT);
					}
					else
					{
						RustyWillBar.SetSize(default.WILL_BAR_LENGTH * max(UnitState.GetCurrentStat(eStat_Will),1.0) / UnitState.GetMaxStat(eStat_Will),default.WILL_BAR_HEIGHT);
					}
				}*/

				//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				// allow mods to add a new stat block pair if they want	
				//	SENT FROM WOTCLootIndicator_Extended.UC
				//		UI Unit Flag Extended
				/*NSLWTuple = new class'LWTuple';
				NSLWTuple.Id = 'UIUnitFlag_NewStatsInfo';
				NSLWTuple.Data.Add(5);

					// To show a new stat or not
				NSLWTuple.Data[0].kind = LWTVBool;
				NSLWTuple.Data[0].b = false;
					// Whether the info should be obfuscated with everything else.
				NSLWTuple.Data[1].kind = LWTVBool;
				NSLWTuple.Data[1].b = false;
					// Icon Path on new stat, does not require "img:///"
				NSLWTuple.Data[2].kind = LWTVString;
				NSLWTuple.Data[2].s = "";
					// New Stat Display String
				NSLWTuple.Data[3].kind = LWTVString;
				NSLWTuple.Data[3].s = "";
					// New Stat Display HexColour
				NSLWTuple.Data[4].kind = LWTVString;
				NSLWTuple.Data[4].s = "FFFFFF";

				//trigger event to ask for replies, eventname	   eventdata, eventsource //gamestate?
				`XEVENTMGR.TriggerEvent('UIUnitFlag_NewStatsInfo', NSLWTuple, UnitState );

				// ===== NEWSTATS =====
				if ( NSLWTuple.Data[0].b )
				{
					if ( NewStatIcon == none ) 
					{
						NewStatIcon = Spawn(class'UIIcon', self).InitIcon('RustyNewStatIcon',"img:///" $ NSLWTuple.Data[2].s,false,false,default.INFO_ICON_SIZE);
						NewStatIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
						NewStatIcon.SetY(StatAnchorY + GetYShift());
						ActiveStats++; //21 ??
					}

					if ( NewStatText == none ) 
					{
						NewStatText = Spawn(class'UIText', self).InitText('RustyNewStatText');
						NewStatText.SetX(StatAnchorX + (IconPadding * ActiveStats));
						NewStatText.SetY(StatAnchorY + GetYShift());
						NewStatText.SetColor(NSLWTuple.Data[4].s);
						ActiveStats++; //22 ??
					}

					if ( NewStatText != none ) 
					{
						if (!m_bObfuscate.GetValue() && !NSLWTuple.Data[1].b)
						{
							NewStatText.SetText(class'UIUtilities_Text'.static.AddFontInfo(NSLWTuple.Data[3].s,false,false,false,default.INFO_FONT_SIZE) );
						}
						else
						{
							NewStatText.SetText(class'UIUtilities_Text'.static.AddFontInfo("##",false,false,false,default.INFO_FONT_SIZE) );
						}
					}
				}*/

				//=====================================//
			}	//		STATS BLOCK ENDS HERE		   //
				//=====================================//

		}	// ===== SHOW ANY DATA ENDS HERE ===== //

		//IF UNIT IS NOT DEAD SET UP TO SHOW HEALTH -- ALSO CALLS SET SHIELD POINTS
		Invoke("SetHitPoints", myArray);
	}
	
	//=====================================//
	//		CHANGE THE BAR COLOURS 		   //
	//=====================================//

	//handling to set the colour by team, handles chosen, cx queen and cx cotk too and hopefully any other 'rulers'
	if (default.HPBAR_COLOR_BYTEAM) 
	{
		//generic colour settings for special units
		if (UnitState.bIsSpecial )
		{
			ColourRulerHealthBar("ACD373", true );	//set ruler colour
		}
		else if (UnitState.IsChosen() )
		{
			AS_SetMCColor(MCPath $".healthMeter.theMeter", "B6B3E3");	//set chosen colour, yes base flash has them set to psionic
		}
		else
		{
			AS_SetMCColor(MCPath $".healthMeter.theMeter", class'UIUtilities_Colors'.static.GetHexColorFromState(FindHudHeadColour() )); //set team colour
		}

		//direct overrides per set template name
		switch (UnitState.GetMyTemplateName())
		{
			case 'ViperKing':
			case 'ViperPrince1':
			case 'ViperPrince2':
			case 'ViperPrince3':
			case 'ViperPrincess':
				ColourRulerHealthBar(HPBAR_COLORHEX_RULER_VIPER,	false);		break;
			case 'BerserkerQueen':
				ColourRulerHealthBar(HPBAR_COLORHEX_RULER_ZERKER,	false);		break;
			case 'ArchonKing':
				ColourRulerHealthBar(HPBAR_COLORHEX_RULER_ARCHON,	false);		break;
			case 'CXQueen':
				ColourRulerHealthBar(HPBAR_COLORHEX_RULER_HIVE,		false);		break;
			case 'AdvPsiWitchM2':
			case 'AdvPsiWitchM3':
				AS_SetMCColor(MCPath $".healthMeter.theMeter", "B6B3E3");	break; //set Avatar colour
			default:
				break;
		}

	}
}

//this.healthMCArray[_loc2_] = Bind.movie(this.healthMeter,"healthMeter","healthMeter" + _loc2_)
//this.shieldMeter = 			 Bind.movie(this.healthMeter,"healthMeter","shieldMeter");

//set ruler colour, and make sure the game takes care of 'the health array extra lines' to colour to this colour
simulated function ColourRulerHealthBar(string HEXCOLOUR, bool Show_BIGHEAD)
{
	local float fTotalHealthBars;
	local int i;

	AS_SetMCColor	(MCPath $".healthMeter.theMeter", HEXCOLOUR);	//set ruler colour, game takes care of 'the health array extra lines' to colour to this colour

	fTotalHealthBars = Movie.GetVariableNumber(MCPath $ ".MeterTotal");
	for (i = 0 ; i < fTotalHealthBars ; i++)
	{
		AS_SetMCColor(MCPath $".healthMeter.healthMeter" $ i $ ".theMeter", HEXCOLOUR);	//set ruler colour, game takes care of 'the health array extra lines' to colour to this colour
	}

	i = 0;
	MC.ChildSetBool ("specialAlienIcon","_visible", Show_BIGHEAD);
}

//=============================================================
//	SECONDARY PART OF THE MOD -- THE SHIELD BAR (AND STAT SHIFTING)
//=============================================================

simulated function SetShieldPoints( int _currentShields, int _maxShields )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentShields, maxShields, iMultiplier;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));

	iMultiplier = `GAMECORE.HP_PER_TICK;

	if( !m_bIsFriendly.GetValue() && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth ) // Profile is set to hide enemy health, so hide shields too
	{			
		myValue.Type = AS_Number;
		myValue.n = 0;
		myArray.AddItem( myValue );
		myValue.n = 0;
		myArray.AddItem( myValue );
	}
	else if ( m_bIsFriendly.GetValue() && !default.SHOW_BARS_ON_FRIENDLY) // Profile is set to hide friendly health, so hide shields too
	{
		myValue.Type = AS_Number;
		myValue.n = 0;
		myArray.AddItem( myValue );
		myValue.n = 0;
		myArray.AddItem( myValue );
	}
	else
	{
		//Always round up for display when using the gamecore multiplier, per Jake's request. 
		if( iMultiplier > 0 )
		{
			currentShields = FCeil(float(_currentShields) / float(iMultiplier));
			maxShields = FCeil(float(_maxShields) / float(iMultiplier));
		}
	
		m_shieldPoints.SetValue(currentShields);
		m_maxShieldPoints.SetValue(maxShields);

		myValue.Type = AS_Number;
		myValue.n = m_shieldPoints.GetValue();
		myArray.AddItem( myValue );
		myValue.n = m_maxShieldPoints.GetValue();
		myArray.AddItem( myValue );

		// ===== SHIELDS =====
		if ( default.SHOW_SHIELD && !m_bThisIsAnObject.GetValue() )
		{
			if ( ShieldIcon == none )
			{
				ShieldIcon = Spawn(class'UIIcon', self).InitIcon('RustyShieldIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Shield",false,false,default.INFO_ICON_SIZE);
				ShieldIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
				ShieldIcon.SetY(StatAnchorY + GetYShift());
				ActiveStats++; //21
			}

			if ( ShieldText == none ) 
			{
				ShieldText = Spawn(class'UIText', self).InitText('RustyShieldText');
				ShieldText.SetX(StatAnchorX + (IconPadding * ActiveStats));
				ShieldText.SetY(StatAnchorY + GetYShift());
				ShieldText.SetColor(default.SHIELD_COLOR);
				ActiveStats++; //22
			}

			if ( _currentShields > 0 )
			{
				ShieldText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(_currentShields),false,false,false,default.INFO_FONT_SIZE) );
			}
			else
			{
				ShieldText.SetText(class'UIUtilities_Text'.static.AddFontInfo("---",false,false,false,default.INFO_FONT_SIZE) );
			}
		}

	} //SHOW DATA ENDS HERE

	RefreshShiftPositions();

	`LOG("REFRESH SHIFT POSITION DONE FOR ::" @UnitState.GetFullName(), default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
 
	Invoke("SetShieldPoints", myArray);

	//=====================================//
	//	CHANGE THE BAR COLOURS - ENEMY	   //
	//=====================================//

	if ( default.SHIELDBAR_COLOR_BYTEAM_ENEMIES && !m_bIsFriendly.GetValue() )
	{
		if (UnitState.bIsSpecial )
		{
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "ACD373");	//set ruler colour, game takes care of 'the health array extra lines' to colour to this colour
		}
		else if (UnitState.IsChosen())
		{
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "B6B3E3");	//set chosen colour, yes base flash has them set to psionic, this needs to repeat this
		}
		else if ( default.SHIELDBAR_COLOR_FROSTLEGION && UnitState.HasAbilityFromAnySource('MZ_FDIceShield') )
		{
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", SHIELDBAR_COLORHEX_FROSTLEGION);	//set as 'frosty' shield colour for the Frost Legion Dudes
		}
		else 
		{
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", class'UIUtilities_Colors'.static.GetHexColorFromState(FindHudHeadColour() )); //set team colour
		}

		//direct overrides per set template name
		switch (UnitState.GetMyTemplateName())
		{
			case 'ViperKing':
			case 'ViperPrince1':
			case 'ViperPrince2':
			case 'ViperPrince3':
			case 'ViperPrincess':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", HPBAR_COLORHEX_RULER_VIPER	);	break; //set ruler colour, game takes care of 'the health array extra lines' to colour to this colour
			case 'BerserkerQueen':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", HPBAR_COLORHEX_RULER_ZERKER	);	break; //set ruler colour, game takes care of 'the health array extra lines' to colour to this colour
			case 'ArchonKing':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", HPBAR_COLORHEX_RULER_ARCHON	);	break; //set ruler colour, game takes care of 'the health array extra lines' to colour to this colour
			case 'CXQueen':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", HPBAR_COLORHEX_RULER_HIVE	);	break; //set ruler colour, game takes care of 'the health array extra lines' to colour to this colour
			case 'AdvPsiWitchM2':
			case 'AdvPsiWitchM3':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "B6B3E3"						);	break; //set Avatar colour
			default:
				break;
		}
	}
	
	//=====================================//
	//	CHANGE THE BAR COLOURS - FRIENDLY  //
	//=====================================//

	if ( default.SHIELDBAR_COLOR_BYTEAM_FRIENDLIES && m_bIsFriendly.GetValue() )
	{
		AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", class'UIUtilities_Colors'.static.GetHexColorFromState(FindHudHeadColour() )); //set team colour

		//direct overrides per set template name
		switch (UnitState.GetMyTemplateName())
		{
			case 'AdvPsiWitchM2':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "B6B3E3"						);	break; //set Avatar colour
			default:
				break;
		}
	}

	// Enable shield-hitpoints preview visualization
	SetShieldPointsPreview();
}

//=============================================================
//	TERTIARY PART OF THE MOD -- THE ARMOUR PIPS
//=============================================================

simulated function SetArmorPoints(optional int _iArmor = 0)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentArmor, iMultiplier;
	//local XComGameState_Unit UnitState;
	//UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));

	iMultiplier = `GAMECORE.HP_PER_TICK;

	if( m_bIsFriendly.GetValue() || `XPROFILESETTINGS.Data.m_bShowEnemyHealth ) 
	{			
		//Always round up for display when using the gamecore multiplier, per Jake's request. 
		if( iMultiplier > 0 )
		{
			currentArmor = FCeil(float(_iArmor) / float(iMultiplier));
		}

		myValue.Type = AS_Number;
		myValue.n = currentArmor;
		myArray.AddItem( myValue );	

		// ===== ARMOUR =====
		if ( default.SHOW_ARMOR && !m_bThisIsAnObject.GetValue() )
		{
			if ( ArmorIcon == none )
			{
				ArmorIcon = Spawn(class'UIIcon', self).InitIcon('RustyArmorIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Armor",false,false,default.INFO_ICON_SIZE);
				ArmorIcon.SetX(StatAnchorX + (IconPadding * ActiveStats));
				ArmorIcon.SetY(StatAnchorY + GetYShift());
				ActiveStats++; //23
			}

			if ( ArmorText == none ) 
			{
				ArmorText = Spawn(class'UIText', self).InitText('RustyArmorText');
				ArmorText.SetX(StatAnchorX + (IconPadding * ActiveStats));
				ArmorText.SetY(StatAnchorY + GetYShift());
				ArmorText.SetColor(default.ARMOR_COLOR);
				ActiveStats++; //24
			}

			if ( _iArmor > 0 )
			{
				ArmorText.SetText(class'UIUtilities_Text'.static.AddFontInfo(string(_iArmor),false,false,false,default.INFO_FONT_SIZE) );
			}
			else
			{
				ArmorText.SetText(class'UIUtilities_Text'.static.AddFontInfo("---",false,false,false,default.INFO_FONT_SIZE) );
			}
		}
		Invoke("ClearAllArmor");
		Invoke("SetArmor", myArray);
	}
	else
	{
		Invoke("ClearAllArmor"); // we dont want to show enemy healthbars so clear armor pips
	}
}

//=========================================================================//
// ===== THIS IS THE WOTC BUILT IN WILL BAR,IN UNDERNEATH THE HEALTH ===== //
// ===== TECHNICALLY NO CHANGES BUT I PUT THE COLOUR OPEN TO CONFIG  ===== //
// =====		AND IF THE BAR SHOULD BE SHOWN OR HIDDEN			 ===== //
//========================================================================//

simulated function SetWillPoints(int _currentWill, int _maxWill, int _previousWill)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( m_bIsFriendly.GetValue() && m_bUsesWillSystem && default.SHOW_WILL_BAR) // Only show will on friendly units if selected
	{
		myValue.Type = AS_Number;
		myValue.n = (_previousWill / float(_maxWill)) * 100.0f;
		myArray.AddItem(myValue);

		myValue.Type = AS_String;
		myValue.s = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(default.eColour_WillBar);	//<< coloured will bar	eColor_Good
		myArray.AddItem(myValue);

		myValue.Type = AS_Number;
		myValue.n = (_currentWill / float(_maxWill)) * 100.0f;
		myArray.AddItem(myValue);

		Invoke("SetUnitWill", myArray);
	}
}

//=========================================================================================//
// ===== THIS IS THE CHL FOCUS BAR , BELOW THE WILL . NO CHANGES BUT HERE TO COMPARE ===== //
//=========================================================================================//
/*
// Start Issue #257 -- deprecated, 
simulated function SetFocusPoints(int _currentFocus, int _maxFocus)
{
	RealizeFocusMeter(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(StoredObjectID)));
}

simulated function RealizeFocusMeter(XComGameState_Unit UnitState)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local XComLWTuple Tup;

	Tup = class'CHHelpers'.static.GetFocusTuple(UnitState);

	//Tup.Data[1].i = FocusState.FocusLevel;
	//Tup.Data[2].i = FocusState.GetMaxFocus(UnitState);
	//Tup.Data[3].s = "0x" $ class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;
	//Tup.Data[4].s = "";
	//Tup.Data[5].s = `XEXPAND.ExpandString(class'UITacticalHUD_SoldierInfo'.default.FocusLevelDescriptions[FocusState.FocusLevel]);
	//Tup.Data[6].s = class'UITacticalHUD_SoldierInfo'.default.FocusLevelLabel;

	myValue.Type = AS_Number;
	myValue.n = Tup.Data[0].b ? float(Tup.Data[1].i) : -1.0f; //focus level
	myArray.AddItem(myValue);
	myValue.Type = AS_Number;
	myValue.n = Tup.Data[2].i;	//max focus
	myArray.AddItem(myValue);

	Invoke("SetFocusPoints", myArray);

	AS_SetMCColor(MCPath$".healthAnchor.focusMeter.theMeter", Tup.Data[3].s);	//colour
}
// End Issue #257
*/

//=============================================================
/*
	WE THEN HAVE A BUNCH OF STUFF SET EVEN LOWER DOWN
	OFFENSE ARROWS	DEFENSE ARROWS	RANK	MOVES			COVER
	SELECTED	TARGETED	ALERTED	SPOTTED
	HOLDING MISSION ITEM	HOLDING OBJECTIVE ITEM
	CONCEALMENT		OVERWATCH EYE	CLAYMORE	STATUS ICON (ONLY ONE AT A TIME !)	RUPTURE ICON	BINDED	
*/
//=============================================================

//==================================================================//
// -- SHIELD SHIFT BUMP NOW TAKES INTO ACCOUNT THE CHL FOCUS BAR -- //
//==================================================================//

//=============================================================
// function for calculating the shift values and setting correctly
//=============================================================

simulated function RefreshShiftPositions()
{
	if ( LootIcon != none ) 	{ LootIcon.SetY(default.LOOT_OFFSET_Y);					}	//NOTE LOOT INDICATOR DOES NOT GET BUMPED UP ... IN THE LIST FOR CONSISTENCY
	if ( DamageIcon != none ) 	{ DamageIcon.SetY(StatAnchorY + GetYShift());			}
	if ( DamageText != none ) 	{ DamageText.SetY(StatAnchorY + GetYShift());			}
	if ( AimIcon != none ) 		{ AimIcon.SetY(StatAnchorY + GetYShift()); 				}
	if ( AimText != none ) 		{ AimText.SetY(StatAnchorY + GetYShift()); 				}
	if ( DefIcon != none ) 		{ DefIcon.SetY(StatAnchorY + GetYShift()); 				}	// ADDED BY RUSTY
	if ( DefText != none ) 		{ DefText.SetY(StatAnchorY + GetYShift()); 				}	// ADDED BY RUSTY
	if ( MobIcon != none )		{ MobIcon.SetY(StatAnchorY + GetYShift()); 				}
	if ( MobText != none )		{ MobText.SetY(StatAnchorY + GetYShift()); 				}
	if ( DodgeIcon != none ) 	{ DodgeIcon.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY
	if ( DodgeText != none ) 	{ DodgeText.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY
	if ( HackIcon != none ) 	{ HackIcon.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY
	if ( HackText != none ) 	{ HackText.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY
	if ( WillIcon != none ) 	{ WillIcon.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY
	if ( WillText != none ) 	{ WillText.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY
	if ( PsiIcon != none ) 		{ PsiIcon.SetY(StatAnchorY + GetYShift()); 				}	// ADDED BY RUSTY
	if ( PsiText != none ) 		{ PsiText.SetY(StatAnchorY + GetYShift()); 				}	// ADDED BY RUSTY
	if ( HPIcon != none ) 		{ HPIcon.SetY(StatAnchorY + GetYShift()); 				}	
	if ( HPText != none ) 		{ HPText.SetY(StatAnchorY + GetYShift()); 				}
	if ( ShieldIcon != none ) 	{ ShieldIcon.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY	
	if ( ShieldText != none ) 	{ ShieldText.SetY(StatAnchorY + GetYShift()); 			}
	if ( ArmorIcon != none ) 	{ ArmorIcon.SetY(StatAnchorY + GetYShift());			}	// ADDED BY RUSTY
	if ( ArmorText != none ) 	{ ArmorText.SetY(StatAnchorY + GetYShift()); 			}
	if ( HudHeadIcon != none)	{ HudHeadIcon.SetY(default.NAME_OFFSET_Y + GetYShift());}	// ADDED BY RUSTY
	if ( NameText != none ) 	{ NameText.SetY(default.NAME_OFFSET_Y + GetYShift());	}

	return;
}

//=================================================================//
// ===== to move all stats UP/DOWN per what bars are present ===== //
//=================================================================//
function int GetYShift() 
{
	local XComGameState_Unit UnitState;
	local int Shift;
	local float fTotalHealthBars;

	local bool bUnitHasFocusBar;
	local Object Tuple;
    local XComGameState_Effect_TemplarFocus FocusState;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));

	//check for the presence of a focus bar, templar or CHL
	if (Function'XComGame.CHHelpers.GetFocusTuple' != none)
    {
        Tuple = class'CHHelpers'.static.GetFocusTuple(UnitState);
        bUnitHasFocusBar = XComLWTuple(Tuple).Data[0].b;
    }
	else if (UnitState.IsFriendlyToLocalPlayer())
    {
        FocusState = UnitState.GetTemplarFocusEffectState();
        if (FocusState != none)
        {
            bUnitHasFocusBar = true;
        }
    }

	// BEGIN SHIFT AT 0
	Shift = 0;

	// BUMP UP IF THEY HAVE SHIELDS
	if ( UnitState.GetCurrentStat( eStat_ShieldHP ) > 0 ) 
	{
		Shift += default.SHIELD_SHIFT_Y;
		`LOG("Shift Shield Bars :: TRUE for ::"@UnitState.GetMyTemplateName(),default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	// BUMP UP IF THEY ARE A 'RULER' FOR THE NUMBER OF EXTRA HP BARS, ACCOUNTS FOR ANY UNIT WITH MORE THAN ONE HEALTH BAR
	// INCLUDING VIPERKING, ARCHONKING, ZERKER QUEEN, HIVE QUEEN, CotK ... ALSO BUMPS CORRECTLY FOR BETA STRIKE BARS
	// 		!! MUCH THANKS TO IRIDAR, ROBOJUMPER AND XYMANEK FOR THE AID AND INSPIRATION !!
	fTotalHealthBars = Movie.GetVariableNumber(MCPath $ ".MeterTotal");
	if (fTotalHealthBars > 1.0)
	{
		Shift += default.ALIENRULER_SHIFT_Y * int(fTotalHealthBars -1);
		`LOG("AS Total Health Bars :: " @int(fTotalHealthBars) @"::" @UnitState.GetMyTemplateName(),default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	// BUMP UP IF THEY ARE FRIENDLY AND HAVE A WILL BAR
	//if (m_bIsFriendly.GetValue() && m_bUsesWillSystem && default.SHOW_WILL_BAR || m_bThisIsAnObject.GetValue() )
	if (m_bUsesWillSystem && default.SHOW_WILL_BAR || m_bThisIsAnObject.GetValue() )
	{
		Shift += default.WILLBAR_SHIFT_Y;
		`LOG("Shift Will Bars :: TRUE for ::"@UnitState.GetMyTemplateName() @":: WAS OBJECT ::" @m_bThisIsAnObject.GetValue(),default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	// BUMP UP IF IT IS AN OBJECT, ODDLY ENOUGH ALWAYS THE SAME SHIFT NEEDED HERE FOR THE WILL BAR
	/*if (m_bThisIsAnObject.GetValue() )
	{
		Shift += default.WILLBAR_SHIFT_Y;
	}*/
	
	// BUMP ONE LAST TIME IF THEY ARE FRIENDLY AND HAVE A FOCUS BAR
	//if (m_bIsFriendly.GetValue() && bUnitHasFocusBar )
	if ( bUnitHasFocusBar )
	{
		Shift += default.FOCUS_SHIFT_Y;
		`LOG("Shift Focus Bars :: TRUE for ::"@UnitState.GetMyTemplateName(),default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	// this should shift everything DOWN if the stats and bars are hidden, so basically just the name and head icon, as that should be all that is left
	if (m_bIsFriendly.GetValue() && !default.SHOW_BARS_ON_FRIENDLY)
	{
		Shift -= default.HIDDENBARS_SHIFT_Y;
		`LOG("Shift HIDDEN Bars Friend:: TRUE for ::"@UnitState.GetMyTemplateName(),default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	if (!m_bIsFriendly.GetValue() && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth)
	{
		Shift -= default.HIDDENBARS_SHIFT_Y / 2;
		`LOG("Shift HIDDEN Bars Enemy:: TRUE for ::"@UnitState.GetMyTemplateName(),default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	return Shift;
}

//==================================================================//
// 						END OF BUMPING AROUND						//
//==================================================================//

//=============================================================
// function for damage stat 
//=============================================================

function string GetDamageString(XComGameState_Unit UnitState)
{
	local int minDamage, maxDamage;
	local X2AbilityTemplateManager 	AbilityManager;
	local XComGameState_Item 		WeaponState;
	local XComGameState_Tech		BreakthroughTech;
	local X2WeaponTemplate 			WeaponTemplate;
	local X2Techtemplate			TechTemplate;
	local X2AbilityTemplate 		AbilityTemplate;
	local StateObjectReference 		ObjectRef;
	local X2Effect					TargetEffect;

    AbilityManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	WeaponState = UnitState.GetPrimaryWeapon();
	WeaponTemplate = X2WeaponTemplate (WeaponState.GetMyTemplate()) ;

	minDamage = WeaponTemplate.BaseDamage.Damage - WeaponTemplate.BaseDamage.Spread;
	maxDamage = WeaponTemplate.BaseDamage.Damage + WeaponTemplate.BaseDamage.Spread;

	if ( WeaponTemplate.BaseDamage.PlusOne > 0 )
	{
		maxDamage++;
	}

	//=================================================================//
	// ===== ACCOUNT FOR BREAKTHROUGH DAMAGES TO THE BASE WEAPON ===== //
	//=================================================================//
	//find the breakthrough damage once, and cache it
	if (!m_BreakthroughBonusesFound.GetValue())
	{
		//get breakthough from HQ
		foreach `XCOMHQ.TacticalTechBreakthroughs(ObjectRef)
		{
			BreakthroughTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ObjectRef.ObjectID));
			TechTemplate = BreakthroughTech.GetMyTemplate();

			//see if this units primary weapon meets breakthrough conditionals
			if (TechTemplate.BreakthroughCondition != none && TechTemplate.BreakthroughCondition.MeetsCondition(WeaponState))
			{
				AbilityTemplate = AbilityManager.FindAbilityTemplate( TechTemplate.RewardName );

				//check if this unit has breakthrough abilities/effects
				if (UnitState.HasAbilityFromAnySource(TechTemplate.RewardName))
				{
					foreach AbilityTemplate.AbilityTargetEffects( TargetEffect )
					{
						//add value to the unitflags cached bonus
						m_BreakthroughBonuses.SetValue( m_BreakthroughBonuses.GetValue() + X2Effect_BonusWeaponDamage(TargetEffect).BonusDmg);
					}
				}
			}
		}
		m_BreakthroughBonusesFound.SetValue(true);
	}

	//bump up damage if the unit is friendly and has a bonus amount 
	if (m_bIsFriendly.GetValue())
	{
		minDamage += m_BreakthroughBonuses.GetValue();
		maxDamage += m_BreakthroughBonuses.GetValue();
	}
	//=============================================================
	//=============================================================

	if(maxDamage - minDamage < 0 || maxDamage <= 0)		//damage output is 'none'
	{
		return "---";
	}

	if(maxDamage - minDamage == 0)		//damages are the same
	{
		return string(maxDamage);
	}

	return minDamage $ "-" $ maxDamage;//damage is a range
}

//=================================================//
// ===== NAME ROW, ON TOP OF EVERYTHING ELSE ===== //
//=================================================//

simulated function SetNames( string unitName, string unitNickName )
{
	local string ThisName;
	
	if ( unitNickName != "" ) 
	{ 
		ThisName = unitNickName; 
	}
	else 
	{ 
		ThisName = unitName; 
	}

	//HUDHEAD CODE CONSTRUCTED WITH HELP FROM EXTENDED INFORMATION ... THANKS GUYS !
	if ( default.SHOW_HUDHEAD && !m_bThisIsAnObject.GetValue() )
	{
		if ( HudHeadIcon == none )
		{
			HudHeadIcon = Spawn(class'UIIcon', self);
			HudHeadIcon.InitIcon(,,false,true, default.INFO_ICON_SIZE); //'RustyHudHeadIcon'
			HudHeadIcon.SetX(default.NAME_OFFSET_X);
			HudHeadIcon.SetY(default.NAME_OFFSET_Y + GetYShift());
			HudHeadIcon.bAnimateOnInit = false;

			//for whatever reason extended information sets the color before loading the icon parts? ... ima going to copy the pro's
			HudHeadIcon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
			HudHeadIcon.SetBGColorState(FindHudHeadColour());

			HudHeadIcon.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath(FindHudHeadString()));
			HudHeadIcon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath(FindHudHeadStringBG()));
		}
	}

	if ( ( default.SHOW_FRIENDLY_NAME && m_bIsFriendly.GetValue() ) || ( default.SHOW_ENEMY_NAME && !m_bIsFriendly.GetValue() ) )
	{
		if ( NameText == none ) 
		{
			NameText = Spawn(class'UIText', self).InitText('RustyNameText');
			if (HudHeadIcon != none)
			{
				NameText.SetX(default.NAME_OFFSET_X + default.INFO_ICON_SIZE);
			}
			else
			{
				NameText.SetX(default.NAME_OFFSET_X);
			}

			NameText.SetY(default.NAME_OFFSET_Y + GetYShift());

			if (default.NAME_COLOR_BYTEAM)
			{
				NameText.SetColor(class'UIUtilities_Colors'.static.GetHexColorFromState(FindHudHeadColour() ) );
			}
			else
			{
				NameText.SetColor(default.NAME_COLOR);
			}

			NameText.SetText(class'UIUtilities_Text'.static.AddFontInfo(ThisName,false,false,false,default.NAME_FONT_SIZE));
		}
	}

	//CHECK AND REFRESH SHIFT POSITIONS
	RefreshShiftPositions();
	`LOG("REFRESH SHIFT POSITION DONE BY NAME ::" @ThisName, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');

}

//=============================================================
// GET TARGET ICON ... COMPRISED OF TWO PARTS THE FOREGROUND OUTLINE AND THE BG SOLID
//=============================================================
simulated function string FindHudHeadString()
{
	local XComGameState_Unit UnitState;
	local X2VisualizerInterface Visualizer;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	Visualizer = X2VisualizerInterface(UnitState.GetVisualizer());

	return Visualizer.GetMyHUDIcon();
} 

simulated function string FindHudHeadStringBG()
{
	local XComGameState_Unit UnitState;
	local X2VisualizerInterface Visualizer;
	local string result;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	Visualizer = X2VisualizerInterface(UnitState.GetVisualizer());

	result = Visualizer.GetMyHUDIcon() $"_bg";
	return result;
} 

//=============================================================
// GET TARGET ICON COLOUR ... WILL ALSO BE THE TEAM COLOUR
//=============================================================
simulated function eUIState FindHudHeadColour()
{
	local XComGameState_Unit UnitState;
	local X2VisualizerInterface Visualizer;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	Visualizer = X2VisualizerInterface(UnitState.GetVisualizer());

	return Visualizer.GetMyHUDIconColor();
} 

//=============================================================
// THIS FUNCTION OFFSETS THE ENTIRE FLAG POSITION FOR UNITS UNDER VIPER BIND
// I EXTENDED IT TO ACCOUNT FOR UNITS THAT HAVE BEEN BOUND BY THE VIPER KING AND HOISTED BY THE ARCHON KING TOO
// ALSO EXTENDED TO ELITE VIPERS AND ABA VIPERS AND FROST LEGION VIPERS/ADDERS
// ARMOURED, VALENTINES AND FLAME VIPERS USE STANDARD BIND
//=============================================================
simulated function RealizeViperBind(XComGameState_Unit NewUnitState)
{
	//const VIPER_BIND_OFFSET = 30; // 30 may have been fine for base game, but it's not for this with with all the extra stats and stuff
	//The unit flag for the unit being bound will overlap with the Viper's unit flag without an offset.
	//m_LocalYOffset = NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_Viper'.default.BindSustainedEffectName) ? VIPER_BIND_OFFSET : 0;
	if (	NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_Viper'.default.BindSustainedEffectName)
		||	NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_DLC_Day60ViperKing'.default.KingBindSustainedEffectName)
		||	NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_DLC_60ArchonKing'.default.IcarusDropGrabbeeEffect_SustainedName)
		||	NewUnitState.IsUnitAffectedByEffectName('BindEliteSustained')
		||	NewUnitState.IsUnitAffectedByEffectName('BoaBindSustained')
		||	NewUnitState.IsUnitAffectedByEffectName('BindSustained')
		||	NewUnitState.IsUnitAffectedByEffectName('MZ_FDAdderRushAndBind_Crush')
		)
	{
		m_LocalYOffset = 125;	//shift whole flag down
	}
	else
	{
		m_LocalYOffset = 0;		//set to normal
	}
}

//=============================================================
//=============================================================
