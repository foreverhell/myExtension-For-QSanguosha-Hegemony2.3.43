-- 创建扩展包  
extension = sgs.Package("canghai",sgs.Package_GeneralPack)  
local skills = sgs.SkillList()

caifuren = sgs.General(extension, "caifuren", "qun", 3, false) -- 吴苋，蜀势力，3血，女性

qieting = sgs.CreateTriggerSkill{  
    name = "qieting",  
    frequency = sgs.Skill_Frequent,  
    events = {sgs.CardUsed, sgs.EventPhaseStart}, -- 结束阶段触发  
      
    can_trigger = function(self, event, room, player, data)            
        -- 检查是否是其他角色的结束阶段  
        local current = room:getCurrent()  
        if current:hasSkill(self:objectName()) then return ""  end  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()
            if use.from ~= current then return "" end
            if use.card and use.to then  
                for _, p in sgs.qlist(use.to) do  
                    if p:objectName() ~= current:objectName() then  
                        current:setFlags("qieting_used_card_to_others")  
                        break  
                    end  
                end  
            end  
            return ""
        end  

        if not current or current:isDead() or current:getPhase() ~= sgs.Player_Finish then  return ""  end      
          
        -- 检查该角色本回合是否对除其外的角色使用过牌  
        if current:hasFlag("qieting_used_card_to_others") then  
            return ""  
        end  
        local owner = room:findPlayerBySkillName(self:objectName())
        return self:objectName(), owner:objectName()
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local current = room:getCurrent()  
        local _data = sgs.QVariant()  
        _data:setValue(current)  
          
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local current = room:getCurrent()  
          
        -- 检查目标是否有装备牌  
        local equips = current:getEquips()  
        local has_equips = not equips:isEmpty()  
          
        local choices = "draw"  
        if has_equips then  
            choices = "draw+move"  
        end  
          
        local choice = room:askForChoice(ask_who, self:objectName(), choices)  
          
        if choice == "draw" then  
            -- 摸1张牌  
            ask_who:drawCards(1, self:objectName())  
        elseif choice == "move" then  
            -- 移动装备区1张牌到自己的装备区  
            local card_id = room:askForCardChosen(ask_who, current, "e", self:objectName())  
            local card = sgs.Sanguosha:getCard(card_id)  
                
            -- 移动装备  
            room:moveCardTo(card, ask_who, sgs.Player_PlaceEquip,   
                sgs.CardMoveReason(sgs.CardMoveReason.S_REASON_TRANSFER, ask_who:objectName(), current:objectName(), self:objectName(), ""))  
        end  
          
        return false  
    end  
}  
-- 技能2：献州（限定技）  
xianzhouCard = sgs.CreateSkillCard{  
    name = "xianzhou_card",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select, player)  
        return #targets == 0 and to_select:objectName() ~= player:objectName()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local equips = source:getEquips()  
          
        if equips:isEmpty() then return false end  
          
        local equip_count = 0  
        local equip_ids = sgs.IntList()
          
        -- 收集所有装备牌  
        for _, card in sgs.qlist(equips) do  
            equip_ids:append(card:getEffectiveId())  
            equip_count = equip_count + 1  
        end  
          
        -- 将装备交给目标  
        local move = sgs.CardsMoveStruct()  
        move.card_ids = equip_ids  
        move.from = source  
        move.from_place = sgs.Player_PlaceEquip  
        move.to = target  
        move.to_place = sgs.Player_PlaceEquip  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason.S_REASON_GIVE, source:objectName(), target:objectName(), "xianzhou", "")  
          
        room:moveCardsAtomic(move, false)  
          
        -- 目标选择攻击范围内的角色造成伤害  
        if equip_count > 0 then  
            local damage_targets = sgs.SPlayerList()
            local victims = room:getAlivePlayers()  
              
            for _, victim in sgs.qlist(victims) do  
                if victim:objectName() ~= target:objectName() and target:inMyAttackRange(victim) then  
                    damage_targets:append(victim)  
                end  
            end  
              
            local max_targets = math.min(equip_count, damage_targets:length())  
            if max_targets > 0 then  
                --至多 max_targets 名
                local selected_targets = room:askForPlayersChosen(source,  damage_targets, self:objectName(), 0, max_targets, "请选择玩家", false)
    
                -- 造成伤害  
                for _, victim in sgs.qlist(selected_targets) do  
                    local damage = sgs.DamageStruct()  
                    damage.from = target  
                    damage.to = victim  
                    damage.damage = 1  
                    damage.reason = "xianzhou"  
                    room:damage(damage)  
                end  
                  
                -- 蔡夫人回复等量体力  
                local recover = sgs.RecoverStruct()  
                recover.recover = selected_targets:length()
                recover.who = source  
                room:recover(source, recover)  
            end  
        end  
        room:setPlayerMark(source, "@xianzhou", 0)
        return false  
    end  
}  
  
xianzhou = sgs.CreateZeroCardViewAsSkill{  
    name = "xianzhou",  
    limit_mark = "@xianzhou",       
    view_as = function(self)  
        local card = xianzhouCard:clone()  
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)  
        return player:getMark("@xianzhou") > 0 and not player:getEquips():isEmpty()  
    end
}  
  
-- 添加技能到武将  
caifuren:addSkill(qieting)  
caifuren:addSkill(xianzhou)  

sgs.LoadTranslationTable{
    ["caifuren"] = "蔡夫人",  
    ["#caifuren"] = "荆州的妇人",  
    ["&caifuren"] = "蔡夫人",  
    ["illustrator:caifuren"] = "未知",  
    
    ["qieting"] = "窃听",  
    [":qieting"] = "其他角色的结束阶段，若其本回合未对除其外的角色使用牌，你可以（1）摸1张牌（2）将其装备区1张牌移动到你的装备区。",  
    ["qieting:draw"] = "摸1张牌",  
    ["qieting:move"] = "移动其1张装备牌",  
    
    ["xianzhou"] = "献州",  
    [":xianzhou"] = "限定技，出牌阶段，你可以将装备区所有牌交给一名其他角色，其对攻击范围内至多等量角色造成1点伤害，然后你恢复等量体力。",  
    ["@xianzhou"] = "献州",  
    ["@xianzhou-damage"] = "献州：请选择攻击范围内的一名角色造成1点伤害",
}

