/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/RandomMutRevised
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class RandomMutRevised extends Mutator
    config(RandomMutRevised);

var KFGameType kfgt;
var bool bDoRandomize;

var config array<string> WeaponList;
var config array< class<KFVeterancyTypes> > PerkList;

function PreBeginPlay() {
    local ShopVolume Shop;

    foreach AllActors(class'ShopVolume', Shop) {
        if (Shop != none) {
            continue;
        }
        Shop.bAlwaysClosed = true;
    }
}

function PostBeginPlay() {
    bDoRandomize = true;
    kfgt = KFGameType(Level.Game);
    if (kfgt == none) {
        warn("KFGameType not found. TERMINATING!");
        Destroy();
        return;
    }
    SetTimer(0.25, true);
}

function Timer() {
    local Controller C;

    if (kfgt.bWaveInProgress) {
        bDoRandomize = true;
        return;
    } else if (bDoRandomize && HasAlivePlayers()) {
        if (kfgt.WaveCountDown > 10) {
            return;
        }
        for (C = Level.ControllerList; C != none; C = C.NextController) {
            if (C.IsA('KFPlayerController') && C.Pawn != none) {
                RandomizePlayer(KFPlayerController(C));
            }
        }
        bDoRandomize = false;
    }
}

function RandomizePlayer(KFPlayerController kfpc) {
    class'Util'.static.RandomizePerk(kfpc, PerkList);
    class'Util'.static.RandomizeArmor(kfpc);
    class'Util'.static.DeleteInventory(kfpc, kfgt);
    class'Util'.static.GiveDefaultInventory(kfpc);
    class'Util'.static.RandomizeInventory(kfpc, WeaponList);
    class'Util'.static.RefillAmmo(kfpc);
    // switch to a new weapon
    kfpc.ClientSwitchToBestWeapon();
}

// do we have any alive players?
final private function bool HasAlivePlayers() {
    local Controller c;

    for (c = Level.ControllerList; c != none; c = c.NextController) {
        if (c.IsA('PlayerController') && c.Pawn != none && c.Pawn.Health > 0) {
            return true;
        }
    }
    return false;
}

defaultproperties {
    GroupName="KF-RandomMut"
    FriendlyName="Revised Randomizer"
    Description="Randomizes perk and weapon selection."
}