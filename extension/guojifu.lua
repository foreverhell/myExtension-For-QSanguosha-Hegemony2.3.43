extension = sgs.Package("guojifu", sgs.Package_GeneralPack)
sgs.LoadTranslationTable{
    ["guojifu"] = "国际服",
}
fengxi2 = sgs.General(extension, "fengxi2", "shu", 4)
qingkou = sgs.CreateTriggerSkill{  
    name = "qingkou",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.Damage},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart and player and player:isAlive() and player:hasSkill(self:objectName()) then
            if player:getPhase() == sgs.Player_Start then
                return self:objectName()
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()  
            if change.to == sgs.Player_Discard and player:hasFlag("qingkou_damage") then
                player:skip(sgs.Player_Discard)
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card:getSkillName() == self:objectName() then
                damage.from:drawCards(1,self:objectName())
                room:setPlayerFlag(damage.from,"qingkou_damage")
            end
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart  then
            return player:askForSkillInvoke(self:objectName(),data)
        end
        return false
    end,  
    on_effect = function(self, event, room, player, data)  
        local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName())
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)  
        duel:setSkillName(self:objectName())  
        local use = sgs.CardUseStruct()  
        use.card = duel  
        use.from = player  
        use.to:append(target)  
        room:useCard(use) 
        duel:deleteLater()
        if player:hasFlag("qingkou_damage") then
            player:skip(sgs.Player_Judge)
        end
        return false  
    end  
}
fengxi2:addSkill(qingkou)
sgs.LoadTranslationTable{
    ["fengxi2"] = "冯习",
    ["qingkou"] = "轻寇",
    [":qingkou"] = "准备阶段，你可以视为使用一张决斗，结算完成后，造成伤害的角色摸1张牌，若造成伤害的角色为你，你跳过本回合的判定阶段和弃牌阶段"
}

gaolan = sgs.General(extension, "gaolan", "qun", 4)  -- 吴国，4血，男性  
jungongCard = sgs.CreateSkillCard{  
    name = "jungongCard",  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,  
      
    on_use = function(self, room, source, targets)  
        local cost = source:usedTimes("ViewAsSkill_jungongCard")
        if not (source:getHandcardNum() >= cost and room:askForDiscard(source, self:objectName(), cost, cost, true, true)) then
            room:loseHp(source, cost)
        end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
        slash:setSkillName("jungong")  
        local use = sgs.CardUseStruct()  
        use.card = slash  
        use.from = source  
        use.to:append(targets[1])  
        room:useCard(use, false) 
        slash:deleteLater()
    end  
}  
  
-- 创建鬼斧视为技  
jungongVS = sgs.CreateZeroCardViewAsSkill{  
    name = "jungong",  
      
    view_as = function(self)  
        local card = jungongCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        --local times = player:usedTimes("ViewAsSkill_jungongCard")+1
        return not player:hasFlag("jungong_unable")
    end  
}  


jungong = sgs.CreateTriggerSkill{
    name = "jungong",
    events = {sgs.Damage},
    view_as_skill = jungongVS,
    can_trigger = function(self, event, room, player, data)
        local damage = data:toDamage()
        if damage.card and damage.card:getSkillName() == self:objectName() then
            room:setPlayerFlag(player, "jungong_unable")
        end
        return ""
    end,
    
    on_cost = function(self, event, room, player, data)
        return false
    end,
    
    on_effect = function(self, event, room, player, data)
        return false
    end
}
dengli = sgs.CreateTriggerSkill{  
    name = "dengli",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)    
        -- 寻找拥有诗怨技能的角色  
        local dengli_player = room:findPlayerBySkillName(self:objectName())  
        if not (dengli_player and dengli_player:isAlive() and dengli_player:hasSkill(self:objectName())) then return "" end

        local use = data:toCardUse()  
        local source = use.from
        if not (source and source:isAlive()) then return "" end
        if not use.card:isKindOf("Slash") then return "" end

        local is_involved = false  
        local other_player = nil  
            
        -- 检查是否为使用者或目标  
        if source and source:objectName() == dengli_player:objectName() then  
            -- 技能拥有者使用牌指定其他角色  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() ~= dengli_player:objectName() then  
                    is_involved = true  
                    other_player = target  
                    break  
                end  
            end  
        elseif source and source:objectName() ~= dengli_player:objectName() then  
            -- 其他角色使用牌指定技能拥有者  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() == dengli_player:objectName() then  
                    is_involved = true  
                    other_player = source  
                    break  
                end  
            end  
        end
        if is_involved and other_player:getHp()==dengli_player:getHp() then
            return self:objectName(), dengli_player:objectName()
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
        ask_who:drawCards(1,self:objectName())          
        return false  
    end  
}  
gaolan:addSkill(jungong)
gaolan:addSkill(dengli)
sgs.LoadTranslationTable{
    ["gaolan"] = "高览",
    ["jungong"] = "峻攻",
    [":jungong"] = "出牌阶段，你可以失去X点体力或弃置X张牌（X为你本回合使用此技能的次数+1），视为使用一张无距离限制的杀，若此杀造成伤害，本回合此技能失效",
    ["dengli"] = "等力",
    [":dengli"] = "当你使用杀指定其他角色为目标，或成为其他角色使用杀的目标时，若你与其体力值相等，你摸一张牌"
}