caiyong = sgs.General(extension, "caiyong", "qun", 3) -- 吴苋，蜀势力，3血，女性
zhudian = sgs.CreateTriggerSkill{  
    name = "zhudian",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        if player:isNude() then return "" end
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
        local use = data:toCardUse()
        if room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@zhudian-recast") then
            player:drawCards(1,self:objectName())
            local card = player:getHandcards():last()
            if card:isBlack() and card:getSuit() ~= use.card:getSuit() then --黑色，并且花色不同，即黑色的另一种花色
                room:showCard(player, card:getId()) --展示
                player:drawCards(1,self:objectName()) --再摸1张
            end
        end
        return false  
    end  
}


botongCard = sgs.CreateSkillCard{  
    name = "botongCard",  
    target_fixed = true,  
    will_throw = true,  
      
    on_use = function(self, room, source, targets) 
        local choices = {}
        if sgs.Slash_IsAvailable(source) then
            table.insert(choices, "slash")
        end
        if sgs.Analeptic_IsAvailable(source) then
            table.insert(choices, "analeptic")
        end
        if source:isWounded() then
            table.insert(choices, "peach")
        end
        if #choices == 0 then return false end
        choice=room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
        card = sgs.Sanguosha:cloneCard(choice)  
        card:setSkillName("botong")
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

botongVS = sgs.CreateViewAsSkill{  
    name = "botong",  
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then
            return true
        else
            for _, c in ipairs(selected) do
                if to_select:getSuit() == c:getSuit() then
                    return false
                end
            end
            return true
        end
    end,  
    view_as = function(self, cards)
        if #cards ~= 4 then return nil end
        local card_name = ""  
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()  
        if pattern == "slash" then  
            card_name = "slash"  
        elseif pattern == "jink" then  
            card_name = "jink"  
        elseif string.find(pattern,"peach") then  
            card_name = "peach"  
        elseif string.find(pattern,"analeptic") then  
            card_name = "analeptic"  
        end  
        local view_as_card = nil
        if card_name ~= "" then
            view_as_card = sgs.Sanguosha:cloneCard(card_name)  
        else
            view_as_card = botongCard:clone()
        end
        for _, c in ipairs(cards) do
            view_as_card:addSubcard(c)
        end
        view_as_card:setSkillName(self:objectName())  
        view_as_card:setShowSkill(self:objectName())  
        return view_as_card  
    end,  
      
    enabled_at_play = function(self, player)   
        return true
    end,
    enabled_at_response = function(self, player, pattern)   
        return pattern == "slash" or pattern == "jink" or string.find(pattern,"peach") or string.find(pattern,"analeptic")
    end,

}

botong = sgs.CreateTriggerSkill{  
    name = "botong",  
    view_as_skill = botongVS,  
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
          
        if card and card:getSkillName() == "botong" then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data) 
    end,  
    on_effect = function(self, event, room, player, data) 
        local card = nil
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else -- sgs.CardResponded  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
        local subcards = card:getSubcards() --分配这些子卡


        for _,c in sgs.qlist(subcards) do
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if player:isFriendWith(p) then  
                    targets:append(p)  
                end  
            end             
            if targets:isEmpty() then return false end  
            
            local target = room:askForPlayerChosen(player, targets, self:objectName(),   
                                                "@botong-choose", false, true)  
            if target and target:isAlive() then
                room:obtainCard(target, c)
            end
        end
        return false  
    end  
}
caiyong:addSkill(zhudian)
caiyong:addSkill(botong)
sgs.LoadTranslationTable{
    ["caiyong"] = "蔡邕",
    ["zhudian"] = "铸典",
    [":zhudian"] = "当你成为黑色牌的目标时，你可以重铸1张牌，若摸的牌为黑色的另一种花色，你摸1张牌",
    ["botong"] = "博通",
    [":botong"] = "你可以将4种不同花色的牌当任意基本牌使用或打出，然后你可以将这些牌分配给任意名势力相同的其他角色",
}

--[[
-- 创建董允武将  
dongyun = sgs.General(extension, "dongyun", "shu", 3)

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
                room:askForDiscard(target, self:objectName(), 1, 1, false, false)  
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
    [":bingzheng"] = "回合结束时，你可以令一名手牌数不等于体力值的角色摸一张牌或弃一张手牌，然后若其手牌数等于体力值，你摸一张牌",  
    ["sheyan"] = "设宴",  
    [":sheyan"] = "当你每回合首次成为普通锦囊的目标时，你可以令此牌的目标＋1或-1，目标数至少为1。",  
}  
]]
guanping = sgs.General(extension, "guanping", "shu", 4)  

zuolie = sgs.CreateTriggerSkill{  
    name = "zuolie",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local source = room:findPlayerBySkillName(self:objectName())  
        if not (source and source:isAlive() and source:hasSkill(self:objectName())) then  
            return ""  
        end
        if source:hasFlag("zuolie_used") then return "" end
        local current = room:getCurrent()
        local use = data:toCardUse()  
        if current ~= use.from then return "" end
        -- 检查是否是杀  
        local card = use.card  
        if card and card:isKindOf("Slash") then  
            return self:objectName(), source:objectName()
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:notifySkillInvoked(ask_who, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse() 
        local card = room:askForCard(ask_who, ".|red", "@zuolie-discard", data, sgs.Card_MethodDiscard)  
        if card then  
            room:setPlayerFlag(ask_who, "zuolie_used")
            room:setPlayerFlag(use.from, "zuolie_slash")
            if card:getSuit()==use.card:getSuit() then
                ask_who:drawCards(1, self:objectName())
                if card:getNumber()==use.card:getNumber() then
                    room:setPlayerMark(ask_who, "@jiezhong", 1)
                end
            end
        end
        return false  
    end  
}

zuolie_targetmod = sgs.CreateTargetModSkill{  
    name = "#zuolie-slash",  
    residue_func = function(self, player, card)  
        if player:hasFlag("zuolie_slash") and card and card:isKindOf("Slash") then  
            return 1 
        end  
        return 0  
    end  
}



jiezhong = sgs.CreateTriggerSkill{  
    name = "jiezhong",  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@jiezhong",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            if player and player:isAlive() and player:hasSkill(self:objectName())   
                and player:getPhase() == sgs.Player_Start
                and player:getMark("@jiezhong") > 0 then  
                return self:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            return player:askForSkillInvoke(self:objectName(),data)
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(),   
                self:objectName(), "@jiezhong-invoke")  
            if target then
                local num = target:getMaxHp() - target:getHandcardNum()
                if num > 0 then
                    target:drawCards(num, self:objectName())
                end
                room:removePlayerMark(player, "@jiezhong")
            end
        end  
        return false  
    end  
}
guanping:addSkill(zuolie)  
guanping:addSkill(zuolie_targetmod)
guanping:addSkill(jiezhong)
sgs.LoadTranslationTable{
    ["guanping"] = "关平",
    ["zuolie"] = "佐烈",  
    [":zuolie"] = "每回合限一次。一名角色于其出牌阶段使用杀时，你可以弃置1张红色牌，令其本回合使用杀次数+1。若弃置的牌与此杀：花色相同，你摸1张牌;花色和点数都相同，你重置【竭忠】",  
    ["jiezhong"] = "竭忠",
    [":jiezhong"] = "限定技。准备阶段，你可以令一名角色摸牌至体力上限"
}

