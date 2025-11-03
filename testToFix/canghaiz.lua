-- 创建扩展包  
canghaiz = sgs.Package("canghaiz",sgs.Package_GeneralPack)
sgs.LoadTranslationTable{["canghaiz"] = "沧海篇",}

--建立武将
--魏势力
luawangling = sgs.General(canghaiz, "luawangling", "wei")
luacaozhi = sgs.General(canghaiz, "luacaozhi", "wei", 3)
luachenqun = sgs.General(canghaiz, "luachenqun", "wei", 3)
lualitong = sgs.General(canghaiz, "lualitong", "wei")
luacaochun = sgs.General(canghaiz, "luacaochun", "wei")

--蜀势力
--luaqinmi = sgs.General(canghaiz,"luaqinmi", "shu", 3)
luawuban = sgs.General(canghaiz, "luawuban", "shu")
luadongyun = sgs.General(canghaiz, "luadongyun", "shu", 3)

--吴势力
luayufan = sgs.General(canghaiz, "luayufan", "wu", 3)
lualuotong = sgs.General(canghaiz, "lualuotong", "wu")

--群势力
luajushou = sgs.General(canghaiz, "luajushou", "qun", 3)
luahuangfusong = sgs.General(canghaiz, "luahuangfusong", "qun")
luachengong = sgs.General(canghaiz, "luachengong", "qun", 3)


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
                if (not current:hasShownOneGeneral()) or current:isFriendWith(p) then --这么写是考虑到暗将可能是队友的情况
                    if skillTriggerable(p, "luaxuyuan") then
                        table.insert(skill_list, "luaxuyuan")
                        table.insert(name_list, p:objectName())
                    end
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
            local skill_owners = room:findPlayersBySkillName(self:objectName())
            local skill_list = {}
            local name_list = {}
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, "luaxuyuan") and player:isFriendWith(skill_owner) and not 
                skill_owner:isNude() then
                    if player:getMark("luaxuyuan_fail") <= 0 then
                        local hasTarget = false
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if p:hasFlag("luaxuyuan_hasTarget") then
                                hasTarget = true
                                break
                            end
                        end
                        if not hasTarget then return false end
                        table.insert(skill_list, self:objectName())
                        table.insert(name_list, skill_owner:objectName())
                    end
				end
			end
            if #name_list > 0 then
                return table.concat(skill_list, "|"), table.concat(name_list, "|")
            end
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
        local d = sgs.QVariant()
        d:setValue(damage.from)
        local choice = room:askForChoice(player, self:objectName(), "luashibei_get+luashibei_discard", d)
        if choice == "luashibei_get" then
            local source = damage.from
            if source and source:isAlive() then
                local equipcards = source:getEquips()
                local horse_ids = sgs.IntList()
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
            local Analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
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
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    slash:setSkillName("luaqinzheng")
                    room:useCard(sgs.CardUseStruct(slash, player, target_player), false)
                end
            end
        elseif player:getMark(suit_spade) == 1 and player:getMark(suit_club) == 1 and player:getMark(suit_diamond) == 1 and
        player:getMark(suit_heart) == 1 and player:getMark("luaqinzheng_suitUsed") == 0 then
            room:addPlayerMark(player, "luaqinzheng_suitUsed", 1)
            local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, -1)
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
                if p:getHandcardNum() > selfHandNum then
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
        local target = room:askForPlayerChosen(player, players_overSelf, self:objectName(), "@luamibei_command", false, true)
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
            if use.card:getTag("luamibeiRecord") and use.card:getTag("luamibeiRecord"):toInt() == 1 and not player:isKongcheng() then
                room:askForDiscard(player, self:objectName(), 1, 1, false, false, "@luamibei_discard")
                use.card:removeTag("luamibeiRecord")
                room:setPlayerFlag(player, "-luamibeiNoCommand")
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
                    if sgs.Sanguosha:getCard(card).getTag("luamibeiRecord") and 
                    sgs.Sanguosha:getCard(card).getTag("luamibeiRecord"):toInt() == 1 then
                        sgs.Sanguosha:getCard(card):removeTag("luamibeiRecord")
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
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                for _, card_id in sgs.qlist(move.card_ids) do
                    if sgs.Sanguosha:getCard(card_id):getSuitString() == "club" and card_id ~= 144 then --敕令弃牌时应直接进入弃牌堆替换成诏令
                        dummy:addSubcard(card_id)
                    end
                end
                room:obtainCard(player, dummy, true)
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
    response_or_use = true,
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
    events = {sgs.DamageInflicted, sgs.EventPhaseChanging, sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return false end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("##luajiushi") > 0 then
                    room:setPlayerMark(p, "##luajiushi", 0)
                end
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
                room:setPlayerMark(p, "##luajiushi", 0)
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

luafenyueCard = sgs.CreateSkillCard{
    name = "luafenyueCard",
    skill_name = "luafenyue",
	will_throw = false,
	filter = function(self, targets, to_select, Self)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= Self:objectName()
	end,
	on_use = function(self, room, source, targets)
    	--room:broadcastSkillInvoke("luafenyue", source)
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
        return not player:hasFlag("luafenyue_fail") and not player:isKongcheng() and player:getMark("#luafenyue_times") < x
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
            local d = sgs.QVariant()
            d:setValue(pdTo)
            local choice = room:askForChoice(pdFrom, "luafenyue", "luafenyue_boyan+luafenyue_slash", d)
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

luajintaoCard = sgs.CreateSkillCard{
    name = "luajintaoCard",
	skill_name = "luajintaoVS",
    will_throw = false,
	handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select, Self)
        return #targets == 0 and to_select:objectName() ~= Self:objectName() and 
        Self:distanceTo(to_select) == self:subcardsLength()
    end,
    on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:addSubcard(self)
        slash:setSkillName("luajintao")
        slash:deleteLater()
        room:useCard(sgs.CardUseStruct(slash, source, targets[1]), false)
    end
}

luajintaoVS = sgs.CreateViewAsSkill{
    name = "luajintaoVS",
    response_pattern = "@@luajintaoVS",
    view_filter = function(self, selected, to_select)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:deleteLater()
        return slash:isAvailable(sgs.Self)
	end,

    view_as = function(self, cards)
		if #cards > 0 then
            local slashCard = luajintaoCard:clone()
            for _, c in pairs(cards) do
                slashCard:addSubcard(c:getId())
            end
            slashCard:setSkillName("luajintao")
            return slashCard
        end
	end,
}

luajintao = sgs.CreatePhaseChangeSkill{
    name = "luajintao",
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Play and not
        player:isNude() then
            return self:objectName()
        end
		return false
	end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            room:askForUseCard(player, "@@luajintaoVS", "@luajintao-toSlash")
            return true
        end
        return false
    end,

    on_phasechange = function(self, player)
        return false
    end
}

luajintaoDraw = sgs.CreateTriggerSkill{
    name = "#luajintaoDraw",
    events = {sgs.Damage},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, "luajintao") then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "luajintao" then
                player:drawCards(damage.card:subcardsLength(), "luajintao")
            end
        end
        return false
    end
}

