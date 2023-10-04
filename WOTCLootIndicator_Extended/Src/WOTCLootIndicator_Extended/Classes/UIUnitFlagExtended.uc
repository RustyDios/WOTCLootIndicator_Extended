//=============================================================
//  FILE:   UIUnitFlagExtended  by Xymanek && RustyDios
//  
//	File created	13/07/22	17:00
//	LAST UPDATED	04/10/23	06:15
//
//	<> TODO : Rework && Update Y Shift value correctly
//
//=============================================================

class UIUnitFlagExtended extends UIUnitFlag dependson(UnitFlagExtendedHelpers);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	GAME STATE CACHING
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var int LastHistoryIndex;
var bool bIsFullyInited;

enum EFlagObjectType
{
	eFOT_Invalid,
	eFOT_Unit,
	eFOT_Destructible,
	eFOT_DestructibleNoFlag,
};

var EFlagObjectType ObjectType;

var bool bObfuscate;

//used for the damage display
var int m_BreakthroughBonuses;
var bool m_BreakthroughBonusesFound, bWeaponChecked;

var CachedString HealthBarColour, ShieldBarColour, DamageString, ShredString, PierceString;
var CachedString HealthBarColourPreMC, ShieldBarColourPreMC;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	NEW UI ELEMENTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var UIIcon LootIcon, HudHeadIcon;
var UIText UnitNameText;

var UIPanel StatRowContainer;
var array<UIUnitFlagExtended_StatEntry> StatRowEntries;

var UIPanel ExtendedStatusRowContainer;
var array<UIIcon> StatusIcons;

var protected bool bLayoutRealizePending, bLootIndicatorScanned, bHealthBarCreated, bCheckAndSetHealthBarColour, bShieldBarCreated, bCheckAndSetShieldBarColour;

var string HUDIconString, HUDIconColour;
var bool bGotFrostShields, bFrostShieldsChecked;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	INIT
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function InitFlag (StateObjectReference ObjectRef)
{
	local XComDestructibleActor DestructibleActor;
	local XComGameState_Unit UnitState;
	local Object ThisObj;

	super.InitFlag(ObjectRef);

	HealthBarColour = new class'CachedString';	HealthBarColourPreMC = new class'CachedString';
	ShieldBarColour = new class'CachedString';	ShieldBarColourPreMC = new class'CachedString';

	DamageString	= new class'CachedString';
	ShredString		= new class'CachedString';
	PierceString 	= new class'CachedString';

	// Determine what we are representing
	DestructibleActor = XComDestructibleActor(History.GetVisualizer(StoredObjectID));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));

	if (DestructibleActor != none)
	{
		if (XComGameState_Destructible(History.GetGameStateForObjectID(StoredObjectID)) != none
	 		&& History.GetGameStateComponentForObjectID(StoredObjectID, class'XComGameState_ObjectiveInfo') == none 
			&& DestructibleActor.TotalHealth <= 1 )
		{
			ObjectType = eFOT_DestructibleNoFlag;
			//Hide(); already hidden by super
		}
		else
		{
			ObjectType = eFOT_Destructible;
		}
	}
	else if ( UnitState != none)
	{
		ObjectType = eFOT_Unit;
		
		//if we are a unit register for mind control/team swapping so we can update health/shield bar colours correctly
		//make sure we filter this this to 'our' unit by callback object, else it'll trigger for all flags everywhere
		ThisObj = self;
		`XEVENTMGR.RegisterForEvent(ThisObj, 'UnitChangedTeam', UnitChangedTeam_Listener, ELD_OnStateSubmitted, , UnitState);
	}

	//doing this once here instead of multiple times throughout the file
	//needs to be done after we determine what we are representing by ObjectType!
	HUDIconString = ""; HUDIconColour = "";
	FindHUDIconDetails(HUDIconString, HUDIconColour);

	//Initial Build of new UI elements
	BuildExtendedStatusRow();
	BuildLootIndicator();
	BuildNameRow();
	BuildStatsRow();
}

simulated function OnInit ()
{
	super.OnInit();

	OnComponentPanelInited(self);
}

// Extracted from super.OnInit(), this gets delayed until everything is ready
simulated protected function DoInitialUpdate ()
{
	local XComGameState_BaseObject StartingState;

	VisualizedHistoryIndex = `XCOMVISUALIZATIONMGR.LastStateHistoryVisualized;
	StartingState = History.GetGameStateForObjectID(StoredObjectID, , VisualizedHistoryIndex);

	UpdateFromState(StartingState, true, true);

}

