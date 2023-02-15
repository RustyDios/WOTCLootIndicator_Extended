//=============================================================
//  FILE:   UIUnitFlagExtended  by Xymanek && RustyDios
//  
//	File created	13/07/22	17:00
//	LAST UPDATED	15/02/23    00:45
//
//	<> TODO : Rework && Update Y Shift value correctly
//	<> TODO : Multiple Stat lines if the Stats Block excedes HealthBar length
//
//=============================================================

class UIUnitFlagExtended extends UIUnitFlag dependson(UnitFlagExtendedHelpers);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	GAME STATE CACHING
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum EFlagObjectType
{
	eFOT_Invalid,
	eFOT_Unit,
	eFOT_Destructible,
	eFOT_DestructibleNoFlag,
};

var EFlagObjectType ObjectType;

var bool bObfuscate;

var int m_BreakthroughBonuses;
var bool m_BreakthroughBonusesFound;

var CachedString HealthBarColour, ShieldBarColour, DamageString;

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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	INIT
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function InitFlag (StateObjectReference ObjectRef)
{
	local XComDestructibleActor DestructibleActor;

	super.InitFlag(ObjectRef);

	HealthBarColour = new class'CachedString';
	ShieldBarColour = new class'CachedString';
	DamageString	= new class'CachedString';

	// Determine what we are representing
	DestructibleActor = XComDestructibleActor(History.GetVisualizer(StoredObjectID));
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
	else if (XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID)) != none)
	{
		ObjectType = eFOT_Unit;
	}

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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	REFRESH/UPDATE 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
	// Expanded version of the same check as in super
	if (!IsFullyInited()) return;

	super.RespondToNewGameState(NewState,bForceUpdate);
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

	UpdateUnitDamageStat(NewUnitState);
	UpdateUnitStats(NewUnitState);

	UpdateBarColours_Health(NewUnitState);
	UpdateBarColours_Shield(NewUnitState);
}

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

	// Disable hitpoints preview visualization - sbatista 6/24/2013 [? more like set to merge HP/ShieldHP preview displays - RustyDios]
	// <> TODO : Investigate if this is needed if ShieldHp <=0 
	SetShieldPointsPreview();
}

//Technically NO CHANGE here now as Armor Text+Icon is a STAT BLOCK thing, Armour Pips are always shown ...
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
	LootIcon.Hide();
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
	local string strUnitName, IconString, IconColour;

	//Find and set colour
	FindHUDIconDetails(IconString, IconColour);

	if (HudHeadIcon != none)
	{
		//HudHeadIcon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		HudHeadIcon.LoadIcon(class'UIUtilities_Image'.static.ValidateImagePath(IconString));

		HudHeadIcon.SetBGColor("0x" $ IconColour);
		HudHeadIcon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath(IconString $"_bg"));
		HudHeadIcon.Show();
	}
	
	if (   ( m_bIsFriendly.GetValue() && class'WOTCLootIndicator_Extended'.default.SHOW_FRIENDS_NAME )
		|| (!m_bIsFriendly.GetValue() && class'WOTCLootIndicator_Extended'.default.SHOW_ENEMIES_NAME ) )
	{
	
		//get the displayed name , set its size , then its colour
		strUnitName = GetUnitDisplayedName(NewUnitState);
		strUnitName = class'UIUtilities_Text'.static.AddFontInfo(strUnitName, false, false, false, class'WOTCLootIndicator_Extended'.default.NAME_FONT_SIZE);
		strUnitName = class'UnitFlagExtendedHelpers'.static.ColourText(
			strUnitName, class'WOTCLootIndicator_Extended'.default.NAME_COLOUR_BYTEAM ? IconColour : class'WOTCLootIndicator_Extended'.default.NAME_COLOURHEX );

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
	local bool IsEffected;

	//bailout if using new status row
	if (!class'WOTCLootIndicator_Extended'.default.bDISABLE_NEW_STATUS_ROW) { return; }

	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	if( NewUnitState != none )
	{
		IsEffected = NewUnitState.AffectedByEffectNames.Find(class'X2Effect_HomingMine'.default.EffectName) > -1;
		if( IsEffected != m_bShowingClaymore )
		{
			AS_SetClaymore(IsEffected);
			m_bShowingClaymore = IsEffected;
		}
	}
}

