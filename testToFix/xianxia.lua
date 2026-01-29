-- 创建扩展包  
xianxia_x = sgs.Package("xianxia_x",sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["xianxia_x"] = "线下包",
}
--建立武将
--魏势力
caozhi_xianxia = sgs.General(xianxia_x, "caozhi_xianxia", "wei", 3)

--蜀势力


--吴势力


--群势力
fuhuanghou = sgs.General(xianxia_x, "fuhuanghou", "qun", 3, false)

--构建装备牌或判定牌能否合理移动至该角色的判断函数
canSetto = function (card, player)
    if card:isKindOf("DelayedTrick") then
        for _, c in sgs.qlist(player:getCards("j")) do
            if c:getName() == card:getName() then
                return false
            end
        end
    elseif card:isKindOf("EquipCard") then
        local equipindexs = {"Weapon", "Armor", "DefensiveHorse", "OffensiveHorse", "Treasure", "SpecialHorse"}
        for i = 1, #equipindexs do
            if card:isKindOf(equipindexs[i]) then
                if player:getEquip(i - 1) then
                    return false
                else
                    if i == 3 or i == 4 then
                        if player:getEquip(6) then
                            return false
                        end
                    elseif i == 6 then
                        if player:getEquip(3) or player:getEquip(4) then
                            return false
                        end
                    end
                end
            end
        end
    end
    return true
end

local skills = sgs.SkillList()

zhuikongUse = sgs.CreateZeroCardViewAsSkill{
    name = "zhuikongUse",
    response_pattern = "@@zhuikongUse",
    response_or_use = true,
    view_as = function(self)
		local card_id = sgs.Self:getMark("zhuikongCardid") - 1
		local view_as_card = sgs.Sanguosha:getCard(card_id)
        return view_as_card
	end,
}

zhuikong = sgs.CreateTriggerSkill{  
    name = "zhuikong",
    events = {sgs.EventPhaseStart, sgs.Pindian},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start
        and not player:hasSkill(self:objectName()) and not player:isKongcheng() then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and not owner:isKongcheng() then
                return self:objectName(), owner:objectName()
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                return self:objectName(), player:objectName()
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        elseif event == sgs.Pindian then
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            ask_who:pindian(player, self:objectName())
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            local winner = nil
            local card = nil
			local card_id = nil
            if pindian.from_number == pindian.to_number then
                return false
            end
            if pindian.from_number > pindian.to_number then
                winner = pindian.from
                card = pindian.to_card
				card_id = pindian.to_card:getId()
            elseif pindian.from_number < pindian.to_number then
                winner = pindian.to
                card = pindian.from_card
				card_id = pindian.from_card:getId()
            end
			room:setPlayerMark(winner, "zhuikongCardid", card_id + 1)
			local prompt = "惴恐：你可以使用拼点输的牌（【"
			room:askForUseCard(winner, "@@zhuikongUse", prompt .. card:getName() .. "】）")
			room:setPlayerMark(winner, "zhuikongCardid", 0)
        end
        return false
    end
}

qiuyuan = sgs.CreateTriggerSkill{  
    name = "qiuyuan",  
    events = {sgs.TargetConfirming},
      
    can_trigger = function(self, event, room, player, data)  
        if not skillTriggerable(player, self:objectName()) then return false end
          
        local use = data:toCardUse()  
        -- 检查是否是杀且当前角色是目标之一  
        if use.card:isKindOf("Slash") and use.to:contains(player) then  
            -- 检查是否还有其他可选目标  
            local others = room:getOtherPlayers(player)  
            for _, p in sgs.qlist(others) do  
                if not use.to:contains(p) and use.from:canSlash(p, use.card, false) then --第二个条件可以不要 
                    return self:objectName()  
                end  
            end  
        end  
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local others = room:getOtherPlayers(player)  
        local targets = sgs.SPlayerList()  
          
        -- 收集可选目标  
        for _, p in sgs.qlist(others) do  
            if not use.to:contains(p) and use.from:canSlash(p, use.card, false) then  
                targets:append(p)  
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@qiuyuan-choose", true)  
        if target then  
            player:setTag("qiuyuan_target", sgs.QVariant(target:objectName()))  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local target_name = player:getTag("qiuyuan_target"):toString()  
        player:removeTag("qiuyuan_target")  
          
        local target = room:findPlayer(target_name)  
        if target then
            local card = room:askForCard(target, "Jink", "@qiuyuan-give:" .. player:objectName(), data, sgs.Card_MethodNone)
            if card then
                player:obtainCard(card)
            else
                -- 将新目标添加到杀的目标列表中  
                use.to:append(target)  
                room:sortByActionOrder(use.to)  
                data:setValue(use)  
                
                -- 触发新目标的TargetConfirming事件  
                room:getThread():trigger(sgs.TargetConfirming, room, target, data)
            end
        end
        return false
    end
}

