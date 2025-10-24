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

sgs.ai_use_priority.jiejianglveCard = 8.2

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
            if p:getTreasure() or p:getArmor() or p:getOffensiveHorse() then
                if p:getArmor() and p:getEquips():length() == 1 then
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
            local maybeResult1 = {}
            local maybeResult2 = {}
            local friendsByAction = sgs.SPlayerList()
            local room = self.player:getRoom()
            friendsByAction = room:getAlivePlayers()
            room:sortByActionOrder(friendsByAction)
            for _, p in sgs.qlist(friendsByAction) do
                if p:objectName() ~= self.player:objectName() and self.player:isFriendWith(p) and p:getHandcardNum() >= 3 then
                    if not p:getCards("j"):isEmpty() then
                        table.insert(maybeResult1, p)
                    elseif p:hasSkill("lirang") then
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
	if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play and not 
    yuanshu:hasUsed("WeidiCard") then return false end
    return true
end

sgs.ai_use_priority.jiejingheCard = 8.4

--祖茂
sgs.ai_skill_invoke.jieyinbing = function(self, data)
    if self.player:hasSkill("huashen") then return false end
	return true
end
sgs.ai_skill_playerchosen.jieyinbing = function(self, targets)
    local junsun = sgs.findPlayerByShownSkillName("jubao")
    if junsun and junsun:isAlive() and self.player:isFriendWith(junsun) then
        return junsun
    end
    for _, p in sgs.qlist(targets) do
        if self.player:isFriendWith(p) then
            if p:hasSkills("diancai|jieyicheng|haoshi|zhukou|jutian|jieyin|guose") then
                if not p:hasSkills("buqu|tianxiang") then
                    return p
                end
            end
        end
    end
    for _, p in sgs.qlist(targets) do
        if p:objectName() == self.player:objectName() then return p end
    end
    return nil
end

