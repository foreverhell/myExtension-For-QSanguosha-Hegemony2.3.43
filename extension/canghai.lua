-- 创建扩展包  
extension = sgs.Package("canghai",sgs.Package_GeneralPack)  

-- 创建董允武将  
dongyun = sgs.General(extension, "dongyun", "shu", 4)

-- 秉正技能实现  
Bingzheng = sgs.CreateTriggerSkill{  
    name = "bingzheng",  
    events = {sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if player:hasSkill(self:objectName()) and player:isAlive() and player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
        return ""  
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
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@bingzheng-target", true, true)  
        if target then  
            player:setTag("BingzhengTarget", sgs.QVariant(target:objectName()))  
            return true  
        end  
          
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local target_name = player:getTag("BingzhengTarget"):toString()  
        player:removeTag("BingzhengTarget")  
        local target = room:findPlayer(target_name)  
          
        if not target or target:isDead() then return false end  
          
        -- 选择摸牌或弃牌  
        local choice = room:askForChoice(player, self:objectName(), "draw+discard", data)  
          
        if choice == "draw" then  
            room:drawCards(target, 1, self:objectName())  
        else  
            if not target:isKongcheng() then  
                room:askForDiscard(target, self:objectName(), 1, 1, false, true)  
            end  
        end  
          
        -- 检查手牌数是否等于体力值  
        if target:getHandcardNum() == target:getHp() then  
            room:drawCards(player, 1, self:objectName())  
        end  
          
        return false  
    end  
}


-- 设宴技能实现  
Sheyan = sgs.CreateTriggerSkill{  
    name = "sheyan",  
    events = {sgs.TargetConfirmed},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        local use = data:toCardUse()  
        if use.to:contains(player) and use.card and use.card:isNDTrick() and   
           not player:hasFlag("SheyanUsed_" .. room:getCurrent():objectName()) then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:setPlayerFlag(player, "SheyanUsed_" .. room:getCurrent():objectName())  
            return true
        end
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
          
        local use = data:toCardUse()  
        local card = use.card  

        local choices = {}
        table.insert(choices,"add")
        if use.to:length()>1 then  
            table.insert(choices, "reduce")  
        end  
        local choice = room:askForChoice(player, "sheyan", table.concat(choices, "+"))  
        if choice=="add" then                
            -- 选择一名角色成为新目标  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if not use.to:contains(p) then  
                    targets:append(p)  
                end  
            end  
              
            if not targets:isEmpty() then  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@sheyan-add", true, true)  
                if target then  
                    use.to:append(target)  
                    room:sortByActionOrder(use.to)  
                      
                    local msg = sgs.LogMessage()  
                    msg.type = "#SheyanAdd"  
                    msg.from = player  
                    msg.to:append(target)  
                    msg.arg = card:objectName()  
                    msg.arg2 = self:objectName()  
                    room:sendLog(msg)  
                      
                    room:doAnimate(1, player:objectName(), target:objectName())  
                end  
            end  
        elseif choice=="reduce" then                
            if use.to:length() > 1 then  
                -- 选择一名角色移除目标  
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(use.to) do  
                    targets:append(p)  
                end  
                  
                if not targets:isEmpty() then  
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@sheyan-reduce", true, true)  
                    if target then  
                        use.to:removeOne(target)  
                          
                        local msg = sgs.LogMessage()  
                        msg.type = "#SheyanReduce"  
                        msg.from = player  
                        msg.to:append(target)  
                        msg.arg = card:objectName()  
                        msg.arg2 = self:objectName()  
                        room:sendLog(msg)  
                    end  
                end  
            end  
        end  
          
        data:setValue(use)  
        return false  
    end  
}

-- 添加技能  
dongyun:addSkill(Bingzheng)  
dongyun:addSkill(Sheyan)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["dongyun"] = "董允",  
    ["#dongyun"] = "社稷之臣",  
    ["bingzheng"] = "秉正",  
    [":bingzheng"] = "回合结束时，你可以令一名手牌数不等于体力值的角色摸一张牌或弃一张牌，然后若其手牌数等于体力值，你摸一张牌",  
    ["sheyan"] = "设宴",  
    [":sheyan"] = "当你每回合首次成为普通锦囊的目标时，你可以令此牌的目标＋1或-1，目标数至少为1。",  
}  

handang = sgs.General(extension, "handang", "wu", 4)  

GongqiCard = sgs.CreateSkillCard{  
    name = "GongqiCard",  
    target_fixed = true,  
    will_throw = true,  
      
    on_use = function(self, room, source, targets)  
        -- 设置本回合攻击范围无限  
        room:setPlayerFlag(source, "gongqi_unlimited_range")  
          
        -- 如果弃置的是装备牌，可以弃置其他角色一张牌  
        local subcards = self:getSubcards()  
        if not subcards:isEmpty() then  
            local card = sgs.Sanguosha:getCard(subcards:first())  
            if card:getTypeId() == sgs.Card_TypeEquip then  
                local targets = sgs.SPlayerList()  
                local all_players = room:getOtherPlayers(source)  
                for _, p in sgs.qlist(all_players) do  
                    if p:getCardCount(true) > 0 then  
                        targets:append(p)  
                    end  
                end  
                  
                if not targets:isEmpty() then  
                    local target = room:askForPlayerChosen(source, targets, "gongqi",   
                        "@gongqi-discard-target", true, true)  
                    if target then  
                        local target_card = room:askForCardChosen(source, target, "he", "gongqi")  
                        if target_card then  
                            room:throwCard(target_card, target, source)  
                        end  
                    end  
                end  
            end  
        end  
    end  
}  
  
-- 弓骑视为技  
gongqi = sgs.CreateOneCardViewAsSkill{  
    name = "gongqi",  
    filter_pattern = ".",  
      
    view_as = function(self, card)  
        local gongqi_card = GongqiCard:clone()  
        gongqi_card:addSubcard(card)  
        gongqi_card:setSkillName(self:objectName())  
        gongqi_card:setShowSkill(self:objectName())  
        return gongqi_card  
    end,  
      
    enabled_at_play = function(self, player)  
        return player:canDiscard(player, "he") and not player:hasUsed("#GongqiCard")  
    end  
}  
  
-- 创建弓骑攻击范围技能  
gongqi_range = sgs.CreateAttackRangeSkill{  
    name = "#gongqi-range",  
    extra_func = function(self, player, include_weapon)  
        if player:hasFlag("gongqi_unlimited_range") then  
            return 1000 -- 无限攻击范围  
        end  
        return 0  
    end  
}  

JiefanCard = sgs.CreateSkillCard{  
    name = "JiefanCard",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
      
    on_use = function(self, room, source, targets)  
        room:setPlayerMark(source, "@jiefan", 0)
        local target = targets[1]  
        if not (target and target:isAlive()) then  
            return  
        end  
          
        -- 找到所有攻击范围内包含目标的角色  
        local in_range_players = {}  
          
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p ~= target and p:inMyAttackRange(target) then  
                table.insert(in_range_players, p) 
            end  
        end  
          
        -- 让每个在攻击范围内的角色选择  
        for _, p in ipairs(in_range_players) do  
            if p:isAlive() then  
                local choices = {}
                if p:getWeapon() then 
                    table.insert(choices,"discard_weapon") 
                end  
                table.insert(choices,"let_draw") 
                  
                local choice = room:askForChoice(p, "jiefan",  table.concat(choices, "+"))  
                  
                if choice == "discard_weapon" and p:getWeapon() then  
                    room:throwCard(p:getWeapon(), p, source)  
                else  
                    target:drawCards(1, "jiefan")  
                end  
            end  
        end  
    end  
}  
  
-- 解烦视为技  
jiefan = sgs.CreateZeroCardViewAsSkill{  
    name = "jiefan",  
    limit_mark = "@jiefan",
    view_as = function(self)  
        local jiefan_card = JiefanCard:clone()  
        jiefan_card:setSkillName(self:objectName())  
        jiefan_card:setShowSkill(self:objectName())  
        return jiefan_card  
    end,  
      
    enabled_at_play = function(self, player)  
        return player:getMark("@jiefan") > 0  
    end  
}
-- 将技能添加到武将  
handang:addSkill(gongqi)  
handang:addSkill(gongqi_range)  
handang:addSkill(jiefan)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["handang"] = "韩当",  
    ["gongqi"] = "弓骑",  
    [":gongqi"] = "出牌阶段限一次，你可以弃置一张牌，令本回合攻击范围无限。若此牌为装备牌，你可以弃置一名其他角色的一张牌。",  
    ["jiefan"] = "解烦",  
    [":jiefan"] = "限定技，出牌阶段，你可以选择一名角色，令所有攻击范围内包含其的角色各选择一项：1.弃置一张武器牌；2.令其摸一张牌。",  
    ["@jiefan"] = "解烦",  
    ["@gongqi-discard"] = "弓骑：弃置一张牌",  
    ["@gongqi-discard-target"] = "弓骑：选择一名角色弃置其一张牌",  
    ["@jiefan-choose"] = "解烦：选择一名角色",  
    ["discard_weapon"] = "弃置一张武器牌",  
    ["let_draw"] = "令其摸一张牌"  
}  
  

haopu = sgs.General(extension, "haopu", "shu", 4) -- 吴苋，蜀势力，3血，女性

-- 镇荧技能卡  
ZhenyingCard = sgs.CreateSkillCard{  
    name = "ZhenyingCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        if #targets >= 1 then return false end  
        if to_select:objectName() == sgs.Self:objectName() then return false end  
        return to_select:getHandcardNum() <= sgs.Self:getHandcardNum()  
    end,  
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        local source = effect.from  
        local target = effect.to  
          
        local source_choice = room:askForChoice(source, "zhenying_number", "0+1+2")  
        local target_choice = room:askForChoice(target, "zhenying_number", "0+1+2")  
          
        local source_num = tonumber(source_choice)  
        local target_num = tonumber(target_choice)  
          
        local source_current = source:getHandcardNum()  
        local target_current = target:getHandcardNum()  
          
        if source_current > source_num then  
            room:askForDiscard(source, "zhenying", source_current - source_num, source_current - source_num, false, false)  
        elseif source_current < source_num then  
            source:drawCards(source_num - source_current, "zhenying")  
        end  
          
        if target_current > target_num then  
            room:askForDiscard(target, "zhenying", target_current - target_num, target_current - target_num, false, false)  
        elseif target_current < target_num then  
            target:drawCards(target_num - target_current, "zhenying")  
        end  
          
        local smaller_player = nil  
        local larger_player = nil  
          
        if source_num < target_num then  
            smaller_player = source  
            larger_player = target  
        elseif target_num < source_num then  
            smaller_player = target  
            larger_player = source  
        end  
          
        if smaller_player and larger_player then  
            local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)  
            duel:setSkillName("zhenying")  
            local use = sgs.CardUseStruct()  
            use.card = duel  
            use.from = smaller_player  
            use.to:append(larger_player)  
            room:useCard(use)  
        end  
    end  
}  
  
zhenying = sgs.CreateZeroCardViewAsSkill{  
    name = "zhenying",  
    enabled_at_play = function(self, player)  
        return player:usedTimes("#ZhenyingCard") < 2  
    end,  
    view_as = function(self)  
        local card = ZhenyingCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end  
}  
  
haopu:addSkill(zhenying)  
  
-- 在翻译表中添加  
sgs.LoadTranslationTable{  
    -- ... 现有翻译 ...  
    ["haopu"] = "郝普",  
    ["zhenying"] = "镇荧",  
    [":zhenying"] = "出牌阶段限二次，你可以选择一名手牌数小于等于你的其他角色，你与其同时选择{0，1，2}中的一个数值，然后各自将手牌摸或弃至自己选择的数值。选择数值较小的角色视为对较大的角色使用一张【决斗】。",  
    ["ZhenyingCard"] = "镇荧",  
    ["zhenying_number"] = "镇荧：选择数值",  
    ["0"] = "0",  
    ["1"] = "1",   
    ["2"] = "2"  
}

-- 创建武将：
hejin = sgs.General(extension, "hejin", "qun", 3)  -- 吴国，4血，男性  

