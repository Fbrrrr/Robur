-- Vector Zed Script by Fbr --
local RREADY, QREADY, WREADY, EREADY
local prediction
local Menu = Libs.NewMenu
local Orbwalker = Libs.Orbwalker
local Nav = CoreEx.Nav
local DamageLib = Libs.DamageLib
local CollisionLib = Libs.CollisionLib
local SpellLib = Libs.Spell
local ts = Libs.TargetSelector()
local Evade = CoreEx.EvadeAPI
local ObjectManager = CoreEx.ObjectManager
local EventManager = CoreEx.EventManager
local Input = CoreEx.Input
local Enums = CoreEx.Enums
local Game = CoreEx.Game
local Geometry = CoreEx.Geometry
local Rectangle = Geometry.Rectangle
local Circle = Geometry.Circle
local Renderer = CoreEx.Renderer
local HealthPrediction = Libs.HealthPred
local Player = ObjectManager.Player.AsHero
local Utils = {}
local SpellSlots = Enums.SpellSlots
local SpellStates = Enums.SpellStates
local Events = Enums.Events
local Libs = _G.Libs
local Zed = {}
local Target = {}
local IsMarked = {}
local Distance = {}
 
if Player.CharName ~= "Zed" then
    return false
end

function Utils.IsGameAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead)
end

function Utils.IsSpellReady(Slot)
    return Player:GetSpellState(Slot) == SpellStates.Ready
end

function Utils.IsInRange(From, To, Min, Max)
    local Distance = From:Distance(To)
    return Distance > Min and Distance <= Max
end

function Utils.TargetMissingHealth(Target)
    local bonusDmg = (Target.MaxHealth - Target.Health) / 100
    return  bonusDmg
end

function Utils.GetMinions()
    local target = TS:GetTarget()
    local minions = {}

    if not Utils.IsValidTarget(Target) then return false end
end

local Spells = {
    Q =  {
        Slot = Enums.SpellSlots.Q,
        SlotString = "Q",
        Range = 900,
        Width = 100,
        Radius = 100/2,
        Speed = 1700,
        Delay = 0.25,
        UseHitbox = true,
        Type = "Linear",
        Collisions={Heroes=false, Minions=true, WindWall=true, Wall=false}
    },
    W = {
        Slot = Enums.SpellSlots.W,
        SlotString = "W",
        Range = 650,
        Radius = 290,
        EffectRadius = 290,
        Delay = 0,
        Type = "Circular"
    },
    E = {
        Slot = Enums.SpellSlots.E,
        SlotString = "E",
        Range = 0,
        EffectRadius = 290,
        Delay = 0,
        Type = "Circular"
    },
    _R = {
        Slot = Enums.SpellSlots.R,
        SlotString = "R",
        Range = 625,
        Delay = 0.6,
		Type = "Targeted"
    }
}

function Zed.LoadMenu()
    Menu.RegisterMenu("FastZed", "FastZed", function()
        Menu.Text("Made by Fbr", true)

        Menu.NewTree("Combo", "Combo", function()
            Menu.Checkbox("Combo.Q.Use", "Use Q", true)
			Menu.Checkbox("Combo.W.Use", "Use W", true)
            Menu.Checkbox("Combo.E.Use", "Use E", true)
			Menu.Checkbox("Combo.R.Use", "Use R", true)
            Menu.NextColumn()
        end)
        Menu.NewTree("Harass", "Harass", function()
            Menu.Checkbox("Harass.Q.Use", "Use Q", true)
            Menu.Slider("Harass.Q.MinMana", "Minimum Energy for Q", 40, 5, 100, 1)
			Menu.Checkbox("Combo.W.Use", "Use W", true)
			Menu.Slider("Harass.W.MinMana", "Minimum Energy for W", 40, 5, 100, 1)
            Menu.Checkbox("Combo.E.Use", "Use E", true)
			Menu.Slider("Harass.E.MinMana", "Minimum Energy for E", 40, 5, 100, 1)
            Menu.NextColumn()
        end)
        Menu.Separator()
        Menu.NewTree("Waveclear", "Waveclear", function()
            Menu.Checkbox("Waveclear.Q.Use", "Use Q", true)
            Menu.Slider("Waveclear.Q.MinMana", "Minimum Energy for Q", 40, 5, 100, 1)
            Menu.Slider("Waveclear.Q.MinTargets", "Minimum Targets for Q", 2, 1, 6, 1)
            Menu.NextColumn()
        end)
        Menu.Separator()
        Menu.NewTree("Drawings", "Drawings", function()
            Menu.Checkbox("Drawings.Q", "Draw Q Range", true)
            Menu.Checkbox("Drawings.W", "Draw W Range", true)
            Menu.Checkbox("Drawings.R", "Draw R Range", true)
            Menu.Checkbox("Draw.Damage", "Draw Damage", false)
			Menu.NextColumn()
        end)
        Menu.Separator()
        Menu.NewTree("Misc", "Misc", function()
		Menu.Checkbox("Misc.AutoE", "Auto E", false )
		Menu.Checkbox("Misc.SaveW", "Save W when Ult", false)
		Menu.Checkbox("Misc.SwapR", "Swap to shadow if Killable", false )
        end)

    end)
