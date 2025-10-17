-- 创建扩展包  
extension = sgs.Package("junba",sgs.Package_GeneralPack)  

caocao_yuanshao = sgs.General(extension, "caocao_yuanshao", "qun", 3)  -- 吴国，4血，男性  
jiechuYin_card = sgs.CreateSkillCard{  
    name = "jiechuYin",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:distanceTo(to_select)<=1
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 视为对目标使用顺手牵羊  
        local snatch = sgs.Sanguosha:cloneCard("snatch")  
        snatch:setSkillName("jiechuYin")
        snatch:deleteLater()  
        local use = sgs.CardUseStruct()  
        use.card = snatch  
        use.from = source  
        use.to:append(target)  
        room:useCard(use, false)  

        --[[
        if target:canSlash(source, nil, false) then  
            use_slash = room:askForUseSlashTo(target, source, "@jiechuYin-slash:" .. source:objectName())  
        end  
        ]]
        -- 目标视为对你使用一张杀  
        local slash = sgs.Sanguosha:cloneCard("slash")  
        slash:setSkillName("jiechuYin")  
        slash:deleteLater()
        if target:canSlash(source, slash, false) then  
            local use2 = sgs.CardUseStruct()  
            use2.card = slash  
            use2.from = target  
            use2.to:append(source)  
            room:useCard(use2, false)  
        end  
    end  
}  
  
-- 劫出-阴主动技能  
jiechuYin_skill = sgs.CreateZeroCardViewAsSkill{  
    name = "jiechuYin",  
    view_as = function(self)  
        card = jiechuYin_card:clone()  
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#jiechuYin")
    end  
}  
  
-- 劫出-阳技能  
jiechuYang_skill = sgs.CreateTriggerSkill{  
    name = "jiechuYang",  
    events = {sgs.TargetConfirming},  
      
    can_trigger = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        if use.card and use.card:isKindOf("Slash") then  
            for _, target in sgs.qlist(use.to) do  
                if target:hasSkill(self:objectName()) and target:isAlive() and not target:isKongcheng() then  
                    return self:objectName(),target:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            local card = room:askForDiscard(ask_who, self:objectName(), 1, 1, true, false, "@jiechuYang-discard")  
            if card then  
                room:broadcastSkillInvoke(self:objectName())  
                return true  
            end  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        local slash = use.card  
          
        -- 改变杀的花色和属性  
        local suits = {"spade", "heart", "club", "diamond"}  
        local suit = room:askForChoice(ask_who, self:objectName(), table.concat(suits, "+"), data)  

        local natures = {"normal", "fire", "thunder"}  
        local nature = room:askForChoice(ask_who, self:objectName(), table.concat(natures, "+"), data)  

        local new_slash
        if nature=="normal" then
            if suit == "heart" then  
                new_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_Heart, slash:getNumber())  
            elseif suit == "diamond" then  
                new_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_Diamond, slash:getNumber())  
            elseif suit == "spade" then  
                new_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_Spade, slash:getNumber())  
            elseif suit == "club" then  
                new_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_Club, slash:getNumber())  
            end
        elseif nature=="fire" then
            if suit == "heart" then  
                new_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_Heart, slash:getNumber())  
            elseif suit == "diamond" then  
                new_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_Diamond, slash:getNumber())  
            elseif suit == "spade" then  
                new_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_Spade, slash:getNumber())  
            elseif suit == "club" then  
                new_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_Club, slash:getNumber())  
            end
        elseif nature=="thunder" then
            if suit == "heart" then  
                new_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_Heart, slash:getNumber())  
            elseif suit == "diamond" then  
                new_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_Diamond, slash:getNumber())  
            elseif suit == "spade" then  
                new_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_Spade, slash:getNumber())  
            elseif suit == "club" then  
                new_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_Club, slash:getNumber())  
            end
        end
          
        new_slash:setSkillName(slash:getSkillName())  
        use.card = new_slash  
        data = sgs.QVariant()  
        data:setValue(use)  
        return false  
    end  
}  
  
-- 道抉技能  
daojue_skill = sgs.CreateTriggerSkill{  
    name = "daojue",  
    events = {sgs.Damaged},--DamageInflicted  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:hasSkill(self:objectName()) and player:isAlive() then  
            local damage = data:toDamage()  
            if damage.card then  
                local suit = damage.card:getSuit()  
                local mark_name = "daojue_" .. suit .. "_used"  
                if player:getMark(mark_name) == 0 then  
                    return self:objectName()  
                end  
            end  
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
        local damage = data:toDamage()  
        local suit = damage.card:getSuit()  
        local mark_name = "daojue_" .. suit .. "_used"  
          
        -- 设置该花色已使用
        room:setPlayerMark(player, mark_name, 1)  
                    
        -- 选择效果  
        local choice = room:askForChoice(player, self:objectName(), "obtain+slash_all", data)  
          
        if choice == "obtain" then  
            -- 获得伤害牌  
            if damage.card then  
                player:obtainCard(damage.card)  
            end  
        else  
            -- 视为对所有其他角色使用杀  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:setSkillName(self:objectName())  
            slash:deleteLater()
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if player:canSlash(p, slash, false) then  
                    targets:append(p)  
                end  
            end  
              
            if not targets:isEmpty() then  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = player  
                for _, target in sgs.qlist(targets) do  
                    use.to:append(target)  
                end  
                room:useCard(use, false)  
            end  
        end  
        -- 防止伤害  
        --damage.damage = 0  
        --data = sgs.QVariant()  
        --data:setValue(damage)  
        return false --不防止伤害  
    end  
}  

guibei_skill = sgs.CreateTriggerSkill{  
    name = "guibei",  
    events = {sgs.GameStart},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        owner = room:findPlayerBySkillName(self:objectName())
        if owner:getSeat()~=1 then return "" end --必须在1号位
        if owner and owner:isAlive() and owner:hasSkill(self:objectName()) then
            return self:objectName(), owner:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName())
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 摸4张牌  
        ask_who:drawCards(4, self:objectName())  
            
        -- 找到末置位玩家  
        local players = room:getAlivePlayers()  
        local last_player = nil  
            
        -- 末置位是座次最大的玩家  
        local max_seat = 0  
        for _, p in sgs.qlist(players) do  
            if p:getSeat() > max_seat then  
                max_seat = p:getSeat()  
                last_player = p  
            end  
        end  
            
        -- 如果找到末置位且不是自己，则交换座次  
        if last_player and last_player:objectName() ~= ask_who:objectName() then  
            local player_seat = ask_who:getSeat()  
            local last_seat = last_player:getSeat()  
                
            -- 交换座次  
            room:swapSeat(ask_who, last_player)  
                
            -- 发送日志消息  
            local log = sgs.LogMessage()  
            log.type = "#SwapSeat"  
            log.from = ask_who  
            log.to:append(last_player)  
            room:sendLog(log)  
        end  
    end  
}
-- 添加技能到武将  
caocao_yuanshao:addSkill(jiechuYin_skill)  
--caocao_yuanshao:addSkill(jiechuYang_skill)  
caocao_yuanshao:addSkill(daojue_skill)
caocao_yuanshao:addSkill(guibei_skill)

-- 翻译表  
sgs.LoadTranslationTable{
["caocao_yuanshao"] = "曹操&袁绍",  
["jiechuYin"] = "劫出-阴",  
[":jiechuYin"] = "出牌阶段限一次。你可以选择一名角色，视为你对其使用顺手牵羊，然后其视为对你使用一张杀。",  
["jiechuYang"] = "劫出-阳",   
[":jiechuYang"] = "当你成为杀的目标时，你可以弃置一张手牌改变该杀的花色和属性。",  
["daojue"] = "道抉",  
[":daojue"] = "本轮游戏中，当你首次受到一种花色的牌造成的伤害时，你可以选择：（1）获得伤害牌（2）视为对所有其他角色使用一张杀。",  
["@jiechuYang-discard"] = "劫出-阳：弃置一张手牌改变杀的花色和属性",  
["obtain"] = "获得伤害牌",  
["slash_all"] = "对所有其他角色使用杀",
["guibei"] = "贵卑",  
[":guibei"] = "游戏开始时，若你是1号位，你可以摸4张牌，然后和末置位交换座次。",  
["#SwapSeat"] = "%from 与 %to 交换了座次",
["normal"] = "无",
["thunder"] = "雷",
["fire"] = "火",
["spade"] = "黑桃",
["club"] = "梅花",
["heart"] = "红桃",
["diamond"] = "方片"
}  
-- 创建武将  
caochong = sgs.General(extension, "caochong", "wei", 3)  

chengxiang = sgs.CreateTriggerSkill{
    name = "chengxiang",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)
        local top_cards = room:getNCards(4)
        room:askForGuanxing(player, top_cards, sgs.Room_GuanxingUpOnly)-- GuanxingUpOnly, GuanxingBothSides, GuanxingDownOnly
        local total_points = 0
        --循环方法一
        for i=1,4 do  
            -- 从牌堆顶获得一张牌  
            local card_id = room:drawCard()  
            if not card_id then break end  -- 牌堆空了  
            
            local card = sgs.Sanguosha:getCard(card_id)  
            total_points = total_points + card:getNumber()  
            if total_points <= 13 then
                -- 将卡牌加入手牌  
                room:obtainCard(player, card_id)
                if total_points==13 and not player:faceUp() then 
                    player:turnOver()
                end
            end                  
        end 
        return false          
    end
}

caochong:addSkill(chengxiang)
sgs.LoadTranslationTable{
    ["junba"] = "军八",
    ["caochong"] = "曹冲",
    ["chengxiang"] = "称象",
    [":chengxiang"] = "当你受到伤害时，你可以查看牌堆顶的4张牌，并以任意顺序排列，然后依次展示，你获得点数和不大于13的所有牌，其余牌置入弃牌堆。若你获得牌的点数和等于13，你复原。",
}

caofang = sgs.General(extension, "caofang", "wei", 3)  -- 吴国，4血，男性  

zhimin_card = sgs.CreateSkillCard{  
    name = "zhimin_card",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets < sgs.Self:getHp() and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,  
    feasible = function(self, targets)  
        return #targets > 0 and #targets <= sgs.Self:getHp()  
    end,  
    on_use = function(self, room, source, targets)  
        for _, target in ipairs(targets) do  
            if not target:isKongcheng() then  
                local cards = target:getHandcards()  
                local min_point = 14  
                local min_cards = {}  
                  
                -- 找到点数最小的牌  
                for _, card in sgs.qlist(cards) do  
                    if card:getNumber() < min_point then  
                        min_point = card:getNumber()  
                        min_cards = {card:getId()}  
                    elseif card:getNumber() == min_point then  
                        table.insert(min_cards, card:getId())  
                    end  
                end  
                  
                if #min_cards > 0 then  
                    local card_id = min_cards[1]  
                    --room:obtainCard(player, card_id)
                    local move = sgs.CardsMoveStruct()  
                    move.card_ids:append(card_id)  
                    move.to = source  
                    move.to_place = sgs.Player_PlaceHand  
                    move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, source:objectName(), "zhimin", "")  
                    room:moveCardsAtomic(move, true)  
                end  
            end  
        end  
    end  
}  
  
zhimin = sgs.CreateZeroCardViewAsSkill{  
    name = "zhimin",  
    view_as = function(self)  
        return zhimin_card:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#zhimin_card")  
    end  
}  


caofang:addSkill(zhimin)

sgs.LoadTranslationTable{  
    ["junba"] = "军八",  
      
    ["caofang"] = "曹芳",  
    ["#caofang"] = "高贵乡公",  
    ["illustrator:caofang"] = "未知",  
      
    ["zhimin"] = "置民",  
    [":zhimin"] = "出牌阶段限一次，你可以选择至多X名其他角色，令其将点数最小的牌交给你（X为你的体力值）。",  
    ["zhimin_card"] = "置民",  
    ["$zhimin1"] = "民为邦本，本固邦宁。",  
    ["$zhimin2"] = "置民安邦，方显君德。",  
    ["~caofang"] = "江山如此多娇...",  
}  
caomao = sgs.General(extension, "caomao", "wei", 3)  
  
-- 潜龙技能  
qianlong = sgs.CreateTriggerSkill{  
    name = "qianlong",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
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
        --[[
        local lost_hp = player:getMaxHp() - player:getHp()  
        local cards = room:getNCards(3, false)  
         
        local to_get = {}  
        for i = 1, math.min(lost_hp, 3) do  
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
            --room:returnToTopDrawPile(id)  
            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, sgs.Player_DrawPile, true) 
        end  
        ]]
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
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(),   
                                             "@fensi-choose", true, true)  
          
        if target and target:isAlive() then  
            local damage = sgs.DamageStruct()  
            damage.from = player  
            damage.to = target  
            damage.damage = 1  
            room:damage(damage)  
              
            if target:objectName() ~= player:objectName() and target:isAlive() then  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)  
                slash:setSkillName(self:objectName())  
                slash:deleteLater()
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
[":qianlong"] = "当你受到伤害后，你可以展示牌堆顶的三张牌，然后获得其中至多X张，其余置入弃牌堆，X为已失去的体力值。",  
["fensi"] = "忿肆",  
[":fensi"] = "回合开始时，你对一名体力值大于等于你的角色造成1点伤害，若其不为你，其视为对你使用一张杀。",  
["@fensi-choose"] = "忿肆：选择一名体力值大于等于你的角色",
}
xing_caoren = sgs.General(extension, "xing_caoren", "jin", 3)  -- 吴国，4血，男性  

sujun = sgs.CreateTriggerSkill{  
    name = "sujun",  
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,    
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local cur_card = nil
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            cur_card = use.card
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()
            cur_card = response.m_card
        end
        if cur_card == nil or cur_card:getTypeId()==sgs.Card_TypeSkill then return "" end
        -- 检查手牌中基本牌和非基本牌数量  
        local basic_count = 0  
        local non_basic_count = 0  
        local handcards = player:getHandcards()  
          
        for _, card in sgs.qlist(handcards) do  
            if card:getTypeId() == sgs.Card_TypeBasic then  
                basic_count = basic_count + 1  
            else  
                non_basic_count = non_basic_count + 1  
            end  
        end  
          
        if basic_count == non_basic_count then  
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
        room:drawCards(player, 1, self:objectName())  
        return false  
    end  
}

pofeng_vs = sgs.CreateViewAsSkill{  
    name = "pofeng",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        if #selected >= 1 or to_select:isEquipped() then return false end  
          
        -- 检查该花色是否已经使用过  
        local suit = to_select:getSuit()  
        local suit_mark = "pofeng_" .. to_select:getSuitString()  
          
        return not sgs.Self:hasFlag(suit_mark) 
    end,  
    view_as = function(self, cards)  
        if #cards ~= 1 then return nil end  
          
        local card = cards[1]  
        local suit = card:getSuitString()  
        local number = card:getNumberString()  
        local card_id = card:getEffectiveId()  
                    
        local new_card = nil
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()  
        if pattern == "nullification" then  
            new_card = sgs.Sanguosha:cloneCard("nullification")  
        else  
            new_card = sgs.Sanguosha:cloneCard("slash")  
        end  
          
        new_card:setSkillName("pofeng")  
        new_card:setShowSkill("pofeng")  
        new_card:addSubcard(card_id)  
        return new_card  
    end,  
    enabled_at_play = function(self, player)  
        if player:isKongcheng() then return false end  
          
        -- 检查是否还有可用的花色  
        local handcards = player:getHandcards()  
        for _, card in sgs.qlist(handcards) do  
            local suit_mark = "pofeng_" .. card:getSuitString()  
            if not player:hasFlag(suit_mark)  then  
                return true  
            end  
        end  
        return false  
    end,  
    enabled_at_response = function(self, player, pattern)  
        if player:isKongcheng() then return false end  
        if pattern ~= "slash" and pattern ~= "nullification" then return false end  
          
        -- 检查是否还有可用的花色  
        local handcards = player:getHandcards()  
        for _, card in sgs.qlist(handcards) do  
            local suit_mark = "pofeng_" .. card:getSuitString()  
            if not player:hasFlag(suit_mark)  then  
                return true  
            end  
        end  
        return false  
    end,  
    enabled_at_nullification = function(self, player)  
        return not player:isKongcheng() --self.enabled_at_response(self, player, "nullification")  
    end  
}  
  
-- 破锋主技能，用于处理花色限制和选择  
pofeng = sgs.CreateTriggerSkill{  
    name = "pofeng",  
    events = {sgs.CardUsed},  
    view_as_skill = pofeng_vs,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
          
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            if use.card and use.card:getSkillName() == "pofeng" then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.CardUsed then  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            if use.card and use.card:getSkillName() == "pofeng" then  
                -- 标记该花色已使用  
                local subcards = use.card:getSubcards()  
                if not subcards:isEmpty() then  
                    local card = sgs.Sanguosha:getCard(subcards:first())  
                    local suit_mark = "pofeng_" .. card:getSuitString()  
                    room:setPlayerFlag(player, suit_mark)  
                end  
            end  
        end  
        return false  
    end  
}
xing_caoren:addSkill(sujun)  
xing_caoren:addSkill(pofeng)
-- 翻译表  
sgs.LoadTranslationTable{
    ["xing_caoren"] = "星曹仁",
    ["sujun"] = "肃军",
    [":sujun"] = "你使用或打出牌时，若你手牌中基本牌和非基本牌数量相等，你摸1张牌。",
    ["pofeng"] = "破锋",
    [":pofeng"] = "每回合每种花色限一次。你可以使用1张牌当杀或无懈可击"
}  

caozhi = sgs.General(extension, "caozhi", "wei", 3)  

-- 羽化技能  
luoying = sgs.CreateTriggerSkill{  
    name = "luoying",  
    events = {sgs.CardsMoveOneTime},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from and move.from:isAlive() and move.from:objectName()~=player:objectName() then
                            for _,card_id in sgs.qlist(move.card_ids) do
                                local card = sgs.Sanguosha:getCard(card_id)  
                                if card:getSuit() == sgs.Card_Club then  
                                    return self:objectName()
                                end
                            end 
                        end
					end
				end
			end
		end     
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)            
        return player:askForSkillInvoke(self:objectName(), data) 
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local move_datas = data:toList()
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            for _,card_id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:getSuit() == sgs.Card_Club then  
                    player:obtainCard(card)
                end
            end 
        end
        return false  
    end  
}  

jiushi_vs = sgs.CreateZeroCardViewAsSkill{  
    name = "jiushi",  
    response_pattern = "analeptic",  
    view_as = function(self, cards)  
        local analeptic = sgs.Sanguosha:cloneCard("analeptic")  
        analeptic:setSkillName(self:objectName())  
        return analeptic  
    end,  
    enabled_at_play = function(self, player)  
        return player:faceUp()  
    end,  
    enabled_at_response = function(self, player, pattern)  
        return player:faceUp() and string.find(pattern,"analeptic")
    end  
}  
  