--徐晃
sgs.ai_skill_invoke.jiejiezi = function(self, data)
    if self.player:hasShownSkill("jiejiezi") then return true end
	local yuanshu = sgs.findPlayerByShownSkillName("weidi")
	if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play and not yuanshu:hasUsed("WeidiCard")
    then return false end
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
	if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play and not yuanshu:hasUsed("WeidiCard")
    then return false end
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
			if card:isKindOf("Slash") then
                if self.player:hasFlag("luamibeiNoCommand") and card:getTag("luamibeiRecord") and 
                card:getTag("luamibeiRecord"):toInt() == 1 then
                    continue
                end
                table.insert(unpreferedCards, card:getEffectiveId()) 
            end
		end
		--table.remove(unpreferedCards, 1)
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
                elseif card:isKindOf("AmazingGrace") and yuanshu and yuanshu:getPhase() <= sgs.Player_Play and not
                yuanshu:hasUsed("WeidiCard") then
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
                    elseif yuanshu and yuanshu:getPhase() <= sgs.Player_Play and not yuanshu:hasUsed("WeidiCard") then
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
                if card:isKindOf("AmazingGrace") and yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play 
                and not yuanshu:hasUsed("WeidiCard") then
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
                    if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play 
                    and not yuanshu:hasUsed("WeidiCard") then
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
                elseif card:isKindOf("AmazingGrace") and yuanshu and yuanshu:getPhase() <= sgs.Player_Play and not 
                yuanshu:hasUsed("WeidiCard") then
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
                    elseif yuanshu and yuanshu:getPhase() <= sgs.Player_Play and not yuanshu:hasUsed("WeidiCard") then
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
                if card:isKindOf("AmazingGrace") and yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play 
                and not yuanshu:hasUsed("WeidiCard") then
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
                    if yuanshu and self:isEnemy(yuanshu) and yuanshu:getPhase() <= sgs.Player_Play and not 
                    yuanshu:hasUsed("WeidiCard") then
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
        for _, p in sgs.qlist(targets) do
            if self:needToThrowArmor(p) then
                self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                return p
            end
        end
        if self.player:hasSkills(sgs.lose_equip_skill) and self.player:getCards("e"):length() == 0 then
            for _, p in sgs.qlist(targets) do
                if p:objectName() == self.player:objectName() then
                    continue
                end
                for _, hcard in sgs.qlist(p:getCards("e")) do
                    if hcard:objectName() == "PeaceSpell" and p:getHp() == 1 then
                        self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                        return p
                    elseif hcard:objectName() == "SilverLion" and p:getLostHp() >= 1 then
                        self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                        return p
                    elseif hcard:objectName() == "Breastplate" and self.player:getHp() <= 2 and p:getHp() > 1 then
                        self.room:setPlayerFlag(self.player, "jiediaodu_takeEquip")
                        return p
                    end
                end
            end
            for _, p in sgs.qlist(targets) do
                if p:objectName() == self.player:objectName() then
                    continue
                end
                if not p:getEquips():isEmpty() then
                    return p
                end
            end
        end
        if self.player:getEquips():length() == 1 and self.player:hasTreasure("WoodenOx") and 
        self.player:getPile("wooden_ox"):length() > 0 then
            return {}
        end
        return self.room:getCurrent()
    elseif self.player:hasFlag("jiediaodu_takeEquip") then
        local diaodu_card
        if self.diaodu_id then
            diaodu_card = sgs.Sanguosha:getCard(self.diaodu_id)
        end
        for _,p in sgs.qlist(targets) do
            if p:hasSkills(sgs.lose_equip_skill) and self.player:isFriendWith(p) and not self:willSkipPlayPhase(p) then
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
            elseif hcard:objectName() == "Breastplate" and self.player:getHp() <= 2 and who:getHp() > 1 then
                self.diaodu_id = hcard:getEffectiveId()
                return self.diaodu_id
            elseif hcard:isKindOf("OffensiveHorse") or hcard:isKindOf("DefensiveHorse") or hcard:isKindOf("SixDragons") then
                self.diaodu_id = hcard:getEffectiveId()
                return self.diaodu_id
            elseif hcard:objectName() == "WoodenOx" and self.player:getPile("wooden_ox"):length() < 1 then
                self.diaodu_id = hcard:getEffectiveId()
                return self.diaodu_id
            elseif hcard:objectName() == "LuminousPearl" then
                self.diaodu_id = hcard:getEffectiveId()
                return self.diaodu_id
            elseif not hcard:isKindOf("Armor") and not hcard:isKindOf("Treasure") then
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
sgs.ai_skill_invoke.jiehengjiang = function(self, data)
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

--王基
sgs.ai_skill_invoke.jinqu = function(self, data)
    local handcardNum = self.player:getHandcardNum()
    local x = self.player:getMark("#qizhi-turn")
    local isJinqu = false
    if x == 1 then
        if handcardNum == 0 and not self.needKongcheng() and not self.player:getMark("##mingfa") then
            isJinqu = true
        end
    elseif x >= 2 then
        if x >= handcardNum then
            if handcardNum == 0 and self.needKongcheng() then
                isJinqu = false
            else
                isJinqu = true
            end
        else
            isJinqu = false
        end
    end
    if isJinqu then
        return true
    else
        return false
    end
end
sgs.ai_skill_playerchosen.jieqizhi = function(self, targets)
    targets = sgs.QList2Table(targets)
    local maybeResult1 = {}
    for _, p in pairs(targets) do
        if p:objectName() == self.player:objectName() and not self.player:isNude() then
            return p
        end
        if p:getTreasure() and not self.player:isFriendWith(p) and not p:hasSkills(sgs.lose_equip_skill) then
            table.insert(maybeResult1, p)
        elseif p:getArmor() and not self.player:isFriendWith(p) and not p:hasSkills(sgs.lose_equip_skill) then
            if p:getArmor():objectName() == "PeaceSpell" and p:getHp() <= 1 then continue end
            table.insert(maybeResult1, p)
        elseif p:getOffensiveHorse() and not self.player:isFriendWith(p) and not p:hasSkills(sgs.lose_equip_skill) then
            table.insert(maybeResult1, p)
        end
    end
    if #maybeResult1 > 0 then
        return maybeResult1[1]
    end
    return ""
