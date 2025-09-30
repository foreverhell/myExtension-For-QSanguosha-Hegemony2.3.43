-- 创建扩展包  
canghaiz = sgs.Package("canghaiz",sgs.Package_GeneralPack)
sgs.LoadTranslationTable{["canghaiz"] = "沧海篇",}

--建立武将
--魏势力
luawangling = sgs.General(canghaiz, "luawangling", "wei", 4)
luacaozhi = sgs.General(canghaiz, "luacaozhi", "wei", 3)
--caomao = sgs.General(canghaiz, "caomao", "wei", 3)

--蜀势力
--luaqinmi = sgs.General(canghaiz,"luaqinmi", "shu", 3)

--吴势力
luayufan = sgs.General(canghaiz, "luayufan", "wu", 3)
lualuotong = sgs.General(canghaiz, "lualuotong", "wu", 4)

--群势力
luajushou = sgs.General(canghaiz, "luajushou", "qun", 3)
luahuangfusong = sgs.General(canghaiz, "luahuangfusong", "qun")



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

luaxuyuan_tag = sgs.CreateTriggerSkill{
    name = "#luaxuyuan_tag",
    events = {sgs.CardUsed, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then
            if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
                room:setPlayerMark(player, "luaxuyuan_fail", 0) --_fail==1即目标不同，没目标的情况由Flag判定
                return false
            end
            local skill_owners = room:findPlayersBySkillName("luaxuyuan")
            local skill_list = {}
            local name_list = {}
            if skill_owners:isEmpty() then return false end
            for _, p in sgs.qlist(skill_owners) do
                local current = room:getCurrent()
                if skillTriggerable(p, "luaxuyuan") and current:isFriendWith(p) then
                    table.insert(skill_list, "luaxuyuan")
                    table.insert(name_list, p:objectName())
				end
			end
            if #name_list <= 0 then return false end
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                local current = room:getCurrent()
                if use.from ~= current then return false end
                for i = 1, #name_list do
                    if current:getMark("luaxuyuan_fail") == 0 and use.card:getTypeId() ~= sgs.Card_TypeSkill then
                        for _, p in sgs.qlist(use.to) do
                            if current:getMark("luaxuyuan_fail") > 0 then return false end
                            if not p:hasFlag("luaxuyuan_hasTarget") then
                                local hasOtherTarget = false
                                for _, sp in sgs.qlist(room:getOtherPlayers(p)) do
                                    if sp:hasFlag("luaxuyuan_hasTarget") then
                                        hasOtherTarget = true
                                        break
                                    end
                                end
                                if hasOtherTarget then
                                    room:setPlayerMark(current, "luaxuyuan_fail", 1)
                                else
                                    room:setPlayerFlag(p, "luaxuyuan_hasTarget")
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
}

luaxuyuan = sgs.CreateTriggerSkill{
    name = "luaxuyuan",
    events = {sgs.EventPhaseEnd},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:getPhase() == sgs.Player_Finish and event == sgs.EventPhaseEnd then
            local skill_owners = room:findPlayersBySkillName("luaxuyuan")
            local skill_list = {}
            local name_list = {}
            if skill_owners:isEmpty() then return false end
            for _, p in sgs.qlist(skill_owners) do
                if skillTriggerable(p, "luaxuyuan") and player:isFriendWith(p) and not p:isNude() then
                    if player:getMark("luaxuyuan_fail") == 0 then
                        local hasTarget = false
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if p:hasFlag("luaxuyuan_hasTarget") then
                                hasTarget = true
                                break
                            end
                        end
                        if not hasTarget then return false end
                        table.insert(skill_list, self:objectName())
                        table.insert(name_list, p)
                    end
				end
			end
            return table.concat(skill_list,"|"), table.concat(name_list,"|")
        end
        return false
    end,

    on_cost = function(self, event, room, player, data, skill_owner)
        if skill_owner:askForSkillInvoke(self:objectName(), data) then
            room:askForDiscard(skill_owner, self:objectName(), 1, 1, false, true)
            room:broadcastSkillInvoke(self:objectName(), skill_owner)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, skill_owner)
        local choices = {"luaxuyuan_draw", "luaxuyuan_play", "luaxuyuan_both"}
        local choice = room:askForChoice(skill_owner, "luaxuyuan_choice", table.concat(choices, "+"), data, 
        "@luaxuyuan-choose::" .. player:objectName(), "luaxuyuan_draw+luaxuyuan_play+luaxuyuan_both")
        if choice == "luaxuyuan_draw" then
            local phases = sgs.PhaseList()
            phases:append(sgs.Player_Draw)
            phases:append(sgs.Player_NotActive)
            player:play(phases)
        elseif choice == "luaxuyuan_play" then
            local phases = sgs.PhaseList()
            phases:append(sgs.Player_Play)
            phases:append(sgs.Player_NotActive)
            player:play(phases)
        elseif choice == "luaxuyuan_both" then
            room:detachSkillFromPlayer(skill_owner, "luaxuyuan")
            room:detachSkillFromPlayer(skill_owner, "luaxuyuan", false, false, false)
            local phases = sgs.PhaseList()
            phases:append(sgs.Player_Draw)
            phases:append(sgs.Player_Play)
            phases:append(sgs.Player_NotActive)
            player:play(phases)
        end
        return false
    end
}

