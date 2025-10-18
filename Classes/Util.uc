/*
 * Author       : Shtoyan
 * Home Repo    : https://github.com/InsultingPros/RandomMutRevised
 * License      : https://www.gnu.org/licenses/gpl-3.0.en.html
*/
class Util extends Object;

var array<string> DefaultInventory;

final static function RefillAmmo(PlayerController pc) {
    local Inventory Inv;
    local KFHumanPawn p;
    local KFAmmunition AmmoToUpdate;
    local KFWeapon WeaponToFill;
    local KFPlayerReplicationInfo KFPRI;
    local class<KFVeterancyTypes> PlayerVeterancy;

    if (pc == none || pc.Pawn == none) {
        return;
    }
    p = KFHumanPawn(pc.Pawn);
    if (p == none) {
        return;
    }

    KFPRI = KFPlayerReplicationInfo(p.PlayerReplicationInfo);
    if (KFPRI != none) {
        PlayerVeterancy = KFPRI.ClientVeteranSkill;
    }

    for (Inv = p.Inventory; Inv != none; Inv = Inv.Inventory) {
        WeaponToFill = KFWeapon(Inv);
        if (WeaponToFill != none) {
            WeaponToFill.MagAmmoRemaining = WeaponToFill.MagCapacity;
        }
        AmmoToUpdate = KFAmmunition(Inv);
        if (AmmoToUpdate != none && AmmoToUpdate.AmmoAmount < AmmoToUpdate.MaxAmmo) {
            if (PlayerVeterancy != none) {
                AmmoToUpdate.MaxAmmo = AmmoToUpdate.default.MaxAmmo;
                AmmoToUpdate.MaxAmmo = float(AmmoToUpdate.MaxAmmo) * PlayerVeterancy.static.AddExtraAmmoFor(KFPRI, AmmoToUpdate.class);
            }

            AmmoToUpdate.AmmoAmount = AmmoToUpdate.MaxAmmo;
        }
    }
}

final static function RandomizePerk(KFPlayerController pc, array< class<KFVeterancyTypes> > PerkList) {
    local class<KFVeterancyTypes> NewPerk;

    if (pc == none)
        return;

    if (PerkList.Length == 0) {
        warn("PerkList is empty!");
        return;
    }
    NewPerk = PerkList[Rand(PerkList.Length)];
    if (NewPerk == none) {
        warn("Selected perk is none!");
        return;
    }

    pc.bChangedVeterancyThisWave = false;
    KFPlayerReplicationInfo(pc.PlayerReplicationInfo).ClientVeteranSkill = NewPerk;
    pc.SelectVeterancy(NewPerk, true);
    // pc.SetSelectedVeterancy(tmpInfo.Perk);
    pc.SelectedVeterancy = NewPerk;
    pc.SendSelectedVeterancyToServer();
    pc.SaveConfig();

    if (KFHumanPawn(pc.pawn) != none) {
        KFHumanPawn(pc.pawn).VeterancyChanged();
    }
}

final static function RandomizeArmor(KFPlayerController pc) {
    if (pc == none || pc.Pawn == none) {
        return;
    }

    pc.pawn.ShieldStrength = 25 + Rand(76);
}

final static function DeleteInventory(KFPlayerController pc, KFGameType kfgt) {
    local KFHumanPawn p;

    if (pc == none || pc.Pawn == none || kfgt == none) {
        return;
    }
    p = KFHumanPawn(pc.Pawn);
    if (p == none) {
        return;
    }

    kfgt.DiscardInventory(p);
}

final static function GiveDefaultInventory(KFPlayerController pc) {
    local int i;
    local KFHumanPawn p;

    if (pc == none || pc.Pawn == none) {
        return;
    }
    p = KFHumanPawn(pc.Pawn);
    if (p == none) {
        return;
    }

    for (i = 0; i < default.DefaultInventory.Length; i++) {
        p.GiveWeapon(default.DefaultInventory[i]);
        p.PlayTeleportEffect(true, true);
    }
}

