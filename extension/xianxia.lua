extension = sgs.Package("xianxia", sgs.Package_GeneralPack)

caozhi_xianxia = sgs.General(extension, "caozhi_xianxia", "wei", 3) -- 蜀势力，4血，男性（默认）  

linlang = sgs.CreateTriggerSkill{  
    name = "linlang",  
    events = {sgs.FinishJudge},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        local caozhi_xianxia = room:findPlayerBySkillName(self:objectName())  
          
        if caozhi_xianxia and caozhi_xianxia:isAlive() and judge.card:isKindOf("TrickCard") then  
            --if room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then  
                return self:objectName(), caozhi_xianxia:objectName()
            --end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local caozhi_xianxia = room:findPlayerBySkillName(self:objectName())  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local caozhi_xianxia = ask_who--room:findPlayerBySkillName(self:objectName())  
        local judge = data:toJudge()  
        
        local choice = room:askForChoice(caozhi_xianxia, "linlang", "obtain+move+cancel")  
        if choice == "obtain" then
            -- 获得判定牌  
            caozhi_xianxia:obtainCard(judge.card)  
        elseif choice == "move" then
            -- 移动场上一张与此牌颜色相同的牌  
            local targets = sgs.SPlayerList()
            -- 查找场上所有与判定牌颜色相同的牌  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                for i = 0, 4 do  
                    local equip = p:getEquip(i)  
                    if equip and (equip:isRed()==judge.card:isRed()) then  
                        targets:append(p)
                        break
                    end  
                end  
                
                -- 检查判定区的牌  
                for _, card in sgs.qlist(p:getJudgingArea()) do  
                    if (card:isRed()==judge.card:isRed()) then  
                        targets:append(p)
                        break
                    end  
                end  
            end  
            if targets:isEmpty() then return false end
            local from_player = room:askForPlayerChosen(caozhi_xianxia, targets, self:objectName(), "@linlang-move-from")  
            if not from_player then return false end
            local to_player = room:askForPlayerChosen(caozhi_xianxia, room:getAlivePlayers(), self:objectName(), "@linlang-move-to")  
            if from_player and to_player then
                local card_id = room:askForCardChosen(caozhi_xianxia,from_player,"ej",self:objectName())
                local card = sgs.Sanguosha:getCard(card_id)
                if card:isKindOf("EquipCard") then
                    -- 移动装备牌  
                    room:moveCardTo(card, to_player, sgs.Player_PlaceEquip)  
                else  
                    -- 移动判定区的牌  
                    room:moveCardTo(card, to_player, sgs.Player_PlaceDelayedTrick)  
                end  
            end
        end
        return false  
    end,  
}

luoyingTurn = sgs.CreateTriggerSkill{  
    name = "luoyingTurn",  
    events = {sgs.Damaged, sgs.TurnedOver},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  return "" end
        if event == sgs.Damaged then
            return self:objectName()  
        elseif event == sgs.TurnedOver and  player:faceUp() then
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
        if event == sgs.Damaged then  
            local lost_hp = player:getLostHp()  
            if lost_hp > 0 then  
                -- 摸X张牌  
                player:drawCards(lost_hp, self:objectName())  
                
                -- 叠置  
                player:turnOver()  
            end  
        elseif event == sgs.TurnedOver then
            local judge = sgs.JudgeStruct()  
            judge.pattern = ".|club"  
            judge.good = true  
            judge.reason = "luoyingTurn"  
            judge.who = player  
            
            room:judge(judge)  
            
            -- 若判定牌为梅花，获得一个出牌阶段  
            if judge.card:getSuit() == sgs.Card_Club then  
                local phases = sgs.PhaseList()
                phases:append(sgs.Player_Play)
                phases:append(sgs.Player_NotActive)
                player:play(phases)  
                room:broadcastProperty(player, "phase")  
            end  
        end
        return false  
    end,  
}  

-- 关联技能  
caozhi_xianxia:addSkill(linlang)  
caozhi_xianxia:addSkill(luoyingTurn)

sgs.LoadTranslationTable{
["#caozhi_xianxia"] = "八斗之才",  
["caozhi_xianxia"] = "曹植",   
["illustrator:caozhi_xianxia"] = "插画师名称",  
["linlang"] = "琳琅",  
[":linlang"] = "当一名角色的判定牌生效后，若判定牌为锦囊牌，你可以选择（1）获得该判定牌（2）移动场上一张与此牌颜色相同的牌。",  
["luoyingTurn"] = "落英",  
[":luoyingTurn"] = "当你受到伤害后，你可以摸X张牌并叠置，X为你已失去的体力值。当你从叠置状态恢复时，你可以进行一次判定，若判定牌为梅花，你立即获得一个出牌阶段。",
}

cuifei = sgs.General(extension, "cuifei", "wei", 3, false) -- 蜀势力，4血，男性（默认）  

