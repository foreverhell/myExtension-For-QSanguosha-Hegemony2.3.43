extension = sgs.Package("xinyue", sgs.Package_GeneralPack)  
  
-- 创建武将蒙恬  
guoyouzhi = sgs.General(extension, "guoyouzhi", "shu", 3) -- 蜀势力，4血，男性（默认）  

zhongyu = sgs.CreateTriggerSkill{  
    name = "zhongyu",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Play then  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) and p ~= player and p:isAlive() then  
                    return self:objectName(), p:objectName()
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local _data = sgs.QVariant()  
        _data:setValue(player)  
        return room:askForSkillInvoke(ask_who, self:objectName(), _data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 各摸1张牌  
        local players = sgs.SPlayerList()  
        players:append(player)  
        players:append(ask_who)  
        room:drawCards(players, 1, self:objectName())  
            
        -- 依次弃置1张牌  
        local player_discard = nil  
        local zhongyu_discard = nil  
            
        if not player:isNude() then  
            local card_id = room:askForCardChosen(player, player, "he", self:objectName())  
            player_discard = sgs.Sanguosha:getCard(card_id)  
            room:throwCard(card_id, player, nil)  
        end  
            
        if ask_who:getHandcardNum() > 0 then  
            local card_id = room:askForCardChosen(ask_who, ask_who, "he", self:objectName())  
            zhongyu_discard = sgs.Sanguosha:getCard(card_id)  
            room:throwCard(card_id, ask_who, nil)  
        end  
            
        -- 检查颜色是否相同  
        if player_discard and zhongyu_discard then  
            if player_discard:sameColorWith(zhongyu_discard) then  
                player:drawCards(1, self:objectName())  
            end  
        end  
        return false  
    end  
}

guoyouzhi:addSkill(zhongyu)

sgs.LoadTranslationTable{
["#guoyouzhi"] = "忠贞谏臣",  
["guoyouzhi"] = "郭攸之",  
["illustrator:guoyouzhi"] = "画师名",  
["zhongyu"] = "忠喻",  
[":zhongyu"] = "其他角色出牌阶段开始时，你可以令其与你各摸1张牌，然后其与你依次弃置1张牌，若弃置的牌颜色相同，其摸1张牌。"
}

lvboshe = sgs.General(extension, "lvboshe", "qun", 3) -- 蜀势力，4血，男性（默认）  
  
-- 款宴技能卡  
kuanyan_card = sgs.CreateSkillCard{  
    name = "kuanyan",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        room:setPlayerMark(target, "@kuanyan_yan", 1)    
    end  
}  
kuanyanVS = sgs.CreateViewAsSkill{  
    name = "kuanyan",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = kuanyan_card:clone()  
            card:addSubcard(cards[1]:getId())  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())  
            return card  
        end  
        return nil  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#kuanyan")
    end  
}  
-- 款宴技能实现（监控使用牌）  
kuanyan = sgs.CreateTriggerSkill{  
    name = "kuanyan",  
    events = {sgs.CardUsed, sgs.CardResponsed, sgs.EventPhaseStart},  
    view_as_skill = kuanyanVS,
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:getMark("@kuanyan_yan") > 0 then  
                        room:setPlayerMark(p,"@kuanyan_yan",0)
                    end  
                end  
            end  
        else  
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                local card = use.card
                if not (card and (card:getTypeId() == sgs.Card_TypeBasic or card:getTypeId() == sgs.Card_TypeTrick)) then return "" end
                -- 监控使用牌  
                if use.from:getMark("@kuanyan_yan") > 0 and not use.from:hasFlag("kuanyan_used_card") then                  
                    local source = room:findPlayerBySkillName(self:objectName())
                    if source and source:isAlive() and source:hasSkill(self:objectName()) then
                        room:setPlayerFlag(use.from,"kuanyan_used_card")
                        return self:objectName(), source:objectName()
                    end  
                end  
            end  
            return ""  
        end  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 摸2张牌  
        ask_who:drawCards(2, "kuanyan")  
            
        -- 交给目标1张牌  
        if not ask_who:isNude() then  
            local card_id = room:askForCardChosen(ask_who, ask_who, "he", "kuanyan")  
            room:obtainCard(player, card_id, false)  
        end  
            
        -- 检查是否体力值全场最低  
        local min_hp = 999  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getHp() < min_hp then  
                min_hp = p:getHp()  
            end  
        end  
            
        if player:getHp() == min_hp then  
            local recover = sgs.RecoverStruct()  
            recover.who = ask_who  
            recover.recover = 1  
            room:recover(player, recover)  
        end  
        return false  
    end  
}  

lvboshe:addSkill(kuanyan)  

