extension = sgs.Package("jiangshanrugu", sgs.Package_GeneralPack)  
local skills = sgs.SkillList()

qi_liubei = sgs.General(extension, "qi_liubei", "wei", 4) -- 蜀势力，4血，男性（默认）  

jishan = sgs.CreateTriggerSkill{  
    name = "jishan",  
    events = {sgs.DamageInflicted, sgs.Damage},  
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        if event == sgs.DamageInflicted then  
            -- 当一名角色受到伤害时  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) and p:isAlive() and p:getHp() > 0 then  
                    if not p:hasFlag("jishan_prevent_used") then  
                        return self:objectName(), p:objectName()
                    end  
                end  
            end  
        elseif event == sgs.Damage then  
            -- 当你造成伤害时  
            if damage.from and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() then  
                if not damage.from:hasFlag("jishan_recover_used") then  
                    return self:objectName(), damage.from:objectName()
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
          
        if event == sgs.DamageInflicted then                
            if ask_who and ask_who:askForSkillInvoke("@jishan-prevent", data) then  
                room:setPlayerFlag(ask_who, "jishan_prevent_used")  
                return true  
            end  
        elseif event == sgs.Damage then  
            if damage.from:askForSkillInvoke("@jishan-recover", data) then  
                room:notifySkillInvoked(damage.from, self:objectName())  
                room:broadcastSkillInvoke(self:objectName())  
                room:setPlayerFlag(damage.from, "jishan_recover_used")  
                return true  
            end  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
          
        if event == sgs.DamageInflicted then  
            if ask_who then  
                -- 失去1点体力，防止此伤害  
                room:loseHp(ask_who, 1)  
                -- 你与其各摸1张牌  
                ask_who:drawCards(1, self:objectName())  
                damage.to:drawCards(1, self:objectName())  
                return true -- 防止伤害  
            end  
        elseif event == sgs.Damage then  
            -- 令一名体力值最小的角色恢复1点体力  
            local min_hp = 999  
            local targets = sgs.SPlayerList()
              
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:getHp() < min_hp then  
                    min_hp = p:getHp()  
                    targets = sgs.SPlayerList()
                    targets:append(p)
                elseif p:getHp() == min_hp then  
                    targets:append(p)
                end  
            end  
              
            local target = room:askForPlayerChosen(damage.from, targets, self:objectName(), "@jishan-recover", false, true)  
            if target then
                local recover = sgs.RecoverStruct()  
                recover.who = damage.from  
                recover.recover = 1  
                room:recover(target, recover)
            end
        end  
          
        return false  
    end  
}  
qi_liubei:addSkill(jishan)
-- 翻译表  
sgs.LoadTranslationTable{        
["#qi_liubei"] = "仁德之君",  
["qi_liubei"] = "起刘备",  
["illustrator:qi_liubei"] = "绘聚艺堂",
["jishan"] = "积善",  
[":jishan"] = "每回合每项限一次。当一名角色受到伤害时，你可以失去1点体力，防止此伤害，然后你与其各摸1张牌；当你造成伤害时，你可以令一名体力值最小的角色恢复1点体力。",  
["zhenqiao"] = "振鞘",  
[":zhenqiao"] = "锁定技。你的攻击范围+1；当你使用杀指定目标后，若你的装备区没有武器牌，此杀额外结算1次。",
["@jishan-prevent"] = "是否发动积善，失去1点体力，防止此伤害，然后你与目标各摸1张牌",
["@jishan-recover"] = "是否发动积善，令一名体力值最小的角色恢复1点体力",
}  
  
qi_nanhualaoxian = sgs.General(extension, "qi_nanhualaoxian", "qun", 4) -- 蜀势力，4血，男性（默认）  

xundao = sgs.CreateTriggerSkill{  
    name = "xundao",  
    events = {sgs.AskForRetrial},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and judge.who == player then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        local targets = {}  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if not p:isNude() then  
                table.insert(targets, p:objectName())  
            end  
        end  
        if #targets == 0 then return false end  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not p:isNude() then  
                targets:append(p) 
            end  
        end  
        local selected = room:askForPlayersChosen(player, targets, self:objectName(), 0, 2, "@xundao-discard", true)  
        local card_ids = sgs.IntList()             
        for _, target in sgs.qlist(selected) do  
            if target and not target:isNude() then  
                --为了获得card_id，不能用askForDiscard，用askForCardChosen
                local card_id = room:askForCardChosen(target, target, "he", self:objectName())  
                room:throwCard(card_id, target, target)  
                card_ids:append(card_id)  
            end  
        end  
        local judge = data:toJudge()  
        if card_ids:length() > 0 then  
            room:fillAG(card_ids, player)  
            local card_id = room:askForAG(player, card_ids, true, "@xundao-choose")  
            room:clearAG(player) 

            local card = sgs.Sanguosha:getCard(card_id)  
            room:retrial(card, player, judge, self:objectName(), true)  
        end  
        return false  
    end  
}  
  
