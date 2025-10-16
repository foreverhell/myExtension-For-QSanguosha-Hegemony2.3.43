
extension = sgs.Package("pokemon", sgs.Package_GeneralPack) 
--[[ 
do
    require "lua.config"
    local config = config
    table.insert(config.kingdoms,"pokemon")
    config.kingdom_colors["pokemon"] = "#fff835ff"
end
]]
sgs.LoadTranslationTable{
    ["pokemon"] = "宝可梦",
}

baofeilong = sgs.General(extension, "baofeilong", "wei", 4)  --wei,qun

weihe = sgs.CreateTriggerSkill{  
    name = "weihe",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.GeneralShown},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        -- 检查是否为明置武将牌事件，且技能在被明置的武将牌上  
        if event == sgs.GeneralShown then  
            local head = data:toBool()  
            if (head and player:inHeadSkills(self:objectName())) or   
               (not head and player:inDeputySkills(self:objectName())) then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:sendCompulsoryTriggerLog(player, self:objectName())  
          
        -- 获取与你势力不相同的其他角色  
        local targets = {}  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:objectName() ~= player:objectName() and not p:isFriendWith(player) then  
                table.insert(targets, p)  
            end  
        end  
          
        -- 让每个目标角色弃置一张手牌  
        for _, target in ipairs(targets) do  
            if not target:isKongcheng() then  
                room:askForDiscard(target, self:objectName(), 1, 1, false, false)  
            end  
        end  
          
        return false  
    end  
}  

zixinguosheng = sgs.CreateTriggerSkill{  
    name = "zixinguosheng",  
    events = {sgs.Death, sgs.ConfirmDamage},  
    frequency = sgs.Skill_Compulsory,  

    can_trigger = function(self, event, room, player, data)  
        if event == sgs.Death then  
            -- 角色死亡时检查是否由技能拥有者杀死  
            local death = data:toDeath()  
            if death.damage and death.damage.from and death.damage.from:isAlive() and
               death.damage.from:hasSkill(self:objectName()) then  
                return self:objectName()  
            end  
        elseif event == sgs.ConfirmDamage then  
            -- 造成伤害时检查是否有"信"标记  
            local damage = data:toDamage()  
            if damage.from and damage.from:isAlive() and damage.from:hasSkill(self:objectName()) and  
               damage.from:getMark("@xin") > 0 then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.Death then  
            local death = data:toDeath()  
            return true--death.damage.from:askForSkillInvoke(self:objectName(), data)  
        elseif event == sgs.ConfirmDamage then  
            local damage = data:toDamage()  
            return true--damage.from:askForSkillInvoke(self:objectName(), data)  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.Death then  
            -- 获得"信"标记  
            local death = data:toDeath()  
            local killer = death.damage.from  
              
            room:addPlayerMark(killer, "@xin", 1)  
              
            -- 显示获得标记的日志  
            local log = sgs.LogMessage()  
            log.type = "#GetMark"  
            log.from = killer  
            log.arg = "xin"  
            log.arg2 = "1"  
            room:sendLog(log)  
              
        elseif event == sgs.ConfirmDamage then  
            -- 增加伤害值  
            local damage = data:toDamage()  
            local xin_count = damage.from:getMark("@xin")  
              
            if xin_count > 0 then  
                -- 显示增伤日志  
                local log = sgs.LogMessage()  
                log.type = "#ZixinguoshengBuff"  
                log.from = damage.from  
                log.to = {damage.to}  
                log.arg = string.format("%d", damage.damage)  
                  
                damage.damage = damage.damage + xin_count  
                  
                log.arg2 = string.format("%d", damage.damage)  
                room:sendLog(log)  
                  
                data:setValue(damage)  
            end  
        end  
          
        return false  
    end  
}  

baofeilong:addSkill(weihe)
baofeilong:addSkill(zixinguosheng)