gongsunyuan = sgs.General(extension, "gongsunyuan_canghai", "qun", 4)  

huaierCard = sgs.CreateSkillCard{  
    name = "huaierCard",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)   
        --展示所有手牌
        room:showAllCards(source)         
        -- 选择一种颜色  
        local handcards = source:getHandcards()  
        if handcards:isEmpty() then return end  
          
        local red_cards = {}  
        local black_cards = {}  
          
        for _, card in sgs.qlist(handcards) do  
            if card:isRed() then  
                table.insert(red_cards, card:getEffectiveId())  
            elseif card:isBlack() then  
                table.insert(black_cards, card:getEffectiveId())  
            end  
        end  
          
        local choices = {}  
        if #red_cards > 0 then table.insert(choices, "red") end  
        if #black_cards > 0 then table.insert(choices, "black") end  
        if #choices ~= 2 then return false end
        if #choices > 0 then  
            local choice = room:askForChoice(source, "huaier", table.concat(choices, "+"))  
            local cards_to_bottom = {}  
              
            if choice == "red" then  
                cards_to_bottom = red_cards  
            else  
                cards_to_bottom = black_cards  
            end  
              
            if #cards_to_bottom > 0 then  
                -- 将选定的牌置于弃牌堆  
                local move = sgs.CardsMoveStruct()  
                move.card_ids = sgs.IntList()  
                for _, id in ipairs(cards_to_bottom) do  
                    move.card_ids:append(id)  
                end  
                move.from = source  
                move.from_place = sgs.Player_PlaceHand  
                move.to = nil  
                move.to_place = sgs.Player_DiscardPile  
                move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "huaier", "")  
                room:moveCardsAtomic(move, true)  

                local targets = room:askForPlayersChosen(source, room:getOtherPlayers(source),   
                    self:objectName(), 0, #cards_to_bottom, "@huaier-choose", true)
                for _, target in sgs.qlist(targets) do
                    local card_id = room:askForCardChosen(source, target, "hej", self:objectName())
                    room:obtainCard(source, card_id)
                end
                if targets:length() >= 2 then
                    room:loseHp(source, 1)
                end
            end  
        end  
    end  
}  
  
-- 备预视为技能  
huaier = sgs.CreateZeroCardViewAsSkill{  
    name = "huaier",  
    view_as = function(self)  
        card = huaierCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#huaierCard")  
    end  
}

gongsunyuan:addSkill(huaier)

sgs.LoadTranslationTable{  
    ["gongsunyuan_canghai"] = "公孙渊",
    ["huaier"] = "怀二",  
    [":huaier"] = "出牌阶段限一次。你可以展示所有手牌，若包含2种颜色，你可以弃置其中1中颜色所有手牌，然后获得至多等量名其他角色各1张牌，若获得的牌数大于等于2，你失去1点体力",  
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
            duel:deleteLater()
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
            slash:deleteLater()
            duel:deleteLater()
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
                card_to_use:deleteLater()
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
        local card = mouzhu_card:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
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
        local x = player:getCardCount(true)  
          
        if x <= 0 then return false end  
          
        -- 弃置杀死你的角色至多X张牌  
        local to_discard = math.min(x, killer:getCardCount(true))  
        for i = 1, to_discard do
            local card_id = room:askForCardChosen(player, killer, "he", "yanhuo")
            room:throwCard(card_id, killer, player)
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

huanghao = sgs.General(extension, "huanghao", "shu", 3)
qinqing = sgs.CreateTriggerSkill{  
    name = "qinqing",
    events = {sgs.CardsMoveOneTime},  --集合，可以有多个触发条件
    frequency = sgs.Skill_Frequent,         
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        if event == sgs.CardsMoveOneTime then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then --and reasonx ~= sgs.CardMoveReason_S_REASON_RECAST then
                        if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
                            if move.from and move.from:isAlive() and move.from:getPhase() ~= sgs.Player_Discard and player:objectName()==move.from:objectName() and not move.from:hasFlag("qinqing_recast") then
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
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if not p:isNude() then  
                targets:append(p)  
            end  
        end  
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@qinqing-target")  --选的角色必须有牌
        if target then
            --为了让重铸时不反复触发这个技能，
            room:setPlayerFlag(target, "qinqing_recast")
            room:askForDiscard(target, self:objectName(), 1, 1, false, true)
            room:setPlayerFlag(target, "-qinqing_recast")
            --[[
            local card = room:askForCard(target, ".|.|.|.", "选择一张牌重铸")  
            if not card then return false end
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, target:objectName(), "", self:objectName(), "")  --原因，卡牌移动来源的玩家，卡牌移动目标的玩家，导致移动的技能，其他事件名称
            -- 方法1：直接使用 CardMoveReason  
            --room:throwCard(card, reason, target)  
            -- 方法2：使用 moveCardTo（推荐）  
            room:moveCardTo(card, target, nil, sgs.Player_DiscardPile, reason, true)  
            ]]
            target:drawCards(1,self:objectName())
            if player:isFriendWith(target) and player:getMark("qinqing_transform")==0 then
                room:transformDeputyGeneral(target)
                room:setPlayerMark(player,"qinqing_transform",1)
            end
        end
        return false  
    end,
}   