luawuban:addSkill(luajintao)
luawuban:addSkill(luajintaoDraw)
canghaiz:insertRelatedSkills("luajintao", "#luajintaoDraw")

if not sgs.Sanguosha:getSkill("luajintaoVS") then skills:append(luajintaoVS) end

sgs.LoadTranslationTable{
    ["luawuban"] = "吴班",  
    ["luajintao"] = "进讨",
    [":luajintao"] = "出牌阶段开始时，你可以将X张牌当一张不计入次数的【杀】对一名其他角色使用，若此【杀】造成伤害，你摸X张牌（X为你与其的距离）。",
    ["@luajintao-toSlash"] = "进讨：选择X张牌与一名其他角色（X为你与其的距离）",
    ["$luajintao1"] = "引兵进讨，断不负丞相之望！",
    ["$luajintao2"] = "举兵出征，以期北伐建功！",
    ["~luawuban"] = "汉室倾颓，匡复无望……",
}

luachengxu = sgs.CreateTriggerSkill{
    name = "luachengxu",
    events = {sgs.CardsMoveOneTime, sgs.PostHpReduced, sgs.EventPhaseStart, sgs.QuitDying},
    on_record = function(self, event, room, player, data)
        if player and player:isAlive() and event == sgs.EventPhaseStart then
			for _, firstPlayer in sgs.qlist(room:getAlivePlayers()) do
				if player ~= firstPlayer then return false end
                if firstPlayer:getPhase() == sgs.Player_Finish and firstPlayer:getMark("ThreatenEmperorExtraTurn") > 0 then
                    room:setPlayerMark(firstPlayer, "teExtraTurn", 1)
                end --开挟天子不算新的轮次
				if not firstPlayer:hasFlag("fangquanInvoked") and firstPlayer:getMark("teExtraTurn") <= 0 and 
                firstPlayer:getPhase() == sgs.TurnStart then
					local skill_owners = room:findPlayersBySkillName("luachengxu")
					if skill_owners:isEmpty() then return false end
					for _, skill_owner in sgs.qlist(skill_owners) do
						room:setPlayerMark(skill_owner, "luachengxu_slash", 1)
                        room:setPlayerMark(skill_owner, "luachengxu_discard", 1)
                        room:setPlayerMark(skill_owner, "teExtraTurn", 0)
					end
					break
                elseif firstPlayer:getPhase() == sgs.TurnStart then
                    room:setPlayerMark(firstPlayer, "teExtraTurn", 0)
				end
			end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then
            local isChengxu_slash, isChengxu_discard = false
            if event == sgs.CardsMoveOneTime then
                local move_datas = data:toList()
                for _, move_data in sgs.qlist(move_datas) do
                    local move = move_data:toMoveOneTime()
                    if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand)) 
                    or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand) then
                        if player:getHandcardNum() == 1 then isChengxu_discard = true end
                    end
                end
            elseif event == sgs.PostHpReduced or event == sgs.QuitDying then
                local damage = data:toDamage()
                local loseHp = data:toInt()
                local dying = data:toDying()
                if (damage or loseHp or dying) and player:getHp() == 1 then isChengxu_slash = true end
            end
            if isChengxu_discard or isChengxu_slash then
                local skill_owners = room:findPlayersBySkillName(self:objectName())
                for _, skill_owner in sgs.qlist(skill_owners) do
                    if skill_owner:objectName() ~= player:objectName() and isChengxu_slash and 
                    skill_owner:getMark("luachengxu_slash") > 0 and skill_owner:canSlash(player, false) then
                        room:setPlayerFlag(skill_owner, "luachengxu2slash") --给AI传数据
                        local d = sgs.QVariant()
                        d:setValue(player)
                        skill_owner:setTag("luachengxu2slash", d)
                        return self:objectName(), skill_owner
                    elseif skill_owner:objectName() ~= player:objectName() and isChengxu_discard and 
                    skill_owner:getMark("luachengxu_discard") > 0 and skill_owner:canDiscard(player, "he") then
                        room:setPlayerFlag(skill_owner, "luachengxu2discard") --给AI传数据
                        local d = sgs.QVariant()
                        d:setValue(player)
                        skill_owner:setTag("luachengxu2discard", d)
                        return self:objectName(), skill_owner
                    end
                end
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data, skill_owner)
        if skill_owner:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), skill_owner)
            room:doAnimate(1, skill_owner:objectName(), player:objectName())
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, skill_owner)
        if event == sgs.CardsMoveOneTime and skill_owner:getMark("luachengxu_discard") > 0 then
            skill_owner:removeTag("luachengxu2discard")
            room:setPlayerMark(skill_owner, "luachengxu_discard", 0)
            local id = room:askForCardChosen(skill_owner, player, "he", self:objectName(), false, sgs.Card_MethodDiscard)
            room:throwCard(id, player, skill_owner)
            if player:isAlive() and player:canDiscard(skill_owner, "he") and not skill_owner:isNude() then
                local choices = {"yes", "no"}
                local d = sgs.QVariant()
                d:setValue(skill_owner)
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), d, "@luachengxu-discard::".. 
                skill_owner:objectName(), "yes+no")
                if choice == "yes" then
                    room:broadcastSkillInvoke("luachengxu", skill_owner)
                    room:doAnimate(1, player:objectName(), skill_owner:objectName())
                    local id2 = room:askForCardChosen(player, skill_owner, "he", self:objectName(), false, sgs.Card_MethodDiscard)
                    room:throwCard(id2, skill_owner, player)
                end
            end
        elseif (event == sgs.PostHpReduced or event == sgs.QuitDying) and skill_owner:getMark("luachengxu_slash") > 0 then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            slash:deleteLater()
            room:setPlayerMark(skill_owner, "luachengxu_slash", 0)
            skill_owner:removeTag("luachengxu2slash")
            room:useCard(sgs.CardUseStruct(slash, skill_owner, player), false)
            if player:isAlive() and player:canSlash(skill_owner, false) then
                local choices = {"yes", "no"}
                local d = sgs.QVariant()
                d:setValue(skill_owner)
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), d, "@luachengxu-slash::".. 
                skill_owner:objectName(), "yes+no")
                if choice == "yes" then
                    room:broadcastSkillInvoke("luachengxu", skill_owner)
                    room:useCard(sgs.CardUseStruct(slash, player, skill_owner), false)
                end
            end
        end
        return false
    end
}