yiyong = sgs.CreateTriggerSkill{
	name = "yiyong",
	events = {sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local use = data:toCardUse()
			if use.card:isKindOf("EquipCard") and use.from == player then
				return self:objectName()
			end
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
        player:drawCards(1, self:objectName())
		return false
	end
}

yashang = sgs.CreateMasochismSkill{  
    name = "yashang",  
    frequency = sgs.Skill_Compulsory,  
      
    on_damaged = function(self, player, damage)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return false end
        local room = player:getRoom()  
        local source = damage.from  
          
        if not source or not source:isAlive() then return false end  
          
        -- 计算空置装备栏数X  
        local empty_slots = 0  
        for i = 0, 4 do  
            if not player:getEquip(i) then  
                empty_slots = empty_slots + 1  
            end  
        end  
          
        local x = empty_slots  
          
        room:sendCompulsoryTriggerLog(player, self:objectName())  
          
        -- 判断势力关系  
        local same_kingdom = player:isFriendWith(source)  
          
        if not same_kingdom then  
            -- 伤害来源与你势力不同  
            local source_handcard_num = source:getHandcardNum()  
            if source_handcard_num > x then  
                -- 伤害来源须将手牌弃至X张  
                local discard_num = source_handcard_num - x  
                local discarded = room:askForDiscard(source, self:objectName(), discard_num, discard_num, false, false, "@yashang-discard:" .. player:objectName() .. "::" .. tostring(x))  
            else
                -- 若其未弃牌，你将手牌摸至X张  
                local player_handcard_num = player:getHandcardNum()  
                if player_handcard_num < x then  
                    player:drawCards(x - player_handcard_num, self:objectName())  
                end  
            end  
        else  
            -- 伤害来源与你势力相同  
            local player_handcard_num = player:getHandcardNum()  
            if player_handcard_num > x then  
                -- 你须将手牌弃至X张  
                local discard_num = player_handcard_num - x  
                local discarded = room:askForDiscard(player, self:objectName(), discard_num, discard_num, false, false, "@yashang-self-discard::" .. tostring(x))  
            else  
                -- 若你未弃牌，伤害来源将手牌摸至X张  
                local source_handcard_num = source:getHandcardNum()  
                if source_handcard_num < x then  
                    source:drawCards(x - source_handcard_num, self:objectName())  
                end  
            end  
        end  
    end,  
}
cuifei:addSkill(yiyong)
cuifei:addSkill(yashang)
sgs.LoadTranslationTable{
["#cuifei"] = "魏宫贵妃",  
["cuifei"] = "崔妃",   
["yiyong"] = "衣镛",  
[":yiyong"] = "当你使用装备牌后，你可以摸1张牌。",  
["yashang"] = "雅殇",  
[":yashang"] = "锁定技，当你受到伤害后，若伤害来源与你势力不同，其须将手牌弃至X张，若其未弃牌，你将手牌摸至X张；若伤害来源与你势力相同，你须将手牌弃至X张，若你未弃牌，伤害来源将手牌摸至X张。X为你空置装备栏数。",
}
dongbai = sgs.General(extension, "dongbai", "qun", 3, false)  

lianzhu = sgs.CreateViewAsSkill{  
    name = "lianzhu",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0 --and not to_select:isEquipped()  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = LianzhuCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())  
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#LianzhuCard")  
    end  
}  
  
-- 连诛卡牌类  
LianzhuCard = sgs.CreateSkillCard{  
    name = "LianzhuCard",  
    target_fixed = false,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local card_id = self:getSubcards():first()  
        local card = sgs.Sanguosha:getCard(card_id)  
          
        -- 展示并交给目标角色  
        room:showCard(source, card_id)  
        room:obtainCard(target, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "lianzhu", ""))  
          
        -- 若该牌为黑色  
        if card:isBlack() then  
            local choices = {"lianzhu_draw", "lianzhu_discard"}  
            local choice = room:askForChoice(target, "lianzhu", table.concat(choices, "+"))  
              
            if choice == "lianzhu_draw" then  
                -- 你摸2张牌  
                room:drawCards(source, 2, "lianzhu")  
            else  
                -- 其弃置2张牌  
                room:askForDiscard(target, "lianzhu", 2, 2, false, true)  
            end  
        end  
    end  
}  
  
-- 技能2：黠慧  
xiahui = sgs.CreateMaxCardsSkill{  
    name = "xiahui",  
    frequency = sgs.Skill_Compulsory,  
    extra_func = function(self, target)  
        if target:hasSkill(self:objectName()) then  
            local black_count = 0  
            local cards = target:getHandcards()  
            for _, card in sgs.qlist(cards) do  
                if card:isBlack() then  
                    black_count = black_count + 1  
                end  
            end  
            return black_count  
        end  
        return 0  
    end  
}  
  
