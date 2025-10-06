-- 创建扩展包  
testToFix = sgs.Package("testToFix",sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["testToFix"] = "平衡性调整",
}
--建立武将
--魏势力
jiexiahouyuan = sgs.General(testToFix, "xiahouyuan", "wei", 5, true, false, true)
jiexiahouyuan:addCompanion("xiahoudun")
jiexiahoudun = sgs.General(testToFix, "xiahoudun", "wei", 4, true, false, true)
jiexiahoudun:addCompanion("yujin")
jiezangba = sgs.General(testToFix, "zangba", "wei", 4, true, false, true)
jiezhangliao = sgs.General(testToFix, "zhangliao", "wei", 4, true, false, true)
jiezhangliao:addCompanion("zangba")
jiexuchu = sgs.General(testToFix, "xuchu", "wei", 4, true, false, true)
jiexuchu:addCompanion("caocao")
jiexuhuang = sgs.General(testToFix, "xuhuang", "wei", 4, true, false, true)
jiewangji = sgs.General(testToFix, "wangji", "wei", 3, true, false, true)
--蜀势力
jiewangping = sgs.General(testToFix, "wangping", "shu", 4, true, false, true)
jieguanyu = sgs.General(testToFix, "guanyu", "shu", 5, true, false, true)
jieguanyu:addCompanion("liaohua")
jieguanyu:addCompanion("liubei")
jiejiangwanfeiyi = sgs.General(testToFix, "jiangwanfeiyi", "shu", 3, true, false, true)
jiejiangwanfeiyi:addCompanion("zhugeliang")
jiejiangwanfeiyi:addCompanion("wangping")
jiezhugeliang = sgs.General(testToFix, "zhugeliang", "shu", 3, true, false, true)
jiezhugeliang:addCompanion("maliang")
jiezhugeliang:addCompanion("huangyueying")
jiezhurong = sgs.General(testToFix, "zhurong", "shu", 4, false, false, true)
jiezhurong:addCompanion("menghuo")
jiejiangwei = sgs.General(testToFix, "jiangwei", "shu", 4, true, false, true)
jiejiangwei:setDeputyMaxHpAdjustedValue(-1)
jiejiangwei:addCompanion("zhugeliang")
jiejiangwei:addCompanion("xiahouba")

--吴势力
jielvfan = sgs.General(testToFix, "lvfan", "wu", 3, true, false, true)
jieluxun = sgs.General(testToFix, "luxun", "wu", 3, true, false, true)
jieluxun:addCompanion("lukang")
jieluxun:addCompanion("sunhuan")
jiepanshu = sgs.General(testToFix, "jiepanshu", "wu", 3, false)
jiepanshu:addCompanion("sunquan")
jiezumao = sgs.General(testToFix, "zumao", "wu", 4, true, false, true)
jiexusheng = sgs.General(testToFix, "xusheng", "wu", 4, true, false, true)
jieganning = sgs.General(testToFix, "ganning", "wu", 4, true, false, true)
jieganning:addCompanion("lingtong")
jieganning:addCompanion("sufei")
jietaishici = sgs.General(testToFix, "taishici", "wu", 4, true, false, true)
jietaishici:addCompanion("sunce")
jiesunjian = sgs.General(testToFix, "sunjian", "wu", 5, true, false, true)
jiesunjian:addCompanion("zumao")
jiesunjian:addCompanion("wuguotai")

--群势力
jienanhualaoxian = sgs.General(testToFix, "nanhualaoxian", "qun", 3, true, false, true)
jiediaochan = sgs.General(testToFix, "diaochan", "qun", 3, false, false, true)
jiediaochan:addCompanion("lvbu")
jieyanliangwenchou = sgs.General(testToFix, "yanliangwenchou", "qun", 4, true, false, true)
jieyanliangwenchou:addCompanion("yuanshao")
jiezuoci = sgs.General(testToFix, "zuoci", "qun", 3)
jiezuoci:addCompanion("yuji")

--双势力
--[[jiepengyang = sgs.General(testToFix, "pengyang", "shu", 3, true, false, true)
jiepengyang:setSubordinateKingdom("qun")
jiehuangquan = sgs.General(testToFix, "huangquan", "shu", 3, true, false, true)
jiehuangquan:setSubordinateKingdom("wei")]]

local skills = sgs.SkillList()


--[[******************
    建立一些通用内容
]]--******************
--建立空卡

MemptyCard = sgs.CreateSkillCard{
	name = "MemptyCard",
	target_fixed = true,
}
--建立table-qlist函数
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for _, x in ipairs(theTable) do
		result:append(x)
	end
	return result
end

listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end

CardList2Table = function(theqlist)
	local result = {}
	for _, item in sgs.qlist(theqlist) do
		table.insert(result, item:getId())
	end
	return result
end

--建立获取服务器玩家函数
function getServerPlayer(room, name)
	for _, p in sgs.qlist(room:getAllPlayers(true)) do
		if p:objectName() == name then return p end
	end
	return nil
end

function skillTriggerable(player, name)
	return player ~= nil and player:isAlive() and player:hasSkill(name)
end

getKingdoms = function(player, will_show)
	local n = 0
    local kingdom_set = {}
	local allplayers = player:getAliveSiblings()
	local same_kingdom = false
	if will_show and not player:hasShownOneGeneral() then
	    for _, p in sgs.qlist(allplayers) do
	        if player:willBeFriendWith(p) then
		        same_kingdom = true
				break
		    end
	    end
		if not same_kingdom then
	        n = n + 1
	    end
	end
	if not same_kingdom then
	    allplayers:append(player)
	end
	for _, p in sgs.qlist(allplayers) do
		if not p:hasShownOneGeneral() then
			continue
		end
		if p:getRole() == "careerist" then
		    n = n + 1
			continue
		end
		if not table.contains(kingdom_set, p:getKingdom()) then table.insert(kingdom_set, p:getKingdom()) end
	end
	return n + #kingdom_set
end