luashibei = sgs.CreateMasochismSkill{
    name = "luashibei",
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then 
            return self:objectName()
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

    on_damaged = function(self, player, damage)
        local room = player:getRoom()
        local choices = {"luashibei_get", "luashibei_discard"}
        local choice = room:askForChoice(player, self:objectName(), "luashibei_get+luashibei_discard", data)
        if choice == "luashibei_get" then
            local source = damage.from
            if source and source:isAlive() then
                local equipcards = source:getEquips()
                local horse_ids = sgs.IntList()
                --if off_horse then horse_ids:append(off_horse:getId()) end
                --if def_horse then horse_ids:append(def_horse:getId()) end
                for _, card in sgs.qlist(equipcards) do
                    if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse")  or card:isKindOf("SixDragons") then
                        horse_ids:append(card:getId())
                    end
                end
                if horse_ids:isEmpty() then return false end
                -- 使用AG界面让玩家选择一张牌  
                room:fillAG(horse_ids, player)
                local horse_id = room:askForAG(player, horse_ids, true, self:objectName())
                room:clearAG(player)
                if horse_id < 0 then return false end
                room:obtainCard(player, horse_id ,true)
            end
        elseif choice == "luashibei_discard" then
            local handcards = player:getHandcards()
            local equipcards = player:getEquips()
            local horse_ids = sgs.IntList()
            --if off_horse then horse_ids:append(off_horse:getId()) end
            --if def_horse then horse_ids:append(def_horse:getId()) end
            for _, card in sgs.qlist(handcards) do
                if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse") or card:isKindOf("SixDragons") then
                    horse_ids:append(card:getId())
                end
            end
            for _, card in sgs.qlist(equipcards) do
                if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse") or card:isKindOf("SixDragons") then
                    horse_ids:append(card:getId())
                end
            end
            if horse_ids:isEmpty() then return false end
            -- 使用AG界面让玩家选择一张牌  
            room:fillAG(horse_ids, player)
            local horse_id = room:askForAG(player, horse_ids, true, self:objectName())
            room:clearAG(player)
            if horse_id < 0 then return false end
            room:throwCard(horse_id, player, player)
            local recover = sgs.RecoverStruct()
            recover.who = player
            recover.recover = 1
            room:recover(player, recover)
        end
        return false
    end
}

luajushou:addSkill(luaxuyuan)
luajushou:addSkill(luaxuyuan_tag)
luajushou:addSkill(luashibei)
canghaiz:insertRelatedSkills("luaxuyuan", "#luaxuyuan_tag")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luajushou"] = "沮授",
    ["luaxuyuan"] = "徐圆",
	[":luaxuyuan"] = "与你势力相同的角色回合结束时，若其本回合使用过的牌均指定相同目标，你可以弃置一张牌，令其执行一个额外的摸牌或出牌"..
    "阶段；你可以失去此技能并改为令其两个阶段均执行。",
	["luashibei"] = "矢北",
	[":luashibei"] = "当你受到伤害后，你可以获得伤害来源装备区一张坐骑牌，或弃置一张坐骑牌并回复1点体力。",
    ["@luaxuyuan-choose"] = "徐圆：选择令%dest执行的效果",
    ["luaxuyuan_choice:luaxuyuan_draw"] = "摸牌阶段",
	["luaxuyuan_choice:luaxuyuan_play"] = "出牌阶段",
    ["luaxuyuan_choice:luaxuyuan_both"] = "失去该技能，两个阶段均执行",
    ["luashibei_get"] = "获得伤害来源的坐骑牌",
	["luashibei_discard"] = "弃置一张坐骑牌并回复1点体力",
    ["$luaxuyuan1"] = "良谋百出，渐定决战胜势！",
    ["$luaxuyuan2"] = "佳策数成，破敌垂手可得！",
    ["$luashibei1"] = "主公在北，吾心亦在北！",
	["$luashibei2"] = "宁向北而死，不面南而生。",
    --["~luajushou"] = "",
}

luazhiyan = sgs.CreateTriggerSkill{
    name = "luazhiyan",
    --frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart, sgs.Player_Finish},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
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
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            targets:append(p)
        end
        if not targets:isEmpty() then
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@luazhiyan_target", true, true)
            if target then
                room:doAnimate(1, player:objectName(), target:objectName())
                local card_id = room:drawCard()
                local card = sgs.Sanguosha:getCard(card_id)
                room:obtainCard(target, card, false)
                if not target:isAlive() then return false end
                room:showCard(target, card_id)
                if card:isKindOf("EquipCard") then
                    if not target:isCardLimited(card, sgs.Card_MethodUse, true) then
                        room:useCard(sgs.CardUseStruct(card, target, target), true)
                        if target:isWounded() then
                            local recover = sgs.RecoverStruct()
                            recover.who = target
                            recover.recover = 1
                            room:recover(target, recover)
                        end
                    end
                end
            end
        end
        return false
    end
}

luazongxuan_remove = sgs.CreateTriggerSkill{
    name = "#luazongxuan_remove",
    events = {sgs.TurnStart, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and event == sgs.EventPhaseStart and player:getPhase() == sgs.TurnStart then
            local skill_owners = room:findPlayersBySkillName("luazongxuan")
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, "luazongxuan") and skill_owner:getMark("luazongxuan_discard") > 0 then
                    room:setPlayerMark(skill_owner, "luazongxuan_discard", 0)
                end
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        return false
    end,
}