-- 添加技能到武将  
dongbai:addSkill(lianzhu)  
dongbai:addSkill(xiahui)
sgs.LoadTranslationTable{
["dongbai"] = "董白",  
["#dongbai"] = "魔女",  
["lianzhu"] = "连诛",  
[":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择：1.你摸两张牌；2.其弃置两张牌。",  
["xiahui"] = "黠慧",  
[":xiahui"] = "锁定技，你的黑色牌不计入手牌上限。",  
["LianzhuCard"] = "连诛",  
["lianzhu_draw"] = "令其摸两张牌",  
["lianzhu_discard"] = "弃置两张牌",  
["@lianzhu-card"] = "连诛：选择要交给目标角色的牌"
}
guanning = sgs.General(extension, "guanning", "qun", 3)  

qinggong = sgs.CreateTriggerSkill{  
    name = "qinggong",  
    events = {sgs.EventPhaseChanging},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
		local change = data:toPhaseChange()
        if player and player:hasSkill(self:objectName()) and change.to == sgs.Player_Discard then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local targets = {}  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            table.insert(targets, p:objectName())  
        end  
          
        if #targets == 0 then return false end  
          
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player),   
            self:objectName(), "@qinggong-discard", true, true)  
          
        if not target then return false end  
          
        -- 令目标角色弃置自己两张牌  
		if target:canDiscard(player, "he") then
			room:throwCard(room:askForCardChosen(target, player, "he", self:objectName(), false, sgs.Card_MethodDiscard), player, target)
		end
		if target:canDiscard(player, "he") then
			room:throwCard(room:askForCardChosen(target, player, "he", self:objectName(), false, sgs.Card_MethodDiscard), player, target)
		end  
          
        -- 跳过弃牌阶段  
        player:skip(sgs.Player_Discard)  
          
        -- 可以令一名角色明置一张武将牌  
        local all_players = room:getAlivePlayers()  
        local can_show = sgs.SPlayerList() 
        for _, p in sgs.qlist(all_players) do  
            if not p:hasShownAllGenerals() then  
                can_show:append(p)
            end  
        end  
          
        if not can_show:isEmpty() then  
            local show_target = room:askForPlayerChosen(player, can_show,   
                self:objectName(), "@qinggong-show", true, true)  
            if show_target then  
                local choices = {}  
                if not show_target:hasShownGeneral1() then  
                    table.insert(choices, "head_general")  
                end  
                if not show_target:hasShownGeneral2() then  
                    table.insert(choices, "deputy_general")  
                end  
                  
                if #choices > 0 then  
                    local choice = room:askForChoice(show_target, self:objectName(), table.concat(choices, "+"))  
                    if choice == "head_general" then  
                        show_target:showGeneral(true)  
                    else  
                        show_target:showGeneral(false)  
                    end  
                end  
            end  
        end  
          
        return false  
    end  
}  
  
-- 尚雅技能实现  
shangya = sgs.CreateTriggerSkill{  
    name = "shangya",  
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        if event == sgs.EventPhaseStart then  
            if player:getPhase() == sgs.Player_Start and player:hasShownAllGenerals() then  
                -- 检查是否有其他角色有暗置武将牌  
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                    if not p:hasShownAllGenerals() and not p:isKongcheng() then  
                        return self:objectName()  
                    end  
                end  
            end  
        end  

        if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from_places:contains(sgs.Player_PlaceHand) then
							if move.from and move.from:isAlive() and move.from:objectName()==player:objectName() then
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
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            -- 弃置每名有暗置武将牌的角色各1张手牌  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if not p:hasShownAllGenerals() and not p:isKongcheng() then  
                    local card_id = room:askForCardChosen(player, p, "h", self:objectName())  
                    room:throwCard(card_id, p, player)  
                end  
            end  
        end  
        if event == sgs.CardsMoveOneTime then  
            local all_shown = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAllPlayers()) do  
                if p:hasShownAllGenerals() then  
                    all_shown:append(p)
                end  
            end  
              
            if all_shown:isEmpty() then return false end
            target = room:askForPlayerChosen(player, all_shown,   
                    self:objectName(), "@shangya-draw", true, true)  
              
            if target then  
                -- 目标摸2张牌  
                target:drawCards(2)  
                  
                -- 暗置其一张武将牌  
                local choices = {}  
                if target:hasShownGeneral1() then  
                    table.insert(choices, "head_general")  
                end  
                if target:hasShownGeneral2() then  
                    table.insert(choices, "deputy_general")  
                end  
                  
                if #choices > 0 then  
                    local choice = room:askForChoice(player, self:objectName() .. "_hide",   
                        table.concat(choices, "+"))  
                    if choice == "head_general" then  
                        target:hideGeneral(true)  
                    else  
                        target:hideGeneral(false)  
                    end  
                end  
            end  
        end
        return false  
    end  
}  
  
guanning:addSkill(qinggong)  
guanning:addSkill(shangya)
sgs.LoadTranslationTable{
    ["#guanning"] = "高洁的隐士",  
    ["guanning"] = "管宁",  
    ["qinggong"] = "清躬",  
    [":qinggong"] = "弃牌阶段开始时，你可以令一名其他角色弃置你两张牌，你跳过弃牌阶段，然后你可以令一名角色明置一张武将牌。",  
    ["shangya"] = "尚雅",  
    [":shangya"] = "准备阶段，若你没有暗置的武将牌，你可以弃置每名有暗置武将牌的角色各1张手牌；当你因弃置而失去手牌后，你可以令一名武将牌均明置的角色摸2张牌，然后暗置其1张武将",  
    ["@qinggong-discard"] = "你可以发动'清躬'，令一名其他角色弃置你两张牌",  
    ["@qinggong-show"] = "你可以令一名角色明置一张武将牌",  
    ["@shangya-draw"] = "你可以发动'尚雅'，令一名武将牌均明置的角色摸2张牌",  
    ["@shangya-discard"] = "你可以发动'尚雅'，弃置有暗置武将牌的角色各1张手牌",  
    ["~qinggong"] = "选择一名其他角色→点击确定",  
    ["~shangya"] = "选择一名武将牌均明置的角色→点击确定",
}