sgs.LoadTranslationTable{
["#lvboshe"] = "好客长者",  
["lvboshe"] = "吕伯奢",  
["illustrator:lvboshe"] = "画师名",  
["kuanyan"] = "款宴",  
[":kuanyan"] = "出牌阶段限一次，你可以弃置一张牌，并选择一名其他角色，令其获得一个'宴'标记。直到你的下回合开始，拥有'宴'标记的角色每回合使用第一张基本牌和锦囊牌后，你摸2张牌并交给其1张牌，若其体力值全场最低，其恢复一点体力。",  
["@kuanyan_yan"] = "宴"
}

ying4yang = sgs.General(extension, "ying4yang", "jin", 3) -- 蜀势力，4血，男性（默认）  
guici = sgs.CreateTriggerSkill{  
    name = "guici",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
               and player:getPhase() == sgs.Player_Start  then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技无需消耗  
    end,  
    on_effect = function(self, event, room, player, data)  
        local yin_mark = player:getMark("@guici_yin")  
        local yang_mark = player:getMark("@guici_yang")  
          
        -- 处理阴阳标记  
        if yin_mark == 0 and yang_mark == 0 then  
            -- 没有标记，选择获得阴或阳标记  
            local choice = room:askForChoice(player, self:objectName(), "yin+yang", data)  
            if choice == "yin" then  
                room:setPlayerMark(player, "@guici_yin", 1)  
            else  
                room:setPlayerMark(player, "@guici_yang", 1)  
            end  
            yin_mark = player:getMark("@guici_yin")  
            yang_mark = player:getMark("@guici_yang")  
        else  
            -- 有标记，交替  
            if yin_mark > 0 then  
                room:setPlayerMark(player, "@guici_yin", 0)  
                room:setPlayerMark(player, "@guici_yang", 1)  
                yang_mark = 1  
                yin_mark = 0  
            else  
                room:setPlayerMark(player, "@guici_yang", 0)  
                room:setPlayerMark(player, "@guici_yin", 1)  
                yin_mark = 1  
                yang_mark = 0  
            end  
        end  
          
        -- 根据标记获得牌  
        if yang_mark > 0 then  
            for _, id in sgs.qlist(room:getDrawPile()) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:getSuit() == sgs.Card_Heart then  
                    card:setFlags("guici_gui")
                    room:obtainCard(source, id) 
                    break 
                end  
            end  
            for _, id in sgs.qlist(room:getDrawPile()) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:getSuit() == sgs.Card_Club then  
                    room:obtainCard(source, id)
                    card:setFlags("guici_gui")
                    break 
                end  
            end  
            for _, id in sgs.qlist(room:getDrawPile()) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:getSuit() == sgs.Diamond then  
                    room:obtainCard(source, id)
                    card:setFlags("guici_gui")
                    break 
                end  
            end
            for _, id in sgs.qlist(room:getDrawPile()) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:getSuit() == sgs.Card_Spade then  
                    room:obtainCard(source, id)
                    card:setFlags("guici_gui")
                    break 
                end  
            end
        elseif yin_mark > 0 then  
            for _, id in sgs.qlist(room:getDrawPile()) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:getTypeId() == sgs.Card_TypeBasic then  
                    card:setFlags("guici_gui")
                    room:obtainCard(source, id) 
                    break 
                end  
            end  
            for _, id in sgs.qlist(room:getDrawPile()) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:getTypeId() == sgs.Card_TypeTrick then  
                    room:obtainCard(source, id)
                    card:setFlags("guici_gui")
                    break 
                end  
            end  
            for _, id in sgs.qlist(room:getDrawPile()) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:getTypeId() == sgs.Card_TypeEquip then  
                    room:obtainCard(source, id)
                    card:setFlags("guici_gui")
                    break 
                end  
            end
        end  
          
        return false  
    end,
}

beili = sgs.CreateTriggerSkill{  
    name = "beili",  
    events = {sgs.Damaged},  
    can_trigger = function(self, event, room, player, data)  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:hasSkill(self:objectName()) and p:isAlive() and not p:isNude() then  
                return self:objectName(), p:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local _data = sgs.QVariant()  
        _data:setValue(player)  
        if room:askForSkillInvoke(ask_who, self:objectName(), _data) then  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 选择弃置的牌  
        local card_id = room:askForCardChosen(ask_who, ask_who, "he", self:objectName())  
        local card = sgs.Sanguosha:getCard(card_id)  
        room:throwCard(card_id, ask_who, nil)  

        -- 令受伤角色摸1张牌  
        player:drawCards(1, self:objectName())  
        ask_who:drawCards(1, self:objectName()) 
        -- 若弃置的牌有'瑰'标记，自己摸1张牌  
        --if card:hasFlag("guici_gui") then  
        --    ask_who:drawCards(1, self:objectName())  
        --end  
        return false  
    end  
}

--ying4yang:addSkill(guici)  
ying4yang:addSkill(beili)