fuhuanghou:addSkill(zhuikong)
fuhuanghou:addSkill(qiuyuan)
if not sgs.Sanguosha:getSkill("zhuikongUse") then skills:append(zhuikongUse) end

sgs.LoadTranslationTable{
    ["fuhuanghou"] = "伏皇后",
    ["zhuikong"] = "惴恐",
    [":zhuikong"] = "其他角色的准备阶段，你可以与其拼点，赢的角色可以使用输的角色的拼点牌。",
    ["qiuyuan"] = "求援",
    [":qiuyuan"] = "当你成为杀的目标时，你可以选择另一名其他角色，其选择交给你一张闪或者也成为此杀的目标。",
    ["@qiuyuan-choose"] = "求援：请选择一名其他角色",
    ["@qiuyuan-give"] = "求援：请交给%dest一张【闪】，否则也成为该【杀】的目标",
    ["$zhuikong1"] = "虎豹骁骑，甲兵自当冠宇天下。",
    ["$zhuikong2"] = "非虎贲难入我营，唯坚铠方配锐士。",
    ["$qiuyuan1"] = "虎豹骁骑，甲兵自当冠宇天下。",
    ["$qiuyuan2"] = "非虎贲难入我营，唯坚铠方配锐士。",
    ["~luacaochun"] = "三属之下，竟也护不住我性命…",
}

linlang = sgs.CreateTriggerSkill{
    name = "linlang",
    events = {sgs.FinishJudge},
    can_trigger = function(self, event, room, player, data)
        local judge = data:toJudge()
        local owner = room:findPlayerBySkillName(self:objectName())

        if owner and owner:isAlive() and judge.card:isKindOf("TrickCard") then
            return self:objectName(), owner:objectName()
        end
        return false
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local judge = data:toJudge()  

        local targets = sgs.SPlayerList()
        -- 查找场上所有与判定牌颜色相同的牌  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            for i = 0, 5 do  
                local equip = p:getEquip(i)  
                if equip and (equip:isRed() == judge.card:isRed()) then  
                    targets:append(p)
                    break
                end  
            end  
            
            -- 检查判定区的牌
            if not targets:contains(p) then
                for _, card in sgs.qlist(p:getJudgingArea()) do  
                    if (card:isRed() == judge.card:isRed()) then  
                        targets:append(p)
                        break
                    end  
                end
            end
        end  
        local choices = {"linlang_obtainCard"}
        if not targets:isEmpty() then
            table.insert(choices, "linlang_move")
        end
        local choice
        if #choices > 1 then
            local prompt = "琳琅：请选择一项"
            choice = room:askForChoice(ask_who, self:objectName(), table.concat(choices, "+"), sgs.QVariant(), prompt,
            "linlang_obtainCard+linlang_move")
        else
            choice = choices[1]
        end

        if choice == "linlang_move" then
            local from_player = room:askForPlayerChosen(ask_who, targets, self:objectName(), "@linlang-move-from")
            if not from_player then return false end
            local card_ids = {}
            for _, c in sgs.qlist(from_player:getCards("ej")) do
                if c:isRed() ~= judge.card:isRed() then
                    table.insert(card_ids, c:getId())
                end
            end
            card_ids = Table2IntList(card_ids)
            local card_id = room:askForCardChosen(ask_who, from_player, "ej", self:objectName(), false, sgs.Card_MethodNone,
            card_ids)
            if card_id then
                local card = sgs.Sanguosha:getCard(card_id)
                local to_players = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(from_player)) do
                    if canSetto(card, p) then
                        to_players:append(p)
                    end
                end
                if to_players:isEmpty() then return false end
                local to_player = room:askForPlayerChosen(ask_who, to_players, self:objectName(), "@linlang-move-to")
                if from_player and to_player then
                    if card:isKindOf("EquipCard") then
                        -- 移动装备牌  
                        room:moveCardTo(card, to_player, sgs.Player_PlaceEquip)
                    else
                        -- 移动判定区的牌  
                        room:moveCardTo(card, to_player, sgs.Player_PlaceDelayedTrick)
                    end
                end
            end
        else --超时未选择等原因则默认获得
            ask_who:obtainCard(judge.card)
        end
        return false
    end
}

