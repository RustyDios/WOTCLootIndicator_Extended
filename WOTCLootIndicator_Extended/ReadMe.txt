You created an XCOM 2 Mod Project!

On a roll now..... for over a year

WOTCLootIndicator_Extended.
A copy of WOTCLootIndicator (Additional Icons) with my personal additions and edits.
These edits include;
	 ALL stat options
	 CHL focus bars (samurai, akimbo, proficiency heroes)
	 Team Coloured Health/shield/will Bars.
Also fixes up;
	positional shifts for all rulers (viperking, zerkerQ, a-king, cx-q, cotk) and for binds of vipers, king, a-king grab and modded enemies
	damage stat respects breakthoughs

https://steamcommunity.com/sharedfiles/filedetails/?id=646244015 VANILLA ADDITIONAL ICONS
https://steamcommunity.com/sharedfiles/filedetails/?id=1127409511 WOTC ADDITIONAL ICONS

https://steamcommunity.com/sharedfiles/filedetails/?id=621376448 NUMERIC HEALTH DISPLAY 
https://steamcommunity.com/sharedfiles/filedetails/?id=1126938196 NUMERIC HEALTH DISPLAY WOTC
https://steamcommunity.com/sharedfiles/filedetails/?id=1630804593 TACTICAL INFORMATION OVERHAUL

https://steamcommunity.com/sharedfiles/filedetails/?id=617015579 SHOW HEALTH VALUE - VANILLA
https://steamcommunity.com/sharedfiles/filedetails/?id=1123174832 SHOW HEALTH VALUE - WOTC

Texture2D'UILibrary_UIFlagExtended.UIFlag_Aim'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Armor'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Damage'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Def'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Dodge'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Hack'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Health'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Loot'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Mob'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Psi'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Shield'
Texture2D'UILibrary_UIFlagExtended.UIFlag_Will'
===========================================================================================

things to do:
   better way to auto space the stats based on number of text characters and icon size
   double up the stats bar if more than 4? stats are selected
   fix the shield preview flashing locks

// ================================================================================================================================================================
//	STEAM DESC		https://steamcommunity.com/sharedfiles/filedetails/?id=2285967646
// ================================================================================================================================================================
[h1]What is it?[/h1]
This is a re-upload of a vanilla port. I failed to contact the original authors, but I think my changes are substantial enough to warrant a new mod.
This mod follows in the footsteps of [url=https://steamcommunity.com/sharedfiles/filedetails/?id=646244015] Additional Icons [/url] and [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1127409511] WOTC Additional Icons [/url]

[h1]So what does this do?[/h1]
This mod like the two it is based upon expands the 'UI Unit Flag' display to have more information. This includes new icons for stat displays and a loot indicator.
You can toggle these stats to display in the config.
By default it will display Loot, Damage, Aim, Defense, Mobility and Health.

[h1]That sounds just like the other versions ... what's new?[/h1]
Well, first is the inclusion of all stats, Loot, Damage, Aim, Defense, Mobility, Hack, Will, Psi, Health, Shields and Armour. You can toggle by config whatever you want.
[list]
[*]I have made a new set of icons for all stats, except loot, which is a rescale of the original.
[*]Each stat text can now be individually coloured
[*]Health can be displayed as current/max or just current.
[*]Mobility can be displayed as the stat or 'in tiles'. Defaults to stat.
[*]Loot can be toggled to only display after [i]scanning protocol, battle scanners[/i] or scouting by Reaper [i]target definition[/i].

[*][b]FIXES:[/b] the damage stat now includes breakthrough damage bonuses
[*][b]FIXES:[/b] the offset for focus bars, including from mod-added CHL focus bar 
(the CHL bar is the one used by classes like Akimbo, Samurai, Proficiency Heroes)
[*][b]FIXES:[/b] the offset for all alien rulers, including CX Hive Queen and Children of The King
[*][b]FIXES:[/b] the offset for when a soldier is bound or grabbed from a number of sources
[*][b]FIXES:[/b] the offset for environmental objects like Psi Transmitters. 
(these will also only display their health)

[*]The WOTC Will bar can now be toggled on/off and recoloured.
[*]The bars can be hidden for both enemies and friendlies.
[*]The Health and Shield bars can be recoloured to the team colour. 
By default the health bar is coloured and enemy shields.
[*]The Name can be coloured by team colour. Defaults to 'yellow/gold'.

[*]Includes the HUD Target Icon next to the name.
[/list]
[h1]Known Issues[/h1][olist]
[*]Basegame has an issue where the UIUnitFlag sometimes fails to initialise and display. A save/reload should fix this.
[*]Base game has an issue where the Shield Preview bar locks to flashing until a move is committed to, I tried to fix this but couldn't, the issue lies in the flash code not resetting the preview correctly.
[*]If you recolour the [i]enemy[/i] shield bar/ablative HP and an [i]ally[/i] unit gets mind-controlled the ablative bar gets recoloured to the enemy colour. It does not reset back to friendly colours. (Normal health bar works as expected). While this is undesirable I'm not going to fix it, as I think it's a cool little nod to 'this unit was mind controlled this mission'.
[/olist]
[h1]Compatibility[/h1]
Overwrites [b]UIUnitFlag[/b] by MCO and will [b]NOT[/b] work with any other mod that does so, such as;
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1127409511] WOTC Additional Icons [/url]
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1123174832] Show Health Value WOTC [/url]
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1126938196] Numeric Health Display WOTC [/url]
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1630804593] Tactical Information Overhaul [/url]

