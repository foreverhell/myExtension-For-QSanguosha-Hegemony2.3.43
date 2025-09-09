extension = sgs.Package("shenhua", sgs.Package_GeneralPack)  


shen_caocao = sgs.General(extension, "shen_caocao", "wei", 3)  -- 吴国，4血，男性 

guixin = sgs.CreateTriggerSkill{  
    name = "guixin",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
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
        -- 获得所有角色各一张牌  
        local targets = room:getAlivePlayers()  
        for _, target in sgs.qlist(targets) do  
            if target:objectName() ~= player:objectName() and not target:isAllNude() then  
                local card_id = room:askForCardChosen(player, target, "hej", self:objectName())  
                room:obtainCard(player, card_id, false)  
            end  
        end  
        player:turnOver()
        return false  
    end  
}
function sgs.CreateJumaSkill(name) --创建马术技能，在CreateDistanceSkill函数基础上建立的函数，啦啦版中的CreateFakeMoveSkill就是这样实现的
	local juma_skill = {}
	juma_skill.name = name
	juma_skill.correct_func = function(self, from, to)
		if to:hasShownSkill(self) then --hasSkill
			return 1
		end
		return 0
	end
	return sgs.CreateDistanceSkill(juma_skill)
end
feiying_caocao = sgs.CreateJumaSkill("feiying_caocao") 
shen_caocao:addSkill(guixin)  
shen_caocao:addSkill(feiying_caocao)  
  
-- 翻译表  
sgs.LoadTranslationTable{ 
    ["shenhua"] = "神话再临", 
    ["shen_caocao"] = "神曹操",  
    ["guixin"] = "归心",  
    [":guixin"] = "你受到伤害时，你可以获得所有角色各一张牌，然后你叠置",  
    ["feiying_caocao"] = "飞影",  
    [":feiying_caocao"] = "锁定技，其他角色到你的距离+1。"  
}  

-- 神甘宁武将  
shen_ganning = sgs.General(extension, "shen_ganning", "wu", 3)  
  
PoxiCard = sgs.CreateSkillCard{  
    name = "PoxiCard",  
    skill_name = "poxi",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        local suits = {}  --已经使用的花色
        local count = 0 --已经弃置的牌数
        --弃置目标的卡牌
        local all_cards = sgs.IntList()          
        -- 添加目标的手牌  
        for _, card in sgs.qlist(target:getHandcards()) do  
            all_cards:append(card:getId())  
        end  

        local to_discard = sgs.IntList()  
        -- 选择至多4张花色不同的牌  
        for i = 1, 4 do  
            room:fillAG(all_cards, source)  
            local card_id = room:askForAG(source, all_cards, true, "poxi")  
            if card_id == -1 then 
                room:clearAG(source)
                break 
            end  
              
            local card = sgs.Sanguosha:getCard(card_id)  
            local suit = card:getSuitString()  
              
            if not suits[suit] then  
                suits[suit] = true  
                to_discard:append(card_id)  
                all_cards:removeOne(card_id)  
                room:clearAG(source)
            else  
                room:sendCompulsoryTriggerLog(source, "poxi", true)  
                room:clearAG(source)
                break  
            end  
        end  
                  
        -- 弃置选择的牌  
        if not to_discard:isEmpty() then  
            local dummy = sgs.DummyCard(to_discard)  
            room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE,   
                          source:objectName(), target:objectName(), "poxi", ""), nil)              
        end  
          
        count = count + to_discard:length()  
        
        --弃置自己的卡牌
        local all_cards = sgs.IntList()          
        -- 添加自己的手牌  
        for _, card in sgs.qlist(source:getHandcards()) do  
            all_cards:append(card:getId())  
        end  

        local to_discard = sgs.IntList()  
        -- 选择至多4张花色不同的牌  
        for i = 1, 4-count do  
            room:fillAG(all_cards, source)  
            local card_id = room:askForAG(source, all_cards, true, "poxi")  
            if card_id == -1 then 
                room:clearAG(source)
                break 
            end  
              
            local card = sgs.Sanguosha:getCard(card_id)  
            local suit = card:getSuitString()  
              
            if not suits[suit] then  
                suits[suit] = true  
                to_discard:append(card_id)  
                all_cards:removeOne(card_id)  
                room:clearAG(source)
            else  
                room:sendCompulsoryTriggerLog(source, "poxi", true)  
                room:clearAG(source)
                break  
            end  
        end  
                  
        -- 弃置选择的牌  
        if not to_discard:isEmpty() then  
            local dummy = sgs.DummyCard(to_discard)  
            room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE,   
                          source:objectName(), source:objectName(), "poxi", ""), nil)              
        end  
          
        count = count + to_discard:length()  
        -- 根据弃置数量执行效果  
        if count == 0 then  
            -- 减一点体力  
            room:loseHp(source, 1)  
        elseif count == 1 then  
            -- 结束出牌阶段，手牌上限-1  
            --source:skip(sgs.Player_Play)  
            room:setPlayerFlag(source, "@poxi_maxcards")  
        elseif count == 3 then  
            -- 回复一点体力  
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 1  
            room:recover(source, recover)  
        elseif count == 4 then  
            -- 摸4张牌  
            source:drawCards(4, "poxi")  
        end  
    end  
}  
  
-- 魄袭视为技  
poxi = sgs.CreateZeroCardViewAsSkill{  
    name = "poxi",  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#PoxiCard")  
    end,  
      
    view_as = function(self)  
        local card = PoxiCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end  
}
  
-- 手牌上限减少技能  
poxi_maxcards = sgs.CreateMaxCardsSkill{  
    name = "#poxi_maxcards",  
    extra_func = function(self, player) 
        if player:hasFlag("@poxi_maxcards") then
            return -1
        end
    end  
}  

