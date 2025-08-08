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
        local use = sgs.CardUseStruct()  
        use.card = snatch  
        use.from = source  
        use.to:append(target)  
        room:useCard(use, false)  


        if target:canSlash(source, nil, false) then  
            use_slash = room:askForUseSlashTo(target, source, "@jiechuYin-slash:" .. source:objectName())  
        end  
        --[[
        -- 目标视为对你使用一张杀  
        local slash = sgs.Sanguosha:cloneCard("slash")  
        slash:setSkillName("jiechuYin")  
        if target:canSlash(source, slash, false) then  
            local use2 = sgs.CardUseStruct()  
            use2.card = slash  
            use2.from = target  
            use2.to:append(source)  
            room:useCard(use2, false)  
        end  
        ]]
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
    events = {sgs.DamageInflicted},  
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
          
        -- 设置本轮已使用标记  
        room:setPlayerMark(player, mark_name, 1)  
          
        -- 防止伤害  
        damage.damage = 0  
        data = sgs.QVariant()  
        data:setValue(damage)  
          
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
          
        return true -- 防止伤害  
    end  
}  

guibei_skill = sgs.CreateTriggerSkill{  
    name = "guibei",  
    events = {sgs.GameStart},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        owner = room:findPlayerBySkillName(self:objectName())
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
caocao_yuanshao:addSkill(jiechuYang_skill)  
caocao_yuanshao:addSkill(daojue_skill)
caocao_yuanshao:addSkill(guibei_skill)

-- 翻译表  
sgs.LoadTranslationTable{
["caocao_yuanshao"] = "曹操&袁绍",  
["jiechuYin"] = "劫出-阴",  
[":jiechuYin"] = "出牌阶段限一次。你可以选择一名角色，视为你对其使用顺手牵羊，然后其可以对你使用一张杀。",  
["jiechuYang"] = "劫出-阳",   
[":jiechuYang"] = "当你成为杀的目标时，你可以弃置一张手牌改变该杀的花色和属性。",  
["daojue"] = "道抉",  
[":daojue"] = "本轮游戏中，当你首次受到一种花色的牌造成的伤害时，你防止此伤害，然后你选择：（1）获得伤害牌（2）视为对所有其他角色使用一张杀。",  
["@jiechuYang-discard"] = "劫出-阳：弃置一张手牌改变杀的花色和属性",  
["obtain"] = "获得伤害牌",  
["slash_all"] = "对所有其他角色使用杀",
["guibei"] = "贵卑",  
[":guibei"] = "游戏开始时，你可以摸4张牌，然后和末置位交换座次。",  
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
                if total_points==13 then 
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
    [":chengxiang"] = "当你受到伤害时，你可以查看牌堆顶的4张牌，并以任意顺序排列，然后依次展示，你获得点数和不大于13的所有牌，其余牌置入弃牌堆。若你获得牌的点数和等于13，你叠置。",
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

caoren_junba = sgs.General(extension, "caoren_junba", "wei", 3)  -- 吴国，4血，男性  

sujun = sgs.CreateTriggerSkill{  
    name = "sujun",  
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,    
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
          
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
                    
        local new_card  
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
        return self.enabled_at_response(self, player, "nullification")  
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
caoren_junba:addSkill(sujun)  
caoren_junba:addSkill(pofeng)
-- 翻译表  
sgs.LoadTranslationTable{
    ["caoren_junba"] = "曹仁",
    ["sujun"] = "肃军",
    [":sujun"] = "你使用或打出牌时，若你手牌中基本牌和非基本牌数量相等，你摸1张牌。",
    ["pofeng"] = "破锋",
    [":pofeng"] = "每回合每种花色限一次。你可以使用1张牌当杀或无懈可击"
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
[":zhengnan"] = "每名角色限一次，任意角色进入濒死时，你可以回复一点体力，并从武圣、当先、制蛮中选择一个技能获得，然后摸1张牌；若所有技能都已获得，则摸三张牌。",  
["xiefang"] = "撷芳",  
[":xiefang"] = "你到其他角色的距离-X，X为全场女性角色数。",  
["wusheng"] = "武圣",  
["dangxian"] = "当先",   
["zhiman"] = "制蛮"
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
        choice=room:askForChoice(source, self:objectName(), "slash+peach+analeptic")
        card = sgs.Sanguosha:cloneCard(choice)  
        card:setSkillName("jiusi")
        if choice=="slash" then
            local targets = {}  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:objectName() ~= source:objectName() and source:inMyAttackRange(p) then  
                    table.insert(targets, p)  
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
        return not player:hasFlag("jiusi_used") and (pattern == "slash" or pattern == "jink" or pattern == "peach" or pattern == "analeptic")  
    end  
}

jiusi = sgs.CreateTriggerSkill{  
    name = "jiusi",  
    view_as_skill = jiusiVS,  
    events = {sgs.CardUsed, sgs.CardResponded},  
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
        --[[
        local dead_player = death.who
        if not (dead_player and dead_player:hasSkill(self:objectName())) then  
            return ""  
        end
        ]]
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

qi_sunjian = sgs.General(extension, "qi_sunjian", "wu", 4)  

pingtaoCard = sgs.CreateSkillCard{  
    name = "pingtaoCard",  
    target_fixed = false,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        if not target then return end  
          
        local choices = {}  
        if not target:isNude() then  
            table.insert(choices, "pingtao_give")  
        end  
        table.insert(choices, "pingtao_slash")  
          
        local choice = room:askForChoice(target, "pingtao", table.concat(choices, "+"))  
          
        if choice == "pingtao_give" then  
            local card = room:askForCard(target, ".", "@pingtao-give:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)  
            if card then  
                room:obtainCard(source, card, false)  
                room:setPlayerFlag(source, "pingtao_extra_slash")
            else --选了给牌，但是后悔了，没给牌
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)  
                slash:setSkillName("pingtao")  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = source  
                use.to:append(target)
                room:useCard(use)
            end  
        else  
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)  
            slash:setSkillName("pingtao")  
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = source  
            use.to:append(target)  
            room:useCard(use)  
        end  
    end  
}  
  
-- 平讨视为技能  
pingtao = sgs.CreateZeroCardViewAsSkill{  
    name = "pingtao",  
    view_as = function(self)  
        local card = pingtaoCard:clone()  
        card:setShowSkill("pingtao")  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#pingtaoCard")  
    end  
}

pingtaoMod = sgs.CreateTargetModSkill{  
    name = "pingtao-mod",  
    pattern = "Slash",  
    residue_func = function(self, player, card)  
        if player:hasFlag("pingtao_extra_slash") then  
            return 1  
        else  
            return 0  
        end  
    end  
}

juelie = sgs.CreateTriggerSkill{  
    name = "juelie",  
    events = {sgs.CardUsed, sgs.DamageCaused},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            if use.card and use.card:isKindOf("Slash") then  
                return self:objectName()  
            end  
        elseif event == sgs.DamageCaused then  
            local damage = data:toDamage()  
            if damage.card and damage.card:isKindOf("Slash") then  
                -- 检查是否手牌数或体力值为全场最少  
                local min_hp = 999  
                local min_hand = 999  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    min_hp = math.min(min_hp, p:getHp())  
                    min_hand = math.min(min_hand, p:getHandcardNum())  
                end  
                  
                if player:getHp() == min_hp or player:getHandcardNum() == min_hand then  
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.CardUsed then  
            if room:askForSkillInvoke(player, self:objectName(), data) then  
                room:broadcastSkillInvoke(self:objectName())  
                return true  
            end  
            return false  
        elseif event == sgs.DamageCaused then  
            return player:askForSkillInvoke(self:objectName(),data) -- 锁定技，自动触发  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            local target = use.to:first()  
              
            local cards_to_discard = {}  
            while true do  
                local card = room:askForCard(player, ".|.|.|hand,equipped", "@juelie-discard", sgs.QVariant(), sgs.Card_MethodNone)  
                if card then  
                    table.insert(cards_to_discard, card)  
                    room:throwCard(card, player, player)  
                else  
                    break  
                end  
            end  
            local discard_num = #cards_to_discard  

            if discard_num > 0 and target and target:isAlive() then    
                local actual_discard = math.min(discard_num, target:getCardCount(true))  
                if actual_discard > 0 then
                    for i=1, actual_discard do
                        local chosen_card = room:askForCardChosen(player, target, "he", self:objectName())  
                        room:throwCard(chosen_card, target, player)
                    end  
                end  
            end  
        elseif event == sgs.DamageCaused then  
            local damage = data:toDamage()  
            damage.damage = damage.damage + 1  
            data:setValue(damage)  
        end  
        return false  
    end  
}
qi_sunjian:addSkill(pingtao)
qi_sunjian:addSkill(pingtaoMod)
qi_sunjian:addSkill(juelie)

sgs.LoadTranslationTable{
    ["qi_sunjian"] = "起孙坚",
    ["pingtao"] = "平讨",  
    [":pingtao"] = "出牌阶段限一次，你可以令一名角色选择一项：1.交给你一张牌，并令你此回合出杀次数+1；2.令你视为对其使用一张杀。",  
    ["@pingtao-choose"] = "平讨：选择一名角色",  
    ["@pingtao-give"] = "平讨：交给%src一张牌，并让其获得标记和额外出杀次数",  
    ["pingtao_give"] = "交给其一张牌",  
    ["pingtao_slash"] = "令其对你使用杀",  
      
    ["juelie"] = "绝烈",  
    [":juelie"] = "你使用杀指定目标时，你可以弃置任意张牌，然后弃置目标等量的牌；你的杀造成伤害时，若你的手牌数或体力值为全场最少，该伤害+1。",  
    ["@juelie-discard"] = "绝烈：你可以弃置任意张牌",  
    ["#juelie_damage"] = "%from 的'%arg'被触发，伤害+1"  
}


simaao = sgs.General(extension, "simaao", "wei", 3)  

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
        if simafu and simafu:isAlive() then  
            return self:objectName(), simafu:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
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

        local skill_owner = room:findPlayerBySkillName(self:objectName())  
        if skill_owner and skill_owner:isAlive() and not skill_owner:hasFlag("chenjie_" .. dead_player:objectName()) then  
            return self:objectName(), skill_owner:objectName()  
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
        room:setPlayerFlag(ask_who, "chenjie_" .. dead_player:objectName())  

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
    [":panxiang"] = "当任意一名角色受到伤害时，你可以选择：1.令此伤害-1，伤害来源摸2张牌；2.令此伤害+1，伤害目标摸3张牌。不能连续选择相同项",  
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

-- 创建武将：
xiahoushi = sgs.General(extension, "xiahoushi", "shu", 3, false)  -- 吴国，4血，男性  

qiaoshi = sgs.CreateTriggerSkill{  
    name = "qiaoshi",  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Finish) then
            return ""
        end
        owner = room:findPlayerBySkillName(self:objectName())
        if player~=owner and player:getHandcardNum()==owner:getHandcardNum() then  
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
    [":qiaoshi"] = "其他角色回合结束时，若其手牌数和你相同，你可令其与你各摸一张牌，直到花色不相同",
    ["yanyu"] = "燕语",
    [":yanyu"] = "出牌阶段，你可以将杀重铸；回合结束时，你可以令一名角色摸X张牌，X为以此法重铸杀的次数"
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
            gui_mark = player:getMaxHp()  
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
                room:setPlayerMark(player, "@gui", player:getMaxHp())  
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
        local yuanyin = room:findPlayerBySkillName(self:objectName())  
        if yuanyin and yuanyin:isAlive() then  
            return self:objectName(), yuanyin:objectName()
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
                
            -- 加一点体力上限 
            ask_who:setMaxHp(ask_who:getMaxHp()+1) 
            --room:setPlayerProperty(ask_who, "maxhp", ask_who:getMaxHp() + 1)  
                
            -- 回复一点体力  
            local recover = sgs.RecoverStruct()  
            recover.who = ask_who  
            recover.recover = 1  
            room:recover(ask_who, recover)  
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
    [":moshou"] = "当你成为其他角色黑色牌的目标后，你可以摸X张牌（X为'规'标记的数量，初始值等于体力上限）。每发动一次本技能，'规'标记-1；当'规'标记等于0时，重置为体力上限。",  
    ["gui"] = '规',  
      
    ["yunshu"] = "运枢",  
    [":yunshu"] = "当任意一名角色死亡时，你可以将该角色死亡时弃置的所有牌交给一名其他角色，然后你加一点体力上限，并回复一点体力。",  
    ["@yunshu-give"] = "请选择一名角色获得死亡角色的所有牌",  
      
    ["$moshou1"] = "墨守成规，固若金汤。",  
    ["$moshou2"] = "规矩方圆，不可逾越。",  
    ["$yunshu1"] = "运筹帷幄，决胜千里。",  
    ["$yunshu2"] = "枢机在握，天下可定。",  
    ["~yuanyin"] = "袁氏门第，终归尘土...",  
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
                room:setPlayerMark(player, "@zhongjie", 0)  
            end
            return ""
        end
        -- 寻找拥有忠节技能的角色  
        local zhongjie_player = room:findPlayerBySkillName(self:objectName()) 
        if not (zhongjie_player and zhongjie_player:isAlive() and zhongjie_player:hasSkill(self:objectName())) then return "" end
        if zhongjie_player:getMark("@zhongjie") > 0 then return "" end

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
            room:setPlayerMark(ask_who, "@zhongjie", 1)  
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

zhangchunhua_junba = sgs.General(extension, "zhangchunhua_junba", "wei", 3, false)  -- 吴国，4血，男性  
  
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
        local zhangchunhua_junba = room:findPlayerBySkillName(self:objectName())  
        if not zhangchunhua_junba or not zhangchunhua_junba:isAlive() or not zhangchunhua_junba:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if player:getPhase() == sgs.Player_Finish then  
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
              
            local zhangchunhua_junba_handcard = zhangchunhua_junba:getHandcardNum()  
              
            -- 检查是否为全场最少或最多  
            if zhangchunhua_junba_handcard == min_handcard or zhangchunhua_junba_handcard == max_handcard then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local zhangchunhua_junba = room:findPlayerBySkillName(self:objectName())  
        return room:askForSkillInvoke(zhangchunhua_junba, self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local zhangchunhua_junba = room:findPlayerBySkillName(self:objectName())  
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
          
        local zhangchunhua_junba_handcard = zhangchunhua_junba:getHandcardNum()  
          
        if zhangchunhua_junba_handcard == min_handcard then  
            -- 手牌数全场最少，选择一名角色视为对其使用杀  
            local target = room:askForPlayerChosen(zhangchunhua_junba, room:getOtherPlayers(zhangchunhua_junba), self:objectName(), "@minghui-slash")  
            if target then  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName(self:objectName())  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = zhangchunhua_junba  
                use.to:append(target)  
                room:useCard(use, false)  
            end  
              
        elseif zhangchunhua_junba_handcard == max_handcard then  
            -- 手牌数全场最多，弃置至不为全场最多  
            local discard_num = zhangchunhua_junba_handcard - second_max_handcard + 1  
            if discard_num > 0 and zhangchunhua_junba:getHandcardNum() > 0 then  
                room:askForDiscard(zhangchunhua_junba, self:objectName(), discard_num, discard_num, false, false)  
            end  
              
            -- 选择一名角色回复1点体力  
            local target = room:askForPlayerChosen(zhangchunhua_junba, all_players, self:objectName(), "@minghui-recover")  
            if target and target:isWounded() then  
                local recover = sgs.RecoverStruct()  
                recover.who = zhangchunhua_junba  
                recover.recover = 1  
                room:recover(target, recover)  
            end  
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
zhangchunhua_junba:addSkill(liangyan)  
zhangchunhua_junba:addSkill(minghui)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["zhangchunhua_junba"] = "张春华",  
    ["#zhangchunhua_junba"] = "冷血皇后",  
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
    [":minghui"] = "任意角色回合结束时，若你的手牌数全场最少，你可以选择一名角色并视为对其使用一张【杀】；若你的手牌数全场最多，你可以将手牌数弃置至不为全场最多，然后令一名角色回复1点体力。",  
    ["@minghui-slash"] = "明慧：选择一名角色，视为对其使用【杀】",  
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

zhouyu_yingfa = sgs.General(extension, "zhouyu_yingfa", "wu", 3)  -- 吴国，4血，男性  

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
                       (card:isKindOf("Duel") or card:isKindOf("ArcheryAttack") or   
                        card:isKindOf("SavageAssault") or card:isKindOf("FireAttack")) then  
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
        return not player:hasUsed("#XiongmouYinCard")  
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
        return not player:hasUsed("#XiongmouYangCard")  
    end  
}  
-- 添加技能到武将  
zhouyu_yingfa:addSkill(xiongmouYin)  
zhouyu_yingfa:addSkill(xiongmouYang)  
  
-- 翻译文件内容（需要添加到对应的翻译文件中）  
sgs.LoadTranslationTable{  
    ["zhouyu_yingfa"] = "英发周瑜",  
    ["#zhouyu_yingfa"] = "英发都督",  
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
            for i = 1,to_discard do  
                --card_id = room:askForCard(target, ".|.|.|hand")
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
            local slash_targets = {}  
            for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
                if target:canSlash(p, sgs.Sanguosha:cloneCard("slash"), false) then  
                    table.insert(slash_targets, p)  
                end  
            end  
              
            if #slash_targets > 0 then  
                local slash_target = room:askForPlayerChosen(source, slash_targets, "cheji", "@cheji-slash:" .. target:objectName())  
                if slash_target then  
                    local slash = sgs.Sanguosha:cloneCard("slash")  
                    local use = sgs.CardUseStruct()  
                    use.card = slash  
                    use.from = target  
                    use.to:append(slash_target)  
                    room:useCard(use, false)  
                end  
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