--[[jieganglie = sgs.CreateTriggerSkill{
	name = "jieganglie",
	events = {sgs.Damaged},
	
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if skillTriggerable(player, self:objectName()) and damage.from and event == sgs.Damaged then 
			return self:objectName()
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			local damage = data:toDamage()
			room:broadcastSkillInvoke("ganglie", player)
			room:doAnimate(1, player:objectName(), damage.from:objectName())
			return true
		end
		return false
	end,
	
	on_effect = function(self, event, room, player, data, skill_owner)
		local judge = sgs.JudgeStruct()
		judge.good = true
		judge.who = skill_owner
		judge.reason = self:objectName()
		room:judge(judge)
		local judge_card = judge.card
		local damage = data:toDamage()
		if judge_card then
			if judge_card:isRed() then 
				local ganglieDamage = sgs.DamageStruct() 
				ganglieDamage.from = judge.who
				ganglieDamage.to = damage.from
				ganglieDamage.damage = 1
				room:damage(ganglieDamage)
			elseif judge_card:isBlack() and not damage.from:isNude() then 
				local card_id = room:askForCardChosen(judge.who, damage.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
				room:throwCard(card_id, damage.from, judge.who)
			end
		end
		return false
	end	
}]]--

jieqingjian = sgs.CreateTriggerSkill{
	name = "jieqingjian",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and player:getPhase() ~= sgs.Player_Draw and not 
		player:hasFlag("jieqingjianUsed") then
			local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move and move.to and move.to:objectName() == player:objectName() then
					local ids = sgs.IntList()
					for _, id in sgs.qlist(move.card_ids) do
						if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
							ids:append(id)
						end
					end
					if ids:isEmpty() then return false end
					return self:objectName()
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		local move_datas = data:toList()
		for _, move_data in sgs.qlist(move_datas) do
			local move = move_data:toMoveOneTime()
			local ids = sgs.IntList()
			for _, id in sgs.qlist(move.card_ids) do
				if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then
					ids:append(id)
				end
			end
			if ids:isEmpty() then return false end
			while room:askForYiji(player, ids, self:objectName(), false, false, true, -1, room:getOtherPlayers(player)) do
				room:setPlayerFlag(player, "jieqingjianUsed")
				if player:isDead() then return false end
			end
		end
		return false
	end
}

--[[jieqingjian = sgs.CreateTriggerSkill{
	name = "jieqingjian",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and player:getPhase() ~= sgs.Player_Draw then
			if event == sgs.CardsMoveOneTime and not player:hasFlag("jieqingjianUsed") then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local now_handcard_ids = CardList2Table(player:getHandcards())
					if #now_handcard_ids <= player:getMark("jieqingjian_hNum") then return false end
					if move.to and move.to:objectName() == player:objectName() then
						return self:objectName()
					end
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		if not player:hasFlag("jieqingjianUsed") then
			local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move.to_place == sgs.Player_PlaceHand and move.to and move.to:objectName() == player:objectName() then
					local qingjianPile_ids = sgs.IntList()
					qingjianPile_ids = move.card_ids
					local beforYijiNum = player:getMark("jieqingjian_hNum")
					while(room:askForYiji(player, qingjianPile_ids, self:objectName(), true, false, true, -1,
					room:getOtherPlayers(player))) do]]
						--[[local moveStruct = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand, 
						sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
						self:objectName(), ""))]]
						--[[for i = 1, qingjianPile_ids:length() do
							if room:getCardPlace(qingjianPile_ids:at(i - 1)) == sgs.Player_PlaceHand then
								--qingjianPile_ids:removeOne(qingjianPile_ids:at(i - 1))
								room:setPlayerFlag(player, "jieqingjianUsed")
							end
						end
						if not player:isAlive() then return false end
					end
					local nowHandcard = CardList2Table(player:getHandcards())
					if #nowHandcard <= 0 then 
						room:setPlayerFlag(player, "jieqingjianUsed") 
					else
						for _, card_id in sgs.qlist(qingjianPile_ids) do
							local hasGive = true
							for i = 1, #nowHandcard do
								if nowHandcard[i]:getId() == card_id then
									hasGive = false
									break
								end
							end
							if hasGive then
								room:setPlayerFlag(player, "jieqingjianUsed")
								return false
							end
						end
					end]]
					--if beforYijiNum > player:getMark("jieqingjian_hNum") then
						--room:setPlayerFlag(player, "jieqingjianUsed")
					--[[elseif not qingjianPile_ids:isEmpty() then
						local moveStruct = sgs.CardsMoveStruct(qingjianPile_ids, player, nil, sgs.Player_PlaceHand, 
						sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
						self:objectName(), ""))
						for i = 1, qingjianPile_ids:length() do
							player:obtainCard(sgs.Sanguosha:getCard(qingjianPile_ids:at(i - 1)), false)
						end]]
					--end
				--[[end
			end
		end
		return false
	end
}

jieqingjian_setHNum = sgs.CreateTriggerSkill{
	name = "#jieqingjian_setHNum",
	events = {sgs.EventPhaseEnd, sgs.Player_Draw, sgs.BeforeCardsMove},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Draw and event == sgs.EventPhaseEnd then
			room:setPlayerMark(player, "jieqingjian_hNum", #CardList2Table(player:getHandcards()))
		elseif skillTriggerable(player, self:objectName()) and player:getPhase() ~= sgs.Player_Draw and event == sgs.BeforeCardsMove then
			room:setPlayerMark(player, "jieqingjian_hNum", #CardList2Table(player:getHandcards()))
		end
		return false
	end,
}]]

jiexiahoudun:addSkill(jieqingjian)
--jiexiahoudun:addSkill(jieqingjian_setHNum)
jiexiahoudun:addSkill("ganglie")
--testToFix:insertRelatedSkills("jieqingjian", "#jieqingjian_setHNum")

sgs.LoadTranslationTable{
	["jiexiahoudun"] = "夏侯惇",
	["jieqingjian"] = "清俭",
	[":jieqingjian"] = "每回合限一次，当你于摸牌阶段外获得手牌后，你可以将其中任意张牌交给任意名其他角色。",
	["$jieqingjian1"] = "福生于清俭，德生于卑退!",
	["$jieqingjian2"] = "钱财，乃身外之物。",
}

--[[jieshesuEquip = sgs.CreateViewAsSkill{
	name = "jieshesuEquip",
	response_pattern = "@@jieshesu_Equip",
	
	view_filter = function(self, selected, to_select)
		if card:getTypeId() == sgs.Card_TypeEquip then return false end
		return #selected == 0 and to_select:isKindOf("EquipCard")
	end,
	
	view_as = function(self, cards)
		if #cards == 1 then
			local skillcard = MemptyCard:clone()
			return skillcard
		end
	end,
}]]--

-- 创建技能 jieshensu
--[[jieshensu = sgs.CreateTriggerSkill{
    name = "jieshensu",
    events = {sgs.EventPhaseChanging}, -- 在两个阶段之间触发技能
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and event ~= sgs.Player_NotActive and event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Judge then --神速1
				return self:objectName()
			elseif change.to == sgs.Player_Play and player:canDiscard(player, "he") then --神速2
				return self:objectName()
			elseif change.to == sgs.Player_Discard then --神速3
				return self:objectName()
			end
		end
		return ""
    end,
	
	on_cost = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:canSlash(p, false) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then 
			if change.to == sgs.Player_Judge then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jieshensu_skipJudgeAndDraw", true, true)
				if target then
					local d = sgs.QVariant()
					d:setValue(target)
					player:setTag("jieshensu_target", d)
					room:broadcastSkillInvoke("shensu", player)
					room:doAnimate(1, player:objectName(), target:objectName())
					return true
				end
			elseif change.to == sgs.Player_Play and player:canDiscard(player, "he") then 
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jieshensu_skipPlay", true, true)
				if target then
					local card_ids = sgs.IntList()  
					-- 将牌堆转换为Lua表
					local handCard = player:getHandcards()
					local equipCard = player:getEquips()  
					for _, card in sgs.qlist(handCard) do  
						if card:isKindOf("EquipCard") then
							-- 如果是装备牌，则添加到card_ids中
							card_ids:append(card:getId())
						end
					end
					for _, card in sgs.qlist(equipCard) do  
						if card:isKindOf("EquipCard") then
							card_ids:append(card:getId())
						end  
					end
					-- 检查牌堆是否为空  
					if card_ids:length() == 0 then  
						return false
					end          
					-- 使用AG界面让玩家选择一张牌  
					room:fillAG(card_ids, player)  
					local card_id = room:askForAG(player, card_ids, true, "jieshensu")  
					room:clearAG(player) 
					if card_id < 0 then return false end
					-- 弃置选中的牌
					room:throwCard(card_id, player, player)
					local d = sgs.QVariant()
					d:setValue(target)
					player:setTag("jieshensu_target", d)
					room:broadcastSkillInvoke("shensu", player)
					room:doAnimate(1, player:objectName(), target:objectName())
					return true
				end
			elseif change.to == sgs.Player_Discard then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jieshensu_skipDiscard", true, true)
				if target then
					local d = sgs.QVariant()
					d:setValue(target)
					player:setTag("jieshensu_target", d)
					room:broadcastSkillInvoke("shensu", player)
					room:doAnimate(1, player:objectName(), target:objectName())
					return true
				end
			end
		end
		return false
	end,
	
	on_effect = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Judge then --神速1
			player:skip(sgs.Player_Judge)
			player:skip(sgs.Player_Draw)
		elseif change.to == sgs.Player_Play then --神速2
			player:skip(sgs.Player_Play)
		elseif change.to == sgs.Player_Discard then --神速3
			player:skip(sgs.Player_Discard)
			room:loseHp(player, 1)
		end
		local target = player:getTag("jieshensu_target"):toPlayer()
		player:removeTag("jieshensu_target")
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("_jieshensu")
		room:useCard(sgs.CardUseStruct(slash, player, target), false)
		return false
	end
    
}]]--

-- 将技能添加到武将
jiexiahouyuan:addSkill("shensu")

--if not sgs.Sanguosha:getSkill("jieshesuEquip") then skills:append(jieshesuEquip) end

-- 加载翻译表
--[[sgs.LoadTranslationTable{
    ["xiahouyuan"] = "夏侯渊",
    ["#xiahouyuan"] = "神射手",
    ["jieshensu"] = "神速",
    [":jieshensu"] = "你可以选择以下任意项：\n1. 跳过判定阶段和摸牌阶段，并视为使用一张无距离限制的【杀】；\n2. 跳过出牌阶段并弃置一张装备牌；\n3. 跳过弃牌阶段并失去一点体力；\n你每执行一项，便视为使用一张无距离限制的【杀】。",
    ["@jieshensu_skipJudgeAndDraw"] = "是否发动“神速”跳过判定和摸牌阶段并对一名目标使用一张【杀】",
    ["@jieshensu_skipPlay"] = "是否发动“神速”跳过出牌阶段并弃置一张装备牌，对一名目标使用一张【杀】（先选目标再弃牌）",
    ["@jieshensu_skipDiscard"] = "是否发动“神速”跳过弃牌阶段并失去一点体力，对一名目标使用一张【杀】",
	["@jieshesu_Equip"] = "“神速”：弃置一张装备牌",
}]]--

jiediaodu = sgs.CreateTriggerSkill{
	name = "jiediaodu",
	events = {sgs.EventPhaseStart},

	can_trigger = function(self, event, room, player)
		if skillTriggerable(player, self:objectName()) then
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then 
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					local card_equip = p:getEquips()
					if p:isFriendWith(player) and card_equip:length() > 0 then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
					return self:objectName()
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			local card_equip = p:getEquips()
			if p:isFriendWith(player) and card_equip:length() > 0 then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jiediaodu_obtainEquip", true, true)
			if target then
				local card_id = room:askForCardChosen(player, target, "e", self:objectName(), false, sgs.Card_MethodGet)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
				room:broadcastSkillInvoke("diaodu", player)
				if player == skill_owner then
					if player:getActualGeneral1Name() == "lvfan" then
						player:showGeneral(true, false, false)
					else
						player:showGeneral(false, true, false)
					end
				end
				local target_to = sgs.SPlayerList() --获取除选择目标的其他角色
				for _, p in sgs.qlist(room:getOtherPlayers(target)) do
					target_to:append(p)
				end
				if not target_to:isEmpty() then
					local target_player = room:askForPlayerChosen(player, target_to, self:objectName(),
					"@jiediaodu_exchangeToEquip", true, true)
					if target_player then
						local card = sgs.Sanguosha:getCard(card_id)
						room:moveCardTo(card, player, target_player, sgs.Player_PlaceHand, reason, false)
						room:doAnimate(1, player:objectName(), target_player:objectName())
					end
				end
			end
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		return false
	end
}

jiediaoduDrawCard = sgs.CreateTriggerSkill{
	name = "#jiediaoduDrawCard",
	events = {sgs.CardUsed},
	frequency = sgs.Skill_Frequent,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and event == sgs.CardUsed and not player:hasFlag("First_use_equipCard") then
			local card_use = data:toCardUse()
			if card_use.card:getTypeId() == sgs.Card_TypeEquip then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName("jiediaodu")
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skill_owner == player then
						return self:objectName(), player:objectName()
					end
					if skillTriggerable(skill_owner, "jiediaodu") and skill_owner:hasShownSkill("jiediaodu") and 
					player:isFriendWith(skill_owner) then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("diaodu", skill_owner)
			room:doAnimate(1, skill_owner:objectName(), player:objectName())
			if player == skill_owner then
				if player:getActualGeneral1Name() == "lvfan" then
					player:showGeneral(true, false, false)
				else
					player:showGeneral(false, true, false)
				end
			end
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
		if not player:hasFlag("First_use_equipCard") then
			player:drawCards(1, "jiediaodu")
			room:setPlayerFlag(player, "First_use_equipCard")
		end
		return false
	end
}

jielvfan:addSkill("diancai")
jielvfan:addSkill(jiediaodu)
jielvfan:addSkill(jiediaoduDrawCard)
testToFix:insertRelatedSkills("jiediaodu", "#jiediaoduDrawCard")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jielvfan"] = "吕范",
    ["jiediaodu"] = "调度",
	[":jiediaodu"] = "每回合首次有与你势力相同的角色使用装备牌时，其可以摸一张牌。出牌阶段开始时，你可以获得一名与你势力相同的角色" ..
	"装备区的一张牌，然后你可以将此牌交给另一名角色。",
	["@jiediaodu_obtainEquip"] = "“是否发动“调度”，获得一名与你相同势力角色装备区的一张牌",
	["@jiediaodu_exchangeToEquip"] = "是否将该装备牌交给另一名角色",
	["#jiediaoduDrawCard"] = "调度",
}