Luaying = sgs.CreateTriggerSkill{  
    name = "Luaying",  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive()) then return "" end
        owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        if player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        owner = room:findPlayerBySkillName(self:objectName())
        if player:objectName() == owner:objectName() then --自己的结束阶段，询问
            return owner:askForSkillInvoke(self:objectName(),data)
        else --其他人的结束阶段，有标记自动触发
            return player:getMark("@ying")>0
        end
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        owner = room:findPlayerBySkillName(self:objectName())
        if player:objectName() == owner:objectName() then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@jieying-choose", true, true)  
            if target then  
                room:addPlayerMark(target, "@ying", 1)  
                room:acquireSkill(target,"LuaYing-draw",false)
                room:acquireSkill(target,"LuaYing-slash",false)
                room:acquireSkill(target,"LuaYing-maxcards",false)
            end  
        else
            room:removePlayerMark(player, "@ying", 1)
            room:detachSkillFromPlayer(player,"LuaYing-draw",false)
            room:detachSkillFromPlayer(player,"LuaYing-slash",false)
            room:detachSkillFromPlayer(player,"LuaYing-maxcards",false)
            if not player:isKongcheng() then  
                local cards = player:handCards()  
                local move = sgs.CardsMoveStruct()  
                move.card_ids = cards  
                move.from = player  
                move.to = owner  
                move.to_place = sgs.Player_PlaceHand  
                move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, owner:objectName(), "Luaying", "")  
                room:moveCardsAtomic(move, true)  
            end  
        end
        return false  
    end  
}  
  
-- 营标记摸牌效果  
LuaYingDraw = sgs.CreateDrawCardsSkill{  
    name = "LuaYing-draw",  
    draw_num_func = function(self, player, n)  
        if player:getMark("@ying") > 0 then  
            return n + 1  
        end  
        return n  
    end  
}  
  
-- 营标记出杀次数效果  
LuaYingSlash = sgs.CreateTargetModSkill{  
    name = "LuaYing-slash",  
    pattern = "Slash",  
    residue_func = function(self, player, card)  
        if player:getMark("@ying") > 0 then  
            return 1  
        end  
        return 0  
    end  
}  
  
-- 营标记手牌上限效果  
LuaYingMaxCards = sgs.CreateMaxCardsSkill{  
    name = "LuaYing-maxcards",  
    extra_func = function(self, player)  
        if player:getMark("@ying") > 0 then  
            return 1  
        end  
        return 0  
    end  
}

-- 添加技能到武将  
shen_ganning:addSkill(poxi)  
shen_ganning:addSkill(poxi_maxcards)  
shen_ganning:addSkill(Luaying)
shen_ganning:addSkill(LuaYingDraw)
shen_ganning:addSkill(LuaYingSlash)
shen_ganning:addSkill(LuaYingMaxCards)
sgs.LoadTranslationTable{  
    ["canghai"] = "沧海",  
    ["shen_ganning"] = "神甘宁",  
    ["poxi"] = "魄袭",   
    [":poxi"] = "出牌阶段限一次。你可以查看一名角色的手牌，然后从你和该角色的手牌中选择花色互不相同的牌弃置。若你弃置了：0张，你失去一点体力；1张，你本回合手牌上限-1；3张，你恢复一点体力；4张，你摸4张牌",  

    ["Luaying"] = "劫营",
    [":Luaying"] = "你的结束阶段，你可以令一名其他角色获得“营”标记；其他角色的结束阶段，若其有“营”标记，其失去“营”标记，你获得其所有手牌。拥有“营”标记的角色摸牌阶段摸牌数+1，出杀次数+1，手牌上限+1"
}  

shen_guanyu = sgs.General(extension, "shen_guanyu", "shu", 4)  -- 吴国，4血，男性 

LuaWuhun = sgs.CreateTriggerSkill{  
    name = "LuaWuhun",  
    events = {sgs.Damaged, sgs.Death},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:hasSkill(self:objectName())) then return "" end  
          
        if event == sgs.Damaged then  
            if player:isAlive() then  
                local damage = data:toDamage()  
                if damage.from and damage.from:isAlive() then  
                    return self:objectName()
                end  
            end  
        elseif event == sgs.Death then  
            local death = data:toDeath()  
            if death.who == player then  
                -- 检查是否有角色拥有梦魇标记  
                local has_mengyan = false  
                for _, p in sgs.qlist(room:getAllPlayers()) do  
                    if p:getMark("@mengyan") > 0 then  
                        has_mengyan = true  
                        break  
                    end  
                end  
                if has_mengyan then  
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.Damaged then  
            return true -- 受到伤害时强制触发  
        elseif event == sgs.Death then  
            return true -- 死亡时强制触发  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.Damaged then  
            local damage = data:toDamage()  
            if damage.from and damage.from:isAlive() then  
                room:addPlayerMark(damage.from, "@mengyan", damage.damage)  
            end  
        elseif event == sgs.Death then  
            -- 找到梦魇标记最多的角色  
            local max_mengyan = 0  
            local targets = {}  
              
            for _, p in sgs.qlist(room:getAllPlayers()) do  
                local mengyan_count = p:getMark("@mengyan")  
                if mengyan_count > 0 then  
                    if mengyan_count > max_mengyan then  
                        max_mengyan = mengyan_count  
                        targets = {p}  
                    elseif mengyan_count == max_mengyan then  
                        table.insert(targets, p)  
                    end  
                end  
            end  
              
            if #targets > 0 then  
                local target  
                if #targets == 1 then  
                    target = targets[1]  
                else  
                    -- 如果有多个角色标记数相同，让死亡角色选择  
                    local target_list = sgs.SPlayerList()  
                    for _, p in ipairs(targets) do  
                        target_list:append(p)  
                    end  
                    target = room:askForPlayerChosen(player, target_list, self:objectName(), "@wuhun-choose", false, false)  
                end  
                  
                if target then  
                    -- 进行判定  
                    local judge = sgs.JudgeStruct()  
                    judge.pattern = "Peach,GodSalvation"  
                    judge.good = true  
                    judge.reason = self:objectName()  
                    judge.who = target  
                      
                    room:judge(judge)  
                      
                    if not judge:isGood() then  
                        -- 判定失败，失去体力  
                        local mengyan_count = target:getMark("@mengyan")  
                        room:loseHp(target, mengyan_count)  
                    end  
                      
                    -- 清除所有梦魇标记  
                    for _, p in sgs.qlist(room:getAllPlayers()) do  
                        if p:getMark("@mengyan") > 0 then  
                            room:setPlayerMark(p, "@mengyan", 0)  
                        end  
                    end  
                end  
            end  
        end  
        return false  
    end  
}
shen_guanyu:addSkill(LuaWuhun)
shen_guanyu:addSkill("wusheng")
-- 翻译表  
sgs.LoadTranslationTable{  
    ["shen_guanyu"] = "神关羽",
    ["LuaWuhun"] = "武魂",
    [":LuaWuhun"] = "当你受到伤害后，伤害来源获得X枚“梦魇”标记，X为伤害值。当你死亡时，选择“梦魇”标记最多的一名角色进行判定：若结果不为【桃】或【桃园结义】，则该角色失去X点体力，X为标记数"
}  

