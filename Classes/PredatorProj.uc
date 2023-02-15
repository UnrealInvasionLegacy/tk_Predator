class PredatorProj extends Projectile 
	config(tk_Monsters);

var bool bRing,bHitWater,bWaterStart;
var int NumExtraRockets;
var Effects Corona;
var byte FlockIndex;
var PredatorProj Flock[2];
var() float	FlockRadius;
var() float	FlockStiffness;
var() float FlockMaxForce;
var() float	FlockCurlForce;
var bool bCurl;
var xEmitter SmokeTrail;
var config float fDamage;

replication
{
    reliable if ( bNetInitial && (Role == ROLE_Authority) )
        FlockIndex, bCurl;
}

function PreBeginPlay()
{
	Super.PreBeginPlay();
	Damage = fDamage;
}

simulated function PostBeginPlay()
{
	local vector Dir;

	if ( bDeleteMe || IsInState('Dying') )
		return;

	Dir = vector(Rotation);
	Velocity = speed * Dir;

	if ( Level.NetMode != NM_DedicatedServer)
	{
		SmokeTrail = Spawn(class'PredTrail',self,,Location - 40 * Dir, Rotation);
		SmokeTrail.SetBase(self);
	}

	Super.PostBeginPlay();
}

simulated function Destroyed()
{
	if ( SmokeTrail != None )
		SmokeTrail.mRegen = False;
	if ( Corona != None )
		Corona.Destroy();
	Super.Destroyed();
}
	
simulated function PostNetBeginPlay()
{
	local PredatorProj R;
	local int i;
	local PlayerController PC;

	Super.PostNetBeginPlay();

	if ( FlockIndex != 0 )
	{
	    SetTimer(0.1, true);

	    // look for other rockets
	    if ( Flock[1] == None )
	    {
			ForEach DynamicActors(class'PredatorProj',R)
				if ( R.FlockIndex == FlockIndex )
				{
					Flock[i] = R;
					if ( R.Flock[0] == None )
						R.Flock[0] = self;
					else if ( R.Flock[0] != self )
						R.Flock[1] = self;
					i++;
					if ( i == 2 )
						break;
				}
		}
	}
    if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
	else
	{
		PC = Level.GetLocalPlayerController();
		if ( (Instigator != None) && (PC == Instigator.Controller) )
			return;
		if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
		{
			bDynamicLight = false;
			LightType = LT_None;
		}
	}
}

simulated function Landed( vector HitNormal )
{
	Explode(Location,HitNormal);
}

simulated function ProcessTouch (Actor Other, Vector HitLocation)
{
	if ( (Other != instigator) && (!Other.IsA('Projectile') || Other.bProjTarget) )
		Explode(HitLocation, vector(rotation)*-1 );
}

function BlowUp(vector HitLocation)
{
	HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
	MakeNoise(1.0);
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
    if ( Role == ROLE_Authority )
    {
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    }

   	PlaySound (Sound'tk_Predator.Predator.hit',,3*TransientSoundVolume);/////changed sound here//it stil plays the old sound, because the hit effect extends the playerspawn effect which plays the pick up sound effect. Another reason to make our own emitter, i wil change it now so it doesnt play the pick up effect.
	if ( EffectIsRelevant(Location,false) )
	{
	    Spawn(class'PredatorExplodeEffect',,, Location);/////////////////explosion effect << here it is!
		if ( !Level.bDropDetail && (Level.DetailMode != DM_Low) )
			Spawn(class'PredatorExplodeEffect',,, Location);///////////////////////^^explode effect << and again here!
	}
    SetCollisionSize(0.0, 0.0);
	Destroy();
}

simulated function Timer()
{
    local vector ForceDir, CurlDir;
    local float ForceMag;
    local int i;
    local vector Dir;

	Velocity =  Default.Speed * Normal(Dir * 0.5 * Default.Speed + Velocity);

	// Work out force between flock to add madness
	for(i=0; i<2; i++)
	{
		if(Flock[i] == None)
			continue;

		// Attract if distance between rockets is over 2*FlockRadius, repulse if below.
		ForceDir = Flock[i].Location - Location;
		ForceMag = FlockStiffness * ( (2 * FlockRadius) - VSize(ForceDir) );
		Acceleration = Normal(ForceDir) * Min(ForceMag, FlockMaxForce);

		// Vector 'curl'
		CurlDir = Flock[i].Velocity Cross ForceDir;
		if ( bCurl == Flock[i].bCurl )
			Acceleration += Normal(CurlDir) * FlockCurlForce;
		else
			Acceleration -= Normal(CurlDir) * FlockCurlForce;
	}
}

defaultproperties
{
     fDamage=50.000000
     Speed=1800.000000
     Damage=75.000000
     MomentumTransfer=60000.000000
     MyDamageType=Class'tk_Predator.DamTypePredProj'
     ExplosionDecal=Class'XEffects.RocketMark'
     LightType=LT_Steady
     LightEffect=LE_QuadraticNonIncidence
     LightHue=175
     LightBrightness=255.000000
     LightRadius=5.000000
     DrawType=DT_Sprite
     StaticMesh=StaticMesh'WeaponStaticMesh.LinkProjectile'
     CullDistance=7500.000000
     bDynamicLight=True
     AmbientSound=Sound'WeaponSounds.LinkGun.LinkGunProjectile'
     LifeSpan=10.000000
     Texture=Texture'tk_Predator.Predimage'
     DrawScale=0.300000
     Skins(0)=Texture'tk_Predator.Predimage'
     AmbientGlow=96
     Style=STY_Translucent
     SoundVolume=255
     SoundRadius=100.000000
}