end
sgs.ai_skill_cardchosen.jieqizhi = function(self, who, flags, method, disable_list)
    if who:objectName() == self.player:objectName() then
        local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        self:sortByUseValue(cards)
        return cards[1]
    end
    if who:getTreasure() and not self.player:isFriendWith(who) and not who:hasSkills(sgs.lose_equip_skill) then
        return who:getTreasure():getId()
    elseif who:getArmor() and not self.player:isFriendWith(who) and not who:hasSkills(sgs.lose_equip_skill) then
        if who:getArmor():objectName() ~= "PeaceSpell" or (who:getArmor():objectName() == "PeaceSpell" and who:getHp() > 1) then 
            return who:getArmor():getId() 
        end
    elseif who:getOffensiveHorse() and not self.player:isFriendWith(who) and not who:hasSkills(sgs.lose_equip_skill) then
        return who:getOffensiveHorse():getId()
    end
    return self:askForCardChosen(who, flags, "jieqizhi", method, disable_list)
end

--颜良＆文丑
sgs.ai_skill_invoke.jieshuangxiong = function(self, data)
	if self.player:isSkipped(sgs.Player_Play) or (self.player:getHp() < 2 and not (self:getCardsNum("Slash") > 1 and self.player:getHandcardNum() >= 3)) or #self.enemies == 0 then
		return false
	end
	if self.player:hasSkill("luanji") then
		local dummy_use = { isDummy = true }
		local archeryattack = sgs.cloneCard("archery_attack")
		self:useTrickCard(archeryattack, dummy_use)
		if self.player:getHandcardNum() >= 5 and dummy_use.card then
			return false
		end
	end
	if not self:willShowForAttack() and self.player:getHandcardNum() < 5 then return false end

	local duel = sgs.cloneCard("duel")

	local dummy_use = { isDummy = true }
	self:useTrickCard(duel, dummy_use)
	
	if (self.player:getHandcardNum() >= 3 and dummy_use.card) and not self.player:isCardLimited(duel, sgs.Card_MethodUse) then
		return true
	end
	return false
end

sgs.ai_skill_askforag.jieshuangxiong = function(self, card_ids)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    local black = 0
    local red = 0
    for _, card in pairs(cards) do
        --if sgs.Sanguosha:getCard(card):isBlack() then
        if card:isBlack() then
            black = black + 1
        else
            red = red + 1
        end
    end
    local card1 = sgs.Sanguosha:getCard(card_ids[1])
    local card2 = sgs.Sanguosha:getCard(card_ids[2])
    if black >= red then
        if card1:isRed() then
            return card1:getId()
        elseif card2:isRed() then
            return card2:getId()
        else
            return card1:getId()
        end
    else
        if card1:isBlack() then
            return card1:getId()
        elseif card2:isBlack() then
            return card2:getId()
        else
            return card1:getId()
        end
    end
end

sgs.ai_cardneed.jieshuangxiong = function(to, card, self)
	return not self:willSkipDrawPhase(to)
end

sgs.ai_view_as.jieshuangxiong = function(card, player, card_place)
    local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
    if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
        if not player:hasFlag("jieshuangxiong_Black") and not player:hasFlag("jieshuangxiong_Red") then return nil end
        local black_mark = player:hasFlag("jieshuangxiong_Red")
        local red_mark = player:hasFlag("jieshuangxiong_Black")

        local cards = {}
        for _, id in sgs.qlist(player:getHandPile()) do
            table.insert(cards, sgs.Sanguosha:getCard(id))
        end
        --self:sortByUseValue(cards, true)

        local c
        for _, acard in ipairs(cards) do
            if (acard:isRed() and red_mark) or (acard:isBlack() and black_mark) then
                c = acard
                break
            end
        end
        if not c then return nil end
        local suit = c:getSuitString()
        local number = c:getNumberString()
        local card_id = c:getEffectiveId()
        return ("duel:jieshuangxiong[%s:%s]=%d&s"):format(suit, number, card_id, "&jieshuangxiong")
    end
