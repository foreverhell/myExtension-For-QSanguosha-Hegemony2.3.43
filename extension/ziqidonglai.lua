
-- 武将定义  
extension = sgs.Package("ziqidonglai", sgs.Package_GeneralPack)  
--sgs.addNewKingdom("jin", "#ff35e4ff")  -- 使用橙红色作为火影势力的颜色

fengyu = sgs.General(extension, "fengyu", "qun", 3, false)  

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
                --room:acquireSkill(target,"tiqi_maxcards")
            else  
                room:setPlayerMark(player, "@tiqi_handcard_minus", y)  
                --room:acquireSkill(target,"tiqi_maxcards")
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
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        -- 移除所有角色的'梳'标记  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            room:setPlayerMark(p, "@shu1", 0)  
        end  
          
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

simalun = sgs.General(extension, "simalun", "wei", 3)  

luanchang = sgs.CreateTriggerSkill{  
    name = "luanchang",  
    frequency = sgs.Skill_Limited,  
    --limit_mark = "@luanchang",  
    events = {sgs.Damaged, sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.Damaged then  
            -- 监听伤害事件，给当前回合角色添加flag  
            local damage = data:toDamage()  
            if not damage.to then return "" end  
              
            local current = room:getCurrent()  
            if not current then return "" end  
              
            -- 检查是否有司马伦存在且技能可用  
            local simalun = room:findPlayerBySkillName(self:objectName())  
            if not (simalun and simalun:isAlive() and simalun:getMark("@luanchang") == 0) then return "" end  
              
            -- 检查受伤角色与司马伦势力相同  
            --if damage.to:getKingdom() == simalun:getKingdom() then  
            if damage.to:isFriendWith(simalun) then --必须明置，并且考虑野心家的情况
                room:setPlayerFlag(current, "luanchang_damaged")  
            end  
            return ""  
              
        elseif event == sgs.EventPhaseEnd then  
            -- 结束阶段检查flag并询问发动  
            if not (player and player:isAlive()) then return "" end  
            if player:getPhase() ~= sgs.Player_Finish then return "" end  
            if not player:hasFlag("luanchang_damaged") then return "" end  
              
            local simalun = room:findPlayerBySkillName(self:objectName())  
            if not (simalun and simalun:isAlive() and simalun:getMark("@luanchang") == 0) then return "" end  
            if player:getHandcardNum() == 0 then return "" end  
              
            return self:objectName(), simalun:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            if ask_who:askForSkillInvoke(self:objectName(), data) then  
                room:broadcastSkillInvoke(self:objectName())  
                room:removePlayerMark(ask_who, "@luanchang")  
                return true  
            end  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            room:setPlayerMark(ask_who,"@luanchang",1)
            -- 当前回合角色弃置所有手牌  
            --local handcards = player:getHandcards()  
            --if handcards:isEmpty() then return false end  
              
            player:throwAllHandCards()  
              
            -- 使用万箭齐发  
            local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)  
            archery_attack:setSkillName(self:objectName())  
              
            local use = sgs.CardUseStruct()  
            use.card = archery_attack  
            use.from = player  
              
            room:useCard(use)  
              
            -- 清除flag  
            room:setPlayerFlag(player, "-luanchang_damaged")  
        end  
        return false  
    end  
}
  
-- 司马伦 - 助澜技能    
zhulan = sgs.CreateTriggerSkill{  
    name = "zhulan",  
    events = {sgs.DamageInflicted},  
      
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive()) then return "" end  
        simalun = room:findPlayerBySkillName(self:objectName())
        if not (simalun and simalun:isAlive() and simalun:hasSkill(self:objectName())) then return "" end

        local damage = data:toDamage()  
        if not damage.from then return "" end  
        if damage.to:objectName() == simalun:objectName() then return "" end  
          
        -- 检查伤害来源与受伤角色势力相同  
        --if damage.from:getKingdom() == damage.to:getKingdom() then 
        if damage.from:isFriendWith(damage.to) then  --考虑野心家的情况
            if not simalun:isNude() then  
                return self:objectName(), simalun:objectName()
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        local _data = sgs.QVariant()  
        _data:setValue(damage.to)  
          
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            room:askForDiscard(ask_who, self:objectName(), 1, 1, false, true)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}  
  