luazongxuan = sgs.CreateTriggerSkill{
    name = "luazongxuan",
    events = {sgs.CardsMoveOneTime}, 
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            if player:getMark("luazongxuan_discard") < 3 then
                local move_datas = data:toList()
                local skill_list = {}
                for _, move_data in sgs.qlist(move_datas) do
                    local move = move_data:toMoveOneTime()
                    if move.from and move.from:objectName() ~= player:objectName() then return "" end
                    if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == 
                    sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
                            table.insert(skill_list, self:objectName())
                        end
                    end
                end
                return table.concat(skill_list, ",")
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
        local move_datas = data:toList()
        for _, move_data in sgs.qlist(move_datas) do
            local hasPut = player:getMark("luazongxuan_discard")
            if hasPut >= 3 then return false end
            local move = move_data:toMoveOneTime()
            if move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand) or 
            move.from_places:contains(sgs.Player_PlaceEquip)) then
                local moveStruct = sgs.AskForMoveCardsStruct() --自定义观星模板
                moveStruct = room:askForMoveCards(player, move.card_ids, sgs.IntList(), true, self:objectName(), "", "_" ..
                self:objectName(), 0, math.min(3 - hasPut, move.card_ids:length()), false, false)
                local putPile_ids = sgs.IntList()
                putPile_ids = moveStruct.bottom
                room:addPlayerMark(player, "luazongxuan_discard", putPile_ids:length())
                local drawPile = room:getDrawPile()
                for i = putPile_ids:length(), 1, -1 do
                    --room:moveCardTo(sgs.Sanguosha:getCard(putPile_ids:at(i - 1)), nil, sgs.Player_DrawPile, false)
                    drawPile:prepend(putPile_ids:at(i - 1))
                end
                room:doBroadcastNotify(sgs.CommandType.S_COMMAND_UPDATE_PILE, sgs.QVariant(drawPile:length()))
            end
        end
        return false
    end
}

luayufan:addSkill(luazhiyan)
luayufan:addSkill(luazongxuan)
luayufan:addSkill(luazongxuan_remove)
canghaiz:insertRelatedSkills("luazongxuan", "#luazongxuan_remove")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luayufan"] = "虞翻",
    ["luazhiyan"] = "直言",
	[":luazhiyan"] = "结束阶段，你可以令一名角色摸一张牌并展示之，若为装备牌，其使用之并回复1点体力。",
	["luazongxuan"] = "纵玄",
	[":luazongxuan"] = "当你的牌因弃置而进入弃牌堆时，你可以将任意张牌以任意顺序置于牌堆顶（每回合限三张）。",
    ["@luazhiyan_target"] = "直言：选择一名角色",
    ["@luazongxuan"] = "底部为放入牌堆顶",
    ["luazongxuan#up"] = "放入弃牌堆",
    ["luazongxuan#down"] = "放入牌堆顶",
    ["$luazongxuan1"] = "近日之事，吾心里有谱。",
    ["$luazongxuan2"] = "我来为将军算上一卦。",
    ["$luazhiyan1"] = "此事，将军请听我一言！",
	["$luazhiyan2"] = "还望主公多斟酌一番！",
    ["~luayufan"] = "还是，顺应天意吧！",
}


