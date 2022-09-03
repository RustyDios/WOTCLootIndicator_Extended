//=================================================================
//  FILE:   UIUnitFlagExtended_StatEntry  by Xymanek && RustyDios
//  
//	File created	13/07/22	17:00
//	LAST UPDATED	13/07/22	19:30
//
//=================================================================

class UIUnitFlagExtended_StatEntry extends UIPanel dependson(UnitFlagExtendedHelpers);

var protectedwrite StatRowEntryDefinition Definition;

var protectedwrite UIIcon Icon;
var protectedwrite UIText Text;

delegate OnSizeRealized();

simulated function InitStatEntry (StatRowEntryDefinition InDefinition)
{
	Definition = InDefinition;
	Height = class'WOTCLootIndicator_Extended'.default.INFO_ICON_SIZE;

	InitPanel(Definition.BlockName);

	// UIIcon should not be needed, but UIImage causes the icon to be slightly shifted upwards
	// and I'm not really interested in digging through the various existing values to figure this out
	//Icon = Spawn(class'UIImage', self);
	//Icon.bAnimateOnInit = false;
	//Icon.InitImage('Icon', Definition.IconPath);
	//Icon.SetSize(Height, Height);

	Icon = Spawn(class'UIIcon', self);
	Icon.bDisableSelectionBrackets = true;
	Icon.bAnimateOnInit = false;
	Icon.InitIcon('Icon', Definition.IconPath, false, false, Height);

	Text = Spawn(class'UIText', self);
	Text.bAnimateOnInit = false;
	Text.InitText('Text');
	Text.TextSizeRealized = true; // By default there is no text, so we know the width
	Text.OnTextSizeRealized = OnTextSizeRealized;
	Text.SetX(Icon.Width + 2);
}

simulated protected function OnTextSizeRealized ()
{
	Width = Text.X + Text.Width;

	if (OnSizeRealized != none) OnSizeRealized();
}

simulated function SetValue (coerce string strValueUnformatted)
{
	local string strValue;

	strValue = strValueUnformatted;
	strValue = class'UnitFlagExtendedHelpers'.static.ColourText(strValue, Definition.HexColour);
	strValue = class'UIUtilities_Text'.static.AddFontInfo(strValue, false, false, false, class'WOTCLootIndicator_Extended'.default.INFO_FONT_SIZE);

	Text.SetHtmlText(strValue);

	class'UnitFlagExtendedHelpers'.static.AddShadowToTextField(Text);

	Show(); // We have a value
}

defaultproperties
{
	bAnimateOnInit = false;
	bIsVisible = false; // Gets shown when the value is set
}