guansuo = sgs.General(extension, "guansuo", "shu", 4)  -- 吴国，4血，男性  

zhengnan_skill = sgs.CreateTriggerSkill{  
    name = "zhengnan",  
    events = {sgs.Death},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        -- 寻找拥有徵南技能的角色  
        local zhengnan_player = room:findPlayerBySkillName(self:objectName())
        if not (zhengnan_player and zhengnan_player:isAlive() and zhengnan_player:hasSkill(self:objectName())) then
            return ""
        end
        local death = data:toDeath()
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
    --第三版
    on_effect = function(self, event, room, player, data, ask_who)            
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
            local skill_name = room:askForChoice(ask_who, self:objectName(), table.concat(available_skills, "+"), data)  
            room:acquireSkill(ask_who, skill_name)  
        elseif ask_who:isWounded() then
            -- 回复一点体力
            local recover = sgs.RecoverStruct()  
            recover.recover = 1  
            recover.who = ask_who  
            room:recover(ask_who, recover)  
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
    --[[
    --第二版，灵活性强
    on_effect = function(self, event, room, player, data, ask_who)            
        -- 检查已获得的技能  
        local available_skills = {}  
        local skill_names = {"wusheng", "dangxian", "zhiman"}  
          
        for _, skill_name in ipairs(skill_names) do  
            if not ask_who:hasSkill(skill_name) then  
                table.insert(available_skills, skill_name)  
            end  
        end  
        
        local choices = {"draw3"}
        if #available_skills > 0 then  
            table.insert(choices,"acquireSkill")
        end
        if ask_who:isWounded() then
            table.insert(choices,"draw1")
        end
        local choice = room:askForChoice(ask_who, self:objectName(), table.concat(choices, "+"), data)  
        if choice == "acquireSkill" then
            -- 选择一个技能获得  
            local skill_name = room:askForChoice(ask_who, self:objectName(), table.concat(available_skills, "+"), data)  
            room:acquireSkill(ask_who, skill_name)  
        elseif choice == "draw1" then
            -- 回复一点体力
            local recover = sgs.RecoverStruct()  
            recover.recover = 1  
            recover.who = ask_who  
            room:recover(ask_who, recover)  
            -- 摸1张牌  
            ask_who:drawCards(1, self:objectName())  
        elseif choice == "draw3" then
            -- 所有技能都已获得，摸3张牌  
            ask_who:drawCards(3, self:objectName())  
        end  
        local death = data:toDying()
        local death_player = death.who
        local mark_name = "zhengnan" .. death_player:objectName()--string.format("zhengnan_%s", dead_player:objectName())  
        room:setPlayerMark(ask_who,mark_name,1)
        return false  
    end  
    ]]
    --[[
    --第一版，和身份局完全一样，最强
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
    ]]
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
--[":zhengnan"] = "每名角色限一次，任意角色进入濒死时，你可以回复一点体力，并从武圣、当先、制蛮中选择一个技能获得，然后摸1张牌；若所有技能都已获得，则摸三张牌。",  
--[":zhengnan"] = "每名角色限一次，任意角色进入濒死时，你可以选择（1）从武圣、当先、制蛮中选择一个技能获得（2）回复一点体力，并摸1张牌（3）摸三张牌。",  
[":zhengnan"] = "每名角色限一次，任意角色死亡时，你可以从武圣、当先、制蛮中选择一个技能获得；当所有技能都已获得：若你受伤，你回复一点体力，并摸1张牌，否则你摸三张牌。",  
["xiefang"] = "撷芳",  
[":xiefang"] = "你到其他角色的距离-X，X为全场女性角色数。",  
["wusheng"] = "武圣",  
["dangxian"] = "当先",   
["zhiman"] = "制蛮"
}  
liuzan = sgs.General(extension, "liuzan", "wu", 4)
fenyin = sgs.CreateTriggerSkill{  
    name = "fenyin",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,--sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            local current = room:getCurrent()
            if current ~= player then return "" end --回合内
            local use = data:toCardUse()  
            if use.from == player and use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill then  --不是技能卡
                if use.card:isBlack() then --用的是黑牌
                    room:setPlayerFlag(player,"fenyin_black") --黑标记
                    if player:hasFlag("fenyin_red") then --若有红标记
                        room:setPlayerFlag(player,"-fenyin_red") --清除红标记
                        return self:objectName() --发动技能
                    end
                elseif use.card:isRed() then --用的是红牌
                    room:setPlayerFlag(player,"fenyin_red") --红标记
                    if player:hasFlag("fenyin_black") then --若有黑标记
                        room:setPlayerFlag(player,"-fenyin_black") --清除黑标记
                        return self:objectName() --发动技能
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
        room:drawCards(player, 1, self:objectName())  
        return false  
    end  
}
liuzan:addSkill(fenyin)
sgs.LoadTranslationTable{
    ["liuzan"] = "留赞",
    ["fenyin"] = "奋音",
    [":fenyin"] = "出牌阶段，若你使用的牌与上一张颜色不同，你摸一张牌",
}
mizhu = sgs.General(extension, "mizhu", "shu", 3)
ziyuanCard = sgs.CreateSkillCard{  
    name = "ziyuanCard",  
    target_fixed = false,--是否需要指定目标，默认false，即需要
    will_throw = false,
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:isFriendWith(to_select)
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  --接收手牌的角色 

        -- 将手牌交给目标角色
        local move = sgs.CardsMoveStruct()
        move.card_ids = self:getSubcards()
        move.to = target
        move.to_place = sgs.Player_PlaceHand
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "ziyuan", "")  
        room:moveCardsAtomic(move, true)

        if target:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who = target
            recover.recover = 1
            room:recover(target, recover)
        end
    end  
}  
ziyuan = sgs.CreateViewAsSkill{  
    name = "ziyuan",  
    view_filter = function(self, selected, to_select)--是过滤当前可选的牌，不是是否可以继续选牌
        local total_points = 0
        for _, card in ipairs(selected) do  
            total_points = total_points + card:getNumber()  
        end  
        return total_points + to_select:getNumber() <= 13 --不算上to_select，可能超过13
    end,  
    view_as = function(self, cards)  
        local view_as_card = ziyuanCard:clone()
        local number = 0
        for _,card in ipairs(cards) do
            number = number + card:getNumber()
            view_as_card:addSubcard(card:getId())
        end
        if number ~= 13 then return nil end
        view_as_card:setShowSkill(self:objectName())
        return view_as_card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#ziyuanCard")
    end,
}