shen_liubei = sgs.General(extension, "shen_liubei", "shu", 4)  -- 吴国，4血，男性 

LuaLongnu = sgs.CreateTriggerSkill{  
    name = "LuaLongnu",  
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
        return true -- 锁定技强制触发  
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
          
        -- 根据当前标记执行效果  
        if player:getMark("@yang") > 0 then  
            -- 阳标记：失去1点体力并摸一张牌  
            --room:loseHp(player, 1)  
            player:drawCards(1)  
        else  
            -- 阴标记：减1点体力上限并摸一张牌  
            --room:loseMaxHp(player, 1)  
            player:drawCards(1)  
        end  
          
        return false  
    end  
}  
  
-- 龙怒阳效果视为技（红色手牌视为火杀）  
LuaLongnuYangVS = sgs.CreateOneCardViewAsSkill{  
    name = "LuaLongnu-yang",  
    filter_pattern = ".|red|.|hand",  
    view_as = function(self, card)  
        local fire_slash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())  
        fire_slash:addSubcard(card)  
        fire_slash:setSkillName("LuaLongnu")  
        return fire_slash  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@yang") > 0  
    end  
}  
  
-- 龙怒阴效果视为技（锦囊牌视为雷杀）  
LuaLongnuYinVS = sgs.CreateOneCardViewAsSkill{  
    name = "LuaLongnu-yin",  
    filter_pattern = "TrickCard|.|.|hand",  
    view_as = function(self, card)  
        local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())  
        thunder_slash:addSubcard(card)  
        thunder_slash:setSkillName("LuaLongnu")  
        return thunder_slash  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@yin") > 0  
    end  
}  
  
-- 龙怒阳效果距离限制技  
LuaLongnuYangDistance = sgs.CreateTargetModSkill{  
    name = "#LuaLongnu-yang-distance",  
    pattern = "Slash",  
    distance_limit_func = function(self, player, card)  
        if player:getMark("@yang") > 0 and card:getSkillName() == "LuaLongnu" then  
            return 1000  
        end  
        return 0  
    end  
}  
  
-- 龙怒阴效果次数限制技  
LuaLongnuYinResidue = sgs.CreateTargetModSkill{  
    name = "#LuaLongnu-yin-residue",  
    pattern = "Slash",  
    residue_func = function(self, player, card)  
        if player:getMark("@yin") > 0 and card:getSkillName() == "LuaLongnu" then  
            return 1000  
        end  
        return 0  
    end  
}  
  
-- 结营技能  
LuaJieying = sgs.CreateTriggerSkill{  
    name = "LuaJieying",  
    events = {sgs.GeneralShown, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
          
        if event == sgs.GeneralShown and data.toBool() == player:inHeadSkills(self:objectName()) then
            return self:objectName()  
        elseif event == sgs.EventPhaseEnd then  
            if player:getPhase() == sgs.Player_Finish then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.GeneralShown then  
            return true -- 游戏开始强制触发  
        elseif event == sgs.EventPhaseEnd then  
            return true
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.GeneralShown then  
            -- 游戏开始时横置自己  
            if not player:isChained() then  
                player:setChained(true)  
                room:broadcastProperty(player, "chained")  
                room:setEmotion(player, "chain")  
            end  
        elseif event == sgs.EventPhaseEnd then  
            -- 横置选择的其他角色  
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@jieying-chain", true, true)  
            target:setChained(not target:isChained())  
            room:broadcastProperty(target, "chained")  
            room:setEmotion(target, "chain")       
        end  
        return false  
    end  
}  
  
-- 结营手牌上限技  
LuaJieyingMaxCards = sgs.CreateMaxCardsSkill{  
    name = "#LuaJieying-maxcards",  
    extra_func = function(self, player)
        if player:hasSkill("LuaJieying") and player:isChained() then  
            return 2  
        end  
        return 0  
    end  
}  
  
-- 结营始终横置效果  
LuaJieyingChain = sgs.CreateTriggerSkill{  
    name = "LuaJieying-chain",  
    events = {sgs.ChainStateChanged},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:hasSkill("LuaJieying") and not player:isChained() then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 强制保持横置状态  
        player:setChained(true)  
        room:broadcastProperty(player, "chained")  
        return false  
    end  
} 
shen_liubei:addSkill(LuaJieying)
shen_liubei:addSkill(LuaJieyingMaxCards)
shen_liubei:addSkill(LuaJieyingChain)

shen_liubei:addSkill(LuaLongnu)
shen_liubei:addSkill(LuaLongnuYinVS)
shen_liubei:addSkill(LuaLongnuYinResidue)
shen_liubei:addSkill(LuaLongnuYangVS)
shen_liubei:addSkill(LuaLongnuYangDistance)
-- 翻译表  
sgs.LoadTranslationTable{  
["shen_liubei"] = "神刘备",
["LuaLongnu"] = "龙怒",
--[":LuaLongnu"] = "锁定技。出牌阶段开始时，若你没有阴阳标记，你选择阴阳标记为阴或者阳，若你有阴阳标记，阴阳标记交替；若阴阳标记为阳，失去1点体力并摸一张牌，本回合所有红色手牌视为​​火【杀】​​且无距离限制；若阴阳标记为阴，减1点体力上限并摸一张牌，本回合所有锦囊牌视为​​雷【杀】​​且无次数限制",
[":LuaLongnu"] = "锁定技。出牌阶段开始时，若你没有阴阳标记，你选择阴阳标记为阴或者阳，若你有阴阳标记，阴阳标记交替；若阴阳标记为阳，摸一张牌，本回合所有红色手牌视为​​火【杀】​​且无距离限制；若阴阳标记为阴，摸一张牌，本回合所有锦囊牌视为​​雷【杀】​​且无次数限制",
["LuaJieying"] = "结营",
[":LuaJieying"] = "锁定技。明置武将后，你始终处于横置状态。你处于横置状态时手牌上限+2。结束阶段你可以横置一名其他角色"
}  

shen_luxun = sgs.General(extension, "shen_luxun", "wu", 3)  -- 吴国，4血，男性 

LuaJunlue = sgs.CreateTriggerSkill{  
    name = "LuaJunlue",  
    events = {sgs.Damage, sgs.Damaged},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        return self:objectName()
    end,  
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技强制触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        room:addPlayerMark(player, "@junlue", damage.damage)  
        return false  
    end  
}  
  
-- 摧克技能  
LuaCuike = sgs.CreateTriggerSkill{  
    name = "LuaCuike",  
    events = {sgs.EventPhaseStart},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:getPhase() == sgs.Player_Play and player:getMark("@junlue") > 0 then  
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
        local junlue_count = player:getMark("@junlue")  
          
        if junlue_count >= 7 then  
            room:setPlayerMark(player, "@junlue", 0) -- 移除所有军略标记  
            -- 对所有其他角色造成1点伤害  
            local others = room:getOtherPlayers(player)  
            for _, target in sgs.qlist(others) do  
                if target:isAlive() then  
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))  
                end  
            end  
        elseif junlue_count % 2 == 1 then  
            -- 奇数：对一名角色造成1点伤害  
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@cuike-damage", false, false)  
            if target then  
                room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))  
            end  
        else  
            -- 偶数：横置一名角色并弃置其1张牌  
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@cuike-chain", false, false)  
            if target then  
                target:setChained(not target:isChained())  
                room:broadcastProperty(target, "chained")  
                room:setEmotion(target, "chain")  
                if not target:isAllNude() then  
                    local card_id = room:askForCardChosen(player, target, "hej", self:objectName())  
                    room:throwCard(card_id, target, player)  
                end  
            end  
        end  
        return false  
    end  
}  
  