//cancel base game rupture if we add it to the status row now
//This function will be spammed, so please only send changes to flash.
simulated function RealizeRupture(XComGameState_Unit NewUnitState)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	//bailout if using new status row
	if (!class'WOTCLootIndicator_Extended'.default.bDISABLE_NEW_STATUS_ROW) { return; }

	myValue.Type = AS_Boolean;
	myValue.b = NewUnitState.GetRupturedValue() > 0;
	myArray.AddItem(myValue);

	Invoke("SetShred", myArray);	//  <> TODO : - UI - rename this ? --- not a RustyNote, this is the flash function call
}

simulated function RealizeStatus(optional XComGameState_Unit NewUnitState = none)
{
	local array<string> Icons;
	local int i, StatusIconX;

	if( NewUnitState == none ) { NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID)); }

	//NOTE: The UI currently only supports one status icon, and this is intentional from design. 
	// I suspect we may need to stack them or show more in the future, so I'm handling everything in an array.
	// Will update the flag to handle multiple icons if we need to. -bsteiner 26/02/2015

	//Updated to handle multiple icons thanks to bsteiner handling it as an array way back then - RustyDios 16/08/2022

	//get mod extended status icon paths
	Icons.length = 0;
	Icons = class'UnitFlagExtendedHelpers'.static.GetCurrentStatusIconPaths(NewUnitState, IsUnitBound(NewUnitState) );

	//set or hide our new status icons panel
	if( Icons.length <= 0 )
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
			AS_SetStatusIcon(Icons[0]);
			ExtendedStatusRowContainer.Hide();
			return;
		}

		//use new behaviour and nullify base game icon setting
		AS_SetStatusIcon("");

		//reset X position
		StatusIconX = 0 - (class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE / 4) ;

		//create or set new icons
		//yes this happens on the realize as the icons need to refresh too
		for (i = 0; i < Icons.length; i++)
		{
			if (StatusIcons[i] == none)
			{
				StatusIcons.AddItem(Spawn(class'UIIcon', ExtendedStatusRowContainer));
				InitStatusIcon(StatusIcons[i], name("StatusIcons_UFE_" $ i), Icons[i]);
			}
			else
			{
				StatusIcons[i].LoadIcon(Icons[i]);
			}
			
			//space correctly and show
			StatusIcons[i].SetPosition(StatusIconX, 22);
			StatusIconX += class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE - (class'WOTCLootIndicator_Extended'.default.ESTI_ICON_SIZE / 4) ;
			StatusIcons[i].Show();
		}

		//remove any uneeded icons
		for (i = StatusIcons.length -1 ; i >= Icons.length; i--)
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

	//bail if not a unit or destructible needing a flag
	if (ObjectType != eFOT_Unit && ObjectType != eFOT_Destructible) return;

	//create a container for the stats icons and texts
	StatRowContainer = Spawn(class'UIPanel', self);
	StatRowContainer.bAnimateOnInit = false;
	StatRowContainer.bIsNavigable = false;
	StatRowContainer.InitPanel('StatRowContainer');
	StatRowContainer.Hide(); // Gets shown when realized
	StatRowContainer.SetX(class'WOTCLootIndicator_Extended'.default.STAT_OFFSET_X);

	//add the special section for damage preview - always first
	if (class'WOTCLootIndicator_Extended'.default.SHOW_DAMAGE && ObjectType == eFOT_Unit)
	{
		EntryDef = EmptyDef;
		EntryDef.BlockName = 'Damage';
		EntryDef.Type = eSRET_Damage;
		EntryDef.IconPath = class'WOTCLootIndicator_Extended'.default.SHOW_DMG_ICONPATH; //"UILibrary_UIFlagExtended.UIFlag_Damage";
		EntryDef.HexColour = class'WOTCLootIndicator_Extended'.default.SHOW_DMG_COLOURHEX;
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
		EntryDef.HexColour = BlockDef.HexColour;
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
		if (   ( m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_FRIENDS )
			|| (!m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_ENEMIES ) )
		{
			Entry.Hide();
			continue;
		}

		// No per-stat value handling if obfuscated, sets as "##" or damage as "#-#"
		if (TryObsfucate(Entry, NewUnitState)) { continue; }

		// Set Value based on event trigger listener from mod addition
		if (Entry.Definition.SpecialTriggerID != '' )
		{
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			// allow mods to change/add the shown value for a stats config entry
			NSLWTuple = new class'LWTuple';
			NSLWTuple.Id = 'UIUnitFlag_AddDisplayInfo';
			NSLWTuple.Data.Add(1);
			NSLWTuple.Data[0].kind = LWTVString;	// What the info should be
			NSLWTuple.Data[0].s = "";
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			`XEVENTMGR.TriggerEvent(Entry.Definition.SpecialTriggerID, NSLWTuple, NewUnitState );
			Entry.SetValue(NSLWTuple.Data[0].s);
			continue;
		}

		// set value based on stat entry
		fCurrentValue = NewUnitState.GetCurrentStat(Entry.Definition.Stat);
		iCurrentValue = int(fCurrentValue); // <> TODO : Are we sure we don't want rounding here?

		switch (Entry.Definition.Stat)
		{
			// Prevent the warning from the default block, as HP is handled elsewhere
			case eStat_HP: break;

			// Stats with standard handling
			case eStat_Offense:
			case eStat_Defense:
			case eStat_Dodge:
			case eStat_Hacking:
			case eStat_PsiOffense:
			case eStat_ShieldHP:
			case eStat_ArmorChance:
			case eStat_ArmorPiercing:
			case eStat_CritChance:
			case eStat_FlankingCritChance:
			case eStat_FlankingAimBonus:
			case eStat_DetectionRadius:
			case eStat_SightRadius:
				Entry.SetValue(iCurrentValue);
			break;

			// Armour has special handling as the pips use a combination of stat+effect
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

			default:
				Entry.Hide();

				`LOG("UNIDENTIFIED STAT TYPE PASSED TO SWITCHBLOCK :"
						@"\n Block	:" $Entry.Definition.BlockName
						@"\n Type	:" $Entry.Definition.Type
						@"\n Stat	:" $Entry.Definition.Stat
						@"\n Icon	:" $Entry.Definition.IconPath
						@"\n Hex	:" $Entry.Definition.HexColour
						@"\n Obs	:" $Entry.Definition.bCanObsfucate
						@"\n ID		:" $Entry.Definition.SpecialTriggerID
					, class'WOTCLootIndicator_Extended'.default.bRustyUIFlagLog,'WOTC_RUSTY_UIFLAG');
		}
	}
}

