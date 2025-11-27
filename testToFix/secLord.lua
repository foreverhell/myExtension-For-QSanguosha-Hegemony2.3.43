-- 创建扩展包  
secLordEq = sgs.Package("secLordEq",sgs.Package_CardPack)
secLordGe = sgs.Package("secLordGe", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["secLordEq"] = "二代君",
    ["secLordGe"] = "二代君",
}
--建立武将
--魏势力
lord_caopi = sgs.General(secLordGe, "lord_caopi$", "wei", 4, true, true)

--蜀势力
lord_liushan = sgs.General(secLordGe, "lord_liushan$", "shu", 4, true, true)
--lualiuchen = sgs.General(secLordGe, "lualiuchen", "shu")

local skills = sgs.SkillList()

--建立伤害牌判断函数
isDamageCard = function(card)
    local damageCard = {"Slash", "Duel", "ArcheryAttack", "SavageAssault", "BurningCamps", "Drowning", "FireAttack"}
    local invoke = false
    for i = 1, #damageCard do
        if card:isKindOf(damageCard[i]) then
            invoke = true
            break
        end
    end
    return invoke
end


--装备部分
jinxiuzhengpao = sgs.CreateArmor{  
    name = "jinxiuzhengpao",  
    class_name = "jinxiuzhengpao",   
    suit = sgs.Card_Spade,  
    number = 2,  
      
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "jinxiuzhengpao", false, true)  
    end,  
      
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, "jinxiuzhengpao", true, false, true)
    end
}
jinxiuzhengpao_skill = sgs.CreateTriggerSkill{
    name = "jinxiuzhengpao",
    events = {sgs.TargetConfirmed, sgs.CardEffected, sgs.SlashEffected},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.TargetConfirmed and player:hasArmorEffect("jinxiuzhengpao") then
            local use = data:toCardUse()
            local armor = player:getArmor()
            if armor and armor:isKindOf("jinxiuzhengpao") and use.card and use.card:getSuit() < sgs.Card_NoSuit and
            use.to:contains(player) and use.from:objectName() ~= player:objectName() then
                --检查是否是伤害牌
                if not isDamageCard(use.card) then return false end

                -- 检查手牌中是否没有该花色
                local has_suit = false  
                local handcards = player:getHandcards()  
                for _, card in sgs.qlist(handcards) do  
                    if card:getSuit() == use.card:getSuit() then  
                        has_suit = true  
                        break  
                    end  
                end  
                if not has_suit then  
                    return self:objectName()  
                end
            end
        elseif (event == sgs.CardEffected or event == sgs.SlashEffected) and player:hasArmorEffect("jinxiuzhengpao") then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and event == sgs.CardEffected then return false end
            if player:hasFlag("jxzpCancel") then
                room:setPlayerFlag(player, "-jxzpCancel")
                local log = sgs.LogMessage()  
                log.type = "#JinxiuZhengpaoNullify"  
                log.from = player  
                log.arg = self:objectName()  
                room:sendLog(log)
                return true
            end
        end
        return false 
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local use = data:toCardUse() 
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse() 
          
        -- 展示所有手牌  
        local handcards = player:getHandcards()  
        if not handcards:isEmpty() then  
            room:showAllCards(player)  
        end  
          
        -- 获得该牌
        player:obtainCard(use.card)  
          
        -- 检查是否包含所有花色  
        local suits = {}  
        local all_cards = player:getHandcards()  
        for _, card in sgs.qlist(all_cards) do  
            local suit = card:getSuit()  
            if suit ~= sgs.Card_NoSuit then  
                suits[suit] = true  
            end  
        end  
          
        -- 检查是否有四种花色
        local suit_count = 0  
        for suit = sgs.Card_Spade, sgs.Card_Diamond do  
            if suits[suit] then  
                suit_count = suit_count + 1  
            end  
        end 
        if suit_count >= 4 then room:setPlayerFlag(player, "jxzpCancel") end  
          
        return false  
    end  
}

jinxiuzhengpao:setParent(secLordEq)

if not sgs.Sanguosha:getSkill("jinxiuzhengpao") then skills:append(jinxiuzhengpao_skill) end


sgs.LoadTranslationTable{
    ["jinxiuzhengpao"] = "锦绣征袍",  
    [":jinxiuzhengpao"] = "装备牌·防具\n\n技能：当你成为其他角色伤害牌的目标后，若你手牌中没有此花色的牌，你可以展示所有手牌并获得" ..
    "之，然后若你的手牌包含所有花色，此牌对你无效。",
    ["#JinxiuZhengpaoNullify"] = "%from 的【%arg】效果被触发，此牌对其无效。",
}

provinceSeal = sgs.CreateTreasure{
    name = "provinceSeal",
    class_name = "provinceSeal",
    suit = sgs.Card_Spade,
    number = 2,
    on_install = function(self, player)  
        local room = player:getRoom()
        if player and player:isAlive() then
            local hasBig = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isBigKingdomPlayer() then
                    hasBig = true
                    break
                end
            end
            if hasBig then
                local isBig = player:isBigKingdomPlayer()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if (isBig and player:isFriendWith(p)) or (not isBig and not p:isBigKingdomPlayer()) and player:isAlive() 
                    and not p:isNude() then
                        local d = sgs.QVariant()
                        d:setValue(player)
                        local choice = room:askForChoice(p, "provinceSeal_give", "yes+no", d, "@provinceSeal_askforgive::" .. 
                        player:objectName())
                        if choice == "yes" then
                            local result = room:askForExchange(p, "provinceSeal_give", 1, 1, "@provinceSeal-give::" .. 
                            player:objectName(), "", ".|.|.|.")
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), 
                            player:objectName(), self:objectName(), "")
                            local move = sgs.CardsMoveStruct(result, player, sgs.Player_PlaceHand, reason)
                            room:moveCardsAtomic(move, false)
                        end
                    end
                end
            end
        end
        room:acquireSkill(player, "provinceSeal", false, true)       
    end,

    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, "provinceSeal", true, false, true)
    end
}

