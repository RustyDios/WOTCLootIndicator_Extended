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
		//Feeding a null Target gets us Mutli-target attacks -- NOT REQUIRED ? IT WAS ALWAYS REPORTING 0/0 --
		AbilityState.GetDamagePreview(UnitState.GetReference(), MinDamagePreview, MaxDamagePreview, AllowsShield);

		minDamageC = MinDamagePreview.Damage - MinDamagePreview.Spread;
		maxDamageC = MaxDamagePreview.Damage + MaxDamagePreview.Spread;

		if ( MaxDamagePreview.PlusOne > 0) { maxDamageC++; }

		//record the values
		if (minDamage == 0 && minDamageC > 0)  			{ minDamage = minDamageC; } // intitial setting?
		if (minDamageC > 0 && minDamageC < minDamage)	{ minDamage = minDamageC; } // found a lower value that is not 0
		if (maxDamageC > maxDamage) 					{ maxDamage = maxDamageC; } // always increase max if it is higher
	}

	//in case there was a perk with higher minimum damage that the recorded max ??
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