mouzhu_card = sgs.CreateSkillCard{  
    name = "mouzhu",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select, Self)  
        return #targets == 0 and to_select ~= Self and not to_select:isKongcheng()  
    end,  
      
    feasible = function(self, targets, Self)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 令目标交给你一张手牌  
        if not target:isKongcheng() then  
            local card_id = room:askForCardChosen(target, target, "h", "mouzhu")  
            room:obtainCard(source, card_id, false)  
        end  
          
        -- 检查手牌数比较  
        if target:getHandcardNum() < source:getHandcardNum() then  
            -- 让目标选择使用杀或决斗  
            local choices = {}  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            local duel = sgs.Sanguosha:cloneCard("duel")  
              
            if not target:isCardLimited(slash, sgs.Card_MethodUse) then  
                table.insert(choices, "slash")  
            end  
            if not target:isCardLimited(duel, sgs.Card_MethodUse) then  
                table.insert(choices, "duel")  
            end  
              
            if #choices > 0 then  
                local choice = room:askForChoice(target, "mouzhu", table.concat(choices, "+"))  
                local card_to_use = nil  
                  
                if choice == "slash" then  
                    card_to_use = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                elseif choice == "duel" then  
                    card_to_use = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)  
                end  
                  
                if card_to_use then  
                    card_to_use:setSkillName("_mouzhu")  
                    -- 这里可能要让目标选择使用目标
                    victim = room:askForPlayerChosen(target,  room:getOtherPlayers(target), self:objectName())
                    local use = sgs.CardUseStruct()  
                    use.card = card_to_use  
                    use.from = target  
                    use.to:append(victim)
                    room:useCard(use, false)  
                end  
            end  
        end  
    end  
}

mouzhu_vs = sgs.CreateZeroCardViewAsSkill{  
    name = "mouzhu",  
      
    view_as = function(self)  
        return mouzhu_card:clone()  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#mouzhu")  
    end  
}

yanhuo = sgs.CreateTriggerSkill{  
    name = "yanhuo",  
    events = {sgs.Death},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then return "" end  
          
        local death = data:toDeath()  
        if death.who ~= player then return "" end  
          
        -- 检查是否有杀死你的角色且该角色有牌可以弃置  
        if death.damage and death.damage.from and death.damage.from:isAlive() then  
            local killer = death.damage.from  
            if not killer:isNude() then  
                return self:objectName()  
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
        local death = data:toDeath()  
        local killer = death.damage.from  
          
        if not killer or not killer:isAlive() or killer:isNude() then  
            return false  
        end  
          
        -- 计算X值：死亡玩家的牌数  
        local x = player:getHandcardNum() + #player:getEquips()  
          
        if x <= 0 then return false end  
          
        -- 弃置杀死你的角色至多X张牌  
        local to_discard = math.min(x, killer:getCardCount(true))  
        if to_discard > 0 then  
            room:askForDiscard(killer, self:objectName(), to_discard, to_discard, false, true) --这里要改成让自己选，但是可能会有问题，先这样测 
        end  
          
        return false  
    end  
}

hejin:addSkill(mouzhu_vs)
hejin:addSkill(yanhuo)

sgs.LoadTranslationTable{
    ["hejin"] = "何进",
    ["mouzhu"] = "谋诛",  
    [":mouzhu"] = "出牌阶段限一次，你可以令一名其他角色交给你一张手牌，然后若其手牌数小于你，其视为使用一张杀或决斗。",  
    ["@mouzhu-invoke"] = "你可以发动谋诛",  
    ["~mouzhu"] = "选择一名其他角色",
    ["yanhuo"] = "延祸",  
    [":yanhuo"] = "你死亡时，你可以弃置杀死你的角色至多X张牌，X为你的牌数。",  
    ["@yanhuo-invoke"] = "你可以发动延祸",
}

-- 创建武将：
heqi = sgs.General(extension, "heqi", "wu", 4)  -- 吴国，4血，男性  

ShanjiCard = sgs.CreateSkillCard{  
    name = "shanji",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        local before_discard = target:getAttackRange() >= target:distanceTo(source)
        -- 弃置双方各一张牌  
        local card_id = room:askForCardChosen(source, source, "he", "shanji")  
        room:throwCard(sgs.Sanguosha:getCard(card_id), source, source)  
          
        local card_id2 = room:askForCardChosen(source, target, "he", "shanji")  
        room:throwCard(sgs.Sanguosha:getCard(card_id2), target, source)  
          
        -- 判断是否有闪  
        local has_jink = false  
        local card1 = sgs.Sanguosha:getCard(card_id)  
        local card2 = sgs.Sanguosha:getCard(card_id2)  
        if card1:isKindOf("Jink") or card2:isKindOf("Jink") then  
            has_jink = true  
        end  
        
        -- 判断是否离开攻击范围  
        local after_discard = target:getAttackRange() < target:distanceTo(source)
        local leave_range = before_discard and after_discard

        -- 如果满足条件，获得目标本回合失去的一张牌  
        if has_jink or leave_range then  
            source:obtainCard(sgs.Sanguosha:getCard(card_id2))  
        end  
    end  
}


Shanji = sgs.CreateZeroCardViewAsSkill{  
    name = "shanji",  
      
    view_as = function(self)  
        local card = ShanjiCard:clone()  
        card:setSkillName(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#shanji") and not player:isNude()  
    end  
}  

-- 华甲技能  
Huajia = sgs.CreateMaxCardsSkill{  
    name = "huajia",  
    extra_func = function(self, player)  
        if player:hasSkill(self:objectName()) then  
            -- 获取装备区的牌  
            local equips = player:getEquips()  
            local suits = {}  
              
            -- 统计不同花色的数量  
            for _, card in sgs.qlist(equips) do  
                local suit = card:getSuit()  
                suits[suit] = true  
            end  
              
            -- 计算不同花色的数量  
            local suit_count = 0  
            for _ in pairs(suits) do  
                suit_count = suit_count + 1  
            end  
              
            return suit_count  
        end  
        return 0  
    end  
}

heqi:addSkill(Shanji)  
heqi:addSkill(Huajia)
sgs.LoadTranslationTable{
    ["heqi"] = "贺齐",
    ["shanji"] = "闪击",  
    [":shanji"] = "出牌阶段限一次。你可以弃置你与一名其他角色各一张牌，若其中有闪或你因此离开其攻击范围，你获得其弃置的该牌。",  
    ["shanji:invoke"] = "你可以发动'闪击'",
    ["huajia"] = "华甲",  
    [":huajia"] = "你的手牌上限+X，X为你装备区牌的花色数。",
}

huojun = sgs.General(extension, "huojun", "shu", 3)  

gue = sgs.CreateOneCardViewAsSkill{  
    name = "gue",  
    filter_pattern = ".|.|.|hand",  
    view_as = function(self, card)  
        if sgs.Self:getHandcardNum() ~= 1 then return nil end
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()  
        if pattern == "slash" then  
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:addSubcard(card:getId())  
            slash:setSkillName(self:objectName()) 
            slash:setShowSkill(self:objectName())   
            return slash  
        elseif pattern == "jink" then  
            local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)  
            jink:addSubcard(card:getId())  
            jink:setSkillName(self:objectName()) 
            jink:setShowSkill(self:objectName())   
            return jink  
        else
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:addSubcard(card:getId())  
            slash:setSkillName(self:objectName())  
            slash:setShowSkill(self:objectName())  
            return slash              
        end  
        return nil  
    end,  
    enabled_at_play = function(self, player)  
        return player:getHandcardNum() == 1 and not player:hasUsed("#gue")  --player:usedTimes("ViewAsSkill_gueCard")==0
    end,  
    enabled_at_response = function(self, player, pattern)  
        return player:getHandcardNum() == 1 and (pattern == "slash" or pattern == "jink")  
    end  
}  
  
-- 技能2：伺攻  
sigong = sgs.CreateTriggerSkill{  
    name = "sigong",  
    events = {sgs.SlashMissed},  
    can_trigger = function(self, event, room, player, data)  
        local effect = data:toSlashEffect()  
        local source = effect.from
        local owner = room:findPlayerBySkillName(self:objectName())
        if (source and source:isAlive() and owner and owner:isAlive() and source:objectName()~=owner:objectName()) then
            return self:objectName(), owner:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who) 
        return ask_who:askForSkillInvoke(self:objectName(),data) 
    end,
    on_effect = function(self, event, room, player, data, ask_who)  
        local effect = data:toSlashEffect()  
        local source = effect.from  
        local target = effect.to  
          
        -- 调整手牌至1张  
        local handcards = ask_who:getHandcardNum()  
        if handcards > 1 then  
            room:askForDiscard(ask_who, self:objectName(), handcards - 1, handcards - 1, false, false)  
        elseif handcards < 1 then  
            ask_who:drawCards(1 - handcards)  
        end  
            
        -- 视为对来源使用决斗  
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)  
        duel:setSkillName(self:objectName())  
        duel:setShowSkill(self:objectName())  
            
        local use = sgs.CardUseStruct()  
        use.card = duel  
        use.from = ask_who  
        use.to:append(source)  
        room:useCard(use)  

        return false  
    end  
}  
  