provinceSeal_skill = sgs.CreateTriggerSkill{
    name = "provinceSeal",
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    priority = -1,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getTreasure() and
        player:getTreasure():isKindOf("provinceSeal") then
            return self:objectName()
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setPlayerMark(player, "provinceSeal_addDraw", 0)
                room:setPlayerMark(player, "provinceSeal_addSlash", 0)
                room:setPlayerMark(player, "provinceSeal_addMod", 0)
                room:setPlayerMark(player, "provinceSeal_reduceDraw", 0)
                room:setPlayerMark(player, "provinceSeal_reduceSlash", 0)
                room:setPlayerMark(player, "provinceSeal_reduceMod", 0)
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName()) then
			return true
		end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        local choice1 = room:askForChoice(player, "proSeal_choose1", "provinceSeal_draw+provinceSeal_slash+provinceSeal_mod+cancel",
        sgs.QVariant(), "@provinceSeal_choose1")
        if choice1 ~= "cancel" then
            local choice2 = room:askForChoice(player, "proSeal_choose2", "provinceSeal_add1+provinceSeal_add2+cancel", sgs.QVariant(), 
            "@provinceSeal_choose2")
            if choice2 ~= "cancel" then --注意杀次数最多-1，手牌上限也要具体分析
                local choices = {}
                if choice1 == "provinceSeal_draw" then
                    if choice2 == "provinceSeal_add1" then
                        table.insert(choices, "provinceSeal_reduceSlash")
                        table.insert(choices, "provinceSeal_reduceMod")
                        room:setPlayerMark(player, "provinceSeal_addDraw", 1)
                    else --这里添加杀次数上限的技能判断（如有）
                        table.insert(choices, "provinceSeal_reduceSlashAndMod")
                        if player:getMaxCards() >= 2 then
                            table.insert(choices, "provinceSeal_reduceMod")
                        end
                        if player:getMark("##luajpzzg_killer") > 0 then
                            table.insert(choices, "provinceSeal_reduceSlash")
                        end
                        room:setPlayerMark(player, "provinceSeal_addDraw", 2)
                    end
                elseif choice1 == "provinceSeal_slash" then
                    if choice2 == "provinceSeal_add1" then
                        table.insert(choices, "provinceSeal_reduceDraw")
                        table.insert(choices, "provinceSeal_reduceMod")
                        room:setPlayerMark(player, "provinceSeal_addSlash", 1)
                    else
                        table.insert(choices, "provinceSeal_reduceDrawAndMod")
                        table.insert(choices, "provinceSeal_reduceDraw")
                        if player:getMaxCards() >= 2 then
                            table.insert(choices, "provinceSeal_reduceMod")
                        end
                        room:setPlayerMark(player, "provinceSeal_addSlash", 2)
                    end
                else
                    if choice2 == "provinceSeal_add1" then
                        table.insert(choices, "provinceSeal_reduceDraw")
                        table.insert(choices, "provinceSeal_reduceSlash")
                        room:setPlayerMark(player, "provinceSeal_addMod", 1)
                    else
                        table.insert(choices, "provinceSeal_reduceDrawAndSlash")
                        --同这里加杀次数上限判断（如有）
                        if player:getMark("##luajpzzg_killer") > 0 then
                            table.insert(choices, "provinceSeal_reduceSlash")
                        end
                        table.insert(choices, "provinceSeal_reduceDraw")
                        room:setPlayerMark(player, "provinceSeal_addMod", 2)
                    end
                end
                if #choices > 0 then
                    local choice3
                    if #choices == 1 then
                        choice3 = choices[1]
                    else
                        choice3 = room:askForChoice(player, "proSeal_choose3", table.concat(choices, "+"), sgs.QVariant(), 
                        "@provinceSeal_choose2")
                    end
                    if choice3 == "" or choice3 == nil then
                        local x = math.random(#choices)
                        choice3 = choices[x]
                    end
                    if choice3 == "provinceSeal_reduceDraw" then
                        if choice2 == "provinceSeal_add1" then
                            room:setPlayerMark(player, "provinceSeal_reduceDraw", 1)
                        else
                            room:setPlayerMark(player, "provinceSeal_reduceDraw", 2)
                        end
                    elseif choice3 == "provinceSeal_reduceSlash" then
                        if choice2 == "provinceSeal_add1" then
                            room:setPlayerMark(player, "provinceSeal_reduceSlash", 1)
                        else
                            room:setPlayerMark(player, "provinceSeal_reduceSlash", 2)
                        end
                    elseif choice3 == "provinceSeal_reduceMod" then
                        if choice2 == "provinceSeal_add1" then
                            room:setPlayerMark(player, "provinceSeal_reduceMod", 1)
                        else
                            room:setPlayerMark(player, "provinceSeal_reduceMod", 2)
                        end
                    elseif choice3 == "provinceSeal_reduceDrawAndSlash" then
                        room:setPlayerMark(player, "provinceSeal_reduceDraw", 1)
                        room:setPlayerMark(player, "provinceSeal_reduceSlash", 1)
                    elseif choice3 == "provinceSeal_reduceDrawAndMod" then
                        room:setPlayerMark(player, "provinceSeal_reduceDraw", 1)
                        room:setPlayerMark(player, "provinceSeal_reduceMod", 1)
                    elseif choice3 == "provinceSeal_reduceSlashAndMod" then
                        room:setPlayerMark(player, "provinceSeal_reduceSlash", 1)
                        room:setPlayerMark(player, "provinceSeal_reduceMod", 1)
                    end
                end
                --显示选择的结果
                local x1 = (player:getMark("provinceSeal_addDraw") - player:getMark("provinceSeal_reduceDraw")) >= 0 and
                ("+" .. player:getMark("provinceSeal_addDraw")) or ("-" .. player:getMark("provinceSeal_reduceDraw"))
                local x2 = (player:getMark("provinceSeal_addSlash") - player:getMark("provinceSeal_reduceSlash")) >= 0 and
                ("+" .. player:getMark("provinceSeal_addSlash")) or ("-" .. player:getMark("provinceSeal_reduceSlash"))
                local x3 = (player:getMark("provinceSeal_addMod") - player:getMark("provinceSeal_reduceMod")) >= 0 and
                ("+" .. player:getMark("provinceSeal_addMod")) or ("-" .. player:getMark("provinceSeal_reduceMod"))
                local log = sgs.LogMessage()
                log.type = "#provinceSeal_chooseResult"
                log.from = player
                log.arg = "摸牌阶段摸牌数" .. x1 .. "，使用【杀】次数上限" .. x2 .. ",手牌上限" .. x3
                room:sendLog(log)
            end
        end
        return false
    end
}

provinceSealDraw = sgs.CreateDrawCardsSkill{
	name = "provinceSealDraw",
	frequency = sgs.Skill_Frequent,
    priority = -1,
	can_trigger = function(self, event, room, player, data)
        if (player:getMark("provinceSeal_reduceDraw") > 0) or (player:getMark("provinceSeal_addDraw") > 0) then
            return self:objectName()
        end
        return false
    end,
      
    on_cost = function(self, event, room, player, data)
		return true
    end,

	draw_num_func= function(self, player, n)
		return n - player:getMark("provinceSeal_reduceDraw") + player:getMark("provinceSeal_addDraw")
	end
}

