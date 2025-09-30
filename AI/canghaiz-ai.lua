--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  Mogara
*********************************************************************]]

--骆统
sgs.ai_skill_invoke.luaqinzheng = function(self, data)
    return true
end
sgs.ai_skill_playerchosen.luaqinzheng = function(self, targets)
    local effectslash, best_target, target, throw_weapon
	local defense = 6
	local weapon = self.player:getWeapon()
	if weapon and (weapon:isKindOf("Fan") or weapon:isKindOf("QinggangSword")) then 
        throw_weapon = true 
    end
    for _, enemy in sgs.qlist(targets) do
        if not self:isFriend(enemy) then
            local def = sgs.getDefenseSlash(enemy, self)
            local slash = sgs.cloneCard("slash")
            local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

            if not self.player:canSlash(enemy, slash, false) then
            elseif throw_weapon and enemy:hasArmorEffect("Vine") then
                if enemy:getHp() <= 2 and getCardsNum("Jink", enemy, self.player) == 0 then
                    best_target = enemy
                    break
                end
            elseif self:slashProhibit(nil, enemy) then
            elseif eff then
                if enemy:getHp() == 1 and getCardsNum("Jink", enemy, self.player) == 0 then
                    best_target = enemy
                    break
                end
                if def < defense then
                    best_target = enemy
                    defense = def
                end
                target = enemy
            end
        end
	end
    if best_target then return best_target end
    if target then return target end
    return ""
end

--虞翻
sgs.ai_skill_invoke.luazhiyan = function(self, data)
    return true
end
sgs.ai_skill_playerchosen.luazhiyan = function(self, targets)
    local friends = {}
    if self.player:getMark("luazongxuan_discard") > 0 then
        self:sort(friends, "hp")
        for _, p in sgs.qlist(targets) do
            if self.player:isFriendWith(p) then
                table.insert(friends, p)
                break
            end
        end
    else
        self.room:sortByActionOrder(targets)
        for _, p in sgs.qlist(targets) do
            if self.player:isFriendWith(p) then
                table.insert(friends, p)
                break
            end
        end
    end
    return friends[1]
end

--曹植
sgs.ai_skill_invoke.lualuoying = function(self, data)
    return true
end
local luajiushi_skill = {}
luajiushi_skill.name = "luajiushi"
table.insert(sgs.ai_skills, luajiushi_skill)
luajiushi_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("#luajiushi") then return false end
    if not self.player:hasShownAllGenerals() or self.player:hasUsed("Analeptic") then return false end
    if self:getCardsNum("Slash") == 0 then return false end
    return sgs.Card_Parse("#luajiushiCard:.:&luajiushi")
end
sgs.ai_use_priority.luajiushiCard = 6

sgs.ai_cardsview.luajiushi = function(self, class_name, player)
	if class_name == "Analeptic" then
		if player:hasShownSkill("luajiushi") and player:hasShownAllGenerals() and sgs.Analeptic_IsAvailable(player) then
			return ("analeptic:luajiushi[no_suit:0]=.")
		end
	end
end

--王凌
sgs.ai_skill_choice["startcommand_luamibei"] = function(self, choices)
    Global_room:writeToConsole(choices)
    choices = choices:split("+")
    local commands_toEnemy = {"command2", "command3", "command6", "command4", "command1", "command5"}--索引大小代表优先级，注意不是原顺序
    local commands_toFriend = {"command5", "command4", "command3", "command6", "command2", "command1"}
    local current = self.room:getCurrent()
    if self.player:isFriendWith(current) then
        local command_value1 = table.indexOf(commands_toFriend,choices[1])
        local command_value2 = table.indexOf(commands_toFriend,choices[2])
        local index = math.max(command_value1,command_value2)
        return commands_toFriend[index]
    else
        local command_value1 = table.indexOf(commands_toEnemy,choices[1])
        local command_value2 = table.indexOf(commands_toEnemy,choices[2])
        local index = math.max(command_value1,command_value2)
        return commands_toEnemy[index]
    end