guansuo_xianxia = sgs.General(extension, "guansuo_xianxia", "shu", 4) -- 蜀势力，4血，男性（默认）  
guansuo_xianxia:setDeputyMaxHpAdjustedValue(-1)

zhengfeng = sgs.CreateTriggerSkill{  
    name = "zhengfeng",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Start then  
            return ""  
        end  
          
        -- 查找拥有征锋技能的同势力角色  
        local guansuo_xianxia = nil  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:hasSkill(self:objectName()) and p:isFriendWith(player) then  
                guansuo_xianxia = p  
                break  
            end  
        end  
          
        if guansuo_xianxia and guansuo_xianxia:isAlive() then  
            return self:objectName(), guansuo_xianxia:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)       
        if ask_who and room:askForUseCard(ask_who, "slash", "", -1, sgs.Card_MethodUse, false) then
            return true
        end
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)            
        return false  
    end,  
}

lvjin = sgs.CreateTriggerSkill{  
    name = "lvjin",  
    relate_to_place = "head", -- 主将技  
    events = {sgs.Damage},  
    --frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("Slash") and not player:hasFlag("lvjin_used") then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@lvjin-give", true)  
        local card = damage.card
          
        if target and target:isAlive() and card then  
            -- 将杀交给目标角色  
            target:obtainCard(card)  
              
            -- 如果目标是女性角色，其摸1张牌  
            if target:hasShownOneGeneral() and target:isFemale() then  
                target:drawCards(1, self:objectName())  
            end  
              
            -- 标记本回合已使用  
            room:setPlayerFlag(player,"lvjin_used")
        end  
          
        return false  
    end,  
}

muyang = sgs.CreateTriggerSkill{  
    name = "muyang",  
    relate_to_place = "deputy", -- 副将技  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then  
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
        -- 亮出牌堆顶2张牌  
        for i=1,2 do  
            -- 从牌堆顶获得一张牌  
            local card_id = room:drawCard()  
            if not card_id then break end  -- 牌堆空了  
            
            local card = sgs.Sanguosha:getCard(card_id)  
            if card:isRed() or card:isKindOf("Slash") then  
                room:obtainCard(player, card_id)
            --else  
            --    room:throwCard(card_id, nil, player) 
            end  
        end  
        return false  
    end,  
}
guansuo_xianxia:addSkill(zhengfeng)  
guansuo_xianxia:addSkill(lvjin)  
guansuo_xianxia:addSkill(muyang)
sgs.LoadTranslationTable{
["#guansuo_xianxia"] = "蜀汉虎将",  
["guansuo_xianxia"] = "关索",   
["illustrator:guansuo_xianxia"] = "插画师名称",  
["zhengfeng"] = "征锋",  
[":zhengfeng"] = "与你势力相同的角色准备阶段，你可以使用一张杀。",  
["lvjin"] = "旅进",  
[":lvjin"] = "主将技，每回合限一次，当你使用杀造成伤害后，你可将该杀交给一名其他角色，若其为女性角色，其摸1张牌。",  
["muyang"] = "募养",  
[":muyang"] = "副将技，-1阴阳鱼。你的结束阶段开始时，你可以亮出牌堆顶2张牌，获得其中的红色牌和杀。",
}

liuchen = sgs.General(extension, "liuchen", "shu", 4) -- 蜀势力，4血，男性（默认）  

zhanjueDuelCard = sgs.CreateSkillCard{  
    name = "zhanjueDuelCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        local duel = sgs.Sanguosha:cloneCard("duel")  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not sgs.Self:isProhibited(to_select, duel)  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 创建决斗牌  
        local duel = sgs.Sanguosha:cloneCard("duel")  
        duel:setSkillName("zhanjueDuel")  
          
        -- 使用决斗  
        if not source:isCardLimited(duel, sgs.Card_MethodUse) and not source:isProhibited(target, duel) then  
            local use = sgs.CardUseStruct(duel, source, target)  
            room:useCard(use)
            --不论谁受到伤害，自己先摸1张
            room:drawCards(source, 1, self:objectName())  
            -- 决斗结算完成后的效果  
            -- 检查谁受到了伤害  
            local source_damaged = source:getTag("zhanjueDuel_damaged"):toBool()  
            local target_damaged = target:getTag("zhanjueDuel_damaged"):toBool()  
                
            -- 清除标记  
            source:removeTag("zhanjueDuel_damaged")  
            target:removeTag("zhanjueDuel_damaged")  
                
            -- 摸牌逻辑  
            if source_damaged and source:isAlive() then  --自己受伤
                room:drawCards(source, 1, self:objectName())
            else --自己没受伤，技能使用次数变为2次  
                room:setPlayerFlag(source, "zhanjueDuel_extra")
            end  
            if target_damaged and target:isAlive() then  
                room:drawCards(target, 1, self:objectName()) 
            end  
        end  
    end  
}  
  