jugu = sgs.CreateTriggerSkill{
	name = "jugu",
	events = {sgs.GeneralShowed},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		if player:cheakSkillLocation("jugu", data) and player:getMark("juguUsed") == 0 then
            return self:objectName()
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, "jugu")
        room:broadcastSkillInvoke("jugu", player)
        room:addPlayerMark(player, "juguUsed")
        return true
	end,
    on_effect = function(self, event, room, player, data)
        player:drawCards(player:getMaxHp(),self:objectName())
		return false
	end,
}
jugu_maxcards = sgs.CreateMaxCardsSkill{  
    name = "#jugu_maxcards",  
    extra_func = function(self, player)  
        if player:hasShownSkill("jugu") then
            return player:getMaxHp()
        end
        return 0
    end  
}
mizhu:addSkill(ziyuan)
mizhu:addSkill(jugu)
mizhu:addSkill(jugu_maxcards)
sgs.LoadTranslationTable{
    ["mizhu"] = "糜竺",
    ["ziyuan"] = "资援",
    [":ziyuan"] = "出牌阶段限一次。你可以将点数和为13的任意张牌交给一名相同势力的其他角色，并令其恢复1点体力。",
    ["jugu"] = "巨贾",
    [":jugu"] = "锁定技。你首次明置此武将后，你摸X张牌；你的手牌上限+X；X为你的体力上限"
}