jieduoshi = sgs.CreatePhaseChangeSkill{
	name = "jieduoshi",
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player)
		if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Play then
			return self:objectName()
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("duoshi", player)
			return true
		end
		return false
	end,

	on_phasechange = function(self, player)
		local room = player:getRoom()
		local await = sgs.Sanguosha:cloneCard("await_exhausted", sgs.Card_NoSuit, 0)
		await:setSkillName(self:objectName())
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if player:isFriendWith(p) then
				targets:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(await, player, targets), true)
		return false
	end
}

jieluxun:addSkill(jieduoshi)
jieluxun:addSkill("qianxun")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jieluxun"] = "陆逊",
    ["jieduoshi"] = "度势",
	[":jieduoshi"] = "出牌阶段开始时，你可以视为使用一张【以逸待劳】。",
}

jiehengjiang = sgs.CreateMasochismSkill{
    name = "jiehengjiang",
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            local current = room:getCurrent()
            if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then 
				return false 
			end
            local damage = data:toDamage()
            local trigger_list = {}
            for i = 1, damage.damage, 1 do
                table.insert(trigger_list, self:objectName())
            end
            return table.concat(trigger_list, ",")
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        local current = room:getCurrent()
        if current and player:askForSkillInvoke(self:objectName(), data) then
            room:doAnimate(1, player:objectName(), current:objectName())
            room:broadcastSkillInvoke("hengjiang", player)
            return true
        end
        return false
    end,

    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        local current = room:getCurrent()
        if not current then return false end
		local equipNum = current:getEquips():length()
		if equipNum < 1 then equipNum = 1 end
        room:addPlayerMark(current, "@hengjiang", equipNum)
		return false
    end
}

jiehengjiang_draw = sgs.CreateTriggerSkill{
    name = "#jiehengjiang-draw",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			local current = room:getCurrent()
			if not current then return false end
			if event == sgs.CardsMoveOneTime and current:getPhase() == sgs.Player_Discard then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
						if move.from_places:contains(sgs.Player_PlaceHand) and move.from and move.from:isAlive() 
						and move.from:objectName() == current:objectName() then
							room:setPlayerMark(current, "jieHengjiangDiscarded", 1)
						end
					end
				end
			elseif event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then return false end
				if current:getMark("jieHengjiangDiscarded") > 0 then 
					room:setPlayerMark(current, "@hengjiang", 0)
					room:removePlayerMark(current, "jiehengjiangDiscarded", 1)
					return false
				end
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName("jiehengjiang")
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, "jiehengjiang") and current:getMark("jieHengjiangDiscarded") <= 0 
					and current:getMark("@hengjiang") > 0 then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
        return false
    end,

    on_cost = function(self, event, room, player, data, skill_owner)
		return true
    end,

    on_effect = function(self, event, room, player, data, skill_owner)
		local current = room:getCurrent()
		if current:getMark("@hengjiang") > 0 and current:getMark("jieHengjiangDiscarded") <= 0 then
			room:setPlayerMark(current, "@hengjiang", 0)
			room:removePlayerMark(current, "jiehengjiangDiscarded", 1)
			skill_owner:fillHandCards(skill_owner:getMaxHp())
		end
        return false
    end
}

jiehengjiang_fail = sgs.CreateTriggerSkill{
	name = "#jiehengjiang-fail",
	events = {sgs.EventPhaseChanging},
	priority = -1,
	can_trigger = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if chage.to == sgs.Player_NotActive then
			if player:getMark("@hengjiang") > 0 or player:getMark("jieHengjiangDiscarded") > 0 then
				room:setPlayerMark(p, "@hengjiang", 0)
				room:removePlayerMark(p, "jiehengjiangDiscarded", 1)
			end
		end
		return false
	end
}

jiehengjiang_maxcard = sgs.CreateMaxCardsSkill{
    name = "#jiehengjiang-maxcard",
    extra_func = function(self, target)
        return -target:getMark("@hengjiang")
    end
}

jiezangba:addSkill(jiehengjiang)
jiezangba:addSkill(jiehengjiang_draw)
jiezangba:addSkill(jiehengjiang_fail)
jiezangba:addSkill(jiehengjiang_maxcard)

testToFix:insertRelatedSkills("jiehengjiang", "#jiehengjiang-draw")
testToFix:insertRelatedSkills("jiehengjiang", "#jiehengjiang-maxcard")
testToFix:insertRelatedSkills("jiehengjiang", "#jiehengjiang-fail")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiezangba"] = "臧霸",
    ["jiehengjiang"] = "横江",
	[":jiehengjiang"] = "当你受到1点伤害后，你可以令当前回合角色本回合手牌上限-X（X为其装备区的牌数，且至少为1），"..
	"然后此回合结束时，若其未于本回合弃牌阶段弃置过其手牌，你摸牌至体力上限。",
}

jiejianglveCard = sgs.CreateSkillCard{
	name = "jiejianglveCard",
	skill_name = "jiejianglve",
	target_fixed = true,

	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@strategy")  
    	room:broadcastSkillInvoke("jianglve", source)
		room:doSuperLightbox("wangping", "jianglve")
		local commandIndex = source:startCommand("jiejianglve", source) --注意5为叠置军令，不能回复体力
		local doCommandPlayer = {}
		for _, player in sgs.qlist(room:getOtherPlayers(source)) do
			if player and player:isAlive() then
				if player:isFriendWith(source) or player:willBeFriendWith(source) then
					if not player:hasShownOneGeneral() then
						player:askForGeneralShow("jiejianglve", true, true, true, true)
						if player:hasShownOneGeneral() then
							player:doCommand("jiejianglve", commandIndex, source)
							if player:isAlive() then
								table.insert(doCommandPlayer, player)
							end
						end
					else
						player:doCommand("jiejianglve", commandIndex, source)
						if player:isAlive() then
							table.insert(doCommandPlayer, player)
						end
					end
				end
			end
		end
		table.insert(doCommandPlayer, source)
		for _, p in pairs(doCommandPlayer) do
			if not p:isAlive() then continue end
			p:setMaxHp(p:getMaxHp() + 1)
			room:broadcastProperty(p, "maxhp")
			if p:canRecover() then
				local recover = sgs.RecoverStruct()
				recover.who = p
				recover.recover = 1
				room:recover(p, recover)
			end
		end
		if commandIndex ~= 5 then
			source:drawCards(#doCommandPlayer, "jiejianglve")
		else
			source:drawCards(1, "jiejianglve")
		end
	end
}  

jiejianglve = sgs.CreateZeroCardViewAsSkill{
	name = "jiejianglve",
	frequency = sgs.Skill_Limited,
	limit_mark = "@strategy",
      
    view_as = function(self)
        local card = jiejianglveCard:clone()
        card:setSkillName(self:objectName())
		card:setShowSkill(self:objectName())
        return card
    end,
      
    enabled_at_play = function(self, player)
        return player:getMark("@strategy") > 0
    end
}

jiewangping:addSkill(jiejianglve)

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiewangping"] = "王平",
    ["jiejianglve"] = "将略",
	[":jiejianglve"] = "限定技，出牌阶段，你可选择一个“军令”，与你势力相同的其他角色依次选择是否执行该军令"..
	"（未确定势力的角色可明置与你势力相同的武将牌执行该军令）。你和每一个执行军令的角色加1点体力上限并回复1点体力，然后你摸X张牌"..
	"（X为因此回复体力的角色数）。",
}