luazhichi = sgs.CreateTriggerSkill{
    name = "luazhichi",
    events = {sgs.CardsMoveOneTime, sgs.TargetConfirming, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_record = function(self, event, room, player, data)
        if player and player:isAlive() and player:getPhase() == sgs.TurnStart then
            local skill_owners = room:findPlayersBySkillName("luazhichi")
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                room:setPlayerMark(skill_owner, "luazhichi_cards", 0)
                room:setPlayerMark(skill_owner, "luazhichi_times", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_NotActive then
            if event == sgs.CardsMoveOneTime and player:getMark("luazhichi_cards") < 2 then
                local move_datas = data:toList()
                for _, move_data in sgs.qlist(move_datas) do
                    local move = move_data:toMoveOneTime()
                    if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or 
                    move.from_places:contains(sgs.Player_PlaceEquip)) then
                        room:addPlayerMark(player, "luazhichi_cards", 1)
                        if player:getMark("luazhichi_cards") == 2 then
                            return self:objectName()
                        end
                    end
                end
            elseif event == sgs.TargetConfirming and player:getMark("luazhichi_times") < 2 then
                local use = data:toCardUse()
                local damageCard = {"Slash", "Duel", "ArcheryAttack", "SavageAssault", "BurningCamps", "Drowning", "FireAttack"}
                for i = 1, #damageCard do
                    if use.card and use.card:isKindOf(damageCard[i]) and not use.card:hasFlag("luazhichiMark") then
                        room:addPlayerMark(player, "luazhichi_times", 1)
                        use.card:setFlags("luazhichiMark")
                        if player:getMark("luazhichi_times") == 2 then
                            return self:objectName()
                        end
                        break
                    end
                end
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
		if not player:hasShownSkill("luazhichi") then
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
        if event == sgs.CardsMoveOneTime and player:getMark("luazhichi_cards") == 2 then
            player:drawCards(1, self:objectName())
        elseif event == sgs.TargetConfirming and player:getMark("luazhichi_times") == 2 then
            local use = data:toCardUse()
            sgs.Room_cancelTarget(use, player)
            data:setValue(use)
        end
        return false
    end
}

luachengong:addSkill(luachengxu)
luachengong:addSkill(luazhichi)

sgs.LoadTranslationTable{
    ["luachengong"] = "陈宫",  
    ["luachengxu"] = "乘虚",
    [":luachengxu"] = "每轮每项各限一次，当一名其他角色的手牌数/体力值变为1后，若没有角色处于濒死状态，你可以弃置其一张牌/视为对其使用一张【杀】，" ..
    "然后其可以弃置你一张牌/视为对你使用一张【杀】。",
    ["luazhichi"] = "智迟",
    [":luazhichi"] = "锁定技，当你于回合外每回合第二次：失去牌后，你摸一张牌；成为伤害牌的目标时，取消之。",
    ["@luachengxu-slash"] = "乘虚：是否对%dest视为使用一张【杀】",
    ["@luachengxu-discard"] = "乘虚：是否弃置%dest一张牌",
    ["$luachengxu1"] = "既有可乘之隙，何必失此良机？",
    ["$luachengxu2"] = "今敌军远来疲惫，将军可速战之。",
    ["$luazhichi1"] = "此地不便久留，不若另寻他处。",
    ["$luazhichi2"] = "暂退三舍，再做计议。",
    ["~luachengong"] = "只恨，当年未能一剑杀了你！",
}

luabingzheng = sgs.CreateTriggerSkill{  
    name = "luabingzheng",  
    events = {sgs.EventPhaseStart},  
      
    can_trigger = function(self, event, room, player, data)  
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)
        -- 找出手牌数不等于体力值的角色  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getHandcardNum() ~= p:getHp() then  
                targets:append(p)  
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@luabingzheng-target", true, true)  
        if target then
            room:broadcastSkillInvoke(self:objectName(), player)
            player:setTag("BingzhengTarget", sgs.QVariant(target:objectName()))  
            return true  
        end  
          
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local target_name = player:getTag("BingzhengTarget"):toString()   
        local target = room:findPlayer(target_name)  
          
        if not target or target:isDead() then return false end

        --target没手牌时默认摸牌
        local choice
        if target:isKongcheng() then
            choice = "luabingzhengDraw"
        else
            -- 选择摸牌或弃牌  
            choice = room:askForChoice(player, self:objectName(), "luabingzhengDraw+luabingzhengDiscard", data)
        end
          
        if choice == "luabingzhengDraw" then  
            room:drawCards(target, 1, self:objectName())  
        elseif choice == "luabingzhengDiscard" then
            if not target:isKongcheng() then  
                room:askForDiscard(target, self:objectName(), 1, 1, false, false, "@luabingzheng_forceDiscard")  
            end  
        end  
          
        -- 检查手牌数是否等于体力值  
        if target:getHandcardNum() == target:getHp() then  
            room:drawCards(player, 1, self:objectName())
            --选择是否交给target一张牌
            if target:objectName() ~= player:objectName() and not player:isNude() then
                local result = room:askForExchange(player, "luabingzheng_give", 1, 0, "@luabingzheng-give::" .. target:objectName(), "", ".|.|.|.")
                if not result:isEmpty() then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), "")
					local move = sgs.CardsMoveStruct(result, target, sgs.Player_PlaceHand, reason)
					room:moveCardsAtomic(move, false)
				end
            end
        end
        player:removeTag("BingzhengTarget") 
          
        return false  
    end  
}

