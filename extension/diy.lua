extension = sgs.Package("diy", sgs.Package_GeneralPack)  

liuxiu = sgs.General(extension, "liuxiu", "jin", 4)
dongzhan = sgs.CreateTriggerSkill{  
    name = "dongzhan",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getPhase() == sgs.Player_Finish then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data) 
        -- 找到所有与选择角色势力相同的角色  
        local same_kingdom_players = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:isFriendWith(player) then  
                same_kingdom_players:append(p)  
            end  
        end  
          
        if same_kingdom_players:isEmpty() then return false end  
          
        -- 让这些角色摸2张牌然后弃2张牌  
        local card_ids = sgs.IntList()
        for _, p in sgs.qlist(same_kingdom_players) do  
            room:drawCards(p, 2, self:objectName())          
            for i = 1, 2 do  
                local card_id = room:askForCardChosen(p, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
                card_ids:append(card_id)
                
                -- 弃置该牌  
                room:throwCard(card_id, p, p) 
            end
        end  
        if player:askCommandto(self:objectName(),player) then
            local dummy = sgs.DummyCard(card_ids)  
            player:obtainCard(dummy)
            dummy:deleteLater()
        end
        return false  
    end  
}

liuxiu:addSkill(dongzhan)
sgs.LoadTranslationTable{
    ["liuxiu"] = "刘秀",
    ["dongzhan"] = "动战",
    [":dongzhan"] = "结束阶段，你可以令所有与你势力相同的角色摸2张牌然后弃置2张牌，然后你向自己发起军令，若你执行，你获得因此弃置的牌"
}


luzhiDiy = sgs.General(extension, "luzhiDiy", "qun", 4)  
luzhiDiy:setHeadMaxHpAdjustedValue(-1)
mingren = sgs.CreateTriggerSkill{
	name = "mingren",
	events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
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
        local ren_pile = player:getPile("ren")  
        if ren_pile:length() > 0 then
            local first_card_id = ren_pile:first()  
            local card = sgs.Sanguosha:getCard(first_card_id)  
            room:obtainCard(player, card, true)  
        end
        ren_pile = player:getPile("ren")
        if ren_pile:length() == 0 then
            local card_id = room:askForCardChosen(player, player, "he", self:objectName(), false, sgs.Card_MethodNone)
            local card = sgs.Sanguosha:getCard(card_id)
            player:addToPile("ren", card)
        end
    end
}

zhenliang = sgs.CreateTriggerSkill{
	name = "zhenliang",
	events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    relate_to_place = "head",
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:getPile("ren"):length()>0 then
            return self:objectName()
        end
		return ""
	end,
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(),data) then
            local ren_pile = player:getPile("ren")  
            local first_card_id = ren_pile:first()  
            local card = sgs.Sanguosha:getCard(first_card_id)
            local pattern = ""
            if card:isKindOf("BasicCard") then
                pattern = "BasicCard"
            elseif card:isKindOf("EquipCard") then
                pattern = "EquipCard"
            elseif card:isKindOf("TrickCard") then
                pattern = "TrickCard"
            end
            return room:askForCard(player, pattern, "@zhenliang-discard", data, sgs.Card_MethodDiscard)  
        end
        return false
    end,  
            
    on_effect = function(self, event, room, player, data)
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())  
        local damage = sgs.DamageStruct()  
        damage.from = player  
        damage.to = target
        damage.damage = 1
        damage.reason = self:objectName()
        room:damage(damage)  
    end
}