-- 宣化技能实现  
xuanhua = sgs.CreateTriggerSkill{  
    name = "xuanhua",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and   
            (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local judge = sgs.JudgeStruct()  
        judge.pattern = "."  
        judge.good = false  
        judge.reason = self:objectName()  
        judge.who = player  
        room:judge(judge)  
          
        local card = judge.card  
        local is_spade_2_to_9 = (card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9)  
          
        if player:getPhase() == sgs.Player_Start then  
            -- 准备阶段  
            if is_spade_2_to_9 then  
                -- 受到3点雷电伤害  
                local damage = sgs.DamageStruct()  
                damage.from = nil  
                damage.to = player  
                damage.damage = 3  
                damage.nature = sgs.DamageStruct_Thunder  
                room:damage(damage)  
            else  
                -- 可以令一名角色恢复1点体力  
                local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "@xuanhua-recover", true)  
                if target then  
                    local recover = sgs.RecoverStruct()  
                    recover.who = player  
                    recover.recover = 1  
                    room:recover(target, recover)  
                end  
            end  
        else  
            -- 结束阶段  
            if is_spade_2_to_9 then  
                -- 可以对一名角色造成1点雷电伤害  
                local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "@xuanhua-damage", true)  
                if target then  
                    local damage = sgs.DamageStruct()  
                    damage.from = player  
                    damage.to = target  
                    damage.damage = 1  
                    damage.nature = sgs.DamageStruct_Thunder  
                    room:damage(damage)  
                end  
            else  
                -- 受到3点雷电伤害  
                local damage = sgs.DamageStruct()  
                damage.from = nil  
                damage.to = player  
                damage.damage = 3  
                damage.nature = sgs.DamageStruct_Thunder  
                room:damage(damage)  
            end  
        end  
          
        return false  
    end  
}  
qi_nanhualaoxian:addSkill(xundao)
qi_nanhualaoxian:addSkill(xuanhua)
-- 翻译表  
sgs.LoadTranslationTable{        
["#qi_nanhualaoxian"] = "仙人指路",  
["qi_nanhualaoxian"] = "起南华老仙",  
["illustrator:qi_nanhualaoxian"] = "君桓文化",  
["xundao"] = "寻道",  
[":xundao"] = "当你的判定牌生效前，你可以令至多2名角色各弃置一张牌，你选择其中一张替换判定牌。",  
["xuanhua"] = "宣化",  
[":xuanhua"] = "准备阶段，你可以进行一次判定，若判定牌为黑桃2-9，你受到3点雷电伤害，否则你可以令一名角色恢复1点体力；结束阶段，你可以进行一次判定，若判定牌为黑桃2-9，你可以对一名角色造成1点雷电伤害，否则你受到3点雷电伤害。",  
  
["@xundao-discard"] = "寻道：选择至多2名角色各弃置一张牌",  
["@xundao-choose"] = "寻道：选择一张牌代替判定牌",  
["@xuanhua-recover"] = "宣化：选择一名角色恢复1点体力",  
["@xuanhua-damage"] = "宣化：选择一名角色造成1点雷电伤害",
}  
qi_sunjian = sgs.General(extension, "qi_sunjian", "qun", 3)  

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
            
            local max_num = math.min(target:getCardCount(true), player:getCardCount(true))
            local cards = room:askForExchange(player, self:objectName(), max_num, 0)   
            for _,card in sgs.qlist(cards) do
                room:throwCard(card, player, player)  
            end
            local discard_num = cards:length()  
            --[[
            local cards_to_discard = {}  
            for i=1,max_num do  
                local card = room:askForCard(player, ".|.|.|hand,equipped", "@juelie-discard", sgs.QVariant(), sgs.Card_MethodNone)  
                if card then  
                    table.insert(cards_to_discard, card)  
                    room:throwCard(card, player, player)  
                else  
                    break  
                end  
            end  
            local discard_num = #cards_to_discard  
            ]]
            if discard_num > 0 and target and target:isAlive() then    
                local actual_discard = math.min(discard_num, target:getCardCount(true))  
                if actual_discard > 0 then
                    --to_discard = sgs.IntList()
                    for i=1, actual_discard do
                        local chosen_card = room:askForCardChosen(player, target, "he", self:objectName())  
                        room:throwCard(chosen_card, target, player)
                        --to_discard:append(chosen_card:getId())
                    end  
                    --[[
                    if to_discard:length() > 0 then  
                        local dummy = sgs.DummyCard(to_discard)  
                        room:throwCard(dummy, target, player)  
                    end 
                    ]] 
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
    ["jiangshanrugu"] = "江山如故",
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
cheng_chendeng = sgs.General(extension, "cheng_chendeng", "qun", 3) -- 蜀势力，4血，男性（默认）  

LunshiCard = sgs.CreateSkillCard{  
    name = "LunshiCard",  
    target_fixed = false,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
      
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        local target = effect.to  
          
        if target and target:isAlive() then  
            -- 计算X：目标攻击范围内的角色数，至多为5  
            local x = 0  
            for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
                if target:inMyAttackRange(p) then  
                    x = x + 1  
                end  
            end  
            x = math.min(x, 5)  
              
            -- 计算Y：攻击范围包含目标的角色数  
            local y = 0  
            for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
                if p:inMyAttackRange(target) then  
                    y = y + 1  
                end  
            end  
              
            -- 先摸牌  
            if x > 0 then  
                target:drawCards(x, "lunshi")  
            end  
              
            -- 再弃牌  
            if y > 0 and target:isAlive() then  
                room:askForDiscard(target, "lunshi", y, y, false, true)  
            end  
        end  
    end  
}

