
-- 创建扩展包  
extension = sgs.Package("junba",sgs.Package_GeneralPack)  


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

caofang = sgs.General(extension, "caofang", "wei", 4)  -- 吴国，4血，男性  

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
    [":moshou"] = "当你成为黑色牌的目标后，你可以摸X张牌（X为'规'标记的数量，初始值等于体力上限）。每发动一次本技能，'规'标记-1；当'规'标记等于0时，重置为体力上限。",  
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

zhugao = sgs.General(extension, "zhugao", "wu", 4)  -- 吴国，4血，男性  

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

zhugao:addSkill(cheji)

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