-- 限定技技能卡  
LuaZhanhuoCard = sgs.CreateSkillCard{  
    name = "LuaZhanhuoCard",  
    skill_name = "LuaZhanhuoCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        if #targets > sgs.Self:getMark("@junlue") then return false end  
        return to_select:isChained() and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    feasible = function(self, targets)  
        return #targets >= 0 and #targets <= sgs.Self:getMark("@junlue")   
    end,  
    on_use = function(self, room, source, targets)  
        room:setPlayerMark(source, "@junlue", 0) -- 移除所有军略标记  
        room:setPlayerMark(source, "@zhanhuo", 0) -- 标记限定技已使用  
          
        -- 弃置所有目标的装备  
        for _, target in ipairs(targets) do  
            if target:hasEquip() then  
                target:throwAllEquips()  
            end  
        end  
          
        -- 选择其中一名角色造成火焰伤害  
        if #targets > 0 then  
            local target_list = sgs.SPlayerList()  
            for _, p in ipairs(targets) do  
                target_list:append(p)  
            end  
            local chosen = room:askForPlayerChosen(source, target_list, "LuaZhanhuo", "@LuaZhanhuo-fire", false, false)  
            if chosen then  
                local damage = sgs.DamageStruct("LuaZhanhuo", source, chosen, 1, sgs.DamageStruct_Fire)  
                room:damage(damage)  
            end  
        end  
    end  
}  
  
-- 限定技视为技  
LuaZhanhuo = sgs.CreateZeroCardViewAsSkill{  
    name = "LuaZhanhuo",  
    limit_mark = "@zhanhuo",
    view_as = function(self)  
        return LuaZhanhuoCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@zhanhuo") > 0 and player:getMark("@junlue") > 0  
    end  
}  
shen_luxun:addSkill(LuaJunlue)
shen_luxun:addSkill(LuaCuike)
shen_luxun:addSkill(LuaZhanhuo)

-- 翻译表  
sgs.LoadTranslationTable{  
["shen_luxun"] = "神陆逊",
["LuaJunlue"]="军略",
[":LuaJunlue"]="锁定技。当你​​受到或造成伤害​​后，获得X枚“军略”标记，X为伤害值。",
["LuaCuike"]="摧克",
[":LuaCuike"]="出牌阶段开始时，若你的军略标记大于等于7，你移除所有军略标记，对所有其他角色造成1点伤害；若为奇数，你对一名角色造成1点伤害；若为偶数，你横置一名角色，并弃置其1张牌。",
["LuaZhanhuo"]="绽火",
[":LuaZhanhuo"]="限定技，主动技。出牌阶段，你可以移除所有军略标记，选择等量已横置的角色，弃置它们所有装备，并对其中一名角色造成1点火焰伤害。"
}  

shen_lvbu = sgs.General(extension, "shen_lvbu", "qun", 4)  -- 吴国，4血，男性 

LuaKuangbao = sgs.CreateTriggerSkill{  
    name = "LuaKuangbao",  
    events = {sgs.GameStart, sgs.Damage, sgs.Damaged},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if event == sgs.GameStart then
            room:addPlayerMark(player, "@baonu", 2)  
            return ""
        else
            local damage = data:toDamage()  
            room:addPlayerMark(player, "@baonu", damage.damage)
            return ""
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技强制触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        --local damage = data:toDamage()  
        --room:addPlayerMark(player, "@baonu", damage.damage)  
        return false  
    end  
}  
  
LuaWumou = sgs.CreateTriggerSkill{  
    name = "LuaWumou",  
    events = {sgs.PreCardUsed},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local use = data:toCardUse()  
        if use.card and use.card:getTypeId() == sgs.Card_TypeTrick and not use.card:isKindOf("DelayedTrick") then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技强制触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        local choices = {}  
          
        -- 根据当前状态构建选择项  
        if player:getMark("@baonu") > 0 then  
            table.insert(choices, "discard_mark")  
        end  
        table.insert(choices, "lose_hp")  
          
        -- 让玩家选择  
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
          
        if choice == "discard_mark" and player:getMark("@baonu") > 0 then  
            room:removePlayerMark(player, "@baonu", 1)  
        else  
            room:loseHp(player, 1)  
        end  
        return false  
    end  
}  

LuaWuqianCard = sgs.CreateSkillCard{  
    name = "LuaWuqianCard",  
    skill_name = "LuaWuqian",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)  
        room:removePlayerMark(source, "@baonu", 2)  
        room:setPlayerMark(source, "@LuaWuqian", 1) -- 标记本回合已使用  
        room:acquireSkill(source, "wushuang", false) -- 获得无双技能  
    end  
}  
  
