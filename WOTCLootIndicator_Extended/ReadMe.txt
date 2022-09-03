You created an XCOM 2 Mod Project!

On a roll now..... for over 2 years!!

WOTCLootIndicator_Extended.
A copy of WOTCLootIndicator (Additional Icons) with my personal additions and edits.
These edits include;
	 ALL stat options
	 CHL focus bars (samurai, akimbo, proficiency heroes)
	 Team Coloured Health/shield/will Bars.
Also fixes up;
	positional shifts for all rulers (viperking, zerkerQ, a-king, cx-q, cotk) and for binds of vipers, king, a-king grab and modded enemies
	damage stat respects breakthoughs
	refreshing stats position etc (thanks to Xymanek)

// ================================================================================================================================================================
//	STEAM DESC		https://steamcommunity.com/sharedfiles/filedetails/?id=2285967646
// ================================================================================================================================================================
[h1]What is it?[/h1]
This is a re-upload of a vanilla port. I failed to contact the original authors, but I think my changes are substantial enough to warrant a new mod.
This mod follows in the footsteps of [url=https://steamcommunity.com/sharedfiles/filedetails/?id=646244015] Additional Icons [/url] and [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1127409511] WOTC Additional Icons [/url]

[h1]So what does this do?[/h1]
This mod, like the two it is based upon, expands the 'UI Unit Flag' display to have more information. This includes new icons for display and a loot indicator.
By default it will display Loot, Damage, Aim, Defence, Mobility, Will and Health.

[h1]That sounds just like the other versions ... what's new?[/h1]
Well, first is the inclusion of all stats, Loot, Damage, Aim, Defence, Mobility, Dodge, Hack, Will, Health, Psi Offense, Shields and Armour. You can toggle by config whatever you want.
[list]
[*]I have made a new set of icons for all stats, except loot, which is a re-scale of the original.
[*]Each stat text can now be individually coloured
[*]Mobility can be displayed as the stat or 'in tiles'. Defaults to stat.
[*]Will can be displayed as actual stat or % of max. Defaults to %.
[*]Health can be displayed as current/max or just current.
[*]Loot can be toggled to only display after [i]scanning protocol, battle scanners[/i] or scouting by Reaper [i]target definition[/i]. Defaults to shown, no scanning needed.

[*][b]FIXES:[/b] the damage stat now includes breakthrough damage bonuses
Damage looks at Secondary Weapon Damage if Primary Weapon Damage is 'none'
If still 'none', or no Weapons found, attempts to calculate min-max from Perks ... 
This should help show damage for melee enemies like Faceless and Chryssalids.
[*][b]FIXES:[/b] Status effects on the unit are now displayed.
[*][b]FIXES:[/b] the offset for focus bars, including from mod-added CHL focus bar 
(the CHL bar is the one used by classes like Akimbo, Samurai, Proficiency Heroes)
[*][b]FIXES:[/b] the offset for all alien rulers, including modded rulers
[*][b]FIXES:[/b] the offset for when a soldier is bound or grabbed from a number of sources
[*][b]FIXES:[/b] the offset for environmental objects like Psi Transmitters. 
(these will also only display their health)

[*]The WOTC Will bar can now be toggled on/off and recoloured.
[*]The Health and Shield bars can be hidden for both enemies and friendlies.
[*]The Health and Shield bars can be recoloured to the team colour. 
By default the health bar is coloured and enemy shields.
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=2481645156] Frost Legion [/url] Damage Reduction Shields are now 'frosty' blue.
Rulers have individual colour settings for their Healthbars. Defaults in the screenshots.
[*]The Name can be coloured by team colour. Defaults to 'yellow/gold'.

