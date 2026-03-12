extension = sgs.Package("sixiangfengyin",sgs.Package_GeneralPack)  
local skills = sgs.SkillList()
sgs.LoadTranslationTable{
    ["sixiangfengyin"] = "四象封印"
}

baoxin_feng = sgs.General(extension, "baoxin_feng", "wei", 4)
yimou = sgs.CreateTriggerSkill{  
    name = "yimou",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data)
        local card = room:askForCard(player, ".|.|.|hand,equipped", self:objectName()) 
        if card then
            local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName())
            room:obtainCard(target, card, false)  
        end
        return false        
    end  
}

mutao = sgs.CreateTriggerSkill{  
    name = "mutao",  
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
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
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@mutao-invoke")  
        if target then
            room:showAllCards(target)
            local can_damage = false
            for _,card in sgs.qlist(target:getHandcards()) do
                if card:isKindOf("Slash") then
                    can_damage = true
                    break
                end
            end
            if can_damage then
                local damage = sgs.DamageStruct()
                damage.from = player
                damage.to = target
                damage.damage = 1
                room:damage(damage)
            end
        end
        return false  
    end  
}
baoxin_feng:addSkill(yimou)
baoxin_feng:addSkill(mutao)
sgs.LoadTranslationTable{  
    ["baoxin_feng"] = "鲍信",  
    ["yimou"] = "毅谋",  
    [":yimou"] = "当你受到伤害后，你可以将一张牌交给一名其他角色",
    ["mutao"] = "募讨",
    [":mutao"] = "准备阶段，你可以令一名其他角色展示所有手牌，若其中有【杀】，你对其造成1点伤害。 "
}
caojinyu_feng = sgs.General(extension, "caojinyu_feng", "wei", 3, false)
yuqi = sgs.CreateTriggerSkill{  
    name = "yuqi",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end  
        local damage = data:toDamage()
        if damage.to:isAlive() and owner:distanceTo(damage.to) <= owner:getHp() and owner:willBeFriendWith(damage.to) then
            return self:objectName(), owner:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
        damage.to:drawCards(1,self:objectName())
    end  
}

shanshen = sgs.CreateTriggerSkill{  
    name = "shanshen",  
    events = {sgs.Death},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:isWounded()) then return "" end
        local death = data:toDeath()  
        if not death.damage or not death.damage.from or not death.damage.from:hasSkill(self:objectName()) then
            return self:objectName()
        end
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data) 
        local recover = sgs.RecoverStruct()  
        recover.who = player  
        recover.recover = 1  
        room:recover(player, recover)  
    end
}

caojinyu_feng:addSkill(yuqi)
caojinyu_feng:addSkill(shanshen)
sgs.LoadTranslationTable{
    ["caojinyu_feng"] = "曹金玉",
    ["yuqi"] = "隅泣",
    [":yuqi"] = "与你势力相同的角色受到伤害后，若你到其的距离小于等于你当前体力值，你可以令其摸1张牌",
    ["shanshen"] = "善身",
    [":shanshen"] = "一名角色死亡时，若没有伤害来源或伤害来源不是你，你可以恢复1点体力"
}

cenhun_feng = sgs.General(extension, "cenhun_feng", "wu", 3)
wudu = sgs.CreateTriggerSkill{  
    name = "wudu",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        local damage = data:toDamage()
        if damage.to:isKongcheng() and owner:willBeFriendWith(damage.to) and owner:getMaxHp()>1 then
            return self:objectName(), owner:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:loseMaxHp(ask_who,1)
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
        damage.damage = 0
        data:setValue(damage)
        return true
    end  
}
cenhun_feng:addSkill("liebo")
cenhun_feng:addSkill(wudu)
sgs.LoadTranslationTable{
    ["cenhun_feng"] = "岑昏",
    ["wudu"] = "无度",
    [":wudu"] = "与你势力相同的角色受到伤害时，若其没有手牌，且你的体力上限大于1，你可以失去1点体力上限，防止此伤害",
}

feiyi_feng = sgs.General(extension, "feiyi_feng", "shu", 3)
tiaoheCard = sgs.CreateSkillCard{
    name = "tiaoheCard",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source)
        --选择一名角色，弃置其装备区的武器
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getWeapon() then
                targets:append(p)
            end
        end
        local target = room:askForPlayerChosen(source, targets, self:objectName(), "选择一名角色弃置其装备区的武器")
        room:throwCard(target:getWeapon():getId(),target,source)

        --选择另一名角色，弃置其装备区的防具
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getOtherPlayers(target)) do
            if p:getArmor() then
                targets:append(p)
            end
        end
        local target = room:askForPlayerChosen(source, targets, self:objectName(), "选择一名角色弃置其装备区的防具")
        room:throwCard(target:getArmor():getId(),target,source)
        return false
    end
}

tiaohe = sgs.CreateZeroCardViewAsSkill{  
    name = "tiaohe",
    view_as = function(self)  
        local card = tiaoheCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#tiaoheCard")
    end  
}

qiansu = sgs.CreateTriggerSkill{  
    name = "qiansu",  
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)   
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local use = data:toCardUse()  
        if use.card:isKindOf("TrickCard") and use.to:contains(player) and player:getEquips():isEmpty() then 
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
        player:drawCards(1,self:objectName())
        return false  
    end  
}

feiyi_feng:addSkill(tiaohe)
feiyi_feng:addSkill(qiansu)
sgs.LoadTranslationTable{
    ["feiyi_feng"] = "费祎",
    ["tiaohe"] = "调和",
    [":tiaohe"] = "出牌阶段限一次。你可以弃置1名角色装备区的武器、另一名角色装备区的防具",
    ["qiansu"] = "谦素",
    [":qiansu"] = "当你成为锦囊的目标后，若你的装备区没有牌，你可以摸一张牌"
}

huangfusong_feng = sgs.General(extension, "huangfusong_feng", "qun", 4)
taoluan = sgs.CreateTriggerSkill{  
    name = "taoluan",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish and not player:isKongcheng() then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and not owner:isNude() and not owner:willBeFriendWith(player) then
                return self:objectName(), owner:objectName()
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local card = room:askForCard(ask_who, ".", "@taolun-give", data, sgs.Card_MethodNone)
        if card then
            player:obtainCard(card)
            room:showAllCards(player)

            local jinks = sgs.IntList()            
            for _, card in sgs.qlist(player:getHandcards()) do  
                if card:isKindOf("Jink") then  
                    jinks:append(card:getEffectiveId())
                end  
            end  
            if not jinks:isEmpty() then  
                local dummy = sgs.DummyCard(jinks)  
                room:throwCard(dummy, player, player)  
                dummy:deleteLater()  
            end
        end
    end
}
huangfusong_feng:addSkill(taoluan)
sgs.LoadTranslationTable{
    ["huangfusong_feng"] = "皇甫嵩",
    ["taoluan"] = "讨乱",
    [":taoluan"] = "其他势力角色结束阶段，你可以交给其1张牌，其展示所有手牌，然后弃置所有闪",
}


huangwudie_feng = sgs.General(extension, "huangwudie_feng", "shu", 4, false)
shuangrui = sgs.CreateTriggerSkill{  
    name = "shuangrui",  
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)
        local n = player:getHandcardNum()
        return player:askForSkillInvoke(self:objectName(),data) and room:askForDiscard(player,self:objectName(),n,1,true,false)
    end,  
    on_effect = function(self, event, room, player, data)  
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@shuangrui-invoke", true, true)  
        if target then            
            -- 视为对目标使用杀  
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:setSkillName(self:objectName())  
            slash:deleteLater()
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = player  
            use.to:append(target)
            if player:getHandcardNum() == target:getHandcardNum() then
                use.card:setFlags("GlobalCardUseDisresponsive")
            end
            room:useCard(use, false)
        end
        return false  
    end  
}
huangwudie_feng:addSkill(shuangrui)
sgs.LoadTranslationTable{
	["huangwudie_feng"] = "黄舞蝶",
	["shuangrui"] = "双锐",
	[":shuangrui"] = "准备阶段，你可以弃置任意张手牌并视为使用一张【杀】，若目标角色手牌数与你相同，此【杀】不能被响应",
    ["@shuangrui-invoke"] = "双锐：选择一名其他角色，视为对其使用1张杀"
}
liuba_feng = sgs.General(extension, "liuba_feng", "shu", 3)
zhubi = sgs.CreateTriggerSkill{  
    name = "zhubi",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish and not player:isKongcheng() then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            player:throwAllHandCards()
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if player:isFriendWith(p) then  
                targets:append(p)  
            end  
        end
        local chosen_players = room:askForPlayersChosen(player, targets, self:objectName(), 2, 2, "请选择至多2名相同势力角色", false)
        if chosen_players and not chosen_players:isEmpty() then  
            room:drawCards(chosen_players, 2)  
        end  
    end
}
liuba_feng:addSkill(zhubi)
sgs.LoadTranslationTable{
    ["liuba_feng"] = "刘巴",
    ["zhubi"] = "锻币",
    [":zhubi"] = "结束阶段，你可以弃置所有手牌，令2名与你势力相同的角色摸2张牌",
}