end

local jieshuangxiong_skill = {}
jieshuangxiong_skill.name = "jieshuangxiongVS"
table.insert(sgs.ai_skills, jieshuangxiong_skill)
jieshuangxiong_skill.getTurnUseCard = function(self)
	if not self.player:hasFlag("jieshuangxiong_Black") and not self.player:hasFlag("jieshuangxiong_Red") then return nil end
	local black_mark = self.player:hasFlag("jieshuangxiong_Red")
	local red_mark = self.player:hasFlag("jieshuangxiong_Black")

	local cards = {}
	for _, c in sgs.qlist(self.player:getCard("h")) do
		table.insert(cards, c)
	end
	self:sortByUseValue(cards, true)

	local card
	for _, acard in ipairs(cards) do
		if (acard:isRed() and red_mark) or (acard:isBlack() and black_mark) then
			card = acard
			break
		end
	end
    if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:jieshuangxiong[%s:%s]=%d&s"):format(suit, number, card_id, "&jieshuangxiong")
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

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
    targets = sgs.QList2Table(targets)
    for _, enemy in pairs(targets) do
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
    targets = sgs.QList2Table(targets)
    if self.player:getMark("luazongxuan_discard") > 0 then
        self:sort(friends, "hp")
        for _, p in pairs(targets) do
            if self.player:isFriendWith(p) then
                table.insert(friends, p)
                break
            end
        end
    else
        local friendsByAction = sgs.SPlayerList()
        local room = self.player:getRoom()
        friendsByAction = room:getAlivePlayers()
        room:sortByActionOrder(friendsByAction)
        for _, p in sgs.qlist(friendsByAction) do
            if self.player:isFriendWith(p) and not (self.player:objectName() == p:objectName() and self.player:getHp() > 2) then
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
    if not self.player:hasShownAllGenerals() or not sgs.Analeptic_IsAvailable(self.player) then return false end
    if self:getCardsNum("Slash") == 0 then return false end
    local str = "analeptic:luajiushi[no_suit:0]=.&luajiushi"
    assert(sgs.Card_Parse(str))
    return sgs.Card_Parse(str)
end
sgs.ai_use_priority.luajiushiCard = 6

sgs.ai_cardsview.luajiushi = function(self, class_name, player)
	if class_name == "Analeptic" then
		if player:hasShownSkill("luajiushi") and player:hasShownAllGenerals() and sgs.Analeptic_IsAvailable(player) then
			return ("analeptic:luajiushi[no_suit:0]=.&luajiushi")
		end
	end
end

--王凌
sgs.ai_skill_invoke.luamibei = function(self, data)
	return true
end
sgs.ai_skill_playerchosen.luamibei = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self.player:isFriendWith(p) then
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
            return p
        end
    end
    return targets[1]
end
sgs.ai_skill_choice["startcommand_luamibei"] = function(self, choices)
    Global_room:writeToConsole(choices)
    choices = choices:split("+")
    local commands_toEnemy = {"command2", "command3", "command6", "command4", "command1", "command5"}--索引大小代表优先级，注意不是原顺序
    local commands_toFriend = {"command5", "command4", "command3", "command6", "command2", "command1"}
    local current = self.room:getCurrent()
    if self.player:isFriendWith(current) or self:isFriend(current) then
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
        if self.player:hasSkill("jushou") and self.player:getPhase() <= sgs.Player_Finish and getKingdoms() > 2 then
            return "yes"
        end
    end
    if index == 6 and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 then
        return "yes"
    end
    return "no"