[*]Includes the HUD Target Icon next to the name.
[*]Config Option to hide the cover shield icon
[*]Config options.. lots of config options... 
[/list]
[h1]Known Issues[/h1][olist]
[*]Basegame has an issue where the UIUnitFlag sometimes fails to initialise and display. 
A save/reload should fix this. Added a console command that might fix this: [b]RustyFix_UFE_RefreshUnitFlagOfActiveUnit[/b] > refreshes the unit flag of the currently active/selected unit
[*][strike]Reload/Mid-Tactical Load, sometimes has an issue where the display scrunches up.
See the screenshots. A blue move/action should fix this.[/strike]
[*]Base game has an issue where the Shield Preview bar locks to flashing until an action is committed to, [strike]I tried to fix this but couldn't, the issue lies in the flash code not resetting the preview correctly.[/strike] I have a fix by [b]MCO[/b] in this mod, however it conflicts with [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1124288875] Gotcha Again [/url] so is disabled by default. [i]See the Update notes for 29th January 2021, v1.7.[/i]
[*][strike]If you recolour the [i]enemy[/i] shield bar/ablative HP and an [i]ally[/i] unit gets mind-controlled the ablative bar gets recoloured to the enemy colour. It does not reset back to friendly colours. (Normal health bar works as expected). While this is undesirable I'm not going to fix it, as I think it's a cool little nod to 'this unit was mind controlled this mission'.[/strike]
[/olist]
[h1]Compatibility[/h1]
Overwrites [b]UIUnitFlag[/b] by MCO and will [b]NOT[/b] work with any other mod that does so, such as;
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1127409511] WOTC Additional Icons [/url]
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1123174832] Show Health Value WOTC [/url]
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1126938196] Numeric Health Display WOTC [/url]
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1630804593] Tactical Information Overhaul [/url]

Works with [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2377251739] YAF1 Autopsy Required [/url], which has settings to control the display of information from this mod.

Works with [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1183444470] Extended Information [/url] and [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1124288875] Gotcha Again [/url].
Not for Vanilla. Works with LWotC and CI.
Can be enabled mid save, mid campaign.

[h1]Credits and Thanks[/h1]
As always many thanks to the good people of the XCOM2 Modders Discord.
Particular thanks to [b]Iridar, Robojumper[/b] and [b]Xymanek[/b] for help with the flash/UI aspects
And thanks to [b]Grimy, SFlo[/b] and [b]Alketi[/b] for the original mods.