luaqinzheng = sgs.CreateTriggerSkill{
    name = "luaqinzheng",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardFinished, sgs.TurnStart, sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() ~= sgs.Player_NotActive and event == sgs.CardFinished then
            local use = data:toCardUse()
            local suit = use.card:getSuitString()
            local suit_mark = "luaqinzheng_" .. suit .. "_suit" --能直接返回花色，就不用数字标记法了
            local suit_spade = "luaqinzheng_spade_suit"
            local suit_club = "luaqinzheng_club_suit"
            local suit_diamond = "luaqinzheng_diamond_suit"
            local suit_heart = "luaqinzheng_heart_suit"
            local skill_list = {}
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and (not use.card:isKindOf("ThreatenEmperor")) then
                if player:getMark("luaqinzheng_type") < 7 and player:getMark("luaqinzheng_typeUsed") == 0 then --0无类别，1基本，2锦囊，4装备
                    if use.card:getTypeId() == sgs.Card_TypeBasic and player:getMark("luaqinzheng_type") ~= 1 
                    and player:getMark("luaqinzheng_type") ~= 3 and player:getMark("luaqinzheng_type") ~= 5 then
                        room:addPlayerMark(player, "luaqinzheng_type", 1)
                    elseif use.card:getTypeId() == sgs.Card_TypeTrick and player:getMark("luaqinzheng_type") ~= 2 
                    and player:getMark("luaqinzheng_type") ~= 3 and player:getMark("luaqinzheng_type") ~= 6 then
                        room:addPlayerMark(player, "luaqinzheng_type", 2)
                    elseif use.card:getTypeId() == sgs.Card_TypeEquip and player:getMark("luaqinzheng_type") < 4 then
                        room:addPlayerMark(player, "luaqinzheng_type", 4)
                    end
                end
                if player:getMark("luaqinzheng_color") < 3 or player:getMark("luaqinzheng_color") == 4 and 
                player:getMark("luaqinzheng_colorUsed") == 0 then --0没有记录颜色，1黑色，2红色，4无色
                    if use.card:isBlack() and player:getMark("luaqinzheng_color") ~= 1 then 
                        room:addPlayerMark(player, "luaqinzheng_color", 1)
                    elseif use.card:isRed() and player:getMark("luaqinzheng_color") ~= 2 then
                        room:addPlayerMark(player, "luaqinzheng_color", 2)
                    elseif not use.card:isBlack() and not use.card:isRed() and player:getMark("luaqinzheng_color") <= 2 then --不是4才可以加4
                        room:addPlayerMark(player, "luaqinzheng_color", 4)
                    end
                end
                if player:getMark(suit_mark) == 0 and player:getMark("luaqinzheng_suitUsed") == 0 then
                    room:addPlayerMark(player, suit_mark, 1)
                end
            end
            if player:getMark("luaqinzheng_type") == 7 and player:getMark("luaqinzheng_typeUsed") == 0 then
                table.insert(skill_list, self:objectName())
            end
            if (player:getMark("luaqinzheng_color") == 3 or player:getMark("luaqinzheng_color") > 4) and 
            player:getMark("luaqinzheng_colorUsed") == 0 then
                table.insert(skill_list, self:objectName())
            end
            if player:getMark(suit_spade) == 1 and player:getMark(suit_club) == 1 and player:getMark(suit_diamond) == 1 and
            player:getMark(suit_heart) == 1 and player:getMark("luaqinzheng_suitUsed") == 0 then
                table.insert(skill_list, self:objectName())
            end
            return table.concat(skill_list, ",")
        elseif player and player:isAlive() and player:getPhase() == sgs.TurnStart and event == sgs.EventPhaseStart then
            local skill_owners = room:findPlayersBySkillName("luaqinzheng")
            local suit_spade = "luaqinzheng_spade_suit"
            local suit_club = "luaqinzheng_club_suit"
            local suit_diamond = "luaqinzheng_diamond_suit"
            local suit_heart = "luaqinzheng_heart_suit"
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, "luaqinzheng") then
                    room:setPlayerMark(skill_owner, "luaqinzheng_type" , 0)
                    room:setPlayerMark(skill_owner, "luaqinzheng_typeUsed" , 0)
                    room:setPlayerMark(skill_owner, "luaqinzheng_color" , 0)
                    room:setPlayerMark(skill_owner, "luaqinzheng_colorUsed" , 0)
                    room:setPlayerMark(skill_owner, suit_spade, 0)
                    room:setPlayerMark(skill_owner, suit_club, 0)
                    room:setPlayerMark(skill_owner, suit_diamond, 0)
                    room:setPlayerMark(skill_owner, suit_heart, 0)
                    room:setPlayerMark(skill_owner, "luaqinzheng_suitUsed", 0)
                end
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        if not player:hasShownSkill("luaqinzheng") then
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
        local suit_spade = "luaqinzheng_spade_suit"
        local suit_club = "luaqinzheng_club_suit"
        local suit_diamond = "luaqinzheng_diamond_suit"
        local suit_heart = "luaqinzheng_heart_suit"
        if player:getMark("luaqinzheng_type") == 7 and player:getMark("luaqinzheng_typeUsed") == 0 then
            room:addPlayerMark(player, "luaqinzheng_typeUsed", 1)
            local Analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			Analeptic:setSkillName("luaqinzheng")
			room:useCard(sgs.CardUseStruct(Analeptic, player, player), false)
        elseif (player:getMark("luaqinzheng_color") == 3 or player:getMark("luaqinzheng_color") > 4) and 
        player:getMark("luaqinzheng_colorUsed") == 0 then
            room:addPlayerMark(player, "luaqinzheng_colorUsed", 1)
            local target_to = sgs.SPlayerList() --获取除选择目标的其他角色
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:canSlash(p, true) then
                    target_to:append(p)
                end
            end
            if not target_to:isEmpty() then
                local target_player = room:askForPlayerChosen(player, target_to, self:objectName(),
                "@luaqinzheng_slashChoose", true, true)
                if target_player then
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    slash:setSkillName("luaqinzheng")
                    room:useCard(sgs.CardUseStruct(slash, player, target_player), false)
                end
            end
        elseif player:getMark(suit_spade) == 1 and player:getMark(suit_club) == 1 and player:getMark(suit_diamond) == 1 and
        player:getMark(suit_heart) == 1 and player:getMark("luaqinzheng_suitUsed") == 0 then
            room:addPlayerMark(player, "luaqinzheng_suitUsed", 1)
            local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
            ex_nihilo:setSkillName("luaqinzheng")
            room:useCard(sgs.CardUseStruct(ex_nihilo, player, player), false)
        end
        return false
    end
}

lualuotong:addSkill(luaqinzheng)

-- 加载翻译表
sgs.LoadTranslationTable{
    ["lualuotong"] = "骆统",
    ["luaqinzheng"] = "勤政",
	[":luaqinzheng"] = "锁定技，你的回合内每项限一次，当你使用：\n 1.两种不同颜色的牌后，你可以视为使用一张不计入次数的【杀】；\n 2." ..
    "三种不同类别的手牌后，你视为使用一张不计入次数的【酒】；\n 3.四种不同花色的牌后，你视为使用一张【无中生有】。（若1、2同时触发" ..
    "则按2、1的顺序发动）",
    ["@luaqinzheng_slashChoose"] = "勤政：选择一名角色对其出【杀】",
    ["$luaqinzheng1"] = "夫国之有民，犹水之有舟，停则以安，扰则以危。",
	["$luaqinzheng2"] = "治疾及其未笃，除患贵其莫深。",
    ["~lualuotong"] = "臣统之大愿，足以死而不朽矣。",
}