-- 战绝技能  
zhanjueDuelVS = sgs.CreateViewAsSkill{  
    name = "zhanjueDuel",  
    n = 999, -- 可以选择所有手牌  
    view_filter = function(self, selected, to_select)  
        if to_select:isEquipped() then  
            return false  
        end  
          
        -- 如果已选择的牌数等于手牌数-1，则必须选择剩余的手牌  
        local handcard_num = sgs.Self:getHandcardNum()  
        return #selected < handcard_num  
    end,  
    view_as = function(self, cards)  
        if #cards ~= sgs.Self:getHandcardNum() then   
            return nil   
        end  
        local zhanjueDuel_card = zhanjueDuelCard:clone()
        for _, card in ipairs(cards) do  
            zhanjueDuel_card:addSubcard(card)  
        end  
        zhanjueDuel_card:setShowSkill(self:objectName())  
        return zhanjueDuel_card  
    end,  
    enabled_at_play = function(self, player)  
        local used_times = player:usedTimes("ViewAsSkill_zhanjueDuelCard")
        local max_times = player:hasFlag("zhanjueDuel_extra") and 2 or 1  
        return used_times < max_times and not player:isKongcheng()  
    end,  
}

zhanjueDuel = sgs.CreateTriggerSkill{  
    name = "zhanjueDuel",  
    events = {sgs.Damaged},  
    view_as_skill = zhanjueDuelVS,
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.card and damage.card:getSkillName() == "zhanjueDuel" then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        local damage = data:toDamage()  
        if event == sgs.Damaged then  
            --可能减伤，导致没有这个事件，没有受到伤害的角色，另一方就不摸牌
            -- 标记造成伤害的角色  
            damage.from:setTag("zhanjueDuel_damaged", sgs.QVariant(false))  
            -- 标记受到伤害的角色  
            damage.to:setTag("zhanjueDuel_damaged", sgs.QVariant(true))  
        end  
        return false  
    end,  
}  

liuchen:addSkill(zhanjueDuel)

sgs.LoadTranslationTable{
["#liuchen"] = "蜀汉忠烈",  
["liuchen"] = "刘谌",   
["illustrator:liuchen"] = "插画师名称",  
["zhanjueDuel"] = "战绝",  
[":zhanjueDuel"] = "出牌阶段限一次，你可以将所有手牌当决斗使用，该决斗结算完成后，你和受到此决斗伤害的角色各摸一张牌；若你未受到此决斗伤害，该技能出牌阶段限2次。",
}
--[[
sunlin = sgs.General(extension, "sunlin", "wu", 4) -- 蜀势力，4血，男性（默认）  
  
-- 专行主技能  
zhuanxing = sgs.CreateTriggerSkill{  
    name = "zhuanxing",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Start then  
            return ""  
        end  
          
        -- 查找拥有专行技能的同势力角色  
        local sunlin = nil  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:hasSkill(self:objectName()) and p:isFriendWith(player) then  
                sunlin = p  
                break  
            end  
        end  
          
        if sunlin and sunlin:isAlive() and not sunlin:isKongcheng() then  
            return self:objectName(), sunlin:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local sunlin = ask_who

        local choices = {}  
            
        -- 检查是否有杀可以使用  
        local has_slash = false  
        for _, card in sgs.qlist(sunlin:getHandcards()) do  
            if card:isKindOf("Slash") then  
                has_slash = true  
                break  
            end  
        end  
        if has_slash then  
            table.insert(choices, "use_slash")  
        end  
            
        -- 检查是否有黑色非锦囊牌  
        local has_black_non_trick = false  
        for _, card in sgs.qlist(sunlin:getHandcards()) do  
            if card:isBlack() and not card:isKindOf("TrickCard") then  
                has_black_non_trick = true  
                break  
            end  
        end  
        for _, card in sgs.qlist(sunlin:getEquips()) do  
            if card:isBlack() and not card:isKindOf("TrickCard") then  
                has_black_non_trick = true  
                break  
            end  
        end  
        if has_black_non_trick then  
            table.insert(choices, "supply")  
        end  
            
        table.insert(choices, "cancel")  
        local choice = room:askForChoice(sunlin, self:objectName(), table.concat(choices, "+"))  
        if choice == "use_slash" then  
            if room:askForUseSlashTo(player, sunlin, "", false, false, false) then  
                -- 然后对一名角色造成1点伤害  
                local damage_target = room:askForPlayerChosen(sunlin, room:getAlivePlayers(), "zhuanxing", "@zhuanxing-damage")  
                if damage_target then  
                    room:damage(sgs.DamageStruct("zhuanxing", sunlin, damage_target, 1, sgs.DamageStruct_Normal))  
                end  
            end
   
        elseif choice == "supply" then  
            -- 选择黑色非锦囊牌  
            local black_cards = {}  
            for _, card in sgs.qlist(sunlin:getHandcards()) do  
                if card:isBlack() and not card:isKindOf("TrickCard") then  
                    table.insert(black_cards, card:getEffectiveId())  
                end  
            end  
            for _, card in sgs.qlist(sunlin:getEquips()) do  
                if card:isBlack() and not card:isKindOf("TrickCard") then  
                    table.insert(black_cards, card:getEffectiveId())  
                end  
            end              
            if #black_cards > 0 then  
                local chosen_card = room:askForCard(sunlin, "^TrickCard|black", "@zhuanxing-supply", data)
                if chosen_card then
                    --实在不行，手动实现一个兵粮寸断的判定：不为梅花跳过摸牌阶段
                    local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage")  
                    supply_shortage:addSubcard(chosen_card:getEffectiveId())  
                    supply_shortage:setSkillName("zhuanxing")  
                    -- 移动到目标判定区  
                    room:moveCardTo(supply_shortage, player, sgs.Player_PlaceDelayedTrick)  
                    -- 目标摸3张牌  
                    player:drawCards(3, "zhuanxing") 

                    local judge = sgs.JudgeStruct()  
                    judge.pattern = ".|club"  
                    judge.good = true  
                    judge.reason = self:objectName()  
                    judge.who = player  
                    
                    room:judge(judge)  
                    if judge.card:getSuit() ~= sgs.Card_Club then
                        player:skip(sgs.Player_Draw)
                    end
                end
            end  
        end  
          
        return false  
    end,  
}



baoshi = sgs.CreateTriggerSkill{  
    name = "baoshi",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.Death},  
    can_trigger = function(self, event, room, player, data)  
        local death = data:toDeath()  
        local killer = death.damage and death.damage.from or nil  
          
        if killer and killer:isAlive() and killer:hasSkill(self:objectName()) then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local death = data:toDeath()  
        local killer = death.damage.from  
        room:sendCompulsoryTriggerLog(killer, self:objectName())  
        room:broadcastSkillInvoke(self:objectName(), killer)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local death = data:toDeath()  
        local killer = death.damage.from  
          
        -- 标记已击杀过角色  
        killer:setMark("@baoshi_killed", 1)  
          
        return false  
    end,  
}  
  
-- 暴施修正技能  
baoshiMode = sgs.CreateTargetModSkill{  
    name = "#baoshi-mode",  
    pattern = "Slash",  
    distance_limit_func = function(self, player, card)  
        if player:hasSkill("baoshi") and player:getMark("@baoshi_killed") > 0 then  
            return 1000 -- 无距离限制  
        end  
        return 0  
    end,  
    extra_target_func = function(self, player, card)  
        if player:hasSkill("baoshi") and player:getMark("@baoshi_killed") > 0 then  
            return 1000 -- 无目标数限制  
        end  
        return 0  
    end,  
}  
  
-- 关联技能  
sgs.insertRelatedSkills(extension, "baoshi", "#baoshi-mode")  

sunlin:addSkill(zhuanxing)  
sunlin:addSkill(baoshi)
sunlin:addSkill(baoshiMode)
sgs.LoadTranslationTable{
["#sunlin"] = "吴国权臣",  
["sunlin"] = "孙琳",   
["illustrator:sunlin"] = "插画师名称",  
["zhuanxing"] = "专行",  
[":zhuanxing"] = "与你势力相同的角色的准备阶段，你可以选择（1）对其使用1张杀，然后对一名角色造成1点伤害（2）将一张黑色非锦囊牌当【兵粮寸断】移动到其判定区，然后其摸3张牌。",  
["baoshi"] = "暴施",  
[":baoshi"] = "锁定技，你击杀过角色后，你使用杀无距离、目标数限制。",
}
]]
wangyun = sgs.General(extension, "wangyun", "qun", 3) -- 蜀势力，4血，男性（默认）  


