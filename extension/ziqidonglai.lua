
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

simaao = sgs.General(extension, "simaao", "wei", 3)  

longfeng = sgs.CreateTriggerSkill{  
    name = "longfeng",  
    events = {sgs.Death, sgs.EventPhaseStart},  
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
            else --之后的准备阶段，转移1个
                -- 检查可转移的标记
                choices = {}
                --long_source = nil
                --feng_source = nil
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:getMark("long") > 0 then 
                        --long_source = p 
                        table.insert(choices, "transfer_long")  
                        break  
                    end  
                end  
                
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:getMark("feng") > 0 then 
                        --feng_source = p 
                        table.insert(choices, "transfer_feng")  
                        break  
                    end  
                end  
                
                if #choices > 0 then  
                    local choice = room:askForChoice(source, "longfeng_transfer_choice", table.concat(choices, "+"))  
                    
                    if choice == "transfer_long" then  
                        -- 转移龙标记  
                        for _, p in sgs.qlist(room:getAlivePlayers()) do  
                            if p:getMark("long") > 0 then  
                                room:setPlayerMark(p, "long", 0)  
                                room:detachSkillFromPlayer(p, "huoji")  
                                target = room:askForPlayerChosen(ask_who, room:getOtherPlayers(p))
                                room:addPlayerMark(target, "long", 1)  
                                room:attachSkillToPlayer(target, "huoji")
                                if target:getMark("feng") then 
                                    room:attachSkillToPlayer(target, "longfengYehuo")
                                end
                                break  
                            end  
                        end  
                    elseif choice == "transfer_feng" then  
                        -- 转移凤标记  
                        for _, p in sgs.qlist(room:getAlivePlayers()) do  
                            if p:getMark("feng") > 0 then  
                                room:setPlayerMark(p, "feng", 0)  
                                room:detachSkillFromPlayer(p, "lianhuan")  
                                target = room:askForPlayerChosen(ask_who, room:getOtherPlayers(p))
                                room:addPlayerMark(target, "feng", 1)  
                                room:attachSkillToPlayer(target, "lianhuan")  
                                if target:getMark("long") then 
                                    room:attachSkillToPlayer(target, "longfengYehuo")
                                end
                                break  
                            end  
                        end  
                    end  
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
        return true -- 锁定技，自动触发  
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
[":longfeng"] = "你的首个准备阶段，你可以令2名角色分别获得'龙'标记和'凤'标记。拥有龙标记的角色获得技能'火技'，拥有凤标记的角色获得技能'连环'。拥有龙凤标记的角色死亡时，你可以转移标记。",  
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
--[":huoji"] = "",  
["lianhuan"] = "连环",  
[":lianhuan"] = "你可以将♣手牌当【铁索连环】使用或重铸。",

["yinshi"] = "隐士",
[":yinshi"] = "锁定技。当你受到属性伤害或者锦囊的伤害时，若你装备区没有防具，你防止此伤害",
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

jin_guohuai = sgs.General(extension, "jin_guohuai", "wei", 3, false)  
  
zhefu = sgs.CreateTriggerSkill{  
    name = "zhefu",  
    events = {sgs.CardUsed, sgs.CardResponded},  
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
}  
  
-- 添加技能到武将  
jin_guohuai:addSkill(zhefu)  
--jin_guohuai:addSkill(yidu)  

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
        room:setPlayerMark("@shunfu",0)
        -- 令目标角色各摸两张牌  
        for _, target in ipairs(targets) do  
            room:drawCards(target, 2, "shunfu")  
        end  
          
        -- 视为依次对它们使用无距离限制且不可响应的杀  
        for _, target in ipairs(targets) do  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:setSkillName("shunfu")  
              
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = source  
            use.to:append(target)  
                          
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

return {extension}