-- 酒诗：翻面效果  
jiushi = sgs.CreateTriggerSkill{  
    name = "jiushi",  
    events = {sgs.PreCardUsed, sgs.Damaged},  
    view_as_skill = jiushi_vs,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()  
            if use.card:getSkillName() == "jiushi" and player:faceUp() then  
                return self:objectName()  
            end
        elseif event == sgs.Damaged then
            if not player:faceUp() then  
                return self:objectName()  
            end  
        end
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.PreCardUsed then
            return true
        elseif event == sgs.Damaged then
            return room:askForSkillInvoke(player, self:objectName(), data)
        end
    end,  
    on_effect = function(self, event, room, player, data)  
        player:turnOver()  
        return false  
    end  
}  

caozhi:addSkill(luoying)
caozhi:addSkill(jiushi)
sgs.LoadTranslationTable{
    ["caozhi"] = "曹植",
    ["luoying"] = "落英",
    [":luoying"] = "其他角色的一张​​梅花牌​​因弃置而置入弃牌堆时，你可以获得之。",
    ["jiushi"] = "酒诗",
    [":jiushi"] = "当你需要使用【酒】时，若武将牌正面向上，可翻面视为使用【酒】；当你受到伤害后，若武将牌背面向上，可翻回正面"
}


fengyu = sgs.General(extension, "fengyu", "jin", 3, false)  

tiqi = sgs.CreateTriggerSkill{  
    name = "tiqi",  
    events = {sgs.DrawNCards, sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        local fengyu = room:findPlayerBySkillName(self:objectName())  
        if not fengyu or not fengyu:isAlive() or not fengyu:hasSkill(self:objectName()) then return false end  
        if event == sgs.DrawNCards then
            local draw_num = data:toInt()  
            if draw_num == 2 then return false end -- 摸牌数等于2时不触发  
            
            return self:objectName(), fengyu:objectName()
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player, "@tiqi_handcard_plus", 0)  
            room:setPlayerMark(player, "@tiqi_handcard_minus", 0)  
            room:detachSkillFromPlayer(player, "tiqi_maxcards")  
        end
        return false
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local draw_num = data:toInt()  
        local y = math.abs(draw_num - 2)  
          
        -- 冯妤摸Y张牌  
        ask_who:drawCards(y, self:objectName())  
          
        -- 询问是否给予"涕"标记并修改手牌上限  
        if ask_who:askForSkillInvoke("tiqi_mark", data) then                
            -- 询问手牌上限增加还是减少  
            local choices = {"tiqi_plus", "tiqi_minus"}  
            local choice = room:askForChoice(ask_who, "tiqi_handcard", table.concat(choices, "+"))  
              
            if choice == "tiqi_plus" then  
                room:setPlayerMark(player, "@tiqi_handcard_plus", y)  
                --room:acquireSkill(player,"tiqi_maxcards", false)
            else  
                room:setPlayerMark(player, "@tiqi_handcard_minus", y)  
                --room:acquireSkill(player,"tiqi_maxcards", false)
            end  
        end  
          
        return false  
    end  
}  
  
-- 涕标记的手牌上限修改技能  
tiqi_maxcards = sgs.CreateMaxCardsSkill{  
    name = "tiqi_maxcards",  
    extra_func = function(self, target)  
        local plus = target:getMark("@tiqi_handcard_plus")  
        local minus = target:getMark("@tiqi_handcard_minus")  
        return plus - minus  
    end  
}  
  
-- 宝梳技能实现  
baoshu = sgs.CreateTriggerSkill{  
    name = "baoshu",  
    events = {sgs.EventPhaseStart},  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start  then
            -- 移除所有角色的'梳'标记  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                room:setPlayerMark(p, "@shu1", 0)  
            end  
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)            
        local x = player:getMaxHp() -- 体力上限  
        local targets = room:askForPlayersChosen(player, room:getAlivePlayers(),   
                                                self:objectName(), 0, x,   
                                                "@baoshu-choose:::" .. tostring(x), true)  
          
        if targets:length() > 0 then  
            local y = targets:length() -- 选择的角色数  
            local mark_num = x - y + 1  
              
            for _, target in sgs.qlist(targets) do  
                room:addPlayerMark(target, "@shu1", mark_num) 
                room:acquireSkill(target,"shu_draw")
            end  
        end  
          
        return false  
    end  
}  
  
shu_draw = sgs.CreateDrawCardsSkill{  
    name = "shu_draw",  
    frequency = sgs.Skill_Compulsory,  
    draw_num_func = function(self, player, n)     
        return n + player:getMark("@shu1")  
    end  
}  
  


fengyu:addSkill(tiqi)  
fengyu:addSkill(tiqi_maxcards)  
fengyu:addSkill(baoshu)  
fengyu:addSkill(shu_draw)  

sgs.LoadTranslationTable{
    ["ziqidonglai"] = "紫气东来",
    ["fengyu"] = "冯妤",  
    ["tiqi"] = "涕泣",  
    [":tiqi"] = "任意一名角色的摸牌阶段，若其摸牌数为X，且不等于2，你摸Y张牌，Y=|X-2|，然后你可以令其获得Y个'涕'标记，本回合手牌上限+Y或-Y。",  
    ["tiqi_mark"] = "是否发动'涕泣'给予标记？",  
    ["tiqi_handcard"] = "选择手牌上限变化",  
    ["tiqi_plus"] = "手牌上限+Y",  
    ["tiqi_minus"] = "手牌上限-Y",  
    ["ti"] = "涕",  
    
    ["baoshu"] = "宝梳",  
    [":baoshu"] = "准备阶段，你移除所有角色的'梳'标记，然后你可以令至多X名角色获得X-Y+1个'梳'标记，X为你的体力上限，Y为你选择的角色数。拥有'梳'标记的角色摸牌阶段摸牌数增加标记数。",  
    ["@baoshu-choose"] = "你可以选择至多 %arg 名角色获得'梳'标记",  
    ["@shu1"] = '梳',
}

guansuo = sgs.General(extension, "guansuo", "shu", 4)  -- 吴国，4血，男性  

zhengnan_skill = sgs.CreateTriggerSkill{  
    name = "zhengnan",  
    events = {sgs.Dying},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        -- 寻找拥有徵南技能的角色  
        local zhengnan_player = room:findPlayerBySkillName(self:objectName())
        if not (zhengnan_player and zhengnan_player:isAlive() and zhengnan_player:hasSkill(self:objectName())) then
            return ""
        end
        local death = data:toDying()
        local death_player = death.who
        local mark_name = "zhengnan" .. death_player:objectName()--string.format("zhengnan_%s", dead_player:objectName())  
        if zhengnan_player:getMark(mark_name) == 0 then
            return self:objectName(), zhengnan_player:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)            
        -- 检查已获得的技能  
        local available_skills = {}  
        local skill_names = {"wusheng", "dangxian", "zhiman"}  
          
        for _, skill_name in ipairs(skill_names) do  
            if not ask_who:hasSkill(skill_name) then  
                table.insert(available_skills, skill_name)  
            end  
        end  
        
        local choices = {"draw3"}
        if #available_skills > 0 then  
            table.insert(choices,"acquireSkill")
        end
        if ask_who:isWounded() then
            table.insert(choices,"draw1")
        end
        local choice = room:askForChoice(ask_who, self:objectName(), table.concat(choices, "+"), data)  
        if choice == "acquireSkill" then
            -- 选择一个技能获得  
            local skill_name = room:askForChoice(ask_who, self:objectName(), table.concat(available_skills, "+"), data)  
            room:acquireSkill(ask_who, skill_name)  
        elseif choice == "draw1" then
            -- 回复一点体力
            local recover = sgs.RecoverStruct()  
            recover.recover = 1  
            recover.who = ask_who  
            room:recover(ask_who, recover)  
            -- 摸1张牌  
            ask_who:drawCards(1, self:objectName())  
        elseif choice == "draw3" then
            -- 所有技能都已获得，摸3张牌  
            ask_who:drawCards(3, self:objectName())  
        end  
        local death = data:toDying()
        local death_player = death.who
        local mark_name = "zhengnan" .. death_player:objectName()--string.format("zhengnan_%s", dead_player:objectName())  
        room:setPlayerMark(ask_who,mark_name,1)
        return false  
    end  
    --[[
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 回复一点体力
        local recover = sgs.RecoverStruct()  
        recover.recover = 1  
        recover.who = ask_who  
        room:recover(ask_who, recover)  
          
        -- 检查已获得的技能  
        local available_skills = {}  
        local skill_names = {"wusheng", "dangxian", "zhiman"}  
          
        for _, skill_name in ipairs(skill_names) do  
            if not ask_who:hasSkill(skill_name) then  
                table.insert(available_skills, skill_name)  
            end  
        end  
          
        if #available_skills > 0 then  
            -- 选择一个技能获得  
            local choice = room:askForChoice(ask_who, self:objectName(), table.concat(available_skills, "+"), data)  
            room:acquireSkill(ask_who, choice)  

            -- 摸1张牌  
            ask_who:drawCards(1, self:objectName())  
        else  
            -- 所有技能都已获得，摸3张牌  
            ask_who:drawCards(3, self:objectName())  
        end  
        local death = data:toDying()
        local death_player = death.who
        local mark_name = "zhengnan" .. death_player:objectName()--string.format("zhengnan_%s", dead_player:objectName())  
        room:setPlayerMark(ask_who,mark_name,1)
        return false  
    end  
    ]]
}

xiefang_skill = sgs.CreateDistanceSkill{  
    name = "xiefang",  
    correct_func = function(self, from, to)  
        if from:hasSkill(self:objectName()) then  
            -- 计算全场女性角色数  
            local female_count = 0  
            for _, p in sgs.qlist(from:getRoom():getAlivePlayers()) do  
                if p:hasShownOneGeneral() and p:isFemale() then  
                    female_count = female_count + 1  
                end  
            end  
            return -female_count  
        end  
        return 0  
    end  
}
guansuo:addSkill(zhengnan_skill)
--guansuo:addSkill(xiefang_skill)
-- 翻译表  
sgs.LoadTranslationTable{
["guansuo"] = "关索",  
["zhengnan"] = "徵南",   
--[":zhengnan"] = "每名角色限一次，任意角色进入濒死时，你可以回复一点体力，并从武圣、当先、制蛮中选择一个技能获得，然后摸1张牌；若所有技能都已获得，则摸三张牌。",  
[":zhengnan"] = "每名角色限一次，任意角色进入濒死时，你可以选择（1）从武圣、当先、制蛮中选择一个技能获得（2）回复一点体力，并摸1张牌（3）摸三张牌。",  
["xiefang"] = "撷芳",  
[":xiefang"] = "你到其他角色的距离-X，X为全场女性角色数。",  
["wusheng"] = "武圣",  
["dangxian"] = "当先",   
["zhiman"] = "制蛮"
}  

-- 武将定义  
guoyuan = sgs.General(extension, "guoyuan", "wei", 3)  

-- 修耕技能：回合开始时记录手牌数  
xiugeng = sgs.CreateTriggerSkill{  
    name = "xiugeng",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then  
            return self:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local all_players = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if player:isFriendWith(p) then
                all_players:append(p)  
            end
        end  
        local targets = room:askForPlayersChosen(player, all_players, self:objectName(), 0, 3, "@xiugeng-choose", true)  
        for _, target in sgs.qlist(targets) do  
            -- 记录该角色的手牌数  
            room:setPlayerMark(target, "@xiugeng_handcard", target:getHandcardNum())  
        end  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        return false  
    end  
}  
  
-- 修耕摸牌效果：摸牌阶段开始时触发  
xiugeng_draw = sgs.CreateTriggerSkill{  
    name = "#xiugeng_draw",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:getPhase() == sgs.Player_Draw and player:getMark("@xiugeng_handcard") > 0 then  
            local recorded_num = player:getMark("@xiugeng_handcard")  
            if player:getHandcardNum() <= recorded_num then  
                return self:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 清除记录标记并摸2张牌  
        room:setPlayerMark(player, "@xiugeng_handcard", 0)  
        player:drawCards(2, "xiugeng")  
        return false  
    end  
}  
  
-- 陈赦技能：其他角色进入濒死时触发  
chenshe = sgs.CreateTriggerSkill{  
    name = "chenshe",  
    events = {sgs.Dying},  
    can_trigger = function(self, event, room, player, data)  
        local dying = data:toDying()  
        --local guoyuan = room:findPlayerBySkillName(self:objectName())  
        --if guoyuan and guoyuan:isAlive() and guoyuan:hasSkill(self:objectName()) and not guoyuan:isAllNude() then
        if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:isAllNude() then
            if dying.who and dying.who:objectName() ~= player:objectName() and not dying.who:isAllNude() and dying.damage and dying.damage.from and dying.damage.from:isAlive() and not dying.damage.from:isAllNude() then  
                return self:objectName() .. "->" .. dying.who:objectName()  
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local dying = data:toDying()  
        local ai_data = sgs.QVariant()  
        ai_data:setValue(dying.who)  
        if ask_who:askForSkillInvoke(self:objectName(), ai_data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local dying = data:toDying()  
        local colors = {}  
          
        -- 1. 弃置濒死角色一张牌  
        if not dying.who:isAllNude() then  
            local card1 = room:askForCardChosen(ask_who, dying.who, "hej", self:objectName())  
            if card1 then  
                colors[1] = sgs.Sanguosha:getCard(card1):getColor()  
                room:throwCard(card1, dying.who, ask_who)  
            end  
        end  
          
        -- 2. 弃置伤害源一张牌  
        if dying.damage and dying.damage.from and not dying.damage.from:isAllNude() then  
            local card2 = room:askForCardChosen(ask_who, dying.damage.from, "hej", self:objectName())  
            if card2 then  
                colors[2] = sgs.Sanguosha:getCard(card2):getColor()  
                room:throwCard(card2, dying.damage.from, ask_who)  
            end  
        end  
          
        -- 3. 弃置自己一张牌  
        if not ask_who:isAllNude() then  
            local card3 = room:askForCardChosen(ask_who, ask_who, "hej", self:objectName())  
            if card3 then  
                colors[3] = sgs.Sanguosha:getCard(card3):getColor()  
                room:throwCard(card3, ask_who, ask_who)  
            end  
        end  
          
        -- 检查三张牌颜色是否相同  
        if #colors >= 3 and colors[1] == colors[2] and colors[2] == colors[3] then  
            -- 恢复至体力上限  
            local recover = sgs.RecoverStruct()  
            recover.who = ask_who  
            recover.recover = dying.who:getMaxHp() - dying.who:getHp()  
            room:recover(dying.who, recover)  
              
            -- 失去此技能。或者写成限定技，有限定标记才能发动
            room:detachSkillFromPlayer(ask_who, self:objectName())  
        end  
          
        return false  
    end  
}  
  

guoyuan:addSkill(xiugeng)  
guoyuan:addSkill(xiugeng_draw)  
guoyuan:addSkill(chenshe)  
extension:insertRelatedSkills("xiugeng", "#xiugeng_draw")

sgs.LoadTranslationTable{
["guoyuan"] = "国渊",  
["#guoyuan"] = "魏之贤臣",  
["xiugeng"] = "修耕",  
[":xiugeng"] = "你的回合开始时，你可以记录至多3名其他相同势力角色的手牌数，其下个摸牌阶段开始时，若其手牌数小于等于记录值，其摸2张牌。",  --削弱方向：小于记录值，摸2张牌/摸至记录值
["chenshe"] = "陈赦",  
[":chenshe"] = "任意其他角色进入濒死时，你可以依次弃置该角色、伤害源、自己一张牌，若这三张牌颜色相同，该角色恢复至体力上限，然后你失去此技能。",  
["@xiugeng-choose"] = "修耕：选择至多3名角色记录其手牌数",  
["@chenshe-discard"] = "陈赦：弃置一张牌",
}

haozhao = sgs.General(extension, "haozhao", "wei", 4)  
  
zhengu = sgs.CreateTriggerSkill{  
    name = "zhengu",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            -- 郝昭/拥有'骨'标记的角色回合结束时触发  
            if player and player:isAlive() and player:getPhase() == sgs.Player_NotActive then
                if player:hasSkill(self:objectName()) or player:getMark("@bone") > 0  then
                    return self:objectName()  
                end
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:hasSkill(self:objectName()) then
            return player:askForSkillInvoke(self:objectName(),data)
        elseif player:getMark("@bone") > 0 then
            -- 拥有'骨'标记的角色回合结束时，自动触发  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if player:hasSkill(self:objectName()) then  
            -- 郝昭的结束阶段效果  
            -- 郝昭的结束阶段，选择其他角色  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if p:isAlive() then  
                    targets:append(p)  
                end  
            end  
              
            if targets:isEmpty() then return false end  
              
            local target = room:askForPlayerChosen(player, targets, self:objectName(),   
                                                 "@zhengu-choose", true, true)  
              
            if target and target:isAlive() then  
                -- 给目标添加'骨'标记  
                room:setPlayerMark(target, "@bone", 1)  
                  
                -- 调整目标手牌数至与郝昭相同  
                local haozhao_handcards = player:getHandcardNum()  
                local target_handcards = target:getHandcardNum()  
                  
                if target_handcards < haozhao_handcards then  
                    target:drawCards(haozhao_handcards - target_handcards, self:objectName())  
                elseif target_handcards > haozhao_handcards then  
                    room:askForDiscard(target, self:objectName(),   
                                     target_handcards - haozhao_handcards,   
                                     target_handcards - haozhao_handcards,   
                                     false, false)  
                end  
            end  
        elseif player:getMark("@bone") > 0 then  
            -- 拥有'骨'标记的角色回合结束时效果  
            room:setPlayerMark(player, "@bone", 0)  
              
            -- 找到拥有镇骨技能的角色（郝昭）  
            local haozhao_player = nil  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) then  
                    haozhao_player = p  
                    break  
                end  
            end  
              
            if haozhao_player and haozhao_player:isAlive() then  
                local haozhao_handcards = haozhao_player:getHandcardNum()  
                local player_handcards = player:getHandcardNum()  
                  
                if player_handcards < haozhao_handcards then  
                    player:drawCards(haozhao_handcards - player_handcards, self:objectName())  
                elseif player_handcards > haozhao_handcards then  
                    room:askForDiscard(player, self:objectName(),   
                                     player_handcards - haozhao_handcards,   
                                     player_handcards - haozhao_handcards,   
                                     false, true)  
                end  
            end  
        end  
          
        return false  
    end  
}  
  
haozhao:addSkill(zhengu)