luasheyan = sgs.CreateTriggerSkill{
    name = "luasheyan",
    events = {sgs.TargetConfirming},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            local use = data:toCardUse()
            if use.card and use.card:isNDTrick() and use.to:contains(player) and not player:hasFlag("luasheyanUsed") and
            use.card:getTypeId() ~= sgs.Card_TypeSkill then
                room:setPlayerFlag(player, "luasheyanUsed")
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
        local use = data:toCardUse()
        if use.card:isKindOf("ThreatenEmperor") then return false end
        local targets = room:getUseExtraTargets(use, false) --获得卡牌其他的合法目标
        for _, p in sgs.qlist(use.to) do
            if p:isAlive() then
                targets:append(p)
            end
        end
        if not targets:isEmpty() then
            local prompt = "@luasheyan-target:" .. use.from:objectName() .. "::" .. use.card:objectName()
            if use.to:length() == 1 then --即只有自己成为目标，只能增加目标
                targets:removeOne(player)
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), prompt, true, true)
            if target then
                room:doAnimate(1, player:objectName(), target:objectName())
                if use.to:contains(target) then
                    sgs.Room_cancelTarget(use, target)
                else
                    use.to:append(target)
                    room:sortByActionOrder(use.to)
                end
                data:setValue(use)
            end
        end
        return false
    end
}