lunshi = sgs.CreateZeroCardViewAsSkill{  
    name = "lunshi",  
      
    view_as = function(self)  
        local card = LunshiCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#LunshiCard")  
    end  
}
guitu = sgs.CreateTriggerSkill{  
    name = "guitu",  
    events = {sgs.EventPhaseStart},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getPhase() == sgs.Player_Start then  
                -- 检查是否有至少两名角色装备武器  
                local weapon_players = {}  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:getWeapon() then  
                        table.insert(weapon_players, p)  
                    end  
                end  
                if #weapon_players >= 2 then  
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
        local weapon_players = sgs.SPlayerList()   
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getWeapon() then  
                weapon_players:append(p)  
            end  
        end  
          
        if weapon_players:length() >= 2 then  
            targets = room:askForPlayersChosen(player, weapon_players, self:objectName(), 2, 2, "guitu-invoke", true)  
        end   
          
        if targets:length() == 2 then  
            local source = targets:at(0)  
            local target = targets:at(1)  

            -- 交换装备区  
            if source:isAlive() and target:isAlive() then  
                local first_range_before = source:getAttackRange()  
                local second_range_before = target:getAttackRange()  

                local source_equips = source:getWeapon()  
                local target_equips = target:getWeapon()  
                
                -- 移除双方装备区的牌  
                local source_cards = sgs.IntList()  
                local target_cards = sgs.IntList()  
                
                for _, card in sgs.qlist(source_equips) do  
                    source_cards:append(card:getEffectiveId())  
                end  
                
                for _, card in sgs.qlist(target_equips) do  
                    target_cards:append(card:getEffectiveId())  
                end  
                local move1 = sgs.CardsMoveStruct()
                move1.card_ids = source_cards
                move1.from = source
                move1.to = target
                move1.to_place = sgs.Player_PlaceEquip
                move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,   
                                            source:objectName(), target:objectName(), "chengliu", "") 

                local move2 = sgs.CardsMoveStruct()
                move2.card_ids = target_cards
                move2.from = target
                move2.to = source
                move2.to_place = sgs.Player_PlaceEquip
                move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,   
                                            target:objectName(), source:objectName(), "chengliu", "")  
                
                local moves = sgs.CardsMoveList()
                moves:append(move1)
                moves:append(move2)
                
                room:moveCardsAtomic(moves, true)

                local decreased_players = {}  
                if source:getAttackRange() < first_range_before then  
                    table.insert(decreased_players, source)  
                end  
                if target:getAttackRange() < second_range_before then  
                    table.insert(decreased_players, target)  
                end  
                  
                -- 让攻击范围减少的角色选择效果  
                for _, p in ipairs(decreased_players) do  
                    if p:isAlive() then  
                        local choices = {"guitu_recover"}  
                        -- 检查是否有攻击范围内的角色可以造成伤害  
                        local can_damage = false  
                        for _, target in sgs.qlist(room:getAlivePlayers()) do  
                            if p:inMyAttackRange(target) and target:objectName() ~= p:objectName() then  
                                can_damage = true  
                                break  
                            end  
                        end  
                        if can_damage then  
                            table.insert(choices, "guitu_damage")  
                        end  
                          
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))  
                        if choice == "guitu_recover" then  
                            room:recover(p, sgs.RecoverStruct(p))  
                        elseif choice == "guitu_damage" then  
                            local damage_targets = sgs.SPlayerList()   
                            for _, target in sgs.qlist(room:getAlivePlayers()) do  
                                if p:inMyAttackRange(target) and target:objectName() ~= p:objectName() then  
                                    damage_targets:append(target)  
                                end  
                            end  
                            if damage_targets:length() > 0 then  
                                local damage_target = room:askForPlayerChosen(p, damage_targets, self:objectName(), "guitu-damage")  
                                if damage_target then  
                                    room:damage(sgs.DamageStruct(self:objectName(), p, damage_target))  
                                end  
                            end  
                        end  
                    end  
                end
            end
        end  
        return false  
    end  
}

cheng_chendeng:addSkill(lunshi)
cheng_chendeng:addSkill(guitu)
-- 翻译表  
sgs.LoadTranslationTable{        
    ["cheng_chendeng"] = "承陈登",  
    ["#cheng_chendeng"] = "承",  
    ["lunshi"] = "论势",  
    [":lunshi"] = "出牌阶段限一次，你可以令一名角色摸X张牌，然后弃置Y张牌，X为其攻击范围内的角色数，且至多为5，Y为攻击范围包含其的角色数。",  
    ["lunshi-invoke"] = "论势：选择一名角色",  
      
    ["guitu"] = "诡图",   
    [":guitu"] = "准备阶段，你可以令两名武器栏有牌的角色交换武器栏的牌，然后攻击范围因此减少的角色选择：1.恢复1点体力；2.对攻击范围内1名角色造成1点伤害。",  
    ["guitu-invoke"] = "诡图：选择2名要交换武器的角色",  
    ["guitu-damage"] = "诡图：选择要造成伤害的目标",  
    ["guitu_recover"] = "恢复1点体力",  
    ["guitu_damage"] = "造成1点伤害"  
}  
zhuan_guojia = sgs.General(extension, "zhuan_guojia", "wei", 3) -- 蜀势力，4血，男性（默认）  