wujing = sgs.General(extension, "wujing", "wu", 4) 
fenghan = sgs.CreateTriggerSkill{  
    name = "fenghan",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,          
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return false  
        end 
        local use = data:toCardUse()  
        if isDamageCard(use.card) and not player:hasFlag("fenghan_used") then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(),data) then
            room:setPlayerFlag(player,"fenghan_used")
            return true
        end
        return false
    end,  
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()
        local num = use.to:length()
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end
        local chosen_players = room:askForPlayersChosen(player,  targets, self:objectName(), num, num, "请选择玩家", false)
        for _,p in sgs.qlist(chosen_players) do
            p:drawCards(1,self:objectName())
        end
        return false  
    end,
}  

congji = sgs.CreateTriggerSkill{  
    name = "congji",  
    events = {sgs.CardsMoveOneTime},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
                if player:objectName()==current:objectName() then return "" end
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from and move.from:isAlive() and move.from==player then
                            for _,card_id in sgs.qlist(move.card_ids) do
                                local card = sgs.Sanguosha:getCard(card_id)  
                                if card:isRed() then  
                                    return self:objectName()
                                end
                            end 
                        end
					end
				end
			end
		end     
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)            
        return player:askForSkillInvoke(self:objectName(), data) 
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local move_datas = data:toList()
        local card_ids = sgs.IntList()
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
            --if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
            if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                if move.from and move.from:isAlive() and move.from==player then
                    for _,card_id in sgs.qlist(move.card_ids) do
                        local card = sgs.Sanguosha:getCard(card_id)  
                        if card:isRed() then  
                            card_ids:append(card_id)
                        end
                    end 
                end
            end
        end
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end
        if targets:isEmpty() then return false end
        local target = room:askForPlayerChosen(player,targets,self:objectName())
        if target then
            local dummy = sgs.DummyCard(card_ids)  
            target:obtainCard(dummy)  
            dummy:deleteLater()  
        end
        return false  
    end  
}  
wujing:addSkill(fenghan)
wujing:addSkill(congji)
sgs.LoadTranslationTable{
    ["fenghan"] = "锋悍",
    [":fenghan"] = "每回合限一次。你使用杀或伤害锦囊指定目标后，你可以令至多X名相同势力角色摸1张牌，X为目标数",
    ["congji"] = "从击",
    [":congji"] = "你回合外因弃置失去牌后，你可以将其中所有红色牌交给一名相同势力的其他角色"
}

yanrou = sgs.General(extension, "yanrou", "wei", 4) 