// Completely random if no weapon set is given.
final static function RandomizeInventory(KFPlayerController kfpc, array<string> WeaponList) {
    local int maxWeight, curWeight, availableWeight;
    local array<string> ProcessedWeaponList;
    local int i, RandomIndex, IterationCount;
    local string SearchString, InfoString;
    local bool bGotWeapon;
    local class<KFWeapon> WClass;
    local KFWeapon W;
    local KFHumanPawn p;

    if (kfpc == none || kfpc.Pawn == none) {
        return;
    }
    p = KFHumanPawn(kfpc.Pawn);
    if (p == none) {
        return;
    }

    maxWeight = p.MaxCarryWeight;
    curWeight = p.CurrentWeight;
    InfoString = p.PlayerReplicationInfo.PlayerName $ "'s Loadout: ";
    ProcessedWeaponList = WeaponList;
    // initial cleanup
    for (i = 0; i < ProcessedWeaponList.Length; i++) {
        if (ProcessedWeaponList[i] == "") {
            ProcessedWeaponList.Remove(i, 1);
            continue;
        }
    }
    if (ProcessedWeaponList.Length == 0) {
        warn("Weapon list is empty!");
        return;
    }

    // do randomization
    while (curWeight < maxWeight && IterationCount < 1000) {
        if (bGotWeapon) {
            InfoString $= W.ItemName $ ", ";
            bGotWeapon = false;
        }

        IterationCount++;
        availableWeight = maxWeight - curWeight;

        for (i = 0; i < ProcessedWeaponList.Length; i++) {
            WClass = class<KFWeapon>(DynamicLoadObject(ProcessedWeaponList[i], class'class', true));
            if (WClass.default.Weight > availableWeight) {
                ProcessedWeaponList.Remove(i, 1);
            }
        }

        if (ProcessedWeaponList.Length == 0) {
            warn("Weapon list is empty!");
            break;
        }

        // Get a random weapon from the processed list.
        RandomIndex = Rand(ProcessedWeaponList.Length);
        WClass = class<KFWeapon>(DynamicLoadObject(ProcessedWeaponList[RandomIndex], class'class', true));

        if (WClass == none) {
            warn("Could not dynamic load weapon class: " $ ProcessedWeaponList[RandomIndex] $ ".");
            continue;
        }

        W = kfpc.Spawn(WClass, p,, p.Location);
        if (W == none) {
            warn("Could not dynamic load weapon class: " $ ProcessedWeaponList[RandomIndex] $ ".");
            continue;
        }

        if (W.Weight > availableWeight) {
            W.Destroy();
            continue;
        }

        if (WClass == class'Dualies') {
            p.DeleteInventory(p.FindInventoryType(class'Single'));
        }

        W.bCanThrow = false;
        W.GiveTo(p);
        curWeight = p.CurrentWeight;

        switch(ProcessedWeaponList[RandomIndex]) {
            case "KFMod.Magnum44Pistol":
                SearchString = "KFMod.Dual44Magnum";
                break;
            case "KFMod.Deagle":
                SearchString = "KFMod.DualDeagle";
                break;
            case "KFMod.MK23Pistol":
                SearchString = "KFMod.DualMK23Pistol";
                break;
            case "KFMod.Dual44Magnum":
                SearchString = "KFMod.Magnum44Pistol";
                break;
            case "KFMod.DualDeagle":
                SearchString = "KFMod.Deagle";
                break;
            case "KFMod.DualMK23Pistol":
                SearchString = "KFMod.MK23Pistol";
                break;
        }

        // Clear current successfully added weapon.
        ProcessedWeaponList.Remove(RandomIndex, 1);

        // Clear any pistol counterparts.
        for (i = 0; i < ProcessedWeaponList.Length; i++) {
            if (ProcessedWeaponList[i] == SearchString) {
                ProcessedWeaponList.Remove(i, 1);
            }
        }
        bGotWeapon = true;
    }

    InfoString $= W.ItemName $ ".";
    kfpc.teammessage(none, InfoString, 'TeamSay');
}

defaultproperties {
    DefaultInventory(0)="KFMod.Knife"
    DefaultInventory(1)="KFMod.Single"
    DefaultInventory(2)="KFMod.Frag"
    DefaultInventory(3)="KFMod.Syringe"
    DefaultInventory(4)="KFMod.Welder"
}