end
sgs.ai_skill_choice["docommand_luamibei"] = function(self, choices, data)
    local source = data:toPlayer()
    local index = self.player:getMark("command_index")
    local is_friend = self:isFriend(source)
    local count = 0
    if self.player:getHandcardNum() <= 1 and not self.player:hasSkills("qiaobian|qiaobian_egf") then
        if self:willSkipPlayPhase() then
            if index <= 2 or index == 4 then --被乐，只执行打一、摸一和驳言军令
                return "yes"
            else
                return "no"
            end
        elseif self:willSkipDrawPhase() then
            if index <= 2 then --只被兵，只执行打一、摸一，体流看血量和手牌数
                return "yes"
            elseif index == 3 then
                if self.player:getHp() > 1 and source:getHandcardNum() >= 3 then
                    return "yes"
                else
                    return "no"
                end
            end
        elseif index == 3 then
            if self.player:getHp() > 1 and source:getHandcardNum() >= 3 then
                return "yes"
            else
                return "no"
            end
        end
    end

    if index == 1 and is_friend then
        return "yes" 
    end
    if index == 2 and is_friend then
        return "yes"
    end
    if index == 3 or (self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty()) then
        return "yes"
    end
    if index == 4 then
        if self.player:getMark("command4_effect") > 0 then
            return "yes"
        end
    end
    if index == 5 then
        if not self.player:faceUp() then
            return "yes"
        end
        if self.player:hasSkill("jushou") and self.player:getPhase() <= sgs.Player_Finish then
            return "yes"
        end
    end
    if index == 6 and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 then
        return "yes"
    end
    return "no"
end
sgs.ai_skill_playerchosen["command_luamibei"] = sgs.ai_skill_playerchosen.damage
sgs.ai_skill_cardshow.luamibei = function(self, who)
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isKindOf("Slash") or c:isKindOf("SavageAssault") or c:isKindOf("ArcheryAttack") then
            return c:getEffectiveId()
        elseif c:isKindOf("BurningCamps") and not self.player:isFriendWith(self.player:getNextAlive()) then
            return c:getEffectiveId()
        elseif card:isKindOf("Duel") then
            return c:getEffectiveId()
        elseif card:isKindOf("Snatch") or card:isKindOf("Dismantlement") then
            return c:getEffectiveId()
        elseif card:isKindOf("Analeptic") then
            return c:getEffectiveId()
        end
    end
    return self:askForCardShow(self.player, "luamibei")
end
sgs.ai_skill_discard.luamibei = sgs.ai_skill_discard.qiaobian

--沮授
sgs.ai_skill_invoke.luaxuyuan = function(self, data)
    local room = self.player:getRoom()
    local current = room:getCurrent()
    if self.player:isFriendWith(current) and not self.player:isNude() then
        if current:hasSkills("kuangcai|gongxiu|wuxin|beige|guidao|yongsi|jijiu|fenglve|lijian|shenwei") then
            return true
        end
    end
    return false
end
sgs.ai_skill_choice["luaxuyuan_choice"] = function(self, choices, data)
    local current = self.room:getCurrent()
    if self.player:isFriendWith(current) and not self.player:isNude() then
        if current:hasSkills("yongsi|fenglve|shenwei") then
            return "luaxuyuan_both"
        elseif current:hasSkills("kuangcai|gongxiu|beige|guidao|jijiu") then
            return "luaxuyuan_draw"
        elseif current:hasSkills("lijian|wuxin") then
            return "luaxuyuan_play"
        end
    end
    return "luaxuyuan_draw"
end

sgs.ai_skill_invoke.luashibei = function(self, data)
    local damage = data:toDamage()
    local from = damage.from
    local equipcards_from = from:getEquips()
    local equipcards_self = self.player:getEquips()
    local hasHorse_self, hasHorse_from = false
    for _, card in sgs.qlist(equipcards_self) do
        if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")  or card:isKindOf("SixDragons") then
            hasHorse_self = true
            break
        end
    end
    for _, card in sgs.qlist(equipcards_from) do
        if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")  or card:isKindOf("SixDragons") then
            hasHorse_from = true
            break
        end
    end
    if hasHorse_self then
        return true
    elseif hasHorse_from and not from:hasSkills(sgs.lose_equip_skill) then
        return true
    end
    return false