simalun:addSkill(luanchang)  
simalun:addSkill(zhulan)

sgs.LoadTranslationTable{
["simalun"] = "司马伦",  
["#simalun"] = "篡逆之王",  
["luanchang"] = "乱常",   
[":luanchang"] = "限定技，一名角色的结束阶段，若有与你势力相同的角色于此回合内受到过伤害，你可令当前回合角色将所有手牌视为使用【万箭齐发】。",  
--与你势力相同的角色受到伤害时，给当前回合角色添加一个flag，有flag的角色回合结束时，你可以令其弃置所有手牌，视为使用万箭齐发
["@luanchang"] = "乱常",  
["zhulan"] = "助澜",  
[":zhulan"] = "当一名其他角色受到伤害时，若伤害来源与其势力相同，你可以弃置一张牌，令此伤害值+1。"
}

jiachong = sgs.General(extension, "jiachong", "wei", 3)  
  
BeiniCard = sgs.CreateSkillCard{  
    name = "BeiniCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:getHp() >= sgs.Self:getHp() and to_select:objectName()~=sgs.Self:objectName()
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 选择谁摸牌  
        local choice = room:askForChoice(source, "beini", "self+target",   
            sgs.QVariant(string.format("self:%s+target:%s", source:objectName(), target:objectName())))  
          
        local drawer, other  
        if choice == "self" then  
            drawer = source  
            other = target  
        else  
            drawer = target  
            other = source  
        end  
          
        -- 摸牌者摸两张牌  
        drawer:drawCards(2, "beini")  
          
        -- 未摸牌的角色选择  
        local choices = {}  
        if other:canSlash(drawer, nil, false) then  
            table.insert(choices, "slash")  
        end  
        if not drawer:isAllNude() then  
            table.insert(choices, "getcard")  
        end  
          
        if #choices > 0 then  
            local other_choice = room:askForChoice(other, "beini", table.concat(choices, "+"))  
            if other_choice == "slash" then  
                -- 视为使用杀  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName("beini")  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = other  
                use.to:append(drawer)  
                room:useCard(use)  
            elseif other_choice == "getcard" then  
                -- 获得一张牌  
                local card_id = room:askForCardChosen(other, drawer, "hej", "beini")  
                room:obtainCard(other, card_id, false)  
            end  
        end  
    end  
}  
  
-- 悖逆技能  
beini = sgs.CreateZeroCardViewAsSkill{  
    name = "beini",  
    view_as = function(self)  
        local card = BeiniCard:clone()  
        card:setShowSkill("beini")  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#BeiniCard")  
    end  
}
  
