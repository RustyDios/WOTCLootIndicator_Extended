//=============================================================
//  FILE:   WOTCLootIndicator_Extended                                    
//  
//	File created by RustyDios	29/01/21	05:00
//	LAST UPDATED				29/01/21	06:00
//
//	THIS MCO FIXES THE HORRIBLE ISSUE OF STUCK FLASHING PIPS ON THE SHIELD PREVIEW
//	UNFORTUNATELY IT CONFLICTS WITH GOTCHA AGAIN
//	SO I DISABLED THIS BY DEFAULT, AWAITING CHL HELP
//	THE ISSUE WAS LINE 29 FOR SHIELDS WAS ALSO COMMENTED OUT
//	LINE 696 OF THE ORIGINAL FILE
//
//=============================================================
class UIUFE_Manager extends UIUnitFlagManager;

simulated function ClearAbilityDamagePreview()
{
	local UIUnitFlag kFlag;

	// Turn all flag info off initially 
	foreach m_arrFlags(kFlag)
	{
		if( !kFlag.m_bIsFriendly.GetValue() )
		{
			kFlag.SetHitPointsPreview(0);
			kFlag.SetArmorPointsPreview(0, 0);
		}
		//			if(kFlag.m_kUnit.GetCharacter().m_ePawnType == ePawnType_Mechtoid)
		kFlag.SetShieldPointsPreview(0);
	}
}