luadongyun:addSkill(luabingzheng)
luadongyun:addSkill(luasheyan)

sgs.LoadTranslationTable{
    ["luadongyun"] = "董允",  
    ["luabingzheng"] = "秉正",
    [":luabingzheng"] = "回合结束时，你可以令一名手牌数不等于体力值的角色摸一张牌或弃置一张手牌，然后若其手牌数等于体力值，你摸一张牌且可以" ..
    "交给其一张牌。",
    ["luasheyan"] = "舍宴",
    [":luasheyan"] = "当你每回合首次成为普通锦囊牌的目标时，你可以令此牌的目标增加或减少一个目标（目标数至少为1）。",
    ["@luabingzheng_forceDiscard"] = "秉正：弃置一张手牌",
    ["@luabingzheng-target"] = "秉正：选择一名目标",
    ["luabingzhengDraw"] = "令其摸一张牌",
    ["luabingzhengDiscard"] = "令其弃置一张牌",
    ["@luabingzheng-give"] = "秉正：是否交给%dest一张牌",
    ["@luasheyan-target"] = "舍宴：选择为%src使用的【%arg】增加或减少一个目标",
    ["$luabingzheng1"] = "自古，就是邪不胜正！",
    ["$luabingzheng2"] = "主公面前，岂容小人搬弄是非！",
    ["$luasheyan1"] = "公事为重，宴席不去也罢。 ",
    ["$luasheyan2"] = "还是改日吧。",
    ["~luadongyun"] = "大汉，要亡于宦官之手了。",
}

luapindiCard = sgs.CreateSkillCard{
    name = "luapindiCard",
    skill_name = "luapindi",
    filter = function(self, targets, to_select, Self)
		return #targets == 0 and to_select:objectName() ~= Self:objectName() and not 
        to_select:hasFlag("luapindiUsed_" .. Self:objectName())
	end,
	on_use = function(self, room, source, targets)
        if not source:hasSkill("huashen") then
            room:addPlayerMark(source, "@luapindiTimes", 1)
        end
        room:setPlayerFlag(targets[1], "luapindiUsed_" .. source:objectName())
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        if card:getTypeId() == sgs.Card_TypeBasic then
            room:setPlayerFlag(source, "luapindiBasic")
        elseif card:getTypeId() == sgs.Card_TypeTrick then
            room:setPlayerFlag(source, "luapindiTrick")
        elseif card:getTypeId() == sgs.Card_TypeEquip then
            room:setPlayerFlag(source, "luapindiEquip")
        end
		local choice
        local x = source:getMark("@luapindiTimes")
        if targets[1]:isNude() then --target无牌则默认摸牌
            choice = "d1tx"
        else
            choice = room:askForChoice(source, "luapindi", "d1tx%log:" .. x .. "+dxt1%log:" .. x)
        end

        if string.find(choice, "d1tx") then
            targets[1]:drawCards(x)
        elseif string.find(choice, "dxt1") then
            room:askForDiscard(targets[1], "luapindi", x, x, false, true)
        end
        if source:isAlive() and targets[1]:getLostHp() > 0 and not source:isChained() then
            --横置,要serverplayer类型
            room:setPlayerProperty(getServerPlayer(room, source:objectName()), "chained", sgs.QVariant(true))
        end
	end
}