qingzi = sgs.CreateTriggerSkill{  
    name = "qingzi",  
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getPhase() == sgs.Player_Start then
                if not player:hasFlag("qingzi_used") then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do  
                        if p:getMark("qingzi_shensu") > 0 then  
                            room:detachSkillFromPlayer(p, "shensu",  true, false, true)  
                            room:setPlayerMark(p, "qingzi_shensu", 0)  
                        end  
                    end  
                end
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        room:setPlayerFlag(player, "qingzi_used")
        local weapon_players = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do --room:getAlivePlayers()
            if not p:getEquips():isEmpty() then  
                weapon_players:append(p) 
            end  
        end  
        targets = room:askForPlayersChosen(player, weapon_players, self:objectName(), 0, weapon_players:length(), "qingzi-choose", true)            
        for _, target in sgs.qlist(targets) do  
            if target and target:isAlive() and not target:getEquips():isEmpty() then  
                local equip_id = room:askForCardChosen(player, target, "e", self:objectName())  
                room:throwCard(equip_id, target, player)  
                room:acquireSkill(target,"shensu", true, true)
                room:setPlayerMark(target, "qingzi_shensu", 1)  
            end  
        end            
        return false  
    end  
}

dingce = sgs.CreateTriggerSkill{  
    name = "dingce",  
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.from and damage.from:isAlive() and not damage.from:isKongcheng()   
               and not player:isKongcheng() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:notifySkillInvoked(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local source = damage.from  
          
        -- 弃置伤害来源一张手牌  
        local source_card_id = room:askForCardChosen(player, source, "h", self:objectName())  
        local source_card = sgs.Sanguosha:getCard(source_card_id)  
        room:throwCard(source_card_id, source, player)  
          
        -- 弃置自己一张手牌  
        local self_card_id = room:askForCardChosen(player, player, "h", self:objectName())  
        local self_card = sgs.Sanguosha:getCard(self_card_id)  
        room:throwCard(self_card_id, player, player)  

        -- 判断颜色是否相同  
        if source_card:getColor() == self_card:getColor() then  
            -- 选择使用无中生有或远交近攻  
            --[[
            local card = sgs.Sanguosha:cloneCard("ex")  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())  
              
            local use = sgs.CardUseStruct()  
            use.card = card  
            use.from = player  
            room:useCard(use)  
            ]]
            player:drawCards(2,self:objectName())
        end  
          
        return false  
    end  
}

zhuan_guojia:addSkill(qingzi)
zhuan_guojia:addSkill(dingce)
-- 翻译表  
sgs.LoadTranslationTable{        
["#zhuan_guojia"] = "转世的先知",  
["zhuan_guojia"] = "转郭嘉",  
["illustrator:zhuan_guojia"] = "绘聚艺堂",
["qingzi"] = "轻辎",  
[":qingzi"] = "准备阶段，你可以弃置任意其他角色装备区内各一张牌，然后令这些角色获得【神速】直到你下回合开始。",  
["dingce"] = "定策",   
[":dingce"] = "你受到伤害后，你可以依次弃置伤害来源和你1张手牌，若这两张牌颜色相同，你摸2张牌。",  
}  
zhuan_zhangfei = sgs.General(extension, "zhuan_zhangfei", "shu", 4) -- 蜀势力，4血，男性（默认）  

baohe = sgs.CreateTriggerSkill{  
    name = "baohe",  
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:getPhase() == sgs.Player_Play then  
            local zhuanzhangfei = nil  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) and p:isAlive() then  
                    if p:getCardCount(true) >= 2 then  
                        zhuanzhangfei = p  
                        break  
                    end  
                end  
            end  
            if zhuanzhangfei then  
                return self:objectName(), zhuanzhangfei:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)      
        return ask_who:askForSkillInvoke(self:objectName(),data) and room:askForDiscard(ask_who, self:objectName(), 2, 2, true, true, "@baohe-discard")  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 找到攻击范围内包含当前角色的所有角色  
        local targets = {}  
        for _, target in sgs.qlist(room:getAlivePlayers()) do  
            if target:inMyAttackRange(player) and target ~= ask_who then  
                table.insert(targets, target)  
            end  
        end  
            
        if #targets > 0 then  
            -- 创建虚拟杀  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:setSkillName(self:objectName())  
            slash:setShowSkill(self:objectName())  
                
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = ask_who  
                
            for _, target in ipairs(targets) do  
                use.to:append(target)  
            end  
                
            room:useCard(use)  
        end            
        return false  
    end  
}

zhuan_zhangfei:addSkill(baohe)
-- 翻译表  
sgs.LoadTranslationTable{        
["#zhuan_zhangfei"] = "万人敌的转世",  
["zhuan_zhangfei"] = "转张飞",  
["illustrator:zhuan_zhangfei"] = "绘聚艺堂",
["baohe"] = "暴喝",  
[":baohe"] = "一名角色出牌阶段结束时，你可以弃置2张牌，视为对攻击范围内包含当前角色的所有其他角色使用一张杀。",  
["@baohe-discard"] = "你可以弃置2张牌发动暴喝",  
["@baohe-card"] = "你可以发动暴喝，弃置2张牌视为使用杀"
}  
  