Works with [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1183444470] Extended Information [/url] and [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1124288875] Gotcha Again [/url].
Not for Vanilla. No Idea about LWotC or CI but should have no issues.
Can be enabled mid save, mid campaign.

Works with [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2377251739] YAF1 Autopsy Required [/url]. That mod has config settings to control the display of information from this mod.

[h1]Credits and Thanks[/h1]
As always many thanks to the good people of the XCOM2 Modders Discord.
Particular thanks to [b]Iridar, Robojumper[/b] and [b]Xymanek[/b] for help with the flash aspects
And thanks to [b]Grimy, SFlo[/b] and [b]Alketi[/b] for the original mods.

~ Enjoy [b]!![/b] and please [url=https://www.buymeacoffee.com/RustyDios] buy me a Cuppa Tea[/url]
// ================================================================================================================================================================
// ================================================================================================================================================================
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			// allow mods to change the show/hide behavior	
			//	SENT FROM WOTCLootIndicator_Extended.UC
			//			UI Unit Flag Extended
			Tuple = new class'LWTuple';
			Tuple.Id = 'UIUnitFlag_OverrideShowInfo';
			Tuple.Data.Add(2);

				// The targeted unit.
			Tuple.Data[0].kind = LWTVObject;
			Tuple.Data[0].o = UnitState;
				// Whether the info should be available.
			Tuple.Data[1].kind = LWTVBool;
			Tuple.Data[1].b = true;

			`XEVENTMGR.TriggerEvent('UIUnitFlag_OverrideShowInfo', Tuple);
			//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			//a HIDE return should set the data false, we flip it here, so that m_bObfuscate = true
			//thus a query to !m_bObfuscate will be true later
			//stats obfuscated actually get hidden/never added
			//obfuscated stats are the same ones hidden in YAF1 -- damage, aim, mobility, dodge, hack, will, psi ... leaving HP, defence, Shields and Armor
			m_bObfuscate.SetValue(!Tuple.Data[1].b);	
// ================================================================================================================================================================
// ================================================================================================================================================================

/*
	So After getting some risky programs, ala JPEXS and a Hex Editor.. and doing some tinkering with gfxComponents , I managed to find the UIUnitFlag.swf and break it open
	the following is what ID's I could find;
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
*/

/*
	TACTICAL STAT OVERHAUL HAS THIS ??;
	// Hide standard hp bar
	if(!DisplayStandardHealthBar)
	{
		Movie.SetVariableBool(MCPath $ ".healthMeter._visible", false);
	}

*/

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
 