//*******************************************************************************************
//  FILE:   UFE. stuff                                 
//  
//	File created	28/03/23	14:30
//	LAST UPDATED    28/03/23	17:30
//
//	This is used in ACTUAL UFE to show the damage value, it calculates once per unit
//	I've also done it this way and included this as an example for someone else to use
//
//*******************************************************************************************
class X2EventListener_UFEGetDamage extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplate_UFEGetDamage());
	
	return Templates; 
}

static function CHEventListenerTemplate CreateListenerTemplate_UFEGetDamage()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'UFEGetDamage');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;

	//the event name is from the config file, there is no GameState, ELD must be ELD_Immediate!
	Template.AddCHEvent('UFE_GetDamageValue', OnUFEGetDamage, ELD_Immediate);

	return Template;
}

/*
//FOR REF/INFO ONLY called in UIUnitFlagExtended 
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

	//the event name is from the config file
	`XEVENTMGR.TriggerEvent(Entry.Definition.SpecialTriggerID, NSLWTuple, NewUnitState );
}
*/

static function EventListenerReturn OnUFEGetDamage(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local LWTuple				Tuple;
    local XComGameState_Unit    UnitState;
	local UIUnitFlagExtended	UnitFlag;

    Tuple = LWTuple(EventData);
    UnitState = XComGameState_Unit(EventSource);

	//INITIAL ABORT CONDITIONS
	if (Tuple == none || Tuple.Id != 'UIUnitFlag_AddDisplayInfo' || UnitState == none)
	{
		return ELR_NoInterrupt;
	}

	//this cast can also be UIUnitFlag to avoid needing to build against this mod or commented out
	//unless you need something specific from the extended flag, like I need to do so here
	UnitFlag = UIUnitFlagExtended(Tuple.Data[0].o);
	if (UnitFlag == none)
	{
		return ELR_NoInterrupt;
	}

	//SET RETURN TUPLE
	/* Display String 	*/	Tuple.Data[1].s = GetDamageString(UnitFlag, UnitState);
	/* Trigger Once		*/	Tuple.Data[2].b = true;

	return ELR_NoInterrupt;
}

static function string GetDamageString(UIUnitFlagExtended UnitFlag, XComGameState_Unit UnitState, optional bool bForcedToUseSecondary)
{
	local XComGameStateHistory 		History;
	local StateObjectReference 		ObjectRef;
	local X2AbilityTemplateManager 	AbilityManager;
	local X2AbilityTemplate 		AbilityTemplate;
	local XComGameState_Tech		BreakthroughTech;
	local XComGameState_Item 		WeaponState;
	local X2Techtemplate			TechTemplate;
	local X2WeaponTemplate 			WeaponTemplate;
	local X2Effect					TargetEffect;
	local int minDamage, maxDamage;

	History = `XCOMHISTORY;
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
		if (!UnitFlag.m_BreakthroughBonusesFound)
		{
			//get breakthough from HQ
			foreach `XCOMHQ.TacticalTechBreakthroughs(ObjectRef)
			{
				BreakthroughTech = XComGameState_Tech(History.GetGameStateForObjectID(ObjectRef.ObjectID));
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
							UnitFlag.m_BreakthroughBonuses = ( UnitFlag.m_BreakthroughBonuses + X2Effect_BonusWeaponDamage(TargetEffect).BonusDmg);
						}
					}
				}
			}
			
			UnitFlag.m_BreakthroughBonusesFound = true;
		}

		//bump up damage if the unit is friendly and has a bonus amount 
		if (UnitFlag.m_bIsFriendly.GetValue())
		{
			minDamage += UnitFlag.m_BreakthroughBonuses;
			maxDamage += UnitFlag.m_BreakthroughBonuses;
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
				return GetDamageString_FromPerks(UnitState); //"-!-";
			}

			return GetDamageString(UnitFlag, UnitState, true);
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
static function string GetDamageString_FromPerks(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;

	local array<StateObjectReference> arrData;
	local StateObjectReference Data;

	local WeaponDamageValue MinDamagePreview, MaxDamagePreview;
	local int AllowsShield, minDamage, maxDamage, minDamageC, maxDamageC;

	History = `XCOMHISTORY;
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
		return "-!-";
	}

	//damages are the same, use max
	if(maxDamage - minDamage == 0)
	{
		return string(maxDamage);
	}
	
	//damage is a range, x - y
	return minDamage $ "-" $ maxDamage;
}
