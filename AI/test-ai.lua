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

--王平
local jiejianglve_skill = {}
jiejianglve_skill.name = "jiejianglve"
table.insert(sgs.ai_skills, jiejianglve_skill)
jiejianglve_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@jiejianglve") < 1 then return end
    return sgs.Card_Parse("#jiejianglveCard:.:&jiejianglve")
end

sgs.ai_skill_use_func["#jiejianglveCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_priority.jiejianglveCard = 6.2

--潘淑
sgs.ai_skill_choice.jiezhiren = function(self, choices, data)
    return "guanxing"
end

--关羽
sgs.ai_skill_invoke.jienuzhan = function(self, data)
	return true
end

--诸葛亮
sgs.ai_skill_invoke.jieguanxing = function(self, data)
	return true
end
sgs.ai_skill_invoke.jieguanxing_jiangwei = function(self, data)
	return true
end
sgs.ai_skill_invoke.jieguanxing_jiangweiYizhi = function(self, data)
	return true
end

--南华老仙
local jiejinghe_skill = {}
jiejinghe_skill.name = "jiejinghe"
table.insert(sgs.ai_skills, jiejinghe_skill)
jiejinghe_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#jiejingheCard") then return false end
    return sgs.Card_Parse("#jiejingheCard:.:&jiejinghe")
end

sgs.ai_skill_use_func["#jiejingheCard"] = function(card, use, self)
    use.card = card
    for _, p in pairs(self.friends) do
        if p:objectName() == self.player:objectName() and use.to then
            use.to:append(p)
            break
        end
    end
end

sgs.ai_use_priority.jiejingheCard = 6.2

--祖茂
sgs.ai_skill_invoke.jieyinbing = function(self, data)
	return true
end
--[[sgs.ai_skill_playerchosen.jieyinbing = function(self, choices, data)
    return self
end]]
sgs.ai_skill_playerchosen.jieyinbing = sgs.ai_skill_playerchosen.juedi

--沮授
--sgs.ai_skill_invoke.luaxuyuan = true

--徐晃
sgs.ai_skill_invoke.jiejiezi = function(self, data)
    if self.player:hasShownSkill("jiejiezi") then return true end
	local yuanshu = sgs.findPlayerByShownSkillName("weidi")
	if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play then return false end
	return true
end

--刘夫人
sgs.ai_skill_invoke.zhuidu = function(self, data)
	local target = data:toPlayer()
    if target:hasArmorEffect("SilverLion") then
        return false
    end
    if target:hasShownSkill("gongqing") and self:getAttackRange() < 3 then
        return false
    end
    return not self:isFriend(target)
end

--孙坚
sgs.ai_skill_invoke.jiepolu = function(self, data)
    local yuanshu = sgs.findPlayerByShownSkillName("weidi")
	if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play then return false end
    if #self.friends_noself > 0 then return true end
    return false
end
sgs.ai_skill_playerchosen.jiepolu = function(self, targets)
    local result = {}
    for _, p in ipairs(self.friends) do
        if p:isAlive() then
            table.insert(result, p)
        end
    end
    return result
end

--张辽
local jiezhengbing_skill = {}
jiezhengbing_skill.name = "jiezhengbing"
table.insert(sgs.ai_skills, jiezhengbing_skill)
jiezhengbing_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#jiezhengbingCard") then return false end
    --[[local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
    if self:getCardsNum("Slash") > 1 then
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then table.insert(unpreferedCards, card:getEffectiveId()) end
		end
		table.remove(unpreferedCards, 1)
        if (#cards - 2) >= self.player:gethp() then 
            return sgs.Card_Parse("#jiezhengbingCard:" .. unpreferedCards[1] .. ":&jiezhengbing")
        end
	end
    local num = self:getCardsNum("Jink") - 1
	if self.player:getArmor() then num = num + 1 end
	if num > 0 then
		for _, card in ipairs(cards) do
			if card:isKindOf("Jink") and num > 0 then
				table.insert(unpreferedCards, card:getEffectiveId())
				num = num - 1
			end
		end
	end
	for _, card in ipairs(cards) do
		if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
			or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") or card:isKindOf("Lightning") then
			table.insert(unpreferedCards, card:getEffectiveId())
		end
	end

	if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
		table.insert(unpreferedCards, self.player:getWeapon():getEffectiveId())
	end

	if self.player:getOffensiveHorse() and self.player:getWeapon() then
		table.insert(unpreferedCards, self.player:getOffensiveHorse():getEffectiveId())
	end

	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then 
            return sgs.Card_Parse("#jiezhengbingCard:" .. unpreferedCards[index] .. ":&jiezhengbing")
        end
	end]]
    local card_id = self:askForDiscard("dummyreason", 1, 1, false, true)
    return sgs.Card_Parse("#jiezhengbingCard:" .. card_id[1] .. ":&jiezhengbing" )
end

sgs.ai_skill_use_func["#jiezhengbingCard"] = function(card, use, self)
    use.card = card
end
sgs.ai_use_priority.jiezhengbingCard = 4.2

--许褚
local jiexiechan_skill = {}
jiexiechan_skill.name = "jiexiechan"
table.insert(sgs.ai_skills, jiexiechan_skill)
jiexiechan_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@jiexiechan") < 1 or not self.player:hasFlag("luoyi") then return false end
    local cards = sgs.QList2Table(self.player:getHandcards())
    if self:getCardsNum("Slash") == 0 then return false end
    for _, enemy in sgs.qlist(self.enemies) do
        if enemy:getHandcardNum() <= 4 and not enemy:isRemoved() and not (enemy:hasShownSkill("gongqing") and 
        self:getAttackRange() < 3) and not enemy:hasArmorEffect("SilverLion") then
            if enemy:hasShownSkill("wushuang") and self:getCardsNum("Slash") < 2 then
                continue
            end
            return sgs.Card_Parse("#jiexiechanCard:.:&jiexiechan")
        end
    end
    return false
end

sgs.ai_skill_use_func["#jiexiechanCard"] = function(card, use, self)
    use.card = card
    for _, enemy in sgs.qlist(self.enemies) do
        if enemy:getHandcardNum() <= 3 and not enemy:isKongcheng() and not enemy:isRemoved() and not (enemy:hasShownSkill("gongqing") 
        and self:getAttackRange() < 3) and not enemy:hasArmorEffect("SilverLion") and not enemy:hasShownSkill("buqu") then
            if (enemy:hasShownSkill("wusheng") and enemy:getHandcardNum() == 1) or (enemy:hasShownSkill("wushuang") and 
            self:getCardsNum("Slash") < 2) then
                continue
            end
            if use.to then
                use.to:append(enemy)
            end
            break
        end
    end
end

sgs.ai_use_priority.jiexiechanCard = 4.2

--甘宁
sgs.ai_skill_invoke.jiefenwei = function(self, data)
    local use = data:toCardUse()
    assert(use)
    local card = use.card
    local tos = sgs.QList2Table(use.to)
    if not use or not card or not use.from then return false end
    local jiefenwei_value = 0
	local evaluate_value = 0
    local result = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if sgs.isAnjiang(p) then
            evaluate_value = evaluate_value + 1
		elseif self.player:isFriendWith(p) then
			jiefenwei_value = jiefenwei_value + 1
		end
	end
    if use and card:isKindOf("IronChain") then return false end
    if evaluate_value >= 3 then --暗将较多，局势明朗再发动
        return false
    elseif jiefenwei_value >= 3 then --队友至少3名时
        if card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
            if self.player:isRemoved() then return false end
            for _, p in pairs(tos) do
                if (self:isFriendWith(p) or self.player:isFriendWith(p)) and not p:isRemoved() then
                    table.insert(result, p)
                end
            end
            if #result == 1 then table.remove(result, 1) end
        elseif card:isKindOf("FightTogether") and use.to:contains(self.player) then
            for _, p in pairs(tos) do
                if (self:isFriendWith(p) or self.player:isFriendWith(p)) and not p:isChained() then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("Duel") and use.from:hasSkill("luoyi|wushuang|wushuang_lvlingqi") then
            for _, p in pairs(tos) do
                if (self:isFriendWith(p) or self.player:isFriendWith(p)) and self:isWeak(p) then
                    table.insert(result, p)
                end
            end
        elseif (card:isKindOf("AwaitExhausted") and #self.enemies >= 3 and use.to:contains(self.enemies[1])) or
        (card:isKindOf("BurningCamps") and self.player:isFriendWith(tos[1])) then
            for _, p in pairs(tos) do
                table.insert(result, p)
            end
        elseif card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") then
            local yuanshu = sgs.findPlayerByShownSkillName("weidi")
            for _, p in pairs(tos) do
                if not self:isFriendWith(p) and not self.player:isFriendWith(p) then
                    table.insert(result, p)
                elseif card:isKindOf("AmazingGrace") and yuanshu and yuanshu:getPhase() <= sgs.Player_Play then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("AllianceFeast") then
            if self.player:isFriendWith(use.from) and #tos >= 4 then
                for _, p in pairs(tos) do
                    if not self:isFriendWith(p) and not self.player:isFriendWith(p) then
                        table.insert(result, p)
                    end
                end
            elseif not self.player:isFriendWith(use.from) and #tos >= 3 then
                local yuanshu = sgs.findPlayerByShownSkillName("weidi")
                for _, p in pairs(tos) do
                    if not self:isFriendWith(p) and not self.player:isFriendWith(p) then
                        table.insert(result, p)
                    elseif yuanshu and yuanshu:getPhase() <= sgs.Player_Play then
                        table.insert(result, p)
                    end
                end
            end
        end
    else --队友最多两名时帮助盟军
        if card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
            if self.player:isRemoved() and self:isFriendWith(use.from) then
                return false
            else
                for _, p in pairs(tos) do
                    if self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            end
        elseif card:isKindOf("FightTogether") and use.to:contains(self.player) then
            for _, p in pairs(tos) do
                if self:isFriend(p) then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("Duel") and use.from:hasSkill("luoyi|wushuang|wushuang_lvlingqi") then
            if self:isFriend(use.from) then
                return false
            else
                for _, p in pairs(tos) do
                    if self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            end
        elseif (card:isKindOf("AwaitExhausted") and #self.enemies >= 3 and use.to:contains(self.enemies[1])) or
        (card:isKindOf("BurningCamps") and self:isFriend(tos[1])) then
            for _, p in pairs(tos) do
                table.insert(result, p)
            end
        elseif card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") then
            local yuanshu = sgs.findPlayerByShownSkillName("weidi")
            for _, p in pairs(tos) do
                if card:isKindOf("AmazingGrace") and yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play then
                    table.insert(result, p)
                elseif not self:isFriend(p) then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("AllianceFeast") then
            if self:isFriend(use.from) and #tos >= 4 then
                for _, p in pairs(tos) do
                    if not self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            elseif not self:isFriend(use.from) and #tos >= 3 then
                local yuanshu = sgs.findPlayerByShownSkillName("weidi")
                for _, p in pairs(tos) do
                    if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play then
                        table.insert(result, p)
                    elseif not self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            end
        end
    end
    if #result > 0 then return true end
    return false
end

sgs.ai_skill_playerchosen.jiefenwei = function(self, targets)
    local use = self.player:getTag("jiefenweiUsedata"):toCardUse()
    assert(use)
    local card = use.card
    local tos = sgs.QList2Table(use.to)
    local result = {}
    if not use or not card or not use.from then return false end
    local jiefenwei_value = 0
	local evaluate_value = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if sgs.isAnjiang(p) then
            evaluate_value = evaluate_value + 1
		elseif self.player:isFriendWith(p) then
			jiefenwei_value = jiefenwei_value + 1
			--if self:isWeak(p) then jiefenwei_value = jiefenwei_value + 1 end
		end
	end
    if use and card:isKindOf("IronChain") then return false end
    if evaluate_value >= 3 then --暗将较多，局势明朗再发动
        return false
    elseif jiefenwei_value >= 3 then --队友至少3名时
        if card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
            if self.player:isRemoved() then return false end
            for _, p in pairs(tos) do
                if (self:isFriendWith(p) or self.player:isFriendWith(p)) and not p:isRemoved() then
                    table.insert(result, p)
                end
            end
            if #result == 1 then table.remove(result, 1) end
        elseif card:isKindOf("FightTogether") and use.to:contains(self.player) then
            for _, p in pairs(tos) do
                if (self:isFriendWith(p) or self.player:isFriendWith(p)) and not p:isChained() then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("Duel") and use.from:hasSkill("luoyi|wushuang|wushuang_lvlingqi") then
            for _, p in pairs(tos) do
                if (self:isFriendWith(p) or self.player:isFriendWith(p)) and self:isWeak(p) then
                    table.insert(result, p)
                end
            end
        elseif (card:isKindOf("AwaitExhausted") and #self.enemies >= 3 and use.to:contains(self.enemies[1])) or
        (card:isKindOf("BurningCamps") and self.player:isFriendWith(tos[1])) then
            for _, p in pairs(tos) do
                table.insert(result, p)
            end
        elseif card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") then
            local yuanshu = sgs.findPlayerByShownSkillName("weidi")
            for _, p in pairs(tos) do
                if not self:isFriendWith(p) and not self.player:isFriendWith(p) then
                    table.insert(result, p)
                elseif card:isKindOf("AmazingGrace") and yuanshu and yuanshu:getPhase() <= sgs.Player_Play then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("AllianceFeast") then
            if self.player:isFriendWith(use.from) and #tos >= 4 then
                for _, p in pairs(tos) do
                    if not self:isFriendWith(p) and not self.player:isFriendWith(p) then
                        table.insert(result, p)
                    end
                end
            elseif not self.player:isFriendWith(use.from) and #tos >= 3 then
                local yuanshu = sgs.findPlayerByShownSkillName("weidi")
                for _, p in pairs(tos) do
                    if not self:isFriendWith(p) and not self.player:isFriendWith(p) then
                        table.insert(result, p)
                    elseif yuanshu and yuanshu:getPhase() <= sgs.Player_Play then
                        table.insert(result, p)
                    end
                end
            end
        end
    else --队友最多两名时帮助盟军
        if card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
            if self.player:isRemoved() and self:isFriendWith(use.from) then
                return false
            else
                for _, p in pairs(tos) do
                    if self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            end
        elseif card:isKindOf("FightTogether") and use.to:contains(self.player) then
            for _, p in pairs(tos) do
                if self:isFriend(p) then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("Duel") and use.from:hasSkill("luoyi|wushuang|wushuang_lvlingqi") then
            if self:isFriend(use.from) then
                return false
            else
                for _, p in pairs(tos) do
                    if self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            end
        elseif (card:isKindOf("AwaitExhausted") and #self.enemies >= 3 and use.to:contains(self.enemies[1])) or
        (card:isKindOf("BurningCamps") and self:isFriend(tos[1])) then
            for _, p in pairs(tos) do
                table.insert(result, p)
            end
        elseif card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") then
            local yuanshu = sgs.findPlayerByShownSkillName("weidi")
            for _, p in pairs(tos) do
                if card:isKindOf("AmazingGrace") and yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play then
                    table.insert(result, p)
                elseif not self:isFriend(p) then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("AllianceFeast") then
            if self:isFriend(use.from) and #tos >= 4 then
                for _, p in pairs(tos) do
                    if not self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            elseif not self:isFriend(use.from) and #tos >= 3 then
                local yuanshu = sgs.findPlayerByShownSkillName("weidi")
                for _, p in pairs(tos) do
                    if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play then
                        table.insert(result, p)
                    elseif not self:isFriend(p) then
                        table.insert(result, p)
                    end
                end
            end
        end
    end
    return result
end