luapindiVS = sgs.CreateOneCardViewAsSkill{
    name = "luapindiVS",
    response_pattern = "@@luapindiVS",
    view_filter = function(self, card)
        if sgs.Self:hasFlag("luapindiBasic") and card:getTypeId() == sgs.Card_TypeBasic then
            return false
        end
        if sgs.Self:hasFlag("luapindiTrick") and card:getTypeId() == sgs.Card_TypeTrick then
            return false
        end
        if sgs.Self:hasFlag("luapindiEquip") and card:getTypeId() == sgs.Card_TypeEquip then
            return false
        end
        return true
    end,

    view_as = function(self, card)
        local skillCard = luapindiCard:clone()
        skillCard:addSubcard(card:getId())
        skillCard:setSkillName("luapindi")
		skillCard:setShowSkill("luapindi")
        return skillCard
    end,
}

luapindi = sgs.CreateOneCardViewAsSkill{
    name = "luapindi",
    view_filter = function(self, card)
        if sgs.Self:hasFlag("luapindiBasic") and card:getTypeId() == sgs.Card_TypeBasic then
            return false
        end
        if sgs.Self:hasFlag("luapindiTrick") and card:getTypeId() == sgs.Card_TypeTrick then
            return false
        end
        if sgs.Self:hasFlag("luapindiEquip") and card:getTypeId() == sgs.Card_TypeEquip then
            return false
        end
        return true
    end,

    view_as = function(self, card)
        local skillCard = luapindiCard:clone()
        skillCard:addSubcard(card:getId())
        skillCard:setSkillName(self:objectName())
		skillCard:setShowSkill(self:objectName())
        return skillCard
    end
}

luapindiDamaged = sgs.CreateTriggerSkill{
    name = "#luapindiDamaged",
    events = {sgs.Damaged, sgs.EventPhaseChanging},

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local skill_owners = room:findPlayersBySkillName(self:objectName())
                if skill_owners:isEmpty() then return false end
                for _, skill_owner in sgs.qlist(skill_owners) do
                    if skillTriggerable(skill_owner, self:objectName()) then
                        room:setPlayerMark(skill_owner, "@luapindiTimes", 0)
                    end
                end
            end
        end
        return false
    end,

    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and not player:isNude() and event == sgs.Damaged then
			return self:objectName()
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("luapindi", player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
        room:askForUseCard(player, "@@luapindiVS", "@luapindi-toDiscard")
        return false
    end
}

luafaen = sgs.CreateTriggerSkill{
    name = "luafaen",
    events = {sgs.TurnedOver, sgs.ChainStateChanged},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then
            if event == sgs.ChainStateChanged and not player:isChained() then return false end
            local skill_owners = room:findPlayersBySkillName(self:objectName())
			local skill_list = {}
			local name_list = {}
			if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, self:objectName()) then
                    table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
            end
            return table.concat(skill_list, "|"), table.concat(name_list, "|")
        end
        return false
    end,

    on_cost = function(self, event, room, player, data, skill_owner)
        local choices = {"yes", "no"}
        local d = sgs.QVariant()
        d:setValue(player)
        local choice = room:askForChoice(skill_owner, self:objectName(), table.concat(choices, "+"), d, "@luafaen-draw::".. 
        player:objectName(), "yes+no")
        if choice == "yes" then
            room:broadcastSkillInvoke("luafaen", skill_owner)
            room:doAnimate(1, skill_owner:objectName(), player:objectName())
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, skill_owner)
        player:drawCards(1)
        return false
    end
}

luachenqun:addSkill(luafaen)
luachenqun:addSkill(luapindi)
luachenqun:addSkill(luapindiDamaged)
canghaiz:insertRelatedSkills("luapindi", "#luapindiDamaged")

if not sgs.Sanguosha:getSkill("luapindiVS") then skills:append(luapindiVS) end

sgs.LoadTranslationTable{
    ["luachenqun"] = "陈群",
    ["luapindi"] = "品第",
    [":luapindi"] = "出牌阶段或当你受到伤害后，你可以弃置一张本回合未以此法选择过的类别牌，令一名本回合未以此法选择过的其他角色摸或弃置X" ..
    "张牌（X为你本回合发动此技能的次数）。若其已受伤，你横置。",
    ["luafaen"] = "法恩",
    [":luafaen"] = "有角色横置或叠置后，你可以令其摸一张牌。",
    ["#luapindiDamaged"] = "品第",
    ["@luapindi-toDiscard"] = "品第:弃置一张牌并选择一名其他角色",
    ["@luafaen-draw"] = "法恩：是否令%dest摸一张牌",
    ["luapindi:d1tx"] = "令其摸 %log 张牌",
    ["luapindi:dxt1"] = "令其弃置 %log 张牌",
    ["$luapindi1"] = "观其风气，查其品行。",
    ["$luapindi2"] = "推举贤才，兴盛大魏。",
    ["$luafaen1"] = "礼法容情，皇恩浩荡。 ",
    ["$luafaen2"] = "法理有度，恩威并施。",
    ["~luachenqun"] = "吾身虽陨，典律昭昭。",
}