-- 无前视为技  
LuaWuqianVS = sgs.CreateZeroCardViewAsSkill{  
    name = "LuaWuqian",  
    view_as = function(self)  
        return LuaWuqianCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@LuaWuqian") == 0 and player:getMark("@baonu") >= 2  
    end  
}  
  
-- 无前主技能  
LuaWuqian = sgs.CreateTriggerSkill{  
    name = "LuaWuqian",  
    events = {sgs.EventPhaseChanging},  
    view_as_skill = LuaWuqianVS,  
    can_trigger = function(self, event, room, player, data)  
        local change = data:toPhaseChange()  
        if change.to == sgs.Player_NotActive and player:getMark("@LuaWuqian") > 0 then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        room:detachSkillFromPlayer(player, "wushuang", false)  
        room:setPlayerMark(player, "@LuaWuqian", 0)  
        return false  
    end  
}  

LuaShenfenCard = sgs.CreateSkillCard{  
    name = "LuaShenfenCard",  
    skill_name = "LuaShenfenCard",  
    target_fixed = true,  
    will_throw = false,  
 
    on_use = function(self, room, source, targets)  
        room:removePlayerMark(source, "@baonu", 6) -- 移除所有军略标记  
        room:setPlayerMark(source, "@shenfen", 0) -- 标记限定技已使用  
          
        -- 弃置所有目标的装备  
        for _, target in sgs.qlist(room:getOtherPlayers(source)) do  
            local damage = sgs.DamageStruct("LuaShenfen", source, target, 1)  
            room:damage(damage)  
            if target:hasEquip() then  
                target:throwAllEquips()  
            end  
            local handcards = target:handCards()  
            local to_discard = math.min(4, handcards:length())  
            for i=1, to_discard do
                room:throwCard(room:askForCardChosen(source, target, "h", self:objectName(), false, sgs.Card_MethodDiscard), target, source)
            end  
        end  
        source:turnOver()
    end  
}  
  
-- 限定技视为技  
LuaShenfen = sgs.CreateZeroCardViewAsSkill{  
    name = "LuaShenfen",  
    limit_mark = "@shenfen",
    view_as = function(self)  
        return LuaShenfenCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@shenfen") > 0 and player:getMark("@baonu") >= 6  
    end  
}  

shen_lvbu:addSkill(LuaKuangbao)
shen_lvbu:addSkill(LuaWumou)
shen_lvbu:addSkill(LuaWuqian)
shen_lvbu:addSkill(LuaShenfen)

-- 翻译表  
sgs.LoadTranslationTable{  
["shen_lvbu"] = "神吕布",
["LuaKuangbao"] = "狂暴",
[":LuaKuangbao"] = "锁定技，游戏开始时，你获得2个“暴怒”标记.你每造成或受到伤害后，你获得X个“暴怒”标记，X为伤害值",
["LuaWumou"] = "无谋",
[":LuaWumou"] = "锁定技。你使用非延时性锦囊时，你弃置1个“暴怒”标记或失去1点体力",
["LuaWuqian"] = "无前",
[":LuaWuqian"] = "主动技。出牌阶段限一次，你可以弃置2个“暴怒”标记，本回合获得无双",
["LuaShenfen"] = "神愤",
[":LuaShenfen"] = "主动技。出牌阶段，你可以弃置6个“暴怒”标记，对所有其他角色造成1点伤害，并弃置其所有装备和4张手牌，然后你叠置。"
}  

shen_pangtong = sgs.General(extension, "shen_pangtong", "shu", 3)  
  
-- 凤燎技能  
fengliao = sgs.CreateTriggerSkill{  
    name = "fengliao",  
    events = {sgs.EventPhaseStart, sgs.CardUsed},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseStart then  
            -- 准备阶段，检查是否没有阴阳标记  
            if player:getPhase() == sgs.Player_Start then  
                if player:getMark("@yin") == 0 and player:getMark("@yang") == 0 then  
                    return self:objectName()  
                end  
            end  
        elseif event == sgs.CardUsed then  
            -- 使用牌指定唯一目标后  
            local use = data:toCardUse()  
            if use.from and use.from:objectName() == player:objectName() and use.to:length() == 1 then  
                if player:getMark("@yin") > 0 or player:getMark("@yang") > 0 then  
                    return self:objectName()  
                end  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            -- 准备阶段选择获得标记  
            local choice = room:askForChoice(player, self:objectName(), "yin+yang")  
            if choice == "yin" then  
                room:setPlayerMark(player, "@yin", 1)  
            else  
                room:setPlayerMark(player, "@yang", 1)  
            end  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        else  
            -- 使用牌时自动触发  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            local target = use.to:first()  
              
            if player:getMark("@yin") > 0 then  
                -- 有阴标记，造成火属性伤害  
                local damage = sgs.DamageStruct()  
                damage.from = player  
                damage.to = target  
                damage.damage = 1  
                damage.nature = sgs.DamageStruct_Fire  
                room:damage(damage)  
                  
                -- 交替标记：阴->阳  
                room:setPlayerMark(player, "@yin", 0)  
                room:setPlayerMark(player, "@yang", 1)  
                  
            elseif player:getMark("@yang") > 0 then  
                -- 有阳标记，令目标摸牌  
                target:drawCards(1, self:objectName())  
                  
                -- 交替标记：阳->阴  
                room:setPlayerMark(player, "@yang", 0)  
                room:setPlayerMark(player, "@yin", 1)  
            end  
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
shen_pangtong:addSkill(fengliao)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["shen_pangtong"] = "神庞统",  
    ["#shen_pangtong"] = "凤雏涅槃",  
    ["fengliao"] = "凤燎",  
    [":fengliao"] = "锁定技，准备阶段，若你没有阴/阳标记，你选择获得阴标记或阳标记。当你使用牌指定唯一目标后，若你有阴标记，你对目标造成1点火属性伤害；若你有阳标记，你令目标摸一张牌。然后阴阳标记交替。",  
    ["@yin"] = "阴",  
    ["@yang"] = "阳",  
    ["fengliao:yin"] = "获得阴标记",  
    ["fengliao:yang"] = "获得阳标记"  
}