jiezhiren = sgs.CreateTriggerSkill{
	name = "jiezhiren",
	events = {sgs.CardUsed, sgs.CardResponded},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and (event == sgs.CardUsed or event == sgs.CardResponded)
		and not player:hasFlag("First_card_use") then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:isRed() and card:getTypeId() ~= sgs.Card_TypeSkill and card:getSkillName() == "" then 
				return self:objectName()
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		local card_use = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card_use = use.card
		else
			local response = data:toCardResponse()
			if response.m_isUse then
				card_use = response.m_card
			end
		end
		local card_name = card_use:getName()
		local x = #card_name
		if x < 1 then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("zhiren", player)
			room:doAnimate(1, player:objectName(), card_use.from:objectName())
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		local card_use = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card_use = use.card
		else
			local response = data:toCardResponse()
			if response.m_isUse then
				card_use = response.m_card
			end
		end
		room:setPlayerFlag(player, "First_card_use")
		local choices = {"guanxing", "discardEquip"}
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
		if choice == "guanxing" then
			local x = 0
			if card_use:getTypeId() == sgs.Card_TypeBasic then --处理“杀”分为“普杀”、“火杀”、鏖战等情况
				x = 1
			elseif card_use:isKindOf("Nullification") then --处理国无懈可击情况
				x = 4
			else
				local card_name = card_use:getName()
				local y = #card_name
				x = y / 3 --一个中文字符长度为3
			end
			local draw_pile = room:getNCards(x)
			room:askForGuanxing(player, draw_pile, sgs.Room_GuanxingBothSides)
		elseif choice == "discardEquip" then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isFemale() and not p:getEquips():isEmpty() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jiezhiren_discardEquip", true, true)
				if target then
					local card_id = room:askForCardChosen(player, target, "e", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(card_id, target, player, "jiezhiren")
				end
			end
		end
		return false
	end
}

jieyaner = sgs.CreateTriggerSkill{
	name = "jieyaner",
	events = {sgs.Player_Play, sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getPhase() == sgs.Player_Play and event == sgs.EventPhaseStart then
			if player:isKongcheng() then
				room:setPlayerMark(player, "AsIs_noHandCard", 1)
			end
		end
		if player and player:isAlive() and player:getPhase() == sgs.Player_Play and event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:isKongcheng() and player:getMark("AsIs_noHandCard") <= 0 then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and player:isFriendWith(skill_owner) 
					and player:getMark("jieyanerUsed") <= 0 then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			elseif not player:isKongcheng() then
				room:removePlayerMark(player, "AsIs_noHandCard", 1)
			end
		end
		if player and player:isAlive() and player:getPhase() == sgs.Player_Finish and event == sgs.EventPhaseStart then
			room:removePlayerMark(player, "jieyanerUsed", 1)
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		if player:getMark("jieyanerUsed") > 0 then return false end
		if skill_owner:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("yaner", skill_owner)
			room:doAnimate(1, skill_owner:objectName(), player:objectName())
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
		if player:getMark("jieyanerUsed") > 0 then return false end
		room:setPlayerMark(player, "jieyanerUsed", 1)
		room:drawCards(player, 1, "jieyaner")
		room:drawCards(skill_owner, 1, "jieyaner")
		return false
	end
}

jiepanshu:addSkill(jieyaner)
jiepanshu:addSkill(jiezhiren)

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiepanshu"] = "潘淑",
    ["jiezhiren"] = "织纫",
	[":jiezhiren"] = "当你于一回合内使用第一张非转化的红色牌时，你可以选择项：1、观看牌堆顶的X张牌，然后将这些牌以任意顺序置于"..
	"牌堆顶或牌堆底（X为此牌字数）；2、弃置一名其他女性角色装备区里的一张牌。",
	["jieyaner"] = "燕尔",
	[":jieyaner"] = "每回合限一次，当一名势力与你相同的角色于其出牌阶段失去手牌时，若其没有手牌，你可以与其各摸一张牌。",
	["@jiezhiren_discardEquip"] = "选择一名装备区有牌的其他女性角色",
	["jiezhiren:guanxing"] = "观星",
	["jiezhiren:discardEquip"] = "弃置一名女性角色的装备牌",
}

jieyicheng = sgs.CreateTriggerSkill{
	name = "jieyicheng",
	events = {sgs.TargetConfirmed, sgs.CardFinished, sgs.TargetChosen},
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		if player and player:isAlive() and use.card:isKindOf("Slash") then--or (use.from and use.from:isAlive())) and use.card:isKindOf("Slash") then
			local skill_list = {}
			local name_list = {}
			local skill_owners = room:findPlayersBySkillName(self:objectName())
			for _, skill_owner in sgs.qlist(skill_owners) do
				if event == sgs.CardFinished then 
					room:setPlayerFlag(skill_owner, "-FirstTarget")
				end
				if not skill_owner:hasFlag("FirstTarget") and (event == sgs.TargetConfirmed or event == sgs.TargetChosen) then
					if skillTriggerable(skill_owner, self:objectName()) then
						--if (player:isFriendWith(skill_owner) and use.to and use.to:contains(player)) or 
						--(use.from and use.from:isFriendWith(skill_owner)) then
						if player:isFriendWith(skill_owner) then
							table.insert(skill_list, self:objectName())
							table.insert(name_list, skill_owner:objectName())
							room:setPlayerFlag(skill_owner, "FirstTarget") --防止多杀时重复触发
						end
					end
				end
			end
			return table.concat(skill_list,"|"), table.concat(name_list,"|")
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		local use = data:toCardUse()
		if (skill_owner:hasShownSkill(self:objectName()) or skill_owner:objectName() == player:objectName()) 
		and use.card:isKindOf("Slash") then
			if player:isFriendWith(skill_owner) then--and use.to and use.to:contains(player) then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke("yicheng", skill_owner)
					room:doAnimate(1, skill_owner:objectName(), player:objectName())
					return true
				end
			--[[elseif use.from and use.from:isFriendWith(skill_owner) then
				if use.from:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke("yicheng", skill_owner)
					room:doAnimate(1, skill_owner:objectName(), use.from:objectName())
					return true
				end]]
			end
		end
		return false
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
		--local use = data:toCardUse()
		if player:isFriendWith(skill_owner) then--and use.to and use.to:contains(player) then
			room:drawCards(player, 1, skill_owner:objectName())
			if player:canDiscard(player, "he") then
				room:askForDiscard(player, skill_owner:objectName(), 1, 1, false, true, "@jieyicheng_discard")
			end
		--[[elseif use.from and use.from:isFriendWith(skill_owner) then
			room:drawCards(use.from, 1, skill_owner:objectName())
			if use.from:canDiscard(use.from, "he") then
				room:askForDiscard(use.from, skill_owner:objectName(), 1, 1, false, true, "@jieyicheng_discard")
			end]]
		end
		return false
	end
}

jiexusheng:addSkill(jieyicheng)

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiexusheng"] = "徐盛",
    ["jieyicheng"] = "疑城",
	[":jieyicheng"] = "与你势力相同的角色使用【杀】指定第一个目标后，或成为【杀】的目标后，其可以摸一张牌，然后弃置一张牌。",
	["@jieyicheng_discard"] = "疑城：弃置一张牌",
}

jieshengxi = sgs.CreateTriggerSkill{
	name = "jieshengxi",
	events = {sgs.Damage, sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			if event == sgs.Damage then
				local damage = data:toDamage()
				if damage.damage == 0 then return false end
				if damage.to and damage.from and damage.from == player then
					room:setPlayerFlag(player, "jieshengxi_damage")
				end
			elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
				if not player:hasFlag("jieshengxi_damage") then
					return self:objectName()
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if not player:hasFlag("jieshengxi_damage") then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke("shengxi", player)
				return true
			end
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		if not player:hasFlag("jieshengxi_damage") then
			player:drawCards(2, self:objectName())
		end
		return false
	end
}

jiejiangwanfeiyi:addSkill("shoucheng")
jiejiangwanfeiyi:addSkill(jieshengxi)

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiejiangwanfeiyi"] = "蒋琬费祎",
    ["jieshengxi"] = "生息",
	[":jieshengxi"] = "弃牌阶段开始时，若你于本回合内没有造成过伤害，则你可以摸两张牌。",
}

jieyinbing = sgs.CreateTriggerSkill{
	name = "jieyinbing",
	events = {sgs.EventPhaseEnd, sgs.EventPhaseStart, sgs.EventLoseSkill},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventLoseSkill and data:toString():split(":")[1] == self:objectName() 
		and player then
			player:clearOnePrivatePile("pileOfYinbing")
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "jieyinbingUsed", 0)
				if not player:getPile("pileOfYinbing"):isEmpty() then
					return self:objectName()
				end
			elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
				if player:getHp() > 1 then
					return self:objectName()
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			if player:askForSkillInvoke(self:objectName(), data) then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					targets:append(p)
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jieyinbing_reduceDamage", true, true)
				if not target then return false end
				local d = sgs.QVariant()
				d:setValue(target)
				player:setTag("@jieyinbing_target", d)
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke("yinbing", player)
				return true
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:broadcastSkillInvoke("yinbing", player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local x = player:getHp() - 1
			if x < 1 then return false end
			local draw_pile = room:getNCards(x)
			player:addToPile("pileOfYinbing", draw_pile, true)
			room:loseHp(player, x)
			room:setPlayerMark(player, "jieyinbingUsed", 1)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local card_ids = player:getPile("pileOfYinbing")
			local target = player:getTag("@jieyinbing_target"):toPlayer()
			player:removeTag("@jieyinbing_target")
			local cards_len = card_ids:length()
			if cards_len <= 0 then return false end
            local dummy = sgs.DummyCard(card_ids)  
            player:obtainCard(dummy)
            dummy:deleteLater()
			player:clearOnePrivatePile("pileOfYinbing")
			local recover = sgs.RecoverStruct()
            recover.who = player
            recover.recover = cards_len
            room:recover(player, recover)
		end
		return false
	end
}

jieyinbing_damaged = sgs.CreateTriggerSkill{
	name = "#jieyinbing_damaged",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and event == sgs.DamageInflicted then
			local skill_owners = room:findPlayersBySkillName("jieyinbing")
			local damage = data:toDamage()
			for _, skill_owner in sgs.qlist(skill_owners) do
				if skillTriggerable(skill_owner, "jieyinbing") and not skill_owner:getPile("pileOfYinbing"):isEmpty() and
				damage.damage > 0 then
					if skill_owner:getMark("jieyinbingUsed") > 0 and skill_owner:getTag("@jieyinbing_target"):toPlayer() == 
					player then
						return self:objectName(), skill_owner:objectName()
					end
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		return true
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
		local damage = data:toDamage()
		local cards = skill_owner:getPile("pileOfYinbing")
		if cards:isEmpty() then return false end
		local x = damage.damage
		local cards_len = cards:length()
		local to_throw = sgs.IntList()
		if x >= cards_len then --伤害大于等于“引兵”数量
			local i = 0
			while cards_len > 0 do
				to_throw:append(cards:at(i))
				i = i + 1
				cards_len = cards_len - 1
			end
		else 
			to_throw = room:askForExchange(skill_owner, "jieyinbing_remove", x, x, "@jieyinbing-remove:::" .. tostring(x), 
			"pileOfYinbing")
		end
		if not to_throw:isEmpty() then
			local reason = sgs.CardMoveReason(
				sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, skill_owner:objectName(), "jieyinbing", "")
			local move = sgs.CardsMoveStruct(to_throw, nil, sgs.Player_DiscardPile, reason)
			room:moveCardsAtomic(move, true)
		end
		local correctDamage = data:toDamage()
		correctDamage.damage = x - to_throw:length()
		data:setValue(correctDamage)
		if skill_owner:getPile("pileOfYinbing"):isEmpty() then
			skill_owner:clearOnePrivatePile("pileOfYinbing")
		end
		-- 显示减伤的提示  
		local msg = sgs.LogMessage()
		msg.type = "#jieyinbingReduceDamage"
		msg.from = player
		msg.arg = to_throw:length()
		msg.arg2 = self:objectName()
		room:sendLog(msg)
		if correctDamage.damage == 0 then return true end --停止结算，达到防止伤害的效果
		return false 
	end
}

