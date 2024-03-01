---
-- @class SWEP
-- @desc ticket muncher
-- @section weapon_ttt_ticket_muncher

if SERVER then
    AddCSLuaFile()
end

DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "ttt_ticket_muncher_name"
    SWEP.Slot = 6

    SWEP.ShowDefaultViewModel = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "ttt_ticket_muncher_desc",
    }

    SWEP.Icon = "vgui/ttt/icon_ticket_muncher"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props/cs_office/microwave.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 1.0

-- This is special equipment
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_DETECTIVE } -- only detectives can buy
SWEP.LimitedStock = true -- only buyable once
SWEP.WeaponID = AMMO_HEALTHSTATION

SWEP.builtin = true

SWEP.AllowDrop = false
SWEP.NoSights = true

SWEP.drawColor = Color(255, 178, 0, 255)

local flags = { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }
CreateConVar("ttt_damage_own_ticket_muncher", "0", flags)
CreateConVar("ttt_ticket_muncher_stomach_capacity", "20", flags)
CreateConVar("ttt_ticket_muncher_digest_rate", "0.1", flags)
CreateConVar("ttt_ticket_muncher_digest_frequency", "0.03", flags)
CreateConVar("ttt_ticket_muncher_digest_to_credit_rate", "1", flags)
CreateConVar("ttt_ticket_muncher_progress_to_credits", "60", flags)

---
-- @ignore
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if SERVER then
        local muncher = ents.Create("ttt_ticket_muncher")

        if muncher:ThrowEntity(self:GetOwner(), Angle(90, -90, 0)) then
            self:Remove()
        end
    end
end

---
-- @ignore
function SWEP:Reload()
    return false
end

---
-- @realm shared
function SWEP:Initialize()
    if CLIENT then
        self:AddTTT2HUDHelp("ttt_ticket_muncher_help")
    end

    self:SetColor(self.drawColor)

    return BaseClass.Initialize(self)
end

if CLIENT then
    ---
    -- @realm client
    function SWEP:DrawWorldModel()
        if IsValid(self:GetOwner()) then
            return
        end

        self:DrawModel()
    end

    ---
    -- @realm client
    function SWEP:DrawWorldModelTranslucent() end

    ---
    -- @ignore
    function SWEP:AddToSettingsMenu(parent)
        local form = vgui.CreateTTT2Form(parent, "header_equipment_additional")

        form:MakeHelp({
            label = "help_ttt_damage_own_ticket_muncher",
        })
        form:MakeCheckBox({
            serverConvar = "ttt_damage_own_ticket_muncher",
            label = "label_ttt_damage_own_ticket_muncher",
        })

        form:MakeHelp({
            label = "help_ttt_ticket_muncher_stomach_capacity",
        })
        form:MakeSlider({
            serverConvar = "ttt_ticket_muncher_stomach_capacity",
            label = "label_ttt_ticket_muncher_stomach_capacity",
            min = 0,
            max = 100,
            decimal = 0,
        })

        form:MakeHelp({
            label = "help_ttt_ticket_muncher_digest_rate",
        })
        form:MakeSlider({
            serverConvar = "ttt_ticket_muncher_digest_rate",
            label = "label_ttt_ticket_muncher_digest_rate",
            min = 0,
            max = 5,
            decimal = 2,
        })

        form:MakeHelp({
            label = "help_ttt_ticket_muncher_digest_frequency",
        })
        form:MakeSlider({
            serverConvar = "ttt_ticket_muncher_digest_frequency",
            label = "label_ttt_ticket_muncher_digest_frequency",
            min = 0,
            max = 1,
            decimal = 2,
        })

        form:MakeHelp({
            label = "help_ttt_ticket_muncher_digest_to_credit_rate",
        })
        form:MakeSlider({
            serverConvar = "ttt_ticket_muncher_digest_to_credit_rate",
            label = "label_ttt_ticket_muncher_digest_to_credit_rate",
            min = 0,
            max = 10,
            decimal = 0,
        })

        form:MakeHelp({
            label = "help_ttt_ticket_muncher_progress_to_credits",
        })
        form:MakeSlider({
            serverConvar = "ttt_ticket_muncher_progress_to_credits",
            label = "label_ttt_ticket_muncher_progress_to_credits",
            min = 0,
            max = 100,
            decimal = 0,
        })
    end
end