sgs.LoadTranslationTable{
["haozhao"] = "郝昭",  
["#haozhao"] = "镇守街亭",  
["zhengu"] = "镇骨",  
[":zhengu"] = "你的回合结束时，你可以选择一名其他角色，令其获得1个'骨'标记，并将手牌摸或弃至与你相同；拥有'骨'标记的角色回合结束时，其移除'骨'标记，然后将手牌摸或弃至与你相同。",  
["@zhengu-choose"] = "镇骨：选择一名其他角色获得'骨'标记",  
["@bone"] = '骨',
}

hejin_junba = sgs.General(extension, "hejin_junba", "qun", 3)  

zhaobing = sgs.CreateTriggerSkill{  
    name = "zhaobing",  
    events = {sgs.EventPhaseEnd},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and player:getHandcardNum() > 0 then
            return self:objectName()
        end
        return "" 
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local handcard_num = player:getHandcardNum()  
        if handcard_num == 0 then return false end  
          
        -- 弃置所有手牌  
        player:throwAllHandCards()  

        --local other_players = room:getOtherPlayers(player)
        local other_targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if not player:isFriendWith(p) then
                other_targets:append(p)  
            end
        end  
        -- 选择至多X名其他角色  
        local chosen_num = math.min(handcard_num, other_players:length())
        local targets = room:askForPlayersChosen(player, other_players, self:objectName(),   
            0, chosen_num, "@zhaobing-choose:::" .. tostring(chosen_num), true)  

          
        -- 让每个被选择的角色做出选择  
        for _, target in sgs.qlist(targets) do  
            local choice = room:askForChoice(target, self:objectName(), "give_slash+lose_hp",   
                data, "@zhaobing-target:" .. player:objectName())  
              
            if choice == "give_slash" then  
                -- 寻找目标角色手牌中的杀  
                local slash = nil  
                for _, card in sgs.qlist(target:getHandcards()) do  
                    if card:isKindOf("Slash") then  
                        slash = card  
                        break  
                    end  
                end  
                  
                if slash then  
                    room:obtainCard(player, slash, false)  
                else  
                    -- 如果没有杀，则失去体力  
                    room:loseHp(target, 1)  
                end  
            else  
                -- 选择失去体力  
                room:loseHp(target, 1)  
            end  
        end  
          
        return false  
    end  
}

zhuhuan4 = sgs.CreateTriggerSkill{  
    name = "zhuhuan4",  
    events = {sgs.EventPhaseStart},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and player:getHandcardNum() > 0 then
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
            if not player:isFriendWith(p) then
                targets:append(p)  
            end
        end  
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhuhuan4", true, true)  
        if not target then return false end  
          
        -- 展示所有手牌  
        room:showAllCards(player)  
          
        -- 统计并弃置所有杀  
        local slash_count = 0  
        for _, card in sgs.qlist(player:getHandcards()) do  
            if card:isKindOf("Slash") then  
                slash_count = slash_count + 1
                room:throwCard(card, player)
            end  
        end  
          
        if slash_count > 0 then                
            -- 让目标角色选择  
            local choice = room:askForChoice(target, "zhuhuan4", "damage_discard+recover_draw", sgs.QVariant(slash_count))  
            if choice == "damage_discard" then  
                local damage = sgs.DamageStruct()  
                damage.from = player  
                damage.to = target  
                damage.damage = 1  
                room:damage(damage)  
                  
                if target:isAlive() then  
                    room:askForDiscard(target, "zhuhuan4", slash_count, slash_count, false, true)  
                end  
            else  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(player, recover)  
                  
                room:drawCards(player, slash_count)  
            end  
        end  
          
        return false  
    end  
}

yanhuoDeath = sgs.CreateTriggerSkill{  
    name = "yanhuoDeath",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.Death},  
    can_trigger = function(self, event, room, player, data)  
        local death = data:toDeath()  
        if death.who and death.who:hasSkill(self:objectName())  then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,
    on_effect = function(self, event, room, player, data)  
        room:setTag("yanhuoDeath_effect", sgs.QVariant(true))  
        return false  
    end  
}  
  
-- 延祸伤害增加效果  
yanhuoDeathDamage = sgs.CreateTriggerSkill{  
    name = "yanhuoDeath_damage",  
    events = {sgs.DamageCaused},  
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if room:getTag("yanhuoDeath_effect"):toBool() and damage.card and damage.card:isKindOf("Slash")  then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}

hejin_junba:addSkill(zhaobing)  
hejin_junba:addSkill(zhuhuan4)  
hejin_junba:addSkill(yanhuoDeath)  
hejin_junba:addSkill(yanhuoDeathDamage)
sgs.LoadTranslationTable{
["#hejin_junba"] = "大将军",  
["hejin_junba"] = "何进",  
["illustrator:hejin_junba"] = "待定",  
["zhaobing"] = "诏兵",  
[":zhaobing"] = "你的结束阶段，你可以弃置所有手牌，然后令至多X名其他势力角色选择（X为弃置的手牌数）：（1）交给你一张杀（2）失去一点体力。",  
["zhuhuan4"] = "诛宦",  
[":zhuhuan4"] = "你的准备阶段，你可以展示所有手牌，并弃置其中所有杀，然后令一名其他势力角色选择：（1）受到1点伤害，并弃置等量的牌（2）令你恢复1点体力，并摸等量的牌。",  
["yanhuoDeath"] = "延祸",  
[":yanhuoDeath"] = "锁定技。你死亡后，本局游戏杀造成的伤害+1。",  
["@zhaobing-choose"] = "诏兵：选择至多%arg名其他角色",  
["@zhaobing-target"] = "诏兵：选择交给%src一张【杀】，或失去1点体力",  
["give_slash"] = "交给一张杀",  
["lose_hp"] = "失去1点体力",
["@zhuhuan4-choose"] = "诛宦：选择受到1点伤害并弃置%arg张牌，或令%src恢复1点体力并摸%arg张牌",
}

huangwudie = sgs.General(extension, "huangwudie", "shu", 3, false)  -- 吴国，4血，男性  

shuangrui = sgs.CreateTriggerSkill{  
    name = "shuangrui",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@shuangrui-invoke", true, true)  
        if not target then return false end  
          
        -- 视为对目标使用杀  
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
        slash:setSkillName(self:objectName())  
        slash:deleteLater()
        local use = sgs.CardUseStruct()  
        use.card = slash  
        use.from = player  
        use.to:append(target)  
        room:useCard(use, false)  
          
        return false  
    end  
}  
  
-- 铩雪技能  
shaxue = sgs.CreateTriggerSkill{  
    name = "shaxue",  
    events = {sgs.Damage},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.from and damage.from:objectName() == player:objectName() and damage.to then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local target = damage.to  
        if not target then return false end  
          
        -- 摸2张牌  
        player:drawCards(2, self:objectName())  
          
        -- 计算距离并弃置X张牌  
        local distance = player:distanceTo(target)  
        if distance > 0 and player:getCardCount(true) > 0 then  
            local discard_num = math.min(distance, player:getCardCount(true))  
            room:askForDiscard(player, self:objectName(), discard_num, discard_num, false, true)  
        end  
          
        return false  
    end  
}  
  
-- 技能2：伏械  
fuxie = sgs.CreateViewAsSkill{  
    name = "fuxie",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0 and to_select:isKindOf("Weapon")  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = FuxieCard:clone()  
            card:setSkillName(self:objectName())
            card:setShowSkill(self:objectName())  
            card:addSubcard(cards[1])  
            return card  
        end  
        return nil  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#FuxieCard") --and player:hasWeapon()  
    end  
}  
  
-- 伏械卡牌类  
FuxieCard = sgs.CreateSkillCard{  
    name = "FuxieCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        if target and target:getCardCount(true) > 0 then  
            local discard_num = math.min(2, target:getCardCount(true))  
            room:askForDiscard(target, "fuxie", discard_num, discard_num, false, true)  
        end  
    end  
}  
  
-- 添加技能到武将  
huangwudie:addSkill(shuangrui)  
huangwudie:addSkill(shaxue)  
huangwudie:addSkill(fuxie)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["huangwudie"] = "黄舞蝶",  
    ["#huangwudie"] = "蝶舞剑影",  
    ["shuangrui"] = "双锐",  
    [":shuangrui"] = "准备阶段，你可以选择一名角色，视为你对该角色使用一张【杀】。",  
    ["@shuangrui-invoke"] = "双锐：你可以选择一名角色，视为对其使用【杀】",  
    ["shaxue"] = "铩雪",  
    [":shaxue"] = "你对一名角色造成伤害后，你可以摸2张牌，然后弃置X张牌，X为你到其的距离。",  
    ["fuxie"] = "伏械",  
    [":fuxie"] = "出牌阶段限一次，你可以弃置一张武器牌，然后令一名其他角色弃置2张牌。",  
    ["FuxieCard"] = "伏械",  
    ["@fuxie"] = "伏械：选择一张武器牌弃置"  
}

jianshi = sgs.General(extension, "jianshi", "wei", 3, false)  -- 吴国，4血，男性  

jiusiCard = sgs.CreateSkillCard{  
    name = "jiusiCard",  
    target_fixed = true,  
    will_throw = false,  
      
    on_use = function(self, room, source, targets) 
        choices = {"analeptic"}
        if sgs.Slash_IsAvailable(source) then
            table.insert(choices, "slash")
        end
        if source:isWounded() then
            table.insert(choices, "peach")
        end
        choice=room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
        card = sgs.Sanguosha:cloneCard(choice)  
        card:setSkillName("jiusi")
        card:deleteLater()
        if choice=="slash" then
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(source)) do  
                if source:inMyAttackRange(p) then  
                    targets:append(p) 
                end  
            end  
            target=room:askForPlayerChosen(source, targets, self:objectName())
            local use = sgs.CardUseStruct()  
            use.from = source  
            use.to:append(target)   
            use.card = card  
            room:useCard(use)
        else
            local use = sgs.CardUseStruct()  
            use.from = source  
            use.to:append(source)   
            use.card = card  
            room:useCard(use)
        end
    end  
}

jiusiVS = sgs.CreateZeroCardViewAsSkill{  
    name = "jiusi",  
    response_or_use = true,  -- 关键参数，允许既主动使用又响应使用  
    --guhuo_type = "b",  -- 显示基础牌选择框  
    view_as = function(self)
        local card_name = ""  
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()  
        if pattern == "slash" then  
            card_name = "slash"  
        elseif pattern == "jink" then  
            card_name = "jink"  
        elseif pattern == "peach" then  
            card_name = "peach"  
        elseif pattern == "analeptic" then  
            card_name = "analeptic"  
        else
            card = jiusiCard:clone()
            return card 
        end  
        local view_as_card = nil
        if card_name ~= nil then
            view_as_card = sgs.Sanguosha:cloneCard(card_name)  
        end
        view_as_card:setSkillName(self:objectName())  
        view_as_card:setShowSkill(self:objectName())  
        return view_as_card  
    end,  
    enabled_at_play = function(self, player)  
        -- 允许在出牌阶段主动使用  
        return not player:hasFlag("jiusi_used")  
    end,  
    enabled_at_response = function(self, player, pattern)  
        -- 允许在需要基本牌时响应使用  
        return not player:hasFlag("jiusi_used") and (pattern == "slash" or pattern == "jink" or string.find(pattern,"peach") or string.find(pattern,"analeptic"))
    end  
}

jiusi = sgs.CreateTriggerSkill{  
    name = "jiusi",  
    view_as_skill = jiusiVS,  
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        local card = nil
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else -- sgs.CardResponded  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        -- 检查是否是通过此技能使用的基本牌  
        if card and card:isKindOf("BasicCard") then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  -- 强制触发，无需询问  
    end,  
    on_effect = function(self, event, room, player, data) 
        --使用或打出基本牌，摸两张
        if not player:hasFlag("jiusi_draw") then
            room:setPlayerFlag(player,"jiusi_draw")
            player:drawCards(2)
        end
        --因为这个技能使用或打出，叠置
        local card = nil
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else -- sgs.CardResponded  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
        if card:getSkillName() == self:objectName() then
            room:setPlayerFlag(player,"jiusi_used")
            player:turnOver()
        end
        return false  
    end  
}

jianshi:addSkill(jiusi)
sgs.LoadTranslationTable{
    ["jianshi"] = "剑侍",
    ["jiusi"] = "纠思",
    [":jiusi"] = "1. 每回合限一次，当你使用或打出基本牌时，你摸两张牌。2. 每回合限一次，当你需要使用或打出基本牌时，你可以视为使用之，然后你叠置。"
}

jikang = sgs.General(extension, "jikang", "wei", 3)  
QingxianCard = sgs.CreateSkillCard{  
    name = "QingxianCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        local max_targets = math.min(sgs.Self:getHp(), sgs.Self:getCardCount(true))
        return #targets < max_targets and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    feasible = function(self, targets)  
        local max_targets = math.min(sgs.Self:getHp(), sgs.Self:getCardCount(true))  
        return #targets <= max_targets and #targets > 0  
    end,  
    on_use = function(self, room, source, targets)  
        local x = source:getHp()  
        local selected_count = #targets  
          
        -- 弃置X张牌
        local discard_num = math.min(source:getCardCount(true), selected_count)
        room:askForDiscard(source, "qingxian", discard_num, discard_num, false, true)  
          
        -- 对每个目标角色执行效果  
        for _, target in ipairs(targets) do  
            local source_equip_count = source:getEquips():length()  
            local target_equip_count = target:getEquips():length()  
              
            if target_equip_count < source_equip_count then  
                -- 回复1点体力  
                local recover = sgs.RecoverStruct()  
                recover.who = source  
                recover.recover = 1  
                room:recover(target, recover)  
            elseif target_equip_count == source_equip_count then  
                -- 摸一张牌  
                target:drawCards(1, "qingxian")  
            else  
                -- 失去1点体力  
                room:loseHp(target, 1)  
            end  
        end  
          
        -- 若选择的角色数等于X，你摸一张牌  
        if selected_count == x then  
            source:drawCards(1, "qingxian")  
        end  
    end  
}  
  
QingxianVS = sgs.CreateZeroCardViewAsSkill{  
    name = "qingxian",  
    view_as = function(self)  
        local card = QingxianCard:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#QingxianCard") and not player:isNude()
    end  
}  
  
-- 绝响技能  
Juexiang = sgs.CreateTriggerSkill{  
    name = "juexiang",  
    events = {sgs.Death},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        local death = data:toDeath()
        if not (player and player:hasSkill(self:objectName())) then  
            return ""  
        end
        if death.who:objectName() ~= player:objectName() then  
            return ""  
        end
        return self:objectName()
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)   
        local death = data:toDeath()        
        -- 来源弃置装备区所有牌并失去1点体力  
        if death.damage and death.damage.from then  
            local killer = death.damage.from  
            if not killer:getEquips():isEmpty() then  
                killer:throwAllEquips()  
            end  
            room:loseHp(killer, 1)  
        end  
          
        -- 选择一名其他角色获得"清弦"  
        local others = room:getOtherPlayers(player)  
        if not others:isEmpty() then  
            local target = room:askForPlayerChosen(player, others, "juexiang", "@juexiang-target", true)  
            if target then  
                room:acquireSkill(target, "qingxian")  
                  
                -- 该角色可以弃置1张梅花牌，获得"绝响"
                local discard_target = room:askForPlayerChosen(target, others, "juexiang", "@juexiang-target", true)  
                local club_card = room:askForCardChosen(target, discard_target, "hej", "juexiang", "@juexiang-club")  
                if club_card and sgs.Sanguosha:getCard(club_card):getSuit() == sgs.Card_Club then  
                    room:throwCard(club_card, discard_target, target)  
                    room:acquireSkill(target, "juexiang")  
                end  
            end  
        end  
          
        return false  
    end  
}  
  

jikang:addSkill(QingxianVS)  
jikang:addSkill(Juexiang)

sgs.LoadTranslationTable{
["#jikang"] = "竹林名士",  
["jikang"] = "嵇康",  
["qingxian"] = "清弦",  
[":qingxian"] = "出牌阶段限一次，你可以选择X名其他角色并弃置等量张牌，若其装备区的牌数：小于你，其回复1点体力；等于你，其摸一张牌；大于你，其失去一点体力。X至多为你的体力值。若X等于你的体力值，你摸一张牌。",  
["juexiang"] = "绝响",  
[":juexiang"] = "你死亡时，来源弃置装备区所有牌并失去1点体力；你可以选择一名其他角色，令其获得\"清弦\"，然后其可以弃置场上1张梅花牌，获得\"绝响\"。",  
["@qingxian"] = "你可以发动'清弦'",  
["~qingxian"] = "选择至多%arg名其他角色→点击确定",  
["@juexiang-target"] = "你可以选择一名其他角色获得'清弦'",  
["@juexiang-club"] = "你可以弃置一张梅花牌获得'绝响'",
}

jun_liuxie = sgs.General(extension, "jun_liuxie", "qun", 3)  -- 吴国，4血，男性  
zhanban_card = sgs.CreateSkillCard{  
    name = "ZhanbanCard",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)  
        -- 记录所有角色的初始手牌数  
        local initial_handcards = {}  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            initial_handcards[p:objectName()] = p:getHandcardNum()  
        end  
          
        -- 让玩家选择摸牌或弃牌  
        local choice = room:askForChoice(source, "zhanban", "draw+discard")  
        local num = room:askForChoice(source, "zhanban", "1+2+3")  
          
        if choice == "draw" then  
            room:drawCards(source, num, "zhanban")  
        else
            num = math.min(source:getCardCount(true),num)
            room:askForDiscard(source, "zhanban", num, num, false, true)  
        end  
          
        local source_handcards = source:getHandcardNum()  
          
        -- 对所有其他角色执行效果  
        for _, target in sgs.qlist(room:getOtherPlayers(source)) do  
            local target_handcards = target:getHandcardNum()  
            local initial_num = initial_handcards[target:objectName()]  
              
            if target_handcards < source_handcards then  
                -- 手牌数小于你：摸至相等，然后弃置3张牌  
                local draw_num = source_handcards - target_handcards  
                if draw_num > 0 then  
                    room:drawCards(target, draw_num, "zhanban")  
                end  
                  
                if target:getHandcardNum() >= 3 then  
                    room:askForDiscard(target, "zhanban", 3, 3, false, true)  
                end  
                  
                -- 检查手牌数是否和最初一致  
                if target:getHandcardNum() == initial_num then  
                    local damage = sgs.DamageStruct()  
                    damage.from = source  
                    damage.to = target  
                    damage.damage = 1  
                    damage.reason = "zhanban"  
                    room:damage(damage)  
                end  
                  
            elseif target_handcards > source_handcards then  
                -- 手牌数大于你：弃置至相等，然后摸3张牌  
                local discard_num = target_handcards - source_handcards  
                if discard_num > 0 then  
                    room:askForDiscard(target, "zhanban", discard_num, discard_num, false, false)  
                end  
                  
                room:drawCards(target, 3, "zhanban")  
                  
                -- 检查手牌数是否和最初一致  
                if target:getHandcardNum() == initial_num then  
                    local damage = sgs.DamageStruct()  
                    damage.from = source  
                    damage.to = target  
                    damage.damage = 1  
                    damage.reason = "zhanban"  
                    room:damage(damage)  
                end  
            end  
        end  
    end  
}  
  