sgs.LoadTranslationTable{
["baofeilong"] = "暴飞龙",--暴鲤龙，也是这两个特性
["weihe"] = "威吓",  
[":weihe"] = "锁定技，当你明置此武将牌时，所有其他势力角色各弃置一张手牌。",  
["zixinguosheng"] = "自信过剩",  
[":zixinguosheng"] = "锁定技。当你杀死一名角色后，你获得一个'信'标记；当你造成伤害时，你令此伤害+X（X为你拥有的'信'标记数）。",  
["xin"] = "信",  
["#ZixinguoshengBuff"] = "%from 的【自信过剩】效果触发，伤害从 %arg 点增加到 %arg2 点",  
}

dakelaiyi = sgs.General(extension, "dakelaiyi", "shu", 4)  

HeidongCard = sgs.CreateSkillCard{  
    name = "HeidongCard",  
    target_fixed = true,  
    will_throw = true,  
    on_use = function(self, room, source, targets)  
        -- 进行判定  
        local judge = sgs.JudgeStruct()  
        judge.who = source  
        judge.reason = self:objectName()  
        judge.pattern = "."  
        room:judge(judge)  
          
        local suit = judge.card:getSuit()  
        local targets_to_turnover = {}  
          
        if suit == sgs.Card_Spade then  
            -- 黑桃：可以选择任意名角色  
            local selected = room:askForPlayersChosen(source, room:getOtherPlayers(source), self:objectName(), 0, 999, "@heidong-spade")  
            for _, p in sgs.qlist(selected) do  
                table.insert(targets_to_turnover, p)  
            end  
              
        elseif suit == sgs.Card_Club then  
            -- 梅花：选择一名角色  
            local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "@heidong-club")  
            if target then  
                table.insert(targets_to_turnover, target)  
            end    
        end  
          
        -- 执行叠置  
        for _, target in ipairs(targets_to_turnover) do  
            target:turnOver()  
        end  
    end  
}  
  
-- 黑洞视为技  
heidong = sgs.CreateZeroCardViewAsSkill{  
    name = "heidong",  
    view_as = function(self, cards)  
        return HeidongCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#HeidongCard")  
    end  
}  

mengyan = sgs.CreateTriggerSkill{  
    name = "mengyan",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,  

    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if player:getPhase() == sgs.Player_Finish then  
            -- 检查是否有叠置的角色  
            local has_turned_over = false  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if not p:faceUp() then  
                    has_turned_over = true  
                    break  
                end  
            end  
              
            if has_turned_over then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local targets = sgs.SPlayerList()
          
        -- 收集所有叠置的角色  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if not p:faceUp() then  
                targets:append(p)
            end  
        end  

        local targets_to_lose = {}
        local selected = room:askForPlayersChosen(player, targets, self:objectName(), 0, 999, "@mengyan-chosen")  
        for _, p in sgs.qlist(selected) do  
            table.insert(targets_to_lose, p)  
        end  

        -- 对所有叠置的角色造成体力流失  
        for _, target in ipairs(targets_to_lose) do  --targets
            if target:isAlive() then  
                room:loseHp(target, 1)  
            end  
        end  
          
        return false  
    end  
}  
dakelaiyi:addSkill(heidong) --cuimian
dakelaiyi:addSkill(mengyan)
sgs.LoadTranslationTable{
    ["dakelaiyi"] = "达克莱伊",  
    ["heidong"] = "黑洞",  
    [":heidong"] = "出牌阶段限一次，你可以发起一次判定，若判定牌为黑桃，你可以选择任意名角色令其叠置；若判定牌为梅花，你可以选择一名角色令其叠置。",  
    ["@heidong-spade"] = "黑洞：请选择任意名角色令其叠置",  
    ["@heidong-club"] = "黑洞：请选择一名角色令其叠置",  
    ["HeidongCard"] = "黑洞",  
    ["mengyan"] = "梦魇",  
    [":mengyan"] = "结束阶段开始时，你可以令任意名叠置的角色失去1点体力。",  

}


heiyemoling = sgs.General(extension, "heiyemoling", "wei", 4)  --wei,qun