luatuifeng = sgs.CreateTriggerSkill{
    name = "luatuifeng",
    events = {sgs.Damaged, sgs.Damage, sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardFinished},
    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            local skill_owners = room:findPlayersBySkillName(self:objectName())
            if skill_owners:isEmpty() or change.to ~= sgs.Player_NotActive then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, self:objectName()) then
                    room:setPlayerMark(skill_owner, "##luatuifeng", 0)
                end
            end
        elseif event == sgs.Damage and skillTriggerable(player, self:objectName()) then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("luatuifengSlash") then
                room:askForQiaobian(player, room:getAlivePlayers(), self:objectName(), "@luatuifeng-move", true, true)
            end
        elseif skillTriggerable(player, self:objectName()) and event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and player:hasFlag("luatuifengUseSlash") and not 
            player:hasFlag("luatuifengNoSlash") then
                room:setPlayerFlag(player, "-luatuifengUseSlash")
                use.card:setFlags("luatuifengSlash")
            end
        elseif skillTriggerable(player, self:objectName()) and event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and player:hasFlag("luatuifengUseSlash") then
                room:setPlayerFlag(player, "-luatuifengUseSlash")
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and (event == sgs.Damaged or event == sgs.Damage) and 
        player:getMark("##luatuifeng") < 1 and not player:isNude() then
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
        local card_id = room:askForDiscard(player, self:objectName(), 1, 1, false, true)
        if card_id then
            room:setPlayerMark(player, "##luatuifeng", 1)
        end
        return false
    end
}

luatuifengEffect = sgs.CreateTriggerSkill{
    name = "#luatuifengEffect",
    events = {sgs.EventPhaseStart},
    
    can_trigger = function(self, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Finish then
            local skill_owners = room:findPlayersBySkillName("luatuifeng")
			local skill_list = {}
			local name_list = {}
			if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, "luatuifeng") and skill_owner:getMark("##luatuifeng") > 0 then
                    table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
            end
            return table.concat(skill_list, "|"), table.concat(name_list, "|")
		end
		return false
	end,

	on_cost = function(self, event, room, player, data, skill_owner)
        room:broadcastSkillInvoke("luatuifeng", skill_owner)
		return true
	end,

	on_effect = function(self, event, room, player, data, skill_owner)
        room:setPlayerFlag(skill_owner, "luatuifengUseSlash")
        --执行后会优先触发CardUsed事件，不继续向下执行代码，故判断逻辑写得较为复杂
        local is_slash = room:askForUseSlashTo(skill_owner, room:getOtherPlayers(skill_owner), "@luatuifeng-slash", true)
        if not is_slash then
            skill_owner:drawCards(2)
            room:setPlayerFlag(skill_owner, "luatuifengNoSlash")
        end
        return false
    end
}

lualitong:addSkill(luatuifeng)
lualitong:addSkill(luatuifengEffect)
canghaiz:insertRelatedSkills("luatuifeng", "#luatuifengEffect")

sgs.LoadTranslationTable{
    ["lualitong"] = "李通",
    ["luatuifeng"] = "推锋",
    [":luatuifeng"] = "每回合限一次，当你造成或受到伤害后，你可以弃置一张牌。若如此做，你于此回合结束时摸两张牌或使用一张【杀】，若" ..
    "此【杀】造成伤害，你可以移动场上的一张牌。",
    ["@luatuifeng-slash"] = "推锋：使用一张【杀】，点【取消】则摸两张牌",
    ["@luatuifeng-move"] = "推锋：移动场上一张牌",
    ["$luatuifeng1"] = "摧锋陷阵，以杀贼首！",
    ["$luatuifeng2"] = "敌锋之锐，我已尽知。",
    ["~lualitong"] = "战死沙场，快哉！",
}