ShelunCard = sgs.CreateSkillCard{  
    name = "ShelunCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        if #targets > 0 then return false end  
        if to_select:objectName() == sgs.Self:objectName() then return false end  
        if to_select:isAllNude() then return false end
        -- 检查攻击范围  
        return sgs.Self:inMyAttackRange(to_select)  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 找出所有手牌数小于等于source的角色（除了target）  
        local participants = {}  
        table.insert(participants, source) -- 王允自己参与  
          
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:objectName() ~= source:objectName() and p:objectName() ~= target:objectName() then  
                if not p:isKongcheng() and p:getHandcardNum() <= source:getHandcardNum() then  
                    table.insert(participants, p)  
                end  
            end  
        end  
          
        -- 所有参与者展示一张手牌  
        local shown_cards = {}  
        local red_count = 0  
        local black_count = 0  
          
        for _, p in ipairs(participants) do  
            if not p:isKongcheng() then  
                local card = room:askForCardShow(p, source, "shelun")  
                if card then  
                    shown_cards[p:objectName()] = card
                    --room:showCard(p, card_id)  
                    if card:isRed() then  
                        red_count = red_count + 1  
                    else  
                        black_count = black_count + 1  
                    end  
                end  
            end  
        end  
        for player_name,card in pairs(shown_cards) do
            room:showCard(room:findPlayer(player_name), card:getEffectiveId()) 
        end
        -- 根据颜色统计结果执行效果  
        if red_count > black_count then  
            -- 红色牌更多，弃置目标1张牌  
            if not target:isAllNude() then  
                local card_id = room:askForCardChosen(source, target, "hej", "shelun", false, sgs.Card_MethodDiscard)  
                room:throwCard(card_id, target, source)  
            end  
        elseif black_count > red_count then  
            -- 黑色牌更多，对目标造成1点伤害  
            room:damage(sgs.DamageStruct("shelun", source, target, 1, sgs.DamageStruct_Normal))  
        end  
          
        -- 对展示颜色和王允不同的角色造成1点伤害  
        local source_card = shown_cards[source:objectName()]
        if source_card then  
            local different_color_players = sgs.SPlayerList()  
              
            for player_name, card in pairs(shown_cards) do  
                if player_name ~= source:objectName() then  
                    local p = room:findPlayer(player_name)  
                    if p and p:isAlive() then  
                        local source_is_red = source_card:isRed()  
                        local card_is_red = card:isRed()  
                          
                        if source_is_red ~= card_is_red then  
                            -- 颜色不同的角色  
                            different_color_players:append(p)  
                        end  
                    end  
                end  
            end   
            chosen_player = room:askForPlayerChosen(source, different_color_players, "shelun", "@shelun-damage")                    
            if chosen_player and source:askForSkillInvoke("@shelun-damage", sgs.QVariant()) then  
                room:damage(sgs.DamageStruct("shelun", source, chosen_player, 1, sgs.DamageStruct_Normal))  
            end  
        end  

        --[[
        if source_card then  
            for player_name, card in pairs(shown_cards) do  
                if player_name ~= source:objectName() then  
                    local p = room:findPlayer(player_name)  
                    if p and p:isAlive() then  
                        local source_is_red = source_card:isRed()  
                        local card_is_red = card:isRed()  
                          
                        if source_is_red ~= card_is_red then  
                            -- 颜色不同，造成伤害  
                            if source:askForSkillInvoke("shelun", sgs.QVariant()) then  
                                room:damage(sgs.DamageStruct("shelun", source, p, 1, sgs.DamageStruct_Normal))  
                            end  
                        end  
                    end  
                end  
            end  
        end  
        ]]
    end  
}  
  