jiezumao:addSkill(jieyinbing)
jiezumao:addSkill(jieyinbing_damaged)
testToFix:insertRelatedSkills("jieyinbing", "#jieyinbing_damaged")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiezumao"] = "祖茂",
    ["jieyinbing"] = "引兵",
	[":jieyinbing"] = "结束阶段，你可以失去体力至1点，将牌堆顶等同于失去体力值的牌置于你的武将牌上，称为“引兵”，并选择一名角色："..
	"其受到伤害时，你移去等同伤害值的“引兵”牌（不足则全移去）并减少等量的伤害；准备阶段，你获得所有“引兵”牌并回复等量体力。",
	["@jieyinbing_reduceDamage"] = "引兵：选择一名角色",
	["@jieyinbing-remove"] = "引兵：移去 %arg 张“引兵”牌以减少等量的伤害",
	["pileOfYinbing"] = "引兵",
	["#jieyinbing_damaged"] = "引兵",
	["#jieyinbingReduceDamage"] = "%from 发动了“%arg2”减少了 “%agr1” 点伤害",
}

taipingShow = sgs.CreateZeroCardViewAsSkill{
	name = "taipingShow",
	view_as = function(self)
		local card = sgs.cloneSkillCard("ShowMashu")
		card:setSkillName(taidan:objectName())
		card:setShowSkill(taidan:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasShownSkill("taidan")
	end
}

taidan = sgs.CreateTriggerSkill{
	name = "taidan",
	frequency = sgs.Skill_Compulsory,
	view_as_skill = taipingShow,
	can_trigger = function(self, event, room, player, data)
		return false
	end
}

taiping_viewhas = sgs.CreateViewHasSkill{
	name = "#taiping_viewhas",
	is_viewhas = function(self, player, skill_name, flag)
		if flag == "armor" and skill_name == "PeaceSpell" and player:isAlive() and player:hasShownSkill("taidan")
		and not player:getArmor() then
			return true
		end
		return false
	end
}

jiejingheCard = sgs.CreateSkillCard{
	name = "jiejingheCard",
	skill_name = "jiejinghe",
	target_fixed = true,
	on_use = function(self, room, source)
		local skill_number = math.random(8)
		local skill_list = {"lundao", "guanyue", "yanzheng", "leiji_tianshu", "yinbing", "huoqi", "guizhu", "xianshou"}
		local prompt = "@jiejinghe_" .. skill_list[skill_number]
		room:setPlayerMark(source, "jiejinghe_Acquire", skill_number) --给AI传技能数据
		room:broadcastSkillInvoke("jinghe", source)
		local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), prompt, false, true)
		if not target then
			target = source
		end
		room:setPlayerMark(source, "jiejinghe_Acquire", 0)
		room:acquireSkill(target, skill_list[skill_number], true, true)
		room:doAnimate(1, source:objectName(), target:objectName())
		room:addPlayerMark(target, "##" .. skill_list[skill_number])
		local d = sgs.QVariant()
		d:setValue(target)
		source:setTag("jiejinghe_skill", d)
	end,
}

jiejinghe = sgs.CreateZeroCardViewAsSkill{
	name = "jiejinghe",
	view_as = function(self)
		local card = jiejingheCard:clone()
		card:setSkillName(self:objectName())
		card:setShowSkill(self:objectName())
		return card
	end,

	enabled_at_play = function(self, player)
		return not player:hasUsed("#jiejingheCard") 
	end,
}

jiejinghe_clear = sgs.CreateTriggerSkill{
	name = "#jiejinghe-clear",
	events = {sgs.EventPhaseStart, sgs.EventLoseSkill, sgs.TurnStart, sgs.Death},
	on_record = function(self, event, room, player, data)
		if (event == sgs.EventLoseSkill and data:toString():split(":")[1] == self:objectName() and player) or 
		event == sgs.Death then
			local target = player:getTag("jiejinghe_skill"):toPlayer()
			local skill_list = {"lundao", "guanyue", "yanzheng", "leiji_tianshu", "yinbing", "huoqi", "guizhu", "xianshou"}
			if target and target:isAlive() then
				for i = 1, #skill_list do
					if target:hasSkill(skill_list[i]) then
						room:detachSkillFromPlayer(target, skill_list[i])
						room:detachSkillFromPlayer(target, skill_list[i], false, false, false)
						room:removePlayerMark(target, "##" .. skill_list[i])
					end
				end
				target:removeTag("jiejinghe_skill")
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.TurnStart then
				local target = player:getTag("jiejinghe_skill"):toPlayer()
				local skill_list = {"lundao", "guanyue", "yanzheng", "leiji_tianshu", "yinbing", "huoqi", "guizhu", "xianshou"}
				if target and target:isAlive() then
					for i = 1, #skill_list do
						if target:hasSkill(skill_list[i]) then
							room:detachSkillFromPlayer(target, skill_list[i])
							room:detachSkillFromPlayer(target, skill_list[i], false, false, false)
							room:removePlayerMark(target, "##" .. skill_list[i])
						end
						target:removeTag("jiejinghe_skill")
					end
				end
			end
		end
		return false
	end,
}

jienanhualaoxian:addSkill(taidan)
jienanhualaoxian:addSkill(taiping_viewhas)
jienanhualaoxian:addSkill(jiejinghe)
jienanhualaoxian:addSkill(jiejinghe_clear)
jienanhualaoxian:addSkill("gongxiu")
testToFix:insertRelatedSkills("taidan", "#taiping_viewhas")
testToFix:insertRelatedSkills("jiejinghe", "#jiejinghe-clear")


-- 加载翻译表
sgs.LoadTranslationTable{
    ["jienanhualaoxian"] = "南华老仙",
    ["jiejinghe"] = "经合",
	[":jiejinghe"] = "出牌阶段限一次，你可以转动“天书”，然后令一名角色获得“天书”向上一面所示的技能，直到你的下回合开始。",
	["taidan"] = "太丹",
	[":taidan"] = "锁定技，若你的装备区没有防具牌，则你视为装备着【太平要术】",
	["jiejingheCard"] = "经合",
	["@jiejinghe_lundao"] = "经合：选择一名角色获得技能“论道”",
	["@jiejinghe_guanyue"] = "经合：选择一名角色获得技能“观月”",
	["@jiejinghe_yanzheng"] = "经合：选择一名角色获得技能“言政”",
	["@jiejinghe_leiji_tianshu"] = "经合：选择一名角色获得技能“雷击”",
	["@jiejinghe_yinbing"] = "经合：选择一名角色获得技能“阴兵”",
	["@jiejinghe_huoqi"] = "经合：选择一名角色获得技能“活气”",
	["@jiejinghe_guizhu"] = "经合：选择一名角色获得技能“鬼助”",
	["@jiejinghe_xianshou"] = "经合：选择一名角色获得技能“仙授”",
}

jienuzhan = sgs.CreateTriggerSkill{
	name = "jienuzhan",
	events = {sgs.CardUsed, sgs.DamageCaused, sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "##jienuzhan_Trick", 0)
				room:setPlayerMark(player, "##jienuzhan_Equip", 0)
			end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and not player:hasFlag("jienuzhanUsed") then
			if event == sgs.DamageCaused then
				local damage = data:toDamage()
				if not damage.card or not damage.card:isKindOf("Slash") then return false end
				if sgs.Sanguosha:getCard(damage.card:getSubcards():first()):getTypeId() == sgs.Card_TypeEquip and 
				damage.from == player and damage.card:getSkillName() ~= "" then
					return self:objectName()
				end
			elseif event == sgs.CardUsed then
				local use = data:toCardUse()
				if use and use.card and use.card:isKindOf("Slash") then
					if use.from == player and sgs.Sanguosha:getCard(use.card:getSubcards():first()):getTypeId() == sgs.Card_TypeTrick
					and player:getPhase() == sgs.Player_Play and use.card:getSkillName() ~= "" then
						return self:objectName()
					end
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if not player:hasShownSkill("jienuzhan") then
            if player:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            else
                return false
            end
        end
		room:broadcastSkillInvoke(self:objectName(), player)
        return true
	end,

	on_effect = function(self, event, room, player, data)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			damage.damage = damage.damage + 1
			data:setValue(damage)
			room:setPlayerFlag(player, "jienuzhanUsed")
			room:addPlayerMark(player, "##jienuzhan_Equip")
			-- 显示加伤的提示  
			local msg = sgs.LogMessage()
			msg.type = "#jienuzhanAddDamage"
			msg.from = player
			msg.arg = 1
			msg.arg2 = self:objectName()
			room:sendLog(msg)
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			room:addPlayerMark(player, "##jienuzhan_Trick")
			room:setPlayerFlag(player, "jienuzhanUsed")
			room:broadcastSkillInvoke(self:objectName(), player)
		end
		return false
	end
}

jienuzhanTarget = sgs.CreateTargetModSkill{
	name = "#jienuzhan-target",
	pattern = "Slash",
	residue_func = function(self, player)
		return player:getMark("##jienuzhan_Trick")
	end,
}

jieguanyu:addSkill(jienuzhan)
jieguanyu:addSkill(jienuzhanTarget)
jieguanyu:addSkill("wusheng")
testToFix:insertRelatedSkills("jienuzhan", "#jienuzhan-target")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jieguanyu"] = "关羽",
    ["jienuzhan"] = "怒斩",
	[":jienuzhan"] = "锁定技，每回合限一次，你使用锦囊牌转化的【杀】无次数限制，装备牌转化的【杀】造成的伤害+1。",
	["#jienuzhanAddDamage"] =  "%from发动了“%arg2” ,造成的伤害加“%arg1”",
	["jienuzhan_Trick"] = "怒斩",
	["jienuzhan_Equip"] = "怒斩",
	["$jienuzhan1"] = "以义传魂，以武入圣！",
	["$jienuzhan2"] = "义击逆流，武安黎庶！",
}