luamibei = sgs.CreateTriggerSkill{
    name = "luamibei",
    events = {sgs.EventPhaseStart, sgs.Player_Start, sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local players_overHand = sgs.SPlayerList()
            local selfHandNum = player:getHandcardNum()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() >= selfHandNum then
                    players_overHand:append(p)
                end
            end
            if not players_overHand:isEmpty() then 
                return self:objectName() 
            end
            return false
        end
    end,

    on_cost = function(self, event, room, player, data)
        if not player:hasShownSkill("luamibei") then
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
        local players_overHand = sgs.SPlayerList()
        local players_overSelf = sgs.SPlayerList()
        local selfHandNum = player:getHandcardNum()
        local maxnum = selfHandNum
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getHandcardNum() >= maxnum then
                maxnum = p:getHandcardNum()
                players_overHand:append(p)
            end
        end
        for _, p in sgs.qlist(players_overHand) do
            if p:getHandcardNum() >= maxnum then
                players_overSelf:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, players_overSelf, self:objectName(), "@luamibei_command", true, true)
        if target then
            if not target:askCommandto(self:objectName(), player) then
                if player:isKongcheng() then return false end
                local card = room:askForCardShow(player, player, self:objectName())
                room:showCard(player, card:getId())
                if card:isKindOf("Jink") or card:isKindOf("DelayedTrick") then return false end
                card:setTag("luamibeiRecord", sgs.QVariant(1))
                room:setPlayerFlag(player, "luamibeiNoCommand")
            else
                local actualHandNum_player = player:getHandcardNum()
                local actualHandNum_target = target:getHandcardNum()
                if actualHandNum_player >= 5 then return false end
                player:drawCards(math.min(actualHandNum_target - actualHandNum_player, 5 - actualHandNum_player), self:objectName())
            end
        end
        return false
    end
}

luamibei_cardUsed = sgs.CreateTriggerSkill{
    name = "#luamibei_cardUsed",
    events = {sgs.CardUsed,sgs.TurnStart,sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player:hasFlag("luamibeiNoCommand") and event == sgs.CardUsed and player:getPhase() ~= sgs.Player_NotActive then
            local use = data:toCardUse()
            if use.card:getTag("luamibeiRecord"):toInt() == 1 and not player:isKongcheng() then
                room:askForDiscard(player, self:objectName(), 1, 1, false, false, "@luamibei_discard")
                use.card:removeTag("luamibeiRecord")
                room:useCard(sgs.CardUseStruct(use.card, use.from, use.to), false)
                local msg = sgs.LogMessage()
                msg.type = "#luamibeiExtra"
                msg.from = player
                msg.arg = use.card
                msg.arg2 = self:objectName()
                room:sendLog(msg)
            end
        elseif player:getPhase() == sgs.TurnStart and event == sgs.EventPhaseStart then
            local skill_owners = room:findPlayersBySkillName("luamibei")
            for _, skill_owner in sgs.qlist(skill_owners) do
                local cards = CardList2Table(player:getHandcards())
                for _, card in pairs(cards) do
                    if card.getTag("luamibeiRecord"):toInt() == 1 then
                        card:removeTag("luamibeiRecord")
                        return false
                    end
                end
            end
        end
        return false
    end,
}

luawangling:addSkill(luamibei)
luawangling:addSkill(luamibei_cardUsed)
canghaiz:insertRelatedSkills("luamibei", "#luamibei_cardUsed")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luawangling"] = "王凌",
    ["luamibei"] = "秘备",
	[":luamibei"] = "锁定技，准备阶段，若你手牌数不为全场最多，你令手牌最多的一名其他角色对你发起“军令”：若你执行，你摸牌至与其相同（至多" ..
    "摸至五张）；若你不执行，你展示一张手牌，本回合你使用此牌时弃置一张手牌，然后令此牌额外结算一次（不包括延时类锦囊、闪）。",
    ["@luamibei_command"] = "秘备：选择一名手牌数最多的其他角色对你发起军令",
    ["@luamibei_discard"] = "秘备：弃置一张手牌",
    ["#luamibeiExtra"] = "%from 发动了“%arg2”令 %arg1 额外结算一次。",
    ["$luamibei1"] = "密为之备，不可有失。",
	["$luamibei2"] = "事以密成，语以泄败！",
    ["~luawangling"] = "一生尽忠事魏，不料，今日晚节尽毁啊！",
}