chenyan = sgs.CreateTriggerSkill{
	name = "chenyan",
    events = {sgs.CardResponded, sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,
   can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then 
            return false
        end  
        if player:getPhase() ~= sgs.Player_NotActive then  --非回合外，不发动
            return false  
        end
        if player:hasFlag("chenyan_used") then return false end --每回合限一次
        local ren_pile = player:getPile("ren")
        if ren_pile:length() == 0 then return false end
        local ren_card_id = ren_pile:first()  
        local ren_card = sgs.Sanguosha:getCard(ren_card_id)

        local card = nil  
        if event == sgs.CardResponded then  
            card = data:toCardResponse().m_card  
        else  
            card = data:toCardUse().card  
        end  

        if card and ren_card and card:getColor()==ren_card:getColor() then
            return self:objectName()
        end  
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local minhp = player:getHp()
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getHp() < minhp then
                minhp = p:getHp()  
            end
        end 

        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:getHp() == minhp then
                targets:append(p)  
            end
        end  
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@chenyan-target", true)
        if target then
            target:drawCards(2,self:objectName())
            room:askForDiscard(target,self:objectName(),1,1,false,true)
            room:setPlayerFlag(player,"chenyan_used")
        end
        return false  
    end  
}
luzhiDiy:addSkill(mingren)
luzhiDiy:addSkill(zhenliang)
luzhiDiy:addSkill(chenyan)

sgs.LoadTranslationTable{
    ["luzhiDiy"] = "卢植",
    ["mingren"] = "明任",
    [":mingren"] = "准备阶段，若你武将牌上有”任“，你可以将其收回手牌；若你武将牌上没有”任“，你可以将1张牌置于武将牌上，称为“任”",
    ["zhenliang"] = "贞良",
    [":zhenliang"] = "主将技，-1阴阳鱼。结束阶段，你可以弃置1张与”任“类型相同的牌，对一名其他角色造成1点伤害",
    ["chenyan"] = "陈言",
    [":chenyan"] = "每回合限一次。当你回合外使用或打出与”任“颜色相同的牌后，你可以令一名体力值最小的角色摸2张牌并弃置1张牌"
}


shiji = sgs.General(extension, "shiji", "wu", 3)  
lianyu = sgs.CreateTriggerSkill{
	name = "lianyu",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then
            if skillTriggerable(player, self:objectName()) then
                local current = room:getCurrent()
                if player == current then return "" end
                if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
                    local move_datas = data:toList()
                    for _, move_data in sgs.qlist(move_datas) do
                        local move = move_data:toMoveOneTime()
                        if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
                            if move.from and move.from:isAlive() and player:objectName()==move.from:objectName() then
                                room:addPlayerMark(player,"@lianyu_lose",move.card_ids:length())
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and not player:hasSkill(self:objectName()) then
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
            if owner:getMark("@lianyu_lose") > 0 then
                return self:objectName(), owner:objectName()
            end
        end
		return ""
	end,
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(),data) then --发动，在on_effect清除
            return true
        end
        room:setPlayerMark(ask_who,"@lianyu_lose",0) --不发动，这里清除
        return false
    end,  
            
    on_effect = function(self, event, room, player, data, ask_who)
		if not ask_who:askCommandto(self:objectName(), player) then
            local choice = room:askForChoice(ask_who, self:objectName(), "discard+draw")
            if choice == "draw" then
                ask_who:drawCards(ask_who:getMark("@lianyu_lose"))
            elseif choice == "discard" then
                for i=1,ask_who:getMark("@lianyu_lose") do
                    if ask_who:canDiscard(player, "he") then
                        room:throwCard(room:askForCardChosen(ask_who, player, "he", self:objectName(), false, sgs.Card_MethodDiscard), player, ask_who)
                    end                    
                end
            end
        end
        room:setPlayerMark(ask_who,"@lianyu_lose",0) --不管执不执行，都需要把标记清掉
    end
}
shiji:addSkill(lianyu)
sgs.LoadTranslationTable{
    ["shiji"] = "施绩",
    ["lianyu"] = "敛御",
    [":lianyu"] = "其他角色的结束阶段，若你本回合失去过牌，你可对其发起军令，若其不执行，你选择（1）弃置其X张牌（2）摸X张牌。X为你本回合失去的牌数"
}

simayi1 = sgs.General(extension, "simayi1", "jin", 4)
simayi1:setHeadMaxHpAdjustedValue(-1)
lijue = sgs.CreateTriggerSkill{  
    name = "lijue",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local damage = data:toDamage()  
        if damage.from:objectName()==player:objectName() or damage.to:objectName() == player:objectName() then  
            if damage.from:getHandcardNum() > damage.to:getHandcardNum() then
                return self:objectName()
            end
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data) 
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
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
jiyong = sgs.CreateTriggerSkill{  
    name = "jiyong",  
    events = {sgs.EventPhaseStart}, 
    frequency = sgs.Skill_Limited,  
    limit_mark = "@jiyong",  
    relate_to_place = "head", 
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart and player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getPhase() == sgs.Player_Play and player:getMark("@jiyong") > 0 then  
                return self:objectName()
            elseif player:getPhase() == sgs.Player_Discard and player:hasFlag("jiyong_used") then
                return self:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Play then  
            return player:askForSkillInvoke(self:objectName(),data)
        elseif player:getPhase() == sgs.Player_Discard then
            return true
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Play then  
            local num = player:getHandcardNum() + player:getEquips():length()
            player:throwAllHandCardsAndEquips()
            player:drawCards(num*2, self:objectName())
            room:setPlayerFlag(player, "jiyong_used")
        elseif player:getPhase() == sgs.Player_Discard then
            player:throwAllHandCardsAndEquips()
        end  
        return false  
    end  
}