~ Enjoy [b]!![/b] and please [url=https://www.buymeacoffee.com/RustyDios] buy me a Cuppa Tea[/url]

// ================================================================================================================================================================
// ================================================================================================================================================================

			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			// allow mods to change the show/hide behavior	
			//	SENT FROM UI Unit Flag Extended
			Tuple = new class'LWTuple';
			Tuple.Id = 'UIUnitFlag_OverrideShowInfo';
			Tuple.Data.Add(2);
			Tuple.Data[0].kind = LWTVObject;	// The targeted unit.
			Tuple.Data[0].o = UnitState;
			Tuple.Data[1].kind = LWTVBool;		// Whether the info should be available.
			Tuple.Data[1].b = true;

			`XEVENTMGR.TriggerEvent('UIUnitFlag_OverrideShowInfo', Tuple);
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			//a HIDE return should set the data false, we flip it here, so that bObfuscate = true
			//thus a query to !bObfuscate will be true later stats obfuscated actually get hidden/never added
			bObfuscate.SetValue(!Tuple.Data[1].b);	

// ================================================================================================================================================================
// ================================================================================================================================================================

			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			// allow mods to change the shown string for a stats config entry
			//	SENT FROM UI Unit Flag Extended
			NSLWTuple = new class'LWTuple';
			NSLWTuple.Id = 'UIUnitFlag_AddDisplayInfo';
			NSLWTuple.Data.Add(1);
			NSLWTuple.Data[0].kind = LWTVString;	// What the info should be
			NSLWTuple.Data[0].s = "";
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[WOTCLootIndicator_Extended.WOTCLootIndicator_Extended]
; stats  unique named PAIR           icon image path without the img:///    text colour         stat to display		hide in YAF1AR   	Special call for other mods to find the string data
+StatsToShow=(BlockName="NSLW_1",    IconPath="UILibrary_NSLW.UINSLW_1",    HexColour="9ACBCB", Stat=,     			bCanObsfucate=1, 	SpecialTriggerID=NSLWTrigger   )

so for OTHER mods to enable new stats they need to include a >> XComWOTCLootIndicator_Extended.ini << with the above header and config entry
the EventTriggerID is called and the above tuple is sent out with 
    `XEVENTMGR.TriggerEvent(SpecialTriggerID, NSLWTuple, UnitState );

Most of the displayed stat entry will come from the config entry, but the text display will come from the tuple result

// ================================================================================================================================================================
// ================================================================================================================================================================
ECharStatType 's I could find

[eStat_HP]				HP/MaxHP
[eStat_Offense]			perception (aim)
[eStat_Mobility]		speed	
[eStat_Will]			focus
[eStat_Dodge]			agility	
[eStat_Defense]			defense
[eStat_Hacking]			Hack
[eStat_PsiOffense]		psi 

[eStat_ShieldHP]		shieldHP
[eStat_ArmorMitigation]	armour pips

//things I think could have a value added ...
[eStat_ArmorPiercing] 		weapon pierce?
[eStat_CritChance]
[eStat_FlankingCritChance]
[eStat_FlankingAimBonus]

[eStat_DetectionRadius]
[eStat_SightRadius]

[eStat_HackDefense]
[eStat_ArmorChance]		NOT pips ??

//things that should not have a value
[eStat_Strength]		used in vs test for knockout from zerkers and stunnies
[eStat_AlertLevel]		enemy behaviour pattern
[eStat_UtilityItems]	# of utility item slots
[eStat_CombatSims]		# of PCS can equip?

//things I have no idea of what they are wrt stats 
[eStat_ReserveActionPoints]
[eStat_FlightFuel]
[eStat_BackpackSize]
[eStat_HighCoverConcealment]

// ================================================================================================================================================================
// ================================================================================================================================================================

UILibrary_UIFlagExtended.UIFlag_Aim
UILibrary_UIFlagExtended.UIFlag_ArmorP
UILibrary_UIFlagExtended.UIFlag_Armour
UILibrary_UIFlagExtended.UIFlag_Armour2
UILibrary_UIFlagExtended.UIFlag_CoverBlue
UILibrary_UIFlagExtended.UIFlag_CoverYellow
UILibrary_UIFlagExtended.UIFlag_Damage
UILibrary_UIFlagExtended.UIFlag_DamCrit
UILibrary_UIFlagExtended.UIFlag_Def
UILibrary_UIFlagExtended.UIFlag_Dodge
UILibrary_UIFlagExtended.UIFlag_Hack
UILibrary_UIFlagExtended.UIFlag_Health
UILibrary_UIFlagExtended.UIFlag_Loot
UILibrary_UIFlagExtended.UIFlag_Mob
UILibrary_UIFlagExtended.UIFlag_Psi
UILibrary_UIFlagExtended.UIFlag_PsiColoured
UILibrary_UIFlagExtended.UIFlag_Shield
UILibrary_UIFlagExtended.UIFlag_Shield2
UILibrary_UIFlagExtended.UIFlag_Will

UILibrary_UIFlagExtended.YA_Aim
UILibrary_UIFlagExtended.YA_Armour
UILibrary_UIFlagExtended.YA_Defense
UILibrary_UIFlagExtended.YA_Dodge
UILibrary_UIFlagExtended.YA_Hack
UILibrary_UIFlagExtended.YA_Health
UILibrary_UIFlagExtended.YA_Mob
UILibrary_UIFlagExtended.YA_Psi
UILibrary_UIFlagExtended.YA_Shield
UILibrary_UIFlagExtended.YA_ShieldS
UILibrary_UIFlagExtended.YA_Will

UILibrary_UIFlagExtended.status_bleeding
UILibrary_UIFlagExtended.status_frozen
UILibrary_UIFlagExtended.status_homingmine
UILibrary_UIFlagExtended.status_immobile
UILibrary_UIFlagExtended.status_poisonChrys

UILibrary_UIFlagExtended.status_chill1
UILibrary_UIFlagExtended.status_chill2
UILibrary_UIFlagExtended.status_chill3
UILibrary_UIFlagExtended.status_cursed
UILibrary_UIFlagExtended.status_ripple

UILibrary_UIFlagExtended.status_shielded

// ================================================================================================================================================================
//		OTHER NOTES IN DEVELOPEMENT -- WELCOME TO MY SCRATCH PAD ;)
// ================================================================================================================================================================
/*
	TACTICAL STAT OVERHAUL HAS THIS ??;
	// Hide standard hp bar
	if(!DisplayStandardHealthBar)
	{
		Movie.SetVariableBool(MCPath $ ".healthMeter._visible", false);
	}

*/

So After getting some programs, ala JPEXS and a Hex Editor.. and doing some tinkering with gfxComponents ,
I managed to find the UIUnitFlag.swf and get it open the following is what ID's I could find from the flash code aspects;

	  this.hitPointsBlockStartY = this.hitPointsBlock._y;
      this.SetFaction(this._isHuman);
      this.defenseModifierMC._visible = false;
      this.missionItemMC._visible = false;
      this.objectiveItemMC._visible = false;
      this.SetCriticallyWounded(false,0);
      this.stunBoltMC._visible = false;
      this.shredIcon._visible = false;
      this.claymoreIcon._visible = false;
      this.overwatchIcon._visible = false;
      this.chosenIcon._visible = false;
      this.statusImage.hideBG();
      this.armorPipAnchor._visible = false;
      this.armorPipArray = [];
      this.healthMeter.theMeter._visible = false;
      this.healthMeter.thePreview._visible = false;
      this.healthMCArray = [];
      this.willMeter._visible = false;
      this.specialAlienIcon._visible = false;
      this.ekgObj._alpha = 75;	

	  var _loc2_ = !isHuman?"_alien":"_human";
	  SetHealthMeterColor(isHuman);

	  hitPointsBlock.flashingPips._visible = false;
      this.hitPointsBlock.flashingPipsShield._visible = false;
      this.hitPointsBlock.shieldBlockFullMain._visible = false;
      this.hitPointsBlock.shieldBlockEmptyMain._visible = false;
      this.hitPointsBlock.shieldBlockFullMain.flag = this;
      this.hitPointsBlock.shieldBlockEmptyMain.flag = this;

	  function SetFactionSpecial()
   	  {
      	var _loc2_ = 0;
      	while(_loc2_ < this.MeterTotal)
      	{
         	Colors.setColor(this.healthMCArray[_loc2_].theMeter,"ACD373");
         	_loc2_ = _loc2_ + 1;
      	}
      	this.specialAlienIcon._visible = true;
      	this._isSpecial = true;
      }

		this.willMeter._visible = true;
		this.willMeter.meterShine._visible = false;
		this.willMeter.meterShadow._visible = false;
		this.willMeter.theMeter._width = numPercentStart / 100 * 264;
		if(this.willMeter.theMeter._width < 264)

	shieldMeter.theMeter
	function SetHealthMeterColor(isHuman)
	{
		if(isHuman)
		{
			var _loc2_ = 0;
			while(_loc2_ < this.MeterTotal)
			{
				Colors.setColor(this.healthMCArray[_loc2_].theMeter,Colors.NORMAL);
				_loc2_ = _loc2_ + 1;
			}
		}
		else
		{
			_loc2_ = 0;
			while(_loc2_ < this.MeterTotal)
			{
				Colors.setColor(this.healthMCArray[_loc2_].theMeter,Colors.BAD);
				_loc2_ = _loc2_ + 1;
			}
		}
	}

function SetHitPointsPreview(damage)
   {
      if(damage != undefined && damage != 0)
      {
         damage = Math.abs(damage);
         this.UpdateHealthMeters(this._cachedCurrHP - damage,this._cachedCurrHPmax,damage);
      }
      else
      {
         this.UpdateHealthMeters(this._cachedCurrHP,this._cachedCurrHPmax,0);
      }
   }

 function SetShieldPointsPreview(potential)
   {
      if(this.shieldMeter == undefined)
      {
         return undefined;
      }
      var _loc2_ = this.shieldMeter.thePreview;
      var _loc3_ = this.shieldMeter.theMeter;
      _loc3_._visible = true;
      if(potential == 0)
      {
         _loc2_._visible = false;
         _loc3_._width = this._cachedCurrShields / this._cachedCurrShieldMax * UnitFlag.METER_MAX_WIDTH;
         _loc2_.gotoAndPlay("_default");
      }
      else
      {
         potential = Math.abs(potential);
         var _loc7_ = this._cachedCurrShields - potential;
         if(_loc7_ < 0)
         {
            _loc2_._width = this._cachedCurrShields / this._cachedCurrShieldMax * UnitFlag.METER_MAX_WIDTH;
            _loc3_._visible = false;
         }
         else
         {
            var _loc6_ = potential / this._cachedCurrShieldMax * UnitFlag.METER_MAX_WIDTH;
            var _loc5_ = (this._cachedCurrShields - potential) / this._cachedCurrShieldMax * UnitFlag.METER_MAX_WIDTH;
            _loc3_._width = _loc5_ != 0?_loc5_:1;
            _loc2_._width = _loc6_ + _loc5_;
         }
         _loc2_._visible = true;
         _loc2_.gotoAndPlay("_animate");
      }
   }