-- 技能2：定法  
dingfa = sgs.CreateTriggerSkill{  
    name = "dingfa",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
          
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then  
            -- 弃牌阶段开始时检查是否获得'定'标记
            discard_num = player:getHandcardNum() - player:getMaxCards()
            if discard_num >= player:getHp() then
                room:setPlayerFlag(player,"ding4")
            end  
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then  
            -- 弃牌阶段结束时检查是否有'定'标记  
            if player:hasFlag("ding4") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseEnd then  
            return player:askForSkillInvoke(self:objectName(),data)  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseEnd then                
            local choices = {}  
            if player:isWounded() then  
                table.insert(choices, "recover")  
            end  
              
            local others = room:getOtherPlayers(player)  
            for _, p in sgs.qlist(others) do  
                if not p:isAllNude() then  
                    table.insert(choices, "discard")
                    break  
                end  
            end                
            if #choices > 0 then  
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
                if choice == "recover" then  
                    local recover = sgs.RecoverStruct()  
                    recover.who = player  
                    recover.recover = 1  
                    room:recover(player, recover)  
                elseif choice == "discard" then  
                    local targets = sgs.SPlayerList()  
                    for _, p in sgs.qlist(others) do  
                        if not p:isAllNude() then  
                            targets:append(p)  
                        end  
                    end  
                      
                    local discarded = 0  
                    while discarded < 2 and not targets:isEmpty() do  
                        local target = room:askForPlayerChosen(player, targets, self:objectName(),   
                            "@dingfa-discard:" .. tostring(2 - discarded), true)  
                        if not target then break end  
                          
                        local card_id = room:askForCardChosen(player, target, "hej", self:objectName())  
                        room:throwCard(card_id, target, player)  
                        discarded = discarded + 1  
                          
                        if target:isAllNude() then  
                            targets:removeOne(target)  
                        end  
                    end  
                end  
            end  
        end  
        return false  
    end  
}  
  
  
-- 添加技能到武将  
jiachong:addSkill(beini)  
jiachong:addSkill(dingfa)  

sgs.LoadTranslationTable{
    ["jiachong"] = "贾充",
    ["beini"] = "悖逆",  
    [":beini"] = "出牌阶段限一次，选择一名体力≥你的角色，你或其摸两张牌，未摸牌的角色需选择：1.视为对摸牌者使用【杀】；2.获得摸牌者一张牌。",  
    ["@beini-target"] = "悖逆：选择一名体力不小于你的角色",  
    ["self"] = "你摸牌",  
    ["target"] = "其摸牌",  
    ["slash"] = "视为使用【杀】",  
    ["getcard"] = "获得一张牌",  
    
    -- 定法技能  
    ["dingfa"] = "定法",  
    [":dingfa"] = "弃牌阶段开始时，若需要弃置的牌数≥体力值，获得'定'标记；弃牌阶段结束时，若有'定'标记，可选择回复1点体力或弃置其他角色至多两张牌。",  
    ["ding4"] = '定',  
    ["recover"] = "回复1点体力",  
    ["discard"] = "弃置牌",  
    ["@dingfa-discard"] = "定法：选择一名其他角色，弃置其一张牌（还可弃置%arg张）",  
    ["#dingfa-clear"] = "定法",
}

jin_guohuai = sgs.General(extension, "jin_guohuai", "wei", 3, false)  
  
zhefu = sgs.CreateTriggerSkill{  
    name = "zhefu",  
    events = {sgs.CardUsed, sgs.CardResponded},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:getPhase() ~= sgs.Player_NotActive then return "" end  
          
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        if card then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if not p:isKongcheng() then  
                targets:append(p)  
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhefu-invoke", true, true)  
        if target then  
            room:broadcastSkillInvoke(self:objectName())  
            player:setTag("zhefu_target", sgs.QVariant(target:objectName()))  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local target_name = player:getTag("zhefu_target"):toString()  
        local target = room:findPlayer(target_name)  
        if not target or target:isKongcheng() then return false end  
          
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        local same_cards = false  
        for _, id in sgs.qlist(target:handCards()) do  
            local hand_card = sgs.Sanguosha:getCard(id)  
            if hand_card:objectName() == card:objectName() then  
                room:throwCard(id, target, player) 
                same_cards = true
            end  
        end  
        if not same_cards then
            local damage = sgs.DamageStruct()  
            damage.from = player  
            damage.to = target  
            damage.damage = 1  
            room:damage(damage)  
        end  
          
        player:removeTag("zhefu_target")  
        return false  
    end  
}  
  