jiebiyue = sgs.CreateTriggerSkill{
	name = "jiebiyue",
	events = {sgs.Player_Finish, sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			return self:objectName()
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("biyue", player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		if player:isKongcheng() then
			player:drawCards(2, self:objectName())
		else
			player:drawCards(1, self:objectName())
		end
		return false
	end,
}

jiediaochan:addSkill(jiebiyue)
jiediaochan:addSkill("lijian")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiediaochan"] = "貂蝉",
    ["jiebiyue"] = "闭月",
	[":jiebiyue"] = "结束阶段，你可以摸一张牌，若你没有手牌则改为摸两张牌。",
}

jieguanxing = sgs.CreatePhaseChangeSkill{
	name = "jieguanxing",
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Start then
			return self:objectName()
		elseif skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("jieguanxing_allBottom") then
				return self:objectName()
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("guanxing", player)
			return true
		end
		return false
	end,

	on_phasechange = function(self, player)
		local room = player:getRoom()
		local playerNum = room:getAlivePlayers():length()
		local gxPile = sgs.IntList()
		if playerNum > 3 then
			gxPile = room:getNCards(5)
			room:askForGuanxing(player, gxPile, sgs.Room_GuanxingBothSides)
		else
			gxPile = room:getNCards(3)
			room:askForGuanxing(player, gxPile, sgs.Room_GuanxingBothSides)
		end
		if not gxPile:contains(room:getDrawPile():at(0)) then
			room:setPlayerFlag(player, "jieguanxing_allBottom")
		end
		return false
	end
}

jiezhugeliang:addSkill(jieguanxing)
jiezhugeliang:addSkill("kongcheng")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiezhugeliang"] = "诸葛亮",
    ["jieguanxing"] = "观星",
	[":jieguanxing"] = "准备阶段，你可以观看牌堆顶五张牌（角色数小于等于3时改为三张），将这些牌以任意顺序置于牌堆顶或牌堆底。若均置于" ..
	"牌堆底，则你可以于结束阶段再次发动此技能。",
}

jielieren = sgs.CreateTriggerSkill{
	name = "jielieren",
	events = {sgs.TargetChosen},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.TargetChosen and not player:isKongcheng() then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from == player then
				local target_list = {}
				for _, p in sgs.qlist(use.to) do
					if p ~= player and not p:isKongcheng() then
						table.insert(target_list, p:objectName())
					end
				end
				if #target_list > 0 then
					return self:objectName() .. "->" .. table.concat(target_list, "+")
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, skill_target, data, player)
		if player:isKongcheng() or skill_target:isKongcheng() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("lieren", player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, skill_target, data, player)
		player:setTag("jielieren_cardUsed", data)
		player:pindian(skill_target, "jielieren")
		player:removeTag("jielieren_cardUsed")
		return false
	end
}

jielierenPindian = sgs.CreateTriggerSkill{
	name = "#jielierenPindian",
	events = {sgs.Pindian},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, "jielieren") and event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "jielieren" then
				local winner = nil
				local loser = nil
				if pindian.success then
					winner = pindian.from
					loser = pindian.to
				else
					winner = pindian.to
					loser = pindian.from
				end
				if winner:isAlive() and loser:isAlive() then
					if winner:objectName() == player:objectName() and not loser:isNude() then
						local card_id = room:askForCardChosen(player, loser, "he", "jielieren", false, sgs.Card_MethodGet)
						room:obtainCard(player, card_id, false)
					elseif loser:objectName() == player:objectName() then
						room:obtainCard(winner, pindian.from_card, false)
						room:obtainCard(player, pindian.to_card, false)
					end
				end
			end
		end
		return false
	end,
}

jiezhurong:addSkill(jielieren)
jiezhurong:addSkill("juxiang")
jiezhurong:addSkill(jielierenPindian)
testToFix:insertRelatedSkills("jielieren", "#jielierenPindian")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiezhurong"] = "祝融",
    ["jielieren"] = "烈刃",
	[":jielieren"] = "当你的【杀】指定目标后，你可以与其拼点。若你赢，你获得其一张牌；若你没赢，你获得其拼点的牌，其获得你拼点的牌。",
}

jiezhengbingCard = sgs.CreateSkillCard{
    name = "jiezhengbingCard",
	skill_name = "jiezhengbing",
    target_fixed = true,--是否需要指定目标，默认false，即需要
    on_use = function(self, room, source)
        source:drawCards(1)
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("Slash") then
			room:setPlayerFlag(source, "jiezhengbing_recastSlash")
		end
    end
}

jiezhengbing = sgs.CreateOneCardViewAsSkill{
	name = "jiezhengbing",
	view_filter = function(self, selected)
		return true
	end,
	view_as = function(self, card)
        local recast_card = jiezhengbingCard:clone()
        recast_card:addSubcard(card:getId())
        recast_card:setSkillName(self:objectName())
		recast_card:setShowSkill(self:objectName())
        return recast_card
    end,

    enabled_at_play = function(self, player)  
        return not player:hasUsed("#jiezhengbingCard")
    end
}

jiezhengbingMaxHandcard = sgs.CreateMaxCardsSkill{
    name = "#jiezhengbingMaxHandcard",
    extra_func = function(self, target)
		if target:hasFlag("jiezhengbing_recastSlash") then
			return 2
		end
		return 0
    end
}

jiezhangliao:addSkill(jiezhengbing)
jiezhangliao:addSkill(jiezhengbingMaxHandcard)
jiezhangliao:addSkill("tuxi")
testToFix:insertRelatedSkills("jiezhengbing", "#jiezhengbingMaxHandcard")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiezhangliao"] = "张辽",
    ["jiezhengbing"] = "整兵",
	[":jiezhengbing"] = "出牌阶段限一次，你可以重铸一张牌，若此牌为【杀】，你本回合手牌上限+2。",
}

jiexiechanCard = sgs.CreateSkillCard{
	name = "jiexiechanCard",
	skill_name = "jiexiechan",
	will_throw = false,
	filter = function(self, targets, to_select, Self)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= Self:objectName() and not 
		to_select:isRemoved()
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@jiexiechan")  
    	room:broadcastSkillInvoke("jiexiechan", source)
		source:pindian(targets[1], "jiexiechan")
	end
}

jiexiechan = sgs.CreateZeroCardViewAsSkill{
	name = "jiexiechan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@jiexiechan",
	view_as = function(self)  
        local card = jiexiechanCard:clone()  
        card:setSkillName(self:objectName())
		card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return player:getMark("@jiexiechan") > 0 and not player:isKongcheng()
    end
}

jiexiechanPindian = sgs.CreateTriggerSkill{
	name = "#jiexiechanPindian",
	events = {sgs.Pindian},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "jiexiechan" then
				return self:objectName()
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		return true
	end,

	on_effect = function(self, event, room, player, data)
		local pindian = data:toPindian()
		local winner = nil
		local loser = nil
		if pindian.success then
			winner = pindian.from
			loser = pindian.to
		else
			winner = pindian.to
			loser = pindian.from
		end
		if winner:isAlive() and loser:isAlive() then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("jiexiechan")
			room:useCard(sgs.CardUseStruct(duel, winner, loser), true)
			duel:deleteLater()
		end
		return false
	end
}

jiexuchu:addSkill(jiexiechan)
jiexuchu:addSkill(jiexiechanPindian)
jiexuchu:addSkill("luoyi")
testToFix:insertRelatedSkills("jiexiechan", "#jiexiechanPindian")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiexuchu"] = "许褚",
    ["jiexiechan"] = "挟缠",
	[":jiexiechan"] = "限定技，出牌阶段，你可以与一名角色拼点。若你赢，你视为对其使用一张【决斗】；若你没赢，其视为对你使用一张【决斗】。",
	["$jiexiechan1"] = "不是你死，便是我亡！",
	["$jiexiechan2"] = "休走！你我今日定要分个胜负！",
}

jiejiezi = sgs.CreateTriggerSkill{
	name = "jiejiezi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseSkipping, sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and event == sgs.EventPhaseSkipping then
			local change = data:toPhaseChange()
			local skill_owners = room:findPlayersBySkillName("jiejiezi")
			local skill_list = {}
			local name_list = {}
			if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
				if skill_owner:getMark("jiejiezi_draw") < 2 and change.to == sgs.Player_Draw and skill_owner ~= player then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
			end
			return table.concat(skill_list, "|"), table.concat(name_list, "|")
		elseif player and player:isAlive() and event == sgs.EventPhaseStart then
			local allPlayer = sgs.SPlayerList()
			allplayer = room:getAlivePlayers()
			for _, firstPlayer in sgs.qlist(allplayer) do
				if player ~= firstPlayer then return false end
				if not firstPlayer:hasFlag("fangquanInvoked") and firstPlayer:getPhase() == sgs.TurnStart then
					local skill_owners = room:findPlayersBySkillName("jiejiezi")
					if skill_owners:isEmpty() then return false end
					for _, skill_owner in sgs.qlist(skill_owners) do
						room:setPlayerMark(skill_owner, "jiejiezi_draw", 0)
					end
					break
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		if not skill_owner:hasShownSkill("jiejiezi") then
            if skill_owner:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), skill_owner)
                return true
            else
                return false
            end
        end
		room:broadcastSkillInvoke(self:objectName(), skill_owner)
        return true
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
		skill_owner:drawCards(1, self:objectName())
		room:addPlayerMark(skill_owner, "jiejiezi_draw", 1)
		-- 显示获得牌的提示  
		local msg = sgs.LogMessage()
		msg.type = "#jiejieziObtain"
		msg.from = skill_owner
		msg.arg = 1
		msg.arg2 = self:objectName()
		room:sendLog(msg)
		return false
	end
}

jiexuhuang:addSkill(jiejiezi)
jiexuhuang:addSkill("duanliang")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiexuhuang"] = "徐晃",
    ["jiejiezi"] = "截辎",
	[":jiejiezi"] = "锁定技，每轮限两次，其他角色跳过摸牌阶段后，你摸一张牌。",
	["#jiejieziObtain"] = "%from 发动了“%arg2”，摸了 %arg 张牌",
	["$jiejiezi1"] = "剪径截辎，馈泽同袍。",
	["$jiejiezi2"] = "截敌粮草，以资袍泽。",
}