choufa = sgs.CreateTriggerSkill{  
    name = "choufa",  
    events = {sgs.TargetConfirming, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
        local choufa_player = room:findPlayerBySkillName(self:objectName())  
        if not (choufa_player and choufa_player:isAlive() and choufa_player:hasSkill(self:objectName())) then return "" end
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()  
            local source = use.from
            if not (source and source:isAlive()) then return "" end
            if source:isNude() then return "" end
            if not use.card:isKindOf("Slash") then return "" end

            local is_involved = false  
                
            -- 检查是否为使用者或目标  
            if source and source:objectName() == choufa_player:objectName() then  
                -- 技能拥有者使用牌指定其他角色  
                is_involved = true  
            elseif source and source:objectName() ~= choufa_player:objectName() then  
                -- 其他角色使用牌指定技能拥有者  
                for _, target in sgs.qlist(use.to) do  
                    if target:objectName() == choufa_player:objectName() then  
                        is_involved = true  
                        break  
                    end  
                end  
            end
            if is_involved then
                return self:objectName(), choufa_player:objectName()
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
            room:setPlayerMark(player,"@choufa",0)
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
        local use = data:toCardUse()  
        local card_id = room:askForCardChosen(ask_who,use.from,"he",self:objectName())
        room:throwCard(card_id,use.from,ask_who)
        use.card:setFlags("GlobalCardUseDisresponsive")
        if use.from == ask_who then
            room:addPlayerMark(ask_who,"@choufa")
        end
        return false  
    end  
}  
choufaMod = sgs.CreateTargetModSkill{  
    name = "#choufa-mod",  
    residue_func = function(self, player, card)  
        return player:getMark("@choufa") 
    end  
}

xiangshuLimit = sgs.CreateTriggerSkill{  
    name = "xiangshuLimit",  
    events = {sgs.Damage, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Limit,  
    --limit_mark = "@xiangshuLimit",
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("@xiangshuLimit") == 0) then return "" end
        if event == sgs.Damage then
            local damage = data:toDamage()
            room:addPlayerMark(player,"@xiangshuLimit_damage",damage.damage)
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:getMark("@xiangshuLimit_damage")>0 then
            return self:objectName()
        end
    end,
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(),data) then
            room:setPlayerMark(player,"@xiangshuLimit",1)
            return true
        end
        room:setPlayerMark(player,"@xiangshuLimit_damage",0)
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local n = player:getMark("@xiangshuLimit_damage")
        n = math.min(n,5)
        room:setPlayerMark(player,"@xiangshuLimit_damage",0)
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end
        local target = room:askForPlayerChosen(player,targets,self:objectName())
        if target:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who = target
            recover.recover = n
            room:recover(target, recover)
        end
        target:drawCards(n,self:objectName())
    end,
}
yanrou:addSkill(choufa)
yanrou:addSkill(choufaMod)
yanrou:addSkill(xiangshuLimit)
sgs.LoadTranslationTable{
    ["yanrou"] = "阎柔",
    ["choufa"] = "仇伐",
    [":choufa"] = "你使用杀指定目标后，或你成为杀的目标后，你可以弃置此杀使用者一张牌，令此杀不可响应，若使用者为你，此杀不计入次数",
    ["xiangshuLimit"] = "襄戍",
    [":xiangshuLimit"] = "限定技。结束阶段，若你本回合造成过伤害，你可以令一名角色恢复X点体力并摸X张牌，X为你本回合造成的伤害值且至多为5"
}
zhangsong = sgs.General(extension, "zhangsong", "shu", 3)

qiangshi = sgs.CreateTriggerSkill{  
    name = "qiangshi",  
    events = {sgs.EventPhaseStart, sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end

        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then --出牌阶段开始时
                return self:objectName()
            elseif player:getPhase() == sgs.Player_Finish then --结束阶段
                room:setPlayerMark(player,"@qiangshi-type",0)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from == player and use.card and use.card:getTypeId() == player:getMark("@qiangshi-type") then
                player:drawCards(1,self:objectName())
            end
        end
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 询问是否发动技能  
        if room:askForSkillInvoke(player, self:objectName(), data) then
            return true
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if not p:isKongcheng() then  
                targets:append(p)  
            end  
        end  
        if targets:isEmpty() then return false end
        local target = room:askForPlayerChosen(player, targets, self:objectName())
        local card_id = room:askForCardChosen(player, target, "h", self:objectName())
        room:showCard(target, card_id)
        local card = sgs.Sanguosha:getCard(card_id)
        if card then
            room:setPlayerMark(player,"@qiangshi-type",card:getTypeId())
        end
        return false
    end  
}
zhangsong:addSkill(qiangshi)
zhangsong:addSkill("luaxiantu")
sgs.LoadTranslationTable{
    ["zhangsong"] = "张松",
    ["qiangshi"] = "强识",
    [":qiangshi"] = "出牌阶段开始时，你可以展示其他角色一张手牌，本回合你使用与此相同类型的牌时，你摸1张牌",
}

zhangxingcai = sgs.General(extension, "zhangxingcai", "shu", 3, false)  
qiangwu = sgs.CreateTriggerSkill{  
    name = "qiangwu",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if player:getPhase() == sgs.Player_Play then  
            return self:objectName()
        elseif player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player,"@qiangwu_number", 0)  
        end  
    end,  
    on_cost = function(self, event, room, player, data)  
        if room:askForSkillInvoke(player, self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local judge = sgs.JudgeStruct()  
        judge.pattern = "."  
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = player  
        room:judge(judge)  
          
        local number = judge.card:getNumber()  
        room:setPlayerMark(player,"@qiangwu_number", number)  
        return false  
    end  
}  
  
-- 目标修改技能：修改杀的限制  
 qiangwu_mod = sgs.CreateTargetModSkill{  
    name = "#qiangwu-mod",  
    pattern = "Slash",  
    distance_limit_func = function(self, player, card)  
        if player:getMark("@qiangwu_number") > 0 and card:getNumber() < player:getMark("@qiangwu_number") then  
            return 1000  -- 无距离限制  
        end  
        return 0  
    end,  
    residue_func = function(self, player, card)  
        if player:getMark("@qiangwu_number") > 0 and card:getNumber() > player:getMark("@qiangwu_number") then  
            return 1000  -- 无次数限制  
        end  
        return 0  
    end  
}  

shenzi = sgs.CreateTriggerSkill{  
    name = "shenzi",  
    events = {sgs.CardsMoveOneTime},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            if player:hasFlag("shenzi_used") then return "" end
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
                if player:objectName()==current:objectName() then return "" end
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from and move.from:isAlive() and move.from:objectName()~=player:objectName() then
                            for _,card_id in sgs.qlist(move.card_ids) do
                                local card = sgs.Sanguosha:getCard(card_id)  
                                local card_type = card:getTypeId()
                                if card_type == sgs.Card_TypeBasic then  
                                    return self:objectName()
                                end
                            end 
                        end
					end
				end
			end
		end     
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)            
        return player:askForSkillInvoke(self:objectName(), data) 
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local move_datas = data:toList()
        should_draw = false
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            for _,card_id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(card_id)  
                local card_type = card:getTypeId()
                if card_type == sgs.Card_TypeBasic then  
                    should_draw = true
                    break
                end
            end 
        end
        if should_draw then
            player:drawCards(1, self:objectName())
            room:setPlayerFlag(player,"shenzi_used")
        end
        return false  
    end  
}  

