//=================================================================
//  FILE:   UIUnitFlagExtended_StatEntry  by Xymanek && RustyDios
//  
//	File created	13/07/22	17:00
//	LAST UPDATED	28/03/23	18:30
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

	// Xymanek: UIIcon should not be needed, but UIImage causes the icon to be slightly shifted upwards and 
	//	I'm not really interested in digging through the various existing values to figure this out

	// RustyDios: UIIcon IS needed as it splits the forground outline and background colours so they can be easily tinted

	Icon = Spawn(class'UIIcon', self);
	Icon.bDisableSelectionBrackets = true;
	Icon.bAnimateOnInit = false;
	Icon.bIsNavigable = false;
	Icon.InitIcon('Icon', Definition.IconPath, false, true, Height);

	//Needs to load AFTER the colour has been set
	//Icon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath(Definition.IconPath $"_bg"));
	Icon.SetY(Icon.Y + 2);
	
	Text = Spawn(class'UIText', self);
	Text.bAnimateOnInit = false;
	Text.InitText('Text');
	Text.TextSizeRealized = true; // By default there is no text, so we don't know the width
	Text.OnTextSizeRealized = OnTextSizeRealized;
	Text.SetX(Icon.Width);
	Text.Hide();

}

simulated protected function OnTextSizeRealized ()
{
	Width = Text.X + Text.Width;

	if (OnSizeRealized != none) OnSizeRealized();
	Text.Show();
}

simulated function SetIconColour(string IconColour)
{
	//initially Definition IconColour should be "", this should ensure we only set the colours once/if they change
	if (Definition.IconColour != IconColour)
	{
		Definition.IconColour = IconColour;
		Icon.SetBGColor("0x" $ IconColour);
		Icon.LoadIconBG(class'UIUtilities_Image'.static.ValidateImagePath(Definition.IconPath $"_bg"));
	}
}

simulated function SetValue (coerce string strValueUnformatted)
{
	local string strValue;

	strValue = strValueUnformatted;
	strValue = class'UIUtilities_Text'.static.AddFontInfo(strValue, false, false, false, class'WOTCLootIndicator_Extended'.default.INFO_FONT_SIZE);
	strValue = class'UnitFlagExtendedHelpers'.static.ColourText(strValue, Definition.HexColour);

	Text.SetHtmlText(strValue);
	class'UnitFlagExtendedHelpers'.static.AddShadowToTextField(Text);

	Show(); // We have a value
}

simulated function ClearSpecialTrigger()
{
	Definition.SpecialTriggerID = '';
	Definition.Stat = eStat_Invalid;
}

defaultproperties
{
	bAnimateOnInit = false;
	bIsVisible = false; // Gets shown when the value is set
}