luoyingTurn = sgs.CreateTriggerSkill{
    name = "luoyingTurn",
    events = {sgs.Damaged, sgs.TurnedOver, sgs.EventPhaseChanging},
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.Damaged and skillTriggerable(player, self:objectName()) then
            return self:objectName()
        elseif skillTriggerable(player, self:objectName()) and event == sgs.TurnedOver and player:faceUp() then
            return self:objectName()
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("luoyingTurnget") then
                        local phases = sgs.PhaseList()
                        phases:append(sgs.Player_Play)
                        phases:append(sgs.Player_NotActive)
                        p:play(phases)
                        room:broadcastProperty(p, "phase")
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
      
    on_effect = function(self, event, room, player, data)
        if event == sgs.Damaged then  
            local lost_hp = player:getLostHp()  
            if lost_hp > 0 then  
                -- 摸X张牌  
                player:drawCards(lost_hp, self:objectName())  
                
                -- 叠置  
                player:turnOver()  
            end  
        elseif event == sgs.TurnedOver then
            local judge = sgs.JudgeStruct()  
            judge.pattern = ".|club"  
            judge.good = true  
            judge.reason = self:objectName()
            judge.who = player  
            
            room:judge(judge)  
            
            -- 若判定牌为梅花，获得一个出牌阶段  
            if judge.card:getSuit() == sgs.Card_Club then  
                room:setPlayerFlag(player, "luoyingTurnget")
            end  
        end
        return false  
    end,  
}

caozhi_xianxia:addSkill(linlang)
caozhi_xianxia:addSkill(luoyingTurn)

sgs.LoadTranslationTable{
    ["#caozhi_xianxia"] = "八斗之才",  
    ["caozhi_xianxia"] = "曹植",   
    ["linlang"] = "琳琅",  
    [":linlang"] = "当一名角色的判定牌生效后，若判定牌为锦囊牌，你可以选择（1）获得该判定牌（2）移动场上一张与此牌颜色相同的牌。",  
    ["luoyingTurn"] = "落英",  
    [":luoyingTurn"] = "当你受到伤害后，你可以摸X张牌并叠置（X为你已失去的体力值）。当你从叠置状态恢复时，你可以进行一次判定，若判定牌为梅花，此回合结束后你获得一个出牌阶段。",
    ["@linlang-move-from"] = "落英：请选择要移动的角色",
    ["@linlang-move-to"] = "落英：请选择要移动至装备区/判定区的角色",
    ["linlang_obtainCard"] = "获得该锦囊牌",
    ["linlang_move"] = "移动场上一张牌",
}

sgs.Sanguosha:addSkills(skills)

return {xianxia_x}

--[[
		local log = sgs.LogMessage()
		log.type = "readytodraw"
		log.from = player
		log.to:append(player)
		room:sendLog(log)
]]--