zhangxingcai:addSkill(qiangwu)
zhangxingcai:addSkill(qiangwu_mod)
zhangxingcai:addSkill(shenzi)
sgs.LoadTranslationTable{
    ["zhangxingcai"] = "张星彩",
    ["qiangwu"] = "枪舞",
    [":qiangwu"] = "出牌阶段开始时，你可以进行一次判定，本回合你使用点数小于判定牌的杀无距离限制，使用点数大于判定牌的杀无次数限制",
    ["shenzi"] = "甚资",
    [":shenzi"] = "每回合限一次。你的回合外，其他角色因弃置而失去基本牌时，你摸1张牌"
}

zhoufang = sgs.General(extension, "zhoufang", "wu", 3)  -- 吴国，4血，男性  

duanfaCard = sgs.CreateSkillCard{
    name = "duanfaCard",
    target_fixed = true,--是否需要指定目标，默认false，即需要
    will_throw = true,
    on_use = function(self, room, source)
        source:drawCards(self:getSubcards():length(),self:objectName())
        return false
    end
}

duanfa = sgs.CreateViewAsSkill{  
    name = "duanfa", 
    view_filter = function(self, selected, to_select)  
        if #selected >= sgs.Self:getMaxHp() then return false end
        return to_select:isBlack()
    end,  
    view_as = function(self, cards)  
        if #cards <= sgs.Self:getMaxHp() then  
            local card = duanfaCard:clone() -- 创建虚拟牌  
            for _, c in ipairs(cards) do
                card:addSubcard(c)  
            end
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#duanfaCard") and not player:isNude() 
    end  
}

youdi = sgs.CreateTriggerSkill{  
    name = "youdi",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish) then
            return ""
        end
        if not player:isKongcheng() then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return room:askForSkillInvoke(player, self:objectName(), data)
    end,  
    on_effect = function(self, event, room, player, data)  
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
        local card_id = room:askForCardChosen(target, player, "h", self:objectName())
        local card = sgs.Sanguosha:getCard(card_id)
        room:throwCard(card_id, player, target)
        if not card:isKindOf("Slash") then
            local to_get = room:askForCardChosen(player, target, "hej", self:objectName())
            room:obtainCard(player, to_get)
        end
        if not card:isBlack() then
            player:drawCards(1,self:objectName())
        end
        return false  
    end  
}
zhoufang:addSkill(duanfa)
zhoufang:addSkill(youdi)
sgs.LoadTranslationTable{
    ["zhoufang"] = "周鲂",
    ["duanfa"] = "断发",
    [":duanfa"] = "出牌阶段限一次，你可以弃置至多X张黑色牌（X为你的体力上限），然后摸等量牌",
    ["youdi"] = "诱敌",
    [":youdi"] = "你的回合结束时，你可以令一名其他角色弃置你一张手牌：若该牌不为杀，你获得其1张牌；若该牌不为黑色，你摸1张牌"
}