provinceSealMaxcard = sgs.CreateMaxCardsSkill{
    name = "provinceSealMaxcard",
    extra_func = function(self, target)
        return target:getMark("provinceSeal_addMod") - target:getMark("provinceSeal_reduceMod")
    end
}

provinceSealSlash = sgs.CreateTargetModSkill{
	name = "provinceSealSlash",
	pattern = "Slash",
	residue_func = function(self, player)
		return player:getMark("provinceSeal_addSlash") - player:getMark("provinceSeal_reduceSlash")
	end,
}

provinceSeal:setParent(secLordEq)

if not sgs.Sanguosha:getSkill("provinceSeal") then skills:append(provinceSeal_skill) end
if not sgs.Sanguosha:getSkill("provinceSealDraw") then skills:append(provinceSealDraw) end
if not sgs.Sanguosha:getSkill("provinceSealMaxcard") then skills:append(provinceSealMaxcard) end
if not sgs.Sanguosha:getSkill("provinceSealSlash") then skills:append(provinceSealSlash) end

sgs.LoadTranslationTable{
    ["provinceSeal"] = "州郡领兵印",  
    [":provinceSeal"] = "装备牌·宝物\n\n技能：此牌置入你装备区后，与你势力大小相同的其他角色均可以交给你一张牌。准备阶段，你可以令本回合" ..
    "以下一项至多+2， 其余两项共计扣减等量的数值：\n1.摸牌阶段摸牌数；\n2.使用【杀】的次数上限；\n3.手牌上限。",
    ["@provinceSeal_askforgive"] = "州郡领兵印：是否选择交给%dest一张牌",
    ["@provinceSeal-give"] = "州郡领兵印：交给%dest一张牌",
    ["@provinceSeal_choose1"] = "州郡领兵印：请选择一项增加数值",
    ["@provinceSeal_choose2"] = "州郡领兵印：请选择一项",
    ["provinceSeal_draw"] = "摸牌阶段摸牌数",
    ["provinceSeal_slash"] = "使用【杀】次数上限",
    ["provinceSeal_mod"] = "手牌上限",
    ["provinceSeal_add1"] = "+1",
    ["provinceSeal_add2"] = "+2",
    ["provinceSeal_reduceDraw"] = "单减摸牌数",
    ["provinceSeal_reduceSlash"] = "单减使用【杀】次数上限",
    ["provinceSeal_reduceMod"] = "单减手牌上限",
    ["provinceSeal_reduceDrawAndSlash"] = "摸牌数和使用【杀】次数上限-1",
    ["provinceSeal_reduceDrawAndMod"] = "摸牌数和手牌上限-1",
    ["provinceSeal_reduceSlashAndMod"] = "使用【杀】次数上限和手牌上限-1",
    ["#provinceSeal_chooseResult"] = "%from 选择了%arg",
}

--君主及其他武将部分
luayanxi = sgs.CreateTriggerSkill{
    name = "luayanxi$",
    events = {sgs.GeneralShown},
    on_record = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasLordSkill(self:objectName()) and data:toBool() == 
        player:inHeadSkills(self:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke(self:objectName(), player)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getSeemingKingdom() == "shu" then
                    room:setPlayerMark(player, "luayanxiHas", 1)
                else
                    room:setPlayerMark(player, "luayanxiHas", 0)
                end
            end
            if player:getMark("Global_RoundCount") == 1 then
                room:setPlayerMark(player, "luapingming_mark", 1)
            end
        elseif player and player:isAlive() then
            local skill_owners = room:findPlayersBySkillName(self:objectName())
            if skill_owners:isEmpty() then return false end
            if player:getSeemingKingdom() == "shu" then
                room:setPlayerMark(player, "luayanxiHas", 1)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        return false
    end
}

luapingming = sgs.CreatePhaseChangeSkill{
    name = "luapingming",
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then
			for _, firstPlayer in sgs.qlist(room:getAlivePlayers()) do
				if player ~= firstPlayer then break end
                if firstPlayer:getPhase() == sgs.Player_Finish and firstPlayer:getMark("ThreatenEmperorExtraTurn") > 0 then
                    room:setPlayerMark(firstPlayer, "teExtraTurn", 1)
                end --开挟天子不算新的轮次
				if not firstPlayer:hasFlag("fangquanInvoked") and firstPlayer:getMark("teExtraTurn") <= 0 and 
                firstPlayer:getPhase() == sgs.TurnStart then
					local skill_owners = room:findPlayersBySkillName(self:objectName())
					if skill_owners:isEmpty() then return false end
					for _, skill_owner in sgs.qlist(skill_owners) do
						room:setPlayerMark(skill_owner, "luapingming_mark", 1)
                        room:setPlayerMark(skill_owner, "teExtraTurn", 0)
					end
					break
                elseif firstPlayer:getPhase() == sgs.TurnStart then
                    room:setPlayerMark(firstPlayer, "teExtraTurn", 0)
				end
			end
        end
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Start and player:getMark("luapingming_mark") == 1 then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("@companion") > 0 then
                    return self:objectName()
                end
            end
        elseif skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_RoundStart then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill("fangquan_lordliushan") then
                    room:detachSkillFromPlayer(p, "fangquan_lordliushan", false, false, true)
                end
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("@companion") > 0 then
                targets:append(p)
            end
        end
        if not targets:isEmpty() then
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@luapingming_choose", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName(), player)
                local d = sgs.QVariant()
                d:setValue(target)
                player:setTag("luapingmingTarget", d)
                return true
            end
        end
		return false
	end,

    on_phasechange = function(self, player)
        local room = player:getRoom()
        local target = player:getTag("luapingmingTarget"):toPlayer()
        if target then
            target:drawCards(1)
            room:acquireSkill(target, "fangquan_lordliushan", true, true)
        end
        return false
    end
}

fangquan_lordliushan = sgs.CreateTriggerSkill{
    name = "fangquan_lordliushan",
    events = {sgs.EventPhaseChanging},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            local change = data:toPhaseChange()
            if change and change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
                return "fangquan"
            end
        end
        return false
    end
}

luayixingCard = sgs.CreateSkillCard{
    name = "luayixingCard",
    skill_name = "luayixingToEquip",
    will_throw = false,
	handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select, Self)
        return #targets == 0 and to_select:getArmor() == nil and to_select:getMark("@companion") < 1
    end,
    on_use = function(self, room, source, targets)
		local card_id = self:getSubcards():first()
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName())
        local move = sgs.CardsMoveStruct(card_id, targets[1], sgs.Player_PlaceEquip, reason)
        room:moveCardsAtomic(move, true)
        room:addPlayerMark(targets[1], "@companion", 1)
    end
}

