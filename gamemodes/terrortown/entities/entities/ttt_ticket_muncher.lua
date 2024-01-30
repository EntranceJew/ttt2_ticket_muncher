---
-- @class ENT
-- @desc Ticket muncher
-- @section ttt_ticket_muncher

if SERVER then
	AddCSLuaFile()
	resource.AddFile("sound/entities/entities/ttt2_ticket_muncher/ticket_muncher_burp.wav")
	resource.AddFile("sound/entities/entities/ttt2_ticket_muncher/ticket_muncher_feed.wav")
else -- CLIENT
	-- this entity can be DNA-sampled so we need some display info
	ENT.Icon = "vgui/ttt/icon_ticket_muncher"
	ENT.PrintName = "ttt_ticket_muncher_name"
end

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/microwave.mdl")

--ENT.CanUseKey = true
ENT.CanHavePrints = true

ENT.DamageFromOwner = false
ENT.StomachCapacity = 20
ENT.DigestRate = 1 / 10
ENT.DigestFreq = 1 / 33 -- in seconds
ENT.DigestToCreditRate = 1
ENT.ProgressToCredits = 60 -- progress is a ratio of an ammo box's ammo over its max ammo

ENT.NextCredit = 0
ENT.CreditRate = 1
ENT.CreditFreq = 0.2
ENT.WasChewing = false

local soundChewing = Sound("entities/entities/ttt2_ticket_muncher/ticket_muncher_feed.wav")
local soundCrediting = Sound("entities/entities/ttt2_ticket_muncher/ticket_muncher_burp.wav")
local soundFail = Sound("items/medshotno1.wav")
local timeLastSound = 0
local loopSoundIndexChewing = 0

local materialCredits = Material("vgui/ttt/tid/tid_credits")

---
-- @realm shared
function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "EatenAmmo")
	self:NetworkVar("Float", 1, "DigestedAmmo")
	self:NetworkVar("Int", 0, "StoredCredits")
	self:NetworkVar("Entity", 0, "Placer")
end

---
-- @realm shared
function ENT:Initialize()
	self:SetModel(self.Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)

	local b = 32

	self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	if SERVER then
		self:SetMaxHealth(200)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(43)
		end

		self:SetUseType(CONTINUOUS_USE)

		self:SetEatenAmmo(0)
		self:SetDigestedAmmo(0)
		self:SetStoredCredits(0)
	end

	self:SetHealth(200)
	self:SetColor(Color(255, 178, 0))

	self.NextCredit = 0
	self.fingerprints = {}

	self.DamageFromOwner = GetConVar("ttt_damage_own_ticket_muncher"):GetBool()
	self.StomachCapacity = GetConVar("ttt_ticket_muncher_stomach_capacity"):GetInt()
	self.DigestRate = GetConVar("ttt_ticket_muncher_digest_rate"):GetFloat()
	self.DigestFreq = GetConVar("ttt_ticket_muncher_digest_frequency"):GetFloat() -- in seconds
	self.DigestToCreditRate = GetConVar("ttt_ticket_muncher_digest_to_credit_rate"):GetFloat()
	self.ProgressToCredits = GetConVar("ttt_ticket_muncher_progress_to_credits"):GetInt()
	 -- progress is a ratio of an ammo box's ammo over its max ammo
end

---
-- @realm shared
function ENT:GetStomachFullness()
	return self:GetEatenAmmo() / self.StomachCapacity
end
function ENT:GetDigestedProgress()
	return self:GetDigestedAmmo() / self.ProgressToCredits
end

-- function ENT:GetProgress()
-- 	return (self:GetStoredAmmo() - (self:GetCredits() * self.ProgressToCredits)) / self.ProgressToCredits
-- end

function ENT:IsChewing()
	return self:GetEatenAmmo() > 0
end

function ENT:HandleChewNoise()
	local now = self:IsChewing()
	local was = self.WasChewing

	if now and not was then
		loopSoundIndexChewing = self:StartLoopingSound(soundChewing)
	end
	if was and not now then
		self:StopLoopingSound(loopSoundIndexChewing)
	end
	was = now
end