-- 添加技能到武将  
huojun:addSkill(gue)  
huojun:addSkill(sigong)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["huojun"] = "霍峻",  
    ["#huojun"] = "孤城守将",  
    ["gue"] = "孤扼",  
    [":gue"] = "你最后一张手牌可以视为杀或闪使用或打出。",  
    ["sigong"] = "伺攻",   
    [":sigong"] = "当任意角色的杀被闪抵消后，你可以将手牌摸或弃置至1张，视为对来源使用一张决斗。"  
}  
--[[
--创建武将
luajushou = sgs.General(extension, "luajushou", "qun", 3)

luaxuyuan_tag = sgs.CreateTriggerSkill{
    name = "#luaxuyuan_tag",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then
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
                for i = 1, #name_list do
                    local skill_owner = name_list[i]
                    if skill_owner:getTag("luaxuyuan_fail"):toPlayer() ~= skill_owner and use.card:getTypeId() ~= sgs.Card_TypeSkill then
                        for _, p in sgs.qlist(use.to) do
                            local if_sameTarget = player:getTag("luaxuyuan_sameTarget"):toPlayer()
                            if not if_sameTarget or p == if_sameTarget then
                                local d = sgs.QVariant()
                                d:setValue(p)
                                player:setTag("luaxuyuan_sameTarget", d)
                            else
                                local d = sgs.QVariant()
                                d:setValue(skill_owner)
                                skill_owner:setTag("luaxuyuan_fail", d)
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
                    table.insert(skill_list, self:objectName())
                    table.insert(name_list, p)
				end
			end
            if #name_list <= 0 then return false end
            for i = 1, #name_list do
                local skill_owner = name_list[i]
                if not skill_owner:getTag("luaxuyuan_fail"):toPlayer() and player:getTag("luaxuyuan_sameTarget"):toPlayer() then
                    player:removeTag("luaxuyuan_sameTarget")
                    skill_owner:removeTag("luaxuyuan_fail")
                    return table.concat(skill_list,"|"), table.concat(name_list,"|")
                else
                    player:removeTag("luaxuyuan_sameTarget")
                    skill_owner:removeTag("luaxuyuan_fail")
                end
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
extension:insertRelatedSkills("luaxuyuan", "#luaxuyuan_tag")

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
]]

-- 创建武将：
liru = sgs.General(extension, "liru", "qun", 3) 

juece = sgs.CreateTriggerSkill{  
    name = "juece",  
    events = {sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:getPhase() ~= sgs.Player_Finish then return "" end  
          
        -- 检查是否有没有手牌的角色  
        for _, p in sgs.qlist(room:getAlivePlayers()) do -- 判断是否有手牌为0的角色
            if p:isKongcheng() then --有，直接返回
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:isKongcheng() then  
                targets:append(p)  
            end  
        end  
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@juece-damage", true, true) 
        --第一个true表示可以取消选择，第二个true表示显示技能名。 
        if target then  
            room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        return false  
    end,  
}

miejiCard = sgs.CreateSkillCard{  
    name = "miejiCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 将黑色锦囊牌置于牌堆顶  
        local card_id = self:getSubcards():first()  
        room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_DrawPile, true)  
          
        -- 发起军令。军令不会写
        local target = targets[1]  
        if target and target:isAlive() and source:isAlive() and not source:askCommandto(self:objectName(),target) then
            -- 目标拒绝执行军令  
            if source:canDiscard(target, "he") then
                room:throwCard(room:askForCardChosen(source, target, "he", self:objectName(), false, sgs.Card_MethodDiscard), target, source)
            end
            if source:canDiscard(target, "he") then
                room:throwCard(room:askForCardChosen(source, target, "he", self:objectName(), false, sgs.Card_MethodDiscard), target, source)
            end
        end  
    end  
}  
  
mieji = sgs.CreateViewAsSkill{  
    name = "mieji",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return to_select:isBlack() and to_select:isKindOf("TrickCard")  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = miejiCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            return card  
        end  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#miejiCard")  
    end  
}


fenchengCard = sgs.CreateSkillCard{  
    name = "fenchengCard",  
    target_fixed = true,  
    will_throw = true,  
      
    on_use = function(self, room, source, targets)  
        room:removePlayerMark(source, "@fencheng")  
        room:broadcastSkillInvoke("fencheng")  
          
        local others = room:getOtherPlayers(source)  
        local discard_num = 0  
        for _, player in sgs.qlist(others) do  
            if player:isAlive() then  
                -- 让玩家选择是否弃牌  
                local choice = room:askForChoice(player, "fencheng", "discard+damage", sgs.QVariant())  
                --伤害部分没问题，弃牌部分有问题
                if choice == "discard" then  
                    -- 选择弃牌  
                    local to_discard = discard_num + 1
                    if player:getHandcardNum()<to_discard then --手牌不够弃，直接造成伤害
                        room:damage(sgs.DamageStruct("fencheng", source, player, 1, sgs.DamageStruct_Fire))               
                    else 
                        room:askForDiscard(player, "fencheng", to_discard, to_discard, false, true)
                        discard_num = to_discard -- 更新下一个玩家需要弃置的牌数
                    end  
                else  
                    -- 选择受到伤害  
                    room:damage(sgs.DamageStruct("fencheng", source, player, 1, sgs.DamageStruct_Fire))  
                end
            end  
        end
    end  
}  
  
fencheng = sgs.CreateZeroCardViewAsSkill{  
    name = "fencheng",  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@fencheng",  
      
    view_as = function(self)  
        local card = fenchengCard:clone()  
        card:setSkillName(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return player:getMark("@fencheng") > 0  
    end  
}


liru:addSkill(juece)
liru:addSkill(mieji)
liru:addSkill(fencheng)

sgs.LoadTranslationTable{
    ["liru"] = "李儒",

    ["juece"] = "绝策",  
    [":juece"] = "你的回合结束时，你可以对一名没有手牌的角色造成一点伤害。",  
    ["@juece-damage"] = "你可以发动'绝策'，对一名没有手牌的角色造成一点伤害", 

    ["mieji"] = "灭计",  
    [":mieji"] = "出牌阶段限一次，你可以将一张黑色锦囊牌置于牌堆顶，然后向一名其他角色发起一个军令，若其不执行，你可以弃置其至多两张牌。",  
    ["mieji"] = "灭计",  
    ["mieji:accept"] = "接受军令",  
    ["mieji:reject"] = "拒绝军令",  
    ["@mieji-discard"] = "请选择要弃置的牌",  

    ["fencheng"] = "焚城",  
    [":fencheng"] = "限定技。出牌阶段，你可以令所有其他角色依次选择一项：弃置至少X张牌，X为上一个因该技能弃置的牌数＋1；或者受到你造成的1点火焰伤害。",  
    ["@fencheng"] = "焚城",  
    ["fencheng:discard"] = "弃置至少 %arg 张牌",  
    ["fencheng:damage"] = "受到1点火焰伤害",  
    ["@fencheng-discard"] = "焚城：请弃置至少 %arg 张牌，否则受到1点火焰伤害",  
}

-- 创建刘协武将  
liuxie = sgs.General(extension, "liuxie", "qun", 3) 

-- 天命技能实现  
Tianming = sgs.CreateTriggerSkill{  
    name = "tianming",  
    events = {sgs.TargetConfirmed},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        local use = data:toCardUse()  
        if use.card and use.card:isKindOf("Slash") and use.to:contains(player) then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        -- 弃置手牌逻辑  
        local handcard_num = player:getHandcardNum()  
        local to_discard = math.min(2, handcard_num)  
          
        if to_discard > 0 then  
            room:askForDiscard(player, self:objectName(), to_discard, to_discard, false, false)  
        end  
          
        -- 摸两张牌  
        room:drawCards(player, 2, self:objectName())  
          
        return false  
    end  
}

-- 密诏卡牌  
MizhaoCard = sgs.CreateSkillCard{  
    name = "mizhao",  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 将牌交给目标角色  
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "mizhao", "")  
        room:moveCardTo(self, target, sgs.Player_PlaceHand, reason)  
          
        -- 记录目标，用于后续拼点  
        source:setTag("MizhaoTarget", sgs.QVariant(target:objectName()))  
          
        -- 选择拼点的另一名角色  
        local others = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
            if p:objectName() ~= source:objectName() and not p:isKongcheng() then  
                others:append(p)  
            end  
        end  
          
        if others:isEmpty() then return end  
          
        local pindian_target = room:askForPlayerChosen(source, others, "mizhao", "@mizhao-pindian", true)  
        if pindian_target then  
            -- 进行拼点  
            target:pindian(pindian_target, "mizhao", nil)  
        end  
    end  
}  
  
-- 密诏视为技  
MizhaoViewAsSkill = sgs.CreateViewAsSkill{  
    name = "mizhao",  
      
    view_filter = function(self, selected, to_select)  
        -- 检查选择的牌数是否达到势力数-1  
        local kingdoms = {}  
        local kingdom_count = 0  
        for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do  
            if p:hasShownOneGeneral() then
                if p:getRole() == 'careerist' then --野心家视为不同势力
                    kingdom_count = kingdom_count+1
                else
                    kingdoms[p:getKingdom()] = true  
                end
            end
        end  
        kingdoms[sgs.Self:getKingdom()] = true  
          
        for _ in pairs(kingdoms) do  
            kingdom_count = kingdom_count + 1  
        end  
          
        local required_cards = kingdom_count - 1
        return #selected < required_cards  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 0 then return nil end  
          
        -- 检查势力数  
        local kingdoms = {}  
        local kingdom_count = 0  
        for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do  
            if p:hasShownOneGeneral() then
                if p:getRole() == 'careerist' then --野心家视为不同势力
                    kingdom_count = kingdom_count+1
                else
                    kingdoms[p:getKingdom()] = true  
                end
            end
        end  
        kingdoms[sgs.Self:getKingdom()] = true  
          
        for _ in pairs(kingdoms) do  
            kingdom_count = kingdom_count + 1  
        end  
          
        local required_cards = kingdom_count - 1 
        if #cards ~= required_cards then return nil end  
          
        local card = MizhaoCard:clone()  
        for _, c in ipairs(cards) do  
            card:addSubcard(c)  
        end  
        return card  
    end,  
      
    enabled_at_play = function(self)  
        return not sgs.Self:hasUsed("#mizhao")  
    end  
}  
  
-- 密诏触发技能（处理拼点后的效果）  
MizhaoTrigger = sgs.CreateTriggerSkill{  
    name = "#mizhao-trigger",  
    events = {sgs.Pindian},  
    global = true,  
      
    can_trigger = function(self, event, room, player, data)  
        local pindian = data:toPindian()  
        if pindian.reason == "mizhao" then  
            local winner = nil  
            local loser = nil  
            if pindian.from_number == pindian.to_number then
                return false
            end
            if pindian.success then  
                winner = pindian.from  
                loser = pindian.to  
            else  
                winner = pindian.to  
                loser = pindian.from  
            end  
              
            if winner and loser and winner:isAlive() and loser:isAlive() then  
                -- 赢家视为对输家使用一张杀  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName("mizhao")  
                  
                if winner:canSlash(loser, slash, false) then  
                    local use = sgs.CardUseStruct()  
                    use.from = winner  
                    use.to:append(loser)  
                    use.card = slash  
                      
                    room:useCard(use, false)  
                end  
            end  
        end  
          
        return false  
    end  
}  
  
-- 密诏技能（组合视为技和触发技）  
Mizhao = sgs.CreateTriggerSkill{  
    name = "mizhao",  
    view_as_skill = MizhaoViewAsSkill,  
      
    on_effect = function() end  -- 实际效果在MizhaoCard和MizhaoTrigger中处理  
}

-- 添加技能  
liuxie:addSkill(Tianming)  
liuxie:addSkill(Mizhao)  
liuxie:addSkill(MizhaoTrigger)  -- 全局触发技需要单独添加  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["liuxie"] = "刘协",  
    ["#liuxie"] = "汉献帝",  
    ["tianming"] = "天命",  
    [":tianming"] = "当你成为【杀】的目标后，你可以弃置两张手牌，不足则全弃，没有则不弃，然后摸两张牌。",  
    ["mizhao"] = "密诏",  
    [":mizhao"] = "出牌阶段限1次，你可以将X张牌交给一名其他角色（X为场上势力数-1），令其与另一名角色拼点，赢的角色视为对没赢的角色使用一张【杀】。",  
    ["@mizhao-pindian"] = "请选择拼点的目标",  
}
--[[
lualuotong = sgs.General(extension, "lualuotong", "wu")

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
]]
luyusheng_canghai = sgs.General(extension, "luyusheng_canghai", "wu", 3, false)  

fengwu = sgs.CreateTriggerSkill{  
    name = "fengwu",  
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart},  
      
    can_trigger = function(self, event, room, player, data)  
        -- 检查技能拥有者是否存活且拥有技能  
        local luyusheng = room:findPlayerBySkillName(self:objectName())  
        if not (luyusheng and luyusheng:isAlive() and luyusheng:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        -- 检查是否为其他同势力角色的准备阶段  
        if player and player:isAlive() and player:getPhase() == sgs.Player_Start   
           and luyusheng:isFriendWith(player) and player ~= luyusheng then  
            return self:objectName(), luyusheng:objectName()
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        -- 检查是否有手牌可以交给目标  
        if ask_who:getCardCount() == 0 then  
            return false  
        end  
          
        -- 询问是否发动技能  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 选择一张牌交给目标角色  
        local card = room:askForCard(ask_who, ".", "@fengwu-give:" .. player:objectName(),   
            sgs.QVariant(), sgs.Card_MethodNone)  
        if card then  
            room:obtainCard(player, card, false)  
        else
            return false
        end  
          
        local all_players = room:getAlivePlayers()  
          
        -- 检查是否手牌数最少  
        local min_handcard = 1000  
        for _, p in sgs.qlist(all_players) do  
            min_handcard = math.min(min_handcard, p:getHandcardNum())  
        end  
          
        if player:getHandcardNum() == min_handcard then  
            -- 恢复一点体力  
            local recover = sgs.RecoverStruct()  
            recover.who = ask_who  
            recover.recover = 1  
            room:recover(player, recover)  
        end  
          
        -- 检查是否体力值最低  
        local min_hp = 1000  
        for _, p in sgs.qlist(all_players) do  
            min_hp = math.min(min_hp, p:getHp())  
        end  
          
        if player:getHp() == min_hp then  
            -- 获得牌堆一张基础牌  
            local basic_cards = {}  
            for i = 1, 20 do -- 检查牌堆顶20张牌  
                local card_id = room:drawCard()  
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:getTypeId() == sgs.Card_TypeBasic then  
                    room:obtainCard(player, card_id, false)  
                    break  
                else  
                    table.insert(basic_cards, card_id)  
                end  
            end  
            -- 将非基础牌放回牌堆底  
            if #basic_cards > 0 then  
                room:returnToDrawPile(basic_cards)  
            end  
        end  
          
        return false  
    end  
}  
  