-- 赦论技能  
shelun = sgs.CreateZeroCardViewAsSkill{  
    name = "shelun",  
    view_as = function(self, cards)  
        card = ShelunCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#ShelunCard") and not player:isKongcheng()
    end,  
}

wangyun:addSkill(shelun)
sgs.LoadTranslationTable{
["#wangyun"] = "忠义之士",  
["wangyun"] = "王允",   
["illustrator:wangyun"] = "插画师名称",  
["shelun"] = "赦论",  
[":shelun"] = "出牌阶段限一次，你可以选择一名你攻击范围内的其他角色，然后你和除其之外所有手牌数小于等于你的角色同时展示一张手牌。若展示的红色牌数更多，你弃置其1张牌；若展示的黑色牌数更多，你对其造成1点伤害；你可以选择一名展示颜色和你不同的角色，对其造成1点伤害。",
}

yangqiu = sgs.General(extension, "yangqiu", "qun", 4) -- 蜀势力，4血，男性（默认）  

SaojianCard = sgs.CreateSkillCard{  
    name = "SaojianCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        --[[
        -- 观看目标手牌并选择一张  
        local handcards = target:handCards()  
        if handcards:isEmpty() then return end  
          
        room:fillAG(sgs.QList2Table(handcards), source)  
        local card_id = room:askForAG(source, sgs.QList2Table(handcards), false, "saojian")  
        room:clearAG(source)  
        ]]
        local card_id = room:askForCardChosen(source, target, "h", self:objectName(), true)
        if card_id == -1 then return end  
                    
        -- 目标角色重复弃置手牌直到弃置选择的牌  
        while not target:isKongcheng() do  
            local discarded_id = room:askForCardChosen(target, target, "h", self:objectName())
            room:throwCard(discarded_id, target, target)              
            if discarded_id == card_id then  
                break  
            end  
        end  
          
        -- 检查手牌数差异  
        if target:getHandcardNum() > source:getHandcardNum() then  
            room:loseHp(source, 1)  
        end  
    end  
}  
  
-- 扫奸技能  
saojian = sgs.CreateZeroCardViewAsSkill{  
    name = "saojian",  
    view_as = function(self)  
        card = SaojianCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#SaojianCard")  
    end,  
}

yangqiu:addSkill(saojian)