end
 
 
function LoadVariables()
        wClone, rClone = nil, nil
				RREADY, QREADY, WREADY, EREADY = false, false, false, false
        ignite = nil
        lastW = 0
        delay, qspeed = 235, 1.742

				        --Helpers
        lastAttack, lastWindUpTime, lastAttackCD, lastAnimation  = 0, 0, 0, ""
        EnemyTable = {}
        EnemysInTable = 0
        HealthLeft = 0
        PctLeft = 0
        BarPct = 0
end

function Zed.OnDrawDamage(target, dmgList)
    if not Menu.Get("Draw.Damage") then 
			return 
		end
		
        table.insert(dmgList, Utils.CalculateComboDamage(Target))
    end

function Zed.OnTick()
				Calculations()
				GlobalInfos()
                SetCooldowns() 
				Zed.AutoE()
	
				local target = ObjectManager.Get("enemy", "heroes")
		for i, v in pairs(target) do
                        local hero = v.AsHero
                        if hero and hero.IsTargetable and Utils.IsInRange(Player.Position, hero.Position, 0, 900) then
						if target == nil then
                    target = v
                end

                if v.Health < target.Health then

                    target = v
	end	
	return target

		end
			end
			    if not Utils.IsGameAvailable() then
        return false
    end

    local OrbwalkerMode = Orbwalker.GetMode()

    local OrbwalkerLogic = Zed[OrbwalkerMode]

    if OrbwalkerLogic then
        if OrbwalkerLogic() then
            return true
        end
    end
			end
			
function Utils.IsValidTarget(Target)
    return Target and Target.IsTargetable and Target.IsAlive
end

function Utils.CountMinionsInRange(range, type)
    local amount = 0
    for k, v in ipairs(ObjectManager.GetNearby(type, "minions")) do
        local minion = v.AsMinion
        if not minion.IsJunglePlant and minion.IsValid and not minion.IsDead and minion.IsTargetable and
                Player:Distance(minion) < range then
            amount = amount + 1
        end
    end
    return amount
end
function Utils.CountMonstersInRange(range, type)
    local amount = 0
    for k, v in ipairs(ObjectManager.GetNearby(type, "minions")) do
        local minion = v.AsMinion
        if not minion.IsJunglePlant and minion.IsValid and not minion.IsDead and minion.IsTargetable and
                Player:Distance(minion) < range then
            amount = amount + 1
        end
    end
    return amount
end

function Utils.HasBuff(target, buff)


    for i, v in pairs(target.Buffs) do
        if v.Name == buff then
            return true
        end

    end

    return false

end

function Zed.OnDraw()
 if Menu.Get("Drawings.Q") then
                if QREADY then
					   Renderer.DrawCircle3D(Player.Position, 900, 0xFFFFE303)
                else
                       Renderer.DrawCircle3D(Player.Position, 900, 0xFFFFFFFF)
                end
        end
        if Menu.Get("Drawings.W") then
                if WREADY then
                        Renderer.DrawCircle3D(Player.Position, 650, 0xFFFFE303)
                else
                        Renderer.DrawCircle3D(Player.Position, 650, 0xFFFFFFFF)
                end
        end
		end
 