-- 昭节技能实现  
zhaojie = sgs.CreateTriggerSkill{  
    name = "zhaojie",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.DamageInflicted},  --sgs.CardEffected
      
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        if event == sgs.DamageInflicted then  
            local damage = data:toDamage()  
            -- 检查是否为红色牌造成的伤害  
            if damage.card and damage.card:isRed() then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 锁定技，无需询问  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.DamageInflicted then  
            local damage = data:toDamage()  
            damage.damage = damage.damage - 1
            data:setValue(damage)
            -- 如果伤害减为0，则防止伤害  
            if damage.damage <= 0 then  
                return true  
            end  
        end  
          
        return false  
    end  
}  
zhaojieDelay = sgs.CreateProhibitSkill{  --不能指定为目标，不是取消目标
    name = "zhaojieDelay",  
    is_prohibited = function(self, from, to, card)  
        if to and to:hasSkill(self:objectName()) and card and card:isKindOf("DelayedTrick") then  
            return true  
        end  
        return false  
    end  
}
-- 将技能添加到武将  
luyusheng_canghai:addSkill(fengwu)  
luyusheng_canghai:addSkill(zhaojie)  
luyusheng_canghai:addSkill(zhaojieDelay)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["luyusheng_canghai"] = "陆郁生",  
    ["fengwu"] = "奉无",  
    [":fengwu"] = "与你势力相同的其他角色的准备阶段，你可以交给其一张牌，然后若其手牌数最少，其恢复一点体力；若其体力值最低，其获得牌堆一张基础牌。",  
    ["zhaojie"] = "昭节",  
    [":zhaojie"] = "锁定技，红色牌对你的伤害-1",  
    ["zhaojieDelay"] = "昭节-延时",  
    [":zhaojieDelay"] = "锁定技，你不会成为延时锦囊的目标",  
    ["@fengwu-give"] = "奉无：交给 %src 一张牌"  
}  
  

luzhi = sgs.General(extension, "luzhi", "wei", 3) -- 吴苋，蜀势力，3血，女性
xianjingVS = sgs.CreateZeroCardViewAsSkill{  
    name = "xianjing",  
    response_or_use = true,  -- 关键参数，允许既主动使用又响应使用  
    n = 0,  
    view_as = function(self)  
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()  
        if pattern == "slash" then  
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:setSkillName(self:objectName())  
            return slash  
        elseif pattern == "jink" then  
            local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)  
            jink:setSkillName(self:objectName())  
            return jink  
        else
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:setSkillName(self:objectName())  
            return slash              
        end  
        return nil  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasFlag("xianjing_used") and sgs.Slash_IsAvailable(player) and not player:isKongcheng()
    end,  
      
    enabled_at_response = function(self, player, pattern)  
        return not player:hasFlag("xianjing_used") and (pattern == "slash" or pattern == "jink") and not player:isKongcheng()
    end  
}  
xianjing = sgs.CreateTriggerSkill{  
    name = "xianjing",  
    events = {sgs.CardUsed, sgs.CardResponded},  
    view_as_skill = xianjingVS,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill("xianjing")) then return "" end  
        -- 当使用衔镜技能时设置标记  
        local card = nil
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else -- sgs.CardResponded  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
        if card:getSkillName() == "xianjing" then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 自动触发  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:setPlayerFlag(player, "xianjing_used")  
        return false  
    end  
}
-- 清忠技能：出牌阶段开始时，你可以摸两张牌，则此阶段结束时，你与一名手牌最少的角色交换手牌  
qingzhong = sgs.CreateTriggerSkill{  
    name = "qingzhong",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player:hasSkill(self:objectName()) then return "" end  
          
        if event == sgs.EventPhaseStart then  
            if player:getPhase() == sgs.Player_Play then  
                return self:objectName()  
            end  
        elseif event == sgs.EventPhaseEnd then  
            if player:getPhase() == sgs.Player_Play and player:hasFlag("qingzhong_used") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            if player:askForSkillInvoke(self:objectName(), data) then  
                room:broadcastSkillInvoke(self:objectName(), player)  
                return true  
            end  
        else  
            return true --player:askForSkillInvoke(self:objectName(), data)   
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            player:drawCards(2, self:objectName())  
            room:setPlayerFlag(player, "qingzhong_used")  
        else  
            -- 找到手牌最少的角色  
            local otherPlayers = sgs.QList2Table(room:getOtherPlayers(player))  
            local least = 1000  
            for _, player in ipairs(otherPlayers) do  
                least = math.min(player:getHandcardNum(), least)  
            end  
            
            -- 找到手牌数等于最少数量的玩家  
            local targets = {}  
            for _, player in ipairs(otherPlayers) do  
                if player:getHandcardNum() == least then  
                    table.insert(targets, player)  
                end  
            end
              
            if  #targets > 0 then  
                local target = nil  
                if #targets == 1 then  
                    target = targets[1]  
                else  
                    target = room:askForPlayerChosen(player, targets, self:objectName(), "@qingzhong-choose")  
                end  
                  
                if target then  
                    -- 全部交换：交换所有手牌
                    local source_handcards = sgs.IntList()
                    local target_handcards = sgs.IntList()
                    
                    -- 获取双方所有手牌
                    for _, card in sgs.qlist(player:getHandcards()) do
                        source_handcards:append(card:getId())
                    end
                    
                    for _, card in sgs.qlist(target:getHandcards()) do
                        target_handcards:append(card:getId())
                    end
                    
                    if not source_handcards:isEmpty() or not target_handcards:isEmpty() then
                        local move1 = sgs.CardsMoveStruct()
                        move1.card_ids = source_handcards
                        move1.from = player
                        move1.to = target
                        move1.to_place = sgs.Player_PlaceHand
                        move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                        player:objectName(), target:objectName(), "exchange", "")
                        
                        local move2 = sgs.CardsMoveStruct()
                        move2.card_ids = target_handcards
                        move2.from = target
                        move2.to = player
                        move2.to_place = sgs.Player_PlaceHand
                        move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                        target:objectName(), player:objectName(), "exchange", "")
                        
                        local moves = sgs.CardsMoveList()
                        moves:append(move1)
                        moves:append(move2)
                        
                        room:moveCardsAtomic(moves, true)
                    end
                end  
            end    
        end  
        return false  
    end  
}  
  

luzhi:addSkill(xianjing)  
luzhi:addSkill(qingzhong)  
sgs.LoadTranslationTable{  
    -- ... 现有翻译 ...  
    ["luzhi"] = "鲁芝",  
    ["xianjing"] = "衔镜",  
    [":xianjing"] = "每回合限一次。当你需要使用杀或闪时，若你有手牌，你可以视为使用之。",  
    ["qingzhong"] = "清忠",  
    [":qingzhong"] = "出牌阶段开始时，你可以摸两张牌，则此阶段结束时，你与一名手牌最少的角色交换手牌",  

} 

manchong = sgs.General(extension, "manchong", "wei", 3) -- 吴苋，蜀势力，3血，女性

junxing_card = sgs.CreateSkillCard{  
    name = "junxing_card",  
    target_fixed = false,  
    will_throw = true,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  

        -- 弃置第三种类别的牌  
        local subcards = self:getSubcards()  
        local used_types = {}  
            
        -- 获取已使用的牌类别  
        for _, id in sgs.qlist(subcards) do  
            local card = sgs.Sanguosha:getCard(id)  
            used_types[card:getTypeId()] = true  
        end  

        local cards = target:getCards("he")  
        local valid_cards = {}         
        -- 添加目标的牌  
        for _, card in sgs.qlist(cards) do
            if not used_types[card:getTypeId()] then
                table.insert(valid_cards, card:getEffectiveId()) 
            end
        end  

        local choices = {"junxing_loseHp", "junxing_turnOver"}  
        if #valid_cards > 0 then
            table.insert(choices,"junxing_discard")
        end
        local choice = room:askForChoice(target, "junxing", table.concat(choices, "+"))  
          
        if choice == "junxing_discard" then
            local chosen_id = nil
            local card = nil
            if #valid_cards > 0 then  
                --chosen_id = room:askForDiscard(target, "junxing", 1, 1, false, true, "@junxing-discard")  
                chosen_id = room:askForCardChosen(target, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
                if chosen_id then                
                    card = sgs.Sanguosha:getCard(chosen_id)
                end
                if chosen_id~=nil and card~=nil and not used_types[card:getTypeId()] then  
                    room:throwCard(chosen_id, target, target, self:objectName())  
                end
            end  
            if #valid_cards<=0 or chosen_id==nil or card==nil or used_types[card:getTypeId()] then  
                -- 没有第三种类别的牌，失去体力  
                room:loseHp(target, 1)  
            end  
        elseif choice == "junxing_loseHp" then  
            room:loseHp(target, 1)  
        else  
            target:turnOver()  
        end  
    end  
}  
  
-- 峻刑技能  
junxing = sgs.CreateViewAsSkill{  
    name = "junxing",  
    n = 2,  
      
    view_filter = function(self, selected, to_select)  
        if #selected >= 2 then return false end  
        if #selected == 0 then return true end  
          
        -- 检查类别是否不同  
        local first_card = selected[1]  
        return first_card:getTypeId() ~= to_select:getTypeId()  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 2 then  
            local card = junxing_card:clone()  
            card:setSkillName(self:objectName())  
            for _, c in ipairs(cards) do  
                card:addSubcard(c)  
            end  
            return card  
        end  
        return nil  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#junxing_card") and not player:isNude()  
    end  
}  
  
-- 御策技能  
yuce = sgs.CreateTriggerSkill{  
    name = "yuce",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not player:hasSkill(self:objectName()) or player:isKongcheng() then  
            return ""  
        end  
        local damage = data:toDamage()  
        if damage.to:objectName() == player:objectName() and damage.from then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if not player:askForSkillInvoke(self:objectName(),data) then
            return false
        end
        local damage = data:toDamage()  
        local cards = player:getHandcards()  
        local card_ids = {}  
        for _, card in sgs.qlist(cards) do  
            table.insert(card_ids, card:getEffectiveId())  
        end  
          
        local card_id = room:askForCardChosen(player, player, "h", self:objectName(), true)  
        if card_id >= 0 then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            room:showCard(player, card_id)  
            player:setTag("yuce_card", sgs.QVariant(card_id))  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local card_id = player:getTag("yuce_card"):toInt()  
        local shown_card = sgs.Sanguosha:getCard(card_id)  
        --没有伤害源
        if not damage.from then return false end

        local from_cards = damage.from:getHandcards()  
        local valid_cards = {}  
        local invalid_cards = {}
        -- 找到类别不同的手牌  
        for _, card in sgs.qlist(from_cards) do  
            if card:getTypeId() ~= shown_card:getTypeId() then  
                table.insert(valid_cards, card:getEffectiveId())  
            else
                table.insert(invalid_cards, card:getEffectiveId())  
            end  
        end
        --伤害源有手牌，且有有效牌，弃置该牌
        local card_id = nil
        local card = nil
        if not damage.from:isKongcheng() and #valid_cards > 0 then      
            --card_id = room:askForDiscard(damage.from, self:objectName(), 1, 1, false, false, "@yuce-discard") --返回bool值
            card_id = room:askForCardChosen(damage.from, damage.from, "h", self:objectName(), false, sgs.Card_MethodDiscard)  
            if card_id then                
                card = sgs.Sanguosha:getCard(card_id)
            end
            if card_id~=nil and card~=nil and card:getTypeId() ~= shown_card:getTypeId() then  
                room:throwCard(card_id, damage.from, damage.from, self:objectName())  
            end
        end

        --伤害源没有手牌，或没有有效牌，或弃置的牌类别相同，伤害-1
        if damage.from:isKongcheng() or #valid_cards <= 0 or card_id==nil or card==nil or (card and card:getTypeId() == shown_card:getTypeId()) then
            -- 没有不同类别的手牌，伤害-1  
            damage.damage = damage.damage - 1  
            data:setValue(damage)  
            if damage.damage <= 0 then  
                return true -- 阻止伤害  
            end  
        end  
          
        return false  
    end  
}  
  

manchong:addSkill(junxing)  
manchong:addSkill(yuce)  
sgs.LoadTranslationTable{
    ["manchong"] = "满宠",
    ["junxing"] = "峻刑",  
    [":junxing"] = "出牌阶段限一次。你可以弃置两张类别不同的牌，令一名其他角色选择一项：1. 弃置一张第三种类别的牌；2. 失去一点体力；3. 叠置。",  
    ["junxing:discard"] = "弃置一张第三种类别的牌",  
    ["junxing:damage"] = "失去一点体力",  
    ["junxing:overlay"] = "叠置",
    ["yuce"] = "御策",  
    [":yuce"] = "当你受到伤害时，你可以展示一张手牌，伤害来源需弃置一张类别不同的手牌，否则此伤害-1。",  
    ["@yuce-discard"] = "%src 对你使用了技能'%arg'并展示了 %arg2，请弃置一张类别不同的手牌，否则此伤害-1",
}

pangdegong = sgs.General(extension, "pangdegong", "qun", 3)  

guiyin = sgs.CreateTriggerSkill{  
    name = "guiyin",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Limited, -- 每轮限一次  
    limit_mark = "@guiyin",
    can_trigger = function(self, event, room, player, data)  
        -- 检查是否为准备阶段且技能拥有者存在  
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Start) then
            return ""
        end
        if player:hasSkill(self:objectName()) then
            room:setPlayerMark(player,"@guiyin",1)
        else
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:getMark("@guiyin")>0) then 
                return ""
            end
            return self:objectName(), owner:objectName()
        end
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        -- 询问是否发动技能  
        if room:askForSkillInvoke(ask_who, self:objectName(), data) then  
            room:setPlayerMark(ask_who,"@guiyin",0)
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 创建调虎离山效果  
        local lure_tiger = sgs.Sanguosha:cloneCard("lure_tiger")  
        local use = sgs.CardUseStruct()  
        use.card = lure_tiger  
        use.from = player -- 准备阶段的角色  
        use.to:append(ask_who) -- 技能拥有者作为目标  
          
        room:useCard(use)  
    end  
}