huisheng = sgs.CreateTriggerSkill{  
    name = "huisheng",   
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:isKongcheng() and not player:hasFlag("huisheng_used") then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data) -- 自动触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()
        local card_id = room:askForCardChosen(damage.from, player, "h", self:objectName(), true)
        room:obtainCard(damage.from, card_id)
        room:setPlayerFlag(player, "huisheng_used")
        return true -- 返回true表示阻止伤害  
    end  
}  
huanghao:addSkill(qinqing)
huanghao:addSkill(huisheng)
sgs.LoadTranslationTable{
    ["huanghao"] = "黄皓",
    ["qinqing"] = "寝情",
    [":qinqing"] = "当你于弃牌阶段外因弃置失去牌后，你可以令一名角色重铸一张牌；若其于你势力相同，你可以令其变更副将（此效果限一次）",
    ["huisheng"] = "贿生",
    [":huisheng"] = "每回合限一次。当你受到伤害时，你可以令伤害来源查看并获得你1张手牌，然后防止此伤害",
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
        return player:getHandcardNum() == 1 --and not player:hasUsed("#gue")  --player:usedTimes("ViewAsSkill_gueCard")==0
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
        duel:deleteLater()
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


jianyong = sgs.General(extension, "jianyong", "shu", 3)

qiaoshuoCard = sgs.CreateSkillCard{  
    name = "qiaoshuoCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        if #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() and to_select:hasShownOneGeneral() then
            if to_select:getRole() == "careerist" then return not to_select:hasFlag("qiaoshuo") end --是野心家，没选过就行
            if to_select:getRole() ~= "careerist" then --不是野心家，没选过这个势力
                return not sgs.Self:hasFlag("qiaoshuo" .. to_select:getKingdom())
            end
        end
        return false
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        if target:getRole() == "careerist" then --是野心家，给目标设标记，避免重复选择
            room:setPlayerFlag(target, "qiaoshuo")
        elseif target:getRole() ~= "careerist" then --不是野心家，给自己设这个势力的标记，避免重复选择相同势力
            room:setPlayerFlag(source, "qiaoshuo" .. target:getKingdom())
        end
        -- 进行拼点  
        local success = source:pindian(target, "qiaoshuo")  
        if success then  --赢，设置标记，下次使用基本牌、锦囊牌，目标加减1（用完之后，标记清除）
            room:setPlayerFlag(source, "qiaoshuo_win")
        else --没赢，本回合不能使用锦囊，本回合此技能失效
            room:setPlayerCardLimitation(source, "use", "TrickCard", true)  --true表示单回合标记，会自动清除
            room:setPlayerFlag(source, "qiaoshuo_lose")
        end  
    end  
}  
  
-- 匡合技能  
qiaoshuoVS = sgs.CreateZeroCardViewAsSkill{  
    name = "qiaoshuo",  
    view_as = function(self, cards)  
        local card = qiaoshuoCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:isKongcheng() and not player:hasFlag("qiaoshuo_lose")
    end  
}


qiaoshuo = sgs.CreateTriggerSkill{  
    name = "qiaoshuo",
    events = {sgs.CardUsed},  --集合，可以有多个触发条件
    view_as_skill = qiaoshuoVS,
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        if not player:hasFlag("qiaoshuo_win") then return "" end --必须赢了
        if event == sgs.CardUsed then
            local use = data:toCardUse()  
            if use.from~=player or use.card:getTypeId()==sgs.Card_TypeSkill then return "" end --自己用
            if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then --基本牌或普通锦囊牌
                room:setPlayerFlag(player, "-qiaoshuo_win")
                return "luasheyan"
            end
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
          
        return false  
    end,
}  

zongzhe = sgs.CreateTriggerSkill{  
    name = "zongzhe",  
    events = {sgs.Pindian},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        local pindian = data:toPindian()  
        if pindian.from:objectName() == player:objectName() or pindian.to:objectName() == player:objectName() then  
            return self:objectName()  
        end  
          
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  -- 强制技能，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local pindian = data:toPindian()  
        local card = nil
          
        -- 确定赢家和输家  
        if pindian.from_number > pindian.to_number then  
            card = pindian.to_card
        elseif pindian.from_number < pindian.to_number then
            card = pindian.from_card  
        else --一样大，自己选一张
            local card_ids = sgs.IntList()  
            card_ids:append(pindian.from_card:getEffectiveId())
            card_ids:append(pindian.to_card:getEffectiveId())
            
            room:fillAG(card_ids, player)  
            local id = room:askForAG(player, card_ids, false, self:objectName())  
            room:clearAG(player)  
            card = sgs.Sanguosha:getCard(id)
        end  

        -- 获得点数小的牌  
        if card and room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceTable then  
            player:obtainCard(card)  
                
            -- 显示获得牌的提示  
            local msg = sgs.LogMessage()  
            msg.type = "#ZongzheObtain"  
            msg.from = player  
            msg.arg = card:getNumber()  
            msg.arg2 = self:objectName()  
            room:sendLog(msg)  
        end  
          
        return false  
    end  
}  
jianyong:addSkill(qiaoshuo)
jianyong:addSkill(zongzhe)
sgs.LoadTranslationTable{
    ["jianyong"] = "简雍",
    ["qiaoshuo"] = "巧说",
    [":qiaoshuo"] = "出牌阶段每个势力角色限一次。你可以与一名角色拼点：若你赢，你本回合使用的下一张基本牌或普通锦囊牌可以增加或者减少1个目标；若你没赢，本回合你不能使用锦囊且此技能失效",
    ["zongzhe"] = "纵谪",
    [":zongzhe"] = "当你拼点后，你可以获得一张没赢的拼点牌",
}

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
            card:setShowSkill(self:objectName())
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
        card:setShowSkill(self:objectName())
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
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
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
                slash:deleteLater()
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
liuyan = sgs.General(extension, "liuyan", "qun", 3)

zifengCard = sgs.CreateSkillCard{
    name = "zifengCard",
    skill_name = "zifeng",
    target_fixed = true,--是否需要指定目标，默认false，即需要
    on_use = function(self, room, source)
        local card_id = self:getSubcards():first()
        local card = sgs.Sanguosha:getCard(card_id)
		local supCard = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())
        supCard:addSubcard(card_id)
        supCard:setSkillName("zifeng")
        supCard:setShowSkill("zifeng")
        room:useCard(sgs.CardUseStruct(supCard, source, source), true)
        supCard:deleteLater()
    end
}