tongkupingfenCard = sgs.CreateSkillCard{  
    name = "tongkupingfenCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and tp_select ~= sgs.Self
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 获取目标角色  
        local target = targets[1]  
          
        local hp1 = source:getHp()  
        local hp2 = target:getHp()  
        
        local hp1_new = math.ceil((hp1+hp2)/2)
        local hp2_new = math.floor((hp1+hp2)/2)
        -- 交换体力值  
        room:setPlayerProperty(source, "hp", sgs.QVariant(hp1_new))  
        room:setPlayerProperty(target, "hp", sgs.QVariant(hp2_new))  
        room:broadcastProperty(source, "hp")  
        room:broadcastProperty(target, "hp")  
    end  
}  
  
-- 创建强行视为技  
tongkupingfen = sgs.CreateZeroCardViewAsSkill{  
    name = "tongkupingfen",  
      
    view_as = function(self)  
        local card = tongkupingfenCard:clone()  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 出牌阶段限一次  
        return not player:hasUsed("#tongkupingfenCard")  
    end  
}  
heiyemoling:addSkill(tongkupingfen)
sgs.LoadTranslationTable{
    ["heiyemoling"] = "黑夜魔灵",
    ["tongkupingfen"] = "痛苦平分",
    ["tongkupingfen"] = "出牌阶段限一次。你可以选择一名其他角色，平分你们的体力值，你向上取整，目标向下取整"
}

kabiShou = sgs.General(extension, "kabiShou", "wei", 4)  

shuijiao = sgs.CreateTriggerSkill{  
    name = "shuijiao",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            -- 只在出牌阶段结束时触发  
            if player:getPhase() == sgs.Player_Play then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 询问玩家是否发动技能  
        if player:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
          
        -- 跳过弃牌阶段  
        player:skip(sgs.Player_Discard)  
          
        -- 体力恢复至体力上限  
        if player:isWounded() then  
            local recover = sgs.RecoverStruct()  
            recover.who = player  
            recover.recover = player:getMaxHp() - player:getHp()  
            room:recover(player, recover)  
        end  
          
        -- 叠置（翻面）  
        player:turnOver()  
          
        -- 发送日志信息  
        local log = sgs.LogMessage()  
        log.type = "#ShuijiaoEffect"  
        log.from = player  
        log.arg = self:objectName()  
        room:sendLog(log)  
          
        return false  
    end  
}  
  
-- 创建卡比兽武将  
kabiShou:addSkill(shuijiao)  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["pokemon"] = "宝可梦",  
    ["kabiShou"] = "卡比兽",  
    ["shuijiao"] = "睡觉",  
    [":shuijiao"] = "出牌阶段结束时，你可以跳过弃牌阶段，体力恢复至体力上限，然后叠置。",  
    ["#ShuijiaoEffect"] = "%from 的【%arg】被触发，跳过弃牌阶段，体力恢复并叠置",  
    ["@shuijiao"] = "你可以发动'睡觉'，跳过弃牌阶段并恢复体力"  
}

miniq = sgs.General(extension, "miniq", "wei", 3)  -- 吴国，4血，男性 

huapi = sgs.CreateTriggerSkill{  
    name = "huapi",  
    events = {sgs.DamageInflicted, sgs.HpRecover},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if event == sgs.DamageInflicted then  
            -- 检查是否体力满且有免疫次数  
            if player:getHp() == player:getMaxHp() and player:getMark("@huapi_used") == 0 then  
                return self:objectName()  
            end  
        elseif event == sgs.HpRecover then  
            -- 检查体力是否恢复至上限  
            local recover = data:toRecover()  
            if recover.to:objectName() == player:objectName() and   
               player:getHp() == player:getMaxHp() then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.DamageInflicted then  
            -- 询问是否使用免疫  
            return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)  
        else  
            -- 体力恢复时自动刷新  
            return true  
        end  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.DamageInflicted then  
            -- 消耗一次免疫次数，防止伤害  
            room:setPlayerMark(player, "@huapi_used", 1)  
            return true -- 返回true表示阻止伤害  
        elseif event == sgs.HpRecover then  
            -- 刷新免疫次数  
            room:setPlayerMark(player, "@huapi_used", 0)  
        end  
        return false  
    end  
}  