luadurui = sgs.CreateTriggerSkill{
    name = "luadurui",
    events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
		if player and player:getPhase() == sgs.Player_Finish then
            local skill_owners = room:findPlayersBySkillName(self:objectName())
			local skill_list = {}
			local name_list = {}
			if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, self:objectName()) and skill_owner:hasFlag("luaduruiEnough") and
                player:isFriendWith(skill_owner) then
                    table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
            end
            return table.concat(skill_list, "|"), table.concat(name_list, "|")
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
        local target_to = sgs.SPlayerList() --获取除选择目标的其他角色
        for _, p in sgs.qlist(room:getOtherPlayers(skill_owner)) do
            if skill_owner:canSlash(p, true) then
                target_to:append(p)
            end
        end
        if not target_to:isEmpty() then
            local target_player = room:askForPlayerChosen(skill_owner, target_to, self:objectName(),
            "@luadurui-slash", true, true)
            if target_player then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                slash:setSkillName(self:objectName())
                room:useCard(sgs.CardUseStruct(slash, skill_owner, target_player), true)
            end
        end
        return false
    end
}

luaduruiMark = sgs.CreateTriggerSkill{
    name = "#luaduruiMark",
    events = {sgs.EventPhaseChanging, sgs.Damage, sgs.DamageInflicted, sgs.PreDamageDone},
    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local skill_owners = room:findPlayersBySkillName("luadurui")
                if skill_owners:isEmpty() then return false end
                for _, skill_owner in sgs.qlist(skill_owners) do
                    if skill_owner:getMark("luaduruiDamage") > 0 then
                        room:setPlayerMark(skill_owner, "luaduruiDamage", 0)
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            local current = room:getCurrent()
            local skill_owners = room:findPlayersBySkillName("luadurui")
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, "luadurui") and skill_owner:isFriendWith(damage.from) and
                current:isFriendWith(skill_owner) then
                    if not skill_owner:hasFlag("luaduruiEnough") then
                        room:addPlayerMark(skill_owner, "luaduruiDamage", damage.damage)
                        if skill_owner:getMark("luaduruiDamage") > 1 then
                            room:setPlayerFlag(skill_owner, "luaduruiEnough")
                        end
                    end
                end
            end
        elseif event == sgs.PreDamageDone then
            local damage = data:toDamage()
            local current = room:getCurrent()
            local skill_owners = room:findPlayersBySkillName("luadurui")
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if skillTriggerable(skill_owner, "luadurui") and skill_owner:isFriendWith(damage.from) and
                current:isFriendWith(skill_owner) then
                    if skill_owner:getTag("luaduruiOnlyDamage") and skill_owner:getTag("luaduruiOnlyDamage"):toPlayer() then
                        local target = skill_owner:getTag("luaduruiOnlyDamage"):toPlayer()
                        if target:objectName() ~= damage.to:objectName() then
                            skill_owner:removeTag("luaduruiOnlyDamage")
                            room:setPlayerFlag(skill_owner, "luaduruiNoOnly")
                        end
                    elseif not skill_owner:hasFlag("luaduruiOnlyDamage") then
                        local d = sgs.QVariant()
                        d:setValue(damage.to)
                        skill_owner:setTag("luaduruiOnlyDamage", d)
                    end
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local skill_owners = room:findPlayersBySkillName("luadurui")
            if skill_owners:isEmpty() then return false end
            for _, skill_owner in sgs.qlist(skill_owners) do
                if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "luadurui" and not
                skill_owner:hasFlag("luaduruiNoOnly") and damage.from:objectName() == skill_owner:objectName() then
                    if skill_owner:getTag("luaduruiOnlyDamage") and skill_owner:getTag("luaduruiOnlyDamage"):toPlayer() then
                        local target = skill_owner:getTag("luaduruiOnlyDamage"):toPlayer()
                        skill_owner:removeTag("luaduruiOnlyDamage")
                        if damage.to:objectName() == target:objectName() then
                            damage.damage = damage.damage + 1
                            data:setValue(damage)
                            -- 显示加伤的提示  
                            local msg = sgs.LogMessage()
                            msg.type = "#jienuzhanAddDamage"
                            msg.from = skill_owner
                            msg.arg = 1
                            msg.arg2 = "luadurui"
                            room:sendLog(msg)
                        end
                    end
                end
            end
        end
        return false
    end
}

luacaochun:addSkill(luadurui)
luacaochun:addSkill(luaduruiMark)
canghaiz:insertRelatedSkills("luadurui", "#luaduruiMark")

sgs.LoadTranslationTable{
    ["luacaochun"] = "曹纯",
    ["luadurui"] = "督锐",
    [":luadurui"] = "与你势力相同的角色回合结束时，若与你势力相同的角色共计造成过2点伤害，你可以视为使用一张【杀】，若本回合受伤角色唯" ..
    "一，此【杀】对其伤害+1。",
    ["@luadurui-slash"] = "督锐：选择一名其他角色视为对其使用【杀】",
    ["$luadurui1"] = "虎豹骁骑，甲兵自当冠宇天下。",
    ["$luadurui2"] = "非虎贲难入我营，唯坚铠方配锐士。",
    ["~luacaochun"] = "三属之下，竟也护不住我性命…",
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