he_gaoxiang = sgs.General(extension, "he_gaoxiang", "shu", 4) -- 蜀势力，4血，男性（默认）  

ChiyingCard = sgs.CreateSkillCard{  
    name = "ChiyingCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local basic_cards = {}  
          
        -- 找到目标攻击范围内的所有其他角色  
        local in_range_players = {}  
        for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
            if target:inMyAttackRange(p) then  
                table.insert(in_range_players, p)  
            end  
        end  
          
        -- 让这些角色各弃置1张牌  
        for _, p in ipairs(in_range_players) do  
            if not p:isNude() then  
                local card_id = room:askForCardChosen(p, p, "he", self:objectName())  
                room:throwCard(card_id, p, p)  
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:isKindOf("BasicCard") then  
                    table.insert(basic_cards, card_id)  
                end  
            end  
        end  
          
        -- 判断是否获得基本牌  
        if #basic_cards <= target:getHp() then  
            for _, card_id in ipairs(basic_cards) do  
                room:obtainCard(target, card_id, false)  
            end  
        end  
    end  
}  
  
chiying = sgs.CreateZeroCardViewAsSkill{  
    name = "chiying",  
    n = 0,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#ChiyingCard")  
    end,  
    view_as = function(self)  
        local card = ChiyingCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end  
}  
he_gaoxiang:addSkill(chiying)
-- 翻译表  
sgs.LoadTranslationTable{        
["#he_gaoxiang"] = "飞将军",  
["he_gaoxiang"] = "合高翔",  
["illustrator:he_gaoxiang"] = "绘聚艺堂",
["chiying"] = "驰应",  
[":chiying"] = "出牌阶段限一次，你可以选择一名角色，令其攻击范围内所有其他角色各弃置1张牌，若弃置的基本牌数小于等于其体力值，其获得这些基本牌。",  
["@chiying-discard"] = "驰应：你需要弃置1张牌（%src的攻击范围内）"
}  

he_zhaoyun = sgs.General(extension, "he_zhaoyun", "shu", 3) -- 蜀势力，4血，男性（默认）  

longlin = sgs.CreateTriggerSkill{  
    name = "longlin",  
    events = {sgs.TargetConfirmed},  
    can_trigger = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        if use.card and use.card:isKindOf("Slash") then  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasSkill(self:objectName()) and p:isAlive() and p:objectName() ~= use.from:objectName() then  
                    if not p:isNude() then  
                        return self:objectName(), p:objectName()
                    end  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data) and room:askForDiscard(ask_who, self:objectName(), 1, 1, true, true, "@longlin-discard")  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        -- 令此杀无效  
        for _, target in sgs.qlist(use.to) do  
            use.to:removeOne(target)  
        end  
        data:setValue(use)  
        local choice = room:askForChoice(use.from, self:objectName(),"yes+no")
        if choice == "yes" then
            -- 其可以视为对你使用1张决斗  
            local duel = sgs.Sanguosha:cloneCard("duel")  
            duel:setSkillName(self:objectName())  
            duel:setShowSkill(self:objectName())  
                
            if not use.from:isCardLimited(duel, sgs.Card_MethodUse) and not use.from:isProhibited(ask_who, duel) then  
                local duel_use = sgs.CardUseStruct()  
                duel_use.card = duel  
                duel_use.from = use.from  
                duel_use.to:append(ask_who)  
                room:useCard(duel_use)  
            end 
        end 
        return false  
    end  
}

zhengdan = sgs.CreateOneCardViewAsSkill{  
    name = "zhengdan",  
    n = 1,  
    view_filter = function(self, to_select)  
        if to_select:hasFlag("using") then return false end  
        return not to_select:isKindOf("BasicCard") and not to_select:isEquipped()  
    end,  
    view_as = function(self, card)  
        local slash = sgs.Sanguosha:cloneCard("Slash", card:getSuit(), card:getNumber())  
        slash:addSubcard(card:getId())
        slash:setSkillName(self:objectName())  
        slash:setShowSkill(self:objectName())  
        return slash  
    end,  
    enabled_at_play = function(self, player)  
        return sgs.Slash_IsAvailable(player)  
    end,  
    enabled_at_response = function(self, player, pattern)  
        return pattern == "slash"  
    end  
}

he_zhaoyun:addSkill(longlin)
he_zhaoyun:addSkill(zhengdan)
-- 翻译表  
sgs.LoadTranslationTable{        
["#he_zhaoyun"] = "常胜将军",  
["he_zhaoyun"] = "合赵云",  
["illustrator:he_zhaoyun"] = "绘聚艺堂",
["longlin"] = "龙临",  
[":longlin"] = "当其他角色使用杀指定目标后，你可以弃置一张牌令此杀无效，然后其可以视为对你使用1张决斗。",  
["zhengdan"] = "镇胆",  
[":zhengdan"] = "你可以将手牌中的非基本牌当杀使用或打出。",  
["@longlin-discard"] = "你可以弃置一张牌发动龙临"
}  
xing_simaliang = sgs.General(extension, "xing_simaliang", "jin", 3) -- 蜀势力，4血，男性（默认）  