liuli_feng = sgs.General(extension, "liuli_feng", "shu", 3)
fuliCard = sgs.CreateSkillCard{
    name = "fuliCard",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)  
        return #targets == 0
    end,  
    on_use = function(self, room, source, targets)
        local target = targets[1]
        --自己展示并弃置所有伤害牌
        if not source:isKongcheng() then
            room:showAllCards(source)
        end
        local to_discard = sgs.IntList()
        for _,card in sgs.qlist(source:getHandcards()) do
            if isDamageCard(card) then
                to_discard:append(card:getId())
            end
        end
        if not to_discard:isEmpty() then  
            local dummy = sgs.DummyCard(to_discard)  
            room:throwCard(dummy, source, source)  
            dummy:deleteLater()  
        end
        if source:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who = source
            recover.recover = 1
            room:recover(source, recover)
        end
        --目标展示并弃置所有伤害牌
        if not target:isKongcheng() then
            room:showAllCards(target)
        end
        local to_discard = sgs.IntList()
        for _,card in sgs.qlist(target:getHandcards()) do
            if isDamageCard(card) then
                to_discard:append(card:getId())
            end
        end
        if not to_discard:isEmpty() then  
            local dummy = sgs.DummyCard(to_discard)  
            room:throwCard(dummy, target, target)  
            dummy:deleteLater()  
        end
        if target:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who = target
            recover.recover = 1
            room:recover(target, recover)
        end       
    end
}

fuli = sgs.CreateZeroCardViewAsSkill{  
    name = "fuli",
    view_as = function(self)  
        local card = fuliCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#fuliCard")
    end  
}

dehua = sgs.CreateTriggerSkill{
	name = "dehua",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then
            if skillTriggerable(player, self:objectName()) then
                local current = room:getCurrent()
                if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
                    local move_datas = data:toList()
                    for _, move_data in sgs.qlist(move_datas) do
                        local move = move_data:toMoveOneTime()
                        if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
                            if move.from and move.from:isAlive() and player:objectName()==move.from:objectName() then
                                room:addPlayerMark(player,"@dehua_lose",move.card_ids:length())
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner and owner:hasSkill(self:objectName()) then
                local num = owner:getMark("@dehua_lose")
                room:setPlayerMark(owner,"@dehua_lose",0)--不管有几个标记都清0
                if num == 2 then
                    return self:objectName(), owner:objectName()
                end
            end
        end
		return ""
	end,
    on_cost = function(self, event, room, player, data, ask_who)
		return ask_who:askForSkillInvoke(self:objectName(),data)
	end,
    on_effect = function(self, event, room, player, data, ask_who)
        player = ask_who
        choices = {}
        table.insert(choices, "slash")
        table.insert(choices, "thunder_slash")
        table.insert(choices, "fire_slash")
        table.insert(choices, "analeptic")
        if player:isWounded() then
            table.insert(choices, "peach")
        end
 
        if #choices > 0 then  
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            if choice and choice ~= "" then  
                local virtual_card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, -1)  
                virtual_card:setSkillName(self:objectName())  
                virtual_card:deleteLater()
                -- 根据卡牌类型设置目标  
                if choice == "slash" or choice == "thunder_slash" or choice == "fire_slash" then  
                    local targets = sgs.SPlayerList()  
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                        if player:inMyAttackRange(p) then  
                            targets:append(p) 
                        end  
                    end  
                    target=room:askForPlayerChosen(player, targets, self:objectName())
                    local use = sgs.CardUseStruct()  
                    use.card = virtual_card  
                    use.from = player 
                    use.to:append(target)
                    room:useCard(use) 
                elseif choice == "peach" then  
                    if player:isWounded() then  
                        local use = sgs.CardUseStruct()  
                        use.card = virtual_card  
                        use.from = player 
                        use.to:append(player)
                        room:useCard(use) 
                    end  
                elseif choice == "analeptic" then  
                    local use = sgs.CardUseStruct()  
                    use.card = virtual_card  
                    use.from = player 
                    use.to:append(player)
                    room:useCard(use) 
                end  
            end  
        end  
        return false
	end
}

liuli_feng:addSkill(fuli)
liuli_feng:addSkill(dehua)
sgs.LoadTranslationTable{
    ["liuli_feng"] = "刘理",
    ["fuli"] = "抚黎",
    [":fuli"] = "出牌阶段限一次，你可以展示所有手牌并弃置其中的所有伤害类牌（没有则不弃），并回复1点体力，然后令一名其他角色进行相同操作，",
    ["dehua"] = "德化",
    [":dehua"] = "你失去仅两张牌的回合结束时，你可以视为使用一张基本牌",
}