end
sgs.ai_skill_playerchosen["command_luamibei"] = sgs.ai_skill_playerchosen.damage
sgs.ai_cardshow.luamibei = function(self, requestor)
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isKindOf("Slash") or c:isKindOf("SavageAssault") or c:isKindOf("ArcheryAttack") then
            return c:getEffectiveId()
        elseif c:isKindOf("BurningCamps") and not self.player:isFriendWith(self.player:getNextAlive()) then
            return c:getEffectiveId()
        elseif c:isKindOf("Duel") then
            return c:getEffectiveId()
        elseif c:isKindOf("AwaitExhausted") then
            return c:getEffectiveId()
        elseif c:isKindOf("Snatch") or c:isKindOf("Dismantlement") then
            return c:getEffectiveId()
        elseif c:isKindOf("Analeptic") then
            return c:getEffectiveId()
        end
    end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if not c:isKindOf("IronChain") and not c:isKindOf("FightTogether") then
            return c:getEffectiveId()
        end
    end
    return self:askForCardShow("luamibei")
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
        elseif current:hasSkills("lijian|guowu") then
            return "luaxuyuan_play"
        end
    end
    return "luaxuyuan_draw"
end

sgs.ai_skill_invoke.luashibei = function(self, data)
    local damage = data:toDamage()
    local from = damage.from
    local equipcards_from = from:getEquips()
    local equipcards_self = self.player:getCards("he")
    local hasHorse_self, hasHorse_from = false, false
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
    local from = data:toPlayer()
    local equipcards_from = from:getEquips()
    local equipcards_self = self.player:getCards("he")
    local hasHorse_self = false
    local hasHorse_from = false
    for _, card in sgs.qlist(equipcards_self) do
        if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")  or card:isKindOf("SixDragons") then
            hasHorse_self = true
            self.luashibeiCard = card:getEffectiveId()
            break
        end
    end
    for _, card in sgs.qlist(equipcards_from) do
        if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")  or card:isKindOf("SixDragons") then
            hasHorse_from = true
            self.luashibeiCard = card:getEffectiveId()
            break
        end
    end
    if self.player:getHp() == 1 and hasHorse_self then
        return "luashibei_discard"
    elseif hasHorse_from and not from:hasSkills(sgs.lose_equip_skill) then
        return "luashibei_get"
    elseif hasHorse_self then
        return "luashibei_discard"
    end
    return ""
end
sgs.ai_skill_askforag.luashibei = function(self, card_ids)
    if self.luashibeiCard > 0 then
        return self.luashibeiCard
    end
	return card_ids[1]
end

--皇甫嵩
local luafenyue_skill = {}
luafenyue_skill.name = "luafenyue"
table.insert(sgs.ai_skills, luafenyue_skill)
luafenyue_skill.getTurnUseCard = function(self, inclusive)
    local x = getKingdoms(self.player, false)
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
    local pd = data:toPlayer()
    if pd then
        if pd:getCards("h"):length() <= 2 then
            if pd:getMark("##boyan") <= 0 then
                local jiangwaifeiyi = sgs.findPlayerByShownSkillName("shoucheng")
                if jiangwaifeiyi and pd:isFriendWith(jiangwaifeiyi) then
                    return "luafenyue_boyan"
                end
                return "luafenyue_slash"
            end
        else
            if pd:getMark("##boyan") <= 0 then
                return "luafenyue_boyan"
            end
        end
        return "luafenyue_slash"
    end
    return "luafenyue_slash"
end
sgs.ai_use_priority.luafenyueCard = 8.2

--吴班
sgs.ai_skill_invoke.luajintao = function(self, data)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sort(self.enemies, "hp")
    for _, enemy in pairs(self.enemies) do
        if self.player:distanceTo(enemy) > 0 and #cards >= self.player:distanceTo(enemy) then
            if enemy:getArmor() and enemy:getArmor():objectName() == "Vine" then
                if self.player:getWeapon() and (self.player:getWeapon():objectName() == "Fan" or 
                self.player:getWeapon():objectName() == "QinggangSword") then
                    return true
                elseif #self.enemies == 1 then
                    return false
                end
            end
        end
    end
    return true