zhixiang = sgs.CreateTriggerSkill{  
    name = "zhixiang",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    relate_to_place = "deputy",
    can_trigger = function(self, event, room, player, data)  
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end 
        local damage = data:toDamage()  
        if damage.from:objectName() ~= owner:objectName() and room:getAlivePlayers():length()>owner:getHp()  then  
            return self:objectName(), owner:objectName()
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
        local damage = data:toDamage()
        local target = room:askForPlayerChosen(ask_who, room:getOtherPlayers(damage.from), self:objectName())
        if target then
            local lure_tiger = sgs.Sanguosha:cloneCard("lure_tiger")  
            local use = sgs.CardUseStruct()  
            use.card = lure_tiger  
            use.from = ask_who  
            use.to:append(target)  
            
            room:useCard(use)  
            lure_tiger:deleteLater()
        end
        if not ask_who:hasFlag("zhixiang_used") then 
            ask_who:drawCards(1,self:objectName())
            room:setPlayerFlag(ask_who, "zhixiang_used")  
        end 
        return false  
    end  
}  
simayi1:addSkill(lijue)
simayi1:addSkill(jiyong)
simayi1:addSkill(zhixiang)
sgs.LoadTranslationTable{
    ["simayi1"] = "司马乂",
    ["lijue"] = "力绝",
    [":lijue"] = "锁定技。当你造成或受到伤害时，若伤害来源的手牌数大于目标，则伤害+1",
    ["jiyong"] = "激勇",
    [":jiyong"] = "主将技，限定技。-1阴阳鱼。出牌阶段开始时，你可以弃置所有牌，并摸2倍的牌，若如此做，弃牌阶段，你弃置所有牌",
    ["zhixiang"] = "支襄",
    [":zhixiang"] = "副将技。当其他角色造成伤害后，若存活角色数大于你的体力值，你可以视为对伤害来源以外的一名其他角色使用【调虎离山】；然后每回合限一次，你可以摸1张牌，"
}

wuqiujian = sgs.General(extension, "wuqiujian", "wei", 4)  
wuqiujian:setHeadMaxHpAdjustedValue(-1)
zhengrong = sgs.CreateTriggerSkill{  
    name = "zhengrong",  
    events = {sgs.Damage, sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end
        local damage = data:toDamage()
        if damage.from and not damage.from:isNude() then
            return self:objectName()
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data)  then  
            return true  
        end            
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        if damage.from and not damage.from:isNude() then
            local card_id = room:askForCardChosen(damage.from, damage.from, "he", self:objectName(), false, sgs.Card_MethodNone)
            local card = sgs.Sanguosha:getCard(card_id)
            player:addToPile("rong", card)
        end
    end
}

qingceCard = sgs.CreateSkillCard{
    name = "qingceCard",
    skill_name = "qingceCard",
    target_fixed = false,--是否需要指定目标，默认false，即需要
    will_throw = true,
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:isAllNude()
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]
        local card_id = room:askForCardChosen(source, target, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
        room:throwCard(card_id, target, source)
        if source:isFriendWith(target) then
            target:drawCards(2,self:objectName())
        end
    end
}

qingce = sgs.CreateOneCardViewAsSkill{
    name = "qingce",
    filter_pattern = ".|.|.|rong",
    expand_pile = "rong",
	view_as = function(self, card)
        local supCard = qingceCard:clone()
        supCard:addSubcard(card:getId())
        supCard:setSkillName("qingce")
        supCard:setShowSkill("qingce")
        return supCard
    end,
    enabled_at_play = function(self, player)   
        local rong_pile = player:getPile("rong")
        return rong_pile:length()>0
    end,
}

hongjv = sgs.CreateTriggerSkill{
	name = "hongjv",
	events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limit,
    relate_to_place = "head",
    limit_mark = "@hongjv",
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if player:getPhase() == sgs.Player_Start and player:getMark("@hongjv")==0 and player:getPile("rong"):length()>0 then
            return self:objectName()
        elseif player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player,"@hongjv_extra_slash",0)
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
        local rong_pile = player:getPile("rong_pile")
        local num = rong_pile:length()
        player:clearOnePrivatePile("rong") 
        local chosen_players = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, num, "请选择玩家", false)

		--local commandIndex = player:startCommand("hongjv", player) --注意5为叠置军令，不能回复体力
        for _, p in sgs.qlist(chosen_players) do  
            --if not p:doCommand("hongjv", commandIndex, player) then
            if not player:askCommandto(self:objectName(),p) then
                player:drawCards(2,self:objectName())
                room:addPlayerMark(player,"@hongjv_extra_slash")
            end
		end
        room:setPlayerMark(player,"@hongjv",1)
    end
}
hongjvExtraSlash = sgs.CreateTargetModSkill{
	name = "#hongjv-mod",
	pattern = "Slash",
	residue_func = function(self, player)
		return player:getMark("@hongjv_extra_slash")
	end,
}