jiakui_feng = sgs.General(extension, "jiakui_feng", "wei", 3)
zhongzuo = sgs.CreateTriggerSkill{  
    name = "zhongzuo",  
    events = {sgs.Damage, sgs.Damaged, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.Damage or event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:hasSkill(self:objectName()) then
                room:setPlayerFlag(damage.from,"zhongzuo_damage")
            end
            if damage.to and damage.to:hasSkill(self:objectName()) then
                room:setPlayerFlag(damage.to,"zhongzuo_damage")
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and owner:hasFlag("zhongzuo_damage") then 
                return self:objectName(),owner:objectName()
            end  
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        ask_who:drawCards(1,self:objectName())
        player:drawCards(1,self:objectName())
    end
}

wanlan = sgs.CreateTriggerSkill{  
    name = "wanlan",  
    events = {sgs.Dying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@wanlan",
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if player:getMark("@wanlan") > 0 and not player:isKongcheng() then
            local dying = data:toDying()
            if player:willBeFriendWith(dying.who) then
                return self:objectName() .. "->" .. dying.who:objectName()
            end
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local dying = data:toDying()  
        local _data = sgs.QVariant()  
        _data:setValue(dying.who)  
        if ask_who:askForSkillInvoke(self:objectName(), _data) then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(ask_who, "@wanlan", 0)
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)
        local dying = data:toDying()
        local source_handcards = ask_who:handCards()  
        if not source_handcards:isEmpty() and ask_who ~= dying.who then
            local move1 = sgs.CardsMoveStruct()  
            move1.card_ids = source_handcards
            move.from = ask_who
            move1.to = dying.who  
            move1.to_place = sgs.Player_PlaceHand  
            room:moveCardsAtomic(move1, false)  
        end
        local recover = sgs.RecoverStruct()  
        recover.recover = 1 - dying.who:getHp()
        room:recover(dying.who, recover)
    end
}
jiakui_feng:addSkill(zhongzuo)
jiakui_feng:addSkill(wanlan)
sgs.LoadTranslationTable{
    ["jiakui_feng"] = "贾逵",
    ["zhongzuo"] = "忠佐",
    [":zhongzuo"] = "锁定技。任意角色回合结束时，若你本回合造成或受到过伤害，你与其各摸1张牌",
    ["wanlan"] = "挽澜",
    [":wanlan"] = "限定技。与你势力相同的角色进入濒死时，你可以将所有手牌交给其 ，令其恢复体力至1点",
}

jianggan_feng = sgs.General(extension, "jianggan_feng", "wei", 3)
daoshuSnatch = sgs.CreateTriggerSkill{  
    name = "daoshuSnatch",  
    events = {sgs.EventPhaseStart, sgs.Damaged},  
    frequency = sgs.Skill_Limited, -- 每轮限一次  
    limit_mark = "@daoshuSnatch",
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then -- 检查是否为准备阶段
            if player:hasSkill(self:objectName()) then --自己的准备阶段，恢复次数
                room:setPlayerMark(player,"@daoshuSnatch",1)
            end
            --任意角色的准备阶段，询问是否发动
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:getMark("@daoshuSnatch")>0 then 
                return self:objectName(), owner:objectName()
            end
        elseif event == sgs.Damaged then
            if player:hasSkill(self:objectName()) then --受到伤害后，恢复次数
                room:setPlayerMark(player,"@daoshuSnatch",1)
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        -- 询问是否发动技能  
        if room:askForSkillInvoke(ask_who, self:objectName(), data) then  
            room:setPlayerMark(ask_who,"@daoshuSnatch",0)
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            if not p:isKongcheng() then
                targets:append(p)
            end
        end
        local target = room:askForPlayerChosen(ask_who, targets, self:objectName())
        local card_id = room:askForCardChosen(ask_who, target, "h", self:objectName())
        room:showCard(target, card_id)
        room:obtainCard(player, card_id, true)
        local card = sgs.Sanguosha:getCard(card_id)
        pattern = ".|" .. card:getSuitString() .. "|.|hand"
        room:setPlayerCardLimitation(player, "use", pattern, true)  --true表示单回合标记，会自动清除
        room:setPlayerCardLimitation(ask_who, "use", pattern, true)  --true表示单回合标记，会自动清除
    end  
}

jianggan_feng:addSkill(daoshuSnatch)
sgs.LoadTranslationTable{
    ["jianggan_feng"] = "蒋干",
    ["daoshuSnatch"] = "盗书",
    [":daoshuSnatch"] = "每轮限一次。任意角色准备阶段，你可以展示其以外的角色1张手牌，并令其获得之，然后你与其本回合不能使用与之花色相同的手牌。当你受到伤害后，“盗书”视为未发动",
}

majun_feng = sgs.General(extension, "majun_feng", "wei", 3)
gongqiaoCard = sgs.CreateSkillCard{
    name = "gongqiaoCard",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)  
        return #targets == 0
    end,  
    on_use = function(self, room, source, targets)
        --翻开牌堆顶直到装备牌
        local target = targets[1]
        local card_ids = sgs.IntList()
        for i=1,3 do
            --local card_id = room:getDrawPile():ai(i)
            local card_id = room:drawCard()
            local card = sgs.Sanguosha:getCard(card_id)
            if not card:isKindOf("EquipCard") then
                card_ids:append(card_id)
            else
                local use = sgs.CardUseStruct()  
                use.card = card
                use.from = target
                use.to:append(target)
                room:useCard(use)
                break
            end
        end
        --用自己手牌和展示牌交换
        local target_handcards = sgs.IntList()
        for _, card in sgs.qlist(target:getHandcards()) do
            target_handcards:append(card:getId())
        end

        local move1 = sgs.CardsMoveStruct()        
        if not target_handcards:isEmpty() then
            move1.card_ids = target_handcards
            move1.from = target
            move1.to = nil
            move1.to_place = sgs.Player_DrawPile
        end

        local move2 = sgs.CardsMoveStruct()        
        if not card_ids:isEmpty() then
            move2.card_ids = card_ids
            move2.from = nil
            move2.to = target
            move2.to_place = sgs.Player_PlaceHand
        end

        local moves = sgs.CardsMoveList()
        moves:append(move1)
        moves:append(move2)
        room:moveCardsAtomic(moves, true)
        return false
    end
}

gongqiao = sgs.CreateZeroCardViewAsSkill{  
    name = "gongqiao",
    view_as = function(self)  
        local card = gongqiaoCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#gongqiaoCard")
    end  
}
majun_feng:addSkill(gongqiao)
sgs.LoadTranslationTable{
    ["majun_feng"] = "马钧",
    ["gongqiao"] = "工巧",
    [":gongqiao"] = "出牌阶段限一次，你可以选择一名角色并依次亮出牌堆顶的牌（至多3张）直至有装备牌，然后令其使用此装备牌并用所有手牌交换其余亮出的牌",
}

mayunlu_feng = sgs.General(extension, "mayunlu_feng", "shu", 4, false)
fengpo = sgs.CreateTriggerSkill{  
    name = "fengpo",  
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local damage = data:toDamage()
        if damage.from == player and damage.card:isKindOf("Slash") and not player:willBeFriendWith(damage.to) then
            return self:objectName()
        end
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local targets = sgs.SPlayerList()
        if not player:isNude() then
            targets:append(player)
        end
        if not damage.to:isNude() then
            targets:append(damage.to)
        end
        if targets:isEmpty() then return false end
        local target = room:askForPlayerChosen(player, targets, self:objectName())
        if not target:isNude() then
            local card_id = room:askForCardChosen(player, target, "he", self:objectName())
            local card = sgs.Sanguosha:getCard(card_id)
            room:throwCard(card_id, target, player)
            if card:getSuit() == sgs.Card_Diamond then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end
}
function sgs.CreatemashuSkill(name)
	local mashu_skill = {}
	mashu_skill.name = name
	mashu_skill.correct_func = function(self, from, to)
		if from:hasShownSkill(self) then
			return -1
		end
		return 0
	end
	return sgs.CreateDistanceSkill(mashu_skill)
end
mashuMayunlu = sgs.CreatemashuSkill("mashuMayunlu") 
mayunlu_feng:addSkill(fengpo)
mayunlu_feng:addSkill(mashuMayunlu)
sgs.LoadTranslationTable{
    ["mayunlu_feng"] = "马云禄",
    ["fengpo"] = "凤魄",
    [":fengpo"] = "你的杀对其他势力角色造成伤害时，你可以弃置你或目标1张牌，若此牌为方片，此杀伤害+1",
    ["mashuMayunlu"] = "马术",
    [":mashuMayunlu"] = "你计算到其他角色的距离-1"
}

mengda_feng = sgs.General(extension, "mengda_feng", "wei", 4)
zhuan = sgs.CreateTriggerSkill{  
    name = "zhuan",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if not player:hasFlag("zhuan_first_damaged") then
            room:setPlayerFlag(player,"zhuan_first_damaged")
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        player:drawCards(3,self:objectName())
        local damage = data:toDamage()
        if damage.from then
            local card_id = room:askForCardChosen(damage.from, player, "he", self:objectName())
            room:obtainCard(damage.from, card_id)
        end
    end
}
mengda_feng:addSkill(zhuan)
sgs.LoadTranslationTable{
    ["mengda_feng"] = "孟达",
    ["zhuan"] = "逐安",
    [":zhuan"] = "锁定技。你每回合首次受到伤害后，你摸3张牌，然后伤害来源获得你1张牌",
}

nahualaoxian_feng = sgs.General(extension, "nahualaoxian_feng", "qun", 3)
xianluCard = sgs.CreateSkillCard{  
    name = "xianluCard",  
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:getEquips():isEmpty()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        -- 选择并弃置目标角色的一张装备  
        local equip_id = room:askForCardChosen(source, target, "e", "xianlu")
        room:throwCard(equip_id, target, source)
        local card = sgs.Sanguosha:getCard(equip_id)
        if card:isRed() then
		    supCard = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())        
            supCard:addSubcard(equip_id)
            supCard:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(supCard, source, source), true) --只能对自己用
            supCard:deleteLater()

            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = target  
            damage.damage = 1  
            room:damage(damage)
        --else
        --    room:throwCard(equip_id, target, source)            
        end
    end  
}  
  