-- 技能2：遗毒  
yidu = sgs.CreateTriggerSkill{  
    name = "yidu",  
    events = {sgs.SlashMissed},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local effect = data:toSlashEffect()  
        local target = effect.to  
        if target and target:isAlive() and not target:isKongcheng() and target:getHandcardNum() >= 2 then  
            return self:objectName()  
        end  
        return self:objectName()  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local effect = data:toSlashEffect()  
        local target = effect.to  
          
        if target:getHandcardNum() < 2 then return false end  
          
        local cards = room:askForCardsChosen(player, target, "hh", self:objectName(), 2, 2)  
        if cards:length() ~= 2 then return false end  
          
        local card1 = sgs.Sanguosha:getCard(cards:at(0))  
        local card2 = sgs.Sanguosha:getCard(cards:at(1))  
          
        room:showCard(target, cards:at(0))  
        room:showCard(target, cards:at(1))  
          
        if card1:isRed() == card2:isRed() then  
            room:throwCard(card1, target, player)  
            room:throwCard(card2, target, player)  
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
jin_guohuai:addSkill(zhefu)  
jin_guohuai:addSkill(yidu)  

sgs.LoadTranslationTable{
    ["jin_guohuai"] = "郭槐",
    ["#jin_guohuai"] = "晋室贤后",  
    ["zhefu"] = "哲妇",  
    [":zhefu"] = "你的回合外，使用或打出牌后，你可以选择一名有手牌的角色，令其弃置同名牌，或受到你的1点伤害。",  
    ["@zhefu-invoke"] = "你可以发动'哲妇'，选择一名有手牌的角色",  
    ["yidu"] = "遗毒",  
    [":yidu"] = "你使用杀被闪避后，你可以展示目标2张手牌，若颜色相同，你弃置这两张牌。",  
}

jin_simayi = sgs.General(extension, "jin_simayi", "wei", 3)  
  
-- 技能1：鹰视  
yingshi = sgs.CreateTriggerSkill{  
    name = "yingshi",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
           and player:getPhase() == sgs.Player_Play then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)  
        targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            targets:append(p)  
        end   
        first_target = room:askForPlayerChosen(player, targets, self:objectName(),   
            "yingshi-invoke", true, true)  

        second_targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:objectName() ~= first_target:objectName() then  
                second_targets:append(p)  
            end  
        end  
        second_target = room:askForPlayerChosen(player, second_targets, self:objectName(),  
            "yingshi-target", false, true)  
          
        -- 视为first_target对second_target使用知己知彼  
        local zhiji_card = sgs.Sanguosha:cloneCard("known_both")  
        zhiji_card:setSkillName(self:objectName())  
          
        local use = sgs.CardUseStruct()  
        use.card = zhiji_card  
        use.from = first_target  
        use.to:append(second_target)  
          
        room:useCard(use)  
          
        -- 若使用者非自己，则摸一张牌  
        if first_target:objectName() ~= player:objectName() then  
            room:drawCards(player, 1, self:objectName())  
        end            
        return false  
    end  
}  
  
-- 技能2：瞬覆  
shunfu_card = sgs.CreateSkillCard{  
    name = "shunfu_card",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        -- 选择未确定势力的角色，最多3个  
        if #targets >= 3 then return false end  
        if to_select:hasShownOneGeneral() then return false end  
        return to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        room:setPlayerMark(source,"@shunfu",0)
        -- 令目标角色各摸两张牌  
        for i=1, #targets do  
            room:drawCards(targets[i], 2, "shunfu")  
        end  
          
        -- 视为依次对它们使用无距离限制且不可响应的杀  
       for i=1, #targets do  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:setSkillName("shunfu")  
              
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = source  
            use.to:append(targets[i])  
                          
            room:useCard(use)  
        end  
    end  
}  
  
shunfu = sgs.CreateZeroCardViewAsSkill{  
    name = "shunfu",  
    limit_mark = "@shunfu",
    view_as = function(self, cards)  
        return shunfu_card:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@shunfu") > 0  
    end  
}  
   
-- 为武将添加技能  
jin_simayi:addSkill(yingshi)  
jin_simayi:addSkill(shunfu)  
  