zhugezhan = sgs.General(extension, "zhugezhan", "shu", 3)  
zuilun = sgs.CreateTriggerSkill{  
    name = "zuilun",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，无需询问  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 观星牌堆顶3张牌  
        local guanxing = room:getNCards(3)  
        room:askForGuanxing(player, guanxing, sgs.Room_GuanxingUpOnly)  --Room_GuanxingBothSides
          
        -- 计算X值  
        local x = 0  
          
        -- 条件1：与你势力相同的其他角色数>1  
        local same_kingdom_count = 0  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if player:isFriendWith(p) then  --p:getKingdom() == player:getKingdom() --需要考虑野心家的情况
                same_kingdom_count = same_kingdom_count + 1  
            end  
        end  
        if same_kingdom_count > 1 then  
            x = x + 1  
        end  
          
        -- 条件2：本回合你造成的伤害数>1  
        local damage_count = player:getMark("@zuilun_damage_count")  
        room:setPlayerMark(player,"@zuilun_damage_count",0)
        if damage_count > 1 then  
            x = x + 1  
        end  
          
        -- 条件3：你已失去的体力数>1  
        local lost_hp = player:getMaxHp() - player:getHp()  
        if lost_hp > 1 then  
            x = x + 1  
        end  
          
        if x > 0 then  
            -- 摸X张牌  
            room:drawCards(player, x, self:objectName())  
        else  
            -- X=0时，选择一名其他角色，你与其各失去一点体力  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                targets:append(p)  
            end  
              
            if not targets:isEmpty() then  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zuilun-choose")  
                room:loseHp(player, 1)  
                room:loseHp(target, 1)  
            end  
        end  
          
        return false  
    end  
}  
  
-- 记录伤害数的辅助技能  
zuilun_record = sgs.CreateTriggerSkill{  
    name = "#zuilun-record",  
    events = {sgs.Damage},  
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.from and damage.from:isAlive() and damage.from:hasSkill("zuilun") then  
            local from = damage.from  
        	local current_count = from:getMark("@zuilun_damage_count")  
        	room:setPlayerMark(from, "@zuilun_damage_count", current_count + damage.damage)
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        return false  
    end  
}  
  
-- 技能2：父荫  
fuyin = sgs.CreateTriggerSkill{  
    name = "fuyin",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.TargetConfirming},  
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        local use = data:toCardUse()
        if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to:contains(owner) then  
            if not owner:hasFlag("fuyin_used") then
                -- 标记本回合已使用
                room:setPlayerFlag(owner, "fuyin_used")  
                return self:objectName(), owner:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(),data) -- 锁定技，无需询问  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        if use.from and use.from:getHandcardNum() > ask_who:getHandcardNum() then  
            -- 取消目标  
            local new_targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(use.to) do  
                if p:objectName() ~= ask_who:objectName() then  
                    new_targets:append(p)  
                end  
            end  
            use.to = new_targets  
            data:setValue(use)
        end  
        return false  
    end  
}  
  
-- 添加技能到武将  
zhugezhan:addSkill(zuilun)  
zhugezhan:addSkill(zuilun_record)  
zhugezhan:addSkill(fuyin)  

sgs.LoadTranslationTable{
["zhugezhan"] = "诸葛瞻",  
["#zhugezhan"] = "蜀汉忠臣",  
["zuilun"] = "罪论",  
[":zuilun"] = "锁定技，结束阶段，你观看牌堆顶3张牌并以任意顺序放回牌堆顶，然后你摸X张牌，X为满足以下条件的数量：①与你势力相同的其他角色数>1；②本回合你造成的伤害数>1；③你已失去的体力数>1。若X=0，你选择一名其他角色，你与其各失去一点体力。",  
["fuyin"] = "父荫",  
[":fuyin"] = "锁定技，你每回合首次成为【杀】或【决斗】的目标后，若使用者的手牌数大于你，取消之。",  
["@zuilun-choose"] = "罪论：选择一名其他角色，你与其各失去一点体力",
}

