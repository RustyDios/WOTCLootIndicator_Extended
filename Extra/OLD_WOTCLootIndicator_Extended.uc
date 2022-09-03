//=============================================================
//  FILE:   WOTCLootIndicator_Extended  by RustyDios
//  
//	File created	04/11/20    02:20
//	LAST UPDATED	13/07/22	10:30
//
//=============================================================

class WOTCLootIndicator_Extended extends UIUnitFlag dependson(XComGameState_Unit) config(WOTCLootIndicator_Extended);

struct StatsBlock
{
    var string BlockName;
    var string IconPath;
    var string HexColour;
    var ECharStatType Stat;
    var int bCanObsfucate;
    var name EventTriggerID;
};

struct StatBlockPair
{
	var UIIcon Icon;
	var UIText Text;
	var bool bStatShown;
};

struct SpecialColour
{
	var name TemplateName;
	var string HexColour;
	var bool bShowBigHead;

	structdefaultproperties
	{
		TemplateName = none ;
		HexColour = "ACD373";
		bShowBigHead = false;
	}
};

var config array<StatsBlock> StatsToShow;
var array<StatBlockPair> StatPairs;

var config array<name> BindEffects;
var config array<SpecialColour> SpecialColours;

var UIIcon DamageIcon, ShieldIcon, ArmorIcon, HudHeadIcon, LootIcon;
var UIText DamageText, ShieldText, ArmorText, NameText;

var config EWidgetColor eColour_WillBar;

var config bool bRustyUIFlagLog;
var config bool NAME_COLOR_BYTEAM, HPBAR_COLOR_BYTEAM, SHIELDBAR_COLOR_BYTEAM_FRIENDLIES, SHIELDBAR_COLOR_BYTEAM_ENEMIES, SHIELDBAR_COLOR_FROSTLEGION;
var config bool SHOW_LOOT, REQUIRE_SCANNING, SHOW_STATS_ON_FRIENDLY, SHOW_BARS_ON_FRIENDLY, SHOW_MAX_HP, SHOW_FRIENDLY_NAME, SHOW_ENEMY_NAME;
var config bool SHOW_MAX_Will, SHOW_PERCENT_WILL, SHOW_COVERSHIELD;
var config bool     SHOW_DAMAGE,    SHOW_ARMOR,     SHOW_SHIELD,    SHOW_WILL_BAR, SHOW_HUDHEAD, SHOW_RULERHEAD, SHOW_MOB_AS_TILES;
var config string   DAMAGE_COLOR,   ARMOR_COLOR,    SHIELD_COLOR,   NAME_COLOR, STAT_COLOR;

var config string HPBAR_COLORHEX_RULER_VIPER, HPBAR_COLORHEX_RULER_ZERKER, HPBAR_COLORHEX_RULER_ARCHON, HPBAR_COLORHEX_RULER_HIVE, SHIELDBAR_COLORHEX_FROSTLEGION;

var config int SHIELD_SHIFT_Y, ALIENRULER_SHIFT_Y, WILLBAR_SHIFT_Y, FOCUS_SHIFT_Y, HIDDENBARS_SHIFT_Y, BIND_SHIFT_Y;

var config int LOOT_OFFSET_X, STAT_OFFSET_X, NAME_OFFSET_X; 
var config int LOOT_OFFSET_Y, STAT_OFFSET_Y, NAME_OFFSET_Y;

var config int NAME_FONT_SIZE, INFO_FONT_SIZE, INFO_ICON_SIZE;

var int StatAnchorX, StatAnchorY, RollingX;