sgs.LoadTranslationTable{
["#ying4yang"] = "文采风流",  
["ying4yang"] = "应玚",  
["illustrator:ying4yang"] = "画师名",  
["guici"] = "瑰词",  
[":guici"] = "锁定技，你的准备阶段，若你没有阴/阳标记，你选择获得阴标记或阳标记；若你有阴/阳标记，阴/阳标记交替。若你有阳标记，你从牌堆获得4张花色各不相同的牌，并标记为'瑰'；若你有阴标记，你从牌堆获得3张类型各不相同的牌，并标记为'瑰'。",  
["@guici_yin"] = "阴",  
["@guici_yang"] = "阳",  
["yin"] = "阴",  
["yang"] = "阳",  
["beili"] = "悲离",  
[":beili"] = "当一名角色受到伤害后，你可以弃置一张牌，令其摸一张牌，你摸1张牌。"
}

zhangbu = sgs.General(extension, "zhangbu", "wu", 3) -- 蜀势力，4血，男性（默认）  

guzhu = sgs.CreateTriggerSkill{  
    name = "guzhu",  
    events = {sgs.TargetConfirmed},  
    can_trigger = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        if use.card and use.card:getTypeId() == sgs.Card_TypeBasic and not use.card:hasFlag("guzhu") then  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) and p:getHandcardNum() > 0 then  
                    return self:objectName(), p:objectName()
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local _data = sgs.QVariant()  
        _data:setValue(player)  
        if room:askForSkillInvoke(ask_who, self:objectName(), _data) then  
            -- 弃置所有手牌  
            ask_who:throwAllHandCards()  
            return false  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        --[[
        -- 让此牌额外结算一次
        local new_use = sgs.CardUseStruct()  
        local new_card = use.card--sgs.Sanguosha:cloneCard(use.card:getName(), use.card:getSuit(), use.card:getNumber())  
        new_card:setFlags("guzhu")
        new_use.card = new_card 
        new_use.from = use.from  
        new_use.to = use.to  
        room:useCard(new_use, false)  
        ]]
        room:useCard(sgs.CardUseStruct(use.card,use.from,use.to),false)
        return false  
    end  
}

zhuanzheng = sgs.CreateTriggerSkill{  
    name = "zhuanzheng",  
    events = {sgs.CardsMoveOneTime},  
    --[[
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return ""  end       
        local move = data:toMoveOneTime()  
        if move.from:getHandcardNum() == 0 then  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) then  
                    return self:objectName() .. "->" .. move.from:objectName()
                end  
            end  
        end  
        return ""  
    end,  
    ]]
    can_trigger = function(self, event, room, player, data)  
        local move = data:toMoveOneTime()  
        if player:getHandcardNum() == 0 then  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) and p:willBeFriendWith(player) then  
                    return self:objectName() .. "->" .. player:objectName()
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local move = data:toMoveOneTime()  
        local target = move.from  
           
        local _data = sgs.QVariant()  
        _data:setValue(target)  
        if room:askForSkillInvoke(ask_who, self:objectName(), _data) then  
            -- 失去1点体力  
            room:loseHp(ask_who, 1)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local move = data:toMoveOneTime()  
        local target = player--move.from  
          
        if target and target:isAlive() then  
            local draw_num = target:getMaxHp() - target:getHandcardNum()  
            if draw_num > 0 then  
                target:drawCards(draw_num, self:objectName())  
            end  
        end  
        return false  
    end  
    --[[
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
                    if move.from_places:contains(sgs.Player_PlaceHand) then
                        if move.from and move.from:isAlive() and move.from:isKongcheng() then
                            return self:objectName()
                        end
                    end
				end
			end
		end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local move = data:toMoveOneTime()  
        local target = move.from  
           
        local _data = sgs.QVariant()  
        _data:setValue(target)  
        if room:askForSkillInvoke(player, self:objectName(), _data) then  
            -- 失去1点体力  
            room:loseHp(player, 1)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local current = room:getCurrent()
        if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
            local move_datas = data:toList()
            for _, move_data in sgs.qlist(move_datas) do
                local move = move_data:toMoveOneTime()
                local draw_num = move.from:getMaxHp() - move.from:getHandcardNum()  
                if draw_num > 0 then  
                    move.from:drawCards(draw_num, self:objectName())  
                end                          
            end
        end
        return false  
    end  
    ]]
}
--zhangbu:addSkill(guzhu)  
zhangbu:addSkill(zhuanzheng)
sgs.LoadTranslationTable{
["#zhangbu"] = "权谋之士",  
["zhangbu"] = "张布",  
["illustrator:zhangbu"] = "画师名",  
["guzhu"] = "孤注",  
[":guzhu"] = "一名角色使用基本牌指定目标后，你可以弃置所有手牌，令此牌额外结算1次。",  
["zhuanzheng"] = "专政",  
[":zhuanzheng"] = "与你势力相同的角色失去手牌后，若其手牌数为0，其可以失去1点体力，然后其将手牌摸至体力上限。"
}
-- 返回扩展包  
return {extension}