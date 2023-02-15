class DamTypePredProj extends WeaponDamageType
	abstract;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictemHealth )
{
    HitEffects[0] = class'HitSmoke';
}

static function IncrementKills(Controller Killer)
{
	local xPlayerReplicationInfo xPRI;
	
	xPRI = xPlayerReplicationInfo(Killer.PlayerReplicationInfo);
	if ( xPRI != None )
	{
		xPRI.combocount++;
		if ( (xPRI.combocount == 15) && (UnrealPlayer(Killer) != None) )
			UnrealPlayer(Killer).ClientDelayedAnnouncementNamed('ComboWhore',15);
	}
}		

defaultproperties
{
     DeathString="%o couldn't avoid the Predator."
     bAlwaysSevers=True
     bDetonatesGoop=True
     bThrowRagdoll=True
}
