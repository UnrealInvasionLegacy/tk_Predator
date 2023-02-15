class M_PredatorArmed extends tk_Monster 
	config(tk_Monsters);

#EXEC OBJ LOAD FILE="Resources/tk_Predator_rc.u" PACKAGE="tk_Predator"

var name DeathAnims[4];
var sound FootStep[2];
var FireProperties RocketFireProperties;
var class<Ammunition> RocketAmmoClass;
var Ammunition RocketAmmo;
var	class<DamageType>  MyDamageType;
var byte sprayoffset;
var config float fHealth;
var config int DeCloakTime;
var string ObjectName; 
var string ObjectType; 
var Material CloakMat0;
var Material DeCloakMat0;
var Material DeCloakMat1;
var Material DeCloakMat2;
var Material DeCloakMat3;
var Material DeCloakMat4;
var String   CloakingMats[5];
var Material    CloakHitMat;
var float       CloakHitMatTime;

replication
{
reliable if ( bNetDirty && (Role == ROLE_SimulatedProxy) )
        StartCloak, StartDeCloak;
        reliable if (Role == ROLE_Authority)
        CloakMat0, DeCloakMat0, DeCloakMat1, DeCloakMat2, DeCloakMat3, ObjectName, ObjectType, CloakingMats, CloakHitMat;  
}

function PreBeginPlay()
{
	Health = fHealth;
	Super.PreBeginPlay();
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    CloakMat0 = Material(DynamicLoadObject(CloakingMats[4],class'Material'));
    DeCloakMat0 = Material(DynamicLoadObject(CloakingMats[0],class'Material'));
    DeCloakMat1 = Material(DynamicLoadObject(CloakingMats[1],class'Material'));
    DeCloakMat2 = Material(DynamicLoadObject(CloakingMats[2],class'Material'));
    DeCloakMat3 = Material(DynamicLoadObject(CloakingMats[3],class'Material'));
    
        RocketAmmo=spawn(RocketAmmoClass);
        PlaySound(Sound'tk_Predator.Predator.Pred_Spearhead4');
}                                   

function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
    PlayDirectionalHit(HitLocation);

    if( Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds )
        return;

    LastPainSound = Level.TimeSeconds;
  
    StartDeCloak();
}

simulated function Timer()
{
	GotoState('DeCloaking');
}

simulated State DeCloaking
{

simulated function BeginState()
	{

StartDeCloak();

}
    simulated function Timer()
	{
		if ( !PlayerCanSeeMe() )
StartDeCloak();
 		else
 			SetTimer(DeCloakTime, true);
}
}
	
simulated function Tick(float DeltaTime)
{
	super.Tick(DeltaTime);/* need this*/
}

function PlayVictory()
{
	Controller.bPreparingMove = true;
	Acceleration = vect(0,0,0);
	bShotAnim = true;
        PlaySound(Sound'tk_Predator.Predator.Pred_Spearhead4',SLOT_Interact);
	SetAnimAction('Gesture_Taunt02');
	Controller.Destination = Location;
	Controller.GotoState('TacticalMove','WaitForAnim');
}

simulated function StartCloak()
{

//if(Role == Role_Authority)
  //log("The server has done something cloak");
//else if(Role < Role_Authority)
 // log("The client has done something cloak");
  
    PlaySound(Sound'tk_Predator.Predator.cloak');
    
    SetOverlayMaterial(CloakHitMat,CloakHitMatTime,true);       
    
}

simulated function StartDeCloak()
{

//if(Role == Role_Authority)
 // log("The server has done something decloak");
//else if(Role < Role_Authority)
// log("The client has done something decloak");
  
    PlaySound(Sound'tk_Predator.Predator.cloak');
    Skins[0]=DeCloakMat0;   
    Skins[1]=DeCloakMat1;     
    Skins[2]=DeCloakMat2;     
    Skins[3]=DeCloakMat3;     
    
}