-- 斩绊视为技  
zhanban = sgs.CreateZeroCardViewAsSkill{  
    name = "zhanban",  
    view_as = function(self)  
        card = zhanban_card:clone()  
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#ZhanbanCard")
    end  
}  
  
chensheng = sgs.CreateTriggerSkill{  
    name = "chensheng",  
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local chensheng_player = room:findPlayerBySkillName(self:objectName())  
        if not (chensheng_player and chensheng_player:isAlive() and chensheng_player:hasSkill(self:objectName())) then return "" end  
          
        -- 检查是否是其他角色的回合结束  
        if player:objectName() ~= chensheng_player:objectName() and player:getPhase() == sgs.Player_Finish then  
            -- 找到手牌数最多的角色  
            local max_handcards = 0  
            local max_players = {}  
              
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                local handcard_num = p:getHandcardNum()  
                if handcard_num > max_handcards then  
                    max_handcards = handcard_num  
                    max_players = {p}  
                elseif handcard_num == max_handcards then  
                    table.insert(max_players, p)  
                end  
            end  
              
            -- 检查自己和当前回合角色是否都不是手牌数最多的角色  
            local chensheng_is_max = false  
            local current_is_max = false  
              
            for _, p in ipairs(max_players) do  
                if p:objectName() == chensheng_player:objectName() then  
                    chensheng_is_max = true  
                end  
                if p:objectName() == player:objectName() then  
                    current_is_max = true  
                end  
            end  
              
            if not chensheng_is_max and not current_is_max then  
                return self:objectName(), chensheng_player:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        room:drawCards(ask_who, 1, self:objectName())  
        return false  
    end  
}
jun_liuxie:addSkill(zhanban)  
jun_liuxie:addSkill(chensheng)
-- 翻译表  
sgs.LoadTranslationTable{
    ["jun_liuxie"] = "君刘协",
    ["zhanban"] = "斩绊",
    [":zhanban"] = "主动技。出牌阶段限一次。你可以摸或弃置至多3张牌，然后对所有角色：若其手牌数小于你，其摸至与你相等，然后弃置3张牌；若其手牌数大于你，其弃置与你相等，然后摸3张牌。你对手牌数因此未发生变化的角色造成1点伤害。",
    ["chensheng"] = "沉声",
    [":chensheng"] = "其他角色回合结束时，若你与当前回合角色均不为手牌数最多的角色，你摸一张牌。"
}  

jushou4 = sgs.General(extension, "jushou4", "qun", 3)  -- 吴国，4血，男性  
jianying = sgs.CreateTriggerSkill{  
    name = "jianying",  
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseChanging},  
    frequency = sgs.Skill_Frequent,    
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseChanging then  
            local change = data:toPhaseChange()  
            if change.from == sgs.Player_Play then  
                -- 清除出牌阶段结束时的记录  
                return self:objectName()  
            end  
        elseif player:getPhase() == sgs.Player_Play then  
            local card = nil  
            if event == sgs.CardUsed then  
                local use = data:toCardUse()  
                if use.from:objectName() == player:objectName() then  
                    card = use.card  
                end  
            elseif event == sgs.CardResponded then  
                local resp = data:toCardResponse()  
                if resp.m_isUse and resp.m_from:objectName() == player:objectName() then  
                    card = resp.m_card  
                end  
            end  
              
            if card and card:getTypeId() ~= sgs.Card_TypeSkill then  
                -- 检查是否与上一张牌花色或点数相同  
                local last_suit = player:getMark("combo_last_suit")  
                local last_number = player:getMark("combo_last_number")  
                -- 记录当前牌的花色和点数  
                room:setPlayerMark(player, "combo_last_suit", card:getSuit())  
                room:setPlayerMark(player, "combo_last_number", card:getNumber())  
                if (last_suit ~= -1 and card:getSuit() == last_suit) or   
                   (last_number > 0 and card:getNumber() == last_number) then  
                    return self:objectName()  
                end  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseChanging then  
            return true  
        else  
            -- 自动触发，无需询问  
            return true  
        end  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseChanging then  
            -- 清除记录  
            room:setPlayerMark(player, "combo_last_suit", -1)  
            room:setPlayerMark(player, "combo_last_number", 0)  
        else  
            -- 摸一张牌  
            room:drawCards(player, 1, self:objectName())  
        end  
        return false  
    end  
}  
shibei = sgs.CreateTriggerSkill{  
    name = "shibei",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Compulsory,    
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive()) then  
            return ""  
        end  
          
        if player:hasSkill(self:objectName()) and event == sgs.Damaged then  
            return self:objectName()
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:hasShownSkill(self:objectName()) then
            return true
        else
            return player:askForSkillInvoke(self:objectName())
        end
    end,  
      
    on_effect = function(self, event, room, player, data)  
        damage = data:toDamage()
        if not player:hasFlag("has_damaged_1") then
            room:setPlayerFlag(player, "has_damaged_1")
            local recover = sgs.RecoverStruct()  
            recover.who = player  --恢复来源
            room:recover(player, recover) --player是恢复目标
            
            --damage.damage = damage.damage-1
            --data:setValue(damage)
            --return false
        elseif player:hasFlag("has_damaged_1") and not player:hasFlag("has_damaged_2") then
            room:setPlayerFlag(player, "has_damaged_2")
            room:loseHp(player,1)
            --damage.damage = damage.damage + 1
            --data:setValue(damage)
            --return false
        end
        return false  
    end  
}  

jushou4:addSkill(jianying)
jushou4:addSkill(shibei)
sgs.LoadTranslationTable{
    ["jushou4"] = "沮授",
    ["jianying"] = "渐营",
    [":jianying"] = "出牌阶段，当你使用的牌的花色或点数和上一张牌相同时，你摸一张牌",
    ["shibei"] = "失北",
    [":shibei"] = "锁定技。每回合你第一次受到伤害后，你回复一点体力；第二次受到伤害后，你失去一点体力"    
}

-- 创建武将蒙恬  

kuailiangkuaiyue = sgs.General(extension, "kuailiangkuaiyue", "jin", 3) -- 蜀势力，4血，男性（默认）  

jianxiangCard = sgs.CreateSkillCard{  
    name = "jianxiangCard",  
    target_fixed = true,  
    will_throw = true,   
    on_use = function(self, room, source, targets)
        local max_handcard = 0 
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getHandcardNum() > max_handcard then  
                max_handcard = p:getHandcardNum()  
            end  
        end 
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getHandcardNum() == max_handcard then  
                targets:append(p)
            end  
        end 
        local target1 = room:askForPlayerChosen(source, targets, self:objectName(), "jianxiang-maxcand") -- 手牌最多的角色  
        local target2 = room:askForPlayerChosen(source, room:getOtherPlayers(target1), self:objectName(), "jianxiang-choose") -- 选择执行效果的角色 

        -- 让target2选择效果  
        local choices = {"jianxiang_give", "jianxiang_damage"}  
        local choice = room:askForChoice(target2, "jianxiang", table.concat(choices, "+"))  
          
        if choice == "jianxiang_give" and not target2:isNude() then  
            -- 选择交给target1一张牌  
            local card_id = room:askForCardChosen(target2, target2, "he", "jianxiang")  
            room:obtainCard(target1, card_id, false)  
        else  
            -- 选择受到target1造成的1点伤害  
            room:damage(sgs.DamageStruct("jianxiang", target1, target2, 1))  
        end  
    end  
}  
  
-- 谏降视为技能  
jianxiangVS = sgs.CreateZeroCardViewAsSkill{  
    name = "jianxiang",  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#jianxiangCard")  
    end,  
    view_as = function(self)  
        local jianxiang_card = jianxiangCard:clone()  
        jianxiang_card:setSkillName(self:objectName())  
        jianxiang_card:setShowSkill(self:objectName())  
        return jianxiang_card  
    end  
}
--卡牌移动时，判断阶段
nashun = sgs.CreateTriggerSkill{
	name = "nashun",
	events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() == sgs.Player_Discard then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
						if move.from_places:contains(sgs.Player_PlaceHand) then
							if move.from and move.from:isAlive() and player:isFriendWith(move.from) then
								return self:objectName()
							end
						end
					end
				end
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		return player:askForSkillInvoke(self:objectName(),data)
	end,
    on_effect = function(self, event, room, player, data)
        local move_datas = data:toList()
        local all_cards = sgs.IntList()
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
            if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                if move.from_places:contains(sgs.Player_PlaceHand) then
                    if move.from and move.from:isAlive() and player:isFriendWith(move.from) then
                        for _,card_id in sgs.qlist(move.card_ids) do
                            all_cards:append(card_id)
                        end
                    end
                end
            end
        end
        --用askForAG让player选择体力值张 
        -- 选择至多4张花色不同的牌  
        for i = 1, player:getHp() do  
            room:fillAG(all_cards, player)  
            local card_id = room:askForAG(player, all_cards, true, "nashun")  
            if card_id == -1 then 
                room:clearAG(player)
                break 
            end
            room:obtainCard(player, card_id, false)
            all_cards:removeOne(card_id)  
            room:clearAG(source)
        end 
        return false
	end,
}
kuailiangkuaiyue:addSkill(jianxiangVS)  
kuailiangkuaiyue:addSkill(nashun)  
-- 翻译表  
sgs.LoadTranslationTable{  
["#kuailiangkuaiyue"] = "上庸守将",  
["kuailiangkuaiyue"] = "蒯良蒯越",  
["&kuailiangkuaiyue"] = "蒯良蒯越",  
["illustrator:kuailiangkuaiyue"] = "画师名",  
["jianxiang"] = "谏降",  
[":jianxiang"] = "出牌阶段限一次。你可以选择一名手牌最多的角色，然后令另一名角色选择：1.交给其1张牌；2.受到其造成的1点伤害。",  
["nashun"] = "纳顺",  
[":nashun"] = "与你势力相同的角色弃牌阶段结束时，你可以获得其弃置的至多X张牌，X为你的体力值。",
}  

liubian = sgs.General(extension, "liubian", "qun", 3)  -- 吴国，4血，男性  
shiyuan_skill = sgs.CreateTriggerSkill{  
    name = "shiyuan",  
    events = {sgs.TargetConfirmed},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)    
        -- 寻找拥有诗怨技能的角色  
        local shiyuan_player = room:findPlayerBySkillName(self:objectName())  
        if not (shiyuan_player and shiyuan_player:isAlive() and shiyuan_player:hasSkill(self:objectName())) then return "" end
        if shiyuan_player:hasFlag("shiyuan_used") then return "" end

        local use = data:toCardUse()  
        local source = use.from
        if not (source and source:isAlive()) then return "" end
        if use.card:getTypeId()==sgs.Card_TypeSkill then return "" end --不能是技能卡
        local is_involved = false  
        local other_player = nil  
            
        -- 检查是否为使用者或目标  
        if source and source:objectName() == shiyuan_player:objectName() then  
            -- 技能拥有者使用牌指定其他角色  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() ~= shiyuan_player:objectName() then  
                    is_involved = true  
                    other_player = target  
                    break  
                end  
            end  
        elseif source and source:objectName() ~= shiyuan_player:objectName() then  
            -- 其他角色使用牌指定技能拥有者  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() == p:objectName() then  
                    is_involved = true  
                    other_player = source  
                    break  
                end  
            end  
        end
        if is_involved then
            return self:objectName(), shiyuan_player:objectName()
        end
        return ""
          
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            room:setPlayerFlag(ask_who, "shiyuan_used")  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        local source = use.from  
        local other_player = nil  
          
        -- 确定对比的角色  
        if source and source:objectName() == ask_who:objectName() then  
            -- 技能拥有者使用牌  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() ~= ask_who:objectName() then  
                    other_player = target  
                    break  
                end  
            end  
        else  
            -- 其他角色使用牌指定技能拥有者  
            other_player = source  
        end  
          
        if other_player then  
            local my_hp = ask_who:getHp()  
            local other_hp = other_player:getHp()  
            local draw_num = 0  
              
            if other_hp > my_hp then  
                draw_num = 3  -- 对方体力大于自己  
            elseif other_hp == my_hp then  
                draw_num = 2  -- 对方体力等于自己  
            else  
                draw_num = 1  -- 对方体力小于自己  
            end  
              
            if draw_num > 0 then  
                ask_who:drawCards(draw_num, self:objectName())  
            end  
        end  
          
        return false  
    end  
}  
liubian:addSkill(shiyuan_skill)

-- 翻译表  
sgs.LoadTranslationTable{
["liubian"] = "刘辩",  
["shiyuan"] = "诗怨",  
[":shiyuan"] = "每回合限一次。当你使用牌指定其他角色为目标或成为其他角色使用牌的目标时，若其体力值：大于你，你摸3张牌；等于你，你摸2张牌；小于你，你摸1张牌。"
}  
lusu_mou = sgs.General(extension, "lusu_mou", "wu", 3)  

YinglueCard = sgs.CreateSkillCard{  
    name = "YinglueCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local choice = room:askForChoice(source, "yinglue", "yinglue_losehp+yinglue_draw")  
          
        if choice == "yinglue_losehp" then  
            room:loseHp(target, 1)  
            room:addPlayerMark(target, "yinglue_draw", 2)  
        else  
            room:drawCards(target, 2, "yinglue")  
            room:addPlayerMark(target, "yinglue_maxcards", 2)  
        end  
    end  
}  
  
YinglueVS = sgs.CreateZeroCardViewAsSkill{  
    name = "yinglue",  
    view_as = function(self)  
        card = YinglueCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#YinglueCard")  
    end  
}  
  
Yinglue = sgs.CreateTriggerSkill{  
    name = "yinglue",  
    view_as_skill = YinglueVS,  
    events = {sgs.DrawNCards, sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.DrawNCards then  
            if player:getMark("yinglue_draw") > 0 then  
                return self:objectName()  
            end  
        elseif event == sgs.EventPhaseStart then  
            if player:getPhase() == sgs.Player_Finish and player:getMark("yinglue_maxcards") > 0 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.DrawNCards then  
            local count = data:toInt()  
            data:setValue(count + player:getMark("yinglue_draw"))  
            room:setPlayerMark(player, "yinglue_draw", 0)  
        elseif event == sgs.EventPhaseStart then  
            room:setPlayerMark(player, "yinglue_maxcards", 0)   
        end  
        return false  
    end  
}  
  
YinglueMaxCards = sgs.CreateMaxCardsSkill{  
    name = "#yinglue_maxcards",  
    extra_func = function(self, target)  
        if target:getMark("yinglue_maxcards") > 0 then  
            return -target:getMark("yinglue_maxcards")  
        end  
        return 0  
    end  
}


Mengshi = sgs.CreateTriggerSkill{  
    name = "mengshi",  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@mengshi",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            if player and player:isAlive() and player:hasSkill(self:objectName())   
                and player:getPhase() == sgs.Player_Finish   
                and player:getMark("@mengshi") > 0 then  
                return self:objectName(), player:objectName()
            end  
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then  
            -- 检查盟势标记的两名角色是否存活  
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
            local target1_name = owner:property("mengshi_target1"):toString()  
            local target2_name = owner:property("mengshi_target2"):toString()  
            if target1_name ~= "" and target2_name ~= "" then  
                local target1 = room:findPlayer(target1_name)  
                local target2 = room:findPlayer(target2_name)  
                if target1 and target1:isAlive() and target2 and target2:isAlive() then  
                    return self:objectName(), owner:objectName()
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            return player:askForSkillInvoke(self:objectName(),data)
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player),   
                self:objectName(), 2, 2, "@mengshi-invoke", true)  
              
            local target1 = targets:at(0)  
            local target2 = targets:at(1)  
              
            local hp1 = target1:getHp()  
            local hp2 = target2:getHp()  
              
            -- 交换体力值  
            room:setPlayerProperty(target1, "hp", sgs.QVariant(hp2))  
            room:setPlayerProperty(target2, "hp", sgs.QVariant(hp1))  
            room:broadcastProperty(target1, "hp")  
            room:broadcastProperty(target2, "hp")  
              
            -- 失去体力  
            local diff = math.abs(hp1 - hp2)  
            if diff > 0 then  
                room:loseHp(player, diff)  
            end  
            room:removePlayerMark(player, "@mengshi")
            -- 记录目标角色  
            room:setPlayerProperty(player, "mengshi_target1", sgs.QVariant(target1:objectName()))  
            room:setPlayerProperty(player, "mengshi_target2", sgs.QVariant(target2:objectName()))  
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then  
            -- 回合结束时效果  
            room:drawCards(ask_who, 1, self:objectName())  
            local recover = sgs.RecoverStruct()  
            recover.who = ask_who  
            recover.recover = 1  
            room:recover(ask_who, recover)  
        end  
        return false  
    end  
}


lusu_mou:addSkill(Yinglue)  
lusu_mou:addSkill(YinglueMaxCards)  
lusu_mou:addSkill(Mengshi)  
extension:insertRelatedSkills("yinglue", "#yinglue_maxcards")  
  
sgs.LoadTranslationTable{
    ["lusu_mou"] = "谋鲁肃",  
    ["#lusu_mou"] = "联盟的缔造者",  
    ["yinglue"] = "英略",  
    [":yinglue"] = "出牌阶段限一次，你可以令一名角色：1.失去1点体力，下个摸牌阶段摸牌数+2；2.摸2张牌，下个弃牌阶段手牌上限-2。",  
    ["yinglue_losehp"] = "失去1点体力，下次摸牌+2",  
    ["yinglue_draw"] = "摸2张牌，下次手牌上限-2",  
    ["mengshi"] = "盟势",  
    [":mengshi"] = "限定技，你的结束阶段开始时，你可以选择两名其他角色，令这两名角色交换体力值，然后你失去X点体力（X为这两名角色的体力值之差）。每回合结束时，若这两名角色都存活，你摸一张牌并回复1点体力。",  
    ["@mengshi"] = "盟势",  
    ["@mengshi-invoke"] = "盟势：选择两名角色交换体力值",  
}

-- 创建武将蒙恬  
shendanshenyi = sgs.General(extension, "shendanshenyi", "wei", 4) -- 蜀势力，4血，男性（默认）  