zifengToIndu = sgs.CreateOneCardViewAsSkill{
    name = "zifengToIndu",
    response_pattern = "@@zifengToIndu",
    filter_pattern = ".|.|.|zifengIndu",
    expand_pile = "zifengIndu",

	view_as = function(self, card)
        local supCard = zifengCard:clone()
        supCard:addSubcard(card:getId())
        supCard:setSkillName("zifeng")
		supCard:setShowSkill("zifeng")
        return supCard
    end,
}

zifeng = sgs.CreateTriggerSkill{  
    name = "zifeng",
    events = {sgs.CardUsed, sgs.CardResponded},  --集合，可以有多个触发条件
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        if owner:hasFlag("zifeng_used") then return "" end --每回合限一次
        local who, card = nil, nil
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            who = use.from
            card = use.card
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse() 
            --m_who是响应目标, m_isUse判断响应是否为使用（如闪响应杀）, m_isHandcard是否来自手牌, m_isRetrial是否用于改判
            who = player
            card = response.m_card
        end
        if who == owner then return "" end --自己用
        if card:isKindOf("Jink") and card:getSkillName() == "" then --非转化的闪
            --判断转化牌的方法：
            --card:getSkillName(), card:getSubcards()
            return self:objectName(), owner:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local jcards = ask_who:getCards("j")
        local hasIndulgence, JudgeAreaCard = false, nil
        for _, c in sgs.qlist(jcards) do
            if c:isKindOf("Indulgence") then 
                hasIndulgence = true 
                JudgeAreaCard = c
            end
        end
        if hasIndulgence and JudgeAreaCard then --有乐不思蜀，获得之
            ask_who:obtainCard(JudgeAreaCard)
        else --没有乐不思蜀，将这张闪当作乐不思蜀
            
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                card = use.card
            elseif event == sgs.CardResponded then
                local response = data:toCardResponse() --m_isUse判断响应是否为使用（如闪响应杀）, m_isHandcard是否来自手牌, m_isRetrial是否用于改判
                card = response.m_card
            end
            if card ~= nil then
                ask_who:addToPile("zifengIndu", card, false)
                local invoke = (room:askForUseCard(ask_who, "@@zifengToIndu", "@zifengAsk")) == nil
                if invoke then 
                    ask_who:clearOnePrivatePile("zifengIndu")
                    return false
                end
            end
        end
        room:setPlayerFlag(ask_who, "zifeng_used")
        return false  
    end
}  


juxian = sgs.CreateTriggerSkill{  
    name = "juxian",        
    events = {sgs.StartJudge, sgs.FinishJudge},  -- 监听判定开始事件  
    frequency = sgs.Skill_Compulsory,  -- 锁定技，自动触发  
      
    can_trigger = function(self, event, room, player, data)  
        local judge = data:toJudge() 
        if not judge.who:hasSkill(self:objectName()) then return "" end
        if event == sgs.StartJudge then 
            if judge.reason == "indulgence" then
                return self:objectName()  
            end  
        elseif event == sgs.FinishJudge then
            if judge.reason == "indulgence" or judge.reason == "supply_shortage" or judge.reason == "lightning" then
                return self:objectName()  
            end  
        end
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        
        if event == sgs.StartJudge then 
            -- 反转乐不思蜀的判定结果  
            -- 乐不思蜀默认：红桃为好判定（good=true），其他为坏判定  
            -- 反转后：红桃为坏判定，其他为好判定  
            if judge.reason == "indulgence" then  
                judge.good = not judge.good  -- 反转好坏标志  
                
                -- 更新判定结果  
                room:sendCompulsoryTriggerLog(player, self:objectName())
                data:setValue(judge)

                -- 发送日志消息  
                local log = sgs.LogMessage()  
                log.type = "#ReverseIndulgence"  
                log.from = player  
                log.to:append(judge.who)  
                log.arg = "juxian"  
                room:sendLog(log)  
                
                -- 播放技能音效  
                room:broadcastSkillInvoke(self:objectName())  
            end  
        elseif event == sgs.FinishJudge then
            local choices = {}  
            -- 检查是否有牌可以弃置  
            if not player:isNude() then  
                table.insert(choices, "damage")  
            end  
            
            -- 摸牌选项总是可用  
            table.insert(choices, "draw")  
            
            -- 让玩家选择效果  
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            
            if choice == "draw" then  
                -- 摸一张牌  
                player:drawCards(1)  
            elseif choice == "damage" then  
                -- 弃置一张牌并对其他角色造成伤害  
                if room:askForDiscard(player, self:objectName(), 1, 1, true, true) then -- 弃牌        
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())  
                    if target then  
                        -- 造成1点伤害  
                        local damage = sgs.DamageStruct()  
                        damage.from = player  
                        damage.to = target  
                        damage.damage = 1  
                        room:damage(damage)  
                    end  
                end  
            end  
        end
        return false  
    end  
}  
liuyan:addSkill(zifeng)
liuyan:addSkill(juxian)