var CachedInt  m_BreakthroughBonuses, m_NumberOfShownStats;
var CachedBool	m_BreakthroughBonusesFound, m_bThisIsAnObject, m_bObfuscate;

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
	m_NumberOfShownStats = new class'CachedInt';

	InitPanel();

	History = `XCOMHISTORY;
	
	StoredObjectID = ObjectRef.ObjectID; 

	UpdateFriendlyStatus();

	m_bIsDead = false;
	m_iMovePipsTouched = 0;

	// Destructible hit points are stored on the actor and updated by environment damage effects
	DestructibleActor = XComDestructibleActor(History.GetVisualizer(StoredObjectID));
	if (DestructibleActor != none)
	{
		m_bThisIsAnObject.SetValue(true);
		`LOG("OBJECT WAS A DESTRUCTIBLE",default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

	if( XComGameState_Destructible(History.GetGameStateForObjectID(StoredObjectID)) != none
	 	&& History.GetGameStateComponentForObjectID(StoredObjectID, class'XComGameState_ObjectiveInfo') == none 
		&& DestructibleActor != none && DestructibleActor.TotalHealth <= 1)
	{
		Hide();
		`LOG("OBJECT WAS DESTRUCTIBLE WITH <=1 HEALTH, UIFLAG HIDDEN",default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}

}

simulated function OnTextSizeRealized()
{
	//<> TODO : CODE A FUNCTION HERE USING XYM'S NOTES THAT WILL SHOW THE ICONS ONLY AFTER THE SIZE IS READY
	//	ALSO REQUIRES ALL STATS ICONS/TEXT TO BE SPAWNED IN INITFLAG
	
	//TryUpdateLayout();

	LoopStatPairsToShow();

    `LOG("TextSize Realized called. ROLLING X: " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
}

simulated function LoopStatPairsToShow()
{
	local int i,z;

	Hide();	i = 0;

	if (m_NumberOfShownStats.GetValue() < StatsToShow.length)
	{

		`LOG("value[" @m_NumberOfShownStats.GetValue()  @"] stats [" @StatsToShow.length @"]",,'look here');
	
		for (z = 0 ; z < StatsToShow.length ; z++)
		{
			if (StatPairs[z].bStatShown && StatPairs[z].Text.TextSizeRealized)
			{
				StatPairs[z].Text.Show();
				StatPairs[z].Icon.Show();
				i-- ;

				//add value to the unitflags cached bonus
				m_NumberOfShownStats.SetValue( m_NumberOfShownStats.GetValue() + 1);
			}
			else if (!StatPairs[z].bStatShown || !StatPairs[z].Text.TextSizeRealized)
			{
				StatPairs[z].Text.Hide();
				StatPairs[z].Icon.Hide();
				i++ ;
			}

			`LOG("wut[" @i @"]" @StatPairs[z].bStatShown,,'look here');
		}
	}
	else if (m_NumberOfShownStats.GetValue() == StatsToShow.length)
	{
		//add value to the unitflags cached bonus
		m_NumberOfShownStats.SetValue( m_NumberOfShownStats.GetValue() + 42);

		class'WorldInfo'.static.GetWorldInfo().ConsoleCommand("UISetAllUnitFlagHitPoints True 0 0");
		Show();
		`LOG("we done this as well",,'look here');
	}

    `LOG("LOOP STAT PAIRS TO SHOW CALLED", default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_LOOPSTATS');
}

//----------------------------------------------------------------------------
//  Called from the UIUnitFlagManager's OnTick
simulated function Update(XGUnit kNewActiveUnit)
{
	super.Update(kNewActiveUnit);

	LoopStatPairsToShow();
}

//function UpdateValues ()
//{
//  Text1.SetHtmlText(/**/);
//  Text2.SetHtmlText(/**/);
// 
//  TryUpdateLayout();
//}

//function TryUpdateLayout ()
//{
//  if (!Text1.TextSizeRealized) return;
//  if (!Text2.TextSizeRealized) return;
//
//  Text2.SetX(Text1.X + Text1.Width + 4);
//}


//==================================================================
//	MAIN PART OF THE MOD -- THE HEALTH BAR AND ALL DISPLAYED STATS
//==================================================================

simulated function SetHitPoints( int _currentHP, int _maxHP )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentHP, maxHP, iMultiplier;
	local XComGameState_Unit UnitState;
	local float WillPercent;
	local SpecialColour SetSpecialColour;

	//local bool bStatShown;
	//local XComDestructibleActor DestructibleActor;

	local LWTuple	Tuple, NSLWTuple;
    local int i,j,z;

	iMultiplier = `GAMECORE.HP_PER_TICK;
	//bStatShown = false;

	//MOVED CHECK TO INIT, DID IT REALLY NEED TO HAPPEN EVERY HP UPDATE?
	/*DestructibleActor = XComDestructibleActor(History.GetVisualizer(StoredObjectID));
	if (DestructibleActor != none)
	{
		m_bThisIsAnObject.SetValue(true);
		`LOG("OBJECT WAS A DESTRUCTIBLE",default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
	}*/

	// DEAD - REMOVE HITPOINTS AND UNIT FLAG, NO LONGER REQUIRED
	if ( _currentHP < 1 )
	{
		m_bIsDead = true;
		`LOG("UNIT/OBJECT WAS DEAD, UNIT FLAG REMOVED",default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
		Remove();
	}
	else
	{
		//set up intial values
        RollingX = 0;
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
		
			m_currentHitPoints.SetValue(currentHP);
			m_maxHitPoints.SetValue(maxHP);

			myValue.Type = AS_Number;
			myValue.n = m_currentHitPoints.GetValue();
			myArray.AddItem(myValue);
			myValue.n = m_maxHitPoints.GetValue();
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
			//thus a query to !m_bObfuscate (not hide) will be true later
			//stats obfuscated get the text filled in as ##
			//obfuscated stats are the same ones hidden in YAF1 -- damage, aim, mobility, will, hack, dodge, psi ... leaving HP, DEF, Shields and Armor .. now config editable
			//yes this needs to check every update as conditions may have changed
			m_bObfuscate.SetValue(!Tuple.Data[1].b);	
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			`LOG("IS UNIT FLAG OBFUSCATED ::" @m_bObfuscate.GetValue(), default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');

			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			// allow mods to change the shown string for a stats config entry
			//	SENT FROM WOTCLootIndicator_Extended.UC
			//		UI Unit Flag Extended
			NSLWTuple = new class'LWTuple';
			NSLWTuple.Id = 'UIUnitFlag_AddDisplayInfo';
			NSLWTuple.Data.Add(1);

				// What the info should be
			NSLWTuple.Data[0].kind = LWTVString;
			NSLWTuple.Data[0].s = "";

			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			//show the loot indicator if it is an enemy AND does not require scanning OR scanned, battlescanned or reaper targeted
			if ( default.SHOW_LOOT && !m_bIsFriendly.GetValue() && !m_bThisIsAnObject.GetValue() &&
				( !default.REQUIRE_SCANNING || UnitState.IsUnitAffectedByEffectName('ScanningProtocol') || UnitState.IsUnitAffectedByEffectName('TargetDefinition')
				) )
			{
				if ( LootIcon == none )
				{
					LootIcon = Spawn(class'UIIcon', self);
					LootIcon.bDisableSelectionBrackets = true;
					LootIcon.bAnimateOnInit = false;
					LootIcon.bIsNavigable = false;
					LootIcon.InitIcon('RustyLootIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Loot",false,false,default.INFO_ICON_SIZE);

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
						DamageIcon = Spawn(class'UIIcon', self);
						DamageIcon.bDisableSelectionBrackets = true;
						DamageIcon.bAnimateOnInit = false;
						DamageIcon.bIsNavigable = false;
						DamageIcon.InitIcon('RustyDamageIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Damage",false,false,default.INFO_ICON_SIZE);
						DamageIcon.SetX(StatAnchorX + RollingX );
						DamageIcon.SetY(StatAnchorY + GetYShift());
					}

                    if (DamageIcon != none)
                    {
                        RollingX += DamageIcon.Width + 2;
                        `LOG("+DamageIconWidth (" @DamageIcon.Width @") +2 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
                    }

					if ( DamageText == none ) 
					{
						DamageText = Spawn(class'UIText', self);
						DamageText.bAnimateOnInit = false;
						DamageText.bIsNavigable = false;
						DamageText.InitText('RustyDamageText');
						DamageText.SetX(StatAnchorX + RollingX );
						DamageText.SetY(StatAnchorY + GetYShift());						
					}

					if ( DamageText != none  ) 
					{
						//damage text returns as max damage if min-max is equal, --- if both are 0 and x-y if a range
						//respects weapon breakthrough bonuses
						if (!m_bObfuscate.GetValue() )
						{
							DamageText.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo( AddStrColor(GetDamageString(UnitState) 
							, default.DAMAGE_COLOR)
							,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
						}
						else
						{
							DamageText.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo( AddStrColor("#-#" 
							, default.DAMAGE_COLOR)
							,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
						}

						AddShadowToTextField(DamageText);

                        RollingX += DamageText.Width + 4;
                        `LOG("+DamageTextWidth (" @DamageText.Width @") +4 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
                    }
				}

                // ===== CONFIGUREABLE STAT ENTRIES ===== 
				StatPairs.length = StatsToShow.length;

				//spawn an icon and text for each added stat - initially hide them
                for (i = 0 ; i < StatsToShow.length ; i++)
                {
                    if (StatPairs[i].Icon == none)
					{
						StatPairs[i].Icon = Spawn(class'UIIcon', self);
					   	StatPairs[i].Icon.bDisableSelectionBrackets = true;
						StatPairs[i].Icon.bAnimateOnInit = false;
						StatPairs[i].Icon.bIsNavigable = false;
						StatPairs[i].Icon.InitIcon(name(StatsToShow[i].BlockName $"_Icon"),"img:///" $StatsToShow[i].IconPath,false,false,default.INFO_ICON_SIZE);
						StatPairs[i].Icon.Hide();
					}

                    if (StatPairs[i].Text == none)
					{
						StatPairs[i].Text = Spawn(class'UIText', self);
						StatPairs[i].Text.bAnimateOnInit = false;
						StatPairs[i].Text.bIsNavigable = false;
						StatPairs[i].Text.InitText(name(StatsToShow[i].BlockName $"_Text"));
						StatPairs[i].Text.Hide();
					}

					StatPairs[i].bStatShown = false;

					`LOG("Stats Pair ADDED :" @StatsToShow[i].BlockName, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
                }

				//go over the stats and if they should be shown, for this unit type, set the text and show them
                for (j = 0 ; j < StatsToShow.length ; j++)
                {
					StatPairs[j].bStatShown = false; //reset for loop, helps for updating rollingX and positions

					//HIDE BY DEFAULT - SHOULD BE ALREADY HIDDEN ON SPAWN
					StatPairs[j].Icon.Hide();
					StatPairs[j].Text.Hide();

                    //STAT HAS AN ASSOCIATED EVENT FROM ANOTHER MOD, SO GO INFO SEEKING ON EVENT FOR TEXT STRING
					//MADE BY REQUEST FOR THE AWESOME NOTSOLONEWOLF
                    if (StatsToShow[j].EventTriggerID != '')
                    {
                        `XEVENTMGR.TriggerEvent(StatsToShow[j].EventTriggerID, NSLWTuple, UnitState );

						//STAT CAN BE OBFUSCATED AND OBFUSCATION ON AND THIS ISN'T AN OBJECT
                        if (StatsToShow[j].bCanObsfucate > 0 && m_bObfuscate.GetValue() && !m_bThisIsAnObject.GetValue() )
                        {
                            StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor("##", StatsToShow[j].HexColour)
								,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
							StatPairs[j].bStatShown = true;
                        }
						//STAT CANNOT BE OBFUSCATED || OBFUSCATION NOT ON && NOT AN OBJECT
                        else if (!m_bThisIsAnObject.GetValue() )
                        {
                            StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(NSLWTuple.Data[0].s, StatsToShow[j].HexColour)
								,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
							StatPairs[j].bStatShown = true;
                        }
                    }
                    //STAT CAN BE OBFUSCATED AND OBFUSCATION ON AND THIS ISN'T AN OBJECT
                    else if (StatsToShow[j].bCanObsfucate > 0 && m_bObfuscate.GetValue() && !m_bThisIsAnObject.GetValue() )
                    {
                        StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor("##", StatsToShow[j].HexColour)
								,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
						StatPairs[j].bStatShown = true;
					}
                    //STAT CANNOT BE OBFUSCATED || OBFUSCATION NOT ON ... IE CASES NOT COVERED ABOVE
                    else
                    {
                        switch (StatsToShow[j].Stat)
                        {
							//PRETTY SURE I DO CATCH EVERYTHING HERE, MIGHT HAVE BEEN BETTER AS THE DEFAULT OPTION, BUT I WANT THAT FOR ERROR CHECKING THE UNKNOWN
                            case eStat_Offense:
                            case eStat_Defense:
                            case eStat_Dodge:
                            case eStat_Hacking:
                            case eStat_PsiOffense:
							case eStat_ShieldHP:
							case eStat_ArmorMitigation:
							case eStat_ArmorChance:
							case eStat_ArmorPiercing:
							case eStat_CritChance:
							case eStat_FlankingCritChance:
							case eStat_FlankingAimBonus:
							case eStat_DetectionRadius:
							case eStat_SightRadius:
                                //standard stat values with no special handling, if its not an object, show the stat
                                if (!m_bThisIsAnObject.GetValue())
                                {
                                    StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(string(int(UnitState.GetCurrentStat(StatsToShow[j].Stat)))
										, StatsToShow[j].HexColour)
										,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
									StatPairs[j].bStatShown = true;
								}
								break;
                            case eStat_Mobility:
                                //mobility has special handling for display as meters/tiles, if its not an object
                                if (!m_bThisIsAnObject.GetValue()) 
                                {
									StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(string(int(
										default.SHOW_MOB_AS_TILES ? UnitState.GetCurrentStat(StatsToShow[j].Stat) / 1.5 : UnitState.GetCurrentStat(StatsToShow[j].Stat)))
										, StatsToShow[j].HexColour)
										,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );

									StatPairs[j].bStatShown = true;
								}
								break;
							case eStat_Will:
                                //Will has special handling for current/max, or percentage display, if its not an object /*and uses the will system*/ - removed if uses, does allow enemies
								if (!m_bThisIsAnObject.GetValue()) // && m_bUsesWillSystem) 
                                {
									if (default.SHOW_MAX_Will)
									{
										StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(string(int(
											UnitState.GetCurrentStat(StatsToShow[j].Stat))) $"/" $string(int(UnitState.GetMaxStat(StatsToShow[j].Stat)))
											, StatsToShow[j].HexColour)
											,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
									}
									else if (default.SHOW_PERCENT_WILL)
									{
										//(value/total value)×100%
										WillPercent = ( UnitState.GetCurrentStat(StatsToShow[j].Stat) / UnitState.GetMaxStat(StatsToShow[j].Stat) ) * 100;

										StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(string(int(WillPercent)) $"%"
											, StatsToShow[j].HexColour)
											,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
									}
									else
									{
										StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(string(int(UnitState.GetCurrentStat(StatsToShow[j].Stat)))
											, StatsToShow[j].HexColour)
											,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
									}
									StatPairs[j].bStatShown = true;
								}
								break;
                            case eStat_HP:
                                //HP has special handling for current/max, display -- and display even if it is an object!
								StatPairs[j].Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(
									default.SHOW_MAX_HP ? _currentHP $ "/" $ _maxHP : _currentHP $ ""
									, StatsToShow[j].HexColour)
									,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );

								StatPairs[j].bStatShown = true;
								break;
                            default:
                                //anything we can't recognise? break for safety
								`LOG("UNIDENTIFIED STAT TYPE PASSED TO SWITCHBLOCK :" @StatsToShow[j].Stat, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
                                break;

                        } // end switch

                    } // end //STAT CANNOT BE OBFUSCATED || OBFUSCATION NOT ON

					//UPDATE ROLLING X AND SET POSITIONS, UPDATE TEXT COLOURS IF STAT PAIR SHOWN
					if (StatPairs[j].bStatShown)
					{
						StatPairs[j].Icon.SetX(StatAnchorX + RollingX );
						StatPairs[j].Icon.SetY(StatAnchorY + GetYShift());

							RollingX += StatPairs[j].Icon.Width + 2;
							`LOG("+NewIconWidth (" @StatPairs[j].Icon.Width @") +2 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');

						StatPairs[j].Text.SetX(StatAnchorX + RollingX );
						StatPairs[j].Text.SetY(StatAnchorY + GetYShift());
						//StatPairs[j].Text.SetColor(StatsToShow[j].HexColour);

							RollingX += StatPairs[j].Text.Width + 4;
							`LOG("+NewTextWidth (" @StatPairs[j].Text.Width @") +4 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
					}

                } //end stats to show loop

				//now all stats have been set and positions are known, loop again to show them - fixes the crunch up on mission load
				for (z = 0 ; z < StatsToShow.length ; z++)
				{
					if (StatPairs[z].bStatShown && StatPairs[z].Text.TextSizeRealized)
					{
						AddShadowToTextField(StatPairs[z].Text);
						StatPairs[z].Text.Show();
						StatPairs[z].Icon.Show();
					}
				}

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
			ColourRulerHealthBar("ACD373", default.SHOW_RULERHEAD );	//set ruler colour
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
		/*switch (UnitState.GetMyTemplateName())
		{
			case 'ViperKing':
			case 'ViperPrince1':
			case 'ViperPrince2':
			case 'ViperPrince3':
			case 'ViperPrincess':
				ColourRulerHealthBar(default.HPBAR_COLORHEX_RULER_VIPER,	default.SHOW_RULERHEAD);		break;
			case 'BerserkerQueen':
				ColourRulerHealthBar(default.HPBAR_COLORHEX_RULER_ZERKER,	default.SHOW_RULERHEAD);		break;
			case 'ArchonKing':
				ColourRulerHealthBar(default.HPBAR_COLORHEX_RULER_ARCHON,	default.SHOW_RULERHEAD);		break;
			case 'CXQueen':
				ColourRulerHealthBar(default.HPBAR_COLORHEX_RULER_HIVE,		default.SHOW_RULERHEAD);		break;
			case 'AdvPsiWitchM2':
			case 'AdvPsiWitchM3':
				AS_SetMCColor(MCPath $".healthMeter.theMeter", "B6B3E3");	break; //set Avatar colour
			default:
				break;
		}*/

		//direct overrides per set template name - moved to config
		foreach default.SpecialColours(SetSpecialColour)
		{
			if (UnitState.GetMyTemplateName() == SetSpecialColour.TemplateName)
			{
				ColourRulerHealthBar(SetSpecialColour.HexColour, SetSpecialColour.bShowBigHead);
				continue; //break out of for loop, we found 'us'
			}
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

	AS_SetMCColor	(MCPath $".healthMeter.theMeter", HEXCOLOUR);	//set ruler colour

	fTotalHealthBars = Movie.GetVariableNumber(MCPath $ ".MeterTotal");
	for (i = 0 ; i < fTotalHealthBars ; i++)
	{
		AS_SetMCColor(MCPath $".healthMeter.healthMeter" $ i $ ".theMeter", HEXCOLOUR);	//set ruler colour, takes care of 'the health array extra lines' to colour to this colour
	}

	i = 0;
	MC.ChildSetBool ("specialAlienIcon","_visible", Show_BIGHEAD);
}

//==================================================================
//	SECONDARY PART OF THE MOD -- THE SHIELD BAR (AND STAT SHIFTING)
//==================================================================

simulated function SetShieldPoints( int _currentShields, int _maxShields )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentShields, maxShields, iMultiplier;
	local XComGameState_Unit UnitState;
	local SpecialColour SetSpecialColour;

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
				ShieldIcon = Spawn(class'UIIcon', self);
				ShieldIcon.bDisableSelectionBrackets = true;
				ShieldIcon.bAnimateOnInit = false;
				ShieldIcon.bIsNavigable = false;
				ShieldIcon.InitIcon('RustyShieldIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Shield2",false,false,default.INFO_ICON_SIZE);
				ShieldIcon.SetX(StatAnchorX + RollingX );
				ShieldIcon.SetY(StatAnchorY + GetYShift());
			}

            if (ShieldIcon != none)
            {
				ShieldIcon.SetX(StatAnchorX + RollingX );
                RollingX += ShieldIcon.Width + 2;
                `LOG("+ShieldIconWidth (" @ShieldIcon.Width @") +2 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
            }

			if ( ShieldText == none ) 
			{
				ShieldText = Spawn(class'UIText', self);
				ShieldText.InitText('RustyShieldText');
				ShieldText.SetX(StatAnchorX + RollingX);
				ShieldText.SetY(StatAnchorY + GetYShift());
			}

			if (ShieldText != none)
			{
				ShieldText.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(
					_currentShields > 0 ? string(_currentShields) : "--"
					, default.SHIELD_COLOR)
					,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );

				AddShadowToTextField(ShieldText);

				ShieldText.SetX(StatAnchorX + RollingX);
				RollingX += ShieldText.Width + 4;
				`LOG("+ShieldTextWidth (" @ShieldText.Width @") +4 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
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
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "ACD373");	//set ruler colour
		}
		else if (UnitState.IsChosen())
		{
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "B6B3E3");	//set chosen colour, yes base flash has them set to psionic, this needs to repeat this
		}
		else if ( default.SHIELDBAR_COLOR_FROSTLEGION && UnitState.HasAbilityFromAnySource('MZ_FDIceShield') )
		{
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", default.SHIELDBAR_COLORHEX_FROSTLEGION);	//set as 'frosty' shield colour for the Frost Legion Dudes
		}
		else 
		{
			AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", class'UIUtilities_Colors'.static.GetHexColorFromState(FindHudHeadColour() )); //set team colour
		}

		//direct overrides per set template name
		/*switch (UnitState.GetMyTemplateName())
		{
			case 'ViperKing':
			case 'ViperPrince1':
			case 'ViperPrince2':
			case 'ViperPrince3':
			case 'ViperPrincess':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", default.HPBAR_COLORHEX_RULER_VIPER	);	break; //set ruler colour viper
			case 'BerserkerQueen':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", default.HPBAR_COLORHEX_RULER_ZERKER	);	break; //set ruler colour zerker
			case 'ArchonKing':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", default.HPBAR_COLORHEX_RULER_ARCHON	);	break; //set ruler colour archon
			case 'CXQueen':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", default.HPBAR_COLORHEX_RULER_HIVE	);	break; //set ruler colour hive
			case 'AdvPsiWitchM2':
			case 'AdvPsiWitchM3':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "B6B3E3"						);	break; //set Avatar colour
			default:
				break;
		}*/

		//direct overrides per set template name - moved to config
		foreach default.SpecialColours(SetSpecialColour)
		{
			if (UnitState.GetMyTemplateName() == SetSpecialColour.TemplateName)
			{
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", SetSpecialColour.HexColour ); //set custom colour
				continue; //break out of for loop, we found 'us'
			}
		}
	}
	
	//=====================================//
	//	CHANGE THE BAR COLOURS - FRIENDLY  //
	//=====================================//

	if ( default.SHIELDBAR_COLOR_BYTEAM_FRIENDLIES && m_bIsFriendly.GetValue() )
	{
		AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", class'UIUtilities_Colors'.static.GetHexColorFromState(FindHudHeadColour() )); //set team colour

		//direct overrides per set template name
		/*switch (UnitState.GetMyTemplateName())
		{
			case 'AdvPsiWitchM2':
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", "B6B3E3" );	break; //set Avatar colour
			default:
				break;
		}*/

		//direct overrides per set template name - moved to config
		foreach default.SpecialColours(SetSpecialColour)
		{
			if (UnitState.GetMyTemplateName() == SetSpecialColour.TemplateName)
			{
				AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", SetSpecialColour.HexColour ); //set custom colour
				continue; //break out of for loop, we found 'us'
			}
		}

	}

	// Disable hitpoints preview visualization - sbatista 6/24/2013
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

		m_armorPoints.SetValue(currentArmor);

		myValue.Type = AS_Number;
		myValue.n = currentArmor;
		myArray.AddItem( myValue );	

		// ===== ARMOUR =====
		if ( default.SHOW_ARMOR && !m_bThisIsAnObject.GetValue() )
		{
			if ( ArmorIcon == none )
			{
				ArmorIcon = Spawn(class'UIIcon', self);
				ArmorIcon.bDisableSelectionBrackets = true;
				ArmorIcon.bAnimateOnInit = false;
				ArmorIcon.bIsNavigable = false;
				ArmorIcon.InitIcon('RustyArmorIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Armour2",false,false,default.INFO_ICON_SIZE);
				ArmorIcon.SetX(StatAnchorX + RollingX);
				ArmorIcon.SetY(StatAnchorY + GetYShift());
			}

            if (ArmorIcon != none)
            {
				ArmorIcon.SetX(StatAnchorX + RollingX);
                RollingX += ArmorIcon.Width + 2;
                `LOG("+ArmorIconWidth (" @ArmorIcon.Width @") +2 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
            }

			if ( ArmorText == none ) 
			{
				ArmorText = Spawn(class'UIText', self);
				ArmorText.InitText('RustyArmorText');
				ArmorText.SetX(StatAnchorX + RollingX);
				ArmorText.SetY(StatAnchorY + GetYShift());
			}

			if ( ArmorText != none)
			{
				ArmorText.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(
					_iArmor > 0 ? string(_iArmor) : "--"
					, default.ARMOR_COLOR)
					,false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );

				AddShadowToTextField(ArmorText);

				ArmorText.SetX(StatAnchorX + RollingX);
				RollingX += ArmorText.Width + 4;
				`LOG("+ArmorTextWidth (" @ArmorText.Width @") +4 : = " @RollingX, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG_ROLLINGX');
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

//============================================================================================================
/*
	WE THEN HAVE A BUNCH OF STUFF SET EVEN LOWER DOWN
	OFFENSE ARROWS	DEFENSE ARROWS	RANK	MOVES			COVERSHIELD
	SELECTED	TARGETED	ALERTED	SPOTTED
	HOLDING MISSION ITEM	HOLDING OBJECTIVE ITEM
	CONCEALMENT		OVERWATCH EYE	CLAYMORE	STATUS ICON (ONLY ONE AT A TIME !)	RUPTURE ICON	BINDED	
*/
//============================================================================================================

//==================================================================//
// -- SHIELD SHIFT BUMP NOW TAKES INTO ACCOUNT THE CHL FOCUS BAR -- //
//==================================================================//

//==================================================================
// function for calculating the shift values and setting correctly
//==================================================================

simulated function RefreshShiftPositions()
{
    local int i;

	if ( LootIcon != none ) 	{ LootIcon.SetY(default.LOOT_OFFSET_Y);					}	//NOTE LOOT INDICATOR DOES NOT GET BUMPED UP ... IN THE LIST FOR CONSISTENCY
	
    if ( DamageIcon != none ) 	{ DamageIcon.SetY(StatAnchorY + GetYShift());			}
	if ( DamageText != none ) 	{ DamageText.SetY(StatAnchorY + GetYShift());			}

    //loop through the config setstats
    for (i = 0 ; i < StatPairs.length ; i++)
    {
        StatPairs[i].Icon.SetY(StatAnchorY + GetYShift());
        StatPairs[i].Text.SetY(StatAnchorY + GetYShift());
    }

	if ( ShieldIcon != none ) 	{ ShieldIcon.SetY(StatAnchorY + GetYShift()); 			}	// ADDED BY RUSTY	
	if ( ShieldText != none ) 	{ ShieldText.SetY(StatAnchorY + GetYShift()); 			}
	
    if ( ArmorIcon != none ) 	{ ArmorIcon.SetY(StatAnchorY + GetYShift());			}	// ADDED BY RUSTY
	if ( ArmorText != none ) 	{ ArmorText.SetY(StatAnchorY + GetYShift()); 			}

	if ( HudHeadIcon != none)	{ HudHeadIcon.SetY(default.NAME_OFFSET_Y + GetYShift());}	// ADDED BY RUSTY
	if ( NameText != none ) 	{ NameText.SetY(default.NAME_OFFSET_Y + GetYShift());	}

	LoopStatPairsToShow();

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

	//if primary is a bust attempt to get secondary - should fix 'primary melee' users like lids and faceless
	if (WeaponState == none)
	{
		WeaponState = UnitState.GetSecondaryWeapon();
	}

	//if weapon is still bust, bail
	if (WeaponState != none)
	{
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
	
	//still couldn't find a weapon state
	return "---";
}

//=================================================//
// ===== NAME ROW, ON TOP OF EVERYTHING ELSE ===== //
//=================================================//

simulated function SetNames( string unitName, string unitNickName )
{
	local string ThisName, IconString, IconColour;
	
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
			HudHeadIcon.bAnimateOnInit = false;
			HudHeadIcon.bIsNavigable = false;
			HudHeadIcon.bDisableSelectionBrackets = true;
			HudHeadIcon.InitIcon(,,false,true, default.INFO_ICON_SIZE); //'RustyHudHeadIcon'
			HudHeadIcon.SetX(default.NAME_OFFSET_X);
			HudHeadIcon.SetY(default.NAME_OFFSET_Y + GetYShift());

			FindHUDHeadIcon(IconString, IconColour );
			
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
			NameText = Spawn(class'UIText', self);
			NameText.InitText('RustyNameText');
			
			AddShadowToTextField(NameText);

			if (HudHeadIcon != none)
			{
				NameText.SetX(default.NAME_OFFSET_X + default.INFO_ICON_SIZE);
			}
			else
			{
				NameText.SetX(default.NAME_OFFSET_X);
			}

			NameText.SetY(default.NAME_OFFSET_Y -4 + GetYShift());

			NameText.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(AddStrColor(ThisName,
				default.NAME_COLOR_BYTEAM ? class'UIUtilities_Colors'.static.GetHexColorFromState(FindHudHeadColour() ) : default.NAME_COLOR )
				,false,false,false,default.NAME_FONT_SIZE));
		}
	}

	//CHECK AND REFRESH SHIFT POSITIONS
	RefreshShiftPositions();
	`LOG("REFRESH SHIFT POSITION DONE BY NAME ::" @ThisName, default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');

}

//======================================================================================
// GET TARGET ICON ... COMPRISED OF TWO PARTS THE FOREGROUND OUTLINE AND THE BG SOLID
//======================================================================================
simulated function FindHUDIconDetails(out string strIcon, out eUIState iColourState)
{
	local XComGameState_Unit UnitState;
	local X2VisualizerInterface Visualizer;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	Visualizer = X2VisualizerInterface(UnitState.GetVisualizer());

	strFG = Visualizer.GetMyHUDIcon();
	iColourState = Visualizer.GetMyHUDIconColor();

}

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

/////////////////////////////////////////////////////////////////////////////////////////////
//	HANDLE DISPLAY OF THE UI	TO COLOUR, OUTLINE AND SHADOW THE TEXT
// 	This is a UnrealScript translation from the original ActionScript function. 
//	From Components.SwfMoview within 'scripts/__Packages/Utilities', in gfxComponents.upk.
// 	Usage: Call this with your UIText element AFTER you've called InitText() on it!
//
//		var UIText Text;
//
//		Text = Spawn(class'UIText', self);
//		Text.InitText('');
//		Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(
//			AddStrColor("STRING", HexColour),false,false,false,default.INFO_FONT_SIZE), OnTextSizeRealized );
//		AddShadowToTextField(Text);
//
/////////////////////////////////////////////////////////////////////////////////////////////

function string AddStrColor(string text, string clr)
{
	return "<font color='#" $ clr $ "'>" $ text $ "</font>";
}

static function AddShadowToTextField(UIText panel, 
	optional float STalpha = 0.75,	optional int STcolor = 656896, 
	optional int STblurX = 2,		optional int STblurY = 2,
	optional int STstrength = 15,	optional int STangle = 0,	optional int STdistance = 0 )
{
	local string path;
	local UIMovie mov;

	path = string(panel.MCPath) $ ".text";
	mov = panel.Movie;

	mov.SetVariableString(path $ ".shadowStyle", "s{0,0}{0,0){0,0}t{0,0}");
	mov.SetVariableNumber(path $ ".shadowColor", STcolor); //3552822);
	mov.SetVariableNumber(path $ ".shadowBlurX", STblurX);
	mov.SetVariableNumber(path $ ".shadowBlurY", STblurY);
	mov.SetVariableNumber(path $ ".shadowStrength", STstrength);
	mov.SetVariableNumber(path $ ".shadowAngle", STangle);
	mov.SetVariableNumber(path $ ".shadowAlpha", STalpha);
	mov.SetVariableNumber(path $ ".shadowDistance", STdistance);
}

//===============================================================================================================
// THIS FUNCTION OFFSETS THE ENTIRE FLAG POSITION FOR UNITS UNDER VIPER BIND
// I EXTENDED IT TO ACCOUNT FOR UNITS THAT HAVE BEEN BOUND BY THE VIPER KING AND HOISTED BY THE ARCHON KING TOO
// ALSO EXTENDED TO ELITE VIPERS AND ABA VIPERS AND FROST LEGION VIPERS/ADDERS
// ARMOURED, VALENTINES AND FLAME VIPERS USE STANDARD BIND
//===============================================================================================================

simulated function RealizeViperBind(XComGameState_Unit NewUnitState)
{
	local name EffectName;
	local bool bIsBound;

	//const VIPER_BIND_OFFSET = 30; // 30 may have been fine for base game, but it's not for this with with all the extra stats and stuff
	//The unit flag for the unit being bound will overlap with the Viper's unit flag without an offset.
	//m_LocalYOffset = NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_Viper'.default.BindSustainedEffectName) ? VIPER_BIND_OFFSET : 0;

	foreach default.BindEffects (EffectName)
	{
		if (NewUnitState.AffectedByEffectNames.Find(EffectName) != INDEX_NONE)
		{
			bIsBound = true;
			break;
		}
	}

	// Shift the whole flag down if bound
	m_LocalYOffset = bIsBound ? default.BIND_SHIFT_Y : 0;

}

//=============================================================
//=============================================================

//=============================================================
// THIS FUNCTION CONTROLS THE COVER SHIELD OVERRIDDEN HERE SO
//	SO THAT CLIBANARIUS HAS A CONFIG OPTION TO HIDE IT
//=============================================================

simulated function RealizeCover(optional XComGameState_Unit UnitState = none, optional int HistoryIndex = INDEX_NONE)
{
	super.RealizeCover(UnitState, HistoryIndex);
	
	MC.ChildSetBool ("coverStatusObj","_visible", default.SHOW_COVERSHIELD);
}

//=============================================================
//=============================================================
