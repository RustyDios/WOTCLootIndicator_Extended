//=============================================================
//  FILE:   WOTCLootIndicator_Extended  by RustyDios
//  
//	File created	04/11/20    02:20
//	LAST UPDATED	28/03/23    08:00
//
//	MASSIVE UPDATE IN CONJUNCTION WITH XYMANEK
//	THIS IS MAINLY NOW JUST THE CONFIG BRIDGE FOR BACKWARDS COMPATIBILITY
//  <> TODO : MAKE THIS ALL MCM OPTIONS
//
//=============================================================

class WOTCLootIndicator_Extended extends UIUnitFlag dependson(UnitFlagExtendedHelpers) config(WOTCLootIndicator_Extended);

//moved structs to HELPERS.uc

var config array<name> BindEffects, ShowLootEffects;

var config array<StatsBlock> StatsToShow;
var config array<SpecialBarColour> SpecialBarColours_Health, SpecialBarColours_Shield;

var config array<EffectStatusIcon> EffectStatusIcons;
var config array<string> StatusIconPath_FrozenM, StatusIconPath_FrozenC;
var config string StatusIconPath_BoundM, StatusIconPath_RuptureM, StatusIconPath_MinedM;
var config string StatusIconPath_BoundC, StatusIconPath_RuptureC, StatusIconPath_MinedC;
var config bool bUseColouredStatusIcons;

var config EWidgetColor eColour_WillBar;

var config bool bRustyUIFlagLog, bDISABLE_NEW_STATUS_ROW, SHOW_HUDHEAD, SHOW_RULERHEAD;
var config bool NAME_COLOUR_BYTEAM, HPBAR_COLOUR_BYTEAM, SHIELDBAR_COLOUR_BYTEAM_FRIENDS, SHIELDBAR_COLOUR_BYTEAM_ENEMIES, SHIELDBAR_COLOUR_FROSTLEGION;
var config bool TEXT_COLOUR_BYTEAM, ICONS_COLOUR_BYTEAM, ICONS_COLOUR_BYTEXT;

var config bool SHOW_LOOT, REQUIRE_SCANNING, PERSISTANT_SCANS, SHOW_STATS_ON_ENEMIES, SHOW_STATS_ON_FRIENDS, SHOW_BARS_ON_FRIENDLY, SHOW_FRIENDS_NAME, SHOW_ENEMIES_NAME;
var config bool SHOW_MAX_HP, SHOW_WILL_BAR, SHOW_MAX_WILL, SHOW_PERCENT_WILL, SHOW_COVERSHIELD, SHOW_DAMAGE, SHOW_DMG_OBFUSCATE, SHOW_MOB_AS_TILES;
var config bool SHOW_ARMOUR_PIPS;

var config string SHOW_DMG_ICONPATH, SHOW_DMG_COLOURHEX, NAME_COLOURHEX, SHIELDBAR_COLOURHEX_DEFAULT, SHIELDBAR_COLOURHEX_FROSTLEGION;

var config int SHIELD_SHIFT_Y, ALIENRULER_SHIFT_Y, WILLBAR_SHIFT_Y, FOCUS_SHIFT_Y, HIDDENBARS_SHIFT_Y, BIND_SHIFT_Y, iMAXSTATWIDTH;
var config int LOOT_OFFSET_X, STAT_OFFSET_X, NAME_OFFSET_X, LOOT_OFFSET_Y, STAT_OFFSET_Y, NAME_OFFSET_Y, NAME_FONT_SIZE, INFO_FONT_SIZE, INFO_ICON_SIZE, ESTI_ICON_SIZE;