function Zed.OnProcessSpell(unit, spell)
        if unit.isMe and spell.name == "ZedShadowDash" then
                lastW = GetTickCount()
        end
end

function Utils.IsInRange(From, To, Min, Max)
    -- Is Target in range
  --  local Distance = From:Distance(To)
   -- return Distance > Min and Distance <= Max
end
 
function Zed.Combo()
  if RREADY then Zed.CastR(Target) return end
	if not Target then
        return false
    end
        if not RREADY or rClone ~= nil then
                if Player:GetSpell(SpellSlots.W).name ~= "zedw2" and WREADY and ((Distance(Target) < 700) or (Distance(Target) > 125 and not RREADY)) then
                        if not (Config.Misc.SaveW and ((Player:GetSpell(SpellSlots.R).name == "ZedR2") or (rClone ~= nil and rClone.valid))) then
                                Input.Cast(SpellSlots.W, Target.x, Target.z)
                        end
                end
                if not WREADY or wClone ~= nil or Config.Misc.SaveW then return  end
                        if EREADY then  
                                if ValidTarget(Target) then    
                                       autoE()
                                end
                        end
                        if QREADY then  
                                if prediction ~= nil and Distance(prediction) < 900 then
                                        Input.Cast(SpellSlots.Q, prediction.x, prediction.z)
                                end
                        end
                end
				if Player:GetSpell(SpellSlots.R).name == "ZedR2" and ((Player.health / Player.maxHealth * 100) <= Config.Misc.SwapR) then
                Input.Cast(SpellSlots.R, Target)
	end
		end
 
function Zed.Harass()
        if prediction ~= nil and (QREADY and WREADY and Distance(prediction) < 700) or (QREADY and wClone ~= nil and wClone.valid and Distance(prediction, wClone) < 900) then
                if Player:GetSpell(SpellSlots.W).name ~= "zedw2" and GetTickCount() > lastW + 1000 then
                        Input.Cast(SpellSlots.W, Target.x, Target.z)
                else
                        Input.Cast(SpellSlots.Q, prediction.x, prediction.z)
                end
        elseif QREADY and not WREADY and prediction and Distance(prediction) < 900 then
                Input.Cast(SpellSlots.Q, prediction.x, prediction.z)
        end
end
 
function Zed.AutoE(target)
        local box = 280
		local target = Target
		if not Menu.Get("Misc.AutoE") then return 
		end
        if Utils.IsInRange(target) < box or (wClone ~= nil and wClone.valid and Utils.IsInRange(target, wClone) < box) or (rClone ~= nil and rClone.valid and Utils.IsInRange(target, rClone) < box) then
                Input.Cast(SpellSlots.E)
        else
                for i = 1, ObjectManager.iCount do
                        local target = ObjectManager:Get("enemy", "heroes")
                        if Target(target) and Utils.IsInRange(target) < box or (wClone ~= nil and wClone.valid and Utils.IsInRange(target, wClone) < box) or (rClone ~= nil and rClone.valid and Utils.IsInRange(target, rClone) < box) then
                                Input.Cast(SpellSlots.E)
                        end
                end
        end
		end
 
 function Utils.TargetsInRange(Target, Range, Team, Type, Condition)
    -- return target in range
    local Objects = ObjectManager.Get(Team, Type)
    local Array = {}
    local Index = 0

    for _, Object in pairs(Objects) do
        if Object and Object ~= Target then
            Object = Object.AsAI
            if
            Utils.IsValidTarget(Object) and
                    (not Condition or Condition(Object))
            then
                local Distance = Target:Distance(Object.Position)
                if Distance <= Range then
                    Array[Index] = Object
                    Index = Index + 1
                end
            end
        end
    end

    return { Array = Array, Count = Index }
end
 
function Zed.CastR()
		local Target = Utils.IsValidTarget()
		local target = ObjectManager.Get("enemy", "heroes")
       if not RREADY then return end
        if Target(target) then
                if Player:Distance(target) <= 625 and RREADY and Player:GetSpell(SpellSlots.R).name ~= "ZedR2" then
                        Input.Cast(SpellSlots.R, target)
                end
        else
                return
        end
end
 