ZhishuCard = sgs.CreateSkillCard{  
    name = "ZhishuCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        --return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
        if #targets > 0 or to_select:objectName() == sgs.Self:objectName() then  
            return false  
        end
        return true  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local card_id = self:getSubcards():first()  
          
        -- 交给目标角色手牌  
        room:obtainCard(target, card_id, false)  
          
        -- 判断势力关系  
        if not source:isFriendWith(target) then  
            -- 势力不同，依次视为使用杀和决斗  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:setSkillName("zhishu")  
            slash:deleteLater()
            if not source:isCardLimited(slash, sgs.Card_MethodUse) then  
                room:useCard(sgs.CardUseStruct(slash, source, target), false)  
            end  
              
            local duel = sgs.Sanguosha:cloneCard("duel")  
            duel:setSkillName("zhishu")  
            duel:deleteLater()
            if not source:isCardLimited(duel, sgs.Card_MethodUse) then  
                room:useCard(sgs.CardUseStruct(duel, source, target), false)  
            end  
        elseif source:isFriendWith(target) then  
            -- 势力相同，检查是否为场上体力最大  
            local max_hp = 0  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:getHp() > max_hp then  
                    max_hp = p:getHp()  
                end  
            end  
              
            if target:getHp() == max_hp then  
                -- 依次视为对自己使用桃和酒  
                local peach = sgs.Sanguosha:cloneCard("peach")  
                peach:setSkillName("zhishu")  
                peach:deleteLater()
                if not source:isCardLimited(peach, sgs.Card_MethodUse) then  
                    room:useCard(sgs.CardUseStruct(peach, source, source), false)  
                end  
                  
                local analeptic = sgs.Sanguosha:cloneCard("analeptic")  
                analeptic:setSkillName("zhishu")  
                analeptic:deleteLater()
                if not source:isCardLimited(analeptic, sgs.Card_MethodUse) then  
                    room:useCard(sgs.CardUseStruct(analeptic, source, source), false)  
                end  
            end  
        end  
    end  
}  
  
-- 质蜀视为技能  
zhishuVS = sgs.CreateOneCardViewAsSkill{  
    name = "zhishu",  
    filter_pattern = ".|.|.|hand",  
    relate_to_place = "head",
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#ZhishuCard") and player:inHeadSkills(self) and not player:isKongcheng()
    end,  
    view_as = function(self, card)  
        local zhishu_card = ZhishuCard:clone()  
        zhishu_card:addSubcard(card)  
        zhishu_card:setSkillName(self:objectName())  
        zhishu_card:setShowSkill(self:objectName())  
        return zhishu_card  
    end  
}

congweiSkill = sgs.CreateTriggerSkill{  
    name = "congwei",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Compulsory,
    relate_to_place = "deputy",
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:inDeputySkills(self) then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)-- 锁定技，必须发动  
    end,  
    on_effect = function(self, event, room, player, data)  
        if player:isKongcheng() then  
            -- 没有手牌直接摸牌  
            room:drawCards(player, 2, self:objectName())  
        else  
            -- 有手牌需要选择目标交出  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                targets:append(p)  
            end  
              
            if not targets:isEmpty() then  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@congwei-give")  
                if target then  
                    local handcards = player:getHandcards()  
                    if not handcards:isEmpty() then
                        for _,card in sgs.qlist(handcards) do
                            room:obtainCard(target, card, false)  
                        end
                    end  
                    room:drawCards(player, 2, self:objectName())  
                end  
            end  
        end  
        return false  
    end  
}
shendanshenyi:addSkill(zhishuVS)  
shendanshenyi:addSkill(congweiSkill)  
-- 翻译表  
sgs.LoadTranslationTable{  
["#shendanshenyi"] = "上庸守将",  
["shendanshenyi"] = "申耽申仪",  
["&shendanshenyi"] = "申耽申仪",  
["illustrator:shendanshenyi"] = "画师名",  
["zhishu"] = "质蜀",  
[":zhishu"] = "主将技。出牌阶段限一次。你可以交给一名其他角色一张手牌，若其势力与你不同，你可以依次视为对其使用一张杀和一张决斗；若其势力与你相同，且为场上体力最大，你可以依次视为对自己使用一张桃和一张酒。",  
["congwei"] = "从魏",  
[":congwei"] = "副将技。锁定技。当你受到伤害后，你需将所有手牌交给一名其他角色，然后你摸2张牌。",
["@congwei-give"] = "从魏：请选择一名其他角色，将所有手牌交给其",
}  
  
simaao = sgs.General(extension, "simaao", "qun", 3)  

longfengTransferCard = sgs.CreateSkillCard{  
    name = "longfengTransferCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return to_select:getMark("long")>0 or to_select:getMark("feng")>0  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)
        dead_player = targets[1]
        if dead_player:getMark("long") > 0 then  
            local target = room:askForPlayerChosen(source, room:getOtherPlayers(dead_player), "longfeng_transfer_dragon",  
                                                    "@longfeng-transfer-dragon", true)  
            if target then  
                room:setPlayerMark(dead_player, "long", 0)  
                room:addPlayerMark(target, "long", 1)  
                room:detachSkillFromPlayer(dead_player, "huoji")  
                room:attachSkillToPlayer(target, "huoji")
                if target:getMark("feng") then 
                    room:attachSkillToPlayer(target, "longfengYehuo")
                end
            end  
        end  
            
        if dead_player:getMark("feng") > 0 then  
            local target = room:askForPlayerChosen(source, room:getOtherPlayers(dead_player), "longfeng_transfer_phoenix",  
                                                    "@longfeng-transfer-phoenix", true)  
            if target then  
                room:setPlayerMark(dead_player, "feng", 0)  
                room:addPlayerMark(target, "feng", 1)  
                room:detachSkillFromPlayer(dead_player, "lianhuan")  
                room:attachSkillToPlayer(target, "lianhuan")  
                if target:getMark("long") then 
                    room:attachSkillToPlayer(target, "longfengYehuo")
                end
            end  
        end  
    end  
}  
longfengVS = sgs.CreateZeroCardViewAsSkill{  
    name = "longfeng",  
      
    view_as = function(self)  
        local card = longfengTransferCard:clone()  
        card:setSkillName(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#longfengTransferCard")  
    end  
}  
longfeng = sgs.CreateTriggerSkill{  
    name = "longfeng",  
    events = {sgs.Death, sgs.EventPhaseStart},
    view_as_skill = longfengVS,
    --limit_mark = "@longfeng",
    can_trigger = function(self, event, room, player, data)  
        local simaao = room:findPlayerBySkillName(self:objectName())  
        if not simaao or not simaao:isAlive() or not simaao:hasSkill(self:objectName()) then return "" end  

        if event == sgs.EventPhaseStart then  
            if player == simaao and player:getPhase() == sgs.Player_Start and player:getMark("@longfeng") == 0 then  
                return self:objectName(),simaao:objectName()
            end 
        elseif event == sgs.Death then  
            local death_data = data:toDeath()  
            local dead_player = death_data.who  
            if dead_player:getMark("long") > 0 or dead_player:getMark("feng") > 0 then  
                return self:objectName(),simaao:objectName()
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            return ask_who:askForSkillInvoke("longfeng", data)  
        elseif event == sgs.Death then  
            return ask_who:askForSkillInvoke("longfeng_transfer", data)  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then
            if ask_who:getMark("@longfeng") == 0 then --第一个准备阶段，分配2个
                room:setPlayerMark(ask_who,"@longfeng",1)
                local targets = room:askForPlayersChosen(ask_who, room:getAlivePlayers(),   
                                                    self:objectName(), 2, 2,   
                                                    "@longfeng-choose", false)  
                
                if targets:length() == 2 then  
                    -- 询问哪个角色获得龙标记  
                    local dragon_target = room:askForPlayerChosen(ask_who, targets, "longfeng_dragon",   
                                                                "@longfeng-dragon")  
                    local phoenix_target = nil  
                    for _, target in sgs.qlist(targets) do  
                        if target ~= dragon_target then  
                            phoenix_target = target  
                            break  
                        end  
                    end  
                    
                    -- 分配标记  
                    room:addPlayerMark(dragon_target, "long", 1)  
                    room:addPlayerMark(phoenix_target, "feng", 1)  
                    
                    -- 赋予技能  
                    room:attachSkillToPlayer(dragon_target, "huoji")  
                    room:attachSkillToPlayer(phoenix_target, "lianhuan")  
                end
            end              
        elseif event == sgs.Death then  
            -- 死亡时转移标记  
            local death_data = data:toDeath()  
            local dead_player = death_data.who  
            local other_players = room:getOtherPlayers(dead_player)  
              
            if dead_player:getMark("long") > 0 then  
                local target = room:askForPlayerChosen(ask_who, other_players, "longfeng_transfer_dragon",  
                                                     "@longfeng-transfer-dragon", true)  
                if target then  
                    room:setPlayerMark(dead_player, "long", 0)  
                    room:addPlayerMark(target, "long", 1)  
                    room:detachSkillFromPlayer(dead_player, "huoji")  
                    room:attachSkillToPlayer(target, "huoji")
                    if target:getMark("feng") then 
                        room:attachSkillToPlayer(target, "longfengYehuo")
                    end
                end  
            end  
              
            if dead_player:getMark("feng") > 0 then  
                local target = room:askForPlayerChosen(ask_who, other_players, "longfeng_transfer_phoenix",  
                                                     "@longfeng-transfer-phoenix", true)  
                if target then  
                    room:setPlayerMark(dead_player, "feng", 0)  
                    room:addPlayerMark(target, "feng", 1)  
                    room:detachSkillFromPlayer(dead_player, "lianhuan")  
                    room:attachSkillToPlayer(target, "lianhuan")  
                    if target:getMark("long") then 
                        room:attachSkillToPlayer(target, "longfengYehuo")
                    end
                end  
            end  
        end  
          
        return false  
    end  
}  
longfengYehuoCard = sgs.CreateSkillCard{  
    name = "longfengYehuoCard",  
    skill_name = "longfengYehuoCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        if #targets >= 3 then return false end  
        return to_select:objectName() ~= sgs.Self:objectName() and to_select:isAlive()  
    end,  
    feasible = function(self, targets)  
        return #targets >= 1 and #targets <= 3  
    end,  
    on_use = function(self, room, source, targets)  
        room:setPlayerMark(source, "long", 0) -- 标记限定技已使用  
        room:setPlayerMark(source, "feng", 0) -- 标记限定技已使用  
        room:detachSkillFromPlayer(source, "huoji")  
        room:detachSkillFromPlayer(source, "lianhuan")  
          
        -- 分配伤害  
        local total_damage = 3  
        local remaining_damage = total_damage
        local damage_allocation = {}  
        local exceed = false
        for i = 1, #targets do  --肯定要初始化啊，万一给第一个人分配了3点伤害，后面的为空啦
            damage_allocation[i] = 0  
        end  
        -- 为每个目标分配伤害  
        for i, target in ipairs(targets) do                
            if i == #targets then  
                -- 最后一个目标获得剩余所有伤害  
                damage_allocation[i] = remaining_damage  
                if damage_allocation[i] >= 2 then 
                    exceed = true 
                end
            else  
                -- 让玩家选择分配给当前目标的伤害数  
                local max_damage = math.min(remaining_damage, total_damage)  
                local choices = {}  
                for d = 1, max_damage do  
                    table.insert(choices, tostring(d))  
                end  
                local choice = room:askForChoice(source, "LuaYehuo", table.concat(choices, "+"))  
                damage_allocation[i] = tonumber(choice)  
                if damage_allocation[i] >= 2 then 
                    exceed = true 
                end
                remaining_damage = remaining_damage - damage_allocation[i]
            end  
        end  
          
        -- 执行伤害  
        for i, target in ipairs(targets) do  
            if damage_allocation[i] > 0 then  
                local damage = sgs.DamageStruct("LuaYehuo", source, target, damage_allocation[i], sgs.DamageStruct_Fire)  
                room:damage(damage)  
            end  
        end  
        if exceed then
            room:loseHp(source,3)
        end
    end  
}  
  
-- 业火技能  
longfengYehuo = sgs.CreateZeroCardViewAsSkill{  
    name = "longfengYehuo",  
      
    view_as = function(self)  
        local card = longfengYehuoCard:clone()  
        card:setSkillName(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return player:getMark("long") > 0 and player:getMark("feng") > 0  
    end  
}  


yinshi = sgs.CreateTriggerSkill{  
    name = "yinshi",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        local damage = data:toDamage()  
          
        -- 检查是否有防具  
        if player:getArmor() then  
            return ""  
        end  
          
        -- 检查伤害类型：属性伤害或锦囊伤害  
        local is_nature_damage = (damage.nature == sgs.DamageStruct_Fire or   
                                 damage.nature == sgs.DamageStruct_Thunder)  
        local is_trick_damage = (damage.card and damage.card:getTypeId() == sgs.Card_TypeTrick)  
          
        if is_nature_damage or is_trick_damage then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，自动触发  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
          
        room:notifySkillInvoked(player, self:objectName())  
          
        -- 输出日志  
        local log = sgs.LogMessage()  
        log.type = "#SkillNullify"  
        log.from = player  
        log.arg = self:objectName()  
        if damage.card then  
            log.arg2 = damage.card:objectName()  
        else  
            log.arg2 = "nature_damage"  
        end  
        room:sendLog(log)  
          
        return true -- 返回true防止伤害  
    end  
}

simaao:addSkill(longfeng)  
simaao:addSkill(longfengYehuo)  
simaao:addSkill(yinshi)  

sgs.LoadTranslationTable{
["#simaao"] = "龙凤之主",  
["simaao"] = "司马傲",  
["longfeng"] = "龙凤",  
[":longfeng"] = "你的首个准备阶段，你可以令2名角色分别获得'龙'标记和'凤'标记。拥有龙标记的角色获得技能'火技'，拥有凤标记的角色获得技能'连环'。出牌阶段限一次，你可以转移一个标记；拥有龙凤标记的角色死亡时，你可以转移标记。",  
["@longfeng-choose"] = "选择2名角色分别获得龙凤标记",  
["@longfeng-dragon"] = "选择获得龙标记的角色",  
["@longfeng-transfer-dragon"] = "选择转移龙标记的目标",  
["@longfeng-transfer-phoenix"] = "选择转移凤标记的目标",  
["longfeng_transfer_choice"] = "选择要转移的标记",  
["transfer_long"] = "转移龙标记",  
["transfer_feng"] = "转移凤标记",  
["long"] = "龙",  
["feng"] = "凤",  
  
["longfengYehuo"] = "业火",  
[":longfengYehuo"] = "任意一名角色若同时拥有龙标记和凤标记，其可以移除这两个标记，发动业火。",  
  
-- 火技和连环技能（如果游戏中没有，需要实现）  
["huoji"] = "火技",  
["lianhuan"] = "连环",  
[":lianhuan"] = "你可以将♣手牌当【铁索连环】使用或重铸。",

["yinshi"] = "隐士",
[":yinshi"] = "锁定技。当你受到属性伤害或者锦囊的伤害时，若你装备区没有防具，你防止此伤害",
}

simafu = sgs.General(extension, "simafu", "wei", 3)  -- 吴国，4血，男性  

panxiang = sgs.CreateTriggerSkill{  
    name = "panxiang",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        -- 寻找拥有蹒襄技能的角色  
        local simafu = room:findPlayerBySkillName(self:objectName())  
        if simafu and simafu:isAlive() and simafu:hasSkill(self:objectName()) and not simafu:hasFlag("panxiang_used") then  
            return self:objectName(), simafu:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        room:setPlayerFlag(ask_who,"panxiang_used")
        local damage = data:toDamage()  
        local choices = {}
        if ask_who:getMark("@last_choice") == 1 then
            choices = {"panxiang:increase", "cancel"}  
        elseif ask_who:getMark("@last_choice") == 2 then
            choices = {"panxiang:reduce", "cancel"}
        else
            choices = {"panxiang:reduce", "panxiang:increase", "cancel"}  
        end 
        local choice = room:askForChoice(ask_who, self:objectName(), table.concat(choices, "+"), data)  
        if choice == "cancel" then  
            return false  
        end  
   
        if choice == "panxiang:reduce" then 
            room:setPlayerMark(ask_who,"@last_choice",1) 
            -- 选择1：伤害-1，伤害来源摸2张牌  
            damage.damage = damage.damage - 1  
            data:setValue(damage)  
                
            if damage.from and damage.from:isAlive() then  
                damage.from:drawCards(2, self:objectName())  
            end  
            if damage.damage <= 0 then
                return true
            end
        elseif choice == "panxiang:increase" then  
            room:setPlayerMark(ask_who,"@last_choice",2) 
            -- 选择2：伤害+1，伤害目标摸3张牌  
            damage.damage = damage.damage + 1  
            data:setValue(damage)  
              
            if damage.to and damage.to:isAlive() then  
                damage.to:drawCards(3, self:objectName())  
            end  
        end  
        return false  
    end  
}

chenjie = sgs.CreateTriggerSkill{  
    name = "chenjie",  
    events = {sgs.Death},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        -- 寻找拥有臣节技能的角色  
        local death = data:toDeath()  
        local dead_player = death.who  

        --local skill_owner = room:findPlayerBySkillName(self:objectName())  
        --if skill_owner and skill_owner:isAlive() and not skill_owner:hasFlag("chenjie_" .. dead_player:objectName()) then  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:hasFlag("chenjie_" .. dead_player:objectName()) then  
            room:setPlayerFlag(player, "chenjie_" .. dead_player:objectName())  
            return self:objectName() .. "->" .. dead_player:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local death = data:toDeath()  
        local dead_player = death.who  

        -- 弃置区域内所有牌  
        local all_cards = sgs.IntList()  
          
        -- 添加手牌  
        for _, card_id in sgs.qlist(ask_who:handCards()) do  
            all_cards:append(card_id)  
        end  
          
        -- 添加装备牌  
        for _, card in sgs.qlist(ask_who:getEquips()) do  
            all_cards:append(card:getId())  
        end  
          
        -- 添加判定区的牌  
        for _, card in sgs.qlist(ask_who:getJudgingArea()) do  
            all_cards:append(card:getId())  
        end  
          
        for _, card in sgs.qlist(all_cards) do  
            room:throwCard(card, ask_who, ask_who)  
        end  
          
        -- 摸4张牌  
        ask_who:drawCards(4, self:objectName())  
        return false  
    end  
}
simafu:addSkill(panxiang)
simafu:addSkill(chenjie)

sgs.LoadTranslationTable{  
    ["junba"] = "军八",  
      
    ["simafu"] = "司马孚",  
    ["#simafu"] = "忠肃公",  
    ["illustrator:simafu"] = "未知",  
      
    ["panxiang"] = "蹒襄",  
    [":panxiang"] = "每回合限一次。当任意一名角色受到伤害时，你可以选择：1.令此伤害-1，伤害来源摸2张牌；2.令此伤害+1，伤害目标摸3张牌。不能连续选择相同项",  
    ["panxiang:reduce"] = "令此伤害-1，伤害来源摸2张牌",  
    ["panxiang:increase"] = "令此伤害+1，伤害目标摸3张牌",  
    ["#PanxiangReduce"] = "%from 发动了'%arg'，伤害减少1点",  
    ["#PanxiangIncrease"] = "%from 发动了'%arg'，伤害增加1点",  
    ["$panxiang1"] = "进退维谷，唯求自保。",  
    ["$panxiang2"] = "时局动荡，当以和为贵。",  

    ["chenjie"] = "臣节",  
    [":chenjie"] = "当任意一名角色死亡时，你可以弃置区域内所有牌，然后摸4张牌。",  
    ["$chenjie1"] = "忠臣之节，死而后已。",  
    ["$chenjie2"] = "臣节不移，虽死犹荣。",  
    
    ["~simafu"] = "忠义两难全...",  
}

sunru = sgs.General(extension, "sunru", "wu", 3, false)  -- 吴国，4血，男性  
chishi = sgs.CreateTriggerSkill{
	name = "chishi",
	events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					if not (move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_Play and player:isFriendWith(move.from)) then return "" end
					if move.from:isKongcheng() then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		return player:askForSkillInvoke(self:objectName(),data)
	end,
    on_effect = function(self, event, room, player, data)
		local current = room:getCurrent()
		current:drawCards(2)
        local max_cards_mark = "chishi_maxcards_" .. current:objectName()  
        room:setPlayerFlag(current, max_cards_mark)          
		return false
	end 
}  

-- 手牌上限修正技能  
chishi_maxcards = sgs.CreateMaxCardsSkill{  
    name = "#chishi-maxcards",  
    extra_func = function(self, target)  
        local mark_name = "chishi_maxcards_" .. target:objectName()  
        if target:hasFlag(mark_name) then
            return 2
        else
            return 0
        end
    end  
}

weimian = sgs.CreateViewAsSkill{  
    name = "weimian",  
    n = 999, -- 可以选择所有手牌  
    view_filter = function(self, selected, to_select)  
        -- 只能选择手牌  
        return to_select:getTypeId() ~= sgs.Card_TypeSkill  
    end,  
    view_as = function(self, cards)  
        -- 必须弃置所有手牌  
        if #cards ~= sgs.Self:getHandcardNum() then return nil end  
        local card = WeimianCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())  
        for _, c in ipairs(cards) do  
            card:addSubcard(c)  
        end  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#WeimianCard")  
    end  
}  
  
-- 慰勉卡牌类  
WeimianCard = sgs.CreateSkillCard{  
    name = "WeimianCard",  
    target_fixed = true,  
    will_throw = true,  
    on_use = function(self, room, source, targets)  
        -- 弃置所有手牌已经在使用时自动完成  
          
        -- 让玩家选择回复体力或摸牌  
        local choices = {}  
        if source:isWounded() then  
            table.insert(choices, "recover")  
        end  
        table.insert(choices, "draw")  
          
        local choice = room:askForChoice(source, "weimian", table.concat(choices, "+"))  
          
        if choice == "recover" and source:isWounded() then  
            -- 回复1点体力  
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 1  
            room:recover(source, recover)  
        else  
            -- 摸4张牌  
            source:drawCards(4, "weimian")  
        end  
    end  
}  
  
sunru:addSkill(chishi)  
sunru:addSkill(chishi_maxcards)
sunru:addSkill(weimian)
-- 翻译表  
sgs.LoadTranslationTable{
    ["sunru"] = "孙茹",
    ["chishi"] = "持室",
    [":chishi"] = "每回合限一次。当前回合角色使用、打出、失去最后一张手牌时，若其与你势力相同，你可以令其摸2张牌，此回合手牌上限+2",
    ["weimian"] = "慰勉",  
    [":weimian"] = "出牌阶段限一次，你可以弃置所有手牌，然后回复1点体力或摸四张牌。",  
    ["WeimianCard"] = "慰勉",  
    ["weimian:recover"] = "回复1点体力",  
    ["weimian:draw"] = "摸四张牌",  
    ["@weimian"] = "慰勉：选择弃置所有手牌"  
}  

wangping_junba = sgs.General(extension, "wangping_junba", "shu", 4)  
  
feijunCard = sgs.CreateSkillCard{  
    name = "FeijunCard",  
    will_throw = true,  
    target_fixed = false,  
    filter = function(self, targets, to_select, Self)  
        if #targets >= 1 then return false end  
        if to_select:objectName() == Self:objectName() then return false end  

        return to_select:getHandcardNum() > Self:getHandcardNum()-1 or to_select:getEquips():length() > Self:getEquips():length()-1
    end,  
    feasible = function(self, targets, Self)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  

        local choices = {}  
        if target:getHandcardNum() > source:getHandcardNum() then  
            table.insert(choices, "handcard")  
        end  
        if target:getEquips():length() > source:getEquips():length() then  
            table.insert(choices, "equip")  
        end       
        if #choices == 0 then return false end  
        local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))  

          
        -- 检查是否第一次选择该目标  
        local first_time_mark = "feijun_first_" .. target:objectName()  
        local is_first_time = source:getMark(first_time_mark) == 0  
        if is_first_time then  
            room:setPlayerMark(source, first_time_mark, 1)  
        end  
          
        if choice == "handcard" then  
            -- 选择1：令手牌数大于你的角色交给你一张牌  
            if target:getHandcardNum() > source:getHandcardNum() and not target:isNude() then  
                local card_id = room:askForCardChosen(target, target, "he", "feijun", false, sgs.Card_MethodNone)  
                room:obtainCard(source, sgs.Sanguosha:getCard(card_id))  
            end  
        elseif choice == "equip" then  
            -- 选择2：令装备区大于你的角色弃置装备区的一张装备  
            if target:getEquips():length() > source:getEquips():length() and not target:getEquips():isEmpty() then  
                local card_id = room:askForCardChosen(target, target, "e", "feijun", false, sgs.Card_MethodDiscard)  
                room:throwCard(sgs.Sanguosha:getCard(card_id), target, target)  
            end  
        end  
          
        -- 若第一次选择该目标，摸2张牌  
        if is_first_time then  
            source:drawCards(2, "feijun")  
        end  
    end  
}  
  
