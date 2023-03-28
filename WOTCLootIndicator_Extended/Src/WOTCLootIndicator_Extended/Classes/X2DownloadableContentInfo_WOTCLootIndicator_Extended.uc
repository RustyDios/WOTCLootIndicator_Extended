//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTCLootIndicator_Extended.uc                                    
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTCLootIndicator_Extended extends X2DownloadableContentInfo;

static event InstallNewCampaign(XComGameState StartState){}
static event OnLoadedSavedGame(){}

//USEFUL SO YOU DONT HAVE TO GO THROUGH THE WHOLE X2ALLOWSELECTALL AND TABTABTAB
//	!! -- REMOVED -- !! CAUSES WIERD SCREEN GLITCH BUGS WITH UNIT FLAGS THAT ARE WORKING FINE
//	<> TODO : Fix This
/*exec function RustyFix_UFE_AllUnitsRefreshFlag()
{
	local UIUnitFlag kUIUnitFlag;
	local XComGameState_Unit CurrentUnitState;

	foreach DynamicActors(class'UIUnitFlag', kUIUnitFlag)
	{
		CurrentUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kUIUnitFlag.StoredObjectID));

		RemoveOldUnitFlag(CurrentUnitState.GetReference(), false);
		AddNewUnitFlag(CurrentUnitState.GetReference(), false);

		class'Helpers'.static.OutputMsg("REFRESH UNIT FLAG:: For Unit [" @CurrentUnitState.GetFullName() @"]");
	}

	class'Helpers'.static.OutputMsg("REFRESH ALL UNIT FLAGS COMPLETE");
}*/

exec function RustyFix_UFE_AllUnitsRefreshFlagHP()
{
	local UIUnitFlag kUIUnitFlag;
	local XComGameState_Unit CurrentUnitState;
 	local XComTacticalController    TacticalController;

	TacticalController = XComTacticalController(`BATTLE.GetALocalPlayerController());
    //XComTacticalCheatManager(TacticalController.CheatManager).UISetAllUnitFlagHitPoints(True, 0,0);

	foreach TacticalController.DynamicActors(class'UIUnitFlag', kUIUnitFlag)
	{
		CurrentUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kUIUnitFlag.StoredObjectID));
		kUIUnitFlag.SetHitPoints(CurrentUnitState.GetCurrentStat(eStat_HP), CurrentUnitState.GetMaxStat(eStat_HP));
		kUIUnitFlag.Show();

		class'Helpers'.static.OutputMsg("REFRESH UNIT FLAG:: For Unit [" @CurrentUnitState.GetFullName() @"]");
	}

}

//USEFUL FOR QUICK RESET OF XCOM UNITS UNDER YOUR CONTROL
//	CAUSES WIERD SCREEN GLITCH BUGS WITH UNIT FLAGS THAT ARE WORKING FINE
//	USED IN CONTROLLED CASES ONLY !!
exec function RustyFix_UFE_RefreshUnitFlagOfActiveUnit()
{
	local XComGameState         NewGameState;
	local XComGameState_Unit    Unit;
	local XGUnit				ActiveUnit;

 	local XComTacticalController    TacticalController;

	TacticalController = XComTacticalController(`BATTLE.GetALocalPlayerController());

	//ActiveUnit = XComTacticalController(GetALocalPlayerController()).GetActiveUnit();
	ActiveUnit = TacticalController.GetActiveUnit();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("DEBUG: Refresh Unit Flag: Remove");

    if(ActiveUnit != none)
	{
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ActiveUnit.ObjectID));

		RemoveOldUnitFlag(Unit.GetReference(), true);
		AddNewUnitFlag(Unit.GetReference(), true);

		class'Helpers'.static.OutputMsg("REFRESH UNIT FLAG:: For Unit [" @Unit.GetFullName() @"]");
		return;
	}
	else
	{
		class'Helpers'.static.OutputMsg("ERROR :: Could not get a unit or object ID :: ABORT ");
		return;
	}

	SubmitNewGameState(NewGameState);

}

simulated function RemoveOldUnitFlag(StateObjectReference kUnitRef, bool bDetailLog)
{
	local UIUnitFlag kFlag;

	if(`PRES.m_kUnitFlagManager != None)
	{
		kFlag = `PRES.m_kUnitFlagManager.GetFlagForObjectID(kUnitRef.ObjectID);

		if ( kFlag != none)
		{
			`PRES.m_kUnitFlagManager.RemoveFlag(kFlag);
			kFlag.Destroy();
			if (bDetailLog) { class'Helpers'.static.OutputMsg("OLD FLAG WAS FOUND AND REMOVED"); }
		}
	}
}

simulated function AddNewUnitFlag(StateObjectReference kUnitRef, bool bDetailLog)
{
	local UIUnitFlag kFlag;
	local XComGameState_BaseObject StartingState;
	local int VisualizedHistoryIndex;

	if(`PRES.m_kUnitFlagManager != None)
	{
		kFlag = `PRES.m_kUnitFlagManager.GetFlagForObjectID(kUnitRef.ObjectID);

		if( kFlag == none )
		{
			`PRES.m_kUnitFlagManager.AddFlag(kUnitRef);	
			if (bDetailLog) { class'Helpers'.static.OutputMsg("NEW FLAG ADDED"); }
			kFlag = `PRES.m_kUnitFlagManager.GetFlagForObjectID(kUnitRef.ObjectID);
		}

		if (kFlag != none)
		{
			VisualizedHistoryIndex = `XCOMVISUALIZATIONMGR.LastStateHistoryVisualized;
			StartingState = `XCOMHISTORY.GetGameStateForObjectID(kUnitRef.ObjectID, , VisualizedHistoryIndex);
			
			kFlag.InitFlag(kUnitRef);
			if (bDetailLog) { class'Helpers'.static.OutputMsg("NEW FLAG INITED"); }
		
			kFlag.UpdateFromState(StartingState, true);	
			if (bDetailLog) { class'Helpers'.static.OutputMsg("NEW FLAG UPDATED"); }

			kFlag.Show();
			if (bDetailLog) { class'Helpers'.static.OutputMsg("NEW FLAG SHOWN"); }
		}
	}
}

//====================================================================================
//	HELPER Funcs - Submit GS copied from Musashi code
//====================================================================================


//helper function to submit new game states        
protected static function SubmitNewGameState(out XComGameState NewGameState)
{
    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        `TACTICALRULES.SubmitGameState(NewGameState);
    }
    else
    {
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
}