function Zed.rUsed()
        if Player:GetSpell(SpellSlots.R).name == "ZedR2" then
                return true
        else
                return false
        end
end
function GlobalInfos()
        QREADY = (Utils.IsSpellReady(SpellSlots.Q))
        WREADY = (Utils.IsSpellReady(SpellSlots.W))
        EREADY = (Utils.IsSpellReady(SpellSlots.E))
        RREADY = (Utils.IsSpellReady(SpellSlots.R))
        QMana = Player:GetSpell(SpellSlots.Q).mana
        WMana = Player:GetSpell(SpellSlots.W).mana
        EMana = Player:GetSpell(SpellSlots.E).mana
        RMana = Player:GetSpell(SpellSlots.R).mana
       
        MyMana = Player.mana
end
 
function Zed.OnCreateObj(obj)
        if obj.valid and obj.name:find("Zed_Clone_idle.troy") then
                if wClone == nil then
                        wClone = obj
                elseif rClone == nil then
                        rClone = obj
                end
        end
end
 
function Zed.OnDeleteObj(obj)
        if obj.valid and wClone and obj == wClone then
                wClone = nil
        elseif obj.valid and rClone and obj == rClone then
                rClone = nil
        end
end

 local function IsMarked(Target)
    return Target:GetBuff("zedulttargetmark");
end
 
function SetCooldowns()
        QREADY = (Utils.IsSpellReady(SpellSlots.Q))
        WREADY = (Utils.IsSpellReady(SpellSlots.W))
        EREADY = (Utils.IsSpellReady(SpellSlots.E))
        RREADY = (Utils.IsSpellReady(SpellSlots.R))
       -- iReady = (ignite ~= nil )
end