if not sgs.Sanguosha:getSkill("zifengToIndu") then skills:append(zifengToIndu) end
-- 翻译文本  
sgs.LoadTranslationTable{  
    ["liuyan"] = "刘焉",
    ["zifeng"] = "自封",
    [":zifeng"] = "每回合限一次。其他角色使用或打出非转化的闪时，你可以将此牌当作乐不思蜀置于判定区，或获得判定区的乐不思蜀",
    ["juxian"] = "据险",  
    [":juxian"] = "锁定技，你的乐不思蜀判定反转（红桃变为坏判定，其他花色变为好判定）。你的延时锦囊牌结算完成后，你摸一张牌，或弃置1张牌并对1名其他角色造成1点伤害", 
    ["@zifengAsk"] = "请选择一张【闪】发动“自封”",
    ["zifengIndu"] = "自封",
    ["damage"] = "弃牌造成伤害"
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
zhaojieDelay = sgs.CreateTriggerSkill{  
    name = "zhaojieDelay",  
    events = {sgs.CardEffected},  
    frequency = sgs.Skill_Compulsory,  
            
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.CardEffected then
            --local use = data:toCardUse()  
            local effect = data:toCardEffect()  
            if effect.card and (effect.card:isKindOf("DelayedTrick")) then  
                return self:objectName()  
            end  
        elseif event == sgs.TurnedOver then --叠置事件开始时
            return self:objectName()
        end   
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,  
            
    on_effect = function(self, event, room, player, data)     
        if event == sgs.CardEffected then
            return true
        elseif event == sgs.TurnedOver then --叠置事件开始时
            --player:setFaceUp(false)
            if not player:faceUp() then --正面朝上
                player:turnOver() --先翻一次面，触发事件翻回来
                return false
            end
            --背面朝上，不需要先翻面
        end
        return true  --返回true，终止效果结算
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
    [":zhaojieDelay"] = "锁定技，延时锦囊对你生效时，取消之",  
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

lvdai = sgs.General(extension, "lvdai", "wu", 4)
qinguo = sgs.CreateTriggerSkill{  
    name = "qinguo",  
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        local card = nil  
        if event == sgs.CardFinished then  
            card = data:toCardUse().card  
        end  

        if card and card:isKindOf("EquipCard") then  
            local subtype = card:getSubtype()
            local flag = "qinguo" .. subtype
            if not player:hasFlag(flag) then
                return self:objectName()
            end
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local card = data:toCardUse().card
        local subtype = card:getSubtype()
        local flag = "qinguo" .. subtype
        room:setPlayerFlag(player, flag)
        if player:getEquips() == player:getHandcardNum() then
            local recover = sgs.RecoverStruct()  
            recover.who = player  
            recover.recover = 1  
            room:recover(player, recover)  
        else
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if player:inMyAttackRange(p) then  
                    targets:append(p)  
                end  
            end  
                
            if not targets:isEmpty() then  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@qinguo-target")  
                if target then  
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                    slash:setSkillName("qinguo")  
                    local use = sgs.CardUseStruct()  
                    use.card = slash  
                    use.from = player  
                    use.to:append(target)  
                    room:useCard(use, false) 
                    slash:deleteLater()
                end  
            end  
        end
        return false  
    end  
}  

lvdai:addSkill(qinguo)
sgs.LoadTranslationTable{
    ["lvdai"] = "吕岱",
    ["qinguo"] = "勤国",
    [":qinguo"] = "每回合每种副类别限一次。当你使用装备牌后，若你装备区的牌数与手牌数：相等，你可以恢复1点体力；不相等，你视为使用1张杀（有距离限制，无次数限制）",
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
            for _, c in ipairs(cards) do  
                card:addSubcard(c)  
            end  
            card:setSkillName(self:objectName())
            card:setShowSkill(self:objectName())
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
        lure_tiger:deleteLater()
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
                    iron_chain:deleteLater()
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

simalang = sgs.General(extension, "simalang", "wei", 3)  

junbing = sgs.CreateTriggerSkill{
    name = "junbing",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        -- 任意角色回合结束时都可能触发
        if player:getPhase() == sgs.Player_Finish then  
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
            if player:getHandcardNum()<=1 and owner:isFriendWith(player) then
                return self:objectName() .. "->" .. player:objectName()
            end
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if player:askForSkillInvoke(self:objectName()) then
            return true
        end
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        player:drawCards(1)
        ask_who = room:findPlayerBySkillName(self:objectName())
        if player == ask_who then return false end
        local num = player:getHandcardNum()

        local move = sgs.CardsMoveStruct()  
        move.card_ids = player:handCards()  
        move.to = ask_who  
        move.to_place = sgs.Player_PlaceHand  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, ask_who:objectName(), self:objectName(), "")  
        room:moveCardsAtomic(move, true)  

        local to_exchange = room:askForExchange(ask_who, self:objectName(), num, num, "@junbing-exchange", "", ".|.|.|hand")  
        local move = sgs.CardsMoveStruct()  
        move.card_ids = to_exchange  
        move.to = player  
        move.to_place = sgs.Player_PlaceHand  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(), self:objectName(), "")  
        room:moveCardsAtomic(move, true)  
        return false  
    end, 
}


qujiCard = sgs.CreateSkillCard{
    name = "qujiCard",
	skill_name = "quji",
    will_throw = true,
	--handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select, Self)
        return #targets == 0 and to_select:objectName() ~= Self:objectName() and 
        Self:distanceTo(to_select) == self:subcardsLength() and to_select:isWounded()
    end,
    on_use = function(self, room, source, targets)
        local recover = sgs.RecoverStruct()  
        recover.who = source  
        recover.recover = 1  
        room:recover(targets[1], recover)  

        local card_ids = self:getSubcards()
        local has_black = false
        for _, card_id in sgs.qlist(card_ids) do
            local card = sgs.Sanguosha:getCard(card_id)
            if card:isBlack() then
                has_black = true
                break
            end
        end
        if has_black then
            room:loseHp(source, 1)
        end
    end
}

quji = sgs.CreateViewAsSkill{
    name = "quji",
    view_filter = function(self, selected, to_select)
        return true
	end,

    view_as = function(self, cards)
		if #cards > 0 then
            local card = qujiCard:clone()
            for _, c in pairs(cards) do
                card:addSubcard(c:getId())
            end
            card:setSkillName(self:objectName())
            card:setShowSkill(self:objectName())
            return card
        end
	end,

    enabled_at_play = function(self, player)  
        return not player:hasUsed("#qujiCard")  
    end  
}
simalang:addSkill(junbing)
simalang:addSkill(quji)
sgs.LoadTranslationTable{  
    ["simalang"] = "司马朗",
    ["junbing"] = "郡兵",
    [":junbing"] = "与你势力相同的角色结束阶段，若该角色手牌数小于等于1，其可以摸1张牌并将所有手牌交给你，然后你交给其等量张牌",
    ["quji"] = "去疾",
    [":quji"] = "出牌阶段限一次。你可以弃置任意张牌，并令等量距离的一名其他角色恢复1点体力，若其中包含黑色牌，你失去1点体力"
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
        card:setShowSkill(self:objectName())  
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
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
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
    [":LuaJiaoJin"] = "锁定技。当你受到伤害时，若杀死你的额外奖励牌数小于等于4，你防止此伤害，然后令杀死你的额外奖励牌数+1，",  
    ["@jiaoJin_reward"] = "娇矜",  
    ["#JiaoJinProtect"] = "%from 的'%arg2'效果被触发，防止了 %arg 点伤害",  
}


-- 创建武将：
sunqian = sgs.General(extension, "sunqian", "shu", 3)  -- 吴国，4血，男性  