sgs.LoadTranslationTable{
    ["jin_simayi"] = "晋司马懿",
    ["yingshi"] = "鹰视",
    [":yingshi"] = "出牌阶段开始时，你可以令一名角色视为对另一名角色使用【知己知彼】，若使用者非自已，则摸一张牌。",
    ["shunfu"] = "瞬覆",
    [":shunfu"] = "限定技，主动技。出牌阶段，你可令至多三名未确定势力角色各摸两张牌，然后你视为依次对它们使用一张无距离限制的【杀】。"
}

jin_zhangchunhua = sgs.General(extension, "jin_zhangchunhua", "wei", 3, false)  
ejue = sgs.CreateTriggerSkill{  
    name = "ejue",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.DamageCaused},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        local damage = data:toDamage()  
        -- 检查是否为杀造成的伤害  
        if damage.card and damage.card:isKindOf("Slash") then  
            -- 检查目标是否为未确定势力角色  
            if damage.to and damage.to:isAlive() and not damage.to:hasShownOneGeneral() then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        -- 锁定技无需询问，直接触发  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 记录日志  
        local log = sgs.LogMessage()  
        log.type = "#AddDamage"  
        log.from = player  
        log.to:append(damage.to)  
        log.arg = self:objectName()  
        log.arg2 = tostring(damage.damage + 1)  
        room:sendLog(log)  
          
        -- 增加1点伤害  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
          
        return false  
    end  
} 
shangshiJin = sgs.CreateTriggerSkill{  
    name = "shangshiJin",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        -- 检查技能拥有者是否存活且拥有此技能  
        owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then
            return ""
        end
        -- 检查是否为回合结束阶段  
        if player:getPhase() == sgs.Player_Finish and owner:getHandcardNum()<owner:getLostHp() then  
            return self:objectName(), owner:objectName()
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local lost_hp = ask_who:getLostHp()  
        local current_handcards = ask_who:getHandcardNum()  
            
        if lost_hp > current_handcards then  
            local draw_num = lost_hp - current_handcards  
            room:drawCards(ask_who, draw_num, self:objectName())  
        end  
        return false  
    end  
}
jin_zhangchunhua:addSkill(ejue)
jin_zhangchunhua:addSkill(shangshiJin)  
sgs.LoadTranslationTable{
    ["jin_zhangchunhua"] = "晋张春华",
    ["ejue"] = "扼绝",
    [":ejue"] = "锁定技，对未确定势力角色使用【杀】造成伤害时，伤害+1",
    ["shangshiJin"] = "伤逝-晋",
    [":shangshiJin"] = "任意角色回合结束时，你可将手牌摸至已失去体力值"
}


weiguan = sgs.General(extension, "weiguan", "wei", 3)  
  
zhongyun = sgs.CreateTriggerSkill{  
    name = "zhongyun",  
    events = {sgs.HpChanged, sgs.CardsMoveOneTime},  --sgs.HpChanged
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end        
        if event == sgs.HpChanged then  
            -- 受伤或回复体力后，检查手牌数是否等于体力值  
            if player:getHandcardNum() == player:getHp() then  
                return self:objectName()  
            end  
        elseif event == sgs.CardsMoveOneTime then  
            local move = data:toMoveOneTime()  
            -- 检查是否是该玩家获得或失去手牌  
            if (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand) or  
               (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand)) then  
                if player:getHandcardNum() == player:getHp() then  
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
        if event == sgs.HpChanged then              
            local choice = room:askForChoice(player, self:objectName(),"recover+damage")  
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@zhongyun")  
            if choice == "recover" then  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(target, recover)  
            elseif choice == "damage" then  
                room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))  
            end  
        else  
            -- 可摸一张牌或弃置一名其他角色一张牌  
            local choices = {"draw"}  
            local others = room:getOtherPlayers(player)  
            for _, p in sgs.qlist(others) do  
                if not p:isAllNude() then  
                    table.insert(choices, "discard")  
                    break  
                end  
            end  
              
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            if choice == "draw" then  
                player:drawCards(1, self:objectName())  
            elseif choice == "discard" then  
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(others) do  
                    if not p:isAllNude() then  
                        targets:append(p)  
                    end  
                end  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhongyun-discard")  
                if target then  
                    --room:askForDiscard(target, self:objectName(), 1, 1, false, true)
                    local card_id = room:askForCardChosen(player, target, "hej", self:objectName())
                    room:throwCard(card_id, target, player)  
                end 
            end 
        end  
        return false  
    end  
}  
  