yinyi_card = sgs.CreateSkillCard{  
    name = "yinyi_card",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)  
        -- 发起判定  
        local judge = sgs.JudgeStruct()  
        judge.pattern = "."  
        judge.good = true  
        judge.reason = "yinyi"  
        judge.who = source  
          
        room:judge(judge)  
          
        local judge_card = judge.card  
        local is_odd = (judge_card:getNumber() % 2 == 1)  
          
        if is_odd then  
            -- 奇数：选择一名角色造成伤害  
            local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "yinyi", "选择一名角色造成伤害", false, true)  
            if target then  
                local damage = sgs.DamageStruct()  
                damage.from = source  
                damage.to = target  
                damage.damage = 1  
                damage.reason = "yinyi"  
                room:damage(damage)  
            end  
        else  
            -- 偶数：选择1-2名角色使用铁索连环  
            local targets = {}  
            -- 第一个目标  
            local target1 = room:askForPlayerChosen(source, room:getAlivePlayers(), "yinyi", "选择第一个铁索连环目标", false, true)  
            if target1 then  
                table.insert(targets, target1)  
                local target2 = room:askForPlayerChosen(source, room:getOtherPlayers(target1), "yinyi", "选择第二个铁索连环目标（可取消）", true, true)  
                if target2 then  
                    table.insert(targets, target2)  
                end  
                  
                -- 创建并使用铁索连环  
                if #targets > 0 then  
                    local iron_chain = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_NoSuit, 0)  
                    iron_chain:setSkillName("yinyi")  
                      
                    local use = sgs.CardUseStruct()  
                    use.card = iron_chain  
                    use.from = source  
                    use.to = sgs.SPlayerList()  
                    for _, target in ipairs(targets) do  
                        use.to:append(target)  
                    end  
                      
                    room:useCard(use, false)  
                end  
            end  
        end  
    end  
}  
  
-- 视为技能类  
yinyi = sgs.CreateZeroCardViewAsSkill{  
    name = "yinyi",  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#yinyi_card")  
    end,  
    view_as = function(self)  
        local card = yinyi_card:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end  
}
pangdegong:addSkill(guiyin)
pangdegong:addSkill(yinyi)
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["pangdegong"] = "庞德公",  

      
    ["guiyin"] = "归隐",  
    [":guiyin"] = "每轮限一次。任意一名角色准备阶段，你可令该角色视为对你使用一张调虎离山",  
    ["yinyi"] = "隐逸",
    [":yinyi"] = "出牌阶段限一次。你可以发起一次判定，若判定牌是奇数，你对一名角色造成1点伤害；若判定牌是偶数，你视为使用一张铁索连环"
}  

panzhang = sgs.General(extension, "panzhang", "wu", 4) -- 3体力，男性  

-- 夺刀技能实现  
duodao = sgs.CreateTriggerSkill{  
    name = "duodao",  
    events = {sgs.Damaged},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("Slash") and damage.from and   
           damage.from:isAlive() and damage.from:getWeapon() then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if player:canDiscard(player, "he") and   
           player:askForSkillInvoke(self:objectName(), data) then  
            local cards = room:askForDiscard(player, self:objectName(), 1, 1, false, true, "@duodao-discard")  
            if #cards > 0 then  
                room:broadcastSkillInvoke(self:objectName())  
                return true  
            end  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local weapon = damage.from:getWeapon()  
        if weapon then  
            room:obtainCard(player, weapon, false)  
        end  
        return false  
    end  
}  
  
-- 暗箭技能实现    
anjian = sgs.CreateTriggerSkill{  
    name = "anjian",  
    events = {sgs.DamageCaused},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("Slash") and damage.to and  
           damage.to:isAlive() and not damage.to:inMyAttackRange(player) then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技，自动触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        room:broadcastSkillInvoke(self:objectName())  
        return false  
    end  
}  
    
-- 创建潘璋武将  
panzhang:addSkill(duodao)  
panzhang:addSkill(anjian)  
  
-- 注册扩展包  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["panzhang"] = "潘璋",  
    ["duodao"] = "夺刀",   
    [":duodao"] = "你受到杀的伤害后，你可以弃置一张牌，然后获得伤害来源装备区的武器。",  
    ["@duodao-discard"] = "你可以弃置一张牌发动'夺刀'",  
    ["anjian"] = "暗箭",  
    [":anjian"] = "锁定技，当你使用杀对目标造成伤害时，若你不在其攻击范围内，此伤害+1。"  
}  


-- 创建武将：
sunluban = sgs.General(extension, "sunluban", "wu", 3, false)  -- 吴国，4血，男性  
jianhuiCard = sgs.CreateSkillCard{  
    name = "jianhuiCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        if #targets == 0 and not to_select:isKongcheng() then  
            return true --to_select:objectName() ~= sgs.Self:objectName()  
        elseif #targets == 1 then  
            return to_select:objectName() ~= targets[1]:objectName() and not to_select:isKongcheng()--and to_select:objectName() ~= sgs.Self:objectName()  
        else  
            return false  
        end  
    end,  
    
    feasible = function(self,targets)
        return #targets==2
    end,

    on_use = function(self, room, source, targets)  
        -- 获取两个目标  
        local first = targets[1]  
        local second = targets[2]  
          
        -- 进行拼点  
        local success = first:pindian(second,"jianhui")
        --[[
        -- 获取拼点结果  
        local winner = nil  
        local loser = nil  
          
        if success then  --平局没处理，所以第一个角色最好不要选自己
            winner = first  
            loser = second  
        else  
            winner = second  
            loser = first  
        end  
        room:loseHp(loser, 1)  
        ]]
    end  
}  
  
jianhui = sgs.CreateZeroCardViewAsSkill{  
    name = "jianhui",  
      
    view_as = function(self)  
        local card = jianhuiCard:clone()  
        card:setSkillName(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#jianhuiCard")  
    end  
}

-- 密诏触发技能（处理拼点后的效果）  
jianhuiTrigger = sgs.CreateTriggerSkill{  
    name = "#jianhui-trigger",  
    events = {sgs.Pindian},  
    global = true,  
      
    can_trigger = function(self, event, room, player, data)  
        local pindian = data:toPindian()  
        if pindian.reason == "jianhui" then  
            local winner = nil  
            local loser = nil  
            if pindian.from_number == pindian.to_number then
                return false
            end
            if pindian.success then  
                winner = pindian.from  
                loser = pindian.to  
            else  
                winner = pindian.to  
                loser = pindian.from  
            end  

            if winner and loser and loser:isAlive() and pindian.from_number + pindian.to_number >= 13 then  
                room:loseHp(loser, 1)  
            end  
        end  
          
        return false  
    end  
}  
  
--只实现了免伤部分，杀死奖励部分怎么写不知道
LuaJiaoJin = sgs.CreateTriggerSkill{  
    name = "LuaJiaoJin",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.DamageInflicted, sgs.Death},  
      
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.DamageInflicted then  
            if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
                return ""  
            end  
              
            -- 获取当前杀死该角色的奖励牌数  
            local reward = player:getMark("@jiaoJin_reward") or 0  
                            
            -- 如果奖励牌数小于等于4，防止伤害  
            if reward <= 4 then    
                return self:objectName()  
            end  
        elseif event == sgs.Death then  
            local death = data:toDeath()  
            local victim = death.who  
              
            if victim and victim:hasSkill(self:objectName()) then  
                local killer = death.damage and death.damage.from  
                if killer then  
                    -- 获取额外奖励牌数  
                    local extra_reward = victim:getMark("@jiaoJin_reward") or 0  
                      
                    -- 设置额外奖励牌数  
                    if extra_reward > 0 then  
                        room:drawCards(killer, extra_reward)  
                    end  
                end  
            end  
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:hasShownSkill(self:objectName()) then
            return true
        else
            return player:askForSkillInvoke(self:objectName(), data)
        end
    end,        
    on_effect = function(self, event, room, player, data)  
        -- 增加奖励牌数标记  
        room:addPlayerMark(player, "@jiaoJin_reward")  
        local damage = data:toDamage()  

        -- 显示技能发动  
        room:notifySkillInvoked(player, self:objectName())  
        room:broadcastSkillInvoke(self:objectName())  
          
        -- 防止伤害  
        --room:sendCompulsoryTriggerLog(player, self:objectName())  
        local msg = sgs.LogMessage()  
        msg.type = "#JiaoJinProtect"  
        msg.from = player  
        msg.to:append(damage.from)  
        msg.arg = tostring(damage.damage)  
        msg.arg2 = self:objectName()  
        room:sendLog(msg)  

        damage.damage = 0
        damage.prevented = true
        data:setValue(damage)          
        return true  
    end  
}

sunluban:addSkill(jianhui)
sunluban:addSkill(jianhuiTrigger)
sunluban:addSkill(LuaJiaoJin)
--sunluban:addCompanion(sunce)
sgs.LoadTranslationTable{
    ['sunluban'] = "孙鲁班",

    ["jianhui"] = "僭毁",  
    [":jianhui"] = "出牌阶段限一次，你可以令两名角色拼点，若点数和大于等于13，没赢的角色失去一点体力。",  
    ["jianhui:pindian"] = "僭毁拼点",  

    ["LuaJiaoJin"] = "娇矜",  
    [":LuaJiaoJin"] = "锁定技。当你受到伤害时，你令杀死你的奖励牌数+1，若杀死你的奖励牌数小于等于4，你防止此伤害。",  
    ["@jiaoJin_reward"] = "娇矜",  
    ["#JiaoJinProtect"] = "%from 的'%arg2'效果被触发，防止了 %arg 点伤害",  
}


-- 创建武将：
sunqian = sgs.General(extension, "sunqian", "shu", 3)  -- 吴国，4血，男性  

shuomengCard = sgs.CreateSkillCard{  
    name = "shuomengCard",  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and (to_select:getKingdom() ~= sgs.Self:getKingdom() or to_select:getRole()=="careerist" or sgs.Self:getRole()=="careerist") 
               and not to_select:isKongcheng()
    end,  
      
    on_effect = function(self, effect)  
        local source = effect.from  
        local target = effect.to  
        local room = source:getRoom()  
          
        -- 执行拼点。可以发起拼点，正式拼点失败
        local success = source:pindian(target, "shuomeng")  
        --[[
        if success then
            --room:setPlayerMark(source,"shuomeng_win")
            local card = sgs.Sanguosha:cloneCard("befriend_attacking", sgs.Card_NoSuit, 0)  
            card:setSkillName("_shuomeng")  
            room:useCard(sgs.CardUseStruct(card, source, target)) 
        else
            --room:setPlayerMark(target,"shuomeng_win")
            local card = sgs.Sanguosha:cloneCard("befriend_attacking", sgs.Card_NoSuit, 0)  
            card:setSkillName("_shuomeng")  
            room:useCard(sgs.CardUseStruct(card, target, source))             
        end  
        ]]
    end  
}  
  
-- 技能视为技部分  
shuomeng = sgs.CreateZeroCardViewAsSkill{  
    name = "shuomeng",  
    view_as = function(self)  
        local card = shuomengCard:clone()  
        card:setShowSkill(self:objectName()) 
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#shuomengCard") and not player:isKongcheng()  --拼点必须有手牌
    end  
}