-- 飞军视为技  
feijun = sgs.CreateOneCardViewAsSkill{  
    name = "feijun",  
    filter_pattern = ".",  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#FeijunCard")  
    end,  
    view_as = function(self, card)  
        local acard = feijunCard:clone()  
        acard:addSubcard(card:getEffectiveId())  
        acard:setShowSkill(self:objectName())  
        return acard  
    end  
}  
wangping_junba:addSkill(feijun)

sgs.LoadTranslationTable{
["wangping_junba"] = "王平",  
["#wangping_junba"] = "镇北将军",  
["feijun"] = "飞军",  
[":feijun"] = "出牌阶段限一次，你可以弃置一张牌，然后选择：1.令一名手牌数大于你的角色交给你一张牌；2.令一名装备区大于你的角色弃置装备区的一张装备。若本局游戏中，你第一次选择该目标，你摸2张牌。",  
["handcard"] = "令其交给你一张手牌",  
["equip"] = "令其弃置一张装备",
}

wangxu = sgs.General(extension, "wangxu", "wei", 3)  

shepan = sgs.CreateTriggerSkill{  
    name = "shepan",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and use.from and use.from:objectName() ~= player:objectName() then  
            if use.to:contains(player) and not player:hasFlag("shepan") and use.card:getTypeId()~=sgs.Card_TypeSkill then  
                return self:objectName(), player:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)   
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        local choices = {"draw", "cancel"}  
        if not use.from:isKongcheng() then  
            table.insert(choices, 1, "put_card")  
        end  
          
        local choice = room:askForChoice(ask_who, self:objectName(), table.concat(choices, "+"), data)  
        if choice == "cancel" then return false end
        room:setPlayerFlag(ask_who,"shepan")          
        if choice == "draw" then  
            -- 选择1：摸一张牌  
            ask_who:drawCards(1, "shepan")  
        elseif choice == "put_card" then  
            -- 选择2：将其1张手牌置于牌堆顶  
            local card_id = room:askForCardChosen(ask_who, use.from, "h", self:objectName())  
            if card_id then  
                room:obtainCard(ask_who, card_id, false)  
                room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_DrawPile, true) 
            end  
        end  
        -- 若你与其手牌数相等，此牌对你无效  
        if ask_who:getHandcardNum() == use.from:getHandcardNum() then  
            sgs.Room_cancelTarget(use, ask_who)
            --data = sgs.QVariant()  
            data:setValue(use)  
        end            
        return false  
    end  
}  

kaiji = sgs.CreateTriggerSkill{  
    name = "kaiji",  
    events = {sgs.EventPhaseStart, sgs.Dying},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data) 
        if not (player and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.Dying then --有角色濒死
            local dying = data:toDying()  
            room:setPlayerMark(dying.who,"kaiji",1)
        elseif event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start and player:hasSkill(self:objectName()) then
            for _, p in room:getAlivePlayers() do
                if p:getMark("kaiji") then
                    return self:objectName()
                end
            end
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        --统计濒死但还活着的人数
        local num = 0
        for _, p in room:getAlivePlayers() do
            if p:getMark("kaiji") then
                num = num + 1
            end
        end
        if num <= 0 then return false end
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end  
        local chosen_players = room:askForPlayersChosen(player, targets, self:objectName(), num, num, "请选择玩家", false)
        local has_diamond = false
        for _, chosen_player in sgs.qlist(chosen_players) do  
            room:drawCards(chosen_player, 1)  
            if chosen_player:getHandcards():last():getSuit() == sgs.Card_Diamond then
                has_diamond = true
            end
        end
        if has_diamond then
            room:drawCards(player, 1) 
        end
        return false  
    end  
}

wangxu:addSkill(shepan)
wangxu:addSkill(kaiji)
sgs.LoadTranslationTable{
["wangxu"] = "王旭",  
["#wangxu"] = "魏之谋士",  
["shepan"] = "慑叛",  
[":shepan"] = "每回合限一次。当你成为其他角色使用牌的目标后，你可以选择：1.摸一张牌；2.将其1张手牌置于牌堆顶；然后若你与其手牌数相等，此牌对你无效。",  
["@kaiji-choose"] = "开济：选择至多%arg名角色各摸一张牌",  
["@shepan"] = "慑叛",  
["shepan:draw"] = "摸一张牌",  
["shepan:put_card"] = "将其手牌置于牌堆顶",
["kaiji"] = "开济",
[":kaiji"] = "准备阶段，你可以令至多X名相同势力角色各摸1张牌，X为进入过濒死状态的存活角色数，若有角色因此获得方块牌，你摸一张牌",
}

wangyue = sgs.General(extension, "wangyue", "shu", 4) -- 蜀势力，4血，男性（默认）  

JingjianSlashVS = sgs.CreateViewAsSkill{  
    name = "JingjianSlash",  
    n = 999, -- 允许选择多张牌  
    enabled_at_play = function(self, player)  
        return not player:hasFlag("JingjianSlash_used")  
    end,  
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then  
            return not to_select:isEquipped()  
        else  
            -- 检查颜色是否相同  
            return not to_select:isEquipped() and to_select:sameColorWith(selected[1])  
        end  
    end,  
    view_as = function(self, cards)  
        local attack_range = sgs.Self:getAttackRange()  
        if #cards == attack_range and #cards > 0 then  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            for _, card in ipairs(cards) do  
                slash:addSubcard(card:getId())  
            end  
            slash:setSkillName(self:objectName())  
            slash:setShowSkill(self:objectName())  
            return slash  
        end  
    end  
}  

JingjianSlash = sgs.CreateTriggerSkill{  
    name = "JingjianSlash",  
    events = {sgs.CardUsed, sgs.DamageCaused},  
    view_as_skill = JingjianSlashVS,  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        if event == sgs.CardUsed then
            local use = data:toCardUse()  
            if use.card and use.card:getSkillName() == self:objectName() then    
                room:setPlayerFlag(player,"JingjianSlash_used")
            end
        elseif event == sgs.DamageCaused then  
            local damage = data:toDamage()  
            if damage.card and damage.card:getSkillName() == self:objectName() then             
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.DamageCaused then  
            local damage = data:toDamage()  
            local attack_range = player:getAttackRange()  
            damage.damage = attack_range  
            data:setValue(damage)  
            return false  
        end  
        return false  
    end  
}

JingjianSlashMod = sgs.CreateTargetModSkill{  
    name = "#JingjianSlash-mod",  
    pattern = "Slash",  
    distance_limit_func = function(self, player, card)  
        if card:getSkillName() == "JingjianSlash" then  
            return 1000 -- 无距离限制  
        end  
        return 0  
    end,  
    residue_func = function(self, player, card)  
        if card:getSkillName() == "JingjianSlash" then  
            return 1000 -- 无次数限制  
        end  
        return 0  
    end  
}
wangyue:addSkill(JingjianSlash)
wangyue:addSkill(JingjianSlashMod)
-- 翻译表  
sgs.LoadTranslationTable{  
["#wangyue"] = "精剑无双",  
["wangyue"] = "王越",   
["illustrator:wangyue"] = "画师名",  
["JingjianSlash"] = "精剑",  
[":JingjianSlash"] = "每回合限一次，你可以将X张颜色相同的手牌当作无距离、次数限制的杀使用，该杀造成的伤害为X，X为你的攻击范围。",
}  

-- 创建武将：
xiahoushi = sgs.General(extension, "xiahoushi", "shu", 3, false)  -- 吴国，4血，男性  

qiaoshi = sgs.CreateTriggerSkill{  
    name = "qiaoshi",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Finish) then
            return ""
        end
        owner = room:findPlayerBySkillName(self:objectName())
        if player~=owner and player:getHandcardNum()==owner:getHandcardNum() and player:isFriendWith(owner) then  
            return self:objectName(),owner:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(),data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        --循环方法一
        while true do  
            player:drawCards(1)
            card1 = player:getHandcards():last()
            room:showCard(player, card1:getEffectiveId())
            ask_who:drawCards(1)
            card2 = ask_who:getHandcards():last()
            room:showCard(ask_who, card2:getEffectiveId())
            if card1:getSuit()~=card2:getSuit() then
                break
            end
        end  
        return false  
    end,  
}

yanyuCard = sgs.CreateSkillCard{
    name = "yanyuCard",
    target_fixed = true,--是否需要指定目标，默认false，即需要
    will_throw = true,
    on_use = function(self, room, source)
        source:drawCards(1)
        source:gainMark("yanyu_recast_count", 1)
        return false
    end
}

yanyu_recast = sgs.CreateOneCardViewAsSkill{  
    name = "yanyu",  
    filter_pattern = "Slash",  
    view_as = function(self, card)  
        local recast_card = yanyuCard:clone()  
        recast_card:addSubcard(card)  
        recast_card:setSkillName("yanyu")  
        return recast_card  
    end,  
    enabled_at_play = function(self, player)  
        return player:getPhase() == sgs.Player_Play  
    end  
}

yanyu = sgs.CreateTriggerSkill{  
    name = "yanyu",  
    view_as_skill = yanyu_recast,  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
            
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:getMark("yanyu_recast_count") > 0 then  
            return self:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())  
        local count = player:getMark("yanyu_recast_count")
        count = math.min(count,3)
        if target and count > 0 then  
            target:drawCards(count, "yanyu")  
            room:setPlayerMark(player, "yanyu_recast_count", 0)  
        end  
        return false  
    end,  
}

xiahoushi:addSkill(qiaoshi)
xiahoushi:addSkill(yanyu)

sgs.LoadTranslationTable{
    ["xiahoushi"] = "夏侯氏",
    ["qiaoshi"] = "樵拾",
    [":qiaoshi"] = "其他与你势力相同的角色回合结束时，若其手牌数和你相同，你可令其与你各摸一张牌，直到花色不相同",
    ["yanyu"] = "燕语",
    [":yanyu"] = "出牌阶段，你可以将杀重铸；回合结束时，你可以令一名角色摸X张牌，X为以此法重铸杀的次数，至多为3"
}
xusheng_jiang1 = sgs.General(extension, "xusheng_jiang1", "wu", 4) -- 蜀势力，4血，男性（默认）  