-- 技能2：神品  
shenpin = sgs.CreateTriggerSkill{  
    name = "shenpin",  
    events = {sgs.AskForRetrial},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        return self:objectName()  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        local card = nil
        if judge.card:isRed() then
            card = room:askForCard(player, ".|black", "@shenpin-retrial", data, sgs.Card_MethodDiscard)  
        elseif judge.card:isBlack() then
            card = room:askForCard(player, ".|red", "@shenpin-retrial", data, sgs.Card_MethodDiscard)  
        end
        if card then
            room:retrial(card, player, judge, self:objectName(), false)
            judge:updateResult()  
        end  
        return false  
    end  
}  

chengxi = sgs.CreateTriggerSkill{  
    name = "chengxi",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getPhase() == sgs.Player_Start then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data) 
        local chosen_target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@chengxi-choose", true, true)  
        if not chosen_target then return false end  
          
        -- 找到所有与选择角色势力相同的角色  
        local same_kingdom_players = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:isFriendWith(chosen_target) then  
                same_kingdom_players:append(p)  
            end  
        end  
          
        if same_kingdom_players:isEmpty() then return false end  
          
        -- 让这些角色摸2张牌然后弃2张牌  
        damage_count = 0 
        for _, p in sgs.qlist(same_kingdom_players) do  
            room:drawCards(p, 2, self:objectName())          
            for i = 1, 2 do  
                local card_id = room:askForCardChosen(p, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
                local card = sgs.Sanguosha:getCard(card_id)  
                
                -- 检查是否为非基本牌  
                if not card:isKindOf("BasicCard") then  
                    damage_count = damage_count + 1  
                end  
                
                -- 弃置该牌  
                room:throwCard(card, p, p) 
            end
        end  
          
        if damage_count > 0 then  
            for _, p in sgs.qlist(same_kingdom_players) do  
                local damage = sgs.DamageStruct()  
                damage.from = chosen_target  
                damage.to = p  
                damage.damage = 1 --damage_count  
                damage.reason = self:objectName()  
                room:damage(damage)  
            end  
        end  
          
        return false  
    end  
}

-- 添加技能到武将  
weiguan:addSkill(zhongyun)  
weiguan:addSkill(shenpin)
weiguan:addSkill(chengxi)  
sgs.LoadTranslationTable{
    ["weiguan"] = "卫瓘",
    ["zhongyun"] = "忠允",  
    [":zhongyun"] = "你体力变化后，若手牌数等于体力值，可令一名角色回复1点体力或对一名角色造成1点伤害；",--你获得或失去手牌后，若手牌数等于体力值，可摸一张牌或弃置一名其他角色一张牌。",  
    ["@zhongyun-damage"] = "忠允：选择一名攻击范围内的角色，对其造成1点伤害",  
    ["@zhongyun-discard"] = "忠允：选择一名其他角色，弃置其一张牌",  
    
    -- 神品技能  
    ["shenpin"] = "神品",  
    [":shenpin"] = "判定牌生效前，你可打出一张颜色不同的牌代替之。",

    ["chengxi"] = "乘隙",
    [":chengxi"] = "准备阶段，你可选择一名角色，令所有与该角色势力相同的角色摸2张牌然后弃2张牌，若弃牌中包含非基本牌，则该角色对所有目标造成1点伤害。"
}
return {extension}