if SERVER then
	---
	-- @param Entity entity
	-- @realm shared
	function ENT:Touch( entity )
		if entity.Base == "base_ammo_ttt" then
			-- local available_feed = entity.AmmoAmount / entity.AmmoMax
			-- local available_feed = entity.AmmoAmount

			local capacity = self.StomachCapacity - self:GetEatenAmmo()
			-- if entity.AmmoAmount < capacity +  then return end
			local given = math.min(capacity, math.ceil(entity.AmmoAmount * 0.25))
			local consumed, excess = self:Eat(given)
			entity.AmmoAmount = entity.AmmoAmount - consumed
			if entity.AmmoAmount > 0 and math.ceil(entity.AmmoEntMax * 0.25) <= entity.AmmoAmount then return end

			entity:Remove()
		end
	end

	function ENT:Eat(amount)
		local target = self:GetEatenAmmo() + amount
		local consumed = 0
		local excess = 0
		--math.min(self.StomachCapacity, target)
		if target > self.StomachCapacity then
			excess = target - self.StomachCapacity
		end
		consumed = amount - excess
		self:SetEatenAmmo(self:GetEatenAmmo() + consumed)
		-- print("eat:",amount,"target",target,"consumed",consumed,"excess",excess,"now",self:GetEatenAmmo())
		return consumed, excess
	end

	function ENT:Digest(digestRate)
		self:HandleChewNoise()

		local target = self:GetEatenAmmo() - digestRate
		local consumed = 0
		local excess = 0
		--math.min(self.StomachCapacity, target)
		if target < 0 then
			excess = 0 - target
		end
		consumed = digestRate - excess
		self:SetEatenAmmo(self:GetEatenAmmo() - consumed)
		self:SetDigestedAmmo(self:GetDigestedAmmo() + consumed)

		-- local consumed = 0
		-- local target = self:GetEatenAmmo() - digestRate
		-- if target > 0 then
		-- 	print("yippie")
		-- 	print("prelim",self:GetDigestedAmmo(),"zimb",self:GetEatenAmmo())
		-- 	self:SetEatenAmmo(self:GetEatenAmmo() - digestRate)
		-- 	self:SetDigestedAmmo(self:GetDigestedAmmo() + digestRate)
		-- 	print("postlim",self:GetDigestedAmmo(),"zimb",self:GetEatenAmmo())
		-- 	consumed = digestRate
		-- end

		-- print("prelim",self:GetDigestedAmmo(),"zimb",self:GetEatenAmmo())
		--

		-- print("digest:",digestRate,"consumed",consumed,"target",target,"excess",excess,"digest",self:GetDigestedAmmo(),"eaten",self:GetEatenAmmo())

		local credited = 0
		if self:GetDigestedAmmo() >= self.ProgressToCredits then
			credited = math.min(self.DigestToCreditRate, (self:GetDigestedAmmo() - (self:GetDigestedAmmo() % self.ProgressToCredits)) / self.ProgressToCredits)
			-- print("credited:", credited, self:GetDigestedAmmo() % self.ProgressToCredits, self:GetStoredCredits() )
			self:SetDigestedAmmo(math.max(0, self:GetDigestedAmmo() - (credited * self.ProgressToCredits)))

			self:SetStoredCredits(math.min(math.huge, self:GetStoredCredits() + credited))
		end
		return consumed, credited
	end
end
---
-- @param number amount
-- @realm shared
function ENT:AddStoredCredits(amount)
	self:SetStoredCredits(math.min(math.huge, self:GetStoredCredits() + amount))
end

---
-- @param number amount
-- @return number
-- @realm shared
function ENT:TakeStoredCredits(amount)
	amount = math.min(amount, self:GetStoredCredits())

	self:SetStoredCredits(math.max(0, self:GetStoredCredits() - amount))

	return amount
end

---
-- This hook that is called on the use of this entity, but only if the player
-- can receive credits.
-- @param Player ply The player that is
-- @param Entity ent The ticket muncher entity that is used
-- @param number credited The amount of credits received in this tick
-- @return boolean Return false to cancel the credit tick
-- @hook
-- @realm server
function GAMEMODE:TTTPlayerUsedTicketMuncher(ply, ent, credited)

end