sgs.LoadTranslationTable{
["#yangqiu"] = "扫除奸佞",  
["yangqiu"] = "杨球",   
["illustrator:yangqiu"] = "插画师名称",  
["saojian"] = "扫奸",  
[":saojian"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并选择一张，该角色重复弃置1张手牌直到弃置你选择的牌；此时若其手牌数大于你，你失去1点体力。",
}

zhugedan = sgs.General(extension, "zhugedan", "wei", 4) -- 蜀势力，4血，男性（默认）  

gongao = sgs.CreateTriggerSkill{  
    name = "gongao",  
    frequency = sgs.Skill_Compulsory, -- 锁定技  
    events = {sgs.Death},  
    can_trigger = function(self, event, room, player, data)  
        local death = data:toDeath()  
        local killer = death.damage and death.damage.from or nil  
        
        -- 检查是否是技能拥有者杀死的角色  
        if killer and killer:isAlive() and killer:hasSkill(self:objectName()) and not killer:hasFlag("gongao_" .. death.who:objectName()) then  
            return self:objectName(), killer:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        -- 锁定技无需询问，直接返回true  
        local death = data:toDeath()  
        local killer = death.damage.from
        if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(),data) then
            room:notifySkillInvoked(ask_who, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end
        return false
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local death = data:toDeath()  
        local killer = death.damage.from  
        local dead_player = death.who  
        room:setPlayerFlag(ask_who,"gongao_" .. death.who:objectName())
        -- 查找与死亡角色势力相同的存活角色  
        local same_kingdom_players = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if dead_player:isFriendWith(p) then  
                same_kingdom_players:append(p)  
            end  
        end  
          
        if same_kingdom_players:length() > 0 then  
            -- 有相同势力角色存活，对他们各造成1点伤害  
            for _, target in sgs.qlist(same_kingdom_players) do  
                room:damage(sgs.DamageStruct(self:objectName(), killer, target, 1, sgs.DamageStruct_Normal))  
            end  
        else  
            -- 没有相同势力角色存活，获得额外回合  
            killer:gainAnExtraTurn()  
        end  
          
        return false  
    end,  
}
zhugedan:addSkill(gongao)

sgs.LoadTranslationTable{
["zhugedan"] = "诸葛诞",  
["illustrator:zhugedan"] = "插画师名称",  
["gongao"] = "功獒",  
[":gongao"] = "锁定技，你杀死角色后，若有与其势力相同的角色存活，你对与其势力相同的角色各造成1点伤害；若没有与其势力相同的角色存活，你获得1个额外回合。",
}
zhugeguo = sgs.General(extension, "zhugeguo", "shu", 3, false)  
qidao = sgs.CreateTriggerSkill{
	name = "qidao",
	events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,  
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local use = data:toCardUse()
			if (use.card:isKindOf("EquipCard") or use.card:isKindOf("TrickCard")) and use.from == player then
				return self:objectName()
			end
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
          
        -- 弃置一张牌并记录弃置牌的类型  
        local discarded_card = nil
        if not player:isNude() then  
            --[[
            local card_id = room:askForCardChosen(player, player, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
            if card_id ~= -1 then  
                discarded_card = sgs.Sanguosha:getCard(card_id)  
                room:throwCard(card_id, player, player) 
                -- 摸一张牌  
                room:drawCards(player, 1, self:objectName())   
            end  
            ]]
            discarded_card = room:askForCard(player, ".|.|.|hand,equipped", "@qidao-discard", data, sgs.Card_MethodDiscard)  
            if discarded_card then  
                -- 摸一张牌  
                room:drawCards(player, 1, self:objectName())  
            end  
        end  
          
        -- 检查是否需要额外摸牌（基于弃置的牌类型）  
        if use.card and discarded_card then  
            if use.card:isKindOf("EquipCard") and discarded_card:isKindOf("TrickCard") then  
                -- 使用装备牌时弃置锦囊牌，额外摸1张牌  
                player:drawCards(1, self:objectName())  
            elseif use.card:isKindOf("TrickCard") and discarded_card:isKindOf("EquipCard") then  
                -- 使用锦囊牌时弃置装备牌，额外摸1张牌  
                player:drawCards(1, self:objectName())  
            end  
        end  
		return false
	end
}

-- 羽化技能  
yuhua = sgs.CreateTriggerSkill{  
    name = "yuhua",  
    events = {sgs.CardsMoveOneTime},  
    --frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
						if move.from and move.from:isAlive() and move.from:objectName()==player:objectName() then
							for _,card_id in sgs.qlist(move.card_ids) do
								local card = sgs.Sanguosha:getCard(card_id)  
								local card_type = card:getTypeId()
								-- 回合内失去装备牌
								if move.from:getPhase() ~= sgs.Player_NotActive and card_type == sgs.Card_TypeEquip then  
									return self:objectName()
								-- 回合外失去锦囊牌  
								elseif move.from:getPhase() == sgs.Player_NotActive and card_type == sgs.Card_TypeTrick then  
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
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            if move.from and move.from:isAlive() and move.from:objectName()==player:objectName() then
                for _,card_id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(card_id)  
                    local card_type = card:getTypeId()
                    local should_give = false
                    -- 回合内失去装备牌
                    if move.from:getPhase() ~= sgs.Player_NotActive and card_type == sgs.Card_TypeEquip then  
                        should_give = true
                    -- 回合外失去锦囊牌  
                    elseif move.from:getPhase() == sgs.Player_NotActive and card_type == sgs.Card_TypeTrick then  
                        should_give = true
                    end
                    if should_give then
                        local targets = sgs.SPlayerList()  
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                            targets:append(p)  
                        end  
                        
                        if not targets:isEmpty() then  
                            local target = room:askForPlayerChosen(player, targets, self:objectName())  
                            if target then  
                                target:obtainCard(card)  
                            end  
                        end  
                    end
                end 
            end
        end          
        return false  
    end  
}  
  
zhugeguo:addSkill(qidao)  
zhugeguo:addSkill(yuhua) 

sgs.LoadTranslationTable{
    ["#zhugeguo"] = "蜀汉公主",  
    ["zhugeguo"] = "诸葛果",  
    ["qidao"] = "祈祷",  
    [":qidao"] = "每当你使用1张装备牌时，你可以弃置1张牌并摸一张牌，若弃置的牌为锦囊牌，你摸一张牌；每当你使用1张锦囊牌时，你可以弃置1张牌并摸一张牌，若弃置的牌为装备牌，你摸一张牌。",  
    ["yuhua"] = "羽化",  
    [":yuhua"] = "你回合内失去装备牌或回合外失去锦囊牌时，可以将其交给一名其他角色。",  
    ["@qidao-discard"] = "你可以弃置一张牌发动‘祈祷’",  
    ["@yuhua-give"] = "你可以发动‘羽化’，将此牌交给一名其他角色",  
    ["~yuhua"] = "选择一名其他角色→点击确定",
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
              
            -- 标记本回合已使用  
            room:setPlayerFlag(player, "fuyin_used")  
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

return {extension}