shuomengTrigger = sgs.CreateTriggerSkill{  
    name = "#shuomeng-trigger",  
    events = {sgs.Pindian},  
    global = true,  
      
    can_trigger = function(self, event, room, player, data)  
        local pindian = data:toPindian()  
        if pindian.reason == "shuomeng" then  
            local winner = nil  
            local loser = nil  
            if pindian.from_number == pindian.to_number then
                return false
            end
            if pindian.success then  
                winner = pindian.from  
                loser = pindian.to  
            else  
                winner = pindian.to  
                loser = pindian.from  
            end  

            if winner and loser and winner:isAlive() and loser:isAlive() then  
                local card = sgs.Sanguosha:cloneCard("befriend_attacking", sgs.Card_NoSuit, 0)  
                card:setSkillName("_shuomeng")  
                room:useCard(sgs.CardUseStruct(card, winner, loser)) 
            end  
        end  
          
        return false  
    end  
}  

qianya = sgs.CreateTriggerSkill{
    name = "qianya",
    --frequency = sgs.Skil_Compulsory,
    events = {sgs.DamageInflicted, sgs.EventPhaseStart}, 
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return "" end  
        if event == sgs.DamageInflicted then 
            return self:objectName()     
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then  
            return self:objectName()
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.DamageInflicted then  
            local damage = data:toDamage()  
            if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("TrickCard")) then
                damage.damage = 0
                damage.prevented = true
                data:setValue(damage)   
                return true
            end
        elseif event == sgs.EventPhaseStart then  
            -- 准备阶段失去技能。这部分有问题
            if player:inHeadSkills(self:objectName()) then
                room:detachSkillFromPlayer(player, self:objectName(), false, false, true)--第三个参数表示该技能的位置是否在主将上，默认true，位置不对移除不了
            else
                room:detachSkillFromPlayer(player, self:objectName(), false, false, false)--第三个参数表示该技能的位置是否在主将上，默认true，位置不对移除不了
            end
        end  
          
        return false  
    end,  
}

sunqian:addSkill(shuomeng)
sunqian:addSkill(qianya)
sunqian:addSkill(shuomengTrigger)
sgs.LoadTranslationTable{
    ["sunqian"] = "孙乾",

    ["shuomeng"] = "说盟",  
    [":shuomeng"] = "出牌阶段限一次。你可与一名与你势力不同的角色拼点，赢的角色视为对没赢的使用一张远交近攻",
    ["@shuomeng"] = "请选择一名与你势力不同的角色进行拼点",  
    ["~shuomeng"] = "选择一张手牌→选择一名与你势力不同的角色→点击确定",  
    ["shuomeng"] = "说盟",  
    ["#ShuoMeng"] = "%from 发动了'%arg'，与 %to 拼点，%from %arg2",

    ["qianya"] = "谦雅",  
    [":qianya"] = "当你受到伤害牌的伤害时，取消之；准备阶段，你失去此技能",
    ["#qianya"] = "%from 的'%arg'被触发，%from 不能成为 %card 的目标",  
    ["#qianyaLose"] = "%from 的'%arg'被触发，%from 失去了'%arg'技能",
}


sunxiu = sgs.General(extension, "sunxiu", "wu", 3) -- 孙休，吴势力，3血


-- 宴诛技能卡  
YanzhuCard = sgs.CreateSkillCard{  
    name = "YanzhuCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        local target = effect.to  
          
        -- 目标摸一张牌  
        target:drawCards(1, "yanzhu")  
          
        -- 目标选择  
        local choices = {}  
        local others = room:getOtherPlayers(source,false)
        local next_player = target:getNextAlive()  
        
        local current = target:getNextAlive()
        while current ~= target do  
            current = current:getNextAlive()  
            if current:getNextAlive() == target then break end  
        end  
        local prev_player = current  

        if target:getHandcardNum() >= 2 and next_player ~= target and prev_player ~= target then  
            table.insert(choices, "give_cards")  
        end  
        table.insert(choices, "slash_effect")  
          
        local choice = room:askForChoice(target, "yanzhu", table.concat(choices, "+"))  
          
        if choice == "give_cards" then  
            -- 交给上下家各一张牌  
            local card_id1 = room:askForCardChosen(target, target, "he", "yanzhu")  
            room:obtainCard(next_player, card_id1, false)  
            local card_id2 = room:askForCardChosen(target, target, "he", "yanzhu")  
            room:obtainCard(prev_player, card_id2, false)  
        else  
            -- 视为对其使用杀  
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)  
            slash:setSkillName("yanzhu")  
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = effect.from  
            use.to:append(target)  
            room:useCard(use)  
        end  
    end  
}  
  
-- 宴诛ViewAsSkill  
yanzhu = sgs.CreateZeroCardViewAsSkill{  
    name = "yanzhu",  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#YanzhuCard")  
    end,  
    view_as = function(self)  
        local card = YanzhuCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end  
}

xingxue = sgs.CreateTriggerSkill{  
    name = "xingxue",  
    frequency = sgs.Skill_NotFrequent,  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data) 
        if not (player and player:hasSkill(self:objectName())) then
            return ""
        end
        if player:getPhase() == sgs.Player_Finish then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)  
        local max_targets = player:getHp()  
        local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, max_targets)  
          
        -- 各摸一张牌  
        for _, target in sgs.qlist(targets) do  
            target:drawCards(1, self:objectName())  
        end  
          
        -- 依次将一张牌置于牌堆顶  
        for _, target in sgs.qlist(targets) do  
            if target:getCardCount(true) > 0 then  
                local card_id = room:askForCardChosen(target, target, "he", "xingxue")
                --local card_id = room:askForCard(target, ".!", "@xingxue-put", sgs.QVariant(), sgs.Card_MethodNone)  
                if card_id then  
                    room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_DrawPile, true)  
                end  
            end  
        end  
    end  
}

-- 添加技能  
sunxiu:addSkill(yanzhu)  
sunxiu:addSkill(xingxue)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["sunxiu"] = "孙休",  
    ["yanzhu"] = "宴诛",  
    [":yanzhu"] = "出牌阶段限一次，你可以令一名角色摸一张牌，然后其选择：1.交给其上下家各一张牌；2.视为你对其使用一张【杀】。",  
    ["xingxue"] = "兴学",   
    [":xingxue"] = "结束阶段，你可以令至多X名角色各摸一张牌，然后依次将一张牌置于牌堆顶（X为你的体力值）。",  
    ["@yanzhu"] = "宴诛：选择一名角色",  
    ["@yanzhu-give"] = "宴诛：选择两张牌分别交给上下家",  
    ["@xingxue"] = "兴学：选择至多%arg名角色",  
    ["@xingxue-put"] = "兴学：选择一张牌置于牌堆顶"  
}  
  

-- 创建武将：
wanglang = sgs.General(extension, "wanglang", "wei", 3)  -- 吴国，4血，男性  

gushe_card = sgs.CreateSkillCard{  
    name = "gushe",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select, Self)  
        return #targets == 0 and to_select ~= Self and not to_select:isKongcheng()  
    end,  
      
    feasible = function(self, targets, Self)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 执行拼点  
        local success = source:pindian(target,"gushe")  
          
        if success then  
            -- 拼点赢：获得对方一张手牌  
            if not target:isKongcheng() then  
                local card_id = room:askForCardChosen(target, target, "h", "gushe")  
                room:obtainCard(source, card_id, false)  
            end  
        else  
            -- 拼点输：给对方"鼓舌"技能  
            room:acquireSkill(target, "gushe")  
            room:setPlayerMark(target, "@gushe-temp", 1)  
        end  
    end  
}

gushe_vs = sgs.CreateZeroCardViewAsSkill{  
    name = "gushe",  
      
    view_as = function(self)  
        local card = gushe_card:clone()  
        card:setSkillName(self:objectName())
        return card
    end,  
      
    enabled_at_play = function(self, player)   
        local used_times = player:usedTimes("#gushe")  
        local max_times = 1  
          
        -- 如果有激词标记，本回合可以使用2次  
        -- 用目标修正技修正次数
        if player:getMark("@gushe-extra") > 0 then  
            max_times = 2  
        end  
        return used_times < max_times and not player:isKongcheng() 
    end  
}

gushe_clear = sgs.CreateTriggerSkill{  
    name = "#gushe-clear",  
    events = {sgs.EventPhaseEnd},  
    global = true,  
      
    can_trigger = function(self, event, room, player, data)  
        if player:getMark("@gushe-temp") > 0 and player:getPhase() == sgs.Player_NotActive then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:detachSkillFromPlayer(player, "gushe")  
        room:setPlayerMark(player, "@gushe-temp", 0)  
        return false  
    end  
}

jici = sgs.CreateTriggerSkill{  
    name = "jici",  
    events = {sgs.Pindian},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() then return "" end  
        if not player:hasSkill(self:objectName()) then return "" end  
          
        local pindian = data:toPindian()  
        -- 检查是否是该玩家参与的拼点且没赢  
        if pindian.from == player and not pindian.success then--not pindian.from_card:getNumber() > pindian.to_card:getNumber() then  
            return self:objectName()  
        elseif pindian.to == player and pindian.success then--not pindian.to_card:getNumber() > pindian.from_card:getNumber() then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local pindian = data:toPindian()  
        local winner = nil  
          
        -- 确定拼点赢家  
        if pindian.from == player then  
            winner = pindian.to  
        else  
            winner = pindian.from  
        end  
          
        -- 受到1点伤害  
        if winner and winner:isAlive() then  
            local damage = sgs.DamageStruct()  
            damage.from = winner  
            damage.to = player  
            damage.damage = 1  
            damage.reason = self:objectName()  
            room:damage(damage)  
        end  
          
        -- 摸2张牌  
        if player:isAlive() then  
            player:drawCards(2)  
        end  
          
        -- 令鼓舌本回合限2次  
        room:addPlayerMark(player, "@gushe-extra")  
          
        return false  
    end  
}

jici_clear = sgs.CreateTriggerSkill{  
    name = "#jici-clear",  
    events = {sgs.EventPhaseEnd},  
    global = true,  
      
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_NotActive and player:getMark("@gushe-extra") > 0 then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:setPlayerMark(player, "@gushe-extra", 0)  
        return false  
    end  
}

wanglang:addSkill(gushe_vs)
wanglang:addSkill(jici)