---
-- @param Player ply
-- @param number creditMax
-- @return boolean
-- @realm shared
function ENT:GiveCredit(ply, creditRate)
	if self:GetStoredCredits() > 0 then
		creditRate = creditRate or self.CreditRate

		local credited = self:TakeStoredCredits(creditRate)

		---
		-- @realm shared
		if hook.Run("TTTPlayerUsedTicketMuncher", ply, self, credited) == false then
			return false
		end

		ply:AddCredits(credited)

		if timeLastSound + 2 < CurTime() then
			self:EmitSound(soundCrediting)

			timeLastSound = CurTime()
		end

		if not table.HasValue(self.fingerprints, ply) then
			self.fingerprints[#self.fingerprints + 1] = ply
		end

		return true
	end

	self:EmitSound(soundFail)
	return false
end

---
-- @param Player ply
-- @realm shared
function ENT:Use(ply)
	local t = CurTime()
	if not IsValid(ply) or not ply:IsPlayer() or not ply:IsActive() or t < self.NextCredit then return end

	local credited = self:GiveCredit(ply, self.CreditRate)

	self.NextCredit = t + (self.CreditFreq * (credited and 1 or 2))
end

if SERVER then
	-- recharge
	local nextdigest = 0

	---
	-- @realm server
	function ENT:Think()
		if nextdigest > CurTime() then return end

		self:Digest(self.DigestRate)

		nextdigest = CurTime() + self.DigestFreq
	end

	---
	-- traditional equipment destruction effects
	-- @param DamageInfo dmginfo
	-- @realm server
	function ENT:OnTakeDamage(dmginfo)
		if dmginfo:GetAttacker() == self:GetPlacer() and not self.DamageFromOwner then return end

		self:TakePhysicsDamage(dmginfo)
		self:SetHealth(self:Health() - dmginfo:GetDamage())

		local att = dmginfo:GetAttacker()
		local placer = self:GetPlacer()

		if IsPlayer(att) then
			DamageLog(Format("DMG: \t %s [%s] damaged ticket muncher [%s] for %d dmg", att:Nick(), att:GetRoleString(), IsPlayer(placer) and placer:Nick() or "<disconnected>", dmginfo:GetDamage()))
		end

		if self:Health() > 0 then return end

		self:Remove()

		util.EquipmentDestroyed(self:GetPos())

		if IsValid(self:GetPlacer()) then
			LANG.Msg(self:GetPlacer(), "ttt_ticket_muncher_broken")
		end
	end
else -- CLIENT
	local TryT = LANG.TryTranslation
	local ParT = LANG.GetParamTranslation

	local key_params = {
		usekey = Key("+use", "USE"),
	}

	-- handle looking at ticket_muncher
	hook.Remove("TTTRenderEntityInfo", "HUDDrawTargetIDTicketMuncher")
	hook.Add("TTTRenderEntityInfo", "HUDDrawTargetIDTicketMuncher", function(tData)
		local client = LocalPlayer()
		local ent = tData:GetEntity()

		if not IsValid(client) or not client:IsTerror() or not client:Alive()
		or not IsValid(ent) or tData:GetEntityDistance() > 100 or ent:GetClass() ~= "ttt_ticket_muncher" then
			return
		end

		-- enable targetID rendering
		tData:EnableText()
		tData:EnableOutline()
		tData:SetOutlineColor(client:GetRoleColor())

		tData:SetTitle(TryT(ent.PrintName))
		tData:SetSubtitle(TryT("ttt_ticket_muncher_subtitle"))

		local ttt_ticket_muncher_fullness = math.Round(ent:GetStomachFullness() * 100, 2)
		local ttt_ticket_muncher_digested = math.Round(ent:GetDigestedProgress() * 100, 2)

		tData:AddDescriptionLine(TryT("ttt_ticket_muncher_short_desc"))

		if (ttt_ticket_muncher_fullness > 0 or ttt_ticket_muncher_digested > 0) then
			tData:AddDescriptionLine(
				ParT("ttt_ticket_muncher_fullness", {
					digested = ttt_ticket_muncher_digested,
					fullness = ttt_ticket_muncher_fullness
				}),
				roles.DETECTIVE.ltcolor
			)
			tData:AddDescriptionLine(
				ParT("ttt_ticket_muncher_digested", {
					digested = ttt_ticket_muncher_digested,
					fullness = ttt_ticket_muncher_fullness
				}),
				roles.DETECTIVE.ltcolor
			)
		else
			tData:AddDescriptionLine(
				TryT("ttt_ticket_muncher_empty"),
				COLOR_ORANGE
			)
		end

		if client:IsActive() and client:IsShopper() and ent:GetStoredCredits() > 0 then
			tData:AddDescriptionLine(
				ParT("ttt_ticket_muncher_credits", {
					usekey = key_params.usekey,
					n = ent:GetStoredCredits(),
				}),
				COLOR_YELLOW,
				{materialCredits}
			)
		end
	end)
end