simulated function Remove()
{
	local Object ThisObj;

	//make sure we unregister from events if we registered, dang garbage collection issues ..
	if (ObjectType == eFOT_Unit)
	{
		ThisObj = self;
		`XEVENTMGR.UnRegisterFromEvent(ThisObj, 'UnitChangedTeam');
	}

	super.Remove();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	REFRESH/UPDATES
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//this ELR should be called when our stored unit changes teams, this updates our hud colours
//triggered from XCGS_Unit SetControllingPlayer, after a team swap has actually happened
function EventListenerReturn UnitChangedTeam_Listener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState NewGameState;

	NewUnitState = XComGameState_Unit(EventData); //Data and Source are both the same

	if (NewUnitState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TeamChange UnitFlag Respond");
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', NewUnitState.ObjectID));

		RespondToNewGameState(NewGameState, true);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TeamChange UnitFlag Colours");
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', NewUnitState.ObjectID));

		//YES! THIS LOGIC SEEMS BACKWARDS, BUT IT IS CORRECT! IS MC = NOT ON ORIGINAL TEAMS
		if(NewUnitState.IsMindControlled())
		{
			HealthBarColourPreMC.SetValue(HealthBarColour.GetValue());
			ShieldBarColourPreMC.setValue(ShieldBarColour.GetValue());
		}
		else
		{
			//ForceBarColours(HealthBarColourPreMC.GetValue(), ShieldBarColourPreMC.GetValue() );

			//FORCE THE COLOURS TO CHANGE AND RESET ...
			HealthBarColour.SetValue("696969");	HealthBarColour.SetValue(HealthBarColourPreMC.GetValue());
			ShieldBarColour.setValue("696969");	ShieldBarColour.setValue(ShieldBarColourPreMC.GetValue());

			UpdateBarColours_Health(NewUnitState);
			UpdateBarColours_Shield(NewUnitState);
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

// This function might get called before object is ready to rock and roll. has a !bIsInited return
simulated function SetSelected(bool isSelected)
{
	// Expanded version of the same check as in super
	if (!IsFullyInited()) return;

	super.SetSelected(isSelected);
}

// This function might get called before object is ready to rock and roll. has a !bIsInited return
//the manager responds to a game state before on init is called on this flag in a replay or a tutorial.
//do not allow calls too early, because unit flag uses direct invoke which results in bad calls pre-init 
simulated function RespondToNewGameState(XComGameState NewState, bool bForceUpdate = false)
{
	local XComGameState_BaseObject ObjectState;
	local int HistoryIndex;

	// Expanded version of the same check as in super
	if (!IsFullyInited()) return;

	//NOT calling super so we can optimise behind LastHistoryIndex
	//super.RespondToNewGameState(NewState,bForceUpdate);

	if (bForceUpdate || bIsVisible)
	{
		//ENSURE WE HAVE AN OBJECT STATE
		if( NewState != None ) 	{ ObjectState = NewState.GetGameStateForObjectID(StoredObjectID); 	}
		else					{ ObjectState = History.GetGameStateForObjectID(StoredObjectID);	}

		//WE HAVE AN OBJECT (UNIT/DESTRUCTABLE) AND ITS VISIBLE/FORCED UPDATE
		if( ObjectState != None )
		{
			//ENSURE WE GET THE HISTORY INDEX FROM THE OBJECT
			HistoryIndex = ObjectState.GetParentGameState().HistoryIndex;

			//UPDATE ONLY IF NEW
			if (LastHistoryIndex < HistoryIndex)
			{
				LastHistoryIndex = HistoryIndex;
				VisualizedHistoryIndex = HistoryIndex;
				UpdateFromState(ObjectState, , bForceUpdate);
			}
		}
	}
}

//  Called from the UIUnitFlagManager's OnTick
simulated function Update(XGUnit kNewActiveUnit)
{
	// Expanded version of the same check as in super
	// If not shown or ready, leave. has a !bIsInited return
	if (!IsFullyInited()) return;

	super.Update(kNewActiveUnit);

	//this checks if the colour bar(s) have been created yet .. once they have been created, set the colour correctly
	TrySetHealthBarColour();
	TrySetShieldBarColour();
}

simulated function UpdateFromState (XComGameState_BaseObject NewState, bool bInitialUpdate = false, bool bForceUpdate = false)
{
	// We can never obfuscate destructible stats.
	// If this is a unit, obfuscation may get enabled in UpdateFromUnitState before any of the values are actually updated
	bObfuscate = false;

	super.UpdateFromState(NewState, bInitialUpdate, bForceUpdate);

	// This refreshes the layout on a change from ShieldsHP or Focus
	RealizeExtendedLayout();
}

simulated function UpdateFromUnitState (XComGameState_Unit NewUnitState, bool bInitialUpdate = false, bool bForceUpdate = false)
{
	super.UpdateFromUnitState(NewUnitState, bInitialUpdate, bForceUpdate);

	if (bInitialUpdate || bForceUpdate)
	{
		UpdateBigAlienHead(NewUnitState);
		UpdateDamageString(NewUnitState);
	}

	UpdateLootIndicator(NewUnitState);
	UpdateNameRow(NewUnitState);

	//UpdateUnitDamageStat(NewUnitState);	//DEPRECIATED
	UpdateUnitStats(NewUnitState);

	UpdateBarColours_Health(NewUnitState);
	UpdateBarColours_Shield(NewUnitState);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	SET STATS - OVERRIDE VANILLA FUNCTIONS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function SetHitPoints (int _currentHP, int _maxHP)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentHP, maxHP, iMultiplier;

	//not calling super to avoid multiple flash invokes
	//super.SetHitPoints(_currentHP, _maxHP);

	//remove the Unit Flag on dead units
	if( _currentHP < 1 )
	{
		m_bIsDead = true;
		Remove();
		return;
	}

	iMultiplier = `GAMECORE.HP_PER_TICK;

	// Profile or config is set to hide health 
	if(    (!m_bIsFriendly.GetValue() && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth )
		|| ( m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_BARS_ON_FRIENDLY) )
	{
		m_currentHitPoints.SetValue(0);
		m_maxHitPoints.SetValue(0);
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
	}

	//only change the display if the value has been updated
	if( m_currentHitPoints.HasChanged() || m_maxHitPoints.HasChanged() )
	{
		myValue.Type = AS_Number;
		myValue.n = m_currentHitPoints.GetValue();		myArray.AddItem(myValue);
		myValue.n = m_maxHitPoints.GetValue();			myArray.AddItem(myValue);

		//invoke sends this to 'the flash queue'
		//this causes issues with colouring that the bar might not exist - we have had to fix it - thanks to Xymanek!
		Invoke("SetHitPoints", myArray);
	}

	// This handles both destructible and unit HP
	SetHealthStatEntry(_currentHP, _maxHP);
}

simulated function SetShieldPoints( int _currentShields, int _maxShields )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentShields, maxShields, iMultiplier;

	//not calling super to avoid multiple flash invokes
	//super.SetShieldPoints(_currentShields, _maxShields );

	iMultiplier = `GAMECORE.HP_PER_TICK;

	// Profile or config is set to hide health 
	if(    (!m_bIsFriendly.GetValue() && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth )
		|| ( m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_BARS_ON_FRIENDLY)	)
	{
		m_shieldPoints.SetValue(0);
		m_maxShieldPoints.SetValue(0);
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
	}

	//only change the display if the value has been updated
	if( m_shieldPoints.HasChanged() || m_maxShieldPoints.HasChanged() )
	{
		myValue.Type = AS_Number;
		myValue.n = m_shieldPoints.GetValue();		myArray.AddItem(myValue);
		myValue.n = m_maxShieldPoints.GetValue();	myArray.AddItem(myValue);

		//invoke sends this to 'the flash queue'
		//this causes issues with colouring that the bar might not exist - we have had to fix it - thanks to Xymanek!
		Invoke("SetShieldPoints", myArray);
	}

	// Disable hitpoints preview visualization - sbatista 6/24/2013 [? more like set to merge HP/ShieldHP preview displays ~ RustyDios]
	// <> TODO : Investigate if this is needed if ShieldHp <=0 
	SetShieldPointsPreview();
}

//Technically NO CHANGE here now as Armor Text+Icon is a STAT BLOCK thing, Armour Pips being shown is now optional ...
//ArmorPips get fed in NewUnitState.GetArmorMitigationForUnitFlag() which is stat + effects
simulated function SetArmorPoints(optional int _iArmor = 0)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentArmor, iMultiplier;

	//not calling super to avoid multiple flash invokes
	//super.SetArmorPoints(_iArmor);

	iMultiplier = `GAMECORE.HP_PER_TICK;

	if(class'WOTCLootIndicator_Extended'.default.SHOW_ARMOUR_PIPS && (m_bIsFriendly.GetValue() || `XPROFILESETTINGS.Data.m_bShowEnemyHealth) )
	{
		//Always round up for display when using the gamecore multiplier, per Jake's request. 
		if( iMultiplier > 0 )
		{
			currentArmor = FCeil(float(_iArmor) / float(iMultiplier));
		}

		m_armorPoints.SetValue(currentArmor);

		if( m_armorPoints.HasChanged() )
		{
			myValue.Type = AS_Number;	myValue.n = currentArmor;	myArray.AddItem(myValue);

			Invoke("ClearAllArmor");
			Invoke("SetArmor", myArray);
		}
	}
	else
	{
		// we dont want to show enemy healthbars so clear armor pips
		Invoke("ClearAllArmor");
	}

}

//THIS DOESN'T WORK HOW I THOUGHT IT WOULD. THIS IS INCOMING FROM ANOTHER UNIT, NOT WHAT *THIS* UNIT CAN DO
//simulated function SetArmorPointsPreview(optional int _iPossibleShred = 0, optional int _iPossiblePierce)
//{
//	//we're only here to collect input data, everything else is the same as base game
//	super.SetArmorPointsPreview(_iPossibleShred, _iPossiblePierce);
//
//	if (_iPossibleShred > int(ShredString.GetValue())) { ShredString.SetValue(string(_iPossibleShred)); }
//	if (_iPossiblePierce > int(PierceString.GetValue())) { PierceString.SetValue(string(_iPossiblePierce)); }
//}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	BUILD LOOT INDICATOR AND SHOW IF REQUIRED
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated protected function BuildLootIndicator()
{
	// Only units have loot
	if (ObjectType != eFOT_Unit) { return; }

	// Only create a loot indicator if we need one
	if (!class'WOTCLootIndicator_Extended'.default.SHOW_LOOT) { return; }

	LootIcon = Spawn(class'UIIcon', self);
	LootIcon.bDisableSelectionBrackets = true;
	LootIcon.bAnimateOnInit = false;
	LootIcon.bIsNavigable = false;
	LootIcon.InitIcon('RustyLootIcon',"img:///UILibrary_UIFlagExtended.UIFlag_Loot", false, false, class'WOTCLootIndicator_Extended'.default.INFO_ICON_SIZE);

	LootIcon.SetX(class'WOTCLootIndicator_Extended'.default.LOOT_OFFSET_X);
	LootIcon.SetY(class'WOTCLootIndicator_Extended'.default.LOOT_OFFSET_Y + GetYShift());
	LootIcon.Hide(); //ALWAYS INITIALLY HIDE, SHOWN IF NEEDED
}

simulated protected function bool ShouldShowLootIndicator (XComGameState_Unit NewUnitState)
{
	local name EffectName;

	//if we don't require scanning, show
	if (!class'WOTCLootIndicator_Extended'.default.REQUIRE_SCANNING ) { return true; }

	//we require scanning, and have been scanned, and scans persists, show
	if (bLootIndicatorScanned) { return true; }

	//we require scanning, and are currently scanned, show
	foreach class'WOTCLootIndicator_Extended'.default.ShowLootEffects(EffectName)
	{
		if (NewUnitState.IsUnitAffectedByEffectName(EffectName))
		{
			bLootIndicatorScanned = class'WOTCLootIndicator_Extended'.default.PERSISTANT_SCANS;	//do scans persist
			return true;
		}
	}

	//can't meet show criteria, hide
	return false;
}

simulated protected function UpdateLootIndicator (XComGameState_Unit NewUnitState)
{
	if ( LootIcon == none ) { return; }

	LootIcon.SetVisible(ShouldShowLootIndicator(NewUnitState) && NewUnitState.PendingLoot.LootToBeCreated.Length > 0);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	BUILD NAME ROW ITEMS -- UPDATE NAME ROW -- DISABLE BASEGAME BEHAVIOUR
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function SetNames (string unitName, string unitNickName)
{
	// Disable vanilla base game behaviour
}

simulated protected function BuildNameRow ()
{
	// Only units have names
	if (ObjectType != eFOT_Unit) { return; }

	// Create the head icon only if needed
	if (class'WOTCLootIndicator_Extended'.default.SHOW_HUDHEAD)
	{
		HudHeadIcon = Spawn(class'UIIcon', self);
		HudHeadIcon.bAnimateOnInit = false;
		HudHeadIcon.bIsNavigable = false;
		HudHeadIcon.bDisableSelectionBrackets = true;
		HudHeadIcon.InitIcon('HudHeadIcon',, false, true, class'WOTCLootIndicator_Extended'.default.INFO_ICON_SIZE);
		HudHeadIcon.SetX(class'WOTCLootIndicator_Extended'.default.NAME_OFFSET_X);

		HudHeadIcon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		HudHeadIcon.Hide();
	}

	// Make sure we will ever show names
	if ( class'WOTCLootIndicator_Extended'.default.SHOW_FRIENDS_NAME || class'WOTCLootIndicator_Extended'.default.SHOW_ENEMIES_NAME )
	{
		UnitNameText = Spawn(class'UIText', self);
		UnitNameText.InitText('UnitNameText');

		if (HudHeadIcon != none)
		{
			UnitNameText.SetX(HudHeadIcon.X + HudHeadIcon.Width);
		}
		else
		{
			UnitNameText.SetX(class'WOTCLootIndicator_Extended'.default.NAME_OFFSET_X);
		}
	}
}

simulated protected function UpdateNameRow (XComGameState_Unit NewUnitState)
{
	local string strUnitName;

	if (HUDIconString == "" || HUDIconColour == "")
	{
		//FORCE AN UPDATE/CHECK OF THE ICON AND COLOUR BEFORE SETTING IT
		FindHUDIconDetails(HUDIconString, HUDIconColour);
	}

	if (HudHeadIcon != none)
	{
		//HudHeadIcon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		HudHeadIcon.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath(HUDIconString));

		HudHeadIcon.SetBGColor("0x" $ HUDIconColour);
		HudHeadIcon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath(HUDIconString $"_bg"));
		HudHeadIcon.Show();
	}
	
	if (   ( m_bIsFriendly.GetValue() && class'WOTCLootIndicator_Extended'.default.SHOW_FRIENDS_NAME )
		|| (!m_bIsFriendly.GetValue() && class'WOTCLootIndicator_Extended'.default.SHOW_ENEMIES_NAME ) )
	{
		//get the displayed name , set its size , then its colour
		strUnitName = GetUnitDisplayedName(NewUnitState);
		strUnitName = class'UIUtilities_Text'.static.AddFontInfo(strUnitName, false, false, false, class'WOTCLootIndicator_Extended'.default.NAME_FONT_SIZE);
		strUnitName = class'UnitFlagExtendedHelpers'.static.ColourText(
			strUnitName, class'WOTCLootIndicator_Extended'.default.NAME_COLOUR_BYTEAM ? HUDIconColour : class'WOTCLootIndicator_Extended'.default.NAME_COLOURHEX );

		UnitNameText.SetHtmlText(strUnitName);
		class'UnitFlagExtendedHelpers'.static.AddShadowToTextField(UnitNameText);

		// Might've been hidden due to team switching
		UnitNameText.Show();
	}
	else if (UnitNameText != none)
	{
		// Might've been shown due to team switching
		UnitNameText.Hide();
	}
}

simulated protected function string GetUnitDisplayedName (XComGameState_Unit NewUnitState)
{
	local string NameToDisplay;

	//Get Nickname
	NameToDisplay = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(NewUnitState.GetNickName(true));

	//If Nickname was Empty get Full Name
	if (NameToDisplay == "")
	{
		NameToDisplay = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(NewUnitState.GetName(eNameType_Full));
	}

	return NameToDisplay;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	BUILD EXTENDED STATUS ROW
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated protected function BuildExtendedStatusRow ()
{
	ExtendedStatusRowContainer = Spawn(class'UIPanel', self);
	ExtendedStatusRowContainer.bAnimateOnInit = false;
	ExtendedStatusRowContainer.bIsNavigable = false;
	ExtendedStatusRowContainer.InitPanel('ExtendedStatusRowContainer');
	ExtendedStatusRowContainer.Hide(); // Gets shown when realized
	ExtendedStatusRowContainer.SetPosition(class'WOTCLootIndicator_Extended'.default.NAME_OFFSET_X, class'WOTCLootIndicator_Extended'.default.STAT_OFFSET_Y + 69);
}

function InitStatusIcon(UIIcon StatusIcon, name InitName, string ImagePath)
{
	StatusIcon.bDisableSelectionBrackets = true;
	StatusIcon.bAnimateOnInit = false;
	StatusIcon.InitIcon(InitName, ImagePath, false, false);
	StatusIcon.SetSize(class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE, class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE);
	StatusIcon.Hide(); // Gets shown when needed
}

//cancel base game homing mine icon if we add it to the status row
//This function will be spammed, so please only send changes to flash.
simulated function RealizeClaymore(optional XComGameState_Unit NewUnitState = none)
{
	//bailout if using new status row
	if (!class'WOTCLootIndicator_Extended'.default.bDISABLE_NEW_STATUS_ROW) { return; }

	//if not call super to use vanilla code
	super.RealizeClaymore(NewUnitState);
}

//cancel base game rupture if we add it to the status row now
//This function will be spammed, so please only send changes to flash.
simulated function RealizeRupture(XComGameState_Unit NewUnitState)
{
	//bailout if using new status row
	if (!class'WOTCLootIndicator_Extended'.default.bDISABLE_NEW_STATUS_ROW) { return; }

	//if not call super to use vanilla code
	super.RealizeRupture(NewUnitState);
}

simulated function RealizeStatus(optional XComGameState_Unit NewUnitState = none)
{
	local array<string> IconPaths;
	local int i, StatusIconX, StatusIconY;

	//GET UNIT STATE IF WE DIDN'T PASS ONE IN
	if( NewUnitState == none ) { NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID)); }

	//NOTE: The UI currently only supports one status icon, and this is intentional from design. 
	// I suspect we may need to stack them or show more in the future, so I'm handling everything in an array.
	// Will update the flag to handle multiple icons if we need to. -bsteiner 26/02/2015

	//Updated to handle multiple icons thanks to bsteiner handling it as an array way back then ~ RustyDios 16/08/2022

	//get mod extended status icon paths
	IconPaths.length = 0;
	IconPaths = class'UnitFlagExtendedHelpers'.static.GetCurrentStatusIconPaths(NewUnitState, IsUnitBound(NewUnitState) );

	//set or hide our new status icons panel and original icon slot
	if( IconPaths.length <= 0 )
	{
		AS_SetStatusIcon("");
		ExtendedStatusRowContainer.Hide();
		return;
	}
	else
	{
		//use vanilla base game single icon only behaviour
		if (class'WOTCLootIndicator_Extended'.default.bDISABLE_NEW_STATUS_ROW)
		{
			AS_SetStatusIcon(IconPaths[0]);
			ExtendedStatusRowContainer.Hide();
			return;
		}

		//use new behaviour and nullify base game icon setting
		// <> TODO : LOCK BEHIND A VISUALISER/HISTORY  CHECK ?
		AS_SetStatusIcon("");

		//reset X position
		StatusIconX = 0 - (class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE / 4) ;
		StatusIconY = 22;

		//create or set new icons
		//yes this happens on the realize as the icons need to refresh too
		for (i = 0; i < IconPaths.length; i++)
		{
			if (StatusIcons[i] == none)
			{
				StatusIcons.AddItem(Spawn(class'UIIcon', ExtendedStatusRowContainer));
				InitStatusIcon(StatusIcons[i], name("StatusIcons_UFE_" $ i), IconPaths[i]);
			}
			else
			{
				StatusIcons[i].LoadIcon(IconPaths[i]);
			}
			
			//space correctly and show
			StatusIcons[i].SetPosition(StatusIconX, StatusIconY);
			StatusIconX += class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE - (class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE / 4) ;

			//create and place on new row if needed
			if (StatusIconX > class'WOTCLootIndicator_Extended'.default.iMAXSTATWIDTH)
			{
				StatusIconX = 0 - (class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE / 4) ;
				StatusIconY += class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE;

				StatusIcons[i].SetPosition(StatusIconX, StatusIconY);
				StatusIconX += class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE - (class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE / 4) ;
			}

			StatusIcons[i].Show();
		}

		//remove any uneeded icons
		for (i = StatusIcons.length -1 ; i >= IconPaths.length; i--)
		{
			if (StatusIcons[i] != none)
			{
				StatusIcons[i].Hide();
				StatusIcons[i].Remove();
				StatusIcons.Remove(i, 1);
			}
		}

		//show if we still have icons
		if (StatusIcons.length > 0)
		{
			ExtendedStatusRowContainer.Show();
		}
		else
		{
			ExtendedStatusRowContainer.Hide();
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	BUILD STATS ROW
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated protected function BuildStatsRow ()
{
	local StatRowEntryDefinition EntryDef, EmptyDef;
	local StatsBlock BlockDef;

	//bail if not a unit and not a destructible needing a HP Only flag .. so Bail then if = eFOT_Invalid or eFOT_DestructibleNoFlag
	if (ObjectType != eFOT_Unit && ObjectType != eFOT_Destructible) { return; }

	//create a container for the stats icons and texts
	StatRowContainer = Spawn(class'UIPanel', self);
	StatRowContainer.bAnimateOnInit = false;
	StatRowContainer.bIsNavigable = false;
	StatRowContainer.InitPanel('StatRowContainer');
	StatRowContainer.Hide(); // Gets shown when realized
	StatRowContainer.SetX(class'WOTCLootIndicator_Extended'.default.STAT_OFFSET_X);

	//add the special section for damage preview - always first
	//DEPRECIATED - SHOW DAMAGE SHOULD ALWAYS = FALSE
	if (class'WOTCLootIndicator_Extended'.default.SHOW_DAMAGE && ObjectType == eFOT_Unit)
	{
		EntryDef = EmptyDef;
		EntryDef.BlockName = 'Damage';
		EntryDef.Type = eSRET_Damage;
		EntryDef.Stat = eStat_Invalid;
		EntryDef.IconPath = class'WOTCLootIndicator_Extended'.default.SHOW_DMG_ICONPATH; //"UILibrary_UIFlagExtended.UIFlag_Damage";
		EntryDef.HexColour = class'WOTCLootIndicator_Extended'.default.TEXT_COLOUR_BYTEAM ? HUDIconColour : class'WOTCLootIndicator_Extended'.default.SHOW_DMG_COLOURHEX;
		EntryDef.bCanObsfucate = class'WOTCLootIndicator_Extended'.default.SHOW_DMG_OBFUSCATE;
		//EntryDef.SpecialTriggerID = BlockDef.SpecialTriggerID; // not needed/ none

		BuildStatsEntry(EntryDef);
	}

	//add the stats as per the config order
	foreach class'WOTCLootIndicator_Extended'.default.StatsToShow(BlockDef)
	{
		// Destructibles get only HP display - Note that they don't actually have eStats stored - there is special handling for eStat_HP
		if (ObjectType == eFOT_Destructible && BlockDef.Stat != eStat_HP) { continue; }

		EntryDef = EmptyDef;
		EntryDef.BlockName = name(BlockDef.BlockName);
		EntryDef.Type = eSRET_UnitStat;
		EntryDef.Stat = BlockDef.Stat;
		EntryDef.IconPath = BlockDef.IconPath;
		EntryDef.HexColour = class'WOTCLootIndicator_Extended'.default.TEXT_COLOUR_BYTEAM ? HUDIconColour : BlockDef.HexColour;
		EntryDef.bCanObsfucate = bool(BlockDef.bCanObsfucate);
		EntryDef.SpecialTriggerID = BlockDef.SpecialTriggerID;

		BuildStatsEntry(EntryDef);
	}
}

simulated protected function BuildStatsEntry (StatRowEntryDefinition EntryDef)
{
	local UIUnitFlagExtended_StatEntry Entry;

	Entry = Spawn(class'UIUnitFlagExtended_StatEntry', StatRowContainer);
	Entry.InitStatEntry(EntryDef);
	Entry.Text.AddOnInitDelegate(OnComponentPanelInited);
	Entry.OnSizeRealized = OnStatEntrySizeRealized;

	StatRowEntries.AddItem(Entry);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UPDATE/REFRESH STATS ROW
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
simulated function bool AreWeHiding()
{
	if (   ( m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_FRIENDS )
		|| (!m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_ENEMIES ) )
	{
		return true;
	}

	return false;
}

simulated protected function UpdateUnitStats (XComGameState_Unit NewUnitState)
{
	local UIUnitFlagExtended_StatEntry Entry;
	local float fCurrentValue, WillPercent;
	local int iCurrentValue;
	local LWTuple NSLWTuple;

	foreach StatRowEntries(Entry)
	{
		// We are only updating actual unit stats here
		if (Entry.Definition.Type != eSRET_UnitStat) { continue; }

		// HP has special handling to catch units and destructibles
		if (Entry.Definition.Stat == eStat_HP) { continue; }

		// Are we hiding friendly stats OR hiding enemy stats ?
		if (AreWeHiding()) { Entry.Hide();	continue; }

		// Needs to happen before obfuscate etc to set the correct background icon + colour
		UpdateStatEntryIconColour(Entry);

		// No per-stat value handling if obfuscated, sets as "##" or damage as "#-#"
		if (TryObsfucate(Entry, NewUnitState)) { continue; }

		// Set Value based on event trigger listener from mod addition
		if (Entry.Definition.SpecialTriggerID != '' )
		{
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			// allow mods to change/add the shown value for a stats config entry
			NSLWTuple = new class'LWTuple';
			NSLWTuple.Id = 'UIUnitFlag_AddDisplayInfo';
			NSLWTuple.Data.Add(3);
			NSLWTuple.Data[0].kind = LWTVObject;	NSLWTuple.Data[0].o = self;		// Sending the UnitFlag
			NSLWTuple.Data[1].kind = LWTVString;	NSLWTuple.Data[1].s = "";		// What the info should be
			NSLWTuple.Data[2].kind = LWTVBool;		NSLWTuple.Data[2].b = false;	// Should this trigger once

			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			//SEND THE EVENT FOR LISTENERS
			`XEVENTMGR.TriggerEvent(Entry.Definition.SpecialTriggerID, NSLWTuple, NewUnitState );

			//SET THE VALUE BASED ON LISTENER
			Entry.SetValue(NSLWTuple.Data[1].s);

			//IF TRIGGER ONCE CLEAR THE TRIGGER ID, USEFUL IF GETTING THE DATA IS INTENSIVE AND UNLIKELY TO CHANGE
			if (NSLWTuple.Data[2].b)
			{
				Entry.ClearSpecialTrigger();
			}

			//THIS STAT IS DEALT WITH CONTINUE TO THE NEXT ONE
			continue;
		}

		// set value based on stat entry
		fCurrentValue = NewUnitState.GetCurrentStat(Entry.Definition.Stat);
		iCurrentValue = int(fCurrentValue); // <> TODO : Are we sure we don't want rounding here?

		switch (Entry.Definition.Stat)
		{
			// This was a triggered response which was set to once only, we do not want to update the previously set value
			case eStat_Invalid: break;

			// Prevent the warning from the default block, as HP is handled elsewhere as it needs to account for units and destructables
			case eStat_HP: break;

			// Stats with standard handling
			case eStat_Offense:
			case eStat_Defense:
			case eStat_Dodge:
			case eStat_Hacking:
			case eStat_HackDefense:
			case eStat_PsiOffense:
			case eStat_ShieldHP:
			case eStat_CritChance:
			case eStat_FlankingCritChance:
			case eStat_FlankingAimBonus:
			case eStat_DetectionRadius:
			case eStat_DetectionModifier:
			case eStat_Strength:
			case eStat_SightRadius:
			case eStat_AlertLevel:			//ENEMY ONLY STAT
			case eStat_UtilityItems:		//UTIL ITEM SIZE!
			case eStat_CombatSims:			//PCS SLOTS SIZE!
			case eStat_Job:					//ONLY FOR LWOTC?
			case eStat_ArmorChance: 		//DEPRECIATED?
			case eStat_BackpackSize: 		//DEPRECIATED?
			case eStat_FlightFuel: 			//DEPRECIATED?
			case eStat_SeeMovement: 		//DEPRECIATED?
			case eStat_HearingRadius: 		//DEPRECIATED?
				Entry.SetValue(iCurrentValue);
			break;

			// Piercing doesn't seem to work as a normal stat, RJ's YAF1 gets the pierce value direct from the weapon
			// Normal unit flag uses SetAbilityDamagePreview from the manager, 
			// which needs an ability state and is for an attacker vs us to adjust the pips display
			// So here we jump the hoops to get the Primary Weapon Base values like YAF1 does
			case eStat_ArmorPiercing:
				Entry.SetValue(GetWeaponValue(NewUnitState));
			break;

			// Armour has special handling as the pips use a combination of stat+effect
			// Thankfully XCGS_Unit has a handy helper function
			case eStat_ArmorMitigation:
				fCurrentValue = NewUnitState.GetArmorMitigationForUnitFlag();
				iCurrentValue = int(fCurrentValue);
				Entry.SetValue(iCurrentValue);
			break;

			// Mobility has special handling for display as meters/tiles
			case eStat_Mobility:
				if (class'WOTCLootIndicator_Extended'.default.SHOW_MOB_AS_TILES)
				{
					iCurrentValue = int(`METERSTOTILES(fCurrentValue));
				}
				Entry.SetValue(iCurrentValue);
			break;

            // Will has special handling for current/max, or percentage display /*and uses the will system*/ - removed if uses, so it allows enemies
			case eStat_Will:
				//if (m_bUsesWillSystem)	
				
				//this catches a case where non-will/shattered users get a massive -2134566827267 number
				if (iCurrentValue < 1) 		{ iCurrentValue = 0; }

				if (class'WOTCLootIndicator_Extended'.default.SHOW_PERCENT_WILL)
				{
					//(current value/max value) * 100%
					WillPercent = (fCurrentValue / NewUnitState.GetMaxStat(eStat_Will)) * 100;

					//handle overflow?
					if (WillPercent < 1.00) 	{ WillPercent = 0.00 ; 		}
					if (WillPercent > 99.00) 	{ WillPercent = 100.00 ; 	}

					Entry.SetValue(int(WillPercent) $ "%");
				}
				else if (class'WOTCLootIndicator_Extended'.default.SHOW_MAX_WILL)
				{
					Entry.SetValue(iCurrentValue $ "/" $ int(NewUnitState.GetMaxStat(eStat_Will)));
				}
				else
				{
					Entry.SetValue(iCurrentValue);
				}
			break;

			// FOR ANYTHING NOT ON THE LIST WE PREFER TO LOG AS AN ERROR REGARDLESS IF LOGGING IS ON
			// WE ALSO HIDE THIS ERROR ENTRY
			default:
				Entry.Hide();

				`LOG("UNIDENTIFIED STAT TYPE PASSED TO UFE SWITCHBLOCK :"
						@"\n Block	:" $Entry.Definition.BlockName
						@"\n Type	:" $Entry.Definition.Type
						@"\n Stat	:" $Entry.Definition.Stat
						@"\n Icon	:" $Entry.Definition.IconPath
						@"\n IcCol	:" $Entry.Definition.IconColour
						@"\n Hex	:" $Entry.Definition.HexColour
						@"\n Obs	:" $Entry.Definition.bCanObsfucate
						@"\n ID		:" $Entry.Definition.SpecialTriggerID
					, /* class'WOTCLootIndicator_Extended'.default.bRustyUIFlagLog */ ,'WOTC_RUSTY_UIFLAG');

		} //END SWITCH

	} //END STATROWS FOREACH
}

// DEPRECIATED - SHOW DAMAGE SHOULD ALWAYS BE FALSE - NOW PART OF NORMAL STATS BLOCK
simulated protected function UpdateUnitDamageStat (XComGameState_Unit NewUnitState)
{
	local UIUnitFlagExtended_StatEntry Entry;

	foreach StatRowEntries(Entry)
	{
		if (Entry.Definition.Type != eSRET_Damage) { continue; }

		// Are we hiding friendly stats OR hiding enemy stats ?
		if (AreWeHiding()) { Entry.Hide();	continue; }

		// Needs to happen before obfuscate etc to set the correct background icon + colour
		UpdateStatEntryIconColour(Entry);

		if (!TryObsfucate(Entry, NewUnitState))
		{
			if (DamageString.HasChanged())
			{
				Entry.SetValue(DamageString.GetValue());
			}
		}
	}
}

//this handles both unit and destructible HP
simulated protected function SetHealthStatEntry (int _currentHP, int _maxHP)
{
	local UIUnitFlagExtended_StatEntry Entry;
	local string strValue;

	foreach StatRowEntries(Entry)
	{
		if (Entry.Definition.Stat != eStat_HP) { continue; }

		// Are we hiding friendly stats OR hiding enemy stats ?
		if (AreWeHiding()) { Entry.Hide();	continue; }

		// Needs to happen before obfuscate etc to set the correct background icon + colour
		UpdateStatEntryIconColour(Entry);

		if (!TryObsfucate(Entry))
		{
			strValue = string(_currentHP);

			if (class'WOTCLootIndicator_Extended'.default.SHOW_MAX_HP)
			{
				strValue $= "/" $ _maxHP;
			}

			Entry.SetValue(strValue);
		}
	}
}

simulated protected function UpdateStatEntryIconColour(UIUnitFlagExtended_StatEntry Entry)
{
	if (class'WOTCLootIndicator_Extended'.default.ICONS_COLOUR_BYTEXT)
	{
		Entry.SetIconColour(Entry.Definition.HexColour);
	}
	else if (class'WOTCLootIndicator_Extended'.default.ICONS_COLOUR_BYTEAM)
	{
		Entry.SetIconColour(HUDIconColour);
	}
	else
	{
		Entry.SetIconColour("BF1E2E"); //default to red
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	THIS FUNCTION WILL SEE IF THE STAT NEEDS OBFUSCATION OR NOT	, True = Obfuscated, False = Normal Display
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated protected function bool TryObsfucate (UIUnitFlagExtended_StatEntry Entry, optional XComGameState_Unit NewUnitState)
{
	local LWTuple Tuple;

	//early bailout if the stat can never be obfuscated
	if (!Entry.Definition.bCanObsfucate) { return false; }

	//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	// allow mods to change the show/hide behavior	
	Tuple = new class'LWTuple';
	Tuple.Id = 'UIUnitFlag_OverrideShowInfo';
	Tuple.Data.Add(2);														// Needed to keep [0] for backwards compatibility!
	Tuple.Data[0].kind = LWTVObject;	Tuple.Data[0].o = NewUnitState;		// The targeted unit. Not really required anymore, as event sends as SourceData! 
	Tuple.Data[1].kind = LWTVBool;		Tuple.Data[1].b = true;				// Whether the info should be available. true = show, false = hide

	`XEVENTMGR.TriggerEvent('UIUnitFlag_OverrideShowInfo', Tuple, NewUnitState);

	//a HIDE return should set the data false, we flip it here, so that bObfuscate = true
	//thus a query to !bObfuscate (not hide) will be correct later
	//stats obfuscated get the text filled in as ##
	//obfuscated stats by default are the same ones hidden in YAF1 
	//	-- damage, aim, mobility, will, hack, dodge, psi 
	//	-- leaving HP, DEF, Shields and Armor 
	//	-- now config editable
	//yes this needs to check every update as conditions may have changed
	bObfuscate = !Tuple.Data[1].b;	
	//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	if (!bObfuscate) return false;

	//`LOG("IS UNIT FLAG OBFUSCATED ::[" @bObfuscate @"] For Unit:[" @NewUnitState.GetFullName() @"]", class'WOTCLootIndicator_Extended'.default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');

	//IF WE GOT THIS FAR THE ENTRY SHOULD BE OBFUSCATED, SET CORRECT OBFUSCATION STRING PER ENTRY TYPE
	if (Entry.Definition.Type == eSRET_Damage) 			{ Entry.SetValue("#-#"); }
	else if (Entry.Definition.Stat == eStat_Invalid) 	{ Entry.SetValue("-?-"); }
	else												{ Entry.SetValue("##");  }

	return true;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UPDATE/REFRESH BAR COLOURS -- FLASH CHECK
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function bool IsBarCreatedInFlash(string VarObjectPath)
{
	return Movie.GetVariableObject(MCPath $ VarObjectPath) != none;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UPDATE/REFRESH BAR COLOURS -- HEALTH
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//In Flash, for referrence ;
//this.healthMeter.theMeter																				the ACTUAL Health Bar
//this.healthMeter.healthMCArray[i]	Bind.movie(this.healthMeter,"healthMeter","healthMeter" + _loc2_)	the EXTRA Health Bars

simulated protected function string GetBarColours_Health (XComGameState_Unit NewUnitState)
{
	local SpecialBarColour SetSpecialBarColour;

	//only set colours to special if unit is not mind controlled
	if (!NewUnitState.IsMindControlled() )
	{
		//direct overrides per set template name
		foreach class'WOTCLootIndicator_Extended'.default.SpecialBarColours_Health(SetSpecialBarColour)
		{
			if (NewUnitState.GetMyTemplateName() == SetSpecialBarColour.TemplateName)
			{
				return SetSpecialBarColour.HexColour;
			}
		}

		if (NewUnitState.bIsSpecial) 	{ return "ACD373" ; }
		if (NewUnitState.IsChosen())	{ return "B6B3E3" ; }
	}

	//else and for all other cases set bar colour to HUD Icon Colour
	return HUDIconColour;
}

simulated protected function UpdateBarColours_Health (optional XComGameState_Unit NewUnitState)
{
	//only do the recolour of Health if it is a unit and set to do so by the config
	if (ObjectType != eFOT_Unit || !class'WOTCLootIndicator_Extended'.default.HPBAR_COLOUR_BYTEAM )  { return; }

	//get unit if it was not passed in, as we need one
	if (NewUnitState == none)
	{
		NewUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(StoredObjectID));
	}

	//set colour
	HealthBarColour.SetValue(GetBarColours_Health(NewUnitState));

	//only update the colour if it has changed
	if (HealthBarColour.HasChanged())
	{
		bCheckAndSetHealthBarColour = true;
		TrySetHealthBarColour(NewUnitState.bIsSpecial);
	}
}

//called in the OnTick Update to change the bar colour, after it has been created and only if it needs changing
simulated function TrySetHealthBarColour(optional bool bWasSpecial)
{
	local float fTotalHealthBars;
	local int i;

	if (!bCheckAndSetHealthBarColour) { return; }

	if (!bHealthBarCreated)
	{
		bHealthBarCreated = IsBarCreatedInFlash(".healthMeter.theMeter");
	}

	if (bHealthBarCreated)
	{
		bCheckAndSetHealthBarColour = false;

		//set the actual health bar
		AS_SetMCColor(MCPath $".healthMeter.theMeter", HealthBarColour.GetValue());

		//if it has extra health bars, lets set those too
		if (bWasSpecial)
		{
			fTotalHealthBars = Movie.GetVariableNumber(MCPath $ ".MeterTotal");
			for (i = 0 ; i < fTotalHealthBars ; i++)
			{
				//takes care of 'the healthbar array extra lines'
				AS_SetMCColor(MCPath $".healthMeter.healthMeter" $ i $ ".theMeter", HealthBarColour.GetValue());
			}
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UPDATE/REFRESH BAR COLOURS -- SHIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//In Flash, for referrence ;
//this.healthMeter.shieldMeter		Bind.movie(this.healthMeter,"healthMeter","shieldMeter");			the SHIELD Health Bar

simulated protected function string GetBarColours_Shield (XComGameState_Unit NewUnitState)
{
	local SpecialBarColour SetSpecialBarColour;

	//Override frosty shields above all else
	if ( class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOUR_FROSTLEGION)
	{
		//we only need to run the check once
		if (!bFrostShieldsChecked)
		{
			bFrostShieldsChecked = true;
			bGotFrostShields = NewUnitState.HasAbilityFromAnySource('MZ_FDIceShield'); // <> TODO : Make this a config lookup array?
		}

		if (bGotFrostShields)
		{
			//set as 'frosty' shield colour for the Frost Legion Dudes
			return class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOURHEX_FROSTLEGION;
		}
	}

	//only set colours to special if unit is not mind controlled
	if (!NewUnitState.IsMindControlled() )
	{
		//direct overrides per set template name
		foreach class'WOTCLootIndicator_Extended'.default.SpecialBarColours_Shield(SetSpecialBarColour)
		{
			if (NewUnitState.GetMyTemplateName() == SetSpecialBarColour.TemplateName)
			{
				return SetSpecialBarColour.HexColour;
			}
		}

		//colours for special units
		if (NewUnitState.bIsSpecial)	{ return "ACD373" ; }
		if (NewUnitState.IsChosen())	{ return "B6B3E3" ; }
	}

	//else and for all other cases set bar colour to HUD Icon Colour
	//check for if team colours on .. find and set team colour
	if ( (class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOUR_BYTEAM_ENEMIES && !m_bIsFriendly.GetValue() )
	  || (class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOUR_BYTEAM_FRIENDS && m_bIsFriendly.GetValue() ) )
	{
		return HUDIconColour;
	}

	// in all other cases set default shield bar colour
	return class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOURHEX_DEFAULT;
}

//this had to be extended to check the shield bar has been created in flash before we try to recolour it
simulated protected function UpdateBarColours_Shield (optional XComGameState_Unit NewUnitState)
{
	//only do the recolour of Shield if it is a unit (and set to do so by the config ... )
	if (ObjectType != eFOT_Unit)  { return; }

	//get unit if it was not passed in, as we need one
	if (NewUnitState == none)
	{
		NewUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(StoredObjectID));
	}

	ShieldBarColour.SetValue(GetBarColours_Shield(NewUnitState));

	if (ShieldBarColour.HasChanged())
	{
		bCheckAndSetShieldBarColour = true;
		TrySetShieldBarColour();
	}
}

//called in the OnTick Update to change the bar colour, after it has been created and only if it needs changing
simulated function TrySetShieldBarColour()
{
	if (!bCheckAndSetShieldBarColour) { return; }

	if (!bShieldBarCreated)
	{
		bShieldBarCreated = IsBarCreatedInFlash(".healthMeter.shieldMeter.theMeter");
	}

	if (bShieldBarCreated)
	{
		bCheckAndSetShieldBarColour = false;
		AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", ShieldBarColour.GetValue());
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UPDATE/REFRESH BAR COLOURS -- FORCED -- CURRENTLY NOT ACTUALLY USED
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function ForceBarColours(string HealthHex, string ShieldHex)
{
	local float fTotalHealthBars;
	local int i;

	AS_SetMCColor(MCPath $".healthMeter.theMeter", HealthHex);

	fTotalHealthBars = Movie.GetVariableNumber(MCPath $ ".MeterTotal");
	for (i = 0 ; i < fTotalHealthBars ; i++)
	{
		AS_SetMCColor(MCPath $".healthMeter.healthMeter" $ i $ ".theMeter", HealthHex);
	}

	AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", ShieldHex);

	MC.ProcessCommands(true);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UPDATE/SET THE BIG ALIEN HEAD - THE SPECIAL RULER HEAD
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function UpdateBigAlienHead(XComGameState_Unit NewUnitState)
{
	local SpecialBarColour SetSpecialBarColour;
	local bool bShouldShow;

	bShouldShow = NewUnitState.bIsSpecial && class'WOTCLootIndicator_Extended'.default.SHOW_RULERHEAD;

	foreach class'WOTCLootIndicator_Extended'.default.SpecialBarColours_Health(SetSpecialBarColour)
	{
		if (NewUnitState.GetMyTemplateName() == SetSpecialBarColour.TemplateName)
		{
			bShouldShow = SetSpecialBarColour.bShowBigHead;
			break;
		}
	}

	foreach class'WOTCLootIndicator_Extended'.default.SpecialBarColours_Shield(SetSpecialBarColour)
	{
		if (NewUnitState.GetMyTemplateName() == SetSpecialBarColour.TemplateName)
		{
			bShouldShow = SetSpecialBarColour.bShowBigHead;
			break;
		}
	}

	MC.ChildSetBool ("specialAlienIcon","_visible", bShouldShow);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	THIS IS THE WOTC WILL BAR, I OPEN THE COLOUR TO CONFIG AND IF THE BAR SHOULD BE SHOWN OR HIDDEN	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function SetWillPoints(int _currentWill, int _maxWill, int _previousWill)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	//not calling super to avoid multiple flash invokes
	//super.SetWillPoints(_currentWill, _maxWill, _previousWill);

	// Only show will on friendly units if selected .. coloured will bar .. defaultgame = eColor_Good	defaultmod = eColor_Purple
	if( m_bIsFriendly.GetValue() && m_bUsesWillSystem && class'WOTCLootIndicator_Extended'.default.SHOW_WILL_BAR)
	{
		myValue.Type = AS_Number;
		myValue.n = (_previousWill / float(_maxWill)) * 100.0f;
		myArray.AddItem(myValue);
		
		myValue.Type = AS_String;
		myValue.s = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(class'WOTCLootIndicator_Extended'.default.eColour_WillBar);
		myArray.AddItem(myValue);
		
		myValue.Type = AS_Number;
		myValue.n = (_currentWill  / float(_maxWill)) * 100.0f;
		myArray.AddItem(myValue);

		Invoke("SetUnitWill", myArray);
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	THIS IS THE CHL FOCUS BAR , BELOW THE WILL
//	NO ACTUAL CHANGES BUT HERE FOR COMPLETENESS AND TO COMPARE OR CHANGE LATER?
//	<> TODO: MAYBE ADD THE FOCUS ICON INTO THE UFE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
// Start Issue #257 -- depreciated by CHL, using new RealizeFocusMeter
simulated function SetFocusPoints(int _currentFocus, int _maxFocus)
{
	RealizeFocusMeter(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(StoredObjectID)));
}

simulated function RealizeFocusMeter(XComGameState_Unit UnitState)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local XComLWTuple Tuple;

	//	Tuple info for reference
	//
	//	local XComGameState_Effect_TemplarFocus FocusState;
	//	FocusState = UnitState.GetTemplarFocusEffectState();
	//	Tuple.Data[0].b = FocusState != none;																								//Has Bar?
	//	Tuple.Data[1].i = FocusState.FocusLevel;																							//Current Level
	//	Tuple.Data[2].i = FocusState.GetMaxFocus(UnitState);																				//Maximum Level
	//	Tuple.Data[3].s = "0x" $ class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;														//Colour
	//	Tuple.Data[4].s = "img:///gfxTacticalHUD.focusMeterIcon"; 																			//IconPath, Templar Default
	//	Tuple.Data[5].s = `XEXPAND.ExpandString(class'UITacticalHUD_SoldierInfo'.default.FocusLevelDescriptions[FocusState.FocusLevel]);	//TooltipDesc
	//	Tuple.Data[6].s = class'UITacticalHUD_SoldierInfo'.default.FocusLevelLabel;															//TooltipName
	//
	//	1, 2 and 3 are handled here in the UFE
	//	4, 5 and 6 are handled in the Soldier info panel

	Tuple = class'CHHelpers'.static.GetFocusTuple(UnitState);

	/* Cur Focus */		myValue.Type = AS_Number;	myValue.n = Tuple.Data[0].b ? float(Tuple.Data[1].i) : -1.0f; 	myArray.AddItem(myValue);
	/* Max Focus */		myValue.Type = AS_Number;	myValue.n = Tuple.Data[2].i;									myArray.AddItem(myValue);

	Invoke("SetFocusPoints", myArray);

	// >>> this little line from RoboJumper is what spurred me to do the other bar colour changes!
	/* Re-Colour */		AS_SetMCColor(MCPath$".healthAnchor.focusMeter.theMeter", Tuple.Data[3].s);
}
// End Issue #257
*/

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
	WE THEN HAVE A BUNCH OF STUFF SET EVEN LOWER DOWN
	OFFENSE ARROWS	DEFENSE ARROWS	RANK	MOVES			COVERSHIELD
	SELECTED	TARGETED	ALERTED	SPOTTED
	HOLDING MISSION ITEM	HOLDING OBJECTIVE ITEM
	CONCEALMENT		OVERWATCH EYE	CLAYMORE	STATUS ICON (ONLY ONE AT A TIME !)	RUPTURE ICON	BINDED	
*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	THIS FUNCTION OFFSETS THE ENTIRE FLAG POSITION FOR UNITS UNDER VIPER BIND
//	I EXTENDED IT TO ACCOUNT FOR UNITS THAT HAVE BEEN BOUND BY THE VIPER KING AND HOISTED BY THE ARCHON KING TOO
//	ALSO EXTENDED TO ELITE VIPERS, ABA VIPERS, FROST LEGION VIPERS/ADDERS ARMOURED, VALENTINES AND FLAME VIPERS
//	AND THEN OUTSOURCED THE ENTIRE THING TO BE CONFIG EXPANDABLE :)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function bool IsUnitBound(XComGameState_Unit NewUnitState)
{
	local name EffectName;

	foreach class'WOTCLootIndicator_Extended'.default.BindEffects (EffectName)
	{
		if (NewUnitState.AffectedByEffectNames.Find(EffectName) != INDEX_NONE)
		{
			return true; //EARLY BREAKOUT IF WE FIND SOMETHING ...
		}
	}

	return false;
}

simulated function RealizeViperBind(XComGameState_Unit NewUnitState)
{
	//NOT MUCH POINT IN CALLING SUPER TBH, JUST IN CASE CHL DOES AN UPDATE, AS WE OVERRIDE THE VALUE HERE ANYWAY!
	super.RealizeViperBind(NewUnitState);

	//const VIPER_BIND_OFFSET = 30; // 30 may have been fine for base game, but it's not for this with with all the extra stats and stuff
	//The unit flag for the unit being bound will overlap with the Viper's unit flag without an offset.
	//m_LocalYOffset = NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_Viper'.default.BindSustainedEffectName) ? VIPER_BIND_OFFSET : 0;

	// Shift the whole flag down if 'bound'
	m_LocalYOffset = IsUnitBound(NewUnitState) ? class'WOTCLootIndicator_Extended'.default.BIND_SHIFT_Y : 0;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// THIS FUNCTION CONTROLS THE COVER SHIELD, OVERRIDDEN HERE SO THAT CLIBANARIUS HAS A CONFIG OPTION TO HIDE IT
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function RealizeCover(optional XComGameState_Unit UnitState = none, optional int HistoryIndex = INDEX_NONE)
{
	//SUPER FIGURES OUT HIGH/LOW/FLANKED, ALSO UPDATES VISUALIZEDHISTORYINDEX !
	super.RealizeCover(UnitState, HistoryIndex);
	
	//HAX: SEND DIRECT OVERRIDE TO FLASH TO SHOW/HIDE THE COVER SHIELD ICON, AFTER VANILLA CODE DECIDES WHAT IT WANTS TO DO WITH IT
	MC.ChildSetBool ("coverStatusObj","_visible", class'WOTCLootIndicator_Extended'.default.SHOW_COVERSHIELD);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	LAYOUT REFRESHING - THANKS XYMANEK!
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Called after all the values were set
simulated protected function RealizeExtendedLayout ()
{
	bLayoutRealizePending = true;

	// Avoid waiting until next frame
	// TODO: This may be quite brutal when doing the initial batch updates (start of the mission or loading a save) especially if there are many units. Need to test/profile
	if (AnyStatEntriesPendingSizeRealized())
	{
		Movie.ProcessQueuedCommands();
	}

	// Call this here to cover the case when none of the stat entries have been changed
	OnStatEntrySizeRealized();
}

simulated function OnStatEntrySizeRealized ()
{
	// Don't care if we are not ready to redo the layout
	if (!bLayoutRealizePending) return;

	// Ensure all of them are ready
	if (AnyStatEntriesPendingSizeRealized()) return;

	DoRealizeExtendedLayout();
}

// Assumes the width of all text was realized
simulated protected function DoRealizeExtendedLayout ()
{
	local UIUnitFlagExtended_StatEntry Entry;
	local float RollingX, RollingY, OffsetY;
	local bool bHasStatEntries;
	local int i, iRows;

	bLayoutRealizePending = false;

	OffsetY = class'WOTCLootIndicator_Extended'.default.STAT_OFFSET_Y + GetYShift();
	RollingY = 0;
	RollingX = 0;
	iRows = 0;

	foreach StatRowEntries(Entry)
	{
		//early bailout if not visible anyway
		if (!Entry.bIsVisible) { continue; }

		Entry.SetPosition(RollingX, RollingY);

		RollingX += Entry.Width + 4;

		//DO WE TRIGGER ANOTHER ROW?
		if (RollingX > class'WOTCLootIndicator_Extended'.default.iMAXSTATWIDTH)
		{
			RollingX = 0;
			RollingY += class'WOTCLootIndicator_Extended'.default.INFO_ICON_SIZE;
			iRows++;
	
			Entry.SetPosition(RollingX, RollingY);
			RollingX += Entry.Width + 4;
		}

		bHasStatEntries = true;
	}

	if (!bHasStatEntries)
	{
		StatRowContainer.Hide();
	}
	else
	{
		//BUMPS UP FOR EACH ADDITIONAL ROW
		for (i = 0 ; i < iRows ; i++)
		{
			OffsetY -= class'WOTCLootIndicator_Extended'.default.INFO_ICON_SIZE;
		}

		StatRowContainer.SetY(OffsetY);
		StatRowContainer.Show();

		//BUMPS UP ABOVE INITIAL STATS ROW
		OffsetY -= class'WOTCLootIndicator_Extended'.default.INFO_ICON_SIZE;
	}

	//SET HUDHEAD AND UNIT NAME ABOVE STATS ROWS
	if (HudHeadIcon != none) HudHeadIcon.SetY(OffsetY);
	if (UnitNameText != none) UnitNameText.SetY(OffsetY);
}

// TODO: Rework this ~ XYMANEK
function int GetYShift() 
{
	local XComGameState_Unit UnitState;
	local float fTotalHealthBars;
	local int Shift;

    local XComGameState_Effect_TemplarFocus FocusState;
	local bool bUnitHasFocusBar;
	local Object Tuple;

	//GET OUR UNIT, WE NEED IT ...
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
		Shift += class'WOTCLootIndicator_Extended'.default.SHIELD_SHIFT_Y;
	}

	// BUMP UP IF THEY ARE A 'RULER' FOR THE NUMBER OF EXTRA HP BARS, ACCOUNTS FOR ANY UNIT WITH MORE THAN ONE HEALTH BAR
	// INCLUDING VIPERKING, ARCHONKING, ZERKER QUEEN, HIVE QUEEN, CotK ... ALSO BUMPS CORRECTLY FOR BETA STRIKE BARS
	// 		!! MUCH THANKS TO IRIDAR, ROBOJUMPER AND XYMANEK FOR THE AID AND INSPIRATION !!
	fTotalHealthBars = Movie.GetVariableNumber(MCPath $ ".MeterTotal");
	if (fTotalHealthBars > 1.0)
	{
		Shift += class'WOTCLootIndicator_Extended'.default.ALIENRULER_SHIFT_Y * int(fTotalHealthBars -1);
	}

	// BUMP UP IF THEY HAVE A WILL BAR OR IT IS A DESTRUCTIBLE OBJECT (SAME VALUE NEEDED FOR BOTH ADJUSTMENTS)
	if (m_bUsesWillSystem && class'WOTCLootIndicator_Extended'.default.SHOW_WILL_BAR || ObjectType == eFOT_Destructible )
	{
		Shift += class'WOTCLootIndicator_Extended'.default.WILLBAR_SHIFT_Y;
	}

	// BUMP ONE LAST TIME IF THEY HAVE A FOCUS BAR
	if (bUnitHasFocusBar )
	{
		Shift += class'WOTCLootIndicator_Extended'.default.FOCUS_SHIFT_Y;
	}

	// this should shift everything DOWN if the stats and bars are hidden, so basically just the name and head icon, as that should be all that is left
	if ( (m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_BARS_ON_FRIENDLY)
		|| (!m_bIsFriendly.GetValue() && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth) )
	{
		Shift -= class'WOTCLootIndicator_Extended'.default.HIDDENBARS_SHIFT_Y;
	}

	return Shift;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UI MC CONTROLLER CONTROLS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
	Returns true if all movie clips that we may read values from are ready
	The function name is technically a lie since we don't check panels that	are only fed data in 1 direction (uc -> flash), 
	but the init state of those panels doesn't have any significance
*/

simulated protected function bool IsFullyInited ()
{
	local UIUnitFlagExtended_StatEntry Entry;

	// UFE - IF WE KNOW WE'RE ALREADY DONE, DON'T CHECK EVERYTHING AGAIN
	if (bIsFullyInited) { return true; }

	// Vanilla Flag
	if (!bIsInited) { return false; }

	// Status Panel
	if (!ExtendedStatusRowContainer.bIsInited) { return false; }

	// Stats texts
	foreach StatRowEntries(Entry) { if (!Entry.Text.bIsInited) return false; }

	//WE'RE DONE CHECKING - EVERYTHING WAS GOOD
	bIsFullyInited = true;

	return true;
}

//	Called when one of the panels that's checked in IsFullyInited (including self) is initialized
simulated protected function OnComponentPanelInited (UIPanel Panel)
{
	// Delay the initial update until everything is ready so that we can safely read from scaleform/flash
	if (!IsFullyInited()) return;

	DoInitialUpdate(); // remember this, yeah it was over 1000 lines ago ... 
}

simulated protected function bool AnyStatEntriesPendingSizeRealized ()
{
	local UIUnitFlagExtended_StatEntry Entry;

	foreach StatRowEntries(Entry)
	{
		if (!Entry.Text.TextSizeRealized)
		{
			return true;
		}
	}

	return false;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	DATA HOOKUP		<> TODO : REWORK THESE ~ XYMANEK
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function FindHUDIconDetails(out string strIcon, out string HexColour)
{
	local XComGameState_Unit UnitState;
	local X2VisualizerInterface Visualizer;
	local eUIState iColourState;

	if (ObjectType == eFOT_Unit)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));

		if (UnitState != none)
		{
			Visualizer = X2VisualizerInterface(UnitState.GetVisualizer());
		}
	}
	else if (ObjectType == eFOT_Destructible)
	{
		Visualizer = X2VisualizerInterface(History.GetVisualizer(StoredObjectID));
	}
	else
	{
		//ObjectType == eFOT_DestructibleNoFlag || eFOT_Invalid;
		//no point in finding out the HUD details as we have no flag anyway!
		return; //strIcon = "" , HexColour = "" 
	}

	//UNIT OR DESTRUCTIBLE VISUALIZER FOUND
	if (Visualizer != none)
	{
		strIcon = Visualizer.GetMyHUDIcon();
		iColourState = Visualizer.GetMyHUDIconColor();
	}

	//cut the 0x from the gethexcolourfromstate return
	HexColour = class'UIUtilities_Colors'.static.GetHexColorFromState(iColourState);
	HexColour = Right(HexColour, Len(HexColour) -2);

}

//ensures we do this once on initial init (or when forced to update)
//this is because all these checks are pretty intensive, especially if we have to go through the perks
function UpdateDamageString(XComGameState_Unit UnitState)
{
	DamageString.SetValue(class'X2EventListener_UFEGetDamage'.static.GetDamageString(self, UnitState));
}

function string GetWeaponValue(XComGameState_Unit UnitState, optional bool bGetShredInstead)
{
	local XComGameState_Item	WeaponState;
	local WeaponDamageValue 	BaseDamageValue;

	if (!bWeaponChecked)
	{
		bWeaponChecked = true;

		WeaponState = UnitState.GetPrimaryWeapon();
		if (WeaponState != none)
		{
			WeaponState.GetBaseWeaponDamageValue(none, BaseDamageValue);
			PierceString.SetValue(string(BaseDamageValue.Pierce));
			ShredString.SetValue(string(BaseDamageValue.Shred));
		}
	}

	return bGetShredInstead ? ShredString.GetValue() : PierceString.GetValue();
}

//	!! MOVED FUNCTION TO ELR TO AVOID DUPLICATE CODE !!
/*
function string GetDamageString(XComGameState_Unit UnitState, optional bool bForcedToUseSecondary)
{
	local StateObjectReference 		ObjectRef;
	local X2AbilityTemplateManager 	AbilityManager;
	local X2AbilityTemplate 		AbilityTemplate;
	local XComGameState_Tech		BreakthroughTech;
	local XComGameState_Item 		WeaponState;
	local X2Techtemplate			TechTemplate;
	local X2WeaponTemplate 			WeaponTemplate;
	local X2Effect					TargetEffect;
	local int minDamage, maxDamage;

    AbilityManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	WeaponState = UnitState.GetPrimaryWeapon();

	//if primary is a bust attempt to get secondary - should fix 'secondary only ' users
	if (WeaponState == none || bForcedToUseSecondary)
	{
		WeaponState = UnitState.GetSecondaryWeapon();
		bForcedToUseSecondary = true;
	}

	//if weapon is still bust, bail to perks, if not find damage ranges
	if (WeaponState != none)
	{
		WeaponTemplate = X2WeaponTemplate (WeaponState.GetMyTemplate()) ;

		//calculate min and max damage value from WeaponDamageValues
		minDamage = WeaponTemplate.BaseDamage.Damage - WeaponTemplate.BaseDamage.Spread;
		maxDamage = WeaponTemplate.BaseDamage.Damage + WeaponTemplate.BaseDamage.Spread;

		if ( WeaponTemplate.BaseDamage.PlusOne > 0 ) { maxDamage++; }

		// ===== ACCOUNT FOR BREAKTHROUGH DAMAGES TO THE BASE WEAPON, ONLY EVER APPLIES TO PRIMARY WEAPONS !! ===== //
		// WE ONLY DO THIS CHECK ONCE FOR CASES WHERE THE DAMAGE STRING IS FORCED TO UPDATE, CUTS OUT A HUGE LAG HANG
		if (!m_BreakthroughBonusesFound)
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
							m_BreakthroughBonuses = ( m_BreakthroughBonuses + X2Effect_BonusWeaponDamage(TargetEffect).BonusDmg);
						}
					}
				}
			}
			m_BreakthroughBonusesFound = true;
		}

		//bump up damage if the unit is friendly and has a bonus amount 
		if (m_bIsFriendly.GetValue())
		{
			minDamage += m_BreakthroughBonuses;
			maxDamage += m_BreakthroughBonuses;
		}

		//=============================================================
		//=============================================================

		//in case there was a weapon with higher minimum damage than the max ??
		if (minDamage > maxDamage) { maxDamage = minDamage; }

		//damage output is 'none', force try secondary .. if none and secondary still has none, try perks
		if( (maxDamage - minDamage < 0 || maxDamage <= 0))
		{
			if (bForcedToUseSecondary)
			{
				return GetDamageString_FromPerks(UnitState); //"---";
			}

			return GetDamageString(UnitState, true);
		}

		//damages are the same, use max
		if(maxDamage - minDamage == 0)
		{
			return string(maxDamage);
		}
		
		//damage is a range, x - y
		return minDamage $ "-" $ maxDamage;
	}

	//couldn't find a weapon state
	return GetDamageString_FromPerks(UnitState); //"-!-";
}

//this is potentially very intensive as it looks at ALL the units perks and gets absolute minimum to maximum damage output across all perks
//thus this is only used on units that have no damage display after a primary and secondary weapon check is done
//which should minimise when this happens, except for fuxxing chryssalid swarms .. and the lost ..
function string GetDamageString_FromPerks(XComGameState_Unit UnitState)
{
	local array<StateObjectReference> arrData;
	local StateObjectReference Data;

	local XComGameState_Ability AbilityState;

	local WeaponDamageValue MinDamagePreview, MaxDamagePreview;
	local int AllowsShield, minDamage, maxDamage, minDamageC, maxDamageC;

	arrData = UnitState.Abilities;

	foreach arrData(Data)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Data.ObjectID));

		//MinDamagePreview, MaxDamagePreview, AllowsShield ? are out values
		//Feeding ourself gets us output damage as ourselves as primary target, not perfect but a neccessary evil ..
		//Feeding a null Target gets us Mutli-target attacks -- NOT REQUIRED ? IT WAS ALWAYS REPORTING the same as this --
		AbilityState.GetDamagePreview(UnitState.GetReference(), MinDamagePreview, MaxDamagePreview, AllowsShield);

		minDamageC = MinDamagePreview.Damage - MinDamagePreview.Spread;
		maxDamageC = MaxDamagePreview.Damage + MaxDamagePreview.Spread;

		if ( MaxDamagePreview.PlusOne > 0) { maxDamageC++; }

		//record the values
		if (minDamage == 0 && minDamageC > 0)  			{ minDamage = minDamageC; } // intitial setting?
		if (minDamageC > 0 && minDamageC < minDamage)	{ minDamage = minDamageC; } // found a lower value that is not 0
		if (maxDamageC > maxDamage) 					{ maxDamage = maxDamageC; } // always increase max if it is higher
	}

	//in case there was a perk with higher minimum damage than the recorded max ??
	if (minDamage > maxDamage) { maxDamage = minDamage; }

	//damage output is STILL 'none', subtly report as an 'error'
	if( (maxDamage - minDamage < 0 || maxDamage <= 0))
	{
		return "---";
	}

	//damages are the same, use max
	if(maxDamage - minDamage == 0)
	{
		return string(maxDamage);
	}
	
	//damage is a range, x - y
	return minDamage $ "-" $ maxDamage;
}
*/