miniq:addSkill(huapi)

sgs.LoadTranslationTable{
    ["miniq"] = "迷你丘",
    ["huapi"] = "画皮",
    [":huapi"] = "当你体力值等于体力上限时，你可以免疫一次伤害；当你体力恢复至体力上限时，你刷新免疫次数。"
}

quanhaishen = sgs.General(extension, "quanhaishen", "qun", 3)  -- 吴国，4血，男性 

neizaiwu = sgs.CreateTriggerSkill{  
    name = "neizaiwu",  
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,  

    can_trigger = function(self, event, room, player, data)  
        local death = data:toDeath()  
        if death.who and death.who:hasSkill(self:objectName()) then  
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local death = data:toDeath() 
        if death.damage and death.damage.from and death.damage.from:isAlive() then  
            room:loseHp(death.damage.from, death.damage.damage+1)
        else
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if not player:isFriendWith(p) then
                    room:loseHp(p,1)
                end
            end
        end  
        return false  
    end  
}
quanhaishen:addSkill(neizaiwu)
-- 翻译表  
sgs.LoadTranslationTable{  
    ["quanhaishen"] = "拳海参",
    ["neizaiwu"] = "飞出的内在物",
    [":neizaiwu"] = "当你死亡时，若有伤害来源，杀死你的角色失去X点体力，X为你死亡时受到的伤害值+1；若没有伤害或没有伤害来源，则所有和你势力不同的角色失去一点体力"
}  

suoluoyake = sgs.General(extension, "suoluoyake", "wei", 3)  --不能有太多限定技

huanxiang = sgs.CreateTriggerSkill{  
    name = "huanxiang",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.EventPhaseStart},  
    --relate_to_place = "head",
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then  
            -- 检查是否可以变更副将  
            if player:canTransform() then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        -- 变更副将  
        room:transformDeputyGeneral(player)  
          
        -- 摸2张牌  
        player:drawCards(2, self:objectName())  
        
        if not player:hasSkill(self:objectName()) then
            room:acquireSkill(player,"huanxiang",true,true)
        end
        -- 记录日志  
        local log = sgs.LogMessage()  
        log.type = "#HuanxiangTransform"  
        log.from = player  
        log.arg = self:objectName()  
        room:sendLog(log)  
          
        return false  
    end  
}  
suoluoyake:addSkill(huanxiang)

sgs.LoadTranslationTable{
["suoluoyake"] = "索罗亚克",
["huanxiang"] = "幻象",  
[":huanxiang"] = "锁定技。准备阶段，你变更你的副将，并摸2张牌。然后若你没有【幻象】，你获得【幻象】",  
["#HuanxiangTransform"] = "%from 发动了'%arg'，变更了副将并摸了2张牌",  
}

tuokerenzhe = sgs.General(extension, "tuokerenzhe", "wei", 2)  

shenmishouhu = sgs.CreateTriggerSkill{  
    name = "shenmishouhu",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            -- 只有当伤害为普通伤害时才触发防护  
            if damage.nature == sgs.DamageStruct_Normal then  
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
        room:notifySkillInvoked(player, self:objectName())  
          
        -- 发送日志信息  
        local log = sgs.LogMessage()  
        log.type = "#SkillNullify"  
        log.from = player  
        log.arg = self:objectName()  
        log.arg2 = "normal_damage"  
        room:sendLog(log)  
          
        -- 返回true表示防止伤害  
        return true  
    end  
}  

tuokerenzhe:addSkill(shenmishouhu)  
sgs.LoadTranslationTable{  
    ["pokemon"] = "宝可梦",
    ["tuokerenzhe"] = "脱壳忍者",  
    ["shenmishouhu"] = "神秘守护",  
    [":shenmishouhu"] = "锁定技，你不会受到普通伤害。",  
    ["#SkillNullify"] = "%from 的'%arg'被触发，防止了 %arg2"  
}