shen_lvmeng = sgs.General(extension, "shen_lvmeng", "wu", 3)  
GongxinCard = sgs.CreateSkillCard{  
    name = "GongxinCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local handcards = target:getHandcards()  
        local card_id = room:askForCardChosen(source, target, "h", self:objectName(), true)
        local card = sgs.Sanguosha:getCard(card_id)  
        if card:getSuit() == sgs.Card_Heart then   
            -- 询问是弃置还是置于牌堆顶  
            local choice = room:askForChoice(source, self:objectName(), "top+to_discard")  
            if choice == "top" then  
                room:moveCardTo(card, nil, sgs.Player_DrawPile, true)   
            else
                --room:moveCardTo(card, nil, sgs.Player_DiscardPile, true)   
                room:throwCard(card_id, target, player)  
            end  
        end
    end  
}  
  
-- 攻心视为技  
Gongxin = sgs.CreateZeroCardViewAsSkill{  
    name = "gongxin",  
    view_as = function(self)  
        local card = GongxinCard:clone()  
        card:setSkillName("gongxin")  
        card:setShowSkill("gongxin")  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#GongxinCard")  
    end  
}  
  
shen_lvmeng:addSkill("shelie")
shen_lvmeng:addSkill(Gongxin)

sgs.LoadTranslationTable{
["shen_lvmeng"] = "神吕蒙",
["gongxin"] = "攻心",
[":gongxin"] = "出牌阶段限一次。你可以观看一名其他角色所有手牌，然后你可以选择其中一张红桃牌，并选择弃置此牌或将此牌置于牌堆顶。"
}
shen_machao = sgs.General(extension, "shen_machao", "shu", 4)  -- 吴国，4血，男性  

shouma = sgs.CreateTriggerSkill{  
    name = "shouma",  
    events = {sgs.GeneralShown},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        -- 检查是否是明置此武将  
        if data.toBool() == player:inHeadSkills(self:objectName()) then  
            return self:objectName()  
        end
        --[[
        -- 检查是否是该武将明置  
        local general_name = data:toString()  
        if player:inHeadSkills(self:objectName()) and general_name == player:getGeneralName() then  
            return self:objectName()  
        elseif not player:inHeadSkills(self:objectName()) and general_name == player:getGeneral2Name() then  
            return self:objectName()  
        end  
        ]]
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)
        return true
        --[[
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
        ]]
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 从摸牌堆中检索所有进攻马和防御马  
        local draw_pile = room:getDrawPile()  
        local horses = {}  
          
        for _, id in sgs.qlist(draw_pile) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse") or card:isKindOf("SixDragons") then  
                table.insert(horses, id)  
            end  
        end  
          
        if #horses == 0 then return false end  
          
        -- 获取所有存活角色  
        local all_players = room:getAlivePlayers()  
        local targets = {}  
          
        for _, p in sgs.qlist(all_players) do  
            -- 必须同时没有进攻马和防御马  
            if not p:getOffensiveHorse() and not p:getDefensiveHorse() then  
                table.insert(targets, p)  
            end  
        end  
          
        -- 为每个符合条件的角色随机分配一张马  
        for _, target_player in ipairs(targets) do  
            if #horses > 0 then  
                -- 随机选择一张马  
                local random_index = math.random(1, #horses)  
                local chosen_horse_id = horses[random_index]  
                local chosen_horse = sgs.Sanguosha:getCard(chosen_horse_id)  
                  
                -- 从摸牌堆移除该牌  
                room:takeAG(nil, chosen_horse_id, false)  
                  
                -- 让角色获得并装备该马  
                room:obtainCard(target_player, chosen_horse, false)  
                  
                -- 创建装备使用结构  
                local use = sgs.CardUseStruct()  
                use.card = chosen_horse  
                use.from = target_player  
                use.to:append(target_player)  
                  
                room:useCard(use, false)  
                  
                -- 从可用列表中移除已使用的马  
                table.remove(horses, random_index)  
            end  
        end  
        return false  
    end  
}

hengwu = sgs.CreateTriggerSkill{  
    name = "hengwu",  
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:hasFlag("hengwu_used") then return "" end
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        if not card then return "" end  
          
        -- 检查手牌中是否没有与该牌花色相同的牌  
        local card_suit = card:getSuit()  
        if card_suit == sgs.Card_NoSuit then return "" end  
          
        local handcards = player:getHandcards()  
        for _, hand_card in sgs.qlist(handcards) do  
            if hand_card:getSuit() == card_suit then  
                return "" -- 有相同花色的牌，不能发动  
            end  
        end  
          
        -- 检查场上是否有相同花色的装备  
        local same_suit_equips = 0  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            local equips = p:getEquips()  
            for _, equip in sgs.qlist(equips) do  
                if equip:getSuit() == card_suit then  
                    same_suit_equips = same_suit_equips + 1  
                end  
            end  
        end  
          
        if same_suit_equips > 0 then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        local _data = sgs.QVariant()  
        _data:setValue(card)  
          
        if player:askForSkillInvoke(self:objectName(), _data) then  
            room:setPlayerFlag(player,"hengwu_used")
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        -- 计算场上相同花色装备数量  
        local card_suit = card:getSuit()  
        local same_suit_equips = 0  
          
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            local equips = p:getEquips()  
            for _, equip in sgs.qlist(equips) do  
                if equip:getSuit() == card_suit then  
                    same_suit_equips = same_suit_equips + 1  
                end  
            end  
        end  
          
        if same_suit_equips > 0 then  
            room:drawCards(player, same_suit_equips, self:objectName())  
        end  
          
        return false  
    end  
}

shen_machao:addSkill(shouma)  
shen_machao:addSkill(hengwu)
-- 翻译表  
sgs.LoadTranslationTable{
    ["shen_machao"] = "神马超",
    ["shouma"] = "狩马",
    [":shouma"] = "锁定技，当你明置此武将牌时，你从摸牌堆中检索所有进攻马和防御马，令所有没有装备进攻马和防御马的角色随机获得并使用一张。",
    ["hengwu"] = "横骛",
    [":hengwu"] = "每回合限一次。你使用或打出牌时，若你手牌中没有与该牌花色相同的牌，你可以摸X张牌，X为场上与该牌花色相同的装备数量。"
}  