simulated function SpawnRocket()
{
	local vector RotX,RotY,RotZ,StartLoc;
	local PredatorProj R;
	

	GetAxes(Rotation, RotX, RotY, RotZ);
	StartLoc=GetFireStart(RotX, RotY, RotZ);
	if ( !RocketFireProperties.bInitialized )
	{
		RocketFireProperties.AmmoClass = RocketAmmo.Class;
		RocketFireProperties.ProjectileClass = RocketAmmo.default.ProjectileClass;
		RocketFireProperties.WarnTargetPct = RocketAmmo.WarnTargetPct;
		RocketFireProperties.MaxRange = RocketAmmo.MaxRange;
		RocketFireProperties.bTossed = RocketAmmo.bTossed;
		RocketFireProperties.bTrySplash = RocketAmmo.bTrySplash;
		RocketFireProperties.bLeadTarget = RocketAmmo.bLeadTarget;
		RocketFireProperties.bInstantHit = RocketAmmo.bInstantHit;
		RocketFireProperties.bInitialized = true;
		
		
	}

	R=PredatorProj(Spawn(RocketAmmo.ProjectileClass,,,StartLoc,Controller.AdjustAim(RocketFireProperties,StartLoc,600)));
	}

function bool SameSpeciesAs(Pawn P)
{
	return ( Monster(P) != none &&
		(P.IsA('SMPTitan') || P.IsA('SMPQueen') || P.IsA('Monster')|| P.IsA('Skaarj') || P.IsA('SkaarjPupae') || P.IsA('LuciferBOSS')));
}

function SpinDamageTarget()
{
	if (MeleeDamageTarget(20, (30000 * Normal(Controller.Target.Location - Location))) )
		PlaySound(Sound'tk_Predator.Predator.Attack_1', SLOT_Interact);
}

simulated function RangedAttack(Actor A)
{
	local float decision;
	if ( bShotAnim )
		return;
	bShotAnim=true;
	decision = FRand();

	if ( Physics == PHYS_Swimming )
		SetAnimAction('Swim_Tread');
	else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
	{
		if(GetAnimSequence()=='DodgeL')
			decision += 0.2;

		if ( decision < 0.5 )
		{
			SetAnimAction('DodgeR');
		}
		else
		{
			SetAnimAction('DodgeF');
		}
		PlaySound(Sound'tk_Predator.Predator.Pred_HeadGib');
		SpinDamageTarget();
		Controller.GotoState('TacticalMove','WaitForAnim');
		Acceleration = vect(0,0,0);
	}
	else if ( Velocity == vect(0,0,0) )


{
		if (decision < 0.35) 

		 {
		 
			//if (Role == ROLE_Authority)
				   // {
				   // log("Cloaked");
			
                        StartCloak();
			SetTimer(DeCloakTime, true);
			SetAnimAction('Weapon_Switch');
                        SpawnRocket();
                        //log("SpawnRocket (1)");
		}
		else 
		{
			sprayoffset = 0;
			PlaySound(Sound'tk_Predator.Predator.Spot_1');

			//if (Role == ROLE_Authority)
				//    {
				  //  log("Cloaked");
			StartCloak();
			}
			SetTimer(DeCloakTime, true);
			SetAnimAction('Weapon_Switch');
                        SpawnRocket();
                        //log("SpawnRocket (2)");
			Controller.GotoState('TacticalMove','WaitForAnim');
		        Acceleration = vect(0,0,0);	
	}
	else
	{
		if (decision < 0.35)
		{

			SetAnimAction('WalkF');

			SpawnRocket();
			//log("walkf (3)");
		}
		else
		{
			sprayoffset = 0;
			PlaySound(Sound'tk_Predator.Predator.Spot_1');
			SetAnimAction('RunF');
			SpawnRocket();
			//log("runf (4)");
			Controller.GotoState('TacticalMove','WaitForAnim');

		}
	}
}