sheju = sgs.CreateTriggerSkill{  
    name = "sheju",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.CardUsed}, 
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        local use = data:toCardUse()  
        if use.card and use.card:isKindOf("Slash") then  
            if use.to:length()~=1 or use.from:isKongcheng() or use.to:first():isKongcheng() then return "" end 
            if use.from:objectName() == owner:objectName() or use.to:contains(owner) then
                return self:objectName(), owner:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who) 
        local use = data:toCardUse()
        if use.from:isKongcheng() or use.to:first():isKongcheng() then return false end 
        return ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(),data) -- 锁定技，必须发动  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        local other_player = nil 
          
        if ask_who == use.from then  
            other_player = use.to:first()  
        else  
            other_player = use.from  
        end  
          
        if not other_player or not other_player:isAlive() then return false end  
        if ask_who:isKongcheng() or other_player:isKongcheng() then return false end  
          
        -- 双方各展示一张牌  
        local player_card_id = room:askForCardChosen(ask_who, ask_who, "h", "sheju", false, sgs.Card_MethodNone)  
        local other_card_id = room:askForCardChosen(other_player, other_player, "h", "sheju", false, sgs.Card_MethodNone)  
          
        if player_card_id == -1 or other_card_id == -1 then return false end  
          
        -- 同时展示两张牌  
        room:showCard(ask_who, player_card_id)  
        room:showCard(other_player, other_card_id)  

        local player_card = sgs.Sanguosha:getCard(player_card_id)  
        local other_card = sgs.Sanguosha:getCard(other_card_id)  
          
        -- 判断颜色  
        local player_black = player_card:isBlack()  
        local other_black = other_card:isBlack()  
          
        if player_black and other_black then  
            -- 都是黑色，双方各失去一点体力  
            room:loseHp(ask_who, 1)  
            room:loseHp(other_player, 1)  
        elseif not player_black or not other_black then  
            -- 有红色，展示黑色的角色摸2张牌  
            if player_black and not other_black then  
                room:drawCards(ask_who, 2, "sheju")  
            elseif not player_black and other_black then  
                room:drawCards(other_player, 2, "sheju")  
            end  
        end  
          
        return false  
    end  
}

zuwang = sgs.CreateTriggerSkill{  
    name = "zuwang",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local phase = player:getPhase()  
            if phase == sgs.Player_Start or phase == sgs.Player_Finish then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，必须发动  
    end,  
    on_effect = function(self, event, room, player, data)  
        local current_hand = player:getHandcardNum()  
        local max_hp = player:getMaxHp()  
          
        if current_hand < max_hp then  
            local draw_count = max_hp - current_hand  
            room:drawCards(player, draw_count, "zuwang")  
        end  
          
        return false  
    end  
}

xing_simaliang:addSkill(sheju)  
xing_simaliang:addSkill(zuwang) 

sgs.LoadTranslationTable{
    ["#xing_simaliang"] = "宗室重臣",  
    ["xing_simaliang"] = "兴司马亮",  
    ["illustrator:xing_simaliang"] = "未知",  
    ["sheju"] = "摄惧",  
    [":sheju"] = "锁定技，当你使用杀指定唯一目标，或成为杀的唯一目标时，你可以与对方同时展示1张手牌：若都是黑色，双方各失去一点体力；若有红色，展示黑色的角色摸2张牌。",  
    ["zuwang"] = "族望",  
    [":zuwang"] = "锁定技，你的准备阶段和结束阶段，你将手牌摸至体力上限。"  
}

shuai_liubiao = sgs.General(extension, "shuai_liubiao", "qun", 4) -- 蜀势力，4血，男性（默认）  