jiefenwei = sgs.CreateTriggerSkill{
	name = "jiefenwei",
	events = {sgs.TargetChosen},
	frequency = sgs.Skill_Limited,
	limit_mark = "@jiefenwei",
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and event == sgs.TargetChosen then
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() == sgs.Card_TypeTrick and use.to:length() > 1 then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and skill_owner:getMark("@jiefenwei") > 0 then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		if skill_owner:askForSkillInvoke(self:objectName(), data) then
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
		local use = data:toCardUse()
		local targets = sgs.SPlayerList()
		local targets_remove = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if p:isAlive() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			room:setPlayerMark(skill_owner, "@jiefenwei", 0)
			local prompt = "@jiefenwei-target:" .. player:objectName() .. "::" .. use.card:objectName()
			skill_owner:setTag("jiefenweiUsedata", data) --给AI传data
			targets_remove = room:askForPlayersChosen(skill_owner, targets, self:objectName(), 1, use.to:length(), prompt, true)
			skill_owner:removeTag("jiefenweiUsedata")
			if targets_remove:isEmpty() then return false end
			room:broadcastSkillInvoke(self:objectName(), skill_owner)
			for _, p in sgs.qlist(targets_remove) do
				sgs.Room_cancelTarget(use, p)
				room:doAnimate(1, skill_owner:objectName(), p:objectName())
			end
			data:setValue(use)
		end
		return false
	end
}

jieganning:addSkill(jiefenwei)
jieganning:addSkill("qixi")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jieganning"] = "甘宁",
    ["jiefenwei"] = "奋威",
	[":jiefenwei"] = "限定技，当一张锦囊牌指定目标后，若此牌的目标数大于1，你可以令此牌减少任意个目标。",
	["@jiefenwei-target"] = "奋威：选择为%src使用的【%arg】至少减少一个目标",
	["$jiefenwei2"] = "哼！敢欺我东吴无人。",
	["$jiefenwei1"] = "奋勇当先，威名远扬。",
}

jiehanzhan = sgs.CreateTriggerSkill{
    name = "jiehanzhan",
    events = {sgs.Pindian},
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)
        if not skillTriggerable(player, self:objectName()) or event ~= sgs.Pindian then
            return false
        end
        local pindian = data:toPindian()
        if pindian.from:objectName() == player:objectName() or pindian.to:objectName() == player:objectName() then
			if pindian.from_card:isKindOf("Slash") or pindian.to_card:isKindOf("Slash") then
				return self:objectName()
			end
        end
        return false
    end,
      
    on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
        return false
    end,
      
    on_effect = function(self, event, room, player, data)
        local pindian = data:toPindian()
		local card1 = pindian.from_card
		local card2 = pindian.to_card
		if card1:isKindOf("Slash") then
			if card2:isKindOf("Slash") then --1和2都是【杀】
				if pindian.from_number > pindian.to_number then --来源点数大
					player:obtainCard(card1, true)
				elseif pindian.from_number < pindian.to_number then --目标点数大
					player:obtainCard(card2, true)
				else --点数一样大
					player:obtainCard(card1, true)
					player:obtainCard(card2, true)
				end
			else
				player:obtainCard(card1, true)
			end
		elseif card2:isKindOf("Slash") then
			player:obtainCard(card2, true)
		else
			return false
		end
        return false
    end
}

jietaishici:addSkill(jiehanzhan)
jietaishici:addSkill("tianyi")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jietaishici"] = "太史慈",
    ["jiehanzhan"] = "酣战",
	[":jiehanzhan"] = "当你拼点后，你可以获得拼点牌之中点数最大的【杀】。",
	["$jiehanzhan1"] = "伯符，且与我一战！",
	["$jiehanzhan2"] = "与君酣战，快哉快哉！",
}

jieshuangxiongVS = sgs.CreateOneCardViewAsSkill{
	name = "jieshuangxiongVS",
	view_filter = function(self, card)
		if card:isEquipped() then return false end
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
		duel:addSubcard(card:getEffectiveId())
		duel:deleteLater()
		if sgs.Self:hasFlag("jieshuangxiong_Black") then
			return card:isRed() and duel:isAvailable(sgs.Self)
		elseif sgs.Self:hasFlag("jieshuangxiong_Red") then
			return card:isBlack() and duel:isAvailable(sgs.Self)
		end
		return false
	end,
	view_as = function(self, card)
		local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
		duel:addSubcard(card:getId())
		duel:setSkillName(self:objectName())
		duel:setShowSkill(self:objectName())
		return duel
	end
}

jieshuangxiong = sgs.CreatePhaseChangeSkill{
	name = "jieshuangxiong",
	view_as_skill = jieshuangxiongVS,
	can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Draw then
            return self:objectName()
        end
        return false
    end,
      
    on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("shuangxiong", player)
			return true
		end
        return false
    end,

	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:setPlayerFlag(player, "jieshuangxiongUsed")
		local card_ids = room:getNCards(2)
		room:fillAG(card_ids, player)
		local card_choose = room:askForAG(player, card_ids, false, self:objectName())
		room:clearAG(player)
		if card_choose < 0 then return false end
		player:obtainCard(sgs.Sanguosha:getCard(card_choose), true)
		if sgs.Sanguosha:getCard(card_choose):isBlack() then
			room:setPlayerFlag(player, "jieshuangxiong_Black")
		elseif sgs.Sanguosha:getCard(card_choose):isRed() then
			room:setPlayerFlag(player, "jieshuangxiong_Red")
		end
		return false
	end
}

jieshuangxiongDraw = sgs.CreateDrawCardsSkill{
	name = "#jieshuangxiongDraw",
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
        if player:hasFlag("jieshuangxiongUsed") then
            return self:objectName()
        end
        return false
    end,
      
    on_cost = function(self, event, room, player, data)
		if player:hasFlag("jieshuangxiongUsed") then return true end
		return false
    end,

	draw_num_func= function(self, player, n)
		return 0
	end
}

jieshuangxiongGetAndClear = sgs.CreateTriggerSkill{
	name = "#jieshuangxiongGetAndClear",
	events = {sgs.EventPhaseStart, sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasFlag("jieshuangxiongUsed") and event == sgs.EventPhaseStart then
			if not player:hasSkill("jieshuangxiong") and player:getPhase() == sgs.Player_Play then
				room:acquireSkill(player, "jieshuangxiong", true, false)
				room:setPlayerFlag(player, "jieshuangxiongGet")
			elseif player:hasFlag("jieshuangxiongGet") and player:getPhase() == sgs.Player_Finish then
				room:detachSkillFromPlayer(player, "jieshuangxiong")
				room:detachSkillFromPlayer(player, "jieshuangxiong", false, false, false)
			end
		elseif skillTriggerable(player, "jieshuangxiong") and event == sgs.CardUsed then
			local use = data:toCardUse()
			if use and use.card and use.card:getSkillName() == "jieshuangxiong" then
				room:broadcastSkillInvoke("shuangxiong", player)
			end
		end
		return false
	end
}

jieyanliangwenchou:addSkill(jieshuangxiong)
jieyanliangwenchou:addSkill(jieshuangxiongDraw)
testToFix:insertRelatedSkills("jieshuangxiong", "#jieshuangxiongDraw")
if not sgs.Sanguosha:getSkill("#jieshuangxiongGetAndClear") then skills:append(jieshuangxiongGetAndClear) end

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jieyanliangwenchou"] = "颜良文丑",
    ["jieshuangxiong"] = "双雄",
	[":jieshuangxiong"] = "摸牌阶段开始时，你可以改为亮出牌堆顶两张牌，你获得其中一张牌，然后你于此回合内可以将一张与该牌颜色不同的手牌" ..
	"当【决斗】使用。",
}

jiepolu = sgs.CreateTriggerSkill{
	name = "jiepolu",
	events = {sgs.BuryVictim},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local skill_list = {}
			local name_list = {}
			local skill_owners = room:findPlayersBySkillName(self:objectName()) 
			for _, skill_owner in sgs.qlist(skill_owners) do
				if death.who:objectName() == skill_owner:objectName() or (death.damage and death.damage.from and 
				death.damage.from == skill_owner) then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
					return table.concat(skill_list,"|"), table.concat(name_list,"|")
				end
			end 
			if death.who:getGeneralName() == "sunjian" or death.who:getGeneral2Name() == "sunjian" then 
				--死亡后就没有该技能，故要后判断自己死亡的条件，但暂不知怎么判断有没被断肠
				return self:objectName(), player:objectName() 
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		local death = data:toDeath()
		if skill_owner:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), skill_owner)
			return true
		end
        return false
    end,

	on_effect = function(self, event, room, player, data, skill_owner)
		local targets = sgs.SPlayerList()
		local x = 0
		local death = data:toDeath()
		targets = room:askForPlayersChosen(skill_owner, room:getAlivePlayers(), self:objectName(), 1, 10, "@jiepolu_draw", true)
		if not targets:isEmpty() then
			room:addPlayerMark(skill_owner, "#jiepolu", 1)
			x = skill_owner:getMark("#jiepolu")
			for _, p in sgs.qlist(targets) do
				room:drawCards(p, x, self:objectName())
			end
		end
		return false
	end
}

jiesunjian:addSkill(jiepolu)
jiesunjian:addSkill("yinghun_sunjian")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiesunjian"] = "孙坚",
    ["jiepolu"] = "破虏",
	[":jiepolu"] = "当你杀死一名角色或当你死亡后，你可以令任意名角色各摸X张牌（X为包含本次在内你发动本技能的次数）。",
	["@jiepolu_draw"] = "破虏：选择任意名角色摸牌",
	["$jiepolu1"] = "斩敌复城，扬我江东军威！",
	["$jiepolu2"] = "宝剑出鞘，踏平贼营！",
}