simulated protected function UpdateUnitDamageStat (XComGameState_Unit NewUnitState)
{
	local UIUnitFlagExtended_StatEntry Entry;

	foreach StatRowEntries(Entry)
	{
		if (Entry.Definition.Type != eSRET_Damage) { continue; }

		// Are we hiding friendly stats OR hiding enemy stats ?
		if (   ( m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_FRIENDS )
			|| (!m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_ENEMIES ) )
		{
			Entry.Hide();
			continue;
		}

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
		if (   ( m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_FRIENDS )
			|| (!m_bIsFriendly.GetValue() && !class'WOTCLootIndicator_Extended'.default.SHOW_STATS_ON_ENEMIES ) )
		{
			Entry.Hide();
			continue;
		}

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
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = LWTVObject;
	Tuple.Data[0].o = NewUnitState;		// The targeted unit. Not really required anymore, as event sends as SourceData! Needed to keep for backwards compatibility :(
	Tuple.Data[1].kind = LWTVBool;
	Tuple.Data[1].b = true;				// Whether the info should be available. true = show, false = hide

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

	if (Entry.Definition.Type == eSRET_Damage)
	{
		Entry.SetValue("#-#");
	}
	else
	{
		Entry.SetValue("##");
	}

	return true;
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
	local string IconString, IconColour;

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

	//find and set team colour
	IconString = "";
	IconColour = "";

	FindHUDIconDetails(IconString, IconColour);

	return IconColour;
}

simulated protected function UpdateBarColours_Health (optional XComGameState_Unit NewUnitState)
{
	//only do the recolour of Health if it is a unit and set to do so by the config
	if (ObjectType != eFOT_Unit || !class'WOTCLootIndicator_Extended'.default.HPBAR_COLOUR_BYTEAM )  { return; }

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

simulated function bool IsHealthBarCreatedInFlash()
{
	return Movie.GetVariableObject(MCPath $".healthMeter.theMeter") != none;
}

//called in the OnTick Update to change the bar colour, after it has been created and only if it needs changing
simulated function TrySetHealthBarColour(optional bool bWasSpecial)
{
	local float fTotalHealthBars;
	local int i;

	if (!bCheckAndSetHealthBarColour) { return; }

	if (!bHealthBarCreated)
	{
		bHealthBarCreated = IsHealthBarCreatedInFlash();
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
	local string IconString, IconColour;

	//Override frosty shields above all else
	if ( class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOUR_FROSTLEGION && NewUnitState.HasAbilityFromAnySource('MZ_FDIceShield') )
	{
		//set as 'frosty' shield colour for the Frost Legion Dudes
		return class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOURHEX_FROSTLEGION;
	}

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

	//check for if team colours on .. find and set team colour
	if ( (class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOUR_BYTEAM_ENEMIES && !m_bIsFriendly.GetValue() )
	  || (class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOUR_BYTEAM_FRIENDS && m_bIsFriendly.GetValue() ) )
	{
		//check for if team colours on .. find and set team colour
		IconString = "";
		IconColour = "";

		FindHUDIconDetails(IconString, IconColour);

		return IconColour;
	}

	// in all other cases set default shield bar colour
	return class'WOTCLootIndicator_Extended'.default.SHIELDBAR_COLOURHEX_DEFAULT;
}

//this had to be extended to check the shield bar has been created in flash before we try to recolour it
simulated protected function UpdateBarColours_Shield (optional XComGameState_Unit NewUnitState)
{
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

simulated function bool IsShieldBarCreatedInFlash()
{
	return Movie.GetVariableObject(MCPath $".healthMeter.shieldMeter") != none;
}

//called in the OnTick Update to change the bar colour, after it has been created and only if it needs changing
simulated function TrySetShieldBarColour()
{
	if (!bCheckAndSetShieldBarColour) { return; }

	if (!bShieldBarCreated)
	{
		bShieldBarCreated = IsShieldBarCreatedInFlash();
	}

	if (bShieldBarCreated)
	{
		bCheckAndSetShieldBarColour = false;
		AS_SetMCColor(MCPath $".healthMeter.shieldMeter.theMeter", ShieldBarColour.GetValue());
	}
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
// Start Issue #257 -- deprecated, 
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
	//		local XComGameState_Effect_TemplarFocus FocusState;
	//		FocusState = UnitState.GetTemplarFocusEffectState();
	//		Tuple.Data[0].b = FocusState != none;																							//Has Bar?
	//
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
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function bool IsUnitBound(XComGameState_Unit NewUnitState)
{
	local name EffectName;

	foreach class'WOTCLootIndicator_Extended'.default.BindEffects (EffectName)
	{
		if (NewUnitState.AffectedByEffectNames.Find(EffectName) != INDEX_NONE)
		{
			return true;
		}
	}

	return false;
}

simulated function RealizeViperBind(XComGameState_Unit NewUnitState)
{

	super.RealizeViperBind(NewUnitState);

	//const VIPER_BIND_OFFSET = 30; // 30 may have been fine for base game, but it's not for this with with all the extra stats and stuff
	//The unit flag for the unit being bound will overlap with the Viper's unit flag without an offset.
	//m_LocalYOffset = NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_Viper'.default.BindSustainedEffectName) ? VIPER_BIND_OFFSET : 0;

	// Shift the whole flag down if bound
	m_LocalYOffset = IsUnitBound(NewUnitState) ? class'WOTCLootIndicator_Extended'.default.BIND_SHIFT_Y : 0;

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// THIS FUNCTION CONTROLS THE COVER SHIELD OVERRIDDEN HERE SO THAT CLIBANARIUS HAS A CONFIG OPTION TO HIDE IT
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function RealizeCover(optional XComGameState_Unit UnitState = none, optional int HistoryIndex = INDEX_NONE)
{
	super.RealizeCover(UnitState, HistoryIndex);
	
	MC.ChildSetBool ("coverStatusObj","_visible", class'WOTCLootIndicator_Extended'.default.SHOW_COVERSHIELD);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	LAYOUT REFRESHING
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
	local float RollingX, RollingY;
	local bool bHasStatEntries;

	bLayoutRealizePending = false;

	RollingY = class'WOTCLootIndicator_Extended'.default.STAT_OFFSET_Y + GetYShift();
	RollingX = 0;

	foreach StatRowEntries(Entry)
	{
		//early bailout if not visible anyway
		if (!Entry.bIsVisible) { continue; }

		Entry.SetX(RollingX);

		RollingX += Entry.Width + 3;
		bHasStatEntries = true;
	}

	if (!bHasStatEntries)
	{
		StatRowContainer.Hide();
	}
	else
	{
		StatRowContainer.Show();
		StatRowContainer.SetY(RollingY);

		RollingY -= class'WOTCLootIndicator_Extended'.default.INFO_ICON_SIZE;
	}

	if (HudHeadIcon != none) HudHeadIcon.SetY(RollingY);
	if (UnitNameText != none) UnitNameText.SetY(RollingY);
}

// TODO: Rework this
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

	// BUMP UP IF THEY HAVE A WILL BAR OR IT IS A DESTRUCTIBLE OBJECT
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

	// Flag itself
	if (!bIsInited) return false;

	// Status Panel
	if (!ExtendedStatusRowContainer.bIsInited) return false;

	// Stats text
	foreach StatRowEntries(Entry)
	{
		if (!Entry.Text.bIsInited) return false;
	}

	return true;
}

//	Called when one of the panels that's checked in IsFullyInited (including self) is initialized
simulated protected function OnComponentPanelInited (UIPanel Panel)
{
	// Delay the initial update until everything is ready so that we can safely read from scaleform
	if (!IsFullyInited()) return;

	DoInitialUpdate();
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
//	DATA HOOKUP		<> TODO : REWORK THESE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function FindHUDIconDetails(out string strIcon, out string HexColour)
{
	local XComGameState_Unit UnitState;
	local X2VisualizerInterface Visualizer;
	local eUIState iColourState;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	Visualizer = X2VisualizerInterface(UnitState.GetVisualizer());

	strIcon = Visualizer.GetMyHUDIcon();
	iColourState = Visualizer.GetMyHUDIconColor();

	//cut the 0x from the gethexcolourfromstate return
	HexColour = class'UIUtilities_Colors'.static.GetHexColorFromState(iColourState);
	HexColour = Right(HexColour, Len(HexColour) -2);
}

//ensures we do this once on initial init
function UpdateDamageString(XComGameState_Unit UnitState)
{
	DamageString.SetValue(GetDamageString(UnitState));
}

function string GetDamageString(XComGameState_Unit UnitState, optional bool bForceSecondary)
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
	if (WeaponState == none || bForceSecondary)
	{
		WeaponState = UnitState.GetSecondaryWeapon();
		bForceSecondary = true;
	}

	//if weapon is still bust, bail to perks
	if (WeaponState != none)
	{
		WeaponTemplate = X2WeaponTemplate (WeaponState.GetMyTemplate()) ;

		minDamage = WeaponTemplate.BaseDamage.Damage - WeaponTemplate.BaseDamage.Spread;
		maxDamage = WeaponTemplate.BaseDamage.Damage + WeaponTemplate.BaseDamage.Spread;

		if ( WeaponTemplate.BaseDamage.PlusOne > 0 ) { maxDamage++; }

		//=================================================================//
		// ===== ACCOUNT FOR BREAKTHROUGH DAMAGES TO THE BASE WEAPON ===== //
		//=================================================================//
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
			if (bForceSecondary)
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
		//Feeding ourself gets us output damage as ourselves as primary target
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