function vector GetFireStart(vector X, vector Y, vector Z)
{
    return Location + 0.9 * CollisionRadius * X + 0.5 * CollisionRadius * Y + 0.9 * CollisionHeight * Z;
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
    bCanTeleport = false;
    bReplicateMovement = false;
    bTearOff = true;
    bPlayedDeath = true;

	LifeSpan = RagdollLifeSpan;
    GotoState('Dying');

	Velocity += TearOffMomentum;
    BaseEyeHeight = Default.BaseEyeHeight;
    SetInvisibility(0.0);
    PlayDirectionalDeath(HitLoc);
    SetPhysics(PHYS_Falling);
    PlaySound(DeathSound[Rand(2)], SLOT_Pain,1000*TransientSoundVolume, true,800);

}

defaultproperties
{
     DeathAnims(0)="DeathF"
     DeathAnims(1)="DeathB"
     DeathAnims(2)="DeathL"
     DeathAnims(3)="DeathR"
     RocketAmmoClass=Class'tk_Predator.PredatorAmmo'
     fHealth=100.000000
     DeCloakTime=3
     CloakMat0=FinalBlend'tk_Predator.Predator.shadeFB'
     DeCloakMat0=Texture'tk_Predator.Predator.Legs'
     DeCloakMat1=Texture'tk_Predator.Predator.Torso'
     DeCloakMat2=Texture'tk_Predator.Predator.head'
     DeCloakMat3=Texture'tk_Predator.Predator.Mask'
     CloakingMats(0)="tk_Predator.Predator.Legs"
     CloakingMats(1)="tk_Predator.Predator.Torso"
     CloakingMats(2)="tk_Predator.Predator.head"
     CloakingMats(3)="tk_Predator.Predator.Mask"
     CloakingMats(4)="tk_Predator.Predator.shadeFB"
     CloakHitMat=FinalBlend'tk_Predator.Predator.shadeFB'
     CloakHitMatTime=10.000000
     DeathSound(0)=Sound'tk_Predator.Predator.attack_1'
     DeathSound(1)=Sound'tk_Predator.Predator.pred_bodygib'
     AmmunitionClass=Class'tk_Predator.PredatorAmmo'
     ScoringValue=10
     GibGroupClass=Class'XEffects.xAlienGibGroup'
     TurnLeftAnim="TurnL"
     TurnRightAnim="TurnR"
     AirAnims(0)="Jump_Mid"
     AirAnims(1)="Jump_Mid"
     AirAnims(2)="Jump_Mid"
     AirAnims(3)="Jump_Mid"
     TakeoffAnims(0)="Jump_Takeoff"
     TakeoffAnims(1)="Jump_Takeoff"
     TakeoffAnims(2)="Jump_Takeoff"
     TakeoffAnims(3)="Jump_Takeoff"
     LandAnims(0)="Jump_Land"
     LandAnims(1)="Jump_Land"
     LandAnims(2)="Jump_Land"
     LandAnims(3)="Jump_Land"
     DoubleJumpAnims(0)="DoubleJumpF"
     DoubleJumpAnims(1)="DoubleJumpF"
     DoubleJumpAnims(2)="DoubleJumpF"
     DoubleJumpAnims(3)="DoubleJumpF"
     DodgeAnims(0)="DodgeL"
     DodgeAnims(1)="DodgeR"
     DodgeAnims(2)="DodgeR"
     DodgeAnims(3)="DodgeL"
     AirStillAnim="Jump_Takeoff"
     TakeoffStillAnim="Jump_Takeoff"
     CrouchTurnRightAnim="Crouch_TurnR"
     CrouchTurnLeftAnim="Crouch_TurnL"
     AmbientSound=Sound'tk_Predator.Predator.idle_0'
     OverlayMaterial=FinalBlend'tk_Predator.Predator.shadeFB'
     Mesh=SkeletalMesh'tk_Predator.Predator.HeavyPred'
     DrawScale=1.400000
     Skins(0)=Texture'tk_Predator.Predator.Legs'
     Skins(1)=Texture'tk_Predator.Predator.Torso'
     Skins(2)=Texture'tk_Predator.Predator.head'
     Skins(3)=Texture'tk_Predator.Predator.Mask'
     CollisionHeight=60.000000
     Mass=150.000000
     Buoyancy=150.000000
}
