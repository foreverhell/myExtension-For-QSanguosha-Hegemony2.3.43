extension = sgs.Package("weather", sgs.Package_CardPack)  
local skills = sgs.SkillList()

Sunny = sgs.CreateTreasure{  
    name = "Sunny",  
    class_name = "Sunny",
    suit = sgs.Card_Heart,  
    number = 13,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:setTag("weather", sgs.QVariant("sunny")) 
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        --永久天气太强
        if room:getTag("weather"):toString() == "sunny" then --当前是晴天，移除后，天气为空
            room:setTag("weather", sgs.QVariant("")) 
        end
        --当前不是晴天，说明已经被覆盖，移除后，天气不变
    end  
}  


Rainy = sgs.CreateTreasure{  
    name = "Rainy",  
    class_name = "Rainy",
    suit = sgs.Card_Spade,  
    number = 13,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:setTag("weather", sgs.QVariant("rainy")) 
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        --永久天气太强
        if room:getTag("weather"):toString() == "rainy" then --当前是雨天，移除后，天气为空
            room:setTag("weather", sgs.QVariant("")) 
        end
        --当前不是雨天，说明已经被覆盖，移除后，天气不变
    end  
}  

--晴天，火属性伤害+1
SunnyFireDamage = sgs.CreateTriggerSkill{  
    name = "SunnyFireDamage",  
    events = {sgs.DamageCaused},
    global = true,
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if room:getTag("weather"):toString() == "sunny" and damage.nature == sgs.DamageStruct_Fire then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}

--晴天，雷属性伤害-1
SunnyThunderDamage = sgs.CreateTriggerSkill{  
    name = "SunnyThunderDamage",  
    events = {sgs.DamageCaused},
    global = true,
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if room:getTag("weather"):toString() == "sunny" and damage.nature == sgs.DamageStruct_Thunder then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage - 1  
        data:setValue(damage)
        if damage.damage <= 0 then
            return true
        end
        return false  
    end  
}
--晴天，摸牌+1
SunnyDraw = sgs.CreateDrawCardsSkill{  
    name = "SunnyDraw",  
    frequency = sgs.Skill_Compulsory,  
    global = true,
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        if room:getTag("weather"):toString() == "sunny" then
            return n+1
        end  
        return n
    end  
}  
--晴天，手牌上限+1
SunnyMaxcards = sgs.CreateMaxCardsSkill{  
    name = "SunnyMaxcards",  
    global = true,
    extra_func = function(self, player)  
        local room = player:getRoom()  
        if room:getTag("weather"):toString() == "sunny" then
            return 1
        end  
        return 0
    end  
}
--晴天，攻击范围+1
SunnyRange = sgs.CreateAttackRangeSkill{  
    name = "SunnyRange",  
    global = true,
    extra_func = function(self, player, include_weapon)  
        local room = player:getRoom()  
        if room:getTag("weather"):toString() == "sunny" then
            return 1
        end  
        return 0
    end  
}  
--晴天，回复量+1
SunnyRecover = sgs.CreateTriggerSkill{  
    name = "SunnyRecover",  
    events = {sgs.PreHpRecover},  
    global = true,      
    can_trigger = function(self, event, room, player, data)  
        return self:objectName() 
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return true
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local recover = data:toRecover()  
        recover.recover = recover.recover + 1
        data:setValue(recover)
        return false        
    end  
}
--雨天，火属性伤害为0
RainyFireDamage = sgs.CreateTriggerSkill{  
    name = "RainyFireDamage",  
    events = {sgs.DamageCaused},
    global = true,
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if room:getTag("weather"):toString() == "rainy" and damage.nature == sgs.DamageStruct_Fire then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = 0--damage.damage - 1  
        data:setValue(damage)
        if damage.damage <= 0 then
            return true
        end
        return false  
    end  
}


--雨天，雷属性伤害+1
RainyThunderDamage = sgs.CreateTriggerSkill{  
    name = "RainyThunderDamage",  
    events = {sgs.DamageCaused},
    global = true,
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if room:getTag("weather"):toString() == "rainy" and damage.nature == sgs.DamageStruct_Thunder then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)
        return false  
    end  
}
--雨天，所有角色到其他角色的距离+1
RainyDistance = sgs.CreateDistanceSkill{
    name = "RainyDistance",
    global = true,
    correct_func = function(self, from, to)
		if room:getTag("weather"):toString() == "rainy" then
			return 1
		end
		return 0
	end
}

Sunny:setParent(extension)
Rainy:setParent(extension)
if not sgs.Sanguosha:getSkill("SunnyFireDamage") then
    skills:append(SunnyFireDamage)
end
if not sgs.Sanguosha:getSkill("SunnyThunderDamage") then
    skills:append(SunnyThunderDamage)
end
if not sgs.Sanguosha:getSkill("SunnyDraw") then
    skills:append(SunnyDraw)
end
if not sgs.Sanguosha:getSkill("SunnyMaxcards") then
    skills:append(SunnyMaxcards)
end
if not sgs.Sanguosha:getSkill("SunnyRange") then
    skills:append(SunnyRange)
end
if not sgs.Sanguosha:getSkill("SunnyRecover") then
    skills:append(SunnyRecover)
end

if not sgs.Sanguosha:getSkill("RainyFireDamage") then
    skills:append(RainyFireDamage)
end
if not sgs.Sanguosha:getSkill("RainyThunderDamage") then
    skills:append(RainyThunderDamage)
end
if not sgs.Sanguosha:getSkill("RainyDistance") then
    skills:append(RainyDistance)
end
sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
    ["weather"] = "天气包",
    ["Sunny"] = "晴天",
    [":Sunny"] = "装备时，将天气改为晴天，火属性伤害+1，雷属性伤害-1，摸牌+1，手牌上限+1，攻击范围+1，治疗量+1；失去时，若天气为晴天，则改为无天气",
    ["Rainy"] = "雨天",
    ["Rainy"] = "装备时，将天气改为雨天，火属性伤害为0，雷属性伤害+1，所有角色到其他角色的距离+1；失去时，若天气为雨天，则改为无天气",
--晴天，火属性伤害+1，雷属性伤害-1，摸牌+1，手牌上限+1，攻击范围+1，治疗量+1
--雨天，火属性伤害为0，雷属性伤害+1，所有角色到其他角色的距离+1，反转判定结果
--可以考虑添加：
--冰雹：每轮随机对一名角色造成一点伤害/流失一点体力；伤害视为体力流失；体力流失+1
--场地
--山地：易守难攻。视为装备+1-1
--要塞：伤害-1
--图书馆：摸牌+1
--魔法阵：属性伤害视为无属性伤害
--圣地：治疗翻倍
--天气覆盖，场地不覆盖；永久天气/5轮天气
--这样就可以创建一个武将，可以修改天气、场地
}
return {extension}

--[[
setSunnyCard = sgs.CreateSkillCard{
    name = "setSunnyCard",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:setTag("weather", sgs.QVariant("sunny")) 
    end
}

setSunny = sgs.CreateZeroCardViewAsSkill{
    name = "setSunny",
    view_as = function(self)
        local skill_card = setSunnyCard:clone()
        skill_card:setShowSkill(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#setSunnyCard")
    end
}
]]