tutuquan = sgs.General(extension, "tutuquan", "qun", 3)  


xiesheng = sgs.CreateTriggerSkill{  
    name = "xiesheng",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)-- 锁定技，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then  
            -- 准备阶段：失去结束阶段获得的技能，获得新技能  
            local old_skill = player:property("xiesheng_finish_skill"):toString()  
            if old_skill ~= "" then  
                room:detachSkillFromPlayer(player, old_skill, true, false, true)  
                room:setPlayerProperty(player, "xiesheng_finish_skill", sgs.QVariant(""))  
            end  
              
            -- 选择场上一名角色获得其技能  
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@xiesheng-start")  
            if target then  
                local skills = {}  
                -- 获取目标角色的可见技能  
                for _, skill in sgs.qlist(target:getVisibleSkillList()) do  
                    if skill:isVisible() and not skill:isLordSkill() and skill:objectName() ~= self:objectName() then  
                        table.insert(skills, skill:objectName())  
                    end  
                end  
                    
                if #skills > 0 then  
                    local skill_name = room:askForChoice(player, self:objectName(), table.concat(skills, "+"))  
                    room:acquireSkill(player, skill_name, true, true)  
                    room:setPlayerProperty(player, "xiesheng_start_skill", sgs.QVariant(skill_name))  
                        
                    -- 记录日志  
                    local log = sgs.LogMessage()  
                    log.type = "#XieshengGet"  
                    log.from = player  
                    log.to = {target}  
                    log.arg = skill_name  
                    room:sendLog(log)  
                end  
            end  
              
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then  
            -- 结束阶段：失去准备阶段获得的技能，获得新技能  
            local old_skill = player:property("xiesheng_start_skill"):toString()  
            if old_skill ~= "" then  
                room:detachSkillFromPlayer(player, old_skill, true, false, true)  
                room:setPlayerProperty(player, "xiesheng_start_skill", sgs.QVariant(""))  
            end  
              
            -- 选择场上一名角色获得其技能  
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@xiesheng-finish")  
            if target then  
                local skills = {}  
                -- 获取目标角色的可见技能  
                for _, skill in sgs.qlist(target:getVisibleSkillList()) do  
                    if skill:isVisible() and not skill:isLordSkill() and skill:objectName() ~= self:objectName() then  
                        table.insert(skills, skill:objectName())  
                    end  
                end  
                    
                if #skills > 0 then  
                    local skill_name = room:askForChoice(player, self:objectName(), table.concat(skills, "+"))  
                    room:acquireSkill(player, skill_name, true, true)  
                    room:setPlayerProperty(player, "xiesheng_finish_skill", sgs.QVariant(skill_name))  
                        
                    -- 记录日志  
                    local log = sgs.LogMessage()  
                    log.type = "#XieshengGet"  
                    log.from = player  
                    log.to = {target}  
                    log.arg = skill_name  
                    room:sendLog(log)  
                end  
            end  
        end  
          
        return false  
    end  
}  


tutuquan:addSkill(xiesheng)

sgs.LoadTranslationTable{
["tutuquan"] = "图图犬",
["xiesheng"] = "写生",  
[":xiesheng"] = "锁定技，准备阶段，你失去结束阶段获得的技能，获得场上一名角色的一个技能；结束阶段，你失去准备阶段获得的技能，获得场上一名角色的一个技能。",  
["@xiesheng-start"] = "写生：选择一名角色，获得其一个技能（准备阶段）",  
["@xiesheng-finish"] = "写生：选择一名角色，获得其一个技能（结束阶段）",  
["#XieshengGet"] = "%from 通过'写生'从 %to 处获得了技能'%arg'",  
["mofang"] = "模仿",  
[":mofang"] = "当其他角色使用非延时性锦囊时，你可以弃置一张相同花色的牌，视为使用之。",  
["MofangCard"] = "模仿",  
["@mofang-invoke"] = "你可以发动【模仿】来模仿 %arg",  
["@mofang-use"] = "模仿：请弃置一张相同花色的牌来视为使用 %arg",  
}

return {extension}