shuomengCard = sgs.CreateSkillCard{  
    name = "shuomengCard",  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:isKongcheng()
               and to_select:hasShownOneGeneral()
               and not sgs.Self:isFriendWith(to_select)
               --and (to_select:getKingdom() ~= sgs.Self:getKingdom() or to_select:getRole()=="careerist" or sgs.Self:getRole()=="careerist") 
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
                card:deleteLater()
            end  
        end  
          
        return false  
    end  
}  

qianya = sgs.CreateTriggerSkill{
    name = "qianya",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted, sgs.EventPhaseStart}, 
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return "" end  
        if event == sgs.DamageInflicted then 
            local damage = data:toDamage() 
            if damage.card then
                return self:objectName()
            end
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
            if damage.card then--and (damage.card:isKindOf("Slash") or damage.card:isKindOf("TrickCard")) then
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

        if target:getCardCount(true) >= 2 and next_player ~= target and prev_player ~= target then  
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
            slash:deleteLater()
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

-- 创建武将：
wangyi = sgs.General(extension, "wangyi", "wei", 3, false)  -- 吴国，4血，男性  
zhenlie = sgs.CreateTriggerSkill{  
    name = "zhenlie",  
    events = {sgs.TargetConfirming}, --sgs.CardEffected
    --frequency = sgs.Skill_Frequent, 
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
            local ids = sgs.IntList()
            ids = room:getNCards(lost_hp)
            room:setPlayerMark(player, "miji_card1", ids:at(0))
            local dummy = sgs.DummyCard(ids)  
            player:obtainCard(dummy)
            dummy:deleteLater()
			
        end  
          
        return false  
    end  
}  

mijiAsk = sgs.CreateTriggerSkill{
    name = "#mijiAsk",
    events = {sgs.CardsMoveOneTime},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Discard then
            local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move and move.to and move.to:objectName() == player:objectName()then
                    local ids = sgs.IntList()
                    local isCard = false
					for _, id in sgs.qlist(move.card_ids) do
						if not isCard then
                            if player:getMark("miji_card1") == id then
                                isCard = true
                            end
                        end
                        if isCard then
                            ids:append(id)
                        end
					end
                    if ids:isEmpty() then return false end
                    while room:askForYiji(player, ids, self:objectName(), false, false, true, -1, room:getOtherPlayers(player)) do
                        if player:isDead() then return false end
                    end
                end
            end
        end
        return false
    end
}
wangyi:addSkill(zhenlie)
wangyi:addSkill(miji)
wangyi:addSkill(mijiAsk)
extension:insertRelatedSkills("miji", "#mijiAsk")
sgs.LoadTranslationTable{
    ["wangyi"] = "王异",
    ["zhenlie"] = "贞烈",
    [":zhenlie"] = "你成为杀或非延时性锦囊的目标时，你可以失去一点体力并取消之，然后摸一张牌，弃置来源一张牌",
    ["miji"] = "秘计",  
    [":miji"] = "弃牌阶段结束后，你可以摸X张牌（X为你已损失的体力值），并任意分配这些牌",  
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
                    card_to_use:deleteLater()
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

wuyi = sgs.General(extension, "wuyi", "shu", 4) -- 吴苋，蜀势力，3血，女性
benxi = sgs.CreateTriggerSkill{  
    name = "benxi",  
    events = {sgs.CardUsed, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end
        if event == sgs.CardUsed and player:getPhase()~=sgs.Player_NotActive then
            local use = data:toCardUse()  
            if player ~= use.from then return "" end
            room:addPlayerMark(player,"@benxi",1)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:distanceTo(p) > 1 then
                    return "" 
                end
            end
            room:setPlayerFlag(player, "zhuanzheng_active")
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player,"@benxi",0)
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        return false  
    end  
}


benxiMod = sgs.CreateDistanceSkill{
    name = "#benxi-distance",
    correct_func = function(self, from, to)
		if from:hasShownSkill(self:objectName()) then --hasSkill
			return -from:getMark("@benxi")
		end
		return 0
	end
}
--[[
zhuanzheng1_card = sgs.CreateSkillCard{  
    name = "zhuanzheng1",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select, Self)  
        return #targets == 0 and to_select:isFriendWith(Self) and Self:distanceTo(to_select)<=1 --sgs.Self
    end,  
      
    feasible = function(self, targets, Self)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local final_num = 1
        if source == target then
            final_num = 1
        else --2个方向遍历
            local n1 = 0
            local n2 = 0
            -- 逆时针遍历  
            local current = source:getNextAlive()
            while current ~= target do
                n1 = n1 + 1
                current = current:getNextAlive()  
                if current == source then break end  
            end  

            -- 顺时针遍历  
            local current = target:getNextAlive()
            while current ~= source do  
                n2 = n2 + 1
                current = current:getNextAlive()  
                if current == target then break end  
            end  
            local n = math.min(n1,n2)  
            final_num = math.max(final_num, n)       
        end
        source:drawCards(final_num, self:objectName())
    end  
}

zhuanzheng1 = sgs.CreateZeroCardViewAsSkill{  
    name = "zhuanzheng1",  
      
    view_as = function(self)  
        local card = zhuanzheng1_card:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
      
    enabled_at_play = function(self, player)   
        local used_times = player:usedTimes("#zhuanzheng1")  
        return used_times < 2
    end  
}
]]