xianlu = sgs.CreateZeroCardViewAsSkill{  
    name = "xianlu",        
    view_as = function(self)  
        local card = xianluCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#xianluCard")  
    end  
}
nahualaoxian_feng:addSkill(xianlu)
nahualaoxian_feng:addSkill("taidan")
sgs.LoadTranslationTable{  
    ["nahualaoxian_feng"] = "南华老仙",  
    ["xianlu"] = "仙箓",  
    [":xianlu"] = "出牌阶段限一次，你可以弃置一名角色场上的一张装备牌，若此牌为红色，你将此牌当【乐不思蜀】置入你的判定区并对其造成1点伤害",  
}
pangdegong_feng = sgs.General(extension, "pangdegong_feng", "qun", 3)
mingshiLimitCard = sgs.CreateSkillCard{
    name = "mingshiLimitCard",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source)
        local choice = room:askForChoice(source, self:objectName(), "draw+recover+damage+move")
        if choice == "draw" then
            source:drawCards(2,self:objectName())
        elseif choice == "recover" and source:isWounded() then
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 1  
            room:recover(source, recover)  
        elseif choice == "damage" then
            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = room:askForPlayerChosen(source,room:getOtherPlayers(source),self:objectName())
            damage.damage = 1
            damage.reason = self:objectName()
            room:damage(damage)
        elseif choice == "move" then
            room:askForQiaobian(source,room:getAlivePlayers(),self:objectName(), "@mingshiLimit-move", true, true)
        end
        room:setPlayerMark(source,"@mingshiLimit",0) --标记已经使用
        return false
    end
}

mingshiLimit = sgs.CreateZeroCardViewAsSkill{  
    name = "mingshiLimit",
    limit_mark = "@mingshiLimit",
    view_as = function(self)  
        local card = mingshiLimitCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@mingshiLimit") > 0
    end  
}

lingjian = sgs.CreateTriggerSkill{  
    name = "lingjian",
    events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:hasSkill(self:objectName()) and not use.from:hasFlag("slash_used") then --自己本回合第一次用杀
                room:setPlayerFlag(use.from,"slash_used") --给自己标记本回合使用过杀
                use.card:setFlags("mingshiLimit_slash") --给杀标记
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card:hasFlag("mingshiLimit_slash") then --造成伤害
                room:setPlayerFlag(damage.from,"mingshiLimit_damage")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("mingshiLimit_slash") then --清除标记
                use.card:setFlags("-mingshiLimit_slash")
                if not use.from:hasFlag("mingshiLimit_damage") then
                    room:setPlayerMark(use.from,"@mingshiLimit",1)
                end
            end
        end
        return ""
    end
}
pangdegong_feng:addSkill(mingshiLimit)
pangdegong_feng:addSkill(lingjian)
sgs.LoadTranslationTable{
    ["pangdegong_feng"] = "庞德公",
    ["mingshiLimit"] = "明识",
    [":mingshiLimit"] = "限定技。出牌阶段，你可以选择1项：（1）摸2张牌（2）恢复1点体力（3）对一名其他角色造成1点伤害（4）移动场上1张牌。当你每回合首次使用【杀】结算后，若此牌未造成伤害，“明识”视为未发动过",
    ["lingjian"] = "令荐",
    [":lingjian"] = "当你每回合首次使用【杀】结算后，若此牌未造成伤害，“明识”视为未发动过",
}

--[[
peixiu_feng = sgs.General(extension, "peixiu_feng", "qun", 3)
zhitu = sgs.CreateViewAsSkill{  
    name = "zhitu",  
    view_filter = function(self, selected, to_select)
        local total_points = 0  
        for _, card in ipairs(selected) do  
            total_points = total_points + card:getNumber()  
        end  
        return total_points < 13
    end,  
    view_as = function(self, cards)  
        if #cards < 2 then return nil end
        local card_name = sgs.Self:getTag(self:objectName()):toString()
		if card_name ~= "" then
			local view_as_card = sgs.Sanguosha:cloneCard(card_name)
            for _,card in ipairs(cards) do
                view_as_card:addSubcard(card:getId())
            end
			view_as_card:setSkillName(self:objectName())
			view_as_card:setShowSkill(self:objectName())
			return view_as_card
		end
    end,  
    enabled_at_play = function(self, player)  
        return true
    end,
    vs_card_names = function(self, selected)  
        -- 检查是否有选中的牌  
        if #selected < 2 then return "" end  
          
        -- 计算选中牌的点数和  
        local total_points = 0  
        for _, card in ipairs(selected) do  
            total_points = total_points + card:getNumber()  
        end  
          
        -- 只有点数和等于13时才返回锦囊牌列表  
        if total_points == 13 then  
            return nil --这里要列举所有锦囊
        else  
            return "" -- 返回空列表，不显示guhuo框  
        end  
    end
}
peixiu_feng:addSkill(zhitu)
sgs.LoadTranslationTable{
    ["peixiu_feng"] = "裴秀",
    ["zhitu"] = "制图",
    [":zhitu"] = "你可以将点数和等于13的至少2张牌当任意锦囊使用",
}
]]