luayixingToEquip = sgs.CreateOneCardViewAsSkill{
    name = "luayixingToEquip",
    response_pattern = "@@luayixingToEquip",
    view_filter = function(self, selected)
        return selected:isKindOf("Armor")
	end,

    view_as = function(self, card)
		local recast_card = luayixingCard:clone()
        recast_card:addSubcard(card:getId())
        recast_card:setSkillName("luayixing")
		recast_card:setShowSkill("luayixing")
        return recast_card
	end,
}

luayixing = sgs.CreatePhaseChangeSkill{
    name = "luayixing",
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
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

    on_phasechange = function(self, player)
        local room = player:getRoom()
        local jxzpTarget = sgs.SPlayerList()
        local hasTarget, hasArmor = false, false
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getArmor() and p:getArmor():objectName() == "jinxiuzhengpao" then
                jxzpTarget:append(p)
                hasTarget = true
            end
        end
        local hecard = player:getCards("he")
        for _, c in sgs.qlist(hecard) do
            if c:isKindOf("Armor") then
                hasArmor = true
            end
        end
        local choices = {}
        if hasTarget then
            table.insert(choices, "luayixing_move")
        end
        if hasArmor then
            table.insert(choices, "luayixing_toEquip")
        end
        if #choices < 1 then return false end

        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), "@luayixing-choose", 
        "luayixing_move+luayixing_toEquip")
        if choice == "luayixing_move" then --默认只有一张“锦绣征袍”防具牌
            local card_id = jxzpTarget:at(0):getArmor():getId()
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName())
            local move = sgs.CardsMoveStruct(card_id, player, sgs.Player_PlaceEquip, reason)
            room:moveCardsAtomic(move, true)
        elseif choice == "luayixing_toEquip" then
            room:askForUseCard(player, "@@luayixingToEquip", "@luayixing_equip")
        end
        return false
    end
}

luaxtfcz = sgs.CreateTriggerSkill{
    name = "#luaxtfcz",
    events = {sgs.EventPhaseStart, sgs.Death, sgs.PreCardUsed},
    on_record = function(self, event, room, player, data)
        if player and player:isAlive() then
            if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or event == sgs.PreCardUsed then
                local skill_owners1 = room:findPlayersBySkillName("luayanxi")
                local skill_owners2 = room:findPlayersBySkillName("xiangle")
                if skill_owners1:isEmpty() or (not skill_owners2:isEmpty() and skill_owners2:at(0):getMark("Global_RoundCount") > 1) 
                then return false end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getSeemingKingdom() == "shu" and p:getMark("@companion") > 0 and p:getMark("luaxtfcz_gotCompanion") < 1 then
                        room:setPlayerMark(p, "luaxtfcz_gotCompanion", 1)
                    end
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and event == sgs.Death then
            local death = data:toDeath()
            if death.who:hasSkill("luayanxi") and player:isFriendWith(death.who) then
                return self:objectName(), death.who:objectName()
            end
        elseif skillTriggerable(player, self:objectName()) and event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local hp = player:getHp()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if hp > p:getHp() then
                    return false
                end
            end
            return self:objectName(), player:objectName()
        end
        return false
    end,

    on_cost = function(self, event, room, player, data, skill_owner)
        if event == sgs.Death then
            local choice = room:askForChoice(player, "luayanxi_death", "yes+no", data, "@luayanxi_death", "yes+no")
            if choice == "yes" then
                room:setPlayerMark(player, "luayanxiZhanjue", 1)
                room:broadcastSkillInvoke("luayanxi", skill_owner)
                room:doAnimate(1, skill_owner:objectName(), player:objectName())
                return true
            end
        elseif event == sgs.EventPhaseStart then
            local choice = room:askForChoice(player, "luayanxi_lose", "yes+no", data, "@luayanxi_lose", "yes+no")
            if choice == "yes" then
                room:setPlayerFlag(player, "luayanxiLoseSkill")
                room:broadcastSkillInvoke("luayanxi", player)
                return true
            end
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, skill_owner)
        if event == sgs.Death then
            if player:getMark("luayanxiZhanjue") > 0 then
                room:loseHp(player, 1)
                if player:isAlive() then
                    room:acquireSkill(player, "luazhanjue", true, true)
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:hasFlag("luayanxiLoseSkill") then
                room:detachSkillFromPlayer(player, "luayanxi", false, false, true)
                --排除获得过珠联璧合标记却没有被正确上“luaxtfcz_gotCompanion”标记的情况
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("luaxtfcz_gotCompanion") <= 0 and player:isFriendWith(p) and p:getMark("@companion")
                    > 0 then
                        room:setPlayerMark(p, "luaxtfcz_gotCompanion", 1)
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("luaxtfcz_gotCompanion") > 0 then
                        room:addPlayerMark(p, "@companion", 1)
                    end
                end
            end
        end
        return false
    end
}

luaxtfcz_extra = sgs.CreateTriggerSkill{
    name = "#luaxtfcz_extra",
    events = {sgs.EventPhaseStart, sgs.PreCardUsed, sgs.BuryVictim},--死亡后的时机早于变野的时机，暂时只能想到这么写
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("luayanxiZhanjue") > 0 then
                    p:setRole("shu")
                    room:broadcastProperty(p, "kingdom")
                    room:broadcastProperty(p, "role")
                    room:setPlayerMark(p, "luayanxiZhanjue", 0)
                end
            end
        end
        if event == sgs.BuryVictim then
            local death = data:toDeath()
            if death.who:getGeneralName() ~= "lord_liushan" then return false end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("luayanxiHas") > 0 then
                    room:setPlayerMark(p, "luayanxiHas", 0)
                end
            end
        end
        return false
    end
}

luaxtfcz_maxcard = sgs.CreateMaxCardsSkill{
    name = "#luaxtfcz_maxcard",
    extra_func = function(self, target)
        return (target:getMark("@companion") > 0 and target:getSeemingKingdom() == "shu" and target:getMark("luayanxiHas") > 0) 
        and 1 or 0
    end
}