end
sgs.ai_skill_choice.luashibei = function(self, choices, data)
    local damage = data:toDamage()
    local from = damage.from
    local equipcards_from = from:getEquips()
    local equipcards_self = self.player:getEquips()
    local hasHorse_self, hasHorse_from = false
    for _, card in sgs.qlist(equipcards_self) do
        if card:isKindOf("SixDragons") then
            hasHorse_self = true
            self.luashibeiCard = card
            break
        elseif card:isKindOf("DefensiveHorse") then
            hasHorse_self = true
            self.luashibeiCard = card
            break
        elseif card:isKindOf("OffensiveHorse") then
            hasHorse_self = true
            self.luashibeiCard = card
            break
        end
    end
    for _, card in sgs.qlist(equipcards_from) do
        if card:isKindOf("SixDragons") then
            hasHorse_self = true
            self.luashibeiCard = card
            break
        elseif card:isKindOf("OffensiveHorse") then
            hasHorse_self = true
            self.luashibeiCard = card
            break
        elseif card:isKindOf("DefensiveHorse") then
            hasHorse_self = true
            self.luashibeiCard = card
            break
        end
    end
    if self:getHp() == 1 and hasHorse_self then
        return "luashibei_discard"
    elseif hasHorse_from and not from:hasSkills(sgs.lose_equip_skill) then
        return "luashibei_get"
    elseif hasHorse_self then
        return "luashibei_discard"
    end
    return ""
end
sgs.ai_skill_askforag.luashibei = function(self, card_ids)
    if self.luashibeiCard then
        return self.luashibeiCard:getEffectiveId()
    end
	return card_ids:at(0)
end

--皇甫嵩
local luafenyue_skill = {}
luafenyue_skill.name = "luafenyue"
table.insert(sgs.ai_skills, luafenyue_skill)
luafenyue_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasFlag("luafenyue_fail") or self.player:isKongcheng() or self.player:getMark("#luafenyue_times") 
    >= x then return false end
    return sgs.Card_Parse("#luafenyueCard:.:&luafenyue")
end

sgs.ai_skill_use_func["#luafenyueCard"] = function(card, use, self)
    for _, enemy in pairs(self.enemies) do
        if not enemy:isKongcheng() and not enemy:isRemoved() and not enemy:hasArmorEffect("PeaceSpell") then
            if not (enemy:hasSkill("liuli") and enemy:hasSkills("xuanlue|xiaoji")) then
                if enemy:getHp() <= 2 and enemy:getHandcardNum() <= 4 then
                    use.card = card
                    if use.to then
                        use.to:append(enemy)
                        break
                    end
                elseif self:getOverflow() > 1 then
                    use.card = card
                    if use.to then
                        use.to:append(enemy)
                        break
                    end
                end
            end
        end
    end
end
sgs.ai_skill_choice.luafenyuePindian = function(self, choices, data)
    local pd = data:toPindian()
    if pd then
        local pdTo = pd.to
        if pd.to:getHandcardNum() <= 2 then
            if pd.to:getMark("##boyan") <= 0 then
                local jiangwaifeiyi = sgs.findPlayerByShownSkillName("shoucheng")
                if jiangwaifeiyi and pd.to:isFriendWith(jiangwaifeiyi) then
                    return "luafenyue_boyan"
                end
            else
                return "luafenyue_slash"
            end
        else
            if pd.to:getMark("##boyan") <= 0 then
                return "luafenyue_boyan"
            else
                return "luafenyue_slash"
            end
        end
        return "luafenyue_slash"
    end
end
sgs.ai_use_priority.luafenyueCard = 7.2
