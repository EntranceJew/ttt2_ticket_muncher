if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/icon_ticket_muncher.vtf")
	resource.AddFile("materials/vgui/ttt/icon_ticket_muncher.vmt")
end

SWEP.HoldType               = "normal"

if CLIENT then
	SWEP.PrintName           = "ttt_ticket_muncher_name"
	SWEP.Slot                = 6

	SWEP.ViewModelFOV        = 10
	SWEP.DrawCrosshair       = false

	SWEP.EquipMenuData = {
	type = "item_weapon",
		desc = "ttt_ticket_muncher_desc"
	}

	SWEP.Icon                = "vgui/ttt/icon_ticket_muncher.vmf"
end

SWEP.Base                   = "weapon_tttbase"

SWEP.ViewModel              = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel             = "models/props/cs_office/microwave.mdl"

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Delay          = 1.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = 1.0

-- This is special equipment
SWEP.Kind                   = WEAPON_EQUIP
SWEP.CanBuy                 = {ROLE_DETECTIVE} -- only detectives can buy
SWEP.LimitedStock           = true -- only buyable once
SWEP.WeaponID               = AMMO_HEALTHSTATION

SWEP.AllowDrop              = false
SWEP.NoSights               = true

local flags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}
CreateConVar("ttt_damage_own_ticket_muncher", "0", flags)
CreateConVar("ttt_ticket_muncher_stomach_capacity", "20", flags)
CreateConVar("ttt_ticket_muncher_digest_rate", "0.1", flags)
CreateConVar("ttt_ticket_muncher_digest_frequency", "0.03", flags)
CreateConVar("ttt_ticket_muncher_digest_to_credit_rate", "1", flags)
CreateConVar("ttt_ticket_muncher_progress_to_credits", "60", flags)


function SWEP:OnDrop()
	self:Remove()
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:TicketMuncherDrop()
end
function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self:TicketMuncherDrop()
end

local throwsound = Sound( "Weapon_SLAM.SatchelThrow" )

-- ye olde droppe code
function SWEP:TicketMuncherDrop()
	if SERVER then
		local ply = self:GetOwner()
		if not IsValid(ply) then return end

		if self.Planted then return end

		local vsrc = ply:GetShootPos()
		local vang = ply:GetAimVector()
		local vvel = ply:GetVelocity()

		local vthrow = vvel + vang * 200

		local ticket_muncher = ents.Create("ttt_ticket_muncher")
		if IsValid(ticket_muncher) then
			ticket_muncher:SetPos(vsrc + vang * 10)
			ticket_muncher:Spawn()

			ticket_muncher:SetPlacer(ply)

			ticket_muncher:PhysWake()
			local phys = ticket_muncher:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(vthrow)
			end
			self:Remove()

			self.Planted = true
		end
	end
	self:EmitSound(throwsound)
end


function SWEP:Reload()
	return false
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
		RunConsoleCommand("lastinv")
	end
end

if CLIENT then
	function SWEP:Initialize()
		self:AddTTT2HUDHelp("ttt_ticket_muncher_help")

		return self.BaseClass.Initialize(self)
	end
end

function SWEP:Deploy()
	if SERVER and IsValid(self:GetOwner()) then
		self:GetOwner():DrawViewModel(false)
	end
	return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end

if CLIENT then
	---
	-- @ignore
	function SWEP:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_equipment_additional")

		form:MakeHelp({
			label = "help_ttt_damage_own_ticket_muncher"
		})
		form:MakeCheckBox({
			serverConvar = "ttt_damage_own_ticket_muncher",
			label = "label_ttt_damage_own_ticket_muncher",
		})

		form:MakeHelp({
			label = "help_ttt_ticket_muncher_stomach_capacity"
		})
		form:MakeSlider({
			serverConvar = "ttt_ticket_muncher_stomach_capacity",
			label = "label_ttt_ticket_muncher_stomach_capacity",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeHelp({
			label = "help_ttt_ticket_muncher_digest_rate"
		})
		form:MakeSlider({
			serverConvar = "ttt_ticket_muncher_digest_rate",
			label = "label_ttt_ticket_muncher_digest_rate",
			min = 0,
			max = 5,
			decimal = 2
		})

		form:MakeHelp({
			label = "help_ttt_ticket_muncher_digest_frequency"
		})
		form:MakeSlider({
			serverConvar = "ttt_ticket_muncher_digest_frequency",
			label = "label_ttt_ticket_muncher_digest_frequency",
			min = 0,
			max = 1,
			decimal = 2
		})

		form:MakeHelp({
			label = "help_ttt_ticket_muncher_digest_to_credit_rate"
		})
		form:MakeSlider({
			serverConvar = "ttt_ticket_muncher_digest_to_credit_rate",
			label = "label_ttt_ticket_muncher_digest_to_credit_rate",
			min = 0,
			max = 10,
			decimal = 0
		})

		form:MakeHelp({
			label = "help_ttt_ticket_muncher_progress_to_credits"
		})
		form:MakeSlider({
			serverConvar = "ttt_ticket_muncher_progress_to_credits",
			label = "label_ttt_ticket_muncher_progress_to_credits",
			min = 0,
			max = 100,
			decimal = 0
		})
	end
end