shen_mazhong = sgs.General(extension, "shen_mazhong", "shu", 3)  -- 吴国，4血，男性  

zhanjue = sgs.CreateTriggerSkill{  
    name = "zhanjue",  
    events = {sgs.EventPhaseStart, sgs.Damage},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
          
        if event == sgs.EventPhaseStart then  
            if player:getPhase() == sgs.Player_Play then  
                return self:objectName()  
            end  
        elseif event == sgs.Damage then  
            local damage = data:toDamage()  
            if damage.from and damage.from:objectName() == player:objectName()   
               and player:hasFlag("zhanjue_recover") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            local choices = {"zhanjue_hp", "zhanjue_lost_hp"}  
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            if choice ~= "" then  
                room:broadcastSkillInvoke(self:objectName())  
                player:setTag("zhanjue_choice", sgs.QVariant(choice))  
                return true  
            end  
        else  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            local choice = player:getTag("zhanjue_choice"):toString()  
              
            if choice == "zhanjue_hp" then  
                -- 选择1：摸等同于当前体力值的牌，然后本回合使用下一张杀无距离限制  
                local hp = player:getHp()  
                if hp > 0 then  
                    room:drawCards(player, hp, self:objectName())  
                    room:setPlayerFlag(player, "zhanjue_slash")  
                end  
            elseif choice == "zhanjue_lost_hp" then  
                -- 选择2：摸等同于已失去体力值的牌，然后本回合下一次造成伤害后回复等量体力值  
                local lost_hp = player:getLostHp()  
                if lost_hp > 0 then  
                    room:drawCards(player, lost_hp, self:objectName())  
                    room:setPlayerFlag(player, "zhanjue_recover")  
                end  
            end  
        elseif event == sgs.Damage then  
            -- 处理伤害后回复体力  
            local damage = data:toDamage()  
            local recover = sgs.RecoverStruct()  
            recover.who = player  
            recover.recover = damage.damage
            room:recover(player, recover)  
            room:setPlayerFlag(player, "-zhanjue_recover")  
        end  
        return false  
    end  
}  
  
-- 杀无距离限制的辅助技能  
zhanjue_slash_ndl = sgs.CreateTargetModSkill{  
    name = "#zhanjue-slash-ndl",  
    pattern = "Slash",  
    distance_limit_func = function(self, from, card)  
        if from:hasFlag("zhanjue_slash") then  
            return 1000  
        end  
        return 0  
    end  
}  
  
shen_mazhong:addSkill(zhanjue)  
shen_mazhong:addSkill(zhanjue_slash_ndl)  
-- 翻译表  
sgs.LoadTranslationTable{
    ["shen_mazhong"] = "神马忠",
    ["zhanjue"] = "斩决",
    [":zhanjue"] = "出牌阶段开始时，你可以选择：（1）摸等同于当前体力值的牌，然后本回合使用杀无距离限制（2）摸等同于已失去体力值的牌，然后本回合下一次造成伤害后回复等量体力值"
}  


shen_zhaoyun = sgs.General(extension, "shen_zhaoyun", "shu", 4)  

juejing = sgs.CreateTriggerSkill{  
    name = "juejing",  
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data) 
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if player:getPhase() == sgs.Player_Start then  
            return self:objectName()
        else
            if player:getHandcardNum()~=4 then
                return self:objectName()
            end
        end  
    end,  
    on_cost = function(self, event, room, player, data)
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Start then  
            player:skip(sgs.Player_Draw)  
        else
            local handcard_num = player:getHandcardNum()  
            if handcard_num ~= 4 then  
                if handcard_num < 4 then  
                    player:drawCards(4 - handcard_num, "juejing")  
                else  
                    room:askForDiscard(player, "juejing", handcard_num - 4, handcard_num - 4, false, false)  
                end  
            end  
        end  
        return false -- 跳过摸牌阶段  
    end  
}  
  
longhun = sgs.CreateViewAsSkill{  
    name = "longhun",  
    n = 1,  
    view_filter = function(self, selected, to_select)
        if #selected ~= 0 then return false end
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if string.find(pattern,"peach") then
            return to_select:getSuit() == sgs.Card_Heart
        elseif pattern == "slash" then
            return to_select:getSuit() == sgs.Card_Diamond
        elseif pattern == "jink" then
            return to_select:getSuit() == sgs.Card_Club
        elseif pattern == "nullification" then
            return to_select:getSuit() == sgs.Card_Spade
        end
        return true
    end,  
    view_as = function(self, cards)  
        if #cards ~= 1 then return nil end  
        local card = cards[1]  
        local suit = card:getSuit()  
        
        if suit == sgs.Card_Heart then  
            local peach = sgs.Sanguosha:cloneCard("peach")  
            peach:addSubcard(card)  
            peach:setSkillName(self:objectName())  
            return peach  
        elseif suit == sgs.Card_Diamond then  
            local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")  
            fire_slash:addSubcard(card)  
            fire_slash:setSkillName(self:objectName())  
            return fire_slash  
        elseif suit == sgs.Card_Club then  
            local jink = sgs.Sanguosha:cloneCard("jink")  
            jink:addSubcard(card)  
            jink:setSkillName(self:objectName())  
            return jink  
        elseif suit == sgs.Card_Spade then  
            local nullification = sgs.Sanguosha:cloneCard("nullification")  
            nullification:addSubcard(card)  
            nullification:setSkillName(self:objectName())  
            return nullification  
        end  
        return nil  
    end,
    enabled_at_play = function(self, player)  
        return true  
    end,  
    enabled_at_response = function(self, player, pattern)  
        return pattern == "slash" or pattern == "jink" or string.find(pattern,"peach") or pattern == "nullification"  
    end  
}


--shen_zhaoyun:addSkill(juejing)  
shen_zhaoyun:addSkill(longhun)
sgs.LoadTranslationTable{
    ["shen_zhaoyun"] = "神赵云",  
    ["juejing"] = "绝境",
    [":juejing"] = "你始终跳过你的摸牌阶段；你的手牌数始终为4.",
    ["longhun"] = "龙魂",
    [":longhun"] = "你的红桃牌可以视为桃，方块牌可以视为火杀，梅花牌可以视为闪，黑桃牌可以视为无懈可击"
}

shen_zhenji = sgs.General(extension, "shen_zhenji", "jin", 3, false)  -- 吴国，4血，男性  