YanshaCard = sgs.CreateSkillCard{  
    name = "YanshaCard",  
    target_fixed = false,  
    will_throw = true,  
    skill_name = "yansha",  
    filter = function(self, targets, to_select)  
        return true -- 可以选择任意角色  
    end,  
    on_use = function(self, room, source, targets)              
        --local top_cards = room:getNCards(#targets)
        --room:askForGuanxing(source, top_cards, sgs.Room_GuanxingUpOnly)-- GuanxingUpOnly, GuanxingBothSides, GuanxingDownOnly
        -- 记录被选择的角色  
        local selected_players = sgs.SPlayerList()  
        for _, target in ipairs(targets) do
            --target:drawCards(1,self:objectName())
            selected_players:append(target)  
        end  
        -- 对选择的角色使用五谷丰登  
        local amazing_grace = sgs.Sanguosha:cloneCard("amazing_grace")  
        amazing_grace:setSkillName("yansha")            
        local ag_use = sgs.CardUseStruct(amazing_grace, source, selected_players)  --使用结构体，目标是qlist类型
        room:useCard(ag_use)  
        amazing_grace:deleteLater()  

        -- 所有未被选择的角色可以弃置装备视为使用杀  
        local all_players = room:getAllPlayers()  
        for _, player in sgs.qlist(all_players) do  
            if not selected_players:contains(player) then --and not player:getEquips():isEmpty() then  
                if room:askForSkillInvoke(player, "yansha_slash", sgs.QVariant()) and room:askForCard(player,"EquipCard","@yansha-discard",sgs.QVariant(),sgs.Card_MethodDiscard) then  
                    --local equip_id = room:askForCardChosen(player, player, "e", "yansha")  
                    --room:throwCard(equip_id, player, player)  
                    -- 选择一个被选择的角色作为杀的目标  
                    local slash_target = room:askForPlayerChosen(player, selected_players, "yansha")  
                    local slash = sgs.Sanguosha:cloneCard("slash")  
                    slash:setSkillName("yansha")                        
                    local slash_use = sgs.CardUseStruct(slash, player, slash_target)  
                    room:useCard(slash_use)  
                    slash:deleteLater()  
                end  
            end  
        end  
    end  
}  
  
-- 宴杀视为技  
yansha = sgs.CreateZeroCardViewAsSkill{  
    name = "yansha",  
    view_as = function(self)  
        card = YanshaCard:clone()  
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#YanshaCard")  
    end  
}  

qingping = sgs.CreateTriggerSkill{  
    name = "qingping",  
    frequency = sgs.Skill_Frequent,  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then  
            local in_range_players = {}  
            local all_players = room:getAllPlayers()  
              
            for _, p in sgs.qlist(all_players) do  
                if p:objectName() ~= player:objectName() and player:inMyAttackRange(p) then  
                    table.insert(in_range_players, p)  
                end  
            end  
              
            if #in_range_players > 0 then  
                local can_trigger = true  
                for _, p in ipairs(in_range_players) do  
                    local hand_count = p:getHandcardNum()  
                    if hand_count <= 0 or hand_count > player:getHandcardNum() then  
                        can_trigger = false  
                        break  
                    end  
                end  
                  
                if can_trigger then  
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local in_range_count = 0  
        local all_players = room:getAllPlayers()  
          
        for _, p in sgs.qlist(all_players) do  
            if p:objectName() ~= player:objectName() and player:inMyAttackRange(p) then  
                in_range_count = in_range_count + 1  
            end  
        end  
          
        if in_range_count > 0 then  
            room:drawCards(player, in_range_count, "qingping")  
        end  
    end  
}

shuai_liubiao:addSkill(yansha)  
shuai_liubiao:addSkill(qingping) 

sgs.LoadTranslationTable{
    ["#shuai_liubiao"] = "衰世牧守",  
    ["shuai_liubiao"] = "衰刘表",  
    ["illustrator:shuai_liubiao"] = "未知",  
    ["yansha"] = "宴杀",  
    [":yansha"] = "出牌阶段限一次，你可以选择任意名角色，对这些角色使用一张【五谷丰登】，所有未被选择的角色可以弃置一张装备，视为对其中1个被选择的角色使用杀。",  
    ["qingping"] = "清平",  
    [":qingping"] = "结束阶段开始时，若你攻击范围内的角色手牌数均大于0且小于等于你，你可以摸X张牌，X为你攻击范围内的角色数。",  
    ["yansha_slash"] = "是否弃置一张装备牌，视为使用【杀】",  
    ["@yansha-target"] = "宴杀：选择【杀】的目标"  
}

shuai_zhangjiao = sgs.General(extension, "shuai_zhangjiao", "qun", 3) -- 蜀势力，4血，男性（默认）  

xiangru = sgs.CreateTriggerSkill{  
    name = "xiangru",  
    frequency = sgs.Skill_Frequent,  
    events = {sgs.DamageInflicted},
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        local damage = data:toDamage()  
        if damage.to and damage.to:isAlive() and damage.to:getHp() <= damage.damage then  
            -- 检查是否有其他非伤害来源角色可以发动技能  
            local all_players = room:getAllPlayers()  
            for _, p in sgs.qlist(all_players) do  
                if p:isAlive() and p ~= damage.from and p ~= damage.to then  
                    if p:getCardCount(true) >= 2 then  
                        return self:objectName(), owner:objectName()
                    end  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        --[[
        local damage = data:toDamage()  
        local all_players = room:getAllPlayers()  
        local available_players = sgs.SPlayerList()  
          
        for _, p in sgs.qlist(all_players) do  
            if p:isAlive() and p ~= damage.from and p ~= damage.to and p:getCardCount(true) >= 2 then  
                available_players:append(p)  
            end  
        end  
          
        if available_players:isEmpty() then return false end  
        ]]
        return ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(),data) 
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()

        local all_players = room:getAllPlayers()  
        local available_players = sgs.SPlayerList()  
          
        for _, p in sgs.qlist(all_players) do  
            if p:isAlive() and p ~= damage.from and p ~= damage.to and p:getCardCount(true) >= 2 then  
                available_players:append(p)  
            end  
        end  
        for _, p in sgs.qlist(available_players) do
            cards = room:askForExchange(p, self:objectName(), 2,0, "@xiangru-give", "", ".|.|.|hand,equipped")  
            if cards:length()==2 then  
                local move = sgs.CardsMoveStruct()  
                move.card_ids = sgs.IntList()  
                for _, id in sgs.qlist(cards) do  
                    move.card_ids:append(id)  
                end  
                move.from = p  
                move.to = damage.from  
                move.to_place = sgs.Player_PlaceHand  
                move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), damage.from:objectName(), "xiangru", "")  
                room:moveCardsAtomic(move, true)  
                
                -- 阻止伤害  
                return true  
            end
        end  
        return false  
    end  
}

