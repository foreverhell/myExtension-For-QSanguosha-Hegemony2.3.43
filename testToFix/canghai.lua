-- 创建扩展包  
canghai = sgs.Package("canghai",sgs.Package_GeneralPack)
sgs.LoadTranslationTable{["canghai"] = "沧海篇",}

--建立武将
--魏势力
luawangling = sgs.General(canghai, "luawangling", "wei", 4, true, false, true)

--蜀势力
--luaqinmi = sgs.General(canghai,"luaqinmi", "shu", 3)

--吴势力
luayufan = sgs.General(canghai, "luayufan", "wu", 3, true, false, true)
lualuotong = sgs.General(canghai, "lualuotong", "wu", 4, true, false, true)

--群势力
luajushou = sgs.General(canghai, "luajushou", "qun", 3, true, false, true)


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
                room:setPlayerMark(player, "luaxuyuan_noTarget", 1)
                room:setPlayerMark(player, "luaxuyuan_fail", 0)
                return false
            end
            local skill_owners = room:findPlayersBySkillName("luaxuyuan")
            local skill_list = {}
            local name_list = {}
            if skill_owners:isEmpty() then return false end
            for _, p in sgs.qlist(skill_owners) do
                if skillTriggerable(p, "luaxuyuan") and player:isFriendWith(p) then
                    table.insert(skill_list, self:objectName())
                    table.insert(name_list, p)
				end
			end
            if #name_list <= 0 then return false end
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                local current = room:getCurrent()
                if use.from ~= current then return false end
                for i = 1, #name_list do
                    local skill_owner = name_list[i]
                    if current:getMark("luaxuyuan_fail") == 0 and use.card:getTypeId() ~= sgs.Card_TypeSkill then
                        for _, p in sgs.qlist(use.to) do
                            if current:getMark("luaxuyuan_fail") > 0 then return false end
                            local if_sameTarget = player:getTag("luaxuyuan_sameTarget"):toPlayer()
                            if current:getMark("luaxuyuan_noTarget") > 0 or p == if_sameTarget then
                                local d = sgs.QVariant()
                                d:setValue(p)
                                player:setTag("luaxuyuan_sameTarget", d)
                                room:setPlayerMark(current, "luaxuyuan_noTarget", 0)
                            else
                                room:setPlayerMark(current, "luaxuyuan_fail", 1)
                                player:removeTag("luaxuyuan_sameTarget")
                                return false
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
                if skillTriggerable(p, "luaxuyuan") and player:isFriendWith(p) then
                    if player:getMark("luaxuyuan_fail") == 0 and player:getTag("luaxuyuan_sameTarget"):toPlayer() ~= "" then
                        player:removeTag("luaxuyuan_sameTarget")
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
        local choice = room:askForChoice(player, self:objectName(), "luashibei_get+luashibei_discard")
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
canghai:insertRelatedSkills("luaxuyuan", "#luaxuyuan_tag")

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
            room:doAnimate(1, player:objectName(), target:objectName())
            local before_handcard_ids = CardList2Table(target:getHandcards())
            room:drawCards(target, 1, "luazhiyan")
            local now_handcard_ids = CardList2Table(target:getHandcards())
            for i = #before_handcard_ids, 1, -1 do
                for j = #now_handcard_ids, 1, -1 do
                    if before_handcard_ids[i] == now_handcard_ids[j] then
                        table.remove(now_handcard_ids, j)
                    end
                end
            end
            room:showCard(target, Table2IntList(now_handcard_ids))
            for i = 1 , #now_handcard_ids do
                local card = sgs.Sanguosha:getCard(now_handcard_ids[i])
                if card:isKindOf("EquipCard") then
                    room:useCard(sgs.CardUseStruct(card, target, target), false)
                    local recover = sgs.RecoverStruct()
                    recover.who = target
                    recover.recover = 1
                    room:recover(target, recover)
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
canghai:insertRelatedSkills("luazongxuan", "#luazongxuan_remove")

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
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local suit_spade = "luaqinzheng_spade_suit"
        local suit_club = "luaqinzheng_club_suit"
        local suit_diamond = "luaqinzheng_diamond_suit"
        local suit_heart = "luaqinzheng_heart_suit"
        if player:getMark("luaqinzheng_type") == 7 and player:getMark("luaqinzheng_typeUsed") == 0 then
            room:broadcastSkillInvoke(self:objectName(), player)
            room:addPlayerMark(player, "luaqinzheng_typeUsed", 1)
            local Analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			Analeptic:setSkillName("_luaqinzheng")
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
            room:broadcastSkillInvoke(self:objectName(), player)
            if not target_to:isEmpty() then
                local target_player = room:askForPlayerChosen(player, target_to, self:objectName(),
                "@luaqinzheng_slashChoose", true, true)
                if target_player then
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    slash:setSkillName("_luaqinzheng")
                    room:useCard(sgs.CardUseStruct(slash, player, target_player), false)
                end
            end
        elseif player:getMark(suit_spade) == 1 and player:getMark(suit_club) == 1 and player:getMark(suit_diamond) == 1 and
        player:getMark(suit_heart) == 1 and player:getMark("luaqinzheng_suitUsed") == 0 then
            room:addPlayerMark(player, "luaqinzheng_suitUsed", 1)
            local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
            ex_nihilo:setSkillName("_luaqinzheng")
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
	[":luaqinzheng"] = "锁定技，你的回合内每项限一次，当你使用：\n 1.两种不同颜色的牌后，你视为使用一张不计入次数的【杀】；\n 2." ..
    "三种不同类别的手牌后，你视为使用一张不计入次数的【酒】；\n 3.四种不同花色的牌后，你视为使用一张【无中生有】。（若1、2同时触发" ..
    "则按2、1的顺序发动）",
    ["@luaqinzheng_slashChoose"] = "勤政：选择一名角色对其出【杀】",
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
canghai:insertRelatedSkills("luamibei", "#luamibei_cardUsed")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luawangling"] = "王凌",
    ["luamibei"] = "秘备",
	[":luamibei"] = "锁定技，准备阶段，若你手牌数不为全场最多，你令手牌最多的一名其他角色对你发起“军令”：若你执行，你摸牌至与其相同（至多" ..
    "摸至五张）；若你不执行，你展示一张手牌，本回合你使用此牌时弃置一张手牌，然后令此牌额外结算一次（不包括延时类锦囊、闪）。",
    ["@luamibei_command"] = "秘备：选择一名手牌数最多的其他角色对你发起军令",
    ["@luamibei_discard"] = "秘备：弃置一张手牌",
    ["#luamibeiExtra"] = "%from 发动了“%arg2”令 %arg1 额外结算一次。",
}