wuqiujian:addSkill(zhengrong)
wuqiujian:addSkill(qingce)
wuqiujian:addSkill(hongjv)
wuqiujian:addSkill(hongjvExtraSlash)
extension:insertRelatedSkills("hongjv", "#hongjv-mod")
sgs.LoadTranslationTable{
    ["wuqiujian"] = "毋丘俭",
    ["zhengrong"] = "征荣",
    [":zhengrong"] = "当你造成或受到伤害后，你可以令伤害来源将1张牌置于你的武将牌上，称为”荣“",
    ["qingce"] = "清侧",
    [":qingce"] = "出牌阶段，你可以弃置1张”荣“并弃置1名角色1张牌，若其与你势力相同，其摸2张牌",
    ["hongjv"] = "鸿举",
    [":hongjv"] = "主将技，限定技。-1阴阳鱼。准备阶段，你可以弃置所有”荣“，并对至多等量名其他角色发起军令，若其不执行，你摸2张牌，并令本回合使用杀次数+1"
}

zhangti = sgs.General(extension, "zhangti", "wu", 4) --wu
zhangti:setDeputyMaxHpAdjustedValue(-1)
lunxian = sgs.CreateTriggerSkill{
	name = "lunxian",
	events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					if move.from_places:contains(sgs.Player_PlaceHand) then
						if move.from and move.from:isAlive() and player:objectName()==move.from:objectName() then
                            local has_basic = false
                            for _, card in sgs.qlist(move.from:getHandcards()) do
                                if card:isKindOf("BasicCard") then
                                    has_basic = true
                                    break
                                end
                            end
                            if not has_basic then
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
        if player:askForSkillInvoke(self:objectName(),data) then
            return true
        end
        return false
    end,  
            
    on_effect = function(self, event, room, player, data)
		player:throwAllHandCards()
        player:drawCards(2,self:objectName())
    end
}


shujueCard = sgs.CreateSkillCard{  
    name = "shujueCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select ~= sgs.Self
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]
        local source_cards = room:askForExchange(source, self:objectName(), source:getHandcardNum(), 0)  
        local target_cards = room:askForExchange(target, self:objectName(), target:getHandcardNum(), 0)
        if not source_cards:isEmpty() then  
            local dummy = sgs.DummyCard(source_cards)  
            room:throwCard(dummy, source, source)
            dummy:deleteLater()
        end
        if not target_cards:isEmpty() then  
            local dummy = sgs.DummyCard(target_cards)  
            room:throwCard(dummy, target, target)
            dummy:deleteLater()
        end
        if source_cards:length() > target_cards:length() then
            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = target
            damage.damage = 1
            damage.reason = self:objectName()
            room:damage(damage)  
        elseif source_cards:length() < target_cards:length() then
            local damage = sgs.DamageStruct()  
            damage.from = target  
            damage.to = source
            damage.damage = 1
            damage.reason = self:objectName()
            room:damage(damage)
        end
    end
}
shujue = sgs.CreateZeroCardViewAsSkill{  
    name = "shujue",  
    relate_to_place = "head",
    view_as = function(self)  
        local shujueCard = shujueCard:clone()  
        shujueCard:setSkillName(self:objectName())  
        shujueCard:setShowSkill(self:objectName())  
        return shujueCard  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#shujueCard")  
    end  
}  

zhizhu = sgs.CreateTriggerSkill{  
    name = "zhizhu",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    relate_to_place = "deputy",
    can_trigger = function(self, event, room, player, data)  
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end 
        local damage = data:toDamage()  
        if not owner:isFriendWith(damage.to)  then  
            return self:objectName(), owner:objectName()
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
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if ask_who:isFriendWith(p) then
                targets:append(p)  
            end
        end  
        local target = room:askForPlayerChosen(ask_who, targets, self:objectName())
        target:drawCards(1, self:objectName())
        room:askForDiscard(target, self:objectName(), 1, 1, false, true)
        return false  
    end  
}  

zhangti:addSkill(lunxian)
zhangti:addSkill(shujue)
zhangti:addSkill(zhizhu)

sgs.LoadTranslationTable{
    ["zhangti"] = "张悌",
    ["lunxian"] = "沦陷",
    [":lunxian"] = "当你失去手牌后，若你手牌中没有基本牌，你可以弃置所有手牌并摸2张牌",
    ["shujue"] = "殊决",
    [":shujue"] = "主将技，-1阴阳鱼。出牌阶段限一次。你可以与一名其他角色同时弃置任意张牌，然后弃置牌多的角色对弃置牌少的角色造成1点伤害",
    ["zhizhu"] = "知著",
    [":zhizhu"] = "副将技。与你势力不同的角色受到伤害后，你可以令一名与你势力相同的角色摸1张牌然后弃置1张牌",
}

return {extension}