end
sgs.ai_skill_use["@@luajintaoVS"] = function(self, prompt)
    local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    self:sort(self.enemies, "hp")
    local target, sec_target
    for _, p in ipairs(self.enemies) do
        if self:damageIsEffective(p, nil, self.player) and not self:needDamagedEffects(p, self.player) and
        not self:needToLoseHp(p, self.player) and self.player:distanceTo(p) > 0 and #cards >= self.player:distanceTo(p) then
            if p:getHp() == 1 and self:isWeak(p) then
                target = p
                break
            end
            if p:getHp() == 2 and self:isWeak(p) then
                sec_target = p
                break
            end
        end
    end
    if not target then
        if sec_target then
            local jintaoCard = {}
            for i = 1, self.player:distanceTo(sec_target) do
                table.insert(jintaoCard, cards[i]:getId())
            end
            return "#luajintaoCard:" .. table.concat(jintaoCard, "+") .. ":&luajintao->" .. sec_target:objectName()
        end
        for _, p in ipairs(self.enemies) do
            if self:damageIsEffective(p, nil, self.player) and not self:needDamagedEffects(p, self.player) and
            not self:needToLoseHp(p, self.player) and self.player:distanceTo(p) > 0 and #cards >= self.player:distanceTo(p) then
                local jintaoCard = {}
                for i = 1, self.player:distanceTo(p) do
                    table.insert(jintaoCard, cards[i]:getId())
                end
                return "#luajintaoCard:" .. table.concat(jintaoCard, "+") .. ":&luajintao->" .. p:objectName()
            end
        end
    else
        local jintaoCard = {}
        for i = 1, self.player:distanceTo(target) do
            table.insert(jintaoCard, cards[i]:getId())
        end
        return "#luajintaoCard:" .. table.concat(jintaoCard, "+") .. ":&luajintao->" .. target:objectName()
    end
end

--陈宫
sgs.ai_skill_invoke.luachengxu = function(self, data)
    --Global_room:writeToConsole("开始乘虚")
    if self.player:hasFlag("luachengxu2slash") then
        local target = self.player:getTag("luachengxu2slash"):toPlayer()
        if not self:isFriend(target) and self:damageIsEffective(target, nil, self.player) then
            local canliuli = false
            for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if p:getMark("@companion") > 0 and p:isFriendWith(target) then
                    return false
                end
                if target:hasSkill("liuli") and self:canLiuli(target, p) and self.player:isFriendWith(p) then
                    canliuli = true
                end
            end
            if canliuli then return false end
            if target:hasShownSkill("buqu") and target:getPile("scars"):length() <= 4 then 
                if self.player:hasSkill("mingshi") and not target:hasShownAllGenerals() then
                    return true
                end
                if self.player:hasArmorEffect("Vine") then
                    if target:getWeapon() and (target:getWeapon():objectName() == "Fan" or 
                    target:getWeapon():objectName() == "QinggangSword") then
                        return false
                    else
                        return true
                    end
                end
                return false 
            end
            if target:hasArmorEffect("Vine") then
                if self.player:getWeapon() and (self.player:getWeapon():objectName() == "Fan" or 
                self.player:getWeapon():objectName() == "QinggangSword") then
                    return true
                else
                    return false
                end
            end
            return true
        end
    elseif self.player:hasFlag("luachengxu2discard") then
        local target = self.player:getTag("luachengxu2discard"):toPlayer()
        local jiangwaifeiyi = sgs.findPlayerByShownSkillName("shoucheng")
        if not self:isFriend(target) then
            if target:getMark("@firstshow") > 0 and target:getPhase() <= sgs.Player_Play then
                return false
            elseif jiangwaifeiyi and target:isFriendWith(jiangwaifeiyi) and target:getPhase() == sgs.Player_NotActive then
                if (target:getArmor() or target:getTreasure() or target:getOffensiveHorse()) and not 
                target:hasSkills(sgs.lose_equip_skill) then
                    return true
                else
                    return false
                end
            else
                return true
            end
        end
    end
    return false
end
sgs.ai_skill_choice.luachengxu = function(self, choices, data)
    local target = data:toPlayer()
    if self.player:isFriendWith(target) or self.player:willBeFriendWith(target) then return "no" end
	return "yes"
end
sgs.ai_skill_invoke.luazhichi = function(self, data)
    return true
end
sgs.ai_skill_cardchosen.luachengxu = sgs.ai_skill_cardchosen.jieqizhi