zhuhuan_guoji = sgs.General(extension, "zhuhuan_guoji", "wu", 4)
fenli = sgs.CreateTriggerSkill{  
    name = "fenli",  
    events = {sgs.EventPhaseChanging},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            local change = data:toPhaseChange()  
            if change.to == sgs.Player_Draw then
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getHandcardNum() > player:getHandcardNum() then
                        return ""
                    end
                end
                return self:objectName()
            elseif change.to == sgs.Player_Play then
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getHp() > player:getHp() then
                        return ""
                    end
                end
                return self:objectName()
            elseif change.to == sgs.Player_Discard then
                if player:getEquips():length() > 0 then
                    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getEquips():length() > player:getEquips():length() then
                            return ""
                        end
                    end
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
        local change = data:toPhaseChange()  
        if change.to == sgs.Player_Draw then
            player:skip(sgs.Player_Draw)
        elseif change.to == sgs.Player_Play then
            player:skip(sgs.Player_Play)
        elseif change.to == sgs.Player_Discard then
            player:skip(sgs.Player_Discard)
        end
        return false  
    end  
}
pingkou = sgs.CreateTriggerSkill{  
    name = "pingkou",  
    events = {sgs.EventPhaseSkipping, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseSkipping then
            room:addPlayerMark(player,"@pingkou_skip")
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:getMark("@pingkou_skip") > 0 then
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
        local num = player:getMark("@pingkou_skip")
        room:setPlayerMark(player,"@pingkou_skip",0)
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  not player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end
        local chosen_players = room:askForPlayersChosen(player,  targets, self:objectName(), num, num, "请选择玩家", false)
        for _, target in sgs.qlist(chosen_players) do
            local damage = sgs.DamageStruct()
            damage.from = player
            damage.to = target
            damage.damage = 1
            damage.reason = self:objectName()
            room:damage(damage)
        end
        return false  
    end  
}
zhuhuan_guoji:addSkill(fenli)
zhuhuan_guoji:addSkill(pingkou)
sgs.LoadTranslationTable{
    ["zhuhuan_guoji"] = "朱桓",
    ["fenli"] = "奋励",
    [":fenli"] = "摸牌阶段开始时，若你的手牌数全场最多，你可以跳过摸牌阶段；出牌阶段开始时，若你的体力值全场最多，你可以跳过出牌阶段；弃牌阶段开始时，若你的装备区有牌且全场最多，你可以跳过弃牌阶段",
    ["pingkou"] = "平寇",
    [":pingkou"] = "回合结束时，你可以对至多X名其他势力角色各造成1点伤害，X为你本回合跳过的阶段数"
}


zhuran = sgs.General(extension, "zhuran", "wu", 4) 
danshouTarget = sgs.CreateTriggerSkill{  
    name = "danshouTarget",  
    events = {sgs.TargetConfirming, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        local current = room:getCurrent()
        if current == owner then return "" end
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.from == current and use.to:contains(owner) then  
                room:addPlayerMark(owner,"@danshou_target")                
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            return self:objectName(), owner:objectName()
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local num = ask_who:getMark("@danshou_target")
        room:setPlayerMark(ask_who,"@danshou_target",0)
        if num == 0 then
            ask_who:drawCards(1,self:objectName())
        elseif ask_who:getCardCount(true) > num and room:askForDiscard(ask_who,self:objectName(),num,num,true,true) then
            local damage = sgs.DamageStruct()
            damage.from = ask_who
            damage.to = room:getCurrent()
            damage.damage = 1
            damage.reason = self:objectName()
            room:damage(damage)
        end
        return false  
    end  
}
zhuran:addSkill(danshouTarget)
sgs.LoadTranslationTable{
    ["danshouTarget"] = "胆守",
    [":danshouTarget"] = "其他角色的结束阶段，若你本回合未成为过其使用牌的目标，你摸一张牌；否则你可以弃置X张牌，对其造成1点伤害，X为你本回合成为其使用牌目标的次数"
}
return {extension}