quyi_feng = sgs.General(extension, "quyi_feng", "qun", 4)
fuqi = sgs.CreateTriggerSkill{  
    name = "fuqi",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:getTypeId() == sgs.Card_TypeSkill then return "" end
            if not use.card:isKindOf("Slash") then return "" end
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
            if use.from ~= owner and use.from:distanceTo(owner) <= 1 and use.to:contains(owner) then
                return self:objectName(),owner:objectName()
            elseif use.from == owner then
                return self:objectName(),owner:objectName()
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(), data) then
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
        disresponsive_list = use.disresponsive_list
        if use.from ~= ask_who  and use.from:distanceTo(ask_who) <= 1 and use.to:contains(ask_who) then
            table.insert(disresponsive_list,ask_who:objectName())
        elseif use.from == ask_who then
            for _,p in sgs.qlist(use.to) do
                if ask_who:distanceTo(p) <= 1 then
                    table.insert(disresponsive_list,p:objectName())
                end
            end
        end
        use.disresponsive_list = disresponsive_list
        data:setValue(use)
    end
}
jiaozi = sgs.CreateTriggerSkill{  
    name = "jiaozi",  
    events = {sgs.DamageCaused, sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() >= player:getHandcardNum() then
                    return ""
                end
            end
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()
        damage.damage = damage.damage + 1
        data:setValue(damage)
        return false        
    end  
}
quyi_feng:addSkill(fuqi)
quyi_feng:addSkill(jiaozi)
sgs.LoadTranslationTable{
    ["quyi_feng"] = "麹义",
    ["fuqi"] = "伏骑",
    [":fuqi"] = "锁定技。你对你距离为1的角色使用的【杀】不能被响应；到你距离为1的角色对你使用的【杀】不能被响应",
    ["jiaozi"] = "骄恣",
    [":jiaozi"] = "锁定技。你造成或受到伤害时，若你的手牌数全场唯一最多，此伤害+1",--四象封印原版是首次
}

simahui_feng = sgs.General(extension, "simahui_feng", "qun", 3)
jianjieUse = sgs.CreateZeroCardViewAsSkill{
    name = "jianjieUse",
    response_pattern = "@@jianjieUse",
    response_or_use = true,
    view_as = function(self)
		local card_id = sgs.Self:getMark("jianjieUseCardid") - 1
		local card = sgs.Sanguosha:getCard(card_id)
        local new_card = nil
        if card:isBlack() then
            new_card = sgs.Sanguosha:cloneCard("iron_chain", card:getSuit(), card:getNumber())
        elseif card:isRed() then
            new_card = sgs.Sanguosha:cloneCard("fire_attack", card:getSuit(), card:getNumber())
        end 
        return new_card
	end,
}
jianjie = sgs.CreateTriggerSkill{  
    name = "jianjie",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(),data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if not p:isNude() then  
                targets:append(p)  
            end  
        end
        local chosen_players = room:askForPlayersChosen(player, targets, self:objectName(), 0, 3, "请选择至多3名角色", false)
        if chosen_players and not chosen_players:isEmpty() then  
            for _,target in sgs.qlist(chosen_players) do
                local card_id = room:askForCardChosen(player,target,"he",self:objectName())
                room:showCard(target,card_id)
                local card = sgs.Sanguosha:getCard(card_id)
                room:setPlayerMark(target, "jianjieUseCardid", card_id + 1)
                local prompt = ""
                if card:isBlack() then
                    prompt = "你可以使用这张牌当【铁索连环】使用"
                elseif card:isRed() then
                    prompt = "你可以使用这张牌当【火攻】使用"
                end
                room:askForUseCard(target, "@@jianjieUse", prompt)
                room:setPlayerMark(target, "jianjieUseCardid", 0)
            end
        end  
    end
}

chenhao = sgs.CreateTriggerSkill{  
    name = "chenhao",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
        local damage = data:toDamage()  
        if damage.nature ~= sgs.DamageStruct_Normal then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and not owner:hasFlag("chenhao_used") then
                return self:objectName(),owner:objectName()
            end
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if ask_who:isFriendWith(p) then  
                targets:append(p)  
            end  
        end
        local target = room:askForPlayerChosen(ask_who, targets, self:objectName())
        target:drawCards(1,self:objectName())
        room:setPlayerFlag(ask_who,"chenhao_used")
    end
}
simahui_feng:addSkill(jianjie)
simahui_feng:addSkill(chenhao)
if not sgs.Sanguosha:getSkill("jianjieUse") then skills:append(jianjieUse) end
sgs.LoadTranslationTable{
    ["simahui_feng"] = "司马徽",
    ["jianjie"] = "荐杰",
    [":jianjie"] = "准备阶段，你可以展示至多三名角色各一张牌，这些角色依次可以将展示的红色/黑色牌当【火攻】/【铁索连环】使用。",
    ["chenhao"] = "称好",
    [":chenhao"] = "每回合限一次，当任意角色受到属性伤害后，你可以令一名与你势力相同的角色摸1张牌。 ",
}

sunluyu_feng = sgs.General(extension, "sunluyu_feng", "wu", 3, false)
mumuMove = sgs.CreateTriggerSkill{  
    name = "mumuMove",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start and not player:isKongcheng() then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if room:askForDiscard(player, self:objectName(), 1, 1, true, false) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        room:askForQiaobian(player, room:getAlivePlayers(), self:objectName(), "@mumu-move", true, false)
    end
}

meibu = sgs.CreateTriggerSkill{  
    name = "meibu",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:getWeapon() and not use.from:isKongcheng() then
                local owner = room:findPlayerBySkillName(self:objectName())
                if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and not owner:willBeFriendWith(use.from) then
                    return self:objectName(),owner:objectName()
                end
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
        room:askForDiscard(use.from, self:objectName(), 1, 1, false, false)
    end
}
sunluyu_feng:addSkill(mumuMove)
sunluyu_feng:addSkill(meibu)
sgs.LoadTranslationTable{
    ["sunluyu_feng"] = "孙鲁育",
    ["mumuMove"] = "穆穆",
    [":mumuMove"] = "准备阶段，你可以弃置1张手牌，然后移动场上一张装备",
    ["meibu"] = "魅步",
    [":meibu"] = "其他势力角色使用杀时，若其装备区有武器，你可以令其弃置1张手牌",
}

sunshao_feng = sgs.General(extension, "sunshao_feng", "wu", 3)
dingyi = sgs.CreateTriggerSkill{  
    name = "dingyi",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) 
            and player:isFriendWith(owner) and player:getEquips():isEmpty() then 
                return self:objectName(),player:objectName()
            end  
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        ask_who:drawCards(1,self:objectName())
    end
}
zuici = sgs.CreateTriggerSkill{  
    name = "zuici",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        return self:objectName()
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        room:askForQiaobian(player, room:getAlivePlayers(), self:objectName(), "@zuici-move", true, true)
    end
}
sunshao_feng:addSkill(dingyi)
sunshao_feng:addSkill(zuici)
sgs.LoadTranslationTable{
    ["sunshao_feng"] = "孙邵",
    ["dingyi"] = "定仪",
    [":dingyi"] = "与你势力相同的角色结束阶段，若其装备区没有牌，其可以摸1张牌",
    ["zuici"] = "罪辞",
    [":zuici"] = "你受到伤害后，你可以移动场上一张牌"
}

sunyi_feng = sgs.General(extension, "sunyi_feng", "wu", 4)
zaoli = sgs.CreateTriggerSkill{  
    name = "zaoli",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        if player:getHp() > 1 then
            room:loseHp(player,1)
        end
        choices = {}
        if not player:isKongcheng() then
            table.insert(choices,"hand")
        end
        if not player:getEquips():isEmpty() then
            table.insert(choices,"equip")
        end
        local choice = room:askForChoice(player,self:objectName(),table.concat(choices, "+"))
        local n = 0
        if choice == "hand" then
            n = player:getHandcardNum()
            player:throwAllHandCards()
        elseif choice == "equip" then
            n = player:getEquips():length()
            player:throwAllEquips()
        end
        n = n + player:getLostHp()
        player:drawCards(n,self:objectName())
    end
}
sunyi_feng:addSkill(zaoli)
sgs.LoadTranslationTable{
    ["sunyi_feng"] = "孙翊",
    ["zaoli"] = "躁厉",
    [":zaoli"] = "锁定技。准备阶段，若你的体力值大于1，你失去1点体力；你弃置你手牌/装备区所有牌，并摸等量+已失去体力数张牌",
}