shenfu_skill = sgs.CreateTriggerSkill{  
    name = "shenfu",  
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then  
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
        local handcard_num = player:getHandcardNum()  
        local skill_used = 0  
          
        if handcard_num % 2 == 1 then  
            -- 奇数：造成1点雷属性伤害  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                targets:append(p)  
            end  
              
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shenfu-damage")  
            if target then  
                room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))  
                skill_used = 1  
            end  
        else  
            -- 偶数：摸牌或弃牌效果  
            local used_targets = {}  
              
            while true do  
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if not used_targets[p:objectName()] then  
                        targets:append(p)  
                    end  
                end  
                  
                if targets:isEmpty() then break end  
                  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shenfu-choose")  
                if not target then break end  
                  
                used_targets[target:objectName()] = true  
                  
                -- 选择摸牌或弃牌  
                local choice = room:askForChoice(player, self:objectName(), "draw+discard", data)  
                  
                if choice == "draw" then  
                    target:drawCards(1, self:objectName())  
                else  
                    if not target:isAllNude() then  
                        --room:askForDiscard(target, self:objectName(), 1, 1, false, true) 
                        local card_id = room:askForCardChosen(player, target, "hej", self:objectName(), false, sgs.Card_MethodDiscard)  
                        room:throwCard(card_id, target, player)   
                    end  
                end  
                  
                skill_used = skill_used + 1  
                  
                -- 检查是否可以重复（手牌数等于体力值）  
                if target:getHandcardNum() ~= target:getHp() then  
                    break  
                end  
                  
                -- 询问是否继续  
                if not player:askForSkillInvoke(self:objectName() .. "_continue", sgs.QVariant()) then  
                    break  
                end  
            end  
        end  
          
        -- 回合结束后摸X张牌  
        if skill_used > 0 then  
            player:drawCards(skill_used, self:objectName())  
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
shen_zhenji:addSkill(shenfu_skill)
shen_zhenji:addSkill("qingguo")

-- 翻译表  
sgs.LoadTranslationTable{
["shen_zhenji"] = "神甄姬",  
["shenfu"] = "神赋",  
[":shenfu"] = "回合结束时，若你的手牌为：奇数，你可以对一名角色造成1点雷属性伤害；偶数，你可以令一名角色摸1张牌或弃置一名角色1张牌，若此时其手牌数等于体力值，你可重复此流程，同一名角色只能选择1次。回合结束后，你摸X张牌，X为本回合发动此技能的次数。",  
["@shenfu-damage"] = "神赋：选择一名角色，对其造成1点雷属性伤害",  
["@shenfu-choose"] = "神赋：选择一名角色，令其摸牌或弃牌",  
["shenfu_continue"] = "是否继续发动神赋？",  
["draw"] = "摸牌",  
["discard"] = "弃牌"
}  

shen_zhouyu = sgs.General(extension, "shen_zhouyu", "wu", 3)  -- 吴国，4血，男性 
LuaQinyin = sgs.CreateTriggerSkill{  
    name = "LuaQinyin",  
    events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:getPhase() == sgs.Player_Discard then  
            if event == sgs.EventPhaseStart then
                local discard_num = player:getHandcardNum() - player:getMaxCards()  
                if discard_num >= 2 then
                    return self:objectName()
                end  
            elseif event == sgs.EventPhaseEnd then
                if player:hasFlag("qinyin") then
                    return self:objectName()  
                end
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then
            local discard_num = player:getHandcardNum() - player:getMaxCards()  
            if discard_num >= 2 then
                return player:askForSkillInvoke(self:objectName(), data)
            end  
        elseif event == sgs.EventPhaseEnd then
            if player:hasFlag("qinyin") then
                return true  
            end
        end
        return false  
    end,  
    on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            local discard_num = player:getHandcardNum() - player:getMaxCards()  
            if discard_num >= 2 then
                room:setPlayerFlag(player,"qinyin")
            end  
        elseif event == sgs.EventPhaseEnd then
            if player:hasFlag("qinyin") then
                local choices = {"recover", "lose_hp", "draw"}  
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
                
                local all_players = room:getAllPlayers()  
                if choice == "recover" then  
                    -- 所有角色恢复1点体力  
                    for _, p in sgs.qlist(all_players) do  
                        if p:isAlive() and p:isWounded() then  
                            local recover = sgs.RecoverStruct()  
                            recover.who = player  
                            recover.recover = 1  
                            room:recover(p, recover)  
                        end  
                    end  
                elseif choice == "lose_hp" then
                    -- 所有角色失去1点体力  
                    for _, p in sgs.qlist(all_players) do  
                        if p:isAlive() then  
                            room:loseHp(p, 1)  
                        end  
                    end
                else
                    for _, p in sgs.qlist(all_players) do  
                        if p:isAlive() then  
                            room:drawCards(p, 1, self:objectName())  
                        end  
                    end                    
                end                   
            end
        end
        return false  
    end  
}  
  
-- 业火技能卡  
LuaYehuoCard = sgs.CreateSkillCard{  
    name = "LuaYehuoCard",  
    skill_name = "LuaYehuo",  
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
        room:setPlayerMark(source, "@LuaYehuo", 0) -- 标记限定技已使用  
          
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
  
-- 业火视为技  
LuaYehuo = sgs.CreateZeroCardViewAsSkill{  
    name = "LuaYehuo",  
    limit_mark = "@LuaYehuo",
    view_as = function(self)  
        return LuaYehuoCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@LuaYehuo") > 0  
    end  
}  

shen_zhouyu:addSkill(LuaQinyin)
shen_zhouyu:addSkill(LuaYehuo)
-- 翻译表  
sgs.LoadTranslationTable{  
["shen_zhouyu"] = "神周瑜",
["LuaQinyin"] = "琴音",
[":LuaQinyin"] = "弃牌阶段开始时，若你需要弃置的牌数大于等于2，你可以选择（1）令所有角色恢复1点体力（2）令所有角色失去1点体力（3）令所有角色摸一张牌。",
["LuaYehuo"] = "业火",
[":LuaYehuo"] = "限定技。​​出牌阶段​​，你可分配最多3点火焰伤害至1-3名角色；若对单个目标分配≥2点伤害，你失去​​3点体力​​"
}  
return {extension}