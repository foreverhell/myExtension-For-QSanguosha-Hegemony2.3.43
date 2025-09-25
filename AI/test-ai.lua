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
    if self.player:getMark("@strategy") < 1 then return end
    return sgs.Card_Parse("#jiejianglveCard:.:&jiejianglve")
end

sgs.ai_skill_use_func["#jiejianglveCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_priority.jiejianglveCard = 6.8

sgs.ai_skill_choice["startcommand_jiejianglve"] = function(self, choices)
    Global_room:writeToConsole(choices)
    choices = choices:split("+")
    if table.contains(choices, "command5") then
        local faceup, not_faceup = 0, 0
        for _, friend in ipairs(self.friends_noself) do
        if self:isFriendWith(friend) then
            if friend:faceUp() then
            faceup = faceup + 1
            else
            not_faceup = not_faceup + 1
            end
        end
        if not_faceup > faceup and not_faceup > 1 then
            return "command5"
        end
        end
    end
    local commands = {"command1", "command2", "command4", "command3", "command6", "command5"}--索引大小代表优先级，注意不是原顺序
    local command_value1 = table.indexOf(commands,choices[1])
    local command_value2 = table.indexOf(commands,choices[2])
    local index = math.min(command_value1,command_value2)
    return commands[index]
end

sgs.ai_skill_choice["docommand_jiejianglve"] = function(self, choices, data)
    local source = data:toPlayer()
    local index = self.player:getMark("command_index")
    if self.player:getActualGeneral1():getKingdom() == "careerist" then
        return "yes"
    end
    if index == 4 then
        if self.player:getMark("command4_effect") > 0 then
        return "yes"
        end
        if self.player:hasSkill("xuanhuo") and not source:hasUsed("XuanhuoAttachCard") and source:getHandcardNum() > 5 then
        return "no"
        end
    end
    if index == 5 then
        if not self.player:faceUp() then
        return "yes"
        end
        return "no"
    end
    if index == 6 then
        if (self.player:getEquips():length() < 4
        and self.player:getHandcardNum() <= (self.player:hasSkills("xuanhuoattach|paoxiao") and 5 or 4))
        or (self:isWeak() and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0) then
        return "yes"
        end
        return "no"
    end
    return "yes"
end

sgs.ai_skill_playerchosen["command_jiejianglve"] = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_choice["jiejianglve"] = function(self, choices, data)--ai势力召唤
    choices = choices:split("+")
    if table.contains(choices,"show_head_general") and (self.player:inHeadSkills("jianxiong") or self.player:inHeadSkills("rende")
        or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("guidao"))--君主替换
        and sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1  then
        return "show_deputy_general"
    end
    if table.contains(choices,"show_both_generals") then
        local wuhu_show_head, wuhu_show_deputy = false,false
        local xuanhuo_priority = {"paoxiao", "tieqi", "kuanggu", "liegong", "wusheng", "longdan"}
        for _, skill in ipairs(xuanhuo_priority) do--有顺序优先度
        if self.player:hasSkill(skill) then
            if self.player:inHeadSkills(skill) then
            wuhu_show_deputy = true
            break
            else
            wuhu_show_head = true
            break
            end
        end
        end
        if wuhu_show_deputy then
        return "show_deputy_general"
        end
        if wuhu_show_head then
        return "show_head_general"
        end
        return "show_both_generals"
    end
    if table.contains(choices,"show_deputy_general") then
        return "show_deputy_general"
    end
    if table.contains(choices,"show_head_general") then
        return "show_head_general"
    end
    return choices[1]
end

sgs.ai_choicemade_filter.skillChoice["jiejianglve"] = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if not player:hasShownOneGeneral() then
		local choice = promptlist[#promptlist]
		if choice == "cancel" and (player:canShowGeneral("h") or player:canShowGeneral("d")) then
			sgs.updateIntention(player, current, 80)
		end
	end
end

--潘淑
sgs.ai_skill_choice.jiezhiren = function(self, choices, data)
    for _, p in pairs(self.enemies) do
        if p:isFemale() then
            if p:getTreasure() or p:getArmor() then
                if p:getArmor() then
                    local armor = p:getArmor()
                    if armor:objectName() == "PeaceSpell" and p:getHp() <= 1 then
                        continue
                    elseif armor:objectName() == "SilverLion" and p:getLostHp() >= 1 then
                        continue
                    elseif p:hasShownSkill("bazhen") or p:hasShownSkill("taidan") then
                        continue
                    end
                end
                return "discardEquip"
            end
        end
    end
    return "guanxing"
end

sgs.ai_skill_playerchosen.jiezhiren = function(self, targets)
    for _, p in pairs(self.enemies) do
        if p:isFemale() then
            if p:getTreasure() or p:getArmor() then
                return p
            end
        end
    end
    return ""
end

sgs.ai_skill_cardchosen.jiezhiren = function(self, who, flags, method, disable_list)
    local armor = who:getArmor()
    local treasure = who:getTreasure()
    local offHorse = who:getOffensiveHorse()
    if treasure then
        return treasure:getEffectiveId()
    elseif armor then
        return armor:getEffectiveId()
    elseif offHorse then
        return offHorse:getEffectiveId()
    end
    return self:askForCardChosen(who, flags, "jiezhiren", method, disable_list)
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
    --[[for _, p in pairs(self.friends) do
        if p:objectName() == self.player:objectName() and use.to then
            use.to:append(p)
            break
        end
    end]]
end
sgs.ai_skill_playerchosen.jiejingheCard = function(self, targets)
    local skill_list = {"lundao", "guanyue", "yanzheng", "leiji_tianshu", "yinbing", "huoqi", "guizhu", "xianshou"}
    if self.player:getMark("jiejinghe_Acquire") > 0 then
        local skill_number = self.player:getMark("jiejinghe_Acquire")
        if skill_number == 3 then
            local maybeResult1, maybeResult2 = {}
            local friendsByAction = sgs.SPlayerList()
            local room = self.player:getRoom()
            friendsByAction = room:getAlivePlayers()
            --room:sortByActionOrder(friendsByAction)
            for _, p in sgs.qlist(friendsByAction) do
                if p:objectName() ~= self.player:objectName() and self.player:isFriendWith(p) and p:getHandcardNum() >= 3 then
                    if not p:getCards("j"):isEmpty() then
                        table.insert(maybeResult1, p)
                    elseif p:hasShownSkill("lirang") then
                        table.insert(maybeResult1, p)
                    else
                        table.insert(maybeResult2, p)
                    end
                end
            end
            if #maybeResult1 > 0 then
                return maybeResult1[1]
            elseif #maybeResult2 > 0 then
                return maybeResult2[1]
            end
        elseif skill_number == 5 then
            local miheng = sgs.findPlayerByShownSkillName("kuangcai")
            local lvbu = sgs.findPlayerByShownSkillName("wushuang")
            local lvlingqi = sgs.findPlayerByShownSkillName("zhuangrong")
            if miheng and self.player:isFriendWith(miheng) and not self:willSkipPlayPhase(miheng) then
                return miheng
            elseif lvlingqi and self.player:isFriendWith(lvlingqi) and not self:willSkipPlayPhase(lvlingqi) then
                return lvlingqi
            elseif lvbu and self.player:isFriendWith(lvbu) and not self:willSkipPlayPhase(lvbu) then
                return lvbu
            end
        elseif skill_number == 7 then
            local miheng = sgs.findPlayerByShownSkillName("kuangcai")
            local huatuo = sgs.findPlayerByShownSkillName("jijiu")
            local lvlingqi = sgs.findPlayerByShownSkillName("zhuangrong")
            local hetaihou = sgs.findPlayerByShownSkillName("zhendu")
            local yuanshao = sgs.findPlayerByShownSkillName("luanji")
            local beimihu = sgs.findPlayerByShownSkillName("guishu")
            if huatuo and self.player:isFriendWith(huatuo) then
                return huatuo
            elseif miheng and self.player:isFriendWith(miheng) and not self:willSkipPlayPhase(miheng) then
                return miheng
            elseif lvlingqi and self.player:isFriendWith(lvlingqi) and not self:willSkipPlayPhase(lvlingqi) then
                return lvlingqi
            elseif beimihu and self.player:isFriendWith(beimihu) and not self:willSkipPlayPhase(beimihu) then
                return beimihu
            elseif hetaihou and self.player:isFriendWith(hetaihou) then
                return hetaihou
            elseif yuanshao and self.player:isFriendWith(yuanshao) and not self:willSkipPlayPhase(yuanshao) then
                return yuanshao
            end
        end
    end
    for _, p in pairs(self.friends) do
        if self.player:objectName() == p:objectName() then
            return p
        end
    end
    return ""
end
sgs.ai_skill_invoke.guizhu = function(self, data)
    local yuanshu = sgs.findPlayerByShownSkillName("weidi")
	if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play then return false end
    return true
end

sgs.ai_use_priority.jiejingheCard = 8.2

--祖茂
sgs.ai_skill_invoke.jieyinbing = function(self, data)
    if self.player:hasSkill("huashen") then return false end
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
    local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
    if self:getCardsNum("Slash") > 1 then
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then table.insert(unpreferedCards, card:getEffectiveId()) end
		end
		table.remove(unpreferedCards, 1)
        if (#cards - 2) >= self.player:getHp() then 
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
	end
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
    if self.player:getMark("@jiexiechan") < 1 or self.player:getMark("##luoyi") < 1 then return false end
    if self:getCardsNum("Slash") == 0 then return false end
    return sgs.Card_Parse("#jiexiechanCard:.:&jiexiechan")
end

sgs.ai_skill_use_func["#jiexiechanCard"] = function(card, use, self)
    for _, enemy in pairs(self.enemies) do
        if enemy:getHandcardNum() <= 3 and not enemy:isKongcheng() and not enemy:isRemoved() and not (enemy:hasShownSkill("gongqing") 
        and self:getAttackRange() < 3) and not enemy:hasArmorEffect("SilverLion") and not enemy:hasShownSkill("buqu") then
            if (enemy:hasShownSkill("wusheng") and enemy:getHandcardNum() > 1) or (enemy:hasShownSkill("wushuang") and 
            self:getCardsNum("Slash") < 2) then
                continue
            end
            use.card = card
            if use.to then
                use.to:append(enemy)
                break
            end
        end
    end
end

sgs.ai_use_priority.jiexiechanCard = 7.2

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
            if self.player:isRemoved() or self:isFriendWith(use.from) then
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
    local jiefenwei_value = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:isFriendWith(p) then
			jiefenwei_value = jiefenwei_value + 1
		end
	end
    if jiefenwei_value >= 3 then --队友至少3名时
        if card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
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
            for _, p in pairs(tos) do
                if self:isFriend(p) then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("FightTogether") and use.to:contains(self.player) then
            for _, p in pairs(tos) do
                if self:isFriend(p) then
                    table.insert(result, p)
                end
            end
        elseif card:isKindOf("Duel") and use.from:hasSkill("luoyi|wushuang|wushuang_lvlingqi") then
            for _, p in pairs(tos) do
                if self:isFriend(p) then
                    table.insert(result, p)
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

--吕范
sgs.ai_skill_invoke.jiediaoduDrawCard = function(self, data)
	return true
end

sgs.ai_skill_invoke.jiediaodu = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.jiediaodu = function(self, targets)
    if not self.player:hasFlag("jiediaodu_takeEquip") then
        if targets:length() > 0 then
            for _, hcard in sgs.qlist(self.player:getCards("e")) do
                if hcard:objectName() == "PeaceSpell" and self.player:getHp() == 1 then
                    self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                    return self.room:getCurrent()
                elseif hcard:objectName() == "SilverLion" and self.player:getLostHp() >= 1 then
                    self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                    return self.room:getCurrent()
                elseif self.player:hasSkills(sgs.lose_equip_skill) then
                    self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                    return self.room:getCurrent()
                end
            end
            for _, p in sgs.qlist(targets) do
                if p:hasSkills(sgs.lose_equip_skill) then
                    self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                    return p
                end
            end
        end
        for _,p in sgs.qlist(targets) do
            if self:needToThrowArmor(p) then
                self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                return p
            end
        end
        if self.player:getEquips():length() == 1 and self.player:hasTreasure("WoodenOx") and 
        self.player:getPile("wooden_ox"):length() > 0 then
            return {}
        end
        --return {}
        return self.room:getCurrent()
    elseif self.player:hasFlag("jiediaodu_takeEquip") then
        local diaodu_card
        if self.diaodu_id then
            diaodu_card = sgs.Sanguosha:getCard(self.diaodu_id)
        end
        for _,p in sgs.qlist(targets) do
            if p:hasSkills(sgs.lose_equip_skill) and self:isFriend(p) and not self:willSkipPlayPhase(p) then
                return p
            end
        end
        local AssistTarget = self:AssistTarget()
        if AssistTarget and targets:contains(AssistTarget) and not self:willSkipPlayPhase(AssistTarget) and 
        self:isFriendWith(AssistTarget) then
            return AssistTarget
        end
        if diaodu_card then
            if diaodu_card:isKindOf("EquipCard") and self:getSameEquip(diaodu_card) then--重复装备
                for _,p in sgs.qlist(targets) do
                    if self:isFriendWith(p) and not self:willSkipPlayPhase(p) and not self:getSameEquip(diaodu_card, p)
                    and self:playerGetRound(p, self.player) < self.room:alivePlayerCount() / 2 then
                        return p
                    end
                end
            end
            --[[
            local c, friend = self:getCardNeedPlayer({diaodu_card})--这样给装备是否合适？
            if c and friend and self:isFriendWith(friend) and self:isFriendWith(friend) and targets:contains(friend) then
            return friend
            end]]
        end
        return self.room:getCurrent()
    end
    return self.room:getCurrent()
end

sgs.ai_skill_cardchosen.jiediaodu = function(self, who, flags, method, disable_list)
	self.diaodu_id = nil
	if who:objectName() == self.player:objectName() then--指针是可以判定等于的，severplayer类型，但是who是否会是player类型？
		for _, hcard in sgs.qlist(self.player:getCards("e")) do
            if hcard:objectName() == "PeaceSpell" and self.player:getHp() == 1 then
                self.diaodu_id = hcard:getEffectiveId()
				return self.diaodu_id
            elseif hcard:objectName() == "SilverLion" and self.player:getLostHp() >= 1 then
                self.diaodu_id = hcard:getEffectiveId()
				return self.diaodu_id
            end
		end
	end
	self.diaodu_id = self:askForCardChosen(who, flags, "diaodu_snatch", method, disable_list)
	return self.diaodu_id
end

sgs.ai_skill_choice["@jiediaodu_obtainEquip"] = function(self, choices, data)
	return "yes"
end
sgs.ai_skill_invoke.jiediaoduDrawCard = function(self, data)
	return true
end

--[[sgs.ai_skill_choice["@jiediaodu_exchangeToEquip"] = function(self, choices, data)
	return "yes"
end]]

--夏侯惇
sgs.ai_skill_cardchosen.ganglie = sgs.ai_skill_cardchosen.jianchu
sgs.ai_skill_invoke.jieqingjian = function(self, data)
    if #self.friends_noself <= 0 then return false end 
	return true
end
sgs.ai_skill_askforyiji.jieqingjian = sgs.ai_skill_askforyiji.yiji

--臧霸
function sgs.ai_skill_invoke.jiehengjiang(self, data)
	local current = self.room:getCurrent()
	if self:isFriend(current) then
		return false
	else
		return true
	end
end

--祝融
sgs.ai_skill_cardchosen.jielierenPindian = function(self, who, flags, method, disable_list)
    if who:hasSkills(sgs.lose_equip_skill) then
		return self:askForCardChosen(who, "h", "jielieren", method, disable_list)
	end
    if who:getCards("e"):length() >= 1 then
        local use = self.player:getTag("jielieren_cardUsed"):toCardUse()
        if who:getArmor() then
            local armor = who:getArmor()
			if armor:objectName() == "PeaceSpell" and who:getHp() <= 1 then 
                if use.card:isKindOf("Fire_slash") or use.card:isKindOf("Thunder_slash") then
                    return armor:getEffectiveId()
                end
            end
            if armor:objectName() == "Vine" then
                if use.card:isKindOf("Fire_slash") then
                    return self:askForCardChosen(who, flags, "jielieren", method, disable_list)
                else
                    return armor:getEffectiveId()
                end
            end
            if armor:objectName() == "SilverLion" and who:getLostHp() > 0 then
                return self:askForCardChosen(who, flags, "jielieren", method, disable_list)
            end
            return armor:getEffectiveId()
        elseif who:getTreasure() then
            return who:getTreasure():getEffectiveId()
        elseif who:getDefensiveHorse() then
            return who:getDefensiveHorse():getEffectiveId()
        end
    else
        return self:askForCardChosen(who, flags, "jielieren", method, disable_list)
    end
end