taoqian_feng = sgs.General(extension, "taoqian_feng", "qun", 3)
yirang = sgs.CreateTriggerSkill{  
    name = "yirang",  
    events = {sgs.EventPhaseStart},  
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Play and not player:isKongcheng() then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        --展示所有手牌
        room:showAllCards(player)
        --找到最小手牌数量
        local min_num = player:getHandcardNum()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if p:getHandcardNum() < min_num then  
                min_num = p:getHandcardNum()
            end  
        end
        --找到其他角色中最小手牌角色
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if p:getHandcardNum() == min_num then  
                targets:append(p)  
            end  
        end
        if targets:isEmpty() then return false end
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@yirang-choose", true)
        if target then
            --获得手牌类型数
            local types = {}
            for _, card in sgs.qlist(player:getHandcards()) do
                types[card:getTypeId()] = true
            end
            --将手牌给目标
            local source_handcards = player:handCards()  
            if not source_handcards:isEmpty() then  
                local move1 = sgs.CardsMoveStruct()  
                move1.card_ids = source_handcards  
                move1.to = target  
                move1.to_place = sgs.Player_PlaceHand  
                room:moveCardsAtomic(move1, false)  
            end
            --摸类别数的牌
            player:drawCards(#types, self:objectName())
        end
    end
}
taoqian_feng:addSkill(yirang)
sgs.LoadTranslationTable{
    ["taoqian_feng"] = "陶谦",
    ["yirang"] = "揖让",
    [":yirang"] = "出牌阶段开始时，你可以展示你的所有手牌，将这些牌交给一名手牌数最少的其他角色，然后你摸X张牌，X为这些牌的类别数",
}

tianfeng_feng = sgs.General(extension, "tianfeng_feng", "qun", 3)
gangjian = sgs.CreateTriggerSkill{  
    name = "gangjian",  
    events = {sgs.EventPhaseStart, sgs.SlashMissed},  
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and not owner:willBeFriendWith(player) then
                return self:objectName(),owner:objectName()
            end
        elseif event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if effect.slash:getSkillName() == self:objectName() then
                room:setPlayerCardLimitation(effect.from, "use", "TrickCard", true)  --true表示单回合标记，会自动清除
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
        slash:setSkillName(self:objectName())  
        local use = sgs.CardUseStruct()  
        use.card = slash  
        use.from = player
        use.to:append(ask_who)  
        room:useCard(use) 
        slash:deleteLater()
    end
}
guijieVS = sgs.CreateViewAsSkill{  
    name = "guijie",
    n = 2,  
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then return true end
        if #selected == 1 then return selected[1]:getColor() == to_select:getColor() end
        return false
    end,  
    view_as = function(self, cards)  
        if #cards == 2 then            
            local view_as_card = sgs.Sanguosha:cloneCard("jink")
            view_as_card:setCanRecast(false)
            view_as_card:addSubcard(cards[1])
            view_as_card:addSubcard(cards[2])
            view_as_card:setSkillName(self:objectName())
            view_as_card:setShowSkill(self:objectName())
            return view_as_card
        end  
    end,  
    enabled_at_play = function(self, player)  
        return false
    end,  
    enabled_at_response = function(self, player, pattern)
        return pattern == "jink"
    end
}
guijie = sgs.CreateTriggerSkill{  
    name = "guijie",  
    events = {sgs.CardResponded, sgs.CardUsed},  
    view_as_skill = guijieVS,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then 
            return false
        end  

        local card = nil  
        if event == sgs.CardResponded then  
            card = data:toCardResponse().m_card  
        else  
            card = data:toCardUse().card  
        end  
        if card and card:isKindOf("Jink") and card:getSkillName() == self:objectName() then
            player:drawCards(1,self:objectName())
        end  
        return false
    end
}
tianfeng_feng:addSkill(gangjian)
tianfeng_feng:addSkill(guijie)
sgs.LoadTranslationTable{
    ["tianfeng_feng"] = "田丰",
    ["gangjian"] = "刚谏",
    [":gangjian"] = "其他势力角色的准备阶段，你可以令其视为对你使用1张杀，若此杀未造成伤害，其本回合不能使用锦囊",
    ["guijie"] = "瑰杰",
    [":guijie"] = "你可以将2张红色牌当作【闪】使用或打出，然后你摸1张牌",
}

wangshen_feng = sgs.General(extension, "wangshen_feng", "wei", 3)
anran = sgs.CreateTriggerSkill{  
    name = "anran",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 询问是否发动技能  
        if room:askForSkillInvoke(player, self:objectName(), data) then  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local n = player:getMark("@anran")
        if n == 0 then
            n = 1
        end
        player:drawCards(n,self:objectName())
        room:setPlayerMark(player,"@anran",math.min(n+1,4))
    end  
}
gaofa = sgs.CreateTriggerSkill{  
    name = "gaofa",  
    events = {sgs.Damaged, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            room:setPlayerFlag(damage.to,"gaofa_damaged")
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and not player:hasSkill(self:objectName()) then
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:hasShownSkill(self:objectName())) then return "" end --必须展示此技能才有发动时机
            local n = 0
            local target = nil
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("gaofa_damaged") then
                    n = n + 1
                    target = p
                end
            end
            if n == 1 then
                return self:objectName(),owner:objectName()
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return true
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasFlag("gaofa_damaged") then
                player = p
                break
            end
        end
        local choice = room:askForChoice(player,self:objectName(),"slash+reset")
        if choice == "slash" then
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if player:inMyAttackRange(p) then
                    targets:append(p)  
                end
            end  
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@gaofa-choose", true)
            if target then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName(self:objectName())  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = player  
                use.to:append(target)  
                room:useCard(use) 
                slash:deleteLater()
            else
                room:setPlayerMark(ask_who,"@anran",1)
            end
        elseif choice == "reset" then
            room:setPlayerMark(ask_who,"@anran",1)
        end
    end  
}

wangshen_feng:addSkill(anran)
wangshen_feng:addSkill(gaofa)
sgs.LoadTranslationTable{
    ["wangshen_feng"] = "王沈",
    ["anran"] = "岸然",
    [":anran"] = "你受到伤害后，你可以摸1张牌，然后下次以此法摸牌数+1，至多为4",
    ["gaofa"] = "告发",
    [":gaofa"] = "锁定技。其他角色回合结束时，若本回合仅有一名受到伤害角色存活，其选择（1）视为使用1张杀（2）重置“岸然”",
}

wangyun_feng = sgs.General(extension, "wangyun_feng", "qun", 3)
zongji = sgs.CreateTriggerSkill{  
    name = "zongji",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        local damage = data:toDamage()
        if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
            if damage.from and damage.from:isAlive() and damage.to and damage.to:isAlive() then
                return self:objectName(), owner:objectName()
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() and not damage.from:isNude() then
            local card_id = room:askForCardChosen(ask_who, damage.from, "he", self:objectName())
            room:throwCard(card_id, damage.from, ask_who)
        end
        if damage.to and damage.to:isAlive() and not damage.to:isNude() then
            local card_id = room:askForCardChosen(ask_who, damage.to, "he", self:objectName())
            room:throwCard(card_id, damage.to, ask_who)
        end
    end  
}
wangyun_feng:addSkill(zongji)
sgs.LoadTranslationTable{
    ["wangyun_feng"] = "王允",
    ["zongji"] = "纵计",
    [":zongji"] = "一名角色受到杀或决斗的伤害后，你可以弃置其与伤害来源各1张牌",
}

wenyuan_feng = sgs.General(extension, "wenyuan_feng", "shu", 3, false)  
kengqiang = sgs.CreateTriggerSkill{
    name = "kengqiang",
    events = {sgs.CardUsed, sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not skillTriggerable(player, self:objectName()) then
            return false
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if isDamageCard(use.card) and not player:hasFlag("kengqiang_used") then
                return self:objectName()
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("kengqiang_add") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then
            room:setPlayerFlag(player,"kengqiang_used")
			return true
		end
        return false 
    end,  
      
    on_effect = function(self, event, room, player, data)
        local choice = room:askForChoice(player,self:objectName(),"draw+damage")
        if choice == "draw" then
            player:drawCards(2,self:objectName())
        else
            room:loseHp(player,1)
            local use = data:toCardUse()
            use.card:setFlags("kengqiang_add")
            data:setValue(use)
        end
    end
}

shangjue = sgs.CreateTriggerSkill{  
    name = "shangjue",  
    events = {sgs.Dying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@shangjue",
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:hasSkill(self:objectName()) and player:getMark("@shangjue") > 0) then return "" end
        local dying = data:toDying()
        if dying.who == player then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(player, "@shangjue", 0)
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)
        local dying = data:toDying()
        local recover = sgs.RecoverStruct()  
        recover.recover = dying.who:getMaxHp() - dying.who:getHp()
        room:recover(dying.who, recover)
        if player:hasSkill("kengqiang") and room:askForChoice(player,"你可以失去“铿锵”令此技能视为未发动过","yes+no") == "yes" then
            if player:inHeadSkills(self:objectName()) then
                room:handleAcquireDetachSkills(player, "-kengqiang")
            else
                room:handleAcquireDetachSkills(player, "-kengqiang!")
            end
            room:setPlayerMark(player, "@shangjue", 1)
        end
    end
}
wenyuan_feng:addSkill(kengqiang)
wenyuan_feng:addSkill(shangjue)
sgs.LoadTranslationTable{
	["wenyuan_feng"] = "文鸳",
	["kengqiang"] = "铿锵",
	[":kengqiang"] = "每回合限一次，当你使用伤害牌时，你可以选择一项：1.摸两张牌；2.失去1点体力，令此牌伤害+1",
    ["shangjue"] = "殇决",
    [":shangjue"] = "限定技，当你进入濒死状态时，你可以将体力回复至体力上限，然后你可以失去“铿锵”令此技能视为未发动过"
}
xiaohouba_feng = sgs.General(extension, "xiaohouba_feng", "shu", 4)
baobianSlash = sgs.CreateTriggerSkill{  
    name = "baobianSlash",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Play then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:loseHp(player,1)
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if not player:isFriendWith(p) then  
                targets:append(p)  
            end  
        end
        local target = room:askForPlayerChosen(player, targets, self:objectName())
        if target then
            local card_id = room:askForCardChosen(target, target, "h", self:objectName())
            local card = sgs.Sanguosha:getCard(card_id)
            room:throwCard(card_id, target, target)
            if card:isKindOf("BasicCard") then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName(self:objectName())  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = player  
                use.to:append(target)  
                room:useCard(use,false)
                slash:deleteLater()
            end
        end
    end,
}
xiaohouba_feng:addSkill(baobianSlash)
sgs.LoadTranslationTable{
    ["xiaohouba_feng"] = "夏侯霸",
    ["baobianSlash"] = "豹变",
    [":baobianSlash"] = "出牌阶段开始时，你可以失去一点体力并令一名其他势力角色弃置1张手牌，若此牌为基础牌，视为你对其使用1张不计入次数的杀",
}

xushu_feng = sgs.General(extension, "xushu_feng", "shu", 3)
wuyanNull = sgs.CreateOneCardViewAsSkill{  
    name = "wuyanNull",  
    filter_pattern = "TrickCard",  
    view_as = function(self, card)  
        local Nullification = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())  
        Nullification:addSubcard(card:getId())  
        Nullification:setSkillName(self:objectName())  --设置转化牌的技能名
        Nullification:setShowSkill(self:objectName())  --使用时亮将
        return Nullification  
    end,
    enabled_at_play = function(self, player)  
        return false  -- 出牌阶段不能主动使用  
    end,  
    enabled_at_response = function(self, player, pattern)  
        return pattern == "nullification"  -- 只在需要无懈可击时可用  
    end,  
    enabled_at_nullification = function(self, player)
        return not player:isKongcheng()
    end
}