--[[luatianbian = sgs.CreateTriggerSkill{
    name = "luatianbian",
    events = {sgs.CardUsed, sgs.TargetConfirming},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and (event == sgs.TargetConfirming or event == sgs.CardUsed) then
            local use = data:toCardUse()
            if use and use.card and use.card:isKindOf("Slash") then
                if event == sgs.TargetConfirming and use.to and use.to:contains(player) and not player:isKongcheng() and not 
                use.from:isKongcheng() then
                    return self:objectName()
                elseif event == sgs.CardUsed and use.from and use.from == player and use.to and not player:isKongcheng() then
                    for _, target in sgs.qlist(use.to) do
                        if not target:isKongcheng() then
                            return self:objectName()
                        end
                    end
                end

            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        local use = data:toCardUse()
        if use.to and use.to:contains(player) then
            if player:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke("luatianbian", player)
                room:doAnimate(1, player:objectName(), use.from:objectName())
                return true
            end
        elseif use.from and use.from == player and use.to then
            if player:askForSkillInvoke(self:objectName(), data) then
                return true
            end
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        local pdTarget = nil
        if use.to and use.to:contains(player) then
            pdTarget = use.from
        elseif use.from and use.from == player then
            local target_to = sgs.SPlayerList()
            for _, p in sgs.qlist(use.to) do
                if not p:isKongcheng() then
                    target_to:append(p)
                end
            end
            if not target_to:isEmpty() then
                local target = room:askForPlayerChosen(player, target_to, self:objectName(), "@luatianbian_choose", true, true)
                if target then
                    room:broadcastSkillInvoke("luatianbian", player)
                    pdTarget = target
                end
            end
        end
        if pdTarget then
            --local d = sgs.QVariant()
            --d:setValue(use)
            player:setTag("luatianbianData", data)
            if player:askForSkillInvoke("luazhuandui", data) then
                local card_id = room:drawCard()
                --room:setPlayerMark(player, "luatianbian_pdCard", card_id)
                local pd = player:pindianSelect(pdTarget, "luatianbian", sgs.Sanguosha:getCard(card_id))
                player:pindian(pd, 1)
            else
                player:pindian(pdTarget, "luatianbian")
            end
        end
        return false
    end
}

luatianbian_verify = sgs.CreateTriggerSkill{
    name = "#luatianbian_verify",
    frequency = sgs.Skill_Frequent,
    events = {sgs.PindianVerifying},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and event == sgs.PindianVerifying then
            local pd = data:toPindian()
            if pd.reason == "luatianbian" and pd.from_card:getSuitString() == "heart" then
                pd.from_number = 13
                data:setValue(pd)
            end
        end
        return false
    end,
}

luatianbian_effect = sgs.CreateTriggerSkill{
    name = "#luatianbian_effect",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Pindian},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and event == sgs.Pindian then
            local pd = data:toPindian()
            if pd.reason == "luatianbian" then
                if pd.success then
                    local use = player:getTag("luatianbianData"):toCardUse()
                    player:removeTag("luatianbianData")
                    if use and use.to and use.to:contains(player) then
                        local log = sgs.LogMessage()
		log.type = "why3"
		log.from = player
		log.to:append(player)
		room:sendLog(log)
                        room:cancelTarget(use, player)
                        data:setValue(use)
                    elseif use and use.from and use.from == player then
                        local nullified_list = {}
                        table.insert(nullified_list, pd.to:objectName())
                        use.nullified_list = nullified_list
                        data:setValue(use)
                        local log = sgs.LogMessage()
		log.type = "why4"
		log.from = player
		log.to:append(player)
		room:sendLog(log)
                    end
                end
            end
        end
        return false
    end,
}

luazhuandui = sgs.CreateTriggerSkill{
    name = "luazhuandui",
}

luaqinmi:addSkill(luatianbian)
luaqinmi:addSkill(luazhuandui)
luaqinmi:addSkill(luatianbian_verify)
luaqinmi:addSkill(luatianbian_effect)
canghaiz:insertRelatedSkills("luatianbian", "#luatianbian_verify")
canghaiz:insertRelatedSkills("luatianbian", "#luatianbian_effect")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luaqinmi"] = "秦宓",
    ["luatianbian"] = "天辩",
	[":luatianbian"] = "当你成为【杀】的目标时，你可以与使用者拼点，若你赢，此牌对你无效；当你使用【杀】指定目标后，你可以与其中一个目标" ..
    "拼点，若你赢，其不能响应此【杀】。",
    ["luazhuandui"] = "专对",
	[":luazhuandui"] = "当你拼点时，可以改为亮出牌堆顶的一张牌拼点；当你的拼点牌亮出后，若此牌的花色为红桃，则点数视为K。",
    ["@luatianbian_choose"] = "天辩：选择一名角色进行拼点",
}]]

lualuoying = sgs.CreateTriggerSkill{
    name = "lualuoying",
    events = {sgs.CardsMoveOneTime, sgs.FinishJudge},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            local move_datas = data:toList()
            for _, move_data in sgs.qlist(move_datas) do
                local move = move_data:toMoveOneTime()
                local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                if move.from and move.from:objectName() == player:objectName() then return "" end
                if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                    if move.to_place == sgs.Player_DiscardPile then
                        for _, card_id in sgs.qlist(move.card_ids) do
                            if sgs.Sanguosha:getCard(card_id):getSuitString() == "club" and room:getCardPlace(card_id) == 
                            sgs.Player_DiscardPile then
                                return self:objectName()
                            end
                        end
                    end
                elseif reasonx == sgs.CardMoveReason_S_REASON_PUT then
                    local card_id = player:getTag("lualuoyingJudge_club"):toInt()
                    if card_id ~= 0 and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                        return self:objectName()
                    else
                        player:removeTag("lualuoyingJudge_club")
                    end
                end
            end
        elseif player and player:isAlive() and event == sgs.FinishJudge then
            local judge = data:toJudge()
            local skill_owners = room:findPlayersBySkillName(self:objectName())
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if judge.card:getSuitString() == "club" and judge.who:objectName() ~= skill_owner:objectName() then
                    local d = sgs.QVariant()
                    d:setValue(judge.card:getEffectiveId())
                    skill_owner:setTag("lualuoyingJudge_club", d)
                end
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        else
            player:removeTag("lualuoyingJudge_club")
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local move_datas = data:toList()
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
            if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                for _, card_id in sgs.qlist(move.card_ids) do
                    if sgs.Sanguosha:getCard(card_id):getSuitString() == "club" then
                        room:obtainCard(player, card_id, true)
                    end
                end
            elseif reasonx == sgs.CardMoveReason_S_REASON_PUT then
                room:obtainCard(player, player:getTag("lualuoyingJudge_club"):toInt(), true)
                player:removeTag("lualuoyingJudge_club")
            end
        end
        return false
    end
}