pojun = sgs.CreateTriggerSkill{  
    name = "pojun",  
    events = {sgs.Damage},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            -- 检查是否是杀造成的伤害  
            if damage.card and damage.card:isKindOf("Slash") and damage.to and damage.to:isAlive() and not player:isFriendWith(damage.to) then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local target = damage.to  
        if not target or target:isDead() then return false end  
          
        local ai_data = sgs.QVariant()  
        ai_data:setValue(target)  
        if player:askForSkillInvoke(self:objectName(), ai_data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local target = damage.to  
        if not target or target:isDead() then  
            return false  
        end  
          
        -- 令目标摸X张牌（X为其体力值）  
        local draw_num = target:getHp()  
        if draw_num > 0 then  
            target:drawCards(draw_num, self:objectName())  
        end  
          
        -- 然后翻面  
        target:turnOver()  
          
        return false  
    end  
}

xusheng_jiang1:addSkill(pojun)

-- 翻译表  
sgs.LoadTranslationTable{        
    ["xusheng_jiang1"] = "徐盛",  
    ["&xusheng_jiang1"] = "徐盛",  
    ["#xusheng_jiang1"] = "江东的铁壁",  
    ["illustrator:xusheng_jiang1"] = "画师名",  
      
    ["pojun"] = "破军",  
    [":pojun"] = "当你使用【杀】对目标造成伤害后，若目标与你势力不同，你可以令其摸X张牌（X为其体力值），然后翻面。",  
}  
  
yuanyin = sgs.General(extension, "yuanyin", "qun", 3)  -- 吴国，4血，男性  

moshou = sgs.CreateTriggerSkill{  
    name = "moshou",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        local use = data:toCardUse()  
        if use.card and use.card:isBlack() and use.from~=player and use.to:contains(player) then 
            if use.card:getTypeId()==sgs.Card_TypeSkill then return "" end 
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local gui_mark = player:getMark("@gui")  
        if gui_mark == 0 then  
            -- 初始化'规'标记为体力上限  
            gui_mark = 3
            room:setPlayerMark(player, "@gui", gui_mark)  
        end  
          
        if gui_mark > 0 then  
            -- 摸X张牌，X为'规'标记数量  
            player:drawCards(gui_mark, self:objectName())  
              
            -- '规'标记-1  
            gui_mark = gui_mark - 1  
            room:setPlayerMark(player, "@gui", gui_mark)  
              
            -- 当'规'标记等于0时，重置为体力上限  
            if gui_mark == 0 then  
                room:setPlayerMark(player, "@gui", 3)  
            end  
        end  
          
        return false  
    end  
}

yunshu = sgs.CreateTriggerSkill{  
    name = "yunshu",  
    events = {sgs.Death},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        -- 寻找拥有运枢技能的角色  
        local death = data:toDeath()  
        local dead_player = death.who  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:hasFlag("yunshu" .. dead_player:objectName()) then  
            room:setPlayerFlag(player, "yunshu" .. dead_player:objectName()) 
            return self:objectName() .. "->" .. dead_player:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local death = data:toDeath()  
        local dead_player = death.who  
          
        -- 检查死亡角色是否有牌可以转移  
        if dead_player:isAllNude() then  
            return false  
        end  
          
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local death = data:toDeath()  
        local dead_player = death.who  
          
        -- 获取死亡角色的所有牌  
        local all_cards = sgs.IntList()  
        for _, card_id in sgs.qlist(dead_player:handCards()) do  
            all_cards:append(card_id)  
        end  
        for _, card in sgs.qlist(dead_player:getEquips()) do  
            all_cards:append(card:getId())  
        end  
        for _, card in sgs.qlist(dead_player:getJudgingArea()) do  
            all_cards:append(card:getId())  
        end  
          
        if all_cards:length() > 0 then  
            -- 选择一名其他角色  
            local target = room:askForPlayerChosen(ask_who, room:getOtherPlayers(ask_who), self:objectName(), "@yunshu-give")  
            -- 将所有牌交给目标角色  
            local move = sgs.CardsMoveStruct()  
            move.card_ids = all_cards  
            move.to = target  
            move.to_place = sgs.Player_PlaceHand  
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, target:objectName(), self:objectName(), "")  
            room:moveCardsAtomic(move, true)  
            
            local has_max = false
            for _,p in sgs.qlist(room:getOtherPlayers(ask_who)) do
                if p:getMaxHp() >= ask_who:getMaxHp() then
                    has_max = true
                    break
                end
            end
            if has_max then
                -- 加一点体力上限 
                --ask_who:setMaxHp(ask_who:getMaxHp()+1) --这么实现没有问题，只是不显示
                --room:broadcastProperty(ask_who,"maxhp")  --告诉所有人，从而显示
                room:setPlayerProperty(ask_who, "maxhp", sgs.QVariant(ask_who:getMaxHp() + 1))  --等于上面2行
                    
                -- 回复一点体力  
                local recover = sgs.RecoverStruct()  
                recover.who = ask_who  
                recover.recover = 1  
                room:recover(ask_who, recover)
            end
        end  
          
        return false  
    end  
}
yuanyin:addSkill(moshou)  
yuanyin:addSkill(yunshu)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["junba"] = "军八",  
      
    ["yuanyin"] = "袁胤",  
    ["#yuanyin"] = "汝南袁氏",  
    ["illustrator:yuanyin"] = "未知",  
      
    ["moshou"] = "墨守",  
    [":moshou"] = "当你成为其他角色黑色牌的目标后，你可以摸X张牌（X为'规'标记的数量，初始值等于3）。每发动一次本技能，'规'标记-1；当'规'标记等于0时，重置为3。",  
    ["gui"] = '规',  
      
    ["yunshu"] = "运枢",  
    [":yunshu"] = "当任意一名角色死亡时，你可以将该角色死亡时弃置的所有牌交给一名其他角色；然后若你体力上限不为全场唯一最大，你加一点体力上限，并回复一点体力。",  
    ["@yunshu-give"] = "请选择一名角色获得死亡角色的所有牌",  
      
    ["$moshou1"] = "墨守成规，固若金汤。",  
    ["$moshou2"] = "规矩方圆，不可逾越。",  
    ["$yunshu1"] = "运筹帷幄，决胜千里。",  
    ["$yunshu2"] = "枢机在握，天下可定。",  
    ["~yuanyin"] = "袁氏门第，终归尘土...",  
}  


yuejiu = sgs.General(extension, "yuejiu", "wei", 4)  

cuijin = sgs.CreateTriggerSkill{  
    name = "cuijin",  
    events = {sgs.SlashProceed},  
    can_trigger = function(self, event, room, player, data)  
        local effect = data:toSlashEffect()  
        local yuejiu = room:findPlayerBySkillName(self:objectName())  
        if yuejiu and yuejiu:isAlive() and not yuejiu:isNude() then  
            return self:objectName(), yuejiu:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local effect = data:toSlashEffect()  
        local ai_data = sgs.QVariant()  
        ai_data:setValue(effect.from)  
        if ask_who:askForSkillInvoke(self:objectName(), ai_data) then  
            local card = room:askForCard(ask_who, ".", "@cuijin-discard", data, sgs.Card_MethodDiscard)  
            if card then  
                room:broadcastSkillInvoke(self:objectName())  
                return true  
            end  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local effect = data:toSlashEffect()  
        -- 令此杀伤害+1  
        room:setCardFlag(effect.slash, "cuijin_enhanced")     
        return false  
    end  
}  
cuijin_damage_add = sgs.CreateTriggerSkill{  
    name = "#cuijin_damage_add",  
    events = {sgs.DamageCaused},  
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.card and damage.card:hasFlag("cuijin_enhanced") then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local log = sgs.LogMessage()  
        log.type = "#LuoyiBuff"  
        log.from = player  
        log.to:append(damage.to)  
        log.arg = tostring(damage.damage)  
        log.arg2 = tostring(damage.damage + 1)  
        room:sendLog(log)  
          
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}  
-- 催进后续效果（杀未造成伤害时的处理）  
cuijin_damage = sgs.CreateTriggerSkill{  
    name = "#cuijin_damage",  
    events = {sgs.SlashHit, sgs.SlashMissed},  
    can_trigger = function(self, event, room, player, data)  
        local effect = data:toSlashEffect()  
        local yuejiu = room:findPlayerBySkillName("cuijin")  
        if yuejiu and yuejiu:isAlive() and effect.slash:hasFlag("cuijin_enhanced") then
            return self:objectName(), yuejiu:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local effect = data:toSlashEffect()            
        if event == sgs.SlashMissed then  
            -- 杀未造成伤害，摸1张牌并对该角色造成1点伤害  
            ask_who:drawCards(1, "cuijin")  
              
            local damage = sgs.DamageStruct()  
            damage.from = ask_who  
            damage.to = effect.from  
            damage.damage = 1  
            damage.nature = sgs.DamageStruct_Normal  
            damage.reason = "cuijin"  
            room:damage(damage)  
        end  
        return false  
    end  
}  
  
-- 武将定义  
yuejiu:addSkill(cuijin)  
yuejiu:addSkill(cuijin_damage_add)  
yuejiu:addSkill(cuijin_damage)  
extension:insertRelatedSkills("cuijin", "#cuijin_damage_add")
extension:insertRelatedSkills("cuijin", "#cuijin_damage")

sgs.LoadTranslationTable{
["yuejiu"] = "乐就",  
["#yuejiu"] = "魏之良将",  
["cuijin"] = "催进",  
[":cuijin"] = "任意角色使用【杀】时，你可以弃置1张牌，令此【杀】伤害+1，然后若此【杀】未造成伤害，你摸1张牌，并对该角色造成1点伤害。",  
["@cuijin-discard"] = "催进：你可以弃置一张牌令此【杀】伤害+1",  
}

zerong = sgs.General(extension, "zerong", "qun", 3)  -- 吴国，4血，男性  

-- 残肆技能  
cansi = sgs.CreateTriggerSkill{  
    name = "cansi",  
    events = {sgs.EventPhaseStart, sgs.Damage},  
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseStart then  
            -- 准备阶段触发  
            if player:getPhase() == sgs.Player_Start then  
                local others = room:getOtherPlayers(player)  
                if not others:isEmpty() then  
                    return self:objectName()  
                end  
            end  
        elseif event == sgs.Damage then  
            -- 造成伤害时摸牌  
            local damage = data:toDamage()  
            if damage.from and damage.from:objectName() == player:objectName() and   
               damage.card and damage.card:getSkillName()==self:objectName() then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            return player:askForSkillInvoke(self:objectName(),data)  
        else  
            -- 造成伤害时自动触发  
            return true  
        end  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            player:skip(sgs.Player_Draw)
            local others = room:getOtherPlayers(player)  
            local target = room:askForPlayerChosen(player, others, self:objectName(), "@cansi-invoke", true, true)  
            if not target then return false end  
              
            -- 双方各回复1点体力  
            if player:isWounded() then  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(player, recover)  
            end  
              
            if target:isWounded() then  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(target, recover)  
            end  
              
            -- 依次使用杀、决斗、火攻  
            local cards = {"slash", "duel", "fire_attack"}  
            for _, card_name in ipairs(cards) do  
                if player:isAlive() and target:isAlive() then  
                    local card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_NoSuit, 0)  
                    card:setSkillName(self:objectName())  
                    card:deleteLater()
                    --card:setFlags("cansi_card")  -- 标记为残肆技能产生的卡牌  
                      
                    local use = sgs.CardUseStruct()  
                    use.card = card  
                    use.from = player  
                    use.to:append(target)  
                    room:useCard(use, false)  
                end  
            end  
              
        elseif event == sgs.Damage then  
            -- 每当目标受到1次伤害后，摸2张牌  
            player:drawCards(2, self:objectName())  
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
zerong:addSkill(cansi)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["zerong"] = "笮融",  
    ["#zerong"] = "割据徐州",  
    ["cansi"] = "残肆",  
    [":cansi"] = "准备阶段，你可以跳过摸牌阶段，并选择一名其他角色，令你与其各回复一点体力，然后你视为对其依次使用【杀】、【决斗】、【火攻】。每当你以此法造成1次伤害后，你摸2张牌。",  
    ["@cansi-invoke"] = "残肆：选择一名其他角色"  
}

zhaoyun_wei = sgs.General(extension, "zhaoyun_wei", "wei", 3)  -- 吴国，4血，男性  

sushou_skill = sgs.CreateTriggerSkill{  
    name = "sushou",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        -- 检查是否为出牌阶段开始  
        if player:getPhase() ~= sgs.Player_Play then return "" end  
        
        -- 寻找拥有夙守技能的角色  
        local sushou_player = room:findPlayerBySkillName(self:objectName())
        if not (sushou_player and sushou_player:isAlive() and sushou_player:hasSkill(self:objectName())) then return "" end
        -- 检查当前回合角色手牌数是否全场最大  
        local current_handcard = player:getHandcardNum()  
        local is_max = true  
        for _, other in sgs.qlist(room:getAlivePlayers()) do  
            if other:objectName() ~= player:objectName() and other:getHandcardNum() > current_handcard then  --唯一最大，>=
                is_max = false  
                break  
            end  
        end  
        if is_max then
            return self:objectName(), sushou_player:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 失去一点体力  
        room:loseHp(ask_who, 1)  
          
        -- 计算X值（已失去的体力值）  
        local x = ask_who:getMaxHp() - ask_who:getHp()  
          
        if x > 0 then  
            -- 摸X张牌  
            ask_who:drawCards(x, self:objectName())  
        end
          
        return false  
    end  
}  


zhongjie_skill = sgs.CreateTriggerSkill{  
    name = "zhongjie",  
    events = {sgs.Dying, sgs.EventPhaseStart},  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@zhongjie",  
      
    can_trigger = function(self, event, room, player, data) 
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:hasSkill(self:objectName()) then
                room:setPlayerMark(player, "@zhongjie", 1)  
            end
            return ""
        end
        -- 寻找拥有忠节技能的角色  
        local zhongjie_player = room:findPlayerBySkillName(self:objectName()) 
        if not (zhongjie_player and zhongjie_player:isAlive() and zhongjie_player:hasSkill(self:objectName())) then return "" end
        if zhongjie_player:getMark("@zhongjie") <= 0 then return "" end

        local dying = data:toDying()  
        -- 检查是否因失去体力而濒死（damage为nil表示失去体力）  
        if dying.damage == nil then  
            return self:objectName(), zhongjie_player:objectName() 
        end  
        return "" 
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local dying = data:toDying()  
        local _data = sgs.QVariant()  
        _data:setValue(dying.who)  
          
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            room:setPlayerMark(ask_who, "@zhongjie", 0)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local dying = data:toDying()  
        local target = dying.who  
          
        -- 回复1点体力  
        local recover = sgs.RecoverStruct()  
        recover.recover = 1  
        recover.who = ask_who  
        room:recover(target, recover)  
            
        -- 摸一张牌  
        target:drawCards(1, self:objectName())  
          
        return false  
    end  
}  
-- 添加技能到武将  
zhaoyun_wei:addSkill(sushou_skill)
--zhaoyun_wei:addSkill(zhongjie_skill)

-- 翻译表  
sgs.LoadTranslationTable{
["zhaoyun_wei"] = "魏赵云",  
["sushou"] = "夙守",  
[":sushou"] = "任意角色出牌阶段开始时，若其手牌数全场最大，你可以失去一点体力并摸X张牌，X为你已失去的体力值。",  
["@sushou-exchange"] = "夙守：选择要交换的手牌",
["zhongjie"] = "忠节",  
[":zhongjie"] = "每轮限一次。当一名角色因失去体力而进入濒死时，你可以令其回复1点体力并摸一张牌。",  
["@zhongjie"] = "忠节"
}  

xing_zhangchunhua = sgs.General(extension, "xing_zhangchunhua", "wei", 3, false)  -- 吴国，4血，男性  
  
-- 梁燕卡牌类  
LiangyanCard = sgs.CreateSkillCard{  
    name = "LiangyanCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 让玩家选择摸牌或弃牌  
        local choice = room:askForChoice(source, "liangyan", "draw+discard")  
          
        if choice == "draw" then  
            -- 选择摸牌数量（1-2张）  
            local choice_num = room:askForChoice(source, "liangyan_draw", "1+2")
            local draw_num = tonumber(choice_num)  
              
            -- 自己摸牌  
            source:drawCards(draw_num, self:objectName())  
              
            -- 目标弃置等量的牌  
            if target:getCardCount(true) > 0 then  
                local discard_num = math.min(draw_num, target:getCardCount(true))  
                room:askForDiscard(target, "liangyan", discard_num, discard_num, false, true)  
            end  
              
            -- 检查手牌数是否相等，如果相等则目标跳过弃牌阶段  
            if source:getHandcardNum() == target:getHandcardNum() then  
                room:setPlayerMark(source,"@liangyan-skip",1)  
            end  
              
        else  
            -- 选择弃牌数量（1-2张）  
            local choice_num = room:askForChoice(source, "liangyan_discard", "1+2")  
            local discard_num = tonumber(choice_num)  

            -- 自己弃牌  
            if source:getCardCount(true) > 0 then  
                local actual_discard = math.min(discard_num, source:getCardCount(true))  
                room:askForDiscard(source, "liangyan", actual_discard, actual_discard, false, true)  
                  
                -- 目标摸等量的牌  
                target:drawCards(actual_discard, "liangyan")  
                  
                -- 检查手牌数是否相等，如果相等则目标跳过弃牌阶段  
                if source:getHandcardNum() == target:getHandcardNum() then  
                    room:setPlayerMark(target,"@liangyan-skip",1)  
                end  
            end  
        end  
    end  
}  
liangyanVS = sgs.CreateZeroCardViewAsSkill{  
    name = "liangyan",  
    view_as = function(self)  
        local card = LiangyanCard:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#LiangyanCard")  
    end  
}  