jujianNull = sgs.CreateTriggerSkill{
    name = "jujianNull",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Nullification") then
                return self:objectName()
            end
        end
        return false
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if player:isFriendWith(p) then  
                targets:append(p)  
            end  
        end
        local target = room:askForPlayerChosen(player, targets, self:objectName())  
        local use = data:toCardUse()
        if target and target:isAlive() then  
            target:obtainCard(use.card)  
        end  
    end
}
xushu_feng:addSkill(wuyanNull)
xushu_feng:addSkill(jujianNull)
sgs.LoadTranslationTable{
    ["xushu_feng"] = "徐庶",
    ["wuyanNull"] = "无言",
    [":wuyanNull"] = "你的锦囊可以视为【无懈可击】",
    ["jujianNull"] = "举荐",
    [":jujianNull"] = "你使用【无懈可击】完成后，你可以将此牌交给一名相同势力的其他角色"
}

yanghu_feng = sgs.General(extension, "yanghu_feng", "wei", 4)
mingfaDamageCard = sgs.CreateSkillCard{
    name = "mingfaDamageCard",
    target_fixed = false,
    will_throw = true,

    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:getHp() > 1
    end,  
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local damage = sgs.DamageStruct()  
        damage.from = source  
        damage.to = target
        damage.damage = 1
        damage.reason = self:objectName()
        room:damage(damage)

        room:setPlayerMark(source,"@mingfa_used",1) --标记已经使用
        room:setPlayerMark(target,"@mingfa_target",1) --标记明伐目标
        return false
    end
}

mingfaDamageVS = sgs.CreateZeroCardViewAsSkill{  
    name = "mingfaDamage",
    view_as = function(self)  
        local card = mingfaDamageCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@mingfa_used") == 0
    end  
}

mingfaDamage = sgs.CreateTriggerSkill{  
    name = "mingfaDamage",
    view_as_skill = mingfaDamageVS,
    events = {sgs.Death, sgs.HpRecover},  
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end  
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:getMark("@mingfa_target") > 0 then --明伐目标死亡，恢复技能
                room:setPlayerMark(owner,"@mingfa_used",0)
            end
        elseif event == sgs.HpRecover then
            if player:getMark("@mingfa_target") > 0 then --明伐目标恢复体力，恢复技能
                room:setPlayerMark(owner,"@mingfa_used",0)
            end
        end
        return ""
    end
}
yanghu_feng:addSkill(mingfaDamage)
sgs.LoadTranslationTable{
    ["yanghu_feng"] = "羊祜",
    ["mingfaDamage"] = "明伐",
    [":mingfaDamage"] = "出牌阶段，你可以对一名体力值大于1的角色造成1点伤害，然后此技能失效直到其死亡或恢复体力",
}

zerong_feng = sgs.General(extension, "zerong_feng", "qun", 4)
  
cansi = sgs.CreateTriggerSkill{  
    name = "cansi",  
    events = {sgs.EventPhaseStart, sgs.Damage},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
        if event == sgs.EventPhaseStart then  
            -- 准备阶段触发  
            if player:getPhase() == sgs.Player_Start then
                return self:objectName()
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
  
cansi = sgs.CreateTriggerSkill{  
    name = "cansi",  
    events = {sgs.EventPhaseStart},--sgs.Damage
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:inMyAttackRange(p) then
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
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then  
            return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
        else  
            -- 造成伤害时自动触发  
            return true  
        end  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:inMyAttackRange(p) then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@cansi-invoke", true, true)  
            if target then
                if not player:isNude() then
                    local card_id = room:askForCardChosen(target, player, "he", self:objectName())
                    room:obtainCard(target,card_id,false)
                end
                --[[
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
                ]]
                -- 依次使用杀、决斗、火攻  
                local cards = {"slash", "duel"}--, "fire_attack"}  
                for _, card_name in ipairs(cards) do  
                    if player:isAlive() and target:isAlive() then  
                        local card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_NoSuit, 0)  
                        card:setSkillName(self:objectName())  
                        card:deleteLater()
                        
                        local use = sgs.CardUseStruct()  
                        use.card = card  
                        use.from = player  
                        use.to:append(target)  
                        room:useCard(use, false)  
                    end  
                end  
            end
        elseif event == sgs.Damage then  
            -- 每当目标受到1次伤害后，摸2张牌  
            player:drawCards(2, self:objectName())  
        end
        return false  
    end  
}  
zerong_feng:addSkill(cansi)  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["zerong_feng"] = "笮融",  
    ["cansi"] = "残肆",  
    [":cansi"] = "准备阶段，你可以跳过摸牌阶段，并选择一名其他角色，令你与其各回复一点体力，然后你视为对其依次使用【杀】、【决斗】、【火攻】。每当你以此法造成1次伤害后，你摸2张牌。",  
    [":cansi"] = "锁定技。准备阶段，你令攻击范围内一名角色获得你一张牌，然后视为你对其依次使用【杀】、【决斗】",  
    ["@cansi-invoke"] = "残肆：选择一名其他角色"  
}

zhangfen_feng = sgs.General(extension, "zhangfen_feng", "wu", 4)  
wangluCard = sgs.CreateSkillCard{  
    name = "wangluCard",  
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:getEquips():isEmpty()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local range = target:getAttackRange()--弃置前角色的攻击范围
        -- 选择并弃置目标角色的一张装备  
        local equip_id = room:askForCardChosen(source, target, "e", "wanglu")  
        room:throwCard(equip_id, target, source)

        local equip = sgs.Sanguosha:getCard(equip_id)
        if equip:isKindOf("Weapon") then --是武器，摸武器的攻击范围
            --是武器的攻击范围，不是角色的攻击范围，角色的攻击范围可能通过其他方式修改
            --武器的攻击范围 = 弃置前的攻击范围 - 弃置后的攻击范围 + 1
            target:drawCards(range - target:getAttackRange() + 1,self:objectName())
        end 
    end  
}  
  
wanglu = sgs.CreateZeroCardViewAsSkill{  
    name = "wanglu",        
    view_as = function(self)  
        local card = wangluCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#wangluCard")  
    end  
}  

zhangfen_feng:addSkill(wanglu)
sgs.LoadTranslationTable{
    ["zhangfen_feng"] = "张奋",
    ["wanglu"] = "望橹",
    [":wanglu"] = "出牌阶段限一次。你可以弃置场上一张装备牌；若为武器牌，失去该牌的角色摸X张牌，X为该武器的攻击范围"
}