luaxtfcz_range = sgs.CreateAttackRangeSkill{
    name = "#luaxtfcz_range",
    extra_func = function(self, target)
        return (target:getMark("@companion") < 1 and target:getSeemingKingdom() == "shu" and target:getMark("luayanxiHas") > 0) 
        and 1 or 0
    end
}

lord_liushan:addSkill(luayanxi)
lord_liushan:addSkill(luapingming)
lord_liushan:addSkill(luayixing)
lord_liushan:addSkill(luaxtfcz)
lord_liushan:addSkill(luaxtfcz_maxcard)
lord_liushan:addSkill(luaxtfcz_extra)
lord_liushan:addSkill(luaxtfcz_range)
secLordGe:insertRelatedSkills("luayanxi", "#luaxtfcz")
secLordGe:insertRelatedSkills("luayanxi", "#luaxtfcz_maxcard")
secLordGe:insertRelatedSkills("luayanxi", "#luaxtfcz_extra")
secLordGe:insertRelatedSkills("luayanxi", "#luaxtfcz_range")

if not sgs.Sanguosha:getSkill("luayixingToEquip") then skills:append(luayixingToEquip) end
if not sgs.Sanguosha:getSkill("fangquan_lordliushan") then skills:append(fangquan_lordliushan) end

sgs.LoadTranslationTable{
    ["#lord_liushan"] = "仁敏的蒲牢",
    ["lord_liushan"] = "刘禅",
    ["&lord_liubei"] = "刘禅",
    ["luayanxi"] = "延熙",
    [":luayanxi"] = "君主技，你拥有“续统辅臣诏”。\n\n#\"续统辅臣诏\"\n" ..
    "锁定技，有珠联璧合标记的蜀势力角色手牌上限+1；没有珠联璧合标记的蜀势力角色攻击范围+1。\n" .. 
    "准备阶段，若你的体力值最小，你可以失去“延熙”，令所有获得过珠联璧合标记的蜀势力角色再次获得该标记。\n" .. 
    "其他蜀势力角色因你的死亡而变成野心家时，其可以失去1点体力并防止之，然后获得技能“战绝”。（战绝：出牌阶段，你可以将所有手牌" ..
    "当【决斗】使用，然后你和因此受伤的角色各摸一张牌。若在同一阶段内你以此法摸过两张或更多的牌，则本回合此技能失效。）",
    ["@luayanxi_death"] = "延熙：是否失去1点体力防止成为野心家，并获得“战绝”",
    ["@luayanxi_lose"] = "延熙：是否失去该技能并令所有获得过珠联璧合标记的蜀势力角色再次获得该标记",
    ["luapingming"] = "平明",
    [":luapingming"] = "每轮限一次，准备阶段，你可以令一名有珠联璧合标记的角色摸一张牌，令其获得“放权”直到你下回合开始。",
    ["@luapingming_choose"] = "平明：选择一名有珠联璧合标记的角色摸一张牌，并令其获得“放权”",
    ["luayixing"] = "义兴",
    [":luayixing"] = "结束阶段，你可以选择一项：1.将场上的【锦绣征袍】移至你的装备区；\n2.将一张防具牌置入一名没有珠联璧合标记的角色装备区，" ..
    "令其获得一枚该标记。",
    ["@luayixing-choose"] = "义兴：请选择一项",
    ["luayixing_move"] = "移动【锦绣征袍】至你的装备区",
    ["luayixing_toEquip"] = "置入防具牌",
    ["@luayixing_equip"] = "义兴：将一张防具牌置入没有珠联璧合标记的角色装备区，令其获得该标记",
    ["fangquan_lordliushan"] = "放权",
    [":fangquan_lordliushan"] = "出牌阶段开始前，你可跳过此阶段▶此回合结束前，你可弃置一张手牌并选择一名其他角色.其获得一个额外回合。",
    ["$luayanxi1"] = "若无忠臣良将，焉有今日之功！",
    ["$luayanxi2"] = "卿等安国定疆，方有今日之统！",
    ["$luapingming1"] = "天下分合，终不改汉祚之名！",
    ["$luapingming2"] = "平安南北，终携百姓致太平！",
    ["$luayixing1"] = "朕虽驽钝，幸有众爱卿襄助！",
    ["$luayixing2"] = "知人善用，任人唯贤！",
    ["~lord_liushan"] = "天下分崩离乱，再难建兴……",
}

luazhanjueCard = sgs.CreateSkillCard{
	name = "luazhanjueCard",
	skill_name = "luazhanjue",
	will_throw = false,
	filter = function(self, targets, to_select, Self)
		return #targets == 0 and to_select:objectName() ~= Self:objectName() and not to_select:isRemoved()
	end,
	on_use = function(self, room, source, targets)
		local hcards = source:getCards("h")
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)
        for _, c in sgs.qlist(hcards) do duel:addSubcard(c:getId()) end
        duel:setSkillName("luazhanjue")
        room:useCard(sgs.CardUseStruct(duel, source, targets[1]), true)
        duel:deleteLater()
	end
}

luazhanjue = sgs.CreateZeroCardViewAsSkill{
    name = "luazhanjue",
    view_as = function(self)
        local card = luazhanjueCard:clone()
        card:setSkillName(self:objectName())
		card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return player:getMark("luazhanjueDraw") < 2 and not player:isKongcheng()
    end
}