sgs.LoadTranslationTable{
    ["wanglang"] = "王朗",
    ["gushe"] = "鼓舌",  
    [":gushe"] = "出牌阶段限一次，你可以与一名角色拼点：当你赢后，其交给你一张手牌；当你没赢后，你令其获得鼓舌技能直到其下回合结束。",  
    ["@gushe-invoke"] = "你可以发动鼓舌",  
    ["~gushe"] = "选择一名角色进行拼点",
    ["jici"] = "激词",  
    [":jici"] = "当你拼点没赢后，你受到赢得角色的1点伤害，然后摸2张牌，令鼓舌本回合限2次。",  
    ["@jici-invoke"] = "你可以发动激词",
}
----------------------------我实现的王凌
--[[wangling = sgs.General(extension, "wangling", "wei", 4)  
  
mibei = sgs.CreateTriggerSkill{  
    name = "mibei",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.EventPhaseStart, sgs.CardUsed},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event==sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then 
            -- 检查是否不是手牌数最多的角色  
            local max_cards = 0  
            local players = room:getAlivePlayers()  
            for _, p in sgs.qlist(players) do  
                if p:getHandcardNum() > max_cards then  
                    max_cards = p:getHandcardNum()  
                end  
            end  
            if player:getHandcardNum() < max_cards then  
                return self:objectName()  
            end  
        elseif event==sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            room:setPlayerProperty(player, "mibei_recorded", sgs.QVariant())
        elseif event == sgs.CardUsed then  
            local use = data:toCardUse()  
            if use.from:objectName() == player:objectName() then  
                -- 检查是否使用了记录的牌  
                local recorded_card_id = player:property("mibei_recorded"):toString()  
                if recorded_card_id ~= "" then  
                    local used_card_id = use.card:getEffectiveId()  
                    if tonumber(recorded_card_id) == used_card_id then  
                        return self:objectName()  
                    end  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，必须发动  
        elseif event == sgs.CardUsed then  
            -- 询问是否弃置一张手牌来额外结算  
            if not player:isKongcheng() then  
                return room:askForSkillInvoke(player, self:objectName(), "@mibei-extra")  
            end  
        end  
        return false 
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 找到手牌数最多的其他角色  
        if event == sgs.EventPhaseStart then  
            -- 找到手牌数最多的其他角色  
            local max_cards = 0  
            local players = room:getAlivePlayers()  
            for _, p in sgs.qlist(players) do  
                if p:getHandcardNum() > max_cards then  
                    max_cards = p:getHandcardNum()  
                end  
            end  
            local max_players = sgs.SPlayerList()  
            for _, p in sgs.qlist(players) do  
                if p:getHandcardNum() == max_cards then  
                    max_players:append(p) 
                end  
            end
            
            if max_players:isEmpty() then return false end  
            
            local target = room:askForPlayerChosen(player, max_players, self:objectName(),   
                                                "@mibei-choose", false, true)  
            if not target then  
                target = max_players:at(0)  
            end  
            
            -- 发起军令  
            if target:askCommandto(self:objectName(), player) then
                -- 执行：摸牌至与其相同  
                local draw_num = target:getHandcardNum() - player:getHandcardNum()  
                if draw_num > 0 then  
                    room:drawCards(player, draw_num, self:objectName())  
                end  
            else  
                -- 不执行：展示一张手牌，使用时需弃置一张手牌  
                if not player:isKongcheng() then  
                    --local card = room:askForCardShow(player, target, self:objectName()) 
                    local card_id = room:askForCardChosen(player, player, "h",   
                        self:objectName(), false, sgs.Card_MethodNone)  
                    room:showCard(player, card_id)  
                        
                    -- 记录牌的ID  
                    room:setPlayerProperty(player, "mibei_recorded", sgs.QVariant(tostring(card_id)))  
                end  
            end  
        elseif event == sgs.CardUsed then  
            -- 额外结算：弃置一张手牌  
            --local discard_id = room:askForCardChosen(player, player, "h", self:objectName())  
            --room:throwCard(discard_id, player, player)  
            room:askForDiscard(player,self:objectName(),1,1,false,false)
            room:setPlayerProperty(player, "mibei_recorded", sgs.QVariant())
            -- 令此牌额外结算一次  
            local use = data:toCardUse()  
            local new_use = sgs.CardUseStruct()  
            new_use.card = use.card  
            new_use.from = use.from  
            new_use.to = use.to  
            room:useCard(new_use, false)  
        end  
        return false  
    end  
}

wangling:addSkill(mibei)  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
      
    ["wangling"] = "王凌",  
    ["#wangling"] = "持重的名将",  
      
    ["mibei"] = "秘备",  
    [":mibei"] = "锁定技。准备阶段，若你的手牌数不为全场最多，你令手牌数最多的一名其他角色对你发起军令。若你执行，你摸牌至与其相同；若你不执行，你展示一张手牌，本回合你使用此牌时需要弃置一张手牌，然后令此牌额外结算一次。",  
      
    ["@mibei-choose"] = "秘备：选择一名手牌数最多的其他角色",  
    ["mibei_execute"] = "执行军令",  
    ["mibei_refuse"] = "拒绝军令",  
    ["@mibei-discard"] = "秘备：你需要弃置一张手牌",  
}  
]]
----------------------------zz实现的王凌
--[[
luawangling = sgs.General(extension, "luawangling", "wei")

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
                --room:setPlayerFlag("luamibeiNoCommand")
            else
                local nowHandNum = player:getHandcardNum()
                if nowHandNum >= 5 then return false end
                player:drawCards(math.min(maxnum - nowHandNum, 5 - nowHandNum), self:objectName())
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
        if skillTriggerable(player, self:objectName()) and event == sgs.CardUsed and player:getPhase() ~= sgs.Player_NotActive then
            local use = data:toCardUse()
            if use.card:getTag("luamibeiRecord"):toInt() == 1 and not player:isKongcheng() then
                room:askForDiscard(player, self:objectName(), 1, 1, false, false, "@luamibei_discard")
                use.card:removeTag("luamibeiRecord")
                room:useCard(sgs.CardUseStruct(use.card, use.from, use.to), false)
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
extension:insertRelatedSkills("luamibei", "#luamibei_cardUsed")

-- 加载翻译表
sgs.LoadTranslationTable{
    ["luawangling"] = "王凌",
    ["luamibei"] = "秘备",
	[":luamibei"] = "锁定技，准备阶段，若你手牌数不为全场最多，你令手牌最多的一名其他角色对你发起“军令”：若你执行，你摸牌至与其相同（至多" ..
    "摸至五张）；若你不执行，你展示一张手牌，本回合你使用此牌时弃置一张手牌，然后令此牌额外结算一次（不包括延时类锦囊、闪）。",
    ["@luamibei_command"] = "秘备：选择一名手牌数最多的其他角色对你发起军令",
    ["@luamibei_discard"] = "秘备：弃置一张手牌",
}
]]
-- 创建武将：
wangyi = sgs.General(extension, "wangyi", "wei", 3)  -- 吴国，4血，男性  
zhenlie = sgs.CreateTriggerSkill{  
    name = "zhenlie",  
    events = {sgs.TargetConfirming}, --sgs.CardEffected
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  

        local use = data:toCardUse()
        if use.from and use.from ~= player and use.to:contains(player) then  
            if use.card:isKindOf("Slash") or use.card:isNDTrick() then
                return self:objectName()  
            end
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
        room:loseHp(player, 1)  -- 失去一点体力  

        local use = data:toCardUse()  
        sgs.Room_cancelTarget(use, player)
        data:setValue(use) 

        player:drawCards(1)
        -- 弃置来源一张牌
        if player:isAlive() and use.from and use.from:isAlive() and not use.from:isNude() then  
            local card_id = room:askForCardChosen(player, use.from, "he", self:objectName())  
            room:throwCard(card_id, use.from, player)  
        end            
        return false  
    end  
}  
miji = sgs.CreateTriggerSkill{  
    name = "miji",  
    frequency = sgs.Skill_Frequent,  
    events = {sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        if player:getPhase() == sgs.Player_Discard and player:isWounded() then  
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
        local lost_hp = player:getLostHp()  
          
        if lost_hp > 0 then  
            -- 显示摸牌提示  
            local msg = sgs.LogMessage()  
            msg.type = "#mijiDraw"  
            msg.from = player  
            msg.arg = lost_hp  
            msg.arg2 = self:objectName()  
            room:sendLog(msg)  
              
            player:drawCards(lost_hp, self:objectName())  
        end  
          
        return false  
    end  
}  
wangyi:addSkill(zhenlie)
wangyi:addSkill(miji)
sgs.LoadTranslationTable{
    ["wangyi"] = "王异",
    ["zhenlie"] = "贞烈",
    [":zhenlie"] = "你成为杀或非延时性锦囊的目标时，你可以失去一点体力并取消之，然后摸一张牌，弃置来源一张牌",
    ["miji"] = "秘计",  
    [":miji"] = "弃牌阶段结束后，你可以摸X张牌，X为你已损失的体力值。",  
    ["#mijiDraw"] = "%from 发动了【%arg2】，摸了 %arg 张牌",  
}

wenyang = sgs.General(extension, "wenyang", "wei", 3) -- 吴苋，蜀势力，3血，女性

-- 齐力技能  
qili = sgs.CreateTriggerSkill{  
    name = "qili",  
    frequency = sgs.Skill_NotFrequent,
    --limit_mark = "@qili",  --不是限定技
    events = {sgs.Damage},  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then return "" end  
        if player:hasUsed("#qili") then return "" end  
        --if player:getMark("@qili") > 0 then return "" end  
        local damage = data:toDamage()  
        if damage.from and damage.from:objectName() == player:objectName() then  
            return self:objectName()  
        end  
        return "" 
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            -- 标记本回合已使用。可以这样主动标记技能使用
            player:addHistory("#qili", 1)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local choices = {"draw_to_hp", "discard_recover"}  
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
        if choice == "draw_to_hp" then  
            local current_cards = player:getHandcardNum()  
            local target_cards = player:getHp()  
            if current_cards < target_cards then  
                player:drawCards(target_cards - current_cards, self:objectName())  
            end  
        elseif choice == "discard_recover" then  
            local handcards = player:getHandcards()  
            local discard_num = handcards:length()  
            if discard_num > 0 then  
                player:throwAllHandCards()  
                --room:askForDiscard(player, self:objectName(), discard_num, discard_num, false, false)  
                local recover_num = math.min(discard_num, player:getMaxHp()) - player:getHp() 
                if recover_num > 0 then  
                    local recover = sgs.RecoverStruct()  
                    recover.who = player  
                    recover.recover = recover_num  
                    room:recover(player, recover)  
                end  
            end  
        end  
        return false  
    end  
}  
  
duoqi = sgs.CreateTriggerSkill{  
    name = "duoqi",  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@duoqi",  
    events = {sgs.EventPhaseChanging},  
    can_trigger = function(self, event, room, player, data)   
        local change = data:toPhaseChange()  
        if change.to ~= sgs.Player_NotActive then return "" end           
        
        if player and player:getHandcardNum() == 0 then
            wenyang = room:findPlayerBySkillName(self:objectName())
            if wenyang and wenyang:isAlive() and wenyang:getMark("@duoqi") > 0 then
                return self:objectName(), wenyang:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:setPlayerMark(ask_who, "@duoqi", 0)  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        ask_who:gainAnExtraTurn()  
        return false  
    end  
}  
  
wenyang:addSkill(qili)  
wenyang:addSkill(duoqi)  
  
-- 在翻译表中添加  
sgs.LoadTranslationTable{  
    -- ... 现有翻译 ...  
    ["wenyang"] = "文鸯",  
    ["qili"] = "齐力",  
    [":qili"] = "每回合限一次，当你造成伤害后，你可以选择：1.摸牌至体力值；2.弃置所有手牌，然后恢复体力至X点（X为以此法弃置的牌数）。",  
    ["@qili"] = "齐力",  
    ["duoqi"] = "夺气",  
    [":duoqi"] = "限定技，任意角色回合结束时，若当前回合角色没有手牌，你可以获得一个额外回合。",  
    ["@duoqi"] = "夺气",  
    ["draw_to_hp"] = "摸牌至体力值",  
    ["discard_recover"] = "弃置所有手牌并恢复体力"  
}

wuxian = sgs.General(extension, "wuxian", "shu", 3, false) -- 吴苋，蜀势力，3血，女性

YirongCard = sgs.CreateSkillCard{  
    name = "YirongCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:isKongcheng()
    end,  
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        local source = effect.from  
        local target = effect.to  
          
        -- 失去一点体力  
        room:loseHp(source, 1)  
          
        -- 查看目标所有手牌  
        local handcards = target:getHandcards()  
        if not handcards:isEmpty() then  
            local cards = sgs.QList2Table(handcards)  
            local card_to_top = room:askForCardChosen(source, target, "h", "yirong", true, sgs.Card_MethodNone)  
            if card_to_top then  
                -- 将选择的牌置于牌堆顶  
                room:moveCardTo(sgs.Sanguosha:getCard(card_to_top), nil, sgs.Player_DrawPile, true)  
            end  
        end  
    end  
}  
  
-- 移荣ViewAsSkill  
yirong = sgs.CreateZeroCardViewAsSkill{  
    name = "yirong",  
    enabled_at_play = function(self, player)  
        return player:getHp() > 0  
    end,  
    view_as = function(self)  
        local card = YirongCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end  
}

guixiang = sgs.CreateTriggerSkill{  
    name = "guixiang",  
    frequency = sgs.Skill_NotFrequent,  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish  then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data) 
    end,  
    on_effect = function(self, event, room, player, data)  
        local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@guixiang", true, true)   
        if target then  
            -- 进行判定  
            local judge = sgs.JudgeStruct()  
            judge.who = target  
            judge.reason = self:objectName()  
            judge.play_animation = false  
            room:judge(judge)  
              
            local judge_card = judge.card  
            if judge_card then  
                local card_to_use = nil  
                  
                if judge_card:getSuit() == sgs.Card_Heart then  
                    -- 红桃：视为使用桃  
                    card_to_use = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)  
                elseif judge_card:getTypeId() == sgs.Card_TypeBasic or   
                       (judge_card:getTypeId() == sgs.Card_TypeTrick and not judge_card:isKindOf("DelayedTrick")) then  
                    -- 基本牌或普通锦囊牌：视为使用它  
                    card_to_use = sgs.Sanguosha:cloneCard(judge_card:objectName(), sgs.Card_SuitToBeDecided, -1)  
                end  
                  
                if card_to_use then  
                    use_target = room:askForPlayerChosen(target, room:getAlivePlayers(), self:objectName()) 
                    card_to_use:setSkillName(self:objectName())  
                    local use = sgs.CardUseStruct()  
                    use.card = card_to_use  
                    use.from = target  
                    use.to:append(use_target)  
                    room:useCard(use)  
                end  
            end  
        end  
    end  
}