liangyan = sgs.CreateTriggerSkill{  
    name = "liangyan",  
    events = {sgs.EventPhaseChanging},  
    --frequency = sgs.Skill_Compulsory,  
    view_as_skill = liangyanVS,
    can_trigger = function(self, event, room, player, data)  
        local change = data:toPhaseChange()  
        if change.to == sgs.Player_Discard and player:getMark("@liangyan-skip")>0 then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        player:skip(sgs.Player_Discard)  
        room:setPlayerMark(player, "@liangyan-skip",0)  
        return false  
    end  
}  
-- 技能2：明慧  
minghui = sgs.CreateTriggerSkill{  
    name = "minghui",  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        local xing_zhangchunhua = room:findPlayerBySkillName(self:objectName())  
        if not xing_zhangchunhua or not xing_zhangchunhua:isAlive() or not xing_zhangchunhua:hasSkill(self:objectName()) then  
            return ""  
        end  
        if xing_zhangchunhua:getMark("minghui_min") ~= 0 and xing_zhangchunhua:getMark("minghui_max") ~= 0 then return "" end
        if player:getPhase() == sgs.Player_Finish then  
            if player == xing_zhangchunhua then
                room:setPlayerMark(player,"minghui_min",0)
                room:setPlayerMark(player,"minghui_max",0)
            end
            local all_players = room:getAlivePlayers()  
            local min_handcard = 999  
            local max_handcard = 0  
              
            -- 计算全场最少和最多手牌数  
            for _, p in sgs.qlist(all_players) do  
                local handcard_num = p:getHandcardNum()  
                if handcard_num < min_handcard then  
                    min_handcard = handcard_num  
                end  
                if handcard_num > max_handcard then  
                    max_handcard = handcard_num  
                end  
            end  
              
            local xing_zhangchunhua_handcard = xing_zhangchunhua:getHandcardNum()  
              
            -- 检查是否为全场最少或最多  
            if (xing_zhangchunhua_handcard == min_handcard and xing_zhangchunhua:getMark("minghui_min") == 0) 
            or (xing_zhangchunhua_handcard == max_handcard and xing_zhangchunhua:getMark("minghui_max") == 0) then  
                return self:objectName(), xing_zhangchunhua:objectName()
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return room:askForSkillInvoke(ask_who, self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local xing_zhangchunhua = ask_who--room:findPlayerBySkillName(self:objectName())  
        local all_players = room:getAlivePlayers()  
        local min_handcard = 999  
        local max_handcard = -1
        local second_max_handcard = -1
          
        -- 重新计算全场最少和最多手牌数  
        for _, p in sgs.qlist(all_players) do  
            local handcard_num = p:getHandcardNum()  
            if handcard_num < min_handcard then  
                min_handcard = handcard_num  
            end  
            if handcard_num >= max_handcard then
                second_max_handcard = max_handcard
                max_handcard = handcard_num
            elseif handcard_num > second_max_handcard then
                second_max_handcard = handcard_num
            end  
        end  
          
        local xing_zhangchunhua_handcard = xing_zhangchunhua:getHandcardNum()  
          
        if xing_zhangchunhua_handcard == min_handcard then  
            -- 手牌数全场最少，选择一名角色视为对其使用杀  
            local target = room:askForPlayerChosen(xing_zhangchunhua, room:getOtherPlayers(xing_zhangchunhua), self:objectName(), "@minghui-slash")  
            if target then  
                room:setPlayerMark(xing_zhangchunhua,"minghui_min",1)
                --room:askForUseSlashTo(xing_zhangchunhua, target, "", false, false, false)  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName(self:objectName())  
                slash:deleteLater()
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = xing_zhangchunhua  
                use.to:append(target)  
                room:useCard(use, false)  
            end  
              
        elseif xing_zhangchunhua_handcard == max_handcard then  
            -- 手牌数全场最多，弃置至不为全场最多  
            local discard_num = xing_zhangchunhua_handcard - second_max_handcard + 1  
            if discard_num > 0 and xing_zhangchunhua:getHandcardNum() > 0 and room:askForDiscard(xing_zhangchunhua, self:objectName(), discard_num, discard_num, true, false) then  
                room:setPlayerMark(xing_zhangchunhua,"minghui_max",1)              
                -- 选择一名角色回复1点体力  
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:isWounded() and xing_zhangchunhua:isFriendWith(p) then
                        targets:append(p)  
                    end
                end  
                local target = room:askForPlayerChosen(xing_zhangchunhua, targets, self:objectName(), "@minghui-recover")  
                if target and target:isWounded() then  
                    local recover = sgs.RecoverStruct()  
                    recover.who = xing_zhangchunhua  
                    recover.recover = 1  
                    room:recover(target, recover)  
                end  
            end
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
xing_zhangchunhua:addSkill(liangyan)  
xing_zhangchunhua:addSkill(minghui)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["xing_zhangchunhua"] = "星张春华",  
    ["#xing_zhangchunhua"] = "冷血皇后",  
    ["liangyan"] = "梁燕",  
    [":liangyan"] = "出牌阶段限一次，你可以选择一名其他角色，你摸至多2张牌然后其弃置等量的牌，或者你弃置至多2张牌然后其摸等量的牌。然后若你与其手牌数相等，摸牌的角色跳过下一个弃牌阶段。",  
    ["LiangyanCard"] = "梁燕",  
    ["liangyan:draw"] = "摸牌",  
    ["liangyan:discard"] = "弃牌",  
    ["liangyan_draw:1"] = "摸1张牌",  
    ["liangyan_draw:2"] = "摸2张牌",  
    ["liangyan_discard:1"] = "弃1张牌",  
    ["liangyan_discard:2"] = "弃2张牌",  
    ["minghui"] = "明慧",  
    [":minghui"] = "每轮每项限一次。任意角色回合结束时，若你的手牌数全场最少，你可以视为对一名其他角色使用一张【杀】；若你的手牌数全场最多，你可以将手牌数弃置至不为全场最多，然后令一名相同势力角色回复1点体力。",  
    ["@minghui-slash"] = "明慧：选择一名角色，对其使用【杀】",  
    ["@minghui-recover"] = "明慧：选择一名角色令其回复1点体力"  
}

zhangjinyun = sgs.General(extension, "zhangjinyun", "shu", 3, false)  -- 吴国，4血，男性  
huizi = sgs.CreateTriggerSkill{  
    name = "huizi",  
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:getPhase() == sgs.Player_Draw then  
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
        -- 让玩家选择要弃置的手牌  
        local handcards = player:getHandcards()  
        if handcards:length() > 0 then  
            local to_discard = room:askForExchange(player, self:objectName(),   
                                                  handcards:length(), 0,   
                                                  "@huizi-discard", "", ".|.|.|hand")  
              
            -- 弃置选择的手牌  
            if to_discard:length() > 0 then  
                local dummy = sgs.DummyCard(to_discard)  
                room:throwCard(dummy, player, player)  
            end  
        end  
        -- 找到场上手牌数最多的角色  
        local max_handcard_num = 0  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            local handcard_num = p:getHandcardNum()  
            if handcard_num > max_handcard_num then  
                max_handcard_num = handcard_num  
            end  
        end            
        -- 摸牌至目标数量  
        local current_handcard_num = player:getHandcardNum()  
        if current_handcard_num < max_handcard_num then  
            local draw_num = max_handcard_num - current_handcard_num  
            room:drawCards(player, draw_num, self:objectName())  
        end  
          
        return false  
    end  
}
zhangjinyun:addSkill(huizi)

-- 翻译表  
sgs.LoadTranslationTable{
    ["zhangjinyun"] = "张瑾云",
    ["huizi"] = "慧资",
    [":huizi"] = "摸牌阶段结束时，你可以弃置任意张手牌，然后将手牌摸至X，X为场上手牌数最多角色的手牌数。"
}  

zhangxingcai = sgs.General(extension, "zhangxingcai", "shu", 3, false)  
qiangwu = sgs.CreateTriggerSkill{  
    name = "qiangwu",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if player:getPhase() == sgs.Player_Play then  
            return self:objectName()
        elseif player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player,"@qiangwu_number", 0)  
        end  
    end,  
    on_cost = function(self, event, room, player, data)  
        if room:askForSkillInvoke(player, self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local judge = sgs.JudgeStruct()  
        judge.pattern = "."  
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = player  
        room:judge(judge)  
          
        local number = judge.card:getNumber()  
        room:setPlayerMark(player,"@qiangwu_number", number)  
        return false  
    end  
}  
  
-- 目标修改技能：修改杀的限制  
 qiangwu_mod = sgs.CreateTargetModSkill{  
    name = "#qiangwu-mod",  
    pattern = "Slash",  
    distance_limit_func = function(self, player, card)  
        if player:getMark("@qiangwu_number") > 0 and card:getNumber() < player:getMark("@qiangwu_number") then  
            return 1000  -- 无距离限制  
        end  
        return 0  
    end,  
    residue_func = function(self, player, card)  
        if player:getMark("@qiangwu_number") > 0 and card:getNumber() > player:getMark("@qiangwu_number") then  
            return 1000  -- 无次数限制  
        end  
        return 0  
    end  
}  

shenzi = sgs.CreateTriggerSkill{  
    name = "shenzi",  
    events = {sgs.CardsMoveOneTime},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            if player:hasFlag("shenzi_used") then return "" end
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
                if player:objectName()==current:objectName() then return "" end
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from and move.from:isAlive() and move.from:objectName()~=player:objectName() then
                            for _,card_id in sgs.qlist(move.card_ids) do
                                local card = sgs.Sanguosha:getCard(card_id)  
                                local card_type = card:getTypeId()
                                if card_type == sgs.Card_TypeBasic then  
                                    return self:objectName()
                                end
                            end 
                        end
					end
				end
			end
		end     
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)            
        return player:askForSkillInvoke(self:objectName(), data) 
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local move_datas = data:toList()
        should_draw = false
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            for _,card_id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(card_id)  
                local card_type = card:getTypeId()
                if card_type == sgs.Card_TypeBasic then  
                    should_draw = true
                    break
                end
            end 
        end
        if should_draw then
            player:drawCards(1, self:objectName())
            room:setPlayerFlag(player,"shenzi_used")
        end
        return false  
    end  
}  

zhangxingcai:addSkill(qiangwu)
zhangxingcai:addSkill(qiangwu_mod)
zhangxingcai:addSkill(shenzi)
sgs.LoadTranslationTable{
    ["zhangxingcai"] = "张星彩",
    ["qiangwu"] = "枪舞",
    [":qiangwu"] = "出牌阶段开始时，你可以进行一次判定，本回合你使用点数小于判定牌的杀无距离限制，使用点数大于判定牌的杀无次数限制",
    ["shenzi"] = "甚资",
    [":shenzi"] = "每回合限一次。你的回合外，其他角色因弃置而失去基本牌时，你摸1张牌"
}
zhouyu_yingfa = sgs.General(extension, "zhouyu_yingfa", "wu", 3)  -- 吴国，4血，男性  
Xiongmou = sgs.CreateTriggerSkill{  
    name = "Xiongmou",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:getPhase() == sgs.Player_Play then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)-- 锁定技强制触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        local yin_mark = player:getMark("@yin")  
        local yang_mark = player:getMark("@yang")  
          
        if yin_mark == 0 and yang_mark == 0 then  
            -- 没有阴阳标记，选择阴或阳  
            local choices = {"yin", "yang"}  
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            if choice == "yin" then  
                room:addPlayerMark(player, "@yin", 1)  
            else  
                room:addPlayerMark(player, "@yang", 1)  
            end  
        else  
            -- 有标记，交替  
            if yin_mark > 0 then  
                room:setPlayerMark(player, "@yin", 0)  
                room:addPlayerMark(player, "@yang", 1)  
            else  
                room:setPlayerMark(player, "@yang", 0)  
                room:addPlayerMark(player, "@yin", 1)  
            end  
        end            
        return false  
    end  
} 

XiongmouYinCard = sgs.CreateSkillCard{  
    name = "XiongmouYinCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local players = room:getAlivePlayers()  --room:getOtherPlayers(source)
        local max_handcards = 0  
        local max_players = {}  
          
        -- 找到手牌数最多的所有角色  
        for _, p in sgs.qlist(players) do  
            local handcard_num = p:getHandcardNum()  
            if handcard_num > max_handcards then  
                max_handcards = handcard_num  
                max_players = {p}  
            elseif handcard_num == max_handcards then  
                table.insert(max_players, p)  
            end  
        end  

        local max_player = nil  
        if #max_players == 1 then  
            max_player = max_players[1]  
        elseif #max_players > 1 then  
            -- 让source选择一个手牌数最多的角色  
            local sgs_max_players = sgs.SPlayerList()  
            for _, p in ipairs(max_players) do  
                sgs_max_players:append(p)  
            end  
            max_player = room:askForPlayerChosen(source, sgs_max_players, "xiongmouYin",   
                "@xiongmouYin-choose::::" .. max_handcards, false, true)  
        end  

        if max_player then  
            local slashes = sgs.IntList()  
            local damage_tricks = sgs.IntList()  
              
            -- 查找所有杀和伤害锦囊  
            for _, card_id in sgs.qlist(max_player:handCards()) do  
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:isKindOf("Slash") then  
                    slashes:append(card_id)
                elseif card:isKindOf("TrickCard") and   
                       (card:isKindOf("Duel") or 
                        card:isKindOf("ArcheryAttack") or   
                        card:isKindOf("SavageAssault") or 
                        card:isKindOf("FireAttack") or 
                        card:isKindOf("BurningCamps") or  
                        card:isKindOf("Drowning")) then  
                    damage_tricks:append(card_id) 
                end  
            end  
              
            if slashes:length() > 0  or damage_tricks:length() > 0 then  
                -- 使用所有杀和伤害锦囊  
                for _, card_id in sgs.qlist(slashes) do  
                    if target and target:isAlive() then
                        local card = sgs.Sanguosha:getCard(card_id)  
                        local use = sgs.CardUseStruct()  
                        use.card = card  
                        use.from = max_player  
                        use.to:append(target)  
                        room:useCard(use)
                    end
                end
                for _, card_id in sgs.qlist(damage_tricks) do
                    if target and target:isAlive() then
                        local card = sgs.Sanguosha:getCard(card_id)  
                        local use = sgs.CardUseStruct()  
                        use.card = card  
                        use.from = max_player  
                        use.to:append(target)  
                        room:useCard(use)
                    end
                end  
            else  
                -- 弃置手牌至与你相同  
                local discard_num = max_player:getHandcardNum() - source:getHandcardNum()  
                if discard_num > 0 then  
                    room:askForDiscard(max_player, "xiongmouYin", discard_num, discard_num, false, false)  
                end  
            end  
        end  
    end  
}  
  
-- 雄谋-阴视为技  
xiongmouYin = sgs.CreateZeroCardViewAsSkill{  
    name = "xiongmouYin",  
    view_as = function(self)  
        local card = XiongmouYinCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#XiongmouYinCard") and player:getMark("@yin")>0
    end  
}  
  
-- 雄谋-阳技能卡  
XiongmouYangCard = sgs.CreateSkillCard{  
    name = "XiongmouYangCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local target_handcards = target:getHandcardNum()  
        local source_handcards = source:getHandcardNum()  
          
        -- 摸牌至手牌数与目标相同  
        if target_handcards > source_handcards then  
            room:drawCards(source, target_handcards - source_handcards, "xiongmouYang")  
        end  
          
        -- 视为对其使用火攻  
        local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)  
        fire_attack:setSkillName("xiongmouYang")  
        fire_attack:deleteLater()
        local use = sgs.CardUseStruct()  
        use.card = fire_attack  
        use.from = source  
        use.to:append(target)  
        room:useCard(use)  
    end  
}  
  
-- 雄谋-阳视为技  
xiongmouYang = sgs.CreateZeroCardViewAsSkill{  
    name = "xiongmouYang",  
    view_as = function(self)  
        local card = XiongmouYangCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#XiongmouYangCard") and player:getMark("@yang")>0
    end  
}  
-- 添加技能到武将  
zhouyu_yingfa:addSkill(Xiongmou)  
zhouyu_yingfa:addSkill(xiongmouYin)  
zhouyu_yingfa:addSkill(xiongmouYang)  
  
-- 翻译文件内容（需要添加到对应的翻译文件中）  
sgs.LoadTranslationTable{  
    ["zhouyu_yingfa"] = "英发周瑜",  
    ["#zhouyu_yingfa"] = "英发都督",
    ["Xiongmou"] = "雄谋",
    [":Xiongmou"] = "你的首个出牌阶段开始时，你选择获得‘阴’或‘阳’标记；你的非首个出牌阶段开始时，‘阴’‘阳’标记交替。你有‘阴’标记时，可以发动雄谋-阴；你有‘阳’标记时，可以发动雄谋-阳",
    ["xiongmouYin"] = "雄谋-阴",  
    [":xiongmouYin"] = "出牌阶段限一次，你选择一名角色，令场上手牌数最大的角色对该角色使用手牌中所有杀和伤害锦囊，若其没有杀和伤害锦囊，其将手牌数弃置与你相同。",  
    ["@xiongmouYin-choose"] = "雄谋-阴：请选择一名手牌数最多的角色（%arg张）",
    ["xiongmouYang"] = "雄谋-阳",   
    [":xiongmouYang"] = "出牌阶段限一次，你选择一名角色，你摸牌至手牌数与它相同，然后视为对其使用一张火攻。"  
} 

zhuhao = sgs.General(extension, "zhuhao", "wu", 4)  -- 吴国，4血，男性  

cheji_card = sgs.CreateSkillCard{  
    name = "cheji_card",  
    target_fixed = false,  
    will_throw = true,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local discard_num = self:subcardsLength()  
          
        -- 自己先摸牌  
        if discard_num > 0 then  
            source:drawCards(discard_num, "cheji")  
        end  
         -- 检查弃置的牌类型并触发效果  
        local has_slash = false  
        local has_jink = false    
        local has_peach = false           
        -- 目标弃置手牌并摸牌  
        --local discarded_cards = {}  
        if target:getHandcardNum() > 0 then  
            local to_discard = math.min(discard_num, target:getHandcardNum()) 
            --[[ 
            local cards_ids = room:askForExchange(target, self:objectName(), to_discard, to_discard, self:objectName(), "", ".|.|.|hand")  
            for _,card_id in sgs.qlist(card_ids) do
                card = sgs.Sanguosha:getCard(card_id)
                if card:isKindOf("Slash") then  
                    has_slash = true  
                elseif card:isKindOf("Jink") then  
                    has_jink = true  
                elseif card:isKindOf("Peach") then  
                    has_peach = true  
                end  
                room:throwCard(card_id,target,target)
            end           
            ]]   
            for i = 1,to_discard do  
                card_id = room:askForCardChosen(target, target, "h",self:objectName())
                card = sgs.Sanguosha:getCard(card_id)
                if card:isKindOf("Slash") then  
                    has_slash = true  
                elseif card:isKindOf("Jink") then  
                    has_jink = true  
                elseif card:isKindOf("Peach") then  
                    has_peach = true  
                end  
                room:throwCard(card_id,target,target)
            end  
            target:drawCards(to_discard, "cheji")  
        end  
          
        -- 处理杀的效果 - 火焰伤害  
        if has_slash then  
            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = target  
            damage.damage = 1  
            damage.nature = sgs.DamageStruct_Fire  
            damage.reason = "cheji"  
            room:damage(damage)  
        end  
          
        -- 处理闪的效果 - 视为使用杀  
        if has_jink then                
            local slash_target = room:askForPlayerChosen(source, room:getOtherPlayers(target), "cheji", "@cheji-slash:" .. target:objectName(), true, true)  
            if slash_target then  
                local slash = sgs.Sanguosha:cloneCard("slash")  
                slash:deleteLater()
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = target  
                use.to:append(slash_target)  
                room:useCard(use, false)  
            end  
        end  
          
        -- 处理桃的效果 - 双方各摸2张牌  
        if has_peach then  
            source:drawCards(2, "cheji")  
            target:drawCards(2, "cheji")  
        end  
    end  
}  
  
-- 撤击视为技  
cheji = sgs.CreateViewAsSkill{  
    name = "cheji",  
    n = 999,  
    view_as = function(self, cards)  
        if #cards == 0 then return nil end  
        local card = cheji_card:clone()  
        for _, c in ipairs(cards) do  
            card:addSubcard(c)  
        end  
        return card  
    end,  
      
    view_filter = function(self, selected, to_select)  
        return true--not to_select:isEquipped()  --自己重铸的牌不限制手牌
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#cheji_card")  
    end  
}  

zhuhao:addSkill(cheji)

sgs.LoadTranslationTable{  
    ["junba"] = "军八",  
      
    ["zhuhao"] = "朱镐",  
    ["#zhuhao"] = "吴王",  
    ["illustrator:zhuhao"] = "未知",  
      
    ["cheji"] = "撤击",  
    [":cheji"] = "出牌阶段限一次，你可以弃置任意数量的牌，并摸等量的牌，然后选择一名其他角色，令其弃置等量的手牌，并摸等量的牌。若其弃置的手牌中有【杀】，你对其造成1点火焰伤害；有【闪】，其对你指定的一名角色视为使用一张【杀】；有【桃】，你与其各摸2张牌。",  
    ["cheji_card"] = "撤击",  
    ["@cheji-discard"] = "%src 发动了'撤击'，你需弃置 %arg 张手牌",  
    ["@cheji-slash"] = "请为 %src 选择'撤击'【杀】的目标",  
    ["$cheji1"] = "进退有度，方显将才。",  
    ["$cheji2"] = "撤而复击，敌不及防。",  
    ["~zhuhao"] = "江东基业，后继有人...",  
}  

return {extension}