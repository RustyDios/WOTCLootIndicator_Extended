//=============================================================
//  FILE:   UnitFlagExtendedHelpers  by Xymanek && RustyDios
//  
//	File created	13/07/22	17:00
//	LAST UPDATED	28/03/23	02:30
//
//=============================================================

class UnitFlagExtendedHelpers extends Object abstract;

enum EStatsRowEntryType
{
	eSRET_UnitStat,
	eSRET_Damage,
};

struct StatsBlock
{
    var string BlockName;
    var string IconPath;
	var string IconColour;
    var string HexColour;
    var ECharStatType Stat;
    var int bCanObsfucate;
    var name SpecialTriggerID;
};

struct StatRowEntryDefinition
{
	var name BlockName;
	var EStatsRowEntryType Type;
    var ECharStatType Stat;

    var string IconPath;
	var string IconColour;
    var string HexColour;
    
	var bool bCanObsfucate;
    var name SpecialTriggerID;
};

struct SpecialBarColour
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

struct EffectStatusIcon
{
	var name EffectName;
	var string IconPathM;
	var string IconPathC;
};

/////////////////////////////////////////////////////////////////////////////////////////////
//	USED TO FIGURE OUT WHAT STATUS ICONS TO SHOW
/////////////////////////////////////////////////////////////////////////////////////////////

static function array<string> GetCurrentStatusIconPaths(XComGameState_Unit NewUnitState, bool bIsBound)
{
	local array<EffectStatusIcon> EffectStatusIcons;
	local EffectStatusIcon ConfigStatusIcon;
	local array<string> IconPaths;
	local string CurrentPath;
	local bool bUseColouredStatusIcons;

	IconPaths.length = 0;

	//get icon paths from CHL/source, thanks to CHL Issue #1120 this will only contain image paths for statuses that have one
	// !! NOTE !! -- I HAVE ZERO CONTROL OVER WHAT THE ICON PATHS ARE SET TO FROM THIS STEP
	// HOWEVER I INCLUDE IT FOR COMPATIBILITY WITH OTHER MODS/USERS
	IconPaths = NewUnitState.GetUISummary_UnitStatusIcons();

	//CHECK IF WE SHOULD USE COLOURED ICONS OR NOT
	bUseColouredStatusIcons = class'WOTCLootIndicator_Extended'.default.bUseColouredStatusIcons;

	//adding extended viper bind effect checks
	if (bIsBound)
	{
		CurrentPath = bUseColouredStatusIcons ? class'WOTCLootIndicator_Extended'.default.StatusIconPath_BoundC : class'WOTCLootIndicator_Extended'.default.StatusIconPath_BoundM;
		AddIfMissing(CurrentPath, IconPaths);
	}

	//add icons for common status effects that might not have them, if they are not already here
	//add icons that have been setup through config .. burning, poison, ko, marked, disorient, panic, stunned, freeze, mind control
	EffectStatusIcons = class'WOTCLootIndicator_Extended'.default.EffectStatusIcons;
	
	foreach EffectStatusIcons(ConfigStatusIcon)
	{
		if (NewUnitState.AffectedByEffectNames.Find(ConfigStatusIcon.EffectName) != INDEX_NONE)
		{
			CurrentPath = bUseColouredStatusIcons ? ConfigStatusIcon.IconPathC : ConfigStatusIcon.IconPathM;
			AddIfMissing(CurrentPath, IconPaths);
		}
	}

	//adding rupture as a status icon .. instead of RealizeRupture in UnitFlag
	if (NewUnitState.GetRupturedValue() > 0 )
	{
		CurrentPath = bUseColouredStatusIcons ? class'WOTCLootIndicator_Extended'.default.StatusIconPath_BleedC : class'WOTCLootIndicator_Extended'.default.StatusIconPath_BleedM;
		AddIfMissing(CurrentPath, IconPaths); //{ IconPaths.AddItem("img:///gfxUnitFlag.shred_icon"); }
	}

	//adding homing mine as a status icon .. also included in effect list above .. instead of RealizeClaymore in UnitFlag
	if (NewUnitState.AffectedByEffectNames.Find(class'X2Effect_HomingMine'.default.EffectName) != INDEX_NONE)
	{
		CurrentPath = bUseColouredStatusIcons ? class'WOTCLootIndicator_Extended'.default.StatusIconPath_MinedC : class'WOTCLootIndicator_Extended'.default.StatusIconPath_MinedM;
		AddIfMissing(CurrentPath, IconPaths); //{ IconPaths.AddItem("img:///gfxUnitFlag.UnitFlag_IC0");	}
	}

	MergeFrostPaths(IconPaths);

	// <> TODO : Add MindControl/Domination/Hacked icons ?
	// <> TODO : Add concealment status as a status icon ?
	// <> TODO : Add overwatch icon as a status icon ?

	return IconPaths;
}

static function AddIfMissing(string CurrentPath, out array<string> IconPaths)
{
	if (IconPaths.Find(CurrentPath) == INDEX_NONE )
	{
		IconPaths.AddItem(CurrentPath);
	}
}

static function MergeFrostPaths(out array<string> IconPaths)
{
	//Cascade Frost Icons, if frozen .. remove chillx ... if chill2 remove chill1
	//this should mean we always only have the 'highest' chill icon 
	if (IconPaths.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[3]) != INDEX_NONE
		|| IconPaths.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[3]) != INDEX_NONE)
	{
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[2]);
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[1]);
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[0]);

		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[2]);
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[1]);
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[0]);
	}
	else if (IconPaths.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[2]) != INDEX_NONE
		|| IconPaths.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[2]) != INDEX_NONE)
	{
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[1]);
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[0]);

		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[1]);
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[0]);
	}
	else if (IconPaths.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[1]) != INDEX_NONE
		|| IconPaths.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[1]) != INDEX_NONE)
	{
		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenM[0]);

		IconPaths.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_FrozenC[0]);
	}
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
//		Text.SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo( ColorText("STRING", HexColour),false,false,false,default.INFO_FONT_SIZE) );
//		AddShadowToTextField(Text);
//
/////////////////////////////////////////////////////////////////////////////////////////////

static function string ColourText (string strValue, string strHexColour)
{
	return "<font color='#" $ strHexColour $ "'>" $ strValue $ "</font>";
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