wudao = sgs.CreateTriggerSkill{  
    name = "wudao",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.Dying},  
    can_trigger = function(self, event, room, player, data)  
		local dying = data:toDying()
		if skillTriggerable(player, self:objectName()) and player:isKongcheng() then
			if dying.who then
				return self:objectName() .. "->" .. dying.who:objectName() --self对dying.who发动技能
			end
		end

        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(),data) -- 锁定技，必须发动  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 增加1点体力上限  
        ask_who:setMaxHp(ask_who:getMaxHp() + 1)  
        room:broadcastProperty(ask_who, "maxhp")    
        --room:setPlayerProperty(ask_who, "maxhp", ask_who:getMaxHp() + 1)         
        -- 回复1点体力  
        local recover = sgs.RecoverStruct()  
        recover.who = ask_who  
        recover.recover = 1  
        room:recover(ask_who, recover)  
            
        -- 获得惊雷技能。
        if not ask_who:hasSkill("jinglei") then
            room:acquireSkill(ask_who, "jinglei", true, true)  
        end
    end  
}

jinglei = sgs.CreateTriggerSkill{  
    name = "jinglei",  
    frequency = sgs.Skill_NotFrequent,  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then  
            -- 检查是否有手牌数不为最少的角色  
            local min_hand = 999  
            local all_players = room:getAllPlayers()  
            for _, p in sgs.qlist(all_players) do  
                if p:isAlive() and p:getHandcardNum() < min_hand then  
                    min_hand = p:getHandcardNum()  
                end  
            end  
              
            for _, p in sgs.qlist(all_players) do  
                if p:isAlive() and p:getHandcardNum() > min_hand then  
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 第一步：选择手牌数不为最少的角色  
        local min_hand = 999  
        local all_players = room:getAllPlayers()  
        for _, p in sgs.qlist(all_players) do  
            if p:isAlive() and p:getHandcardNum() < min_hand then  
                min_hand = p:getHandcardNum()  
            end  
        end  
          
        local available_targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(all_players) do  
            if p:isAlive() and p:getHandcardNum() > min_hand then  
                available_targets:append(p)  
            end  
        end  
          
        if available_targets:isEmpty() then return false end  
          
        local first_target = room:askForPlayerChosen(player, available_targets, "jinglei", "@jinglei-first")  
        if not first_target then return false end  
          
        -- 第二步：选择手牌数之和小于第一个目标的角色  
        local damage_targets = sgs.SPlayerList()  
        local first_hand_count = first_target:getHandcardNum()  
          
        -- 递归选择目标  
        local function selectTargets(current_sum, selected_players)  
            local candidates = sgs.SPlayerList()  
            for _, p in sgs.qlist(all_players) do  
                if p:isAlive() and p ~= first_target and not selected_players:contains(p) then  
                    if current_sum + p:getHandcardNum() < first_hand_count then  
                        candidates:append(p)  
                    end  
                end  
            end  
              
            if not candidates:isEmpty() then  
                local target = room:askForPlayerChosen(player, candidates, "jinglei", "@jinglei-damage", true)  
                if target then  
                    selected_players:append(target)  
                    selectTargets(current_sum + target:getHandcardNum(), selected_players)  
                end  
            end  
        end  
          
        selectTargets(0, damage_targets)  
          
        -- 第三步：对选择的角色造成雷属性伤害  
        for _, target in sgs.qlist(damage_targets) do  
            local damage = sgs.DamageStruct()  
            damage.from = target  
            damage.to = first_target  
            damage.damage = 1  
            damage.nature = sgs.DamageStruct_Thunder  
            damage.reason = "jinglei"  
            room:damage(damage)  
        end  
          
        return false  
    end  
}

shuai_zhangjiao:addSkill(xiangru)  
shuai_zhangjiao:addSkill(wudao) 
--shuai_zhangjiao:addSkill(jinglei) 
if not sgs.Sanguosha:getSkill("jinglei") then
    skills:append(jinglei)
end
sgs.LoadTranslationTable{
    ["#shuai_zhangjiao"] = "太平道祖",  
    ["shuai_zhangjiao"] = "衰张角",  
    ["illustrator:shuai_zhangjiao"] = "未知",  
    ["xiangru"] = "相濡",  
    [":xiangru"] = "任意角色受到致命伤时，其他非伤害来源角色可以将2张牌交给伤害来源，阻止此伤害。",  
    ["wudao"] = "悟道",  
    [":wudao"] = "锁定技，当一名角色进入濒死状态时，若你没有手牌，你增加1点体力上限并恢复1点体力，获得【惊雷】。",  
    ["jinglei"] = "惊雷",  
    [":jinglei"] = "准备阶段，你可以选择1名手牌数不为最少的角色，然后选择任意名手牌数之和小于其的角色。令他们各对其造成1点雷属性伤害。",  
    ["@jinglei-first"] = "惊雷：选择1名手牌数不为最少的角色",  
    ["@jinglei-damage"] = "惊雷：选择手牌数之和小于目标的角色（可取消）",
    ["@xiangru-ask"] = "相濡：是否让一名角色交给伤害来源2张牌来阻止对 %src 的致命伤？",  
    ["@xiangru-give"] = "相濡：请交给 %src 2张牌来阻止致命伤"  
}

sgs.Sanguosha:addSkills(skills)
return {extension}