zhuanzheng1 = sgs.CreateViewAsSkill{  
    name = "zhuanzheng1",  
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then
            return to_select:isKindOf("BasicCard") or to_select:isKindOf("TrickCard")
        else
            return selected[1]:getTypeId() == to_select:getTypeId()
        end
    end,  
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local card = nil
        if cards[1]:getTypeId() == sgs.Card_TypeBasic then
            card = sgs.Sanguosha:cloneCard("Slash")
        elseif cards[1]:getTypeId() == sgs.Card_TypeTrick then
            card = sgs.Sanguosha:cloneCard("Snatch")
        end
        for _, c in ipairs(cards) do
            card:addSubcard(c)
        end
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
      
    enabled_at_play = function(self, player)   
        return player:hasFlag("zhuanzheng_active") and player:usedTimes("ViewAsSkill_zhuanzheng1Card") == 0
    end  
}
zhuanzheng1Mod = sgs.CreateTargetModSkill{  
    name = "#zhuanzheng1-mod",   
    pattern = "Slash#Snatch",  --同类模式用#并列，不同类用|并列  
    extra_target_func = function(self, player, card)  
        if card:getSkillName() == "zhuanzheng1" then  
            return card:getSubcards():length()-1
        else  
            return 0  
        end  
    end  
}  
wuyi:addSkill(benxi)
wuyi:addSkill(benxiMod)
wuyi:addSkill(zhuanzheng1)
wuyi:addSkill(zhuanzheng1Mod)
extension:insertRelatedSkills("benxi", "#benxi-distance")
extension:insertRelatedSkills("zhuanzheng1", "#zhuanzheng1-mod")
sgs.LoadTranslationTable{
    ["wuyi"] = "吴懿",
    ["benxi"] = "奔袭",
    [":benxi"] = "锁定技。你回合内使用牌时，本回合你计算与其他角色的距离-1",
    ["zhuanzheng1"] = "转征",
    [":zhuanzheng1"] = "出牌阶段限2次。你可以选择1名距离小于等于1的同势力角色，你摸X张牌，X为你与其之间的角色数且至少为1",
    ["zhuanzheng1"] = "转征",
    [":zhuanzheng1"] = "出牌阶段限1次。若你与所有角色的距离都为1，你可以将：任意数量的基础牌当作杀，指定等量角色；任意数量的锦囊当作顺手牵羊，指定等量角色"
}

xujing = sgs.General(extension, "xujing", "shu", 3) -- 吴苋，蜀势力，3血，女性

-- 许名技能卡  
XumingCard = sgs.CreateSkillCard{  
    name = "XumingCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:hasShownOneGeneral() and not to_select:isFriendWith(sgs.Self)
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
        yuanjiao:deleteLater()
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
        local choices = {"cancel"}  
          
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
        if choice ~= "cancel" then  
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
    [":xingshen"] = "你受到伤害后，你可以选择摸1张牌或弃置1张手牌，然后展示所有手牌，若没有伤害牌，或者所有手牌的花色和伤害牌都不相同，你可以令一名其他角色恢复一点体力。",  
      
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
        return #targets == 0 and to_select:hasShownOneGeneral()
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 令目标视为使用远交近攻  
        local yuanjiao = sgs.Sanguosha:cloneCard("befriend_attacking", sgs.Card_NoSuit, 0)  
        yuanjiao:setSkillName("fushu")  
        yuanjiao:deleteLater()
        -- 选择与目标势力相同的角色作为伤害目标  
        local same_kingdom_players = sgs.SPlayerList()
        local different_kingdom_players = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
            --if p:hasShownOneGeneral() and (p:getKingdom() == target:getKingdom() and p:objectName() ~= target:objectName() and p:getRole()~="careerist") then  
            if p:isFriendWith(target) then
                same_kingdom_players:append(p)
            elseif p:hasShownOneGeneral() and not p:isFriendWith(target) then
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
        local card = fushuCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
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

zhongyao = sgs.General(extension, "zhongyao", "wei", 3)

zuoding = sgs.CreateTriggerSkill{  
    name = "zuoding",  
    events = {sgs.TargetConfirmed, sgs.Damaged},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())  
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName()) then return "" end   

        local current = room:getCurrent()
        if event == sgs.Damaged then
            room:setPlayerFlag(current, "zuoding_damaged") --本回合有人受过伤
            return ""
        end
        if current:hasFlag("zuoding_damaged") then return "" end

        local use = data:toCardUse()  
        if use.from == owner or use.from ~= current then return "" end
        if use.card and use.card:getSuitString()=="spade" and use.card:getTypeId()~=sgs.Card_TypeSkill then 
            return self:objectName(), owner:objectName()
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
        local use = data:toCardUse()  
        local target = room:askForPlayerChosen(ask_who, use.to, self:objectName(), "@zuoding_target", true, true)    
        if target then
            target:drawCards(1,self:objectName())
        end
        return false  
    end  
}


huomoVS = sgs.CreateOneCardViewAsSkill{  
    name = "huomo",  
    guhuo_type = "b",  -- 显示基础牌选择框  
    filter_pattern = "^BasicCard|black|.|.",  --牌名，类型|颜色，花色|点数|位置
    response_or_use = true,  
    view_as = function(self, card)  
        local pattern = sgs.Self:getTag(self:objectName()):toString()  
        local new_card = sgs.Sanguosha:cloneCard(pattern)  
        if new_card then  
            new_card:addSubcard(card:getId())  
            new_card:setSkillName(self:objectName())  
            new_card:setShowSkill(self:objectName())  
        end  
        return new_card  
    end,  

    enabled_at_play = function(self, player)  
        return not player:isNude() and not player:hasFlag("huomo_lose")
    end,
    
    enabled_at_response = function(self, player, pattern)  
        return not player:isNude() and not player:hasFlag("huomo_lose") and
            pattern == "slash" or pattern == "jink" or string.find(pattern,"peach") or string.find(pattern,"analeptic")  
    end  
}


huomo = sgs.CreateTriggerSkill{  
    name = "huomo",
    events = {sgs.CardUsed, sgs.CardsMoveOneTime},  --集合，可以有多个触发条件
    view_as_skill = huomoVS,
    frequency = sgs.Compulsory,         
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        if event == sgs.CardUsed then
            local use = data:toCardUse()  
            if use.card:getSkillName() == self:objectName() then
                room:moveCardTo(use.card, nil, sgs.Player_DrawPile, true) 
            end
        elseif event == sgs.CardsMoveOneTime then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
						if move.from and move.from:isAlive() and player:objectName()==move.from:objectName() then
                            room:setPlayerFlag(player, "huomo_lose")
						end
					end
				end
			end
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return false
    end,  
    on_effect = function(self, event, room, player, data)  
        return false  
    end,
}  

zhongyao:addSkill(zuoding)
zhongyao:addSkill(huomo)
sgs.LoadTranslationTable{
    ["zhongyao"] = "钟繇",
    ["zuoding"] = "佐定",
    [":zuoding"] = "其他角色于出牌阶段使用黑桃牌指定目标后，若此阶段没有角色受到过伤害，你可以令其中一个目标摸1张牌",
    ["huomo"] = "活墨",
    [":huomo"] = "若你本回合没有失去过牌，你可以将一张黑色非基本牌当作任意基本牌使用，然后将该牌放在牌堆顶",
}

sgs.Sanguosha:addSkills(skills)
return {extension}