function Calculations()
       
        for i=1, EnemysInTable do
               
                local target = EnemyTable[i].hero
                if target(target) and target.visible then
                        caaDmg = getDmg("AD",target,Player)
                        cpDmg = getDmg("P", target, Player)
                        cqDmg = getDmg("Q", target, Player)
                        ceDmg = getDmg("E", target, Player)
                        ciDmg = getDmg("IGNITE", target, Player)
               
                        UltExtraDmg = 0
                        cItemDmg = 0
                        cTotal = 0
       
                       
                        EnemyTable[i].p = cpDmg
                       
                        EnemyTable[i].q = cqDmg
                       
                        if WillQCol then
                                EnemyTable[i].q = EnemyTable[i].q / 2          
                        end
                        EnemyTable[i].q2 = EnemyTable[i].q + (cqDmg / 2)
                       
                        EnemyTable[i].e = ceDmg
                        if RREADY then
                                UltExtraDmg = Player.totalDamage
                                if WREADY then
                                        UltExtraDmg = UltExtraDmg + (15*Player:GetSpell(SpellSlots.R).level+5) * (EnemyTable[i].q2 + EnemyTable[i].e + EnemyTable[i].p + caaDmg)
                                else
                                        UltExtraDmg = UltExtraDmg + (15*Player:GetSpell(SpellSlots.R).level+5) * (EnemyTable[i].q + EnemyTable[i].e + EnemyTable[i].p + caaDmg)
                                end
                                UltExtraDmg = Player:CalcDamage(target, UltExtraDmg)
                        end
                        EnemyTable[i].r = UltExtraDmg
                       
                       
                        if target.health < EnemyTable[i].e  then
                                EnemyTable[i].IndicatorText = "E Kill"
                                EnemyTable[i].IndicatorPos = 0
                        if not EReady then
                                        EnemyTable[i].NotReady = true
                                else
                                        EnemyTable[i].NotReady = false
                        end    
                elseif target.health < EnemyTable[i].q then
                                EnemyTable[i].IndicatorText = "Q Kill"
                                EnemyTable[i].IndicatorPos = 0
                        if not QREADY then
                                        EnemyTable[i].NotReady = true
                                else
                                        EnemyTable[i].NotReady = false
                        end    
                elseif target.health < EnemyTable[i].q2 then
                                EnemyTable[i].IndicatorText = "W+Q Kill"
                                EnemyTable[i].IndicatorPos = 0
                        if QMana + WMana > MyMana or not QREADY or not WREADY then
                                        EnemyTable[i].NotReady = true
                                else
                                        EnemyTable[i].NotReady = false
                        end            
                elseif target.health < EnemyTable[i].q2 + EnemyTable[i].e then
                                EnemyTable[i].IndicatorText = "W+E+Q Kill"
                                EnemyTable[i].IndicatorPos = 0
                        if QMana + WMana + EMana > MyMana or not QREADY or not WREADY or not EREADY then
                                        EnemyTable[i].NotReady = true
                                else
                                        EnemyTable[i].NotReady = false
                        end
                elseif (not RREADY) and target.health < EnemyTable[i].q2 + EnemyTable[i].e + EnemyTable[i].p + caaDmg + ciDmg + cItemDmg then
                                EnemyTable[i].IndicatorText = "All In"
                                EnemyTable[i].IndicatorPos = 0
                        if QMana + WMana + EMana > MyMana or not QREADY or not WREADY or not EREADY then
                                        EnemyTable[i].NotReady = true
                                else
                                        EnemyTable[i].NotReady = false
                        end    
                elseif (not WREADY) and target.health < EnemyTable[i].q + EnemyTable[i].e + EnemyTable[i].p + EnemyTable[i].r + caaDmg + ciDmg + cItemDmg then
                                EnemyTable[i].IndicatorText = "All In"
                                EnemyTable[i].IndicatorPos = 0
                        if QMana + EMana + RMana > MyMana or not QREADY or not EREADY or not RREADY then
                                        EnemyTable[i].NotReady = true
                                else
                                        EnemyTable[i].NotReady = false
                        end
                elseif target.health < EnemyTable[i].q2 + EnemyTable[i].e + EnemyTable[i].p + EnemyTable[i].r + caaDmg + ciDmg + cItemDmg then
                                EnemyTable[i].IndicatorText = "All In"
                                EnemyTable[i].IndicatorPos = 0
                        if QMana + WMana + EMana + RMana > MyMana or not QREADY or not WREADY or not EREADY or not RREADY then
                                        EnemyTable[i].NotReady = true
                                else
                                        EnemyTable[i].NotReady = false
                        end
                else
                        cTotal = cTotal + EnemyTable[i].q2 + EnemyTable[i].e + EnemyTable[i].p + EnemyTable[i].r + caaDmg
                               
                                HealthLeft = math.round(target.health - cTotal)
                                PctLeft = math.round(HealthLeft / target.maxHealth * 100)
                                BarPct = PctLeft / 103 * 100
                                EnemyTable[i].Pct = PctLeft
                                EnemyTable[i].IndicatorPos = BarPct
                                EnemyTable[i].IndicatorText = PctLeft .. "% Harass"
                                if not qReady or not wReady or not eReady then
                                        EnemyTable[i].NotReady =  true
                                else
                                        EnemyTable[i].NotReady = false
                                end
                end
                end    
        end
end

function Zed.OnCreateObj(obj)
        if obj.valid and obj.name:find("Zed_Clone_idle.troy") then
                if wUsed and wClone == nil then
                        wClone = obj
                elseif rClone == nil then
                        rClone = obj
                end
        end
end
 
function Zed.OnDeleteObj(obj)
        if obj.valid and wClone and obj == wClone then
                wUsed = false
                wClone = nil   
        elseif obj.valid and rClone and obj == rClone then
                rClone = nil
        end
end
 
function Zed.OnProcessSpell(unit, spell)
        if unit.isMe and spell.name == "ZedShadowDash" then
                wUsed = true
                lastW = GetTickCount()
        end
        if unit.isMe then
                if spell.name:lower():find("attack") then
                        lastAttack = GetTickCount() - GetLatency()/2
                        lastWindUpTime = spell.windUpTime*1000
                        lastAttackCD = spell.animationTime*1000
                end
        end
end
 
 
function Zed.OnAnimation(unit, animationName)
        if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end

function OnLoad()
	
	--Ignite()
	
    LoadVariables()
	
    Zed.LoadMenu()
		for EventName, EventId in pairs(Events) do
        if Zed[EventName] then
            EventManager.RegisterCallback(EventId, Zed[EventName])
        end
    end

    return true
end