jieyizhi = sgs.CreateTriggerSkill{
	name = "jieyizhi",
	events = {sgs.EventLoseSkill, sgs.GeneralShown, sgs.EventPhaseChanging},
	frequency = sgs.Skill_Frequent,
	relate_to_place = "deputy",
	on_record = function(self, event, room, player, data)
		if not player and not player:hasSkill("jieyizhi") and player:getMark("jieyizhiUsed2") > 0 then return false end
		local has_head_guanxing = false;
		for _, skill in sgs.qlist(player:getHeadSkillList()) do
			if skill:objectName() == "jieguanxing" then --or skill:objectName() == "jieguanxing_jiangwei" then
				has_head_guanxing = true
			end
		end
		if event == sgs.GeneralShown then
			if not player:hasSkill(self:objectName()) then return false end
		elseif event == sgs.EventLoseSkill then
			if data:toString() ~= "jieguanxing" or data:toString() ~= self:objectName() then return false end
		end
		if player:hasShownSkill(self:objectName()) and not (has_head_guanxing and player:hasShownGeneral1()) then
			if player:getMark("jieyizhiUsed1") > 0 then return false end
			room:acquireSkill(player, "jieguanxing_jiangwei", true, false)
			room:setPlayerMark(player, "jieyizhiUsed1", 1)
		elseif player:hasShownSkill(self:objectName()) and has_head_guanxing and player:hasShownGeneral1() then
			room:detachSkillFromPlayer(player, "jieguanxing")
			room:detachSkillFromPlayer(player, "jieguanxing_jiangwei")
			room:detachSkillFromPlayer(player, "jieguanxing_jiangwei", false, false, false)
			room:setPlayerMark(player, "jieyizhiUsed2", 1)
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventLoseSkill and player and player:isAlive() then
			if player:getMark("jieyizhiUsed2") > 0 then
				room:detachSkillFromPlayer(player, "jieguanxing_jiangweiYizhi")
				room:acquireSkill(player, "jieguanxing", true, true)
			end
		elseif skillTriggerable(player, self:objectName()) and event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Start and player:getMark("jieyizhiUsed2") == 1 and not 
			player:hasSkill("jieguanxing_jiangweiYizhi") then
				room:acquireSkill(player, "jieguanxing_jiangweiYizhi", true, true)
				room:detachSkillFromPlayer(player, "jieguanxing_jiangwei", false, false, false)
			end
		end
		return false
	end,
}

jieguanxing_jiangwei = sgs.CreatePhaseChangeSkill{
	name = "jieguanxing_jiangwei",
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Start then
			return self:objectName()
		elseif skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("jieguanxing_allBottom") then
				return self:objectName()
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("guanxing_jiangwei", player)
			return true
		end
		return false
	end,

	on_phasechange = function(self, player)
		local room = player:getRoom()
		local playerNum = room:getAlivePlayers():length()
		local gxPile = sgs.IntList()
		if playerNum > 3 then
			gxPile = room:getNCards(5)
			room:askForGuanxing(player, gxPile, sgs.Room_GuanxingBothSides)
		else
			gxPile = room:getNCards(3)
			room:askForGuanxing(player, gxPile, sgs.Room_GuanxingBothSides)
		end
		if not gxPile:contains(room:getDrawPile():at(0)) then
			room:setPlayerFlag(player, "jieguanxing_allBottom")
		end
		return false
	end
}

jieguanxing_jiangweiYizhi = sgs.CreatePhaseChangeSkill{
	name = "jieguanxing_jiangweiYizhi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Start then
			return self:objectName()
		elseif skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("jieguanxing_allBottom") then
				return self:objectName()
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("guanxing", player)
			return true
		end
		return false
	end,

	on_phasechange = function(self, player)
		local room = player:getRoom()
		local gxPile = sgs.IntList()
		gxPile = room:getNCards(5)
		room:askForGuanxing(player, gxPile, sgs.Room_GuanxingBothSides)
		if not gxPile:contains(room:getDrawPile():at(0)) then
			room:setPlayerFlag(player, "jieguanxing_allBottom")
		end
		return false
	end
}

jiejiangwei:addSkill("tiaoxin")
jiejiangwei:addSkill("tianfu")
jiejiangwei:addSkill(jieyizhi)
if not sgs.Sanguosha:getSkill("jieguanxing_jiangwei") then skills:append(jieguanxing_jiangwei) end
if not sgs.Sanguosha:getSkill("jieguanxing_jiangweiYizhi") then skills:append(jieguanxing_jiangweiYizhi) end

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiejiangwei"] = "姜维",
    ["jieyizhi"] = "遗志",
	[":jieyizhi"] = "副将技，若你的主将没有技能“观星”，则你视为拥有“观星”，否则将其描述中的“（角色数小于等于3时改为三张）”删去。",
	["jieguanxing_jiangweiYizhi"] = "观星",
	[":jieguanxing_jiangweiYizhi"] = "准备阶段，你可以观看牌堆顶五张牌，将这些牌以任意顺序置于牌堆顶或牌堆底。若均置于牌堆底，则你可以" ..
	"于结束阶段再次发动此技能。",
	["jieguanxing_jiangwei"] = "观星",
	[":jieguanxing_jiangwei"] = "准备阶段，你可以观看牌堆顶五张牌（角色数小于等于3时改为三张），将这些牌以任意顺序置于牌堆顶" ..
	"或牌堆底。若均置于牌堆底，则你可以于结束阶段再次发动此技能。",
}

jiezuoci:addSkill("huashen")
jiezuoci:addSkill("xinsheng")

--[[jiehuangquan:addSkill("quanjian")
jiehuangquan:addSkill("tujue")

jiedaming = sgs.CreateTriggerSkill{
	name = "jiedaming",
	view_as_skill = jiedamingVS,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:getPhase() == sgs.Player_Play then
			local skill_owners = room:findPlayersBySkillName(self:objectName())
            local skill_list = {}
            local name_list = {}
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
				if skill_owner:isFriendWith(player) and not skill_owner:isKongcheng() then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
			end
			return table.concat(skill_list,"|"), table.concat(name_list,"|")
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
		if skill_owner:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), skill_owner)
            return true
        end
		return false
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
		local invoke = false
		invoke = (room:askForUseCard(skill_owner, "@@jiedaming_trick", "@jiedaming-discardTrick") ~= nil)
		if invoke and player:isAlive() and skill_owner:isAlive() then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@jiedaming-chooseChain", 
			false, true)
			if target and skill_owner:isAlive() then
				target:setChained(true)
				local kingdoms = {} --记录势力
				local i = 1
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isChained() then
						if p:getRole() == "careerist" then
							local kd = "ye" .. i
							i = i + 1
							table.insert(kingdoms, kd)
						elseif not table.contains(kingdoms, p:getKingdom()) then
							table.insert(kingdoms, p:getKingdom())
						end
					end
				end
				if #kingdoms > 0 then
					skill_owner:drawCards(#kingdoms, self:objectName())
				end
				local choice = room:askForChoice(player, self:objectName(), "jiedaming_recover+jiedaming_slash", data)
				local current = room:getCurrent()
				if choice == "jiedaming_recover" then
					if current:getLostHp() > 0 and current:canRecover() then
						local recover = sgs.RecoverStruct()
						recover.who = current
						recover.recover = 1
						room:recover(current, recover)
					end
				elseif choice == "jiedaming_slash" then
					local targets = sgs.SPlayerList()
					targets = room:getOtherPlayers(current)
					for _, p in sgs.qlist(targets) do
						if not current:canSlash(p, false) then
							targets:removeOne(p)
						end
					end
					local target_to = room:askForPlayerChosen(skill_owner, targets, self:objectName(), "@jiedaming_toSlash", 
					false, true)
					if target_to then
						local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("jiedaming")
						room:useCard(sgs.CardUseStruct(slash, current, target_to), false)
					end
				end
			end
		end
		return false
	end
}

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiepengyang"] = "彭羕",
    ["jiedaming"] = "达命",
	[":jiedaming"] = "与你势力相同的角色的出牌阶段开始时，你可以弃置一张锦囊牌，横置一名角色副将的武将牌，然后你摸X张牌（X为有处于" ..
	"“连环状态”的角色的势力数），若如此做，你选择一项：1.令当前回合角色回复1点体力；2.令当前回合角色视为对你选择的另一名角色" ..
	"使用一张不计入次数的雷【杀】。",
	["jiexiaoni"] = "嚣逆",
	[":jiexiaoni"] = "锁定技，当你使用牌指定目标后，或成为其他角色使用牌的目标后，若场上有与你势力相同的角色且你的手牌数是" ..
	"所属势力最多的，目标角色不能响应此牌。",
	["jiedaming_recover"] = "回复体力",
	["jiedaming_slash"] = "对另一名角色使用雷【杀】",
}]]

jieqizhi = sgs.CreateTriggerSkill{
	name = "jieqizhi",
	events = {sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and player:getPhase() ~= sgs.Player_NotActive and 
		player:getMark("#qizhi-turn") <= 3 then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeBasic or use.card:getTypeId() == sgs.Card_TypeTrick then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not use.to:contains(p) and (not p:isNude()) then
						return self:objectName()
					end
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		local use = data:toCardUse()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not use.to:contains(p) and (not p:isNude()) then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, targets, self:objectName(), "qizhi-invoke", true, true)
		if target then
			room:broadcastSkillInvoke("qizhi", player)
			room:addPlayerMark(player, "#qizhi-turn", 1)
			local d = sgs.QVariant()
            d:setValue(target)
            player:setTag("jieqizhi_target", d)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
		local target = player:getTag("jieqizhi_target"):toPlayer()
		if target and player:canDiscard(target, "he") then
			local card_id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
			room:throwCard(card_id, target, player)
			if target:isAlive() then
				target:drawCards(1, self:objectName())
			end
		end
		return false
	end
}

jiewangji:addSkill(jieqizhi)
jiewangji:addSkill("jinqu")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiewangji"] = "王基",
    ["jieqizhi"] = "奇制",
	[":jieqizhi"] = "当你于回合内使用非装备牌时，你可以弃置不为此牌目标的一名角色的一张牌，令其摸一张牌。每回合限四次。",
}

sgs.Sanguosha:addSkills(skills)

return {testToFix}

--[[
		local log = sgs.LogMessage()
		log.type = "readytodraw"
		log.from = player
		log.to:append(player)
		room:sendLog(log)
]]--