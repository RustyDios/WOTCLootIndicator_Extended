//=============================================================
//  FILE:   UnitFlagExtendedHelpers  by Xymanek && RustyDios
//  
//	File created	13/07/22	17:00
//	LAST UPDATED	17/08/22	03:30
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
	var string IconPath;
};

/////////////////////////////////////////////////////////////////////////////////////////////
//	USED TO FIGURE OUT WHAT STATUS ICONS TO SHOW
/////////////////////////////////////////////////////////////////////////////////////////////

static function array<string> GetCurrentStatusIconPaths(XComGameState_Unit NewUnitState, bool bIsBound)
{
	local array<string> Icons;
	local EffectStatusIcon ConfigStatusIcon;

	Icons.length = 0;

	//get icon paths from CHL/source, thanks to CHL Issue #1120 this will only contain image paths for statuses that have one
	Icons = NewUnitState.GetUISummary_UnitStatusIcons();

	//adding extended viper bind effect checks
	if (bIsBound && Icons.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Bound) == INDEX_NONE)
	{ Icons.AddItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Bound); }

	//add icons for common status effects that might not have them, if they are not already here
	//add icons that have been setup through config .. burning, poison, ko, marked, disorient, panic, stunned, freeze, mind control
	foreach class'WOTCLootIndicator_Extended'.default.EffectStatusIcons(ConfigStatusIcon)
	{
		if (Icons.Find(ConfigStatusIcon.IconPath) == INDEX_NONE && NewUnitState.AffectedByEffectNames.Find(ConfigStatusIcon.EffectName) != INDEX_NONE)
		{
			Icons.AddItem(ConfigStatusIcon.IconPath);
		}
	}

	//adding rupture as a status icon .. instead of RealizeRupture in UnitFlag
	if ( Icons.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Bleed) == INDEX_NONE && NewUnitState.GetRupturedValue() > 0 )
	{ Icons.AddItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Bleed); }		//{ Icons.AddItem("img:///gfxUnitFlag.shred_icon"); }

	//adding homing mine as a status icon .. also included in effect list above .. instead of RealizeClaymore in UnitFlag
	if ( Icons.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Mined) == INDEX_NONE && NewUnitState.AffectedByEffectNames.Find(class'X2Effect_HomingMine'.default.EffectName) != INDEX_NONE)
	{ Icons.AddItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Mined); }		//{ Icons.AddItem("img:///gfxUnitFlag.UnitFlag_IC0");	}

	//Cascade Frost Icons, if frozen .. remove chillx ... if chill2 remove chill1
	//this should mean we always only have the 'highest' chill icon 
	if (Icons.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[3]) != INDEX_NONE)
	{
		Icons.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[2]);
		Icons.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[1]);
		Icons.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[0]);
	}
	else if (Icons.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[2]) != INDEX_NONE)
	{
		Icons.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[1]);
		Icons.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[0]);
	}
	else if (Icons.Find(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[1]) != INDEX_NONE)
	{
		Icons.RemoveItem(class'WOTCLootIndicator_Extended'.default.StatusIconPath_Frozen[0]);
	}

	// <> TODO : Add MindControl/Domination/Hacked icons ?
	// <> TODO : Add concealment status as a status icon ?
	// <> TODO : Add overwatch icon as a status icon ?

	return Icons;
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
