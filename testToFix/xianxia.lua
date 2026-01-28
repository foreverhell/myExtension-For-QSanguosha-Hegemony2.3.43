-- 创建扩展包  
xianxia_x = sgs.Package("xianxia_x",sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
    ["xianxia_x"] = "线下包-X",
}
--建立武将
--魏势力

--蜀势力

--吴势力

--群势力
fuhuanghou = sgs.General(xianxia_x, "fuhuanghou", "qun", 3, false)

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
        if not player:hasSkill(self:objectName()) then return "" end  
          
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
        return ""  
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
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@fuhuanghou2-choose", true)  
        if target then  
            player:setTag("fuhuanghou2_target", sgs.QVariant(target:objectName()))  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local target_name = player:getTag("fuhuanghou2_target"):toString()  
        player:removeTag("fuhuanghou2_target")  
          
        local target = room:findPlayer(target_name)  
        if target then
            local card = room:askForCard(target, "Jink", "@fuhuanghou2-give:" .. player:objectName(), data, sgs.Card_MethodNone)
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