zhangxuan_feng = sgs.General(extension, "zhangxuan_feng", "wu", 4, false)  
tongli = sgs.CreateTriggerSkill{
    name = "tongli",
    events = {sgs.CardUsed, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not skillTriggerable(player, self:objectName()) then
            return false
        end
        if event == sgs.EventPhaseStart then
            room:setPlayerMark(player,"@tongli",0)
            return false
        end
        if player:getPhase() ~= sgs.Player_Play then return false end --出牌阶段
        local current = room:getCurrent()
        if current ~= player then return false end --自己的出牌阶段
        local use = data:toCardUse()
        if use.card:getTypeId() == sgs.Card_TypeSkill then return false end
        if use.card:hasFlag("tongli") then return false end
        --使用牌的数量
        room:addPlayerMark(player,"@tongli")
        --手牌中的花色
        local suits = {}  
        local suit_count = 0  
        for _, card in sgs.qlist(player:getHandcards()) do  
            local suit = card:getSuitString()  
            if not suits[suit] then  
                suits[suit] = true  
                suit_count = suit_count + 1  
            end  
        end
        if player:getMark("@tongli") == suit_count then
            return self:objectName()
        end
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then
			return true
		end
        return false 
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()
        local card = use.card
        card:setFlags("tongli")
        local new_use = sgs.CardUseStruct()  
        new_use.card = use.card  
        new_use.from = use.from  
        new_use.to = use.to  
        room:useCard(new_use) --额外结算。直接用use，方天画戟杀不会再次生效
        return false  
    end  
}  
zhangxuan_feng:addSkill(tongli)
sgs.LoadTranslationTable{
	["zhangxuan_feng"] = "张璇",
	["tongli"] = "同礼",
	[":tongli"] = "出牌阶段，当你使用牌时，若你手牌中的花色数等于你此阶段已使用的牌数，你可以令此牌额外执行1次。",
}
zhangyi_feng = sgs.General(extension, "zhangyi_feng", "shu", 4)
zhiyi = sgs.CreateTriggerSkill{  
    name = "zhiyi",  
    events = {sgs.CardUsed, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:hasSkill(self:objectName()) then
                room:setPlayerFlag(use.from,"zhiyi_used_slash")
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and owner:hasFlag("zhiyi_used_slash") then 
                return self:objectName(),owner:objectName()
            end  
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local choice = room:askForChoice(ask_who, self:objectName(), "draw+slash")
        if choice == "draw" then
            ask_who:drawCards(1,self:objectName())
        else
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(ask_who)) do  
                if ask_who:inMyAttackRange(p) then  
                    targets:append(p)  
                end  
            end
            local target = room:askForPlayerChosen(ask_who, targets, self:objectName(), "@zhiyi", true)
            if target then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName(self:objectName())  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = ask_who  
                use.to:append(target)  
                room:useCard(use) 
                slash:deleteLater()
            else
                ask_who:drawCards(1,self:objectName())
            end
        end
    end
}
zhangyi_feng:addSkill(zhiyi)
sgs.LoadTranslationTable{
    ["zhangyi_feng"] = "张翼",
    ["zhiyi"] = "执义",
    [":zhiyi"] = "你使用过杀的回合结束时，你摸1张牌或视为使用一张杀",
}

zhaoyan_feng = sgs.General(extension, "zhaoyan_feng", "wu", 3, false)
jinhui = sgs.CreateTriggerSkill{  
    name = "jinhui",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(),data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        --摸牌堆3张牌
        local ids = room:getNCards(3)  
        local card_ids = sgs.IntList()  
        for _, card_id in sgs.qlist(ids) do  
            card_ids:append(card_id)  
        end
        --你选一张并使用
        room:fillAG(card_ids, player)  
        local card_id = room:askForAG(player, card_ids, false, self:objectName())  
        room:clearAG(player)
        local card = sgs.Sanguosha:getCard(card_id)
        if card and not (card:isKindOf("Jink") or card:isKindOf("Nullification") or card:isKindOf("ThreatenEmperor")) then
            room:setPlayerMark(player, "zhuikongCardid", card_id + 1)
            local prompt = "你可以使用这张牌（【"
            if room:askForUseCard(player, "@@zhuikongUse", prompt .. card:getName() .. "】）") then
                card_ids:removeOne(card_id)
                for _, id in sgs.qlist(card_ids) do
                    if card:getColor() == sgs.Sanguosha:getCard(id):getColor() then
                        card_ids:removeOne(id)
                    end
                end
            end
            room:setPlayerMark(player, "zhuikongCardid", 0)
        end
        --选择一个目标，该目标选一张并使用
        local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName())
        room:fillAG(card_ids, target)  
        local card_id = room:askForAG(target, card_ids, false, self:objectName())  
        room:clearAG(target)
        local card = sgs.Sanguosha:getCard(card_id)
        if card and not (card:isKindOf("Jink") or card:isKindOf("Nullification") or card:isKindOf("ThreatenEmperor")) then
            room:setPlayerMark(target, "zhuikongCardid", card_id + 1)
            local prompt = "你可以使用这张牌（【"
            room:askForUseCard(target, "@@zhuikongUse", prompt .. card:getName() .. "】）")
            room:setPlayerMark(target, "zhuikongCardid", 0)
        end
    end
}

qingman = sgs.CreateTriggerSkill{  
    name = "qingman",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
            local empty_slots = 0  
            for i = 0, 4 do  
                if not player:getEquip(i) then  
                    empty_slots = empty_slots + 1  
                end  
            end  
            local equips = player:getEquips()  
            for _, equip in sgs.qlist(equips) do  
                if equip:isKindOf("SixDragons") then  
                    -- 找到了六龙骖驾，占2个装备格子
                    empty_slots = empty_slots - 2
                    break  
                end  
            end
            if player:getHandcardNum() ~= empty_slots then
                return self:objectName()
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local empty_slots = 0  
        for i = 0, 4 do  
            if not player:getEquip(i) then  
                empty_slots = empty_slots + 1  
            end  
        end  
        local equips = player:getEquips()  
        for _, equip in sgs.qlist(equips) do  
            if equip:isKindOf("SixDragons") then  
                -- 找到了六龙骖驾，占2个装备格子
                empty_slots = empty_slots - 2
                break  
            end  
        end
        if player:getHandcardNum() > empty_slots then
            local n = player:getHandcardNum() - empty_slots
            room:askForDiscard(player,self:objectName(),n,n,false,false)
        elseif player:getHandcardNum() < empty_slots then
            player:drawCards(empty_slots - player:getHandcardNum())
        end
    end
}
zhaoyan_feng:addSkill(jinhui)
zhaoyan_feng:addSkill(qingman)
sgs.LoadTranslationTable{
    ["zhaoyan_feng"] = "赵嫣",
    ["jinhui"] = "锦绘",
    [":jinhui"] = "准备阶段，你可以亮出牌堆顶的三张牌，令你与一名其他角色依次使用其中一张牌，不能使用相同颜色的牌。",
    ["qingman"] = "轻幔",
    [":qingman"] = "锁定技，回合结束时，你将手牌数调整为X（X为你空置装备栏数）",
}

zhengxuan_feng = sgs.General(extension, "zhengxuan_feng", "qun", 3)
zhengjing = sgs.CreateTriggerSkill{  
    name = "zhengjing",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Draw and not player:isKongcheng() then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local n = math.min(player:getHandcardNum(),3)
        player:drawCards(n,self:objectName())
        room:showAllCards(player)  
        local suit = room:askForSuit(player, "zhengjing_suit") --这个直接就可以选花色，不需要再转换一次
        local card_ids = sgs.IntList()
        for _, card in sgs.qlist(player:getHandcards()) do
            if card:getSuit()==suit then
                card_ids:append(card:getId())
            end
        end
        if card_ids:isEmpty() then return false end
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
        local move1 = sgs.CardsMoveStruct()
        move1.card_ids = card_ids
        move1.from = player
        move1.to = target
        move1.to_place = sgs.Player_PlaceHand 
        room:moveCardsAtomic(move1, true)
    end
}
zhengxuan_feng:addSkill(zhengjing)
sgs.LoadTranslationTable{
    ["zhengxuan_feng"] = "郑玄",
    ["zhengjing"] = "整经",
    [":zhengjing"] = "摸牌阶段开始时，你可以摸X张牌（X为你的手牌数且至多为3）并展示所有手牌，你选择1种花色，将该花色所有牌交给一名其他角色",--没有这种花色怎么办，直接不给？
}

zhonghui_feng = sgs.General(extension, "zhonghui_feng", "wei", 4)
xingfa = sgs.CreateTriggerSkill{  
    name = "xingfa",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start and player:getHandcardNum()>=player:getHp() then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if not player:isFriendWith(p) then  
                targets:append(p)  
            end  
        end
        local target = room:askForPlayerChosen(player, targets, self:objectName())
        if target then
            local damage = sgs.DamageStruct()  
            damage.from = player  
            damage.to = target
            damage.damage = 1
            damage.reason = self:objectName()
            room:damage(damage)
        end
    end
}
zhonghui_feng:addSkill(xingfa)
sgs.LoadTranslationTable{
    ["zhonghui_feng"] = "钟会",
    ["xingfa"] = "兴伐",
    [":xingfa"] = "准备阶段，若你的手牌数不小于你的体力值，你可以对一名其他势力角色造成1点伤害",
}
sgs.Sanguosha:addSkills(skills)
return {extension}