luajiushi = sgs.CreateZeroCardViewAsSkill{
    name = "luajiushi",
    view_as = function(self)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		return analeptic
	end,
    enabled_at_play = function(self, player)
		return player:hasShownAllGenerals() and sgs.Analeptic_IsAvailable(player)
	end,
    enabled_at_response = function(self, player, pattern)
        return player:hasShownAllGenerals() and string.find(pattern, "analeptic")
    end
}

luajiushiDamaged = sgs.CreateTriggerSkill{
    name = "#luajiushiDamaged",
    events = {sgs.DamageInflicted, sgs.CardUsed, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return false end
            local skill_owners = room:findPlayersBySkillName("luajiushi")
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                room:setPlayerMark(skill_owner, "##luajiushi", 0)
            end
		end
	end,
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            if player:hasFlag("luajiushiUsed") and event == sgs.DamageInflicted then
                local isHead
                if player:getActualGeneral2Name() == "luacaozhi" then
                    isHead = false
                elseif player:getActualGeneral1Name() == "luacaozhi" then
                    isHead = true
                end
                if isHead ~= nil then --防止“化身”移除武将
                    player:removeGeneral(isHead)
                end
            elseif event == sgs.CardUsed then
                local use = data:toCardUse()
                if use and use.card:getSkillName() == "luajiushi" then  
                    room:setPlayerFlag(player, "luajiushiUsed")
                    room:addPlayerHistory(player, "Analeptic", 1)
                    room:broadcastSkillInvoke("luajiushi", player)
                    room:addPlayerMark(player, "##luajiushi")
                    local isHead
                    if player:getActualGeneral2Name() == "luacaozhi" then
                        isHead = false
                    elseif player:getActualGeneral1Name() == "luacaozhi" then
                        isHead = true
                    end
                    if isHead ~= nil then
                        player:hideGeneral(isHead)
                    end
                end
            end
        end
        return false
    end,
}

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luacaozhi"] = "曹植",
    ["lualuoying"] = "落英",
	[":lualuoying"] = "当其他角色的♣牌因弃置或判定而进入弃牌堆时，你可以获得之。",
    ["luajiushi"] = "酒诗",
	[":luajiushi"] = "每回合限一次，当你需要使用【酒】时，若你武将牌均明置，你可以暗置此武将牌并视为使用之，然后当你本回合下次受到伤害时，"..
    "移除此武将牌。",
    ["$lualuoying1"] = "绿蚁洗墨锋，入喉酒香浓。",
	["$lualuoying2"] = "新酒赋旧词，墨香正醉人。",
    ["$luajiushi1"] = "花落白宣上，秉笔有天工。",
	["$luajiushi2"] = "泼墨染秋意，落花亦有情。",
    ["~luacaozhi"] = "酒醉不知归路，唯见星河漫天。",
}

luacaozhi:addSkill(luajiushi)
luacaozhi:addSkill(lualuoying)
luacaozhi:addSkill(luajiushiDamaged)
canghaiz:insertRelatedSkills("luajiushi", "#luajiushiDamaged")

-- 潜龙技能  
--[[qianlong = sgs.CreateTriggerSkill{  
    name = "qianlong",  
    events = {sgs.Damaged},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local lost_hp = player:getLostHp() 
        local cards = room:getNCards(3, false)  
         
        local to_get = {}  
        local moveStruct = sgs.AskForMoveCardsStruct() --自定义观星模板
        moveStruct = room:askForMoveCards(player, cards, sgs.IntList(), true, self:objectName(), "", "_" ..
        self:objectName(), 0, lost_hp, false, false)
        local obtainPile_ids = sgs.IntList()
        obtainPile_ids = moveStruct.bottom
        if obtainPile_ids:length() > 0 then
            local dummy = sgs.DummyCard(obtainPile_ids)  
            player:obtainCard(dummy)
            dummy:deleteLater()
        end
        local putPile_ids = sgs.IntList()
        putPile_ids = moveStruct.top
        local drawPile = room:getDrawPile()
        if putPile_ids:length() > 0 then
            for _, id in sgs.qlist(putPile_ids) do
                room:throwCard(id, player)
            end
        end
        room:doBroadcastNotify(sgs.CommandType.S_COMMAND_UPDATE_PILE, sgs.QVariant(drawPile:length()))
        --[[for i = 1, math.min(lost_hp, 3) do  
            room:fillAG(cards, player) 
            local card_id = room:askForAG(player, cards, true, self:objectName())  
            if card_id == -1 then 
                room:clearAG(player)
                break
            end  
            table.insert(to_get, card_id)  
            cards:removeOne(card_id)  
            room:clearAG(player)
        end  
          
        if #to_get > 0 then  
            local dummy = sgs.DummyCard()  
            for _, id in ipairs(to_get) do  
                dummy:addSubcard(id)  
            end  
            player:obtainCard(dummy)  
        end  
          
        -- 将剩余的牌放回牌堆顶  
        for _, id in sgs.qlist(cards) do  
            room:returnToTopDrawPile(id)  
        end
          
        return false  
    end  
}  
  
-- 忿肆技能  
fensi = sgs.CreateTriggerSkill{  
    name = "fensi",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
           and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getHp() >= player:getHp() then  
                targets:append(p)  
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@fensi-choose", true, true)  
          
        if target and target:isAlive() then  
            local damage = sgs.DamageStruct()  
            damage.from = player  
            damage.to = target  
            damage.damage = 1  
            room:damage(damage)  
              
            if target:objectName() ~= player:objectName() and target:isAlive() then  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)  
                slash:setSkillName(self:objectName())  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = target  
                use.to:append(player)  
                room:useCard(use, false)  
            end  
        end  
          
        return false  
    end  
}  
  
caomao:addSkill(qianlong)  
caomao:addSkill(fensi)

sgs.LoadTranslationTable{
    ["caomao"] = "曹髦",  
    ["#caomao"] = "高贵乡公",  
    ["qianlong"] = "潜龙",  
    [":qianlong"] = "当你受到伤害后，你可以展示牌堆顶的三张牌，然后获得其中至多X张（X为已失去的体力值），弃置未获得的牌。",  
    ["fensi"] = "忿肆",  
    [":fensi"] = "回合开始时，你可以对一名体力值大于等于你的角色造成1点伤害，若其不为你，其视为对你使用一张杀。",  
    ["@fensi-choose"] = "忿肆：选择一名体力值大于等于你的角色",
    ["@qianlong"] = "潜龙：获得至多X张牌（X为你已损失的体力值）",
    ["qianlong#up"] = "放入弃牌堆",
    ["qianlong#down"] = "获得的牌",
}]]

luafenyueCard = sgs.CreateSkillCard{
    name = "luafenyueCard",
    skill_name = "luafenyue",
	will_throw = false,
	filter = function(self, targets, to_select, Self)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= Self:objectName() and not 
		to_select:isRemoved()
	end,
	on_use = function(self, room, source, targets)
    	room:broadcastSkillInvoke("luafenyue", source)
        room:addPlayerMark(source, "#luafenyue_times", 1)
		source:pindian(targets[1], "luafenyue")
	end
}

luafenyue = sgs.CreateZeroCardViewAsSkill{
	name = "luafenyue",
	view_as = function(self)
        local card = luafenyueCard:clone()
        card:setSkillName(self:objectName())
		card:setShowSkill(self:objectName())
        return card
    end,
      
    enabled_at_play = function(self, player)
        local x = getKingdoms(player, false)
        return not player:hasFlag("luafenyue_fail") and not player:isKongcheng() and player:getMark("#luafenyue_times")
        < x
    end
}

luafenyuePindian = sgs.CreateTriggerSkill{
	name = "#luafenyuePindian",
	events = {sgs.Pindian, sgs.CardUsed, sgs.EventPhaseChanging},
	frequency = sgs.Skill_Frequent,
    on_record = function(self, event, room, player, data)
		if event == sgs.CardUsed and skillTriggerable(player, "luafenyue") then
			local use = data:toCardUse()
            if use and (use.card:getTypeId() == sgs.Card_TypeEquip or use.card:getTypeId() == sgs.Card_TypeTrick) then
                room:setPlayerFlag(player, "luafenyue_fail")
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Play then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("##boyan") > 0 then
                        room:setPlayerMark(p, "##boyan", 0)
                    end
                    if p:getMark("#luafenyue_times") > 0 then
                        room:setPlayerMark(p, "#luafenyue_times", 0)
                    end
                end
            end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "luafenyue" then
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
		local pdFrom = pindian.from
		local pdTo = pindian.to
		if pindian.success then
            if pdFrom:isDead() or pdTo:isDead() then return false end
            local choice = room:askForChoice(pdFrom, "luafenyue", "luafenyue_boyan+luafenyue_slash", data)
            if choice == "luafenyue_boyan" then
                room:setPlayerCardLimitation(pdTo, "use,response", ".|.|.|hand", true)
                room:addPlayerMark(pdTo, "##boyan")
            elseif choice == "luafenyue_slash" then
                local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
                slash:setSkillName("luafenyue")
                room:useCard(sgs.CardUseStruct(slash, pdFrom, pdTo), false)
                slash:deleteLater()
            end
		else
			room:setPlayerFlag(pdFrom, "luafenyue_fail")
		end
		return false
	end
}

luahuangfusong:addSkill(luafenyue)
luahuangfusong:addSkill(luafenyuePindian)
canghaiz:insertRelatedSkills("luafenyue", "#luafenyuePindian")

sgs.LoadTranslationTable{
    ["luahuangfusong"] = "皇甫嵩",  
    ["luafenyue"] = "奋钺",
    [":luafenyue"] = "出牌阶段限X次（X为场上势力数），若此阶段你未使用过非基本牌，你可以与一名角色拼点，若你赢，你选择一项：" ..
    "\n1.其不能使用或打出手牌直到回合结束；\n2.视为你对其使用了一张雷【杀】（不计入次数限制）。\n若你没赢，本回合你不可再发动此技能。",
    ["luafenyue_times"] = "奋钺",
    ["luafenyue_boyan"] = "令其本回合不能使用或打出手牌",
    ["luafenyue_slash"] = "对其使用一张雷【杀】",
    ["$luafenyue1"] = "逆贼势大，且扎营寨，击其懈怠。",
    ["$luafenyue2"] = "兵有其变，不在众寡。",
    ["~luahuangfusong"] = "力有所能，臣必为也……",
}

sgs.Sanguosha:addSkills(skills)

return {canghaiz}

--[[
		local log = sgs.LogMessage()
		log.type = "readytodraw"
		log.from = player
		log.to:append(player)
		room:sendLog(log)
]]--