--[[luatianbian = sgs.CreateTriggerSkill{
    name = "luatianbian",
    events = {sgs.TargetConfirmed},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and event = sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                if use.to and use.to:contains(player) and not player:isKongcheng() and not use.from:isKongcheng() then
                    return self:objectName()
                elseif use.from and use.from == player and use.to then
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
            local target_to = sgs.SPlayerList()
            for _, p in sgs.qlist(use.to) do
                if not p:isKongcheng() then
                    target_to:append(p)
                end
            end
            if not target_to:isEmpty() then
                if player:askForSkillInvoke(self:objectName(), data) then
                    return true
                end
            end
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        if use.to and use.to:contains(player) then
            room:setPlayerFlag(player, "toluazhuandui")
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
                    room:setPlayerFlag(player, "toluazhuandui")
                end
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
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                local pd = data:toPindian()
                if pd.from_card:getSuitString() == "heart" then
                    pd.from_number = 13
                    data:setValue(pd)
                end
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
                if pd.from_number <= pd.to_number then
                    return false
                else
                    local use = data:toCardUse()
                    if use.to and use.to:contains(player) then
                        room:cancelTarget(use, player)
                    elseif use.from and use.from == player then

                    end
                end
            end
        end
        return false
    end,
}

luazhuandui = sgs.CreateTriggerSkill{
    name = "luazhuandui",
    events = {},
}

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luaqinmi"] = "秦宓",
    ["luatianbian"] = "天辩",
	[":luatianbian"] = "当你成为【杀】的目标后，你可以与使用者拼点，若你赢，此牌对你无效；当你使用【杀】指定目标后，你可以与其中一个目标" ..
    "拼点，若你赢，其不能响应此【杀】。",
    ["luazhuandui"] = "专对",
	[":luazhuandui"] = "当你拼点时，可以改为亮出牌堆顶的一张牌拼点；当你的拼点牌亮出后，若此牌的花色为红桃，则点数视为K。",
    ["@luatianbian_choose"] = "天辩：选择一名角色进行拼点",
}]]--

sgs.Sanguosha:addSkills(skills)

return {canghai}

--[[
		local log = sgs.LogMessage()
		log.type = "readytodraw"
		log.from = player
		log.to:append(player)
		room:sendLog(log)
]]--