wuxian:addSkill(yirong)  
wuxian:addSkill(guixiang)  
  
-- 在翻译表中添加  
sgs.LoadTranslationTable{  
    -- ... 现有翻译 ...  
    ["wuxian"] = "吴苋",  
    ["yirong"] = "移荣",  
    [":yirong"] = "出牌阶段，你可以失去一点体力，并查看一名角色的所有手牌，然后选择一张置于牌堆顶。",  
    ["YirongCard"] = "移荣",  
    ["guixiang"] = "贵相",  
    [":guixiang"] = "结束阶段，你可以令一名角色进行判定，若判定牌是基本牌或普通锦囊牌，其可以视为使用它；若为红桃，改为可以视为使用桃。",  
    ["@guixiang"] = "贵相：选择一名角色进行判定"  
}


xujing = sgs.General(extension, "xujing", "shu", 3) -- 吴苋，蜀势力，3血，女性

-- 许名技能卡  
XumingCard = sgs.CreateSkillCard{  
    name = "XumingCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:isFriendWith(sgs.Self)
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        local source = effect.from  
        local target = effect.to  
          
        -- 视为使用远交近攻  
        local yuanjiao = sgs.Sanguosha:cloneCard("befriend_attacking", sgs.Card_SuitToBeDecided, -1)  
        yuanjiao:setSkillName("xuming")  
        local use = sgs.CardUseStruct()  
        use.card = yuanjiao  
        use.from = source  
        use.to:append(target)  
        room:useCard(use)  
        
        -- 让玩家选择遍历方向  
        local direction = room:askForChoice(source, "xuming_direction", "clockwise+counterclockwise")  
          
        -- 根据选择计算路径  
        local path_players = {}            
        if direction == "counterclockwise" then 
            -- 逆时针遍历  
            local current = source:getNextAlive()
            while current ~= target do  
                table.insert(path_players, current)  --这里不能选自己
                current = current:getNextAlive()  
                if current == source then break end  
            end  
        else  
            -- 顺时针遍历  
            local current = target:getNextAlive()--就是这个函数有问题
            while current ~= source do  
                table.insert(path_players, current)  --这里不能选自己
                current = current:getNextAlive()  
                if current == target then break end  
            end  
        end  
          
        -- 所有路径上的角色摸牌  
        for _, player in ipairs(path_players) do  
            player:drawCards(1, "xuming")  
        end  
    end  
}  
  
-- 许名ViewAsSkill  
xuming = sgs.CreateOneCardViewAsSkill{  
    name = "xuming",  
    filter_pattern = "TrickCard",  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#XumingCard")  
    end,  
    view_as = function(self, card)  
        local xuming_card = XumingCard:clone()  
        xuming_card:addSubcard(card)  
        xuming_card:setShowSkill(self:objectName())  
        return xuming_card  
    end  
}

-- 靖德技能  
jingde = sgs.CreateTriggerSkill{  
    name = "jingde",  
    frequency = sgs.Skill_NotFrequent,  
    events = {sgs.DamageInflicted},  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then return "" end  
        local damage = data:toDamage()  
        return self:objectName()  
    end,  
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local choices = {}  
          
        -- 检查自己是否有未明置的武将牌  
        if not player:hasShownGeneral1() and player:canShowGeneral("h") then  
            table.insert(choices, "self_show_head_general")  
        end  
        if not player:hasShownGeneral2() and player:canShowGeneral("d") then  
            table.insert(choices, "self_show_deputy_general")  
        end            
        -- 检查来源是否有未明置的武将牌  
        if damage.from and not damage.from:hasShownGeneral1() and damage.from:canShowGeneral("h") then  
            table.insert(choices, "source_show_head_general")  
        end  
        if damage.from and not damage.from:hasShownGeneral2() and damage.from:canShowGeneral("d") then  
            table.insert(choices, "source_show_deputy_general")  
        end 

        if #choices == 0 then return false end  
          
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)  
        if choice ~= "" then  
            player:setTag("JingdeChoice", sgs.QVariant(choice))  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local choice = player:getTag("JingdeChoice"):toString()  
          
        if choice == "self_show_head_general" and not player:hasShownGeneral1() then  
            -- 明置自己的武将牌  
            player:showGeneral(true)  
        elseif choice == "self_show_deputy_general" and not player:hasShownGeneral2() then  
            player:showGeneral(false)  

        elseif choice == "source_show_head_general" and not damage.from:hasShownGeneral1() then  
            -- 明置自己的武将牌  
            damage.from:showGeneral(true)  
        elseif choice == "source_show_deputy_general" and not damage.from:hasShownGeneral2() then  
            damage.from:showGeneral(false)
        end  
          
        -- 伤害-1  
        damage.damage = damage.damage - 1  
        data:setValue(damage)  
        if damage.damage <= 0 then  
            return true -- 阻止伤害  
        end  
        return false  
    end  
}

xujing:addSkill(xuming)  
xujing:addSkill(jingde)  
  
-- 在翻译表中添加  
sgs.LoadTranslationTable{  
    -- ... 现有翻译 ...  
    ["xujing"] = "许靖",  
    ["xuming"] = "许名",  
    [":xuming"] = "出牌阶段限一次，你可以将一张锦囊牌当【远交近攻】使用，然后令你与目标一条路径之间的所有角色各摸一张牌。",  
    ["XumingCard"] = "许名",  
    ["xuming_direction"] = "许名：选择遍历方向",  
    ["clockwise"] = "顺时针",  
    ["counterclockwise"] = "逆时针",
    ["jingde"] = "靖德",  
    [":jingde"] = "当你受到伤害时，你可以明置自己或伤害来源的一张武将牌，令此伤害-1。",  
    ["self_show_head_general"] = "明置自己的主将",  
    ["self_show_deputy_general"] = "明置自己的副将",
    ["source_show_head_general"] = "明置伤害来源的主将",  
    ["source_show_deputy_general"] = "明置伤害来源的副将",
}
--[[
-- 创建武将：
luayufan = sgs.General(extension, "luayufan", "wu", 3)

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
extension:insertRelatedSkills("luazongxuan", "#luazongxuan_remove")

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
]]
zhangchangpu = sgs.General(extension, "zhangchangpu", "wei", 3, false)  

xingshen = sgs.CreateTriggerSkill{  
    name = "xingshen",  
    events = {sgs.Damaged},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local choices = {}  
        if not player:isKongcheng() then  
            table.insert(choices, "discard")  
        end  
        table.insert(choices, "draw")  
        table.insert(choices, "cancel")  
          
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
        if choice ~= "cancel" then  
            player:setTag("zhangchangpu_choice", sgs.QVariant(choice))  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        local choice = player:getTag("zhangchangpu_choice"):toString()  
          
        if choice == "draw" then  
            player:drawCards(1)  
        elseif choice == "discard" and not player:isKongcheng() then  
            room:askForDiscard(player, self:objectName(), 1, 1, false, true)  
        end  
          
        -- 展示所有手牌  
        room:showAllCards(player)  
          
        -- 检查手牌花色是否与伤害牌花色不同  
        local damage_card = damage.card  
        if not damage_card then
            return false
        end
        local can_heal = true  
          
        if damage_card then  
            local damage_suit = damage_card:getSuit()  
            local handcards = player:getHandcards()  
            for _, card in sgs.qlist(handcards) do  
                if card:getSuit() == damage_suit then  
                    can_heal = false  
                    break  
                end  
            end  
        end  
          
        if can_heal then  
            local others = room:getOtherPlayers(player)  
            local target = room:askForPlayerChosen(player, others, self:objectName(), "选择一名其他角色令其回复1点体力", true)  
            if target then  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(target, recover)  
            end  
        end  
          
        return false  
    end  
}

yanjiao_card = sgs.CreateSkillCard{  
    name = "yanjiao_card",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select, Self)  
        return #targets == 0 and to_select:objectName() ~= Self:objectName()   
               and (to_select:getKingdom() == Self:getKingdom() and to_select:getRole()~="careerist" and Self:getRole()~="careerist")
    end,  
    feasible = function(self, targets, Self)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 造成1点伤害  
        local damage = sgs.DamageStruct()  
        damage.from = source  
        damage.to = target  
        damage.damage = 1  
        room:damage(damage)  
          
        -- 令其摸2张牌  
        if target:isAlive() then  
            target:drawCards(2)  
        end  
    end  
}  
  
-- 技能2的视为技  
yanjiao = sgs.CreateZeroCardViewAsSkill{  
    name = "yanjiao",  
    view_as = function(self)  
        local card = yanjiao_card:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#yanjiao_card")  
    end  
}
zhangchangpu:addSkill(xingshen)  
zhangchangpu:addSkill(yanjiao)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["zhangchangpu"] = "张昌蒲",  
    ["&zhangchangpu"] = "张昌蒲",  
    ["#zhangchangpu"] = "沧海遗珠",  
    ["~zhangchangpu"] = "海潮退去，唯余沧桑...",  
      
    ["xingshen"] = "省身",  
    [":xingshen"] = "你受到伤害后，你可以选择摸1张牌或弃置1张手牌，然后展示所有手牌，若所有手牌的花色和伤害牌都不相同，你可以令一名其他角色恢复一点体力。",  
      
    ["yanjiao"] = "严教",   
    [":yanjiao"] = "出牌阶段限一次，你可以对一名同势力其他角色造成1点伤害，令其摸2张牌。",  

}  

-- 创建武将：
zhonghui_wei = sgs.General(extension, "zhonghui_wei", "wei", 3)  -- 吴国，4血，男性  

fushuCard = sgs.CreateSkillCard{  
    name = "fushu",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 令目标视为使用远交近攻  
        local yuanjiao = sgs.Sanguosha:cloneCard("befriend_attacking", sgs.Card_NoSuit, 0)  
        yuanjiao:setSkillName("fushu")  
   
        -- 选择与目标势力相同的角色作为伤害目标  
        local same_kingdom_players = sgs.SPlayerList()
        local different_kingdom_players = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
            if p:hasShownOneGeneral() and (p:getKingdom() == target:getKingdom() and p:objectName() ~= target:objectName() and p:getRole()~="careerist") then  
                --not sgs.isAnjiang(p)
                --sgs.ai_explicit[p:objectName()] ~= "unknown"
                same_kingdom_players:append(p)
            elseif not p:isFriendWith(target) then --p:getKingdom() ~= target:getKingdom() then
                different_kingdom_players:append(p)
            end  
        end  
        if not different_kingdom_players:isEmpty() then
            local yuanjiao_target = room:askForPlayerChosen(target, different_kingdom_players, "fushu", "@fushu-yuanjiao:" .. target:objectName())
            local use = sgs.CardUseStruct()  
            use.card = yuanjiao  
            use.from = target  
            use.to:append(yuanjiao_target) --可能是一个列表
            --use.to = yuanjiao_target
            room:useCard(use)  
        end
        if not same_kingdom_players:isEmpty() then  
            local victim = room:askForPlayerChosen(source, same_kingdom_players, "fushu", "@fushu-damage:" .. target:objectName())  
              
            -- 造成伤害  
            local damage = sgs.DamageStruct()  
            damage.from = target  
            damage.to = victim  
            damage.damage = 1  
            damage.reason = "fushu"  
              
            room:damage(damage)  
        end  
    end  
}  
  
-- 扶术视为技  
fushu = sgs.CreateZeroCardViewAsSkill{  
    name = "fushu",  
      
    view_as = function(self)  
        return fushuCard:clone()  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#fushu")  
    end  
}


zhonghui_wei:addSkill(fushu)
sgs.LoadTranslationTable{
    ["zhonghui_wei"] = "钟会",
    ["fushu"] = "扶术",  
    [":fushu"] = "出牌阶段限一次。你可以令一名角色视为使用一张远交近攻，然后其对你指定的另一名与其势力相同的角色造成一点伤害。",  
    ["@fushu-damage"] = "请选择一名与 %src 势力相同的角色，令 %src 对其造成一点伤害",
}

return {extension}