luazhanjue_draw = sgs.CreateTriggerSkill{
    name = "#luazhanjue_draw",
    events = {sgs.DamageCaused, sgs.CardFinished, sgs.EventPhaseChanging, sgs.Damaged},
    priority = -1,
    frequency = sgs.Skill_Compulsory,
    on_record = function(self, event, room, player, data)
        if skillTriggerable(player, "luazhanjue") and event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setPlayerMark(player, "luazhanjueDraw", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then
            local current = room:getCurrent()
            if current and current:isAlive() and current:hasSkill("luazhanjue") then
                if event == sgs.DamageCaused or event == sgs.Damaged then
                    local damage = data:toDamage()
                    if damage.card:isKindOf("Duel") and damage.card:getSkillName() == "luazhanjue" and damage.damage > 0 then
                        if event == sgs.Damaged then
                            room:setPlayerFlag(damage.to, "luazhanjueDamaged")
                        elseif event == sgs.DamageCaused then
                            room:setPlayerFlag(current, "luazhanjueDamage")
                        end
                    end
                elseif event == sgs.CardFinished then
                    local use = data:toCardUse()
                    if use and use.card:isKindOf("Duel") and use.card:getSkillName() == "luazhanjue" then
                        return self:objectName()
                    end
                end
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
		return true
	end,

	on_effect = function(self, event, room, player, data)
        local current = room:getCurrent()
        local use = data:toCardUse()
        local target = use.to
        if current:hasFlag("luazhanjueDamage") then
            current:drawCards(1)
            room:addPlayerMark(current, "luazhanjueDraw", 1)
            room:setPlayerFlag(current, "-luazhanjueDamage")
        end
        if current:hasFlag("luazhanjueDamaged") then
            current:drawCards(1)
            room:addPlayerMark(current, "luazhanjueDraw", 1)
            room:setPlayerFlag(current, "-luazhanjueDamaged")
        else
            if target:length() > 0 then
                room:sortByActionOrder(target)
            end
            for _, p in sgs.qlist(target) do
                p:drawCards(1)
            end
        end
        return false
    end
}

--[[lualiuchen:addSkill(luazhanjue)
lualiuchen:addSkill(luazhanjue_draw)
secLordGe:insertRelatedSkills("luazhanjue", "#luazhanjue_draw")

sgs.LoadTranslationTable{
    ["lualiuchen"] = "刘谌",
    ["luazhanjue"] = "战绝",
    [":luazhanjue"] = "出牌阶段，你可以将所有手牌当【决斗】使用，然后你和因此受伤的角色各摸一张牌。若在同一阶段内你以此法摸过两张或更多的牌，则" ..
    "本回合此技能失效。",
    ["$luazhanjue1"] = "虎豹骁骑，甲兵自当冠宇天下。",
    ["$luazhanjue2"] = "非虎贲难入我营，唯坚铠方配锐士。",
    ["~lualiuchen"] = "三属之下，竟也护不住我性命…",
}]]

luahuangchu = sgs.CreateTriggerSkill{
    name = "luahuangchu$",
    events = {sgs.GeneralShown},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasLordSkill(self:objectName()) and data:toBool() == 
        player:inHeadSkills(self:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local weiMax, allMax = {}, {}
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getSeemingKingdom() == "wei" then
                    table.insert(weiMax, p:getMark("luajpzzg_killCount"))
                else
                    table.insert(allMax, p:getMark("luajpzzg_killCount"))
                end
            end
            table.sort(weiMax, function(a, b) return a > b end)
            table.sort(allMax, function(a, b) return a > b end)
            if weiMax[1] == weiMax[2] or player:getPlayerNumWithSameKingdom("AI", "wei", 1) <= 1 then 
                return false 
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getSeemingKingdom() == "wei" and p:getMark("luajpzzg_killCount") == weiMax[1] then
                    if weiMax[1] >= allMax[1] then
                        room:setPlayerMark(p, "##luajpzzg_killer", 2)
                    else
                        room:setPlayerMark(p, "##luajpzzg_killer", 1)
                    end
                    break
                end
            end
        end
        return false
    end
}

luajpzzg = sgs.CreateTriggerSkill{
    name = "#luajpzzg",
    events = {sgs.CardsMoveOneTime, sgs.Death},
    frequency = sgs.Skill_Compulsory,
    priority = -1,
    on_record = function(self, event, room, player, data)
        if player then
            local skill_owners1 = room:findPlayersBySkillName("luahuangchu")
            local skill_owners2 = room:findPlayersBySkillName("xingshang")
            if skill_owners1:isEmpty() and skill_owners2:isEmpty() then return false end
            --[[local isFirstRound = false
            for _, skill_owner in sgs.qlist(skill_owners2) do
                if skillTriggerable(skill_owner, "fangzhu") and skill_owner:getMark("Global_RoundCount") <= 1 then
                    isFirstRound = true
                    break
                end
            end
            if isFirstRound then return false end]]
            local hasAnjiang = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if sgs.isAnjiang(p) then
                    hasAnjiang = true
                    break
                end
            end
            if not hasAnjiang and player:getPlayerNumWithSameKingdom("AI", "wei", 1) <= 1 then 
                return false --若没有暗将且魏势力角色数不足两人，则无大旗效果，无需再往下执行
            end
              
            if event == sgs.Death then
                local death = data:toDeath()
                if death.who:getActualGeneral1Name() == "lord_caopi" then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getMark("##luajpzzg_peach") > 0 then
                            room:setPlayerMark(p, "##luajpzzg_peach", 0)
                        end
                        if p:getMark("##luajpzzg_killer") > 0 then
                            room:setPlayerMark(p, "##luajpzzg_killer", 0)
                        end
                        if p:getMark("##luajpzzg_handcards") > 0 then
                            room:setPlayerMark(p, "##luajpzzg_handcards", 0)
                        end
                    end
                    return false
                end

                if death.damage and death.damage.from then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do--先清标记
                        if p:getMark("##luajpzzg_killer") > 0 then
                            room:setPlayerMark(p, "##luajpzzg_killer", 0)
                        end
                        break
                    end

                    local killPlayer = death.damage.from
                    if killPlayer:isAlive() then
                        room:addPlayerMark(killPlayer, "luajpzzg_killCount", 1)
                    end
                    local weiMax, allMax = {}, {}
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getSeemingKingdom() == "wei" then
                            table.insert(weiMax, p:getMark("luajpzzg_killCount"))
                        else
                            table.insert(allMax, p:getMark("luajpzzg_killCount"))
                        end
                    end
                    table.sort(weiMax, function(a, b) return a > b end)
                    table.sort(allMax, function(a, b) return a > b end)
                    if weiMax[1] == weiMax[2] or player:getPlayerNumWithSameKingdom("AI", "wei", 1) <= 1 or 
                    skill_owners1:isEmpty() then return false end
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getSeemingKingdom() == "wei" and p:getMark("luajpzzg_killCount") == weiMax[1] then
                            if weiMax[1] >= allMax[1] then
                                room:setPlayerMark(p, "##luajpzzg_killer", 2)
                            else
                                room:setPlayerMark(p, "##luajpzzg_killer", 1)
                            end
                            break
                        end
                    end
                end
            elseif event == sgs.CardsMoveOneTime then
                if not player:getSeemingKingdom() == "wei" then return false end
                local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
                    if not move.from_places:contains(sgs.Player_PlaceHand) then return false end
                    if (move.from and move.from:getSeemingKingdom() ~= "wei") or (move.to and move.to:getSeemingKingdom() ~= "wei") then
                        return false
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do --先清标记
                    if p:getMark("##luajpzzg_handcards") > 0 then
                        room:setPlayerMark(p, "##luajpzzg_handcards", 0)
                    end
                    if p:getMark("##luajpzzg_peach") > 0 then
                        local dying = data:toDying()
                        if dying and dying.who then continue end
                        room:setPlayerMark(p, "##luajpzzg_peach", 0)
                    end
                end

                if player:hasSkill("luachenyin") and player:getPhase() == sgs.Player_Play then
                    local move_datas = data:toList()
                    for _, move_data in sgs.qlist(move_datas) do
                        local move = move_data:toMoveOneTime()
                        if move.to_place == sgs.Player_DiscardPile then
                            for _, id in sgs.qlist(move.card_ids) do
                                if room:getCardPlace(id) == sgs.Player_DiscardPile then
                                    local card = sgs.Sanguosha:getCard(id)
                                    room:setPlayerFlag(player, "luachenyin_" .. card:getSuitString())
                                end
                            end
                        end
                    end
                end

                if skill_owners1:isEmpty() then return false end
                local weiMax, allMax = {}, {}
                local weiMaxcard, allMaxcard = {}, {}
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getSeemingKingdom() == "wei" then
                        table.insert(weiMax, p:getHandcardNum())
                        table.insert(weiMaxcard, p:getMaxCards())
                    else
                        table.insert(allMax, p:getHandcardNum())
                        table.insert(allMaxcard, p:getMaxCards())
                    end
                end
                table.sort(weiMax, function(a, b) return a > b end)
                table.sort(allMax, function(a, b) return a > b end)
                table.sort(weiMaxcard, function(a, b) return a > b end)
                table.sort(allMaxcard, function(a, b) return a > b end)
                if weiMax[1] ~= weiMax[2] and player:getPlayerNumWithSameKingdom("AI", "wei", 1) > 1 then 
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getSeemingKingdom() == "wei" and p:getHandcardNum() == weiMax[1] then
                            if weiMax[1] >= allMax[1] then
                                room:setPlayerMark(p, "##luajpzzg_handcards", 2)
                            else
                                room:setPlayerMark(p, "##luajpzzg_handcards", 1)
                            end
                            break
                        end
                    end
                end
     
                if weiMaxcard[1] == weiMaxcard[2] or player:getPlayerNumWithSameKingdom("AI", "wei", 1) <= 1 then return false end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getSeemingKingdom() == "wei" and p:getMaxCards() == weiMaxcard[1] then
                        if weiMaxcard[1] >= allMaxcard[1] then
                            room:setPlayerMark(p, "##luajpzzg_peach", 2)
                        else
                            room:setPlayerMark(p, "##luajpzzg_peach", 1)
                        end
                        break
                    end
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        return false
    end
}

luajpzzg_markEffect = sgs.CreateTriggerSkill{
    name = "#luajpzzg_markEffect",
    events = {sgs.CardFinished, sgs.PreHpRecover, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    priority = -5,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardFinished then
            if player:getPlayerNumWithSameKingdom("AI", "wei", 1) <= 1 then return false end
            local effect = data:toCardUse()
            if effect.card and (effect.card:isKindOf("Slash") or effect.card:isNDTrick()) then
                local skill_owners = room:findPlayersBySkillName("luahuangchu")
                if skill_owners:isEmpty() or player:getPlayerNumWithSameKingdom("AI", "wei", 1) <= 1 then return false end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getSeemingKingdom() == "wei" and p:getCardUsedTimes("Nullification") > p:getMark("luajpzzg_nullification") and
                    p:getMark("##luajpzzg_handcards") > 0 then
                        return self:objectName(), p:objectName()
                    end
                    if p:getSeemingKingdom() == "wei" and p:getCardUsedTimes("Jink") > p:getMark("luajpzzg_jink") and
                    p:getMark("##luajpzzg_handcards") > 0 then
                        return self:objectName(), p:objectName()
                    end
                end
            end
        elseif player and event == sgs.PreHpRecover then
            if player:getPlayerNumWithSameKingdom("AI", "wei", 1) <= 1 then return false end
            local recover = data:toRecover()
            if recover.who and recover.who:getMark("##luajpzzg_peach") > 0 and recover.card and player:getHp() < 1 and
            recover.card:isKindOf("Peach") then
                return self:objectName(), recover.who:objectName()
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("luajpzzg_jink") > 0 then
                        room:setPlayerMark(p, "luajpzzg_jink", 0)
                    end
                    if p:getMark("luajpluajpzzg_nullificationzzg_jink") > 0 then
                        room:setPlayerMark(p, "luajpzzg_nullification", 0)
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
        if event == sgs.CardFinished then
            skill_owner:drawCards(skill_owner:getMark("##luajpzzg_handcards"))
            if skill_owner:getCardUsedTimes("Nullification") > skill_owner:getMark("luajpzzg_nullification") then
                room:setPlayerMark(skill_owner, "luajpzzg_nullification", skill_owner:getCardUsedTimes("Nullification"))
            elseif skill_owner:getCardUsedTimes("Jink") > skill_owner:getMark("luajpzzg_Jink") then
                room:setPlayerMark(skill_owner, "luajpzzg_jink", skill_owner:getCardUsedTimes("Jink"))
            end
            local msg = sgs.LogMessage()
			msg.type = "#luajpzzg_logDraw"
			msg.from = skill_owner
			msg.arg = skill_owner:getMark("##luajpzzg_handcards")
			room:sendLog(msg)
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            recover.recover = recover.recover + skill_owner:getMark("##luajpzzg_peach")
            data:setValue(recover)
            local msg = sgs.LogMessage()
			msg.type = "#luajpzzg_logRecover"
			msg.from = player
			msg.arg = recover.recover
            room:sendLog(msg)
        end
        return false
    end
}

luajpzzgSlashTimes = sgs.CreateTargetModSkill{
	name = "luajpzzgSlashTimes",
	pattern = "Slash",
	residue_func = function(self, player)
		return player:getMark("##luajpzzg_killer")
	end,
}

luachenyinCard = sgs.CreateSkillCard{
    name = "luachenyinCard",
    skill_name = "luachenyin",
	filter = function(self, targets, to_select, Self)
		return #targets == 0 and not to_select:isNude() and to_select:getKingdom() == "wei"
	end,
	on_use = function(self, room, source, targets)
		room:askForDiscard(targets[1], "luachenyin", 2, 2, false, true)
        local suit_spade = "luachenyin_spade"
        local suit_club = "luachenyin_club"
        local suit_diamond = "luachenyin_diamond"
        local suit_heart = "luachenyin_heart"
        if source:objectName() == targets[1]:objectName() then
            room:acquireSkill(source, "fangzhu_lordcaopi", true, true)
        else
            source:drawCards(2)
            if targets[1]:canRecover() and targets[1]:hasFlag(suit_spade) and targets[1]:hasFlag(suit_club) and 
            targets[1]:hasFlag(suit_diamond) and targets[1]:hasFlag(suit_heart) then
                local recover = sgs.RecoverStruct()
                recover.who = source
                recover.recover = 1
                room:recover(targets[1], recover)
            end
        end
	end
}

luachenyin = sgs.CreateZeroCardViewAsSkill{
    name = "luachenyin",
    view_as = function(self)
        local card = luachenyinCard:clone()
        card:setSkillName(self:objectName())
		card:setShowSkill(self:objectName())
        return card
    end,
      
    enabled_at_play = function(self, player)
        return not player:hasUsed("#luachenyinCard")
    end
}

fangzhu_lordcaopi = sgs.CreateTriggerSkill{
    name = "fangzhu_lordcaopi",
    events = {sgs.Damaged, sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and event == sgs.Damaged then
            return "fangzhu"
        elseif event == sgs.EventPhaseStart and skillTriggerable(player, self:objectName()) and player:getPhase() == 
        sgs.Player_RoundStart then
            room:detachSkillFromPlayer(player, self:objectName(), false, false, true)
        end
        return false
    end
}

luahuandou = sgs.CreatePhaseChangeSkill{
    name = "luahuandou",
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Start then
            local id = 165
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf("provinceSeal") and (room:getCardPlace(id) == sgs.Player_DiscardPile or room:getCardPlace(id) 
            == sgs.Player_PlaceEquip) then
                return self:objectName()
            elseif not card:isKindOf("provinceSeal") then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getTreasure() and p:getTreasure():isKindOf("provinceSeal") then
                        return self:objectName()
                    end
                end
                for _, pId in sgs.qlist(room:getDiscardPile()) do
                    if sgs.Sanguosha:getCard(pId):isKindOf("provinceSeal") then
                        return self:objectName()
                    end
                end
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

    on_phasechange = function(self, player)
        local room = player:getRoom()
        player:drawCards(1)
        local target_hasTr = sgs.SPlayerList()
        local target_noTr = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getTreasure() then
                target_hasTr:append(p)
            else
                target_noTr:append(p)
            end
        end
        if target_hasTr:isEmpty() then return false end
        local target1 = room:askForPlayerChosen(player, target_hasTr, "luahuandou_move", "@luahuandou_player1", true, true)
        if target1 then
            local target2 = room:askForPlayerChosen(player, target_noTr, "luahuandou_get", "@luahuandou_player2", true, true)
            if target2 then
                room:moveCardTo(target1:getTreasure(), target2, sgs.Player_PlaceEquip, true)
            end
        end
        return false
    end
}

lord_caopi:addSkill(luahuangchu)
lord_caopi:addSkill(luajpzzg)
lord_caopi:addSkill(luajpzzg_markEffect)
lord_caopi:addSkill(luachenyin)
lord_caopi:addSkill(luahuandou)
secLordGe:insertRelatedSkills("luahuangchu", "#luajpzzg")
secLordGe:insertRelatedSkills("luahuangchu", "#luajpzzg_markEffect")

if not sgs.Sanguosha:getSkill("luajpzzgSlashTimes") then skills:append(luajpzzgSlashTimes) end
if not sgs.Sanguosha:getSkill("fangzhu_lordcaopi") then skills:append(fangzhu_lordcaopi) end

sgs.LoadTranslationTable{
    ["#lord_caopi"] = "挣罗的负屭",
    ["lord_caopi"] = "曹丕",
    ["&lord_caopi"] = "曹丕",
    ["luahuangchu"] = "黄初",
    [":luahuangchu"] = "君主技，你拥有“九品中正诰”。\n\n#\"九品中正诰\"\n" ..
    "锁定技，若场上魏势力角色数大于1，且一名魏势力角色以下数值为魏势力中唯一最大，其获得对应效果： \n" .. 
    "手牌数~抵消牌后摸一张牌；\n" .. 
    "杀死过的角色数~出牌阶段【杀】的使用次数+1；\n" ..
    "手牌上限~对濒死角色使用【桃】的回复值+1。\n若其前项数值为全场最大，则后项的数值再翻倍。",
    ["luajpzzg_handcards"] = "大旗1",
    ["luajpzzg_killer"] = "大旗2",
    ["luajpzzg_peach"] = "大旗3",
    ["#luajpzzg_logDraw"] = "%from 发动了“九品中正诰”，抵消牌后发动摸牌效果",
    ["#luajpzzg_logRecover"] = "%from 发动了“九品中正诰”，令该【桃】的回复值为%arg",
    ["luachenyin"] = "沉吟",
    [":luachenyin"] = "出牌阶段限一次，你可以令一名魏势力角色弃置两张牌，若弃牌的角色：为你，你获得“放逐”直到你的下回合开始；不为你，你" ..
    "摸两张牌，然后若此阶段置入弃牌堆的牌包含四种花色，其回复1点体力。",
    ["fangzhu_lordcaopi"] = "放逐",
    ["luahuandou"] = "换斗",
    [":luahuandou"] = "准备阶段，若【州郡领兵印】处于场上或弃牌堆，你可以摸一张牌，然后可以移动场上一张宝物牌。",
    ["@luahuandou_player1"] = "换斗：请选择一名场上有宝物牌的角色",
    ["@luahuandou_player2"] = "换斗：请选择一名场上没有宝物牌的角色",
    ["luahuandou_move"] = "换斗",
    ["luahuandou_get"] = "换斗",
    ["$luahuangchu1"] = "纵是身死，仍要为我所用。",
    ["$luahuangchu2"] = "汝九泉之下，定会感朕之情。",
    ["$luachenyin1"] = "战败而降，辱我国威，岂能轻饶。",
    ["$luachenyin2"] = "此等过错，不杀已是承了朕恩。",
    ["$luahuandou1"] = "江山锦绣，尽在朕手。",
    ["$luahuandou2"] = "成功建业，扬我魏威！",
    ["~lord_caopi"] = "大魏如何踏破吴蜀，就全看叡儿了……",
}

sgs.Sanguosha:addSkills(skills)

return {secLordEq, secLordGe}

--[[
		local log = sgs.LogMessage()
		log.type = "readytodraw"
		log.from = player
		log.to:append(player)
		room:sendLog(log)
]]--