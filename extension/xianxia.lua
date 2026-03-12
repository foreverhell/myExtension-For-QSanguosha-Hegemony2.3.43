extension = sgs.Package("xianxia", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

caoying = sgs.General(extension, "caoying", "wei", 3, false)
lingren = sgs.CreateTriggerSkill{  
    name = "lingren",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return false
        end

        local use = data:toCardUse()
        if use.from:objectName() ~= player:objectName() then
            return false
        end

        local card = use.card
        if not (card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("FireAttack")
            or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")
            or card:isKindOf("BurningCamps") or card:isKindOf("Drowning")) then
            return false
        end

        for _, p in sgs.qlist(use.to) do
            if not p:isKongcheng() then
                return self:objectName()
            end
        end
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            return true
        end
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
          
        -- 构建可选择的玩家列表  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(use.to) do
            if not p:isKongcheng() then
                targets:append(p)
            end
        end  
          
        -- 选择一名角色  
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@lingren-select")  
        if not target then return false end  

        --展示其至多2张手牌
        local num = math.min(target:getHandcardNum(),2)
        local card_ids = room:askForCardsChosen(player, target, string.rep("h",num), self:objectName(), num, num)  
        for _,card_id in sgs.qlist(card_ids) do
            room:showCard(target, card_id)
        end

        --弃置一张“谋”
        local pile_cards = player:getPile("mou")  
        if pile_cards:isEmpty() then return false end  
        local mou_ids = sgs.IntList()  
        -- 将牌堆转换为Lua表  
        for _, id in sgs.qlist(pile_cards) do  
            mou_ids:append(id)
        end  
        -- 检查牌堆是否为空  
        if mou_ids:length() == 0 then  
            return false
        end  
        -- 使用AG界面让玩家选择一张牌  
        room:fillAG(mou_ids, player)  
        local mou_id = room:askForAG(player, mou_ids, true, self:objectName())  
        room:clearAG(player) 
        if mou_id == -1 then return false end
        room:throwCard(mou_id, player, player)
        local mou = sgs.Sanguosha:getCard(mou_id)


        --判断“谋”和展示的手牌的关系
        for _,card_id in sgs.qlist(card_ids) do
            local card = sgs.Sanguosha:getCard(card_id)
            if card:getSuit() == mou:getSuit() then
                local tag = sgs.QVariant()  
                tag:setValue(use.card)  
                room:setTag("lingren_card", tag)  
                
                -- 设置伤害+1的标记  
                room:addPlayerMark(player, "lingren_damage")  
                --增加伤害的目标
                room:setTag("lingren_target", sgs.QVariant(target:objectName()))
            end
            if card:getEffectName() == mou:getEffectName() then
                player:obtainCard(card)
            end
        end
        return false  
    end  
}  
  
-- 增加伤害的触发技  
lingrenDamage = sgs.CreateTriggerSkill{  
    name = "#lingren-damage",  --附加效果用#号，将技能解耦
    events = {sgs.DamageCaused},  
    global = true,  
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or player:getMark("lingren_damage") <= 0 then  
            return false  
        end  
        local damage = data:toDamage()  
        local card = room:getTag("lingren_card"):toCard()  
        local target_name = room:getTag("lingren_target"):toString()  
        if card and damage.card and damage.card:getId() == card:getId() and   
           damage.to and damage.to:objectName() == target_name then  
            return self:objectName()  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:removePlayerMark(player, "lingren_damage")  
        room:removeTag("lingren_card")  
        room:removeTag("lingren_target")

        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}

fujian = sgs.CreateTriggerSkill{  
    name = "fujian",  
    events = {sgs.EventPhaseEnd, sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName()) and not player:isNude()) then 
            return false
        end  

        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
        elseif event == sgs.Damaged then
            return self:objectName()
        end
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local card_ids = room:askForExchange(player, self:objectName(), 1, 0)
        if card_ids:isEmpty() then return false end
        for _,card_id in sgs.qlist(card_ids) do  
            player:addToPile("mou", card_id)  
        end
        player:drawCards(1)
        return false  
    end  
}

caoying:addSkill(lingren)
caoying:addSkill(lingrenDamage)
caoying:addSkill(fujian)
extension:insertRelatedSkills("lingren", "#lingren-damage")
sgs.LoadTranslationTable{
    ["caoying"] = "曹婴",  
    ["lingren"] = "凌人",  
    [":lingren"] = "当你使用伤害牌指定目标后，你可以展示一个目标至多2张手牌，然后你可以移除一张“谋”牌，若展示牌与此“谋”牌：花色相同，此牌对其伤害+1；牌名相同，你获得该牌",
    ["fujian"] = "伏间",  
    [":fujian"] = "结束阶段或你受到伤害后，你可以将一张牌置于“谋”牌堆，然后摸一张牌",
    ["mou"] = "谋"
}

--[[
chenqun = sgs.General(extension, "chenqun", "wei", 3)

pindiCard = sgs.CreateSkillCard{
    name = "pindiCard",
    skill_name = "pindi",
    filter = function(self, targets, to_select, Self)
		return #targets == 0 and to_select:objectName() ~= Self:objectName() and not 
        to_select:hasFlag("pindiUsed_" .. Self:objectName())
	end,
	on_use = function(self, room, source, targets)
        if not source:hasSkill("huashen") then
            room:addPlayerMark(source, "@pindiTimes", 1)
        end
        room:setPlayerFlag(targets[1], "pindiUsed_" .. source:objectName())
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        if card:getTypeId() == sgs.Card_TypeBasic then
            room:setPlayerFlag(source, "pindiBasic")
        elseif card:getTypeId() == sgs.Card_TypeTrick then
            room:setPlayerFlag(source, "pindiTrick")
        elseif card:getTypeId() == sgs.Card_TypeEquip then
            room:setPlayerFlag(source, "pindiEquip")
        end

        local judge = sgs.JudgeStruct()  
        judge.pattern = "."  
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = targets[1]    
        room:judge(judge)  

        if judge.card:isBlack() then
            local choice
            local x = source:getMark("@pindiTimes")
            if targets[1]:isNude() then --target无牌则默认摸牌
                choice = "d1tx"
            else
                choice = room:askForChoice(source, "pindi", "d1tx%log:" .. x .. "+dxt1%log:" .. x)
            end

            if string.find(choice, "d1tx") then
                targets[1]:drawCards(x)
            elseif string.find(choice, "dxt1") then
                room:askForDiscard(targets[1], "pindi", x, x, false, true)
            end
        else
            source:turnOver()
        end

        if source:isAlive() and targets[1]:getLostHp() > 0 and not source:isChained() then
            --横置,要serverplayer类型
            room:setPlayerProperty(getServerPlayer(room, source:objectName()), "chained", sgs.QVariant(true))
        end
	end
}

pindi = sgs.CreateOneCardViewAsSkill{
    name = "pindi",
    --response_pattern = "@@pindiVS",
    view_filter = function(self, card)
        if sgs.Self:hasFlag("pindiBasic") and card:getTypeId() == sgs.Card_TypeBasic then
            return false
        end
        if sgs.Self:hasFlag("pindiTrick") and card:getTypeId() == sgs.Card_TypeTrick then
            return false
        end
        if sgs.Self:hasFlag("pindiEquip") and card:getTypeId() == sgs.Card_TypeEquip then
            return false
        end
        return true
    end,

    view_as = function(self, card)
        local skillCard = pindiCard:clone()
        skillCard:addSubcard(card:getId())
        skillCard:setSkillName(self:objectName())
		skillCard:setShowSkill(self:objectName())
        return skillCard
    end,
    enabled_at_play = function(self, player)   
        return true
    end,
    enabled_at_response = function(self, player, pattern)   
        return pattern == "@@pindiVS"
    end,
}

pindiDamaged = sgs.CreateTriggerSkill{
    name = "pindi",
    events = {sgs.Damaged, sgs.EventPhaseChanging},
    view_as_skill = pindi,
    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local skill_owners = room:findPlayersBySkillName(self:objectName())
                if skill_owners:isEmpty() then return false end
                for _, skill_owner in sgs.qlist(skill_owners) do
                    if skillTriggerable(skill_owner, self:objectName()) then
                        room:setPlayerMark(skill_owner, "@pindiTimes", 0)
                    end
                end
            end
        end
        return false
    end,

    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and not player:isNude() and event == sgs.Damaged then
			return self:objectName()
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("pindi", player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
        room:askForUseCard(player, "@@pindiVS", "@pindi-toDiscard")
        return false
    end
}

chenqun:addSkill("luafaen")
chenqun:addSkill(pindiDamaged)

sgs.LoadTranslationTable{
    ["chenqun"] = "陈群",
    ["pindi"] = "品第",
    [":pindi"] = "出牌阶段或当你受到伤害后，你可以弃置一张本回合未以此法选择过的类别牌，令一名本回合未以此法选择过的其他角色判定：若判定牌为黑，你令其摸或弃置X张牌（X为你本回合发动此技能的次数）；" .. 
    "若判定牌为红色，你叠置。若其已受伤，你横置。",
    ["faen"] = "法恩",
    [":faen"] = "有角色横置或叠置后，你可以令其摸一张牌。",
    ["#pindiDamaged"] = "品第",
    ["@pindi-toDiscard"] = "品第:弃置一张牌并选择一名其他角色",
    ["@faen-draw"] = "法恩：是否令%dest摸一张牌",
    ["pindi:d1tx"] = "令其摸 %log 张牌",
    ["pindi:dxt1"] = "令其弃置 %log 张牌",
    ["$pindi1"] = "观其风气，查其品行。",
    ["$pindi2"] = "推举贤才，兴盛大魏。",
    ["$faen1"] = "礼法容情，皇恩浩荡。 ",
    ["$faen2"] = "法理有度，恩威并施。",
    ["~chenqun"] = "吾身虽陨，典律昭昭。",
}
]]
cuifei = sgs.General(extension, "cuifei", "wei", 3, false) -- 蜀势力，4血，男性（默认）  

yiyong = sgs.CreateTriggerSkill{
	name = "yiyong",
	events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,
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

yiyong = sgs.CreateTriggerSkill{
	name = "yiyong",
	events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive and current~=player then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
                    if move.to and move.to:isAlive() and move.to:hasSkill(self:objectName()) and move.to_place == sgs.Player_PlaceHand then
                        for _,card_id in sgs.qlist(move.card_ids) do
                            local card = sgs.Sanguosha:getCard(card_id)
                            if card:isKindOf("EquipCard") then 
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
        local move_datas = data:toList()
        local equips = sgs.IntList()
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            for _,card_id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:isKindOf("EquipCard") then 
                    equips:append(card_id)
                end
            end 
        end

        -- 检查牌堆是否为空  
        if equips:length() == 0 then  
            return false
        end
        while not equips:isEmpty() do
            room:fillAG(equips, player)  
            local card_id = room:askForAG(player, equips, true, self:objectName())  
            room:clearAG(player) 
            if card_id == nil then return false end
            local equip = sgs.Sanguosha:getCard(card_id)
            if equip == nil then return false end
            room:useCard(sgs.CardUseStruct(equip, player, player), false)   
            equips:remove(card_id)
        end
        return false
	end
}

yashang = sgs.CreateMasochismSkill{  
    name = "yashang",  
    frequency = sgs.Skill_Compulsory,  
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			return self:objectName()
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
	end,
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
        local equips = player:getEquips()  
        for _, equip in sgs.qlist(equips) do  
            if equip:isKindOf("SixDragons") then  
                -- 找到了六龙骖驾，占2个装备格子
                empty_slots = empty_slots - 2
                break  
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
[":yiyong"] = "当你回合外获得装备时，你可以使用之",  
["yashang"] = "雅殇",  
[":yashang"] = "锁定技，当你受到伤害后，若伤害来源与你势力不同，其须将手牌弃至X张，若其未弃牌，你将手牌摸至X张；若伤害来源与你势力相同，你须将手牌弃至X张，若你未弃牌，伤害来源将手牌摸至X张。X为你空置装备栏数。",
}
--[[
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
        if target:hasShownSkill(self:objectName()) then  
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

fuhuanghou = sgs.General(extension, "fuhuanghou", "qun", 3, false)
zhuikongUse = sgs.CreateZeroCardViewAsSkill{
    name = "zhuikongUse",
    response_pattern = "@@zhuikongUse",
    response_or_use = true,
    view_as = function(self)
		local card_id = sgs.Self:getMark("zhuikongCardid") - 1
		local view_as_card = sgs.Sanguosha:getCard(card_id)
        return view_as_card
	end,
}

zhuikong = sgs.CreateTriggerSkill{  
    name = "zhuikong",
    events = {sgs.EventPhaseStart, sgs.Pindian},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start
        and not player:hasSkill(self:objectName()) and not player:isKongcheng() then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and not owner:isKongcheng() then
                return self:objectName(), owner:objectName()
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                return self:objectName(), player:objectName()
            end
        end
        return false
    end,

    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true
        elseif event == sgs.Pindian then
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            ask_who:pindian(player, self:objectName())
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            local winner = nil
            local card = nil
			local card_id = nil
            if pindian.from_number == pindian.to_number then
                return false
            end
            if pindian.from_number > pindian.to_number then
                winner = pindian.from
                card = pindian.to_card
				card_id = pindian.to_card:getId()
            elseif pindian.from_number < pindian.to_number then
                winner = pindian.to
                card = pindian.from_card
				card_id = pindian.from_card:getId()
            end
			room:setPlayerMark(winner, "zhuikongCardid", card_id + 1)
			local prompt = "惴恐：你可以使用拼点输的牌（【"
			room:askForUseCard(winner, "@@zhuikongUse", prompt .. card:getName() .. "】）")
			room:setPlayerMark(winner, "zhuikongCardid", 0)
        end
        return false
    end
}


qiuyuan = sgs.CreateTriggerSkill{  
    name = "qiuyuan",  
    events = {sgs.TargetConfirming},
      
    can_trigger = function(self, event, room, player, data)  
        if not player:hasSkill(self:objectName()) then return "" end  
          
        local use = data:toCardUse()  
        -- 检查是否是杀且当前角色是目标之一  
        if use.card:isKindOf("Slash") and use.to:contains(player) then  
            -- 检查是否还有其他可选目标  
            local others = room:getOtherPlayers(player)  
            for _, p in sgs.qlist(others) do  
                if not use.to:contains(p) and use.from:canSlash(p, use.card, false) then --第二个条件可以不要 
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local others = room:getOtherPlayers(player)  
        local targets = sgs.SPlayerList()  
          
        -- 收集可选目标  
        for _, p in sgs.qlist(others) do  
            if not use.to:contains(p) and use.from:canSlash(p, use.card, false) then  
                targets:append(p)  
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@qiuyuan-choose", true)  
        if target then  
            player:setTag("qiuyuan_target", sgs.QVariant(target:objectName()))  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local target_name = player:getTag("qiuyuan_target"):toString()  
        player:removeTag("qiuyuan_target")  
          
        local target = room:findPlayer(target_name)  
        if target then
            local card = room:askForCard(target, "Jink", "@qiuyuan-give:" .. player:objectName(), data, sgs.Card_MethodNone)
            if card then
                player:obtainCard(card)
            else
                -- 将新目标添加到杀的目标列表中  
                use.to:append(target)  
                room:sortByActionOrder(use.to)  
                data:setValue(use)  
                
                -- 触发新目标的TargetConfirming事件  
                room:getThread():trigger(sgs.TargetConfirming, room, target, data)
            end
        end
        return false
    end
}

fuhuanghou:addSkill(zhuikong)
fuhuanghou:addSkill(qiuyuan)
if not sgs.Sanguosha:getSkill("zhuikongUse") then skills:append(zhuikongUse) end

sgs.LoadTranslationTable{
    ["fuhuanghou"] = "伏皇后",
    ["zhuikong"] = "惴恐",
    [":zhuikong"] = "其他角色的准备阶段，你可以与其拼点，赢的角色可以使用输的角色的拼点牌。",
    ["qiuyuan"] = "求援",
    [":qiuyuan"] = "当你成为杀的目标时，你可以选择另一名其他角色，其选择交给你一张闪或者也成为此杀的目标。",
}
ganfuren = sgs.General(extension, "ganfuren", "shu", 3, false)
shushen = sgs.CreateTriggerSkill{  
    name = "jieshushen",  
    frequency = sgs.Skill_Frequent,  
    events = {sgs.HpRecover},  
    can_trigger = function(self, event, room, player, data)
        if player and player:hasSkill(self:objectName()) then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)
        local recover = data:toRecover()
        -- 回复几点体力就触发几次
        for i = 1, recover.recover do  
            -- 选择目标
            local targets = room:getOtherPlayers(player)
            local target = room:askForPlayerChosen(player, targets, "shushen", "shushen-invoke", true, true)
              
            if target then
                room:broadcastSkillInvoke("shushen", player)
                player:drawCards(1, "shushen")
                if target:isKongcheng() then
                    target:drawCards(2, "shushen")
                else
                    target:drawCards(1, "shushen")
                end
            end
        end
        return false
    end
}  

shushenLose = sgs.CreateTriggerSkill{
	name = "#jieshushen-lose",
	events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
						if move.from and move.from:isAlive() and player:objectName()==move.from:objectName() then
                            if move.card_ids:length() >= 2 then
                                return "jieshushen"
                            end
						end
					end
				end
			end
		end
		return ""
	end
}
extension:insertRelatedSkills("jieshushen","#jieshushen-lose")
ganfuren:addSkill(shushen)
ganfuren:addSkill(shushenLose)
ganfuren:addSkill("shenzhi")
sgs.LoadTranslationTable{
    ["ganfuren"] = "甘夫人",
    ["jieshushen"] = "淑慎",
    [":jieshushen"] = "当你回复1点体力/一次性失去至少2张牌后，你可以选择一名其他角色，令你与其各摸一张牌，若其没有手牌，其摸2张牌"
}
]]
guanluo = sgs.General(extension, "guanluo", "wei", 3)

luatuiyanCard = sgs.CreateSkillCard{
    name = "luatuiyanCard",
    skill_name = "luatuiyan",
    target_fixed = true,--是否需要指定目标，默认false，即需要
    on_use = function(self, room, source)
        local card_id = self:getSubcards():first()
        local card = sgs.Sanguosha:getCard(card_id)
        local supCard = nil
        if card:isBlack() then
		    supCard = sgs.Sanguosha:cloneCard("supply_shortage", card:getSuit(), card:getNumber())
        elseif card:isRed() then
		    supCard = sgs.Sanguosha:cloneCard("Indulgence", card:getSuit(), card:getNumber())
        end
        supCard:addSubcard(card_id)
        supCard:setSkillName("luatuiyan")
        supCard:setShowSkill("luatuiyan")
        supCard:setFlags("Global_NoDistanceChecking")
        room:useCard(sgs.CardUseStruct(supCard, source, source), true) --只能对自己用
        room:setPlayerMark(source,"@tuiyanNumber",card:getNumber())
        supCard:deleteLater()
    end
}

luatuiyan = sgs.CreateOneCardViewAsSkill{
    name = "luatuiyan",
    response_pattern = "@@luatuiyan",
    view_filter = function(self, to_select)
		if to_select:isKindOf("TrickCard") then return false end
        if sgs.Self:hasFlag("no_black") and to_select:isBlack() then return false end
        if sgs.Self:hasFlag("no_red") and to_select:isRed() then return false end
        return true
    end,

	view_as = function(self, card)
        local supCard = luatuiyanCard:clone()
        supCard:addSubcard(card:getId())
        supCard:setSkillName("luatuiyan")
		supCard:setShowSkill("luatuiyan")
        return supCard
    end,
}

tuiyan = sgs.CreateTriggerSkill{
    name = "tuiyan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and not player:isNude() then
            local jcards = player:getCards("j")
            local hasIndulgence, hasShortage = false, false
            for _, c in sgs.qlist(jcards) do
                if c:isKindOf("SupplyShortage") then 
                    hasShortage = true 
                    room:setPlayerFlag(player,"no_black")
                end
                if c:isKindOf("Indulgence") then 
                    hasIndulgence = true 
                    room:setPlayerFlag(player,"no_red")
                end
            end
            if not (hasIndulgence and hasShortage) then
                return self:objectName()
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
        local d = sgs.QVariant()
        d:setValue(player)
        if room:askForUseCard(player, "@@luatuiyan", "@luatuiyan::" .. player:objectName()) then 
            local N = math.min(player:getMark("@tuiyanNumber"), 5)
            top_cards=room:getNCards(N)
            room:askForGuanxing(player, top_cards, sgs.Room_GuanxingBothSides)
            room:setPlayerMark(player,"@tuiyanNumber",0)
        end
        return false
    end
}



mingjie = sgs.CreateTriggerSkill{
    name = "mingjie",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
        end
        return false
    end,

    on_cost = function(self, event, room, player, data)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        for i=1,3 do  
            if player:askForSkillInvoke(self:objectName(), data) then
                -- 从牌堆顶获得一张牌  
                local card_id = room:drawCard()  
                if not card_id then break end  -- 牌堆空了  
                
                local card = sgs.Sanguosha:getCard(card_id)  
                room:obtainCard(player, card_id)
                room:showCard(player, card_id)
                if card:isBlack() then
                    if player:getHp()>1 then
                        room:loseHp(player,1)
                    end
                    break
                end  
            else
                break
            end
        end  
        return false
    end
}
guanluo:addSkill(tuiyan)
guanluo:addSkill(mingjie)
if not sgs.Sanguosha:getSkill("luatuiyan") then skills:append(luatuiyan) end

sgs.LoadTranslationTable{  
    ["guanluo"] = "管络",
    ["tuiyan"] = "推演",
    [":tuiyan"] = "准备阶段，你可以将1张红色非锦囊牌当乐不思蜀或1张黑色非锦囊牌当兵粮寸断置于判定区，并卜算X，X为该牌点数且至多为5",  
      
    ["mingjie"] = "命劫",  
    [":mingjie"] = "结束阶段，你可以摸1张牌，若此牌为：红色，你可以重复此流程（最多摸3张）；黑色，若你的体力值大于1，你失去1点体力",  
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
        local dummy = sgs.DummyCard() 
		if target:canDiscard(player, "he") then
			dummy:addSubcard(room:askForCardChosen(target, player, "he", self:objectName()))
		end
		if target:canDiscard(player, "he") then
			dummy:addSubcard(room:askForCardChosen(target, player, "he", self:objectName()))--必须不是同一张
		end  
        room:throwCard(dummy, player, target)
        dummy:deleteLater()
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
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Start) then return ""  end  

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
        if room:askForUseCard(ask_who, "slash", "你可以使用一张杀", -1, sgs.Card_MethodUse, false) then
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
            local card_ids = room:getNCards(1)            
            -- 创建卡牌移动结构，从牌堆移动到桌面（可见）  
            local move = sgs.CardsMoveStruct()  
            move.from = nil  
            move.from_place = sgs.Player_DrawPile  
            move.to = nil  -- 移动到桌面  
            move.to_place = sgs.Player_PlaceTable  
            move.card_ids = card_ids  
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason.S_REASON_DEMONSTRATE, player:objectName())  
            -- 执行移动并展示  
            room:moveCardsAtomic(move, true)
            local card_id = card_ids:first()
            local card = sgs.Sanguosha:getCard(card_id)
            if card:isRed() or card:isKindOf("Slash") then  
                room:obtainCard(player, card_id)
                room:showCard(player, card_id)
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

guanyinping = sgs.General(extension, "guanyinping", "shu", 4, false)
guanyinping:setDeputyMaxHpAdjustedValue(-1)

xuehen = sgs.CreateTriggerSkill{  
    name = "xuehen",  
    events = {sgs.CardUsed, sgs.DamageCaused},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local source = room:findPlayerBySkillName(self:objectName())  
        if not (source and source:isAlive() and source:hasSkill(self:objectName())) then  
            return ""  
        end
        if event == sgs.CardUsed then
            if source:hasFlag("xuehen_used") then return "" end
            local use = data:toCardUse()  
            -- 检查是否是红色杀  
            local card = use.card  
            if card and card:isKindOf("Slash") and card:isRed() and source:isFriendWith(use.from) then  
                return self:objectName(), source:objectName()
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("xuehen_fire") then
                damage.nature = sgs.DamageStruct_Fire
                data:setValue(damage)
            end
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:setPlayerFlag(ask_who, "xuehen_used")
            room:notifySkillInvoked(ask_who, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse() 
        local target = use.from
        local card_id = room:drawCard()
        local card = sgs.Sanguosha:getCard(card_id)
        room:obtainCard(target, card, true)
        room:showCard(target, card_id)
        if use.card:getColor() == card:getColor() then
            use.card:setFlags("xuehen_fire")
        end
        if use.card:getSuit() == card:getSuit() then
            --参考业仇
            use.card:setFlags("GlobalCardUseDisresponsive")  -- 设置不可响应标志  
            --use.card:setTag("addcardinality", sgs.QVariant(1)) --伤害+1
        end
        data:setValue(use)
        return false  
    end  
}

wuji = sgs.CreateTriggerSkill{  
    name = "wuji",  
    events = {sgs.EventLoseSkill, sgs.GeneralShown, sgs.GeneralHidden, sgs.DFDebut, sgs.TurnStart},
    -- sgs.GameStart, sgs.GeneralTransformed, sgs.TurnStart
    relate_to_place = "deputy",
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)
        if event == sgs.TurnStart then
            player = room:findPlayerBySkillName(self:objectName())
            if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        end
        if player:hasShownSkill(self:objectName()) then
            if player:inHeadSkills("wusheng") and player:hasShownSkill("wusheng") then
                room:handleAcquireDetachSkills(player, "wushengExtraSlash!")
            else
                room:handleAcquireDetachSkills(player, "wusheng!")
            end
        else
            if player:inHeadSkills("wusheng") and player:hasShownSkill("wusheng") then
                room:handleAcquireDetachSkills(player, "-wushengExtraSlash!")
            else
                room:handleAcquireDetachSkills(player, "-wusheng!")
            end            
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return false
    end,  
    on_effect = function(self, event, room, player, data, ask_who)
        return false
    end
}
wushengExtraSlash = sgs.CreateTriggerSkill{  
    name = "wushengExtraSlash",  
    events = {sgs.SlashMissed, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local current = room:getCurrent()
        if player ~= current then return "" end
        if event == sgs.SlashMissed then
            local effect = data:toSlashEffect() 
            if effect.slash:getSkillName() == "wusheng" then
                room:addPlayerMark(player,"@wusheng_missed")
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player,"wusheng_missed",0)
        end
        return ""
    end
}
wushengExtraSlashMod = sgs.CreateTargetModSkill{  
    name = "wushengExtraSlashMod",  
    pattern = "Slash",  
    residue_func = function(self, player, card)  
        if player:hasShownSkill("wushengExtraSlash") then
            return player:getMark("@wusheng_missed")
        end
        return 0
    end  
}
guanyinping:addSkill(xuehen)
guanyinping:addSkill(wuji)
if not sgs.Sanguosha:getSkill("wushengExtraSlash") then skills:append(wushengExtraSlash) end
if not sgs.Sanguosha:getSkill("wushengExtraSlashMod") then skills:append(wushengExtraSlashMod) end
sgs.LoadTranslationTable{
    ["guanyinping"] = "关银屏",
    ["xuehen"] = "雪恨",
    [":xuehen"] = "每回合限一次。与你势力相同的角色使用红色杀时，你可以令其摸1张牌并展示，若这两张牌：颜色相同，此杀造成的伤害改为火属性；花色相同，此杀不可响应",
    ["wuji"] = "武继",
    [":wuji"] = "副将技。-1阴阳鱼。你视为拥有武圣；若你已有武圣，则增加描述“以此法使用的杀被抵消后，不计入次数”",
    ["wushengExtraSlash"] = "武继",
    [":wushengExtraSlash"] = "你因“武圣”转化的杀被抵消后，不计入次数”",
}

guozhao = sgs.General(extension, "guozhao", "wei", 3, false)

pianchong = sgs.CreateTriggerSkill{  --如果成了，好几个技能都需要调整一下（出牌阶段改为，而不是准备阶段跳过出牌阶段）
    name = "pianchong",  
    events = {sgs.DrawNCards}, --sgs.EventPhaseStart 
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
           --and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        --player:skip(sgs.Player_Draw)
        local count = data:toInt()
        data:setValue(0)          
        -- 亮出牌堆顶X+1张牌  
        local cards = room:getNCards(4)
          
        if not cards:isEmpty() then  
            room:fillAG(cards)
              
            -- 让玩家选择一种颜色  
            local red_cards = sgs.IntList()  
            local black_cards = sgs.IntList()  
              
            for _, id in sgs.qlist(cards) do  
                local card = sgs.Sanguosha:getCard(id)  
                if card:isRed() then  
                    red_cards:append(id)  
                else  
                    black_cards:append(id)  
                end  
            end  
              
            local choice = "red"  
            if not red_cards:isEmpty() and not black_cards:isEmpty() then  
                choice = room:askForChoice(player, self:objectName(), "red+black+1r1b")  
            elseif not black_cards:isEmpty() then  
                choice = "black"  
            end  
            room:clearAG() 
            -- 获得选择颜色的所有牌  
            local chosen_cards = sgs.IntList()  
            if choice == "red" then  
                chosen_cards = red_cards  
            elseif choice == "black" then
                chosen_cards = black_cards  
            elseif choice == "1r1b" then
                room:fillAG(red_cards, player) 
                local red_card_id = room:askForAG(player, red_cards, false, self:objectName())
                room:clearAG(player) 
                if red_card_id ~= -1 then
                    chosen_cards:append(red_card_id)
                end

                room:fillAG(black_cards, player) 
                local black_card_id = room:askForAG(player, black_cards, false, self:objectName())
                room:clearAG(player) 
                if black_card_id ~= -1 then
                    chosen_cards:append(black_card_id)
                end
            end  
            if not chosen_cards:isEmpty() then
                local dummy = sgs.DummyCard(chosen_cards)  
                room:obtainCard(player, dummy)  
                dummy:deleteLater()  
            end                             
            -- 其余牌置入弃牌堆  
            for _, id in sgs.qlist(cards) do  
                if not chosen_cards:contains(id) then  
                    room:throwCard(id, nil) 
                end  
            end   
        end  
        return false  
    end  
}  

zunwei = sgs.CreateTriggerSkill{  
    name = "zunwei",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.Damaged}, --sgs.EventPhaseStart 
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
            if event == sgs.EventPhaseStart then
                if player:getPhase() == sgs.Player_Start then --标记清除
                    room:setPlayerMark(player,"zunwei_heart",0)
                    room:setPlayerMark(player,"zunwei_spade",0)
                    room:setPlayerMark(player,"zunwei_diamond",0)
                    room:setPlayerMark(player,"zunwei_club",0)
                elseif player:getPhase() == sgs.Player_Discard and player:getHandcardNum()<=player:getMaxCards() then  
                    room:setPlayerFlag(player,"zunwei_no_discard")
                end
            elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:hasFlag("zunwei_no_discard") then
                return self:objectName()
            elseif event == sgs.Damaged then
                return self:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)
        room:drawCards(player,1,self:objectName())
        local card_id = room:askForCardChosen(player, player, "he", self:objectName())
        room:throwCard(card_id, player, player)
        local card = sgs.Sanguosha:getCard(card_id)
        room:setPlayerMark(player,"zunwei_" .. card:getSuitString(),1)
    end
}


zunweiLose = sgs.CreateTriggerSkill{
	name = "#zunwei-lose",
	events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
						if move.from and move.from:isAlive() and player:objectName()==move.from:objectName() then
                            for _,card_id in sgs.qlist(move.card_ids) do
                                local card = sgs.Sanguosha:getCard(card_id)
                                if player:getMark("zunwei_" .. card:getSuitString()) > 0 then 
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
		return player:askForSkillInvoke(self:objectName(),data) --player:hasShownSkill(self:objectName())
	end,
    on_effect = function(self, event, room, player, data)
		--player:drawCards(1)
		local red_count = 0
		local move_datas = data:toList()
		for _, move_data in sgs.qlist(move_datas) do
			local move = move_data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
				if move.from and move.from:isAlive() and player:objectName()==move.from:objectName() then
					for _,card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						if player:getMark("zunwei_" .. card:getSuitString()) > 0 then 
							red_count = red_count + 1
						end
					end
				end
			end
		end
		if red_count > 0 then
			player:drawCards(red_count)
		end
        return false
	end
}
guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)
guozhao:addSkill(zunweiLose)
extension:insertRelatedSkills("zunwei","#zunwei-lose")
sgs.LoadTranslationTable{  
    ["guozhao"] = "郭照",  
    ["pianchong"] = "偏宠",  
    [":pianchong"] = "摸牌阶段，你可以改为亮出牌堆顶4张牌，然后选择获得（1）所有红色牌（2）所有黑色牌（3）红黑各1张",  
      
    ["zunwei"] = "尊位",  
    [":zunwei"] = "若你弃牌阶段未弃牌或受到伤害后，你可以摸1张牌，并弃置1张牌，直到你的下回合开始，你失去与弃置牌花色相同的牌时，你摸一张牌",  
    ["1r1b"] = "1黑1红"
}
liubian = sgs.General(extension, "liubian", "qun", 3)  -- 吴国，4血，男性  
shiyuan = sgs.CreateTriggerSkill{  
    name = "shiyuan",  
    events = {sgs.TargetConfirmed},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)    
        -- 寻找拥有诗怨技能的角色  
        local shiyuan_player = room:findPlayerBySkillName(self:objectName())  
        if not (shiyuan_player and shiyuan_player:isAlive() and shiyuan_player:hasSkill(self:objectName())) then return "" end
        if shiyuan_player:hasFlag("shiyuan_used") then return "" end

        local use = data:toCardUse()  
        local source = use.from
        if not (source and source:isAlive()) then return "" end
        if use.card:getTypeId()==sgs.Card_TypeSkill then return "" end --不能是技能卡
        local is_involved = false  
        local other_player = nil  
        --[[
        -- 检查是否为使用者或目标  
        if source and source:objectName() == shiyuan_player:objectName() then  
            -- 技能拥有者使用牌指定其他角色  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() ~= shiyuan_player:objectName() then  
                    is_involved = true  
                    other_player = target  
                    break  
                end  
            end  
        elseif source and source:objectName() ~= shiyuan_player:objectName() then  
            -- 其他角色使用牌指定技能拥有者  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() == shiyuan_player:objectName() then  
                    is_involved = true  
                    other_player = source  
                    break  
                end  
            end  
        end
        ]]
        if source and source:objectName() ~= shiyuan_player:objectName() then  
            -- 其他角色使用牌指定技能拥有者  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() == shiyuan_player:objectName() then  
                    is_involved = true  
                    other_player = source  
                    break  
                end  
            end
        end
        if is_involved then
            return self:objectName(), shiyuan_player:objectName()
        end
        return ""
    end,
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            room:setPlayerFlag(ask_who, "shiyuan_used")  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        local source = use.from  
        local other_player = nil  
          
        -- 确定对比的角色  
        if source and source:objectName() == ask_who:objectName() then  
            -- 技能拥有者使用牌  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() ~= ask_who:objectName() then  
                    other_player = target  
                    break  
                end  
            end  
        else  
            -- 其他角色使用牌指定技能拥有者  
            other_player = source  
        end  
          
        if other_player then  
            local my_hp = ask_who:getHp()  
            local other_hp = other_player:getHp()  
            local draw_num = 0  
              
            if other_hp > my_hp then  
                draw_num = 2  -- 对方体力大于自己  
            elseif other_hp <= my_hp then  
                draw_num = 1  -- 对方体力小于等于自己  
            end  
              
            if draw_num > 0 then  
                ask_who:drawCards(draw_num, self:objectName())  
            end  
        end  
          
        return false  
    end  
}  

shiyuan = sgs.CreateTriggerSkill{  
    name = "shiyuan",  
    events = {sgs.TargetConfirmed},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)    
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if player:hasFlag("shiyuan_used") then return "" end

        local use = data:toCardUse()
        if use.card:getTypeId()==sgs.Card_TypeSkill then return "" end --不能是技能卡
        if use.from ~= player and use.to:contains(player) then return self:objectName() end
        return ""
    end,
      
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerFlag(player, "shiyuan_used")
            return true
        end
        return false
    end,
      
    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        if use.from then
            local my_hp = player:getHp()
            local other_hp = use.from:getHp()
            local draw_num = 0

            if other_hp > my_hp then
                draw_num = 2  -- 对方体力大于自己
            elseif other_hp <= my_hp then
                draw_num = 1  -- 对方体力小于等于自己
            end

            if draw_num > 0 then
                player:drawCards(draw_num, self:objectName())
            end
        end
        return false  
    end  
}
liubian:addSkill(shiyuan)

-- 翻译表  
sgs.LoadTranslationTable{
["liubian"] = "刘辩",  
["shiyuan"] = "诗怨",  
[":shiyuan"] = "每回合限一次。当你成为其他角色使用牌的目标后，若其体力值：大于你，你摸2张牌；小于等于你，你摸1张牌。"
}
--[[
liuchen = sgs.General(extension, "liuchen", "shu", 4) -- 蜀势力，4血，男性（默认）  

zhanjueDuelCard = sgs.CreateSkillCard{  
    name = "zhanjueDuelCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        local duel = sgs.Sanguosha:cloneCard("duel")  
        duel:deleteLater()
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
        duel:deleteLater()
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
]]

liuyao = sgs.General(extension, "liuyao", "qun", 4)  -- 群雄，4血  
zhannanCard = sgs.CreateSkillCard{  
    name = "zhannan",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()  
    end,  

    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        -- 进行拼点  
        local success = source:pindian(target, "zhannan")
    end  
}  
  
zhannanVS = sgs.CreateZeroCardViewAsSkill{  
    name = "zhannan",
    view_as = function(self)
        local card = zhannanCard:clone()
        card:setSkillName(self:objectName())
        return card  
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#zhannan") and not player:isKongcheng()
    end
}

zhannan = sgs.CreateTriggerSkill{  
    name = "zhannan",  
    events = {sgs.Pindian, sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,
    view_as_skill = zhannanVS,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                return self:objectName()
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:hasFlag("zhannan_add") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
                room:setPlayerFlag(damage.from,"-zhannan_add")
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.Pindian then
            return true
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.Pindian then
            local pindian = data:toPindian()
            local winner = nil
            if pindian.from_number == pindian.to_number then
                return false
            end
            if pindian.from_number > pindian.to_number then
                winner = pindian.from
            elseif pindian.from_number < pindian.to_number then
                winner = pindian.to
            end
            room:setPlayerFlag(winner,"zhannan_add")
        end
        return false  
    end  
}
liuyao:addSkill(zhannan)
sgs.LoadTranslationTable{
    ["liuyao"] = "刘繇",
    ["zhannan"] = "战难",
    [":zhannan"] = "出牌阶段限一次。你可以与一名其他角色拼点，赢的角色本回合下次杀的伤害+1",
}
quyi = sgs.General(extension, "quyi", "qun", 4)

yiqi = sgs.CreateTriggerSkill{  
    name = "yiqi",  
    events = {sgs.EventPhaseStart, sgs.Damage},
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            return self:objectName()
        elseif event == sgs.Damage then
            return self:objectName()
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            return player:askForSkillInvoke(self:objectName(), data)  
        elseif event == sgs.Damage then
            return true
        end
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if not player:isFriendWith(p) then  
                    targets:append(p)  
                end  
            end  
            if not targets:isEmpty() then  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@firstshow-give")  
                if target then  
                    target:gainMark("@firstshow",1)
                end  
            end 
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:getMark("@firstshow") > 0 then
                damage.to:loseMark("@firstshow",1)
                player:gainMark("@firstshow",1)
            end
        end
        return false  
    end  
}  
quyi:addSkill(yiqi)
sgs.LoadTranslationTable{
    ["quyi"] = "麹义",
    ["yiqi"] = "刈旗",
    [":yiqi"] = "准备阶段，你可以令一名势力不同角色获得先驱。你对角色造成伤害后，你可以获得其先驱"
}
simashi = sgs.General(extension, "simashi", "wei", 3)

yimie = sgs.CreateTriggerSkill{  
    name = "yimie",  
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Limited,
    limit_mark = "@yimie",
    can_trigger = function(self, event, room, player, data) 
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("@yimie") > 0 then
            local damage = data:toDamage()
            if damage.to:getHp() > damage.from:getHp() then
                return self:objectName()
            end
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        damage.damage = damage.damage * 2
        data:setValue(damage)
        room:setPlayerMark(player, "@yimie", 0)
        return false
    end
}

tairanCard = sgs.CreateSkillCard{
    name = "tairanCard",
    target_fixed = true,--是否需要指定目标，默认false，即需要
    on_use = function(self, room, source)
        local choices = {}  
        for i = 0, source:getHp()-1 do  
            table.insert(choices, tostring(i))  
        end  
        if #choices ~= 0 then
            local choice = room:askForChoice(source, "@tairan-losehp", table.concat(choices, "+"))  
            local hp_mark = tonumber(choice)  
            if hp_mark > 0 then
                room:loseHp(source, hp_mark)
                room:setPlayerMark(source, "@tairan_hp", hp_mark)
            end
        end

        choices = {}  
        for i = 0, source:getLostHp() do  
            table.insert(choices, tostring(i))  
        end  
        if #choices ~= 0 then
            local choice = room:askForChoice(source, "@tairan-discard", table.concat(choices, "+"))  
            local card_mark = tonumber(choice)
            if card_mark > 0 then
                room:askForDiscard(source, self:objectName(), card_mark, card_mark, false, true)
                room:setPlayerMark(source, "@tairan_card", card_mark)
            end
        end
    end
}

tairanVS = sgs.CreateZeroCardViewAsSkill{
    name = "tairan",
	view_as = function(self)
        local supCard = tairanCard:clone()
        supCard:setSkillName(self:objectName())
		supCard:setShowSkill(self:objectName())
        return supCard
    end,
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#tairanCard") and not player:isNude() 
    end  
}

tairan = sgs.CreateTriggerSkill{  
    name = "tairan",  
    events = {sgs.EventPhaseEnd},
    view_as_skill = tairanVS,
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data) 
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
            if player:getMark("@tairan_hp") > 0 or player:getMark("@tairan_card") > 0 then
                return self:objectName()
            end
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true--player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)
        local hp_mark = player:getMark("@tairan_hp")
        local card_mark = player:getMark("@tairan_card")
        if hp_mark > 0 then
            --恢复
            local recover = sgs.RecoverStruct()  
            recover.who = player
            recover.recover = hp_mark
            room:recover(player, recover)
            --清除标记
            room:setPlayerMark(player, "@tairan_hp", 0)
        end
        if card_mark > 0 then
            --摸牌
            player:drawCards(card_mark)
            --清除标记
            room:setPlayerMark(player, "@tairan_card", 0)
        end
        return false
    end
}

simashi:addSkill(yimie)
simashi:addSkill(tairan)
sgs.LoadTranslationTable{
    ["simashi"] = "司马师",
    ["yimie"] = "夷灭",
    [":yimie"] = "限定技。你对体力值大于你的角色造成伤害时，你可以令伤害翻倍",
    ["tairan"] = "泰然",
    [":tairan"] = "出牌阶段限一次。你可以失去任意点体力并弃置至多X张牌（X为已失去的体力值），回合结束时，你恢复因此失去的体力值，并摸因此弃置的牌数",
    ["@tairan-losehp"] = "要失去的体力值",
    ["@tairan-discard"] = "要弃的牌数"
}
-- 创建武将：
sunru_xianxia = sgs.General(extension, "sunru_xianxia", "wu", 3, false)  

xiecui = sgs.CreateTriggerSkill{  
    name = "xiecui",  
    events = {sgs.DamageComplete},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        local current = room:getCurrent()
        local damage = data:toDamage()  
        -- 检查是否是杀造成的伤害  
        if damage.from == current and damage.card and damage.card:isKindOf("Slash") then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and not owner:hasFlag("xiecui_used") then
                room:setPlayerFlag(owner, "xiecui_used")--首次。不管发不发动，都加标记
                return self:objectName(), owner:objectName()
            end
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
        local damage = data:toDamage()  
        damage.from:obtainCard(damage.card)
        if ask_who:isFriendWith(damage.from) then
            room:setPlayerFlag(damage.from, "xiecui_maxcards_plus")
        end
        return false  
    end  
}
xiecuiMaxCards = sgs.CreateMaxCardsSkill{  
    name = "#xiecui-maxcards",  
    extra_func = function(self, target)  
        if target:hasFlag("xiecui_maxcards_plus") then  
            return 1
        end  
        return 0  
    end  
}

fuxu = sgs.CreateTriggerSkill{  
    name = "fuxu",  
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:getPhase()==sgs.Player_Finish and player:getHandcardNum() > player:getHp() then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) then
                return self:objectName(), owner:objectName()
            end
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
        local card_id = room:askForCardChosen(ask_who, player, "h", self:objectName())
        if card_id then
            room:showCard(player, card_id)
            local target = room:askForPlayerChosen(ask_who, room:getOtherPlayers(player), self:objectName())
            if target then
                room:obtainCard(target, card_id)
                local is_min_hp = true
                for _,p in sgs.qlist(room:getOtherPlayers(target)) do
                    if target:getHp() > p:getHp() then
                        is_min_hp = false
                        break
                    end
                end
                if is_min_hp then
                    target:drawCards(1,self:objectName())
                end
            end
        end
        return false  
    end  
}
extension:insertRelatedSkills("xiecui","#xiecui-maxcards")
sunru_xianxia:addSkill(xiecui)
sunru_xianxia:addSkill(xiecuiMaxCards)
sunru_xianxia:addSkill(fuxu)
sgs.LoadTranslationTable{
    ["sunru_xianxia"] = "孙茹",
    ["xiecui"] = "撷翠",
    [":xiecui"] = "一名角色在自己回合内首次使用杀造成伤害结算后，你可以令其获得此牌；若其与你势力相同，其本回合手牌上限+1",
    ["fuxu"] = "抚恤",
    [":fuxu"] = "一名角色回合结束时，若其手牌数大于体力值，你可以展示其一张手牌并交给另一名角色。若获得牌的角色体力值最小，其摸一张牌",
}
wangtaowangyue = sgs.General(extension, "wangtaowangyue", "shu", 3, false)  

fengnuCard = sgs.CreateSkillCard{  
    name = "fengnuCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isAllNude()
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]
        local card_id = room:askForCardChosen(source, target, "hej", self:objectName())
        local card = sgs.Sanguosha:getCard(card_id)
        local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
        duel:addSubcard(card_id)
        duel:setSkillName("fengnu")  
        local use = sgs.CardUseStruct()  
        use.card = duel  
        use.from = target  
        use.to:append(source)
        room:useCard(use) 
        duel:deleteLater()
    end
}
fengnu = sgs.CreateZeroCardViewAsSkill{  
    name = "fengnu",  
    view_as = function(self)  
        local fengnuCard = fengnuCard:clone()  
        fengnuCard:setSkillName(self:objectName())  
        fengnuCard:setShowSkill(self:objectName())  
        return fengnuCard  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#fengnuCard")  
    end  
}  


shuangguanVS = sgs.CreateViewAsSkill{  
    name = "shuangguan",
    n = 2,  
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then return true end
        if #selected == 1 then return selected[1]:getColor() == to_select:getColor() and selected[1]:getSuit() ~= to_select:getSuit() end
        return false
    end,  
    view_as = function(self, cards)  
        if #cards == 2 then            
            local card_name = sgs.Self:getTag(self:objectName()):toString()
            if card_name ~= "" then
                local view_as_card = sgs.Sanguosha:cloneCard(card_name)
                view_as_card:setCanRecast(false)
                view_as_card:addSubcard(cards[1])
                view_as_card:addSubcard(cards[2])
                view_as_card:setSkillName(self:objectName())
                view_as_card:setShowSkill(self:objectName())
                return view_as_card
            end
        end  
    end,  
    enabled_at_play = function(self, player)  
        return true
    end,  
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash" or pattern == "jink"
    end,
    vs_card_names = function(self, selected)
		if #selected == 2 then
			return "slash+jink"
		end
		return ""
	end,
}

shuangguan = sgs.CreateTriggerSkill{  
    name = "shuangguan",  
    events = {sgs.CardResponded, sgs.CardUsed},  
    view_as_skill = shuangguanVS,
    --frequency = sgs.Skill_Frequent,
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
        if card and card:isKindOf("Slash") and card:getSkillName() == self:objectName() and player:isKongcheng() then
            return self:objectName()
        end  
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)
        return true--player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), player)
          
        player:drawCards(1)
        return false  
    end  
}
wangtaowangyue:addSkill(fengnu)  
wangtaowangyue:addSkill(shuangguan)
sgs.LoadTranslationTable{
    ["wangtaowangyue"] = "王桃王悦",  
    ["fengnu"] = "锋驽",  
    [":fengnu"] = "出牌阶段限一次。你可以选择一名其他角色区域一张牌，令其将这张牌当作决斗对你使用",
    ["shuangguan"] = "双关",  
    [":shuangguan"] = "你可以将2张颜色相同花色不同的牌当杀或闪使用或打出，你因此失去所有手牌后摸一张牌",  
}
wangyun = sgs.General(extension, "wangyun", "qun", 3) -- 蜀势力，4血，男性（默认）  

ShelunCard = sgs.CreateSkillCard{  
    name = "ShelunCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        if #targets > 0 then return false end  
        if to_select:objectName() == sgs.Self:objectName() then return false end  
        --if to_select:isAllNude() then return false end
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

xinxianying = sgs.General(extension, "xinxianying", "wei", 3, false)

chengjieCard = sgs.CreateSkillCard{  
    name = "chengjieCard",  
    target_fixed = false,--是否需要指定目标，默认false，即需要
    will_throw = false,
    filter = function(self, selected, to_select)  
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]
        local my_card_id = self:getSubcards():first()
        local mycard = sgs.Sanguosha:getCard(my_card_id)
        room:showCard(source, my_card_id)
        --至多3张
        local choices = {}  
        for i = 1, math.min(target:getHandcardNum(),3) do  
            table.insert(choices, tostring(i))  
        end    
        local count = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))  

        local chosen_card_ids = room:askForCardsChosen(source, target, string.rep("h",count), self:objectName(), count, count)  
        for _,id in sgs.qlist(chosen_card_ids) do
            local card = sgs.Sanguosha:getCard(id)
            room:showCard(target, id)
            if mycard:getSuit() == card:getSuit() then
                source:drawCards(1,self:objectName())
            end
            if mycard:getNumber() == card:getNumber() then
                room:damage(sgs.DamageStruct(self:objectName(), source, target, 1, sgs.DamageStruct_Normal)) 
            end
            if mycard:getSuit() ~= card:getSuit() and mycard:getNumber() ~= card:getNumber() then
                room:askForDiscard(source, self:objectName(), 1, 1, false, true)
            end
        end
    end  
}  
chengjie = sgs.CreateOneCardViewAsSkill{
    name = "chengjie",
    filter_pattern = ".|.|.|hand", 
    view_as = function(self, card)
        local skillCard = chengjieCard:clone()
        skillCard:addSubcard(card:getId())
        skillCard:setSkillName(self:objectName())
		skillCard:setShowSkill(self:objectName())
        return skillCard
    end,
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#chengjieCard") and not player:isKongcheng()  
    end  
}
qingshi2 = sgs.CreateTriggerSkill{
    name = "qingshi2",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
            return ""
        end
        return self:objectName()
    end,
    
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            return true
        end
        return false
    end,
    
    on_effect = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:hasShownOneGeneral() then  
                targets:append(p)  
            end  
        end  
        local target = room:askForPlayerChosen(player, targets, self:objectName())
        if player:isFriendWith(target) then
            player:drawCards(1,self:objectName())
            target:drawCards(1,self:objectName())
        else
            if not target:isNude() then
                room:throwCard(room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard), target, player)
                if not player:isNude() then
                    room:throwCard(room:askForCardChosen(player, player, "he", self:objectName(), false, sgs.Card_MethodDiscard), player, player)
                end
            end
        end
        return false
    end
}
xinxianying:addSkill(chengjie)
xinxianying:addSkill(qingshi2)
sgs.LoadTranslationTable{
    ["xinxianying"] = "辛宪英",
    ["chengjie"] = "诚节",
    [":chengjie"] = "出牌阶段限一次。你可以展示一张手牌，指定一名其他角色，然后展示其至多3张手牌，若其与你展示的手牌：花色相同，你摸1张牌；点数相同，你对其造成1点伤害；都不相同，你弃置1张牌",
    ["qingshi2"] = "清识",
    [":qingshi2"] = "你受到伤害后，你可以选择一名有明置武将的角色：若其与你势力相同，你与其各摸1张牌；若其与你势力不同，你弃置你与其各1张牌"
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

zhangyi_xianxia = sgs.General(extension, "zhangyi_xianxia", "shu", 4) 

wujieCard = sgs.CreateSkillCard{  
    name = "wujie",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select)  
        if #targets == 0 then  
            return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
        end  
        return false  
    end,  
    feasible = function(self, targets)  
        return #targets==1
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  

        local card1 = room:askForCardShow(target, source, self:objectName())  
        local card2 = room:askForCardShow(source, source, self:objectName())  
        room:showCard(target, card1:getId())  
        room:showCard(source, card2:getId())  
        if card2:isKindOf("Slash") and not card1:isKindOf("Jink") then --你展示的是杀，其展示的不是闪
            room:throwCard(card2:getId(), source, source)
            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = target  
            damage.damage = 1  
            damage.reason = self:objectName() 
            room:damage(damage)  
        elseif not card2:isKindOf("Slash") and card1:isKindOf("Jink") then --你展示的不是杀，其展示的是闪
            room:throwCard(card2:getId(), source, source)
            local card_id = room:askForCardChosen(source, target, "he", self:objectName(), false, sgs.Card_MethodNone)  
            room:obtainCard(source, card_id)  
        end    
    end  
}  
  
wujie = sgs.CreateZeroCardViewAsSkill{  
    name = "wujie",  
    view_as = function(self)  
        local card = wujieCard:clone()
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
        
    enabled_at_play = function(self, player)  
        return not player:isKongcheng() and not player:hasUsed("#wujie") 
    end  
}

shizhi = sgs.CreateOneCardViewAsSkill{  
    name = "shizhi",  
    filter_pattern = "Jink|.|.|.",  
    view_as = function(self, card)  
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())  
        slash:addSubcard(card:getId())  
        slash:setSkillName(self:objectName())  --设置转化牌的技能名
        slash:setShowSkill(self:objectName())  --使用时亮将
        return slash  
    end,
    enabled_at_play = function(self, player)   
        return player:getHp() == 1 --and sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)   
        return player:getHp() == 1 and pattern == "slash"
    end,
}

shizhiMod = sgs.CreateTargetModSkill{  
    name = "#shizhi-mod",  
    pattern = "Slash",  
	residue_func = function(self, player, card)  
        if card:getSkillName() == "shizhi" then
            return 1000
        end
        return 0  
    end  
}
extension:insertRelatedSkills("shizhi","#shizhi-mod")
zhangyi_xianxia:addSkill(wujie)
zhangyi_xianxia:addSkill(shizhi)
zhangyi_xianxia:addSkill(shizhiMod)
sgs.LoadTranslationTable{
    ["zhangyi_xianxia"] = "张嶷",
    ["wujie"] = "无戒",
    [":wujie"] = "出牌阶段限一次。你可以和一名其他角色同时展示一张手牌：若你展示的是杀，其展示的不是闪，你弃置展示的牌，对其造成1点伤害；若你展示的不是杀，其展示的是闪，你弃置展示的牌，获得其1张牌",
	["shizhi"] = "矢志",
	[":shizhi"] = "当你体力值为1时，你的闪可以视为杀，你以此法使用的杀无次数限制",
}

zhonghuiQuan = sgs.General(extension, "zhonghuiQuan", "wei", 3)
quanji = sgs.CreateTriggerSkill{  
    name = "jiequanji",  
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
        return "quanji" 
    end,  
    on_cost = function(self, event, room, player, data)  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        return false  
    end  
}
quanjiMaxCard = sgs.CreateMaxCardsSkill{  
    name = "#jiequanji-maxcard",  
    frequency = sgs.Skill_Compulsory,  
    extra_func = function(self, target)  
        return target:getPile("power_pile"):length()
    end  
}  
extension:insertRelatedSkills("jiequanji", "#jiequanji-maxcard")
zhonghuiQuan:addSkill(quanji)
zhonghuiQuan:addSkill(quanjiMaxCard)
zhonghuiQuan:addSkill("paiyi")
sgs.LoadTranslationTable{
    ["zhonghuiQuan"] = "钟会",
    ["jiequanji"] = "权计",
    [":jiequanji"] = "你受到伤害后，你可以摸1张牌并将1张牌置于“权”牌堆；你的手牌上限+X，X为“权”的数量"
}
zhoucang = sgs.General(extension, "zhoucang", "shu", 4)  
zhongyong = sgs.CreateTriggerSkill{
    name = "zhongyong",
    events = {sgs.CardFinished, sgs.SlashMissed},
    can_trigger = function(self, event, room, player, data)
        if not skillTriggerable(player, self:objectName()) then
            return false
        end
        if player:hasFlag("zhongyong_used") then return false end
        if event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            local jink = effect.jink
            local tag = player:getTag("zhongyong_jink"):toString()
            if tag then
                tag = tag .. "+" .. tostring(jink:getId())
                player:setTag("zhongyong_jink", sgs.QVariant(tag))
            else
                player:setTag("zhongyong_jink", sgs.QVariant(tostring(jink:getId()))) 
            end
            return false
        end
        if event == sgs.CardFinished then
            local card = data:toCardUse().card
            if card and card:isKindOf("Slash") then  
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
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@zhongyong-target")
		if target then
            local card = nil
            local tag = player:getTag("zhongyong_jink"):toString()
            if tag then
                local card_ids = sgs.IntList()
                card_ids:append(data:toCardUse().card:getId())
                for _,id in ipairs(tag:split("+")) do
                    card_ids:append(tonumber(id))
                end
                player:setTag("zhongyong_jink", sgs.QVariant())

                room:fillAG(card_ids, player)  
                local id = room:askForAG(player, card_ids, false, self:objectName())  
                room:clearAG(player)
                if id then
                    card = sgs.Sanguosha:getCard(id)
                else--没选，默认选杀
                    card = data:toCardUse().card
                end
            else
                card = data:toCardUse().card
            end
            if not card then return false end
			target:obtainCard(card)
            if card:isRed() then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
					if p:isAlive() and player:inMyAttackRange(p) then  
						targets:append(p)
					end  
				end 
				local victim = room:askForPlayerChosen(target, targets, self:objectName(), "@zhongyong-victim", true)
				if victim then  
					local prompt = string.format("@zhongyong-slash:%s:%s:", victim:objectName(), target:objectName())
					room:askForUseSlashTo(target, victim, prompt, false, false, false)
				end
			end
			room:setPlayerFlag(player,"zhongyong_used")
        end
        return false  
    end  
}  
zhoucang:addSkill(zhongyong)
sgs.LoadTranslationTable{
	["zhoucang"] = "周仓",
	["zhongyong"] = "忠勇",
	[":zhongyong"] = "每回合限一次。你使用杀结算后，你可以将此杀或响应此杀的闪交给一名其他角色，若其获得的牌为红色，其可以对你攻击范围内一名角色使用一张杀",
}
zhugedan = sgs.General(extension, "zhugedan", "wei", 4)

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

weizhong = sgs.CreateTriggerSkill{  
    name = "weizhong",  
    frequency = sgs.Skill_Frequent,  
    events = {sgs.PostHpReduced},  
    can_trigger = function(self, event, room, player, data)          
        -- 检查是否是技能拥有者杀死的角色  
        if player and player:hasSkill(self:objectName()) then  
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(),data) then
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end
        return false
    end,  
      
    on_effect = function(self, event, room, player, data)
        if player:isKongcheng() then
            player:drawCards(2,self:objectName()) 
        else
            player:drawCards(1,self:objectName())
        end
    end
}

zhugedan:addSkill(gongao)
zhugedan:addSkill(weizhong)
sgs.LoadTranslationTable{
["zhugedan"] = "诸葛诞",  
["illustrator:zhugedan"] = "插画师名称",  
["gongao"] = "功獒",  
[":gongao"] = "锁定技，你杀死角色后，若有与其势力相同的角色存活，你对与其势力相同的角色各造成1点伤害；若没有与其势力相同的角色存活，你获得1个额外回合。",
["weizhong"] = "威重",
[":weizhong"] = "你体力减少时，你可以摸一张牌，若你没有手牌，则改为摸2张"
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

huaman = sgs.General(extension, "huaman", "shu", 3, false) 

mansi = sgs.CreateTriggerSkill{  
    name = "mansi",  
    events = {sgs.DamageInflicted, sgs.Damaged, sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)        
        if event == sgs.DamageInflicted then
            if player and player:isAlive() and player:hasSkill(self:objectName()) then  
                local damage = data:toDamage()  
                if damage.card:isKindOf("SavageAssault") then  
                    return self:objectName()  
                end  
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()  
            if damage.card:isKindOf("SavageAssault") then 
                room:addPlayerMark(damage.to, "@mansi")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("SavageAssault")  then
                local count = 0
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("@human1") > 0 then
                        count = count + 1
                        room:setPlayerMark(p,"@human1",0)
                    end
                end
                if count > 0 then
                    local owner = room:findPlayerBySkillName(self:objectName())
                    if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
                    owner:drawCards(count,self:objectName())
                end
            end
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)  
        return true  
    end  
}  

zhanyuanCard = sgs.CreateSkillCard{  
    name = "zhanyuanCard",  
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1
    end,  
      
    on_use = function(self, room, source, targets)  
        room:setPlayerMark(source, "@zhanyuan", 0)
        local target = targets[1]
        room:acquireSkill(source,"xili", true, true)
        room:acquireSkill(target,"xili", true, true)
    end  
}  
-- 创建相马视为技  
zhanyuan = sgs.CreateZeroCardViewAsSkill{  
    name = "zhanyuan",
    frequency = sgs.Skill_Limit,
    limit_mark = "@zhanyuan",
    view_as = function(self)  
        local xc = zhanyuanCard:clone()  
        xc:setShowSkill(self:objectName())  
        return xc  
    end,  
      
    enabled_at_play = function(self, player)  
        return player:getMark("@zhanyuan") > 0
    end  
}  


xili = sgs.CreateTriggerSkill{  
    name = "xili",  
    events = {sgs.TargetConfirming, sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
        if event == sgs.TargetConfirming then
            --这种实现的思路是：有xili的其他角色使用杀，自己弃牌
            --另一种思路是：自己使用杀，在room:getOtherPlayers(player)中找到其他有xili的角色，他弃牌
            local use = data:toCardUse()  
            if use.card:isKindOf("Slash") and use.from:hasSkill(self:objectName()) and use.from ~= player then 
                if player:hasSkill(self:objectName()) then
                    return self:objectName()
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card:hasFlag("xili_add") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@xili-discard")
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
        use.card:setFlags("xili_add")
        data:setValue(use)
        return false  
    end  
}

huaman3VS = sgs.CreateViewAsSkill{  
    name = "huaman3",  
      
    view_filter = function(self, selected, to_select)  
        return #selected < sgs.Self:getHandcardNum()
    end,  
      
    view_as = function(self, cards)  
        if #cards ~= sgs.Self:getHandcardNum() then return nil end  
                    
        local card =  sgs.Sanguosha:cloneCard("savage_assault")
        for _, c in ipairs(cards) do  
            card:addSubcard(c)  
        end  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:isKongcheng() and not player:hasFlag("huaman3_used")
    end  
}  
huaman3 = sgs.CreateTriggerSkill{  
    name = "huaman3",  
    events = {sgs.CardUsed},  
    view_as_skill = huaman3VS,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill("huaman3")) then return "" end  
        -- 当使用衔镜技能时设置标记  
        local use = data:toCardUse()  
        card = use.card  
        if card:getSkillName() == "huaman3" then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 自动触发  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:setPlayerFlag(player, "huaman3_used")  
        return false  
    end  
}
--huaman:addSkill(mansi)--这个技能暂时有问题
huaman:addSkill(zhanyuan)
huaman:addSkill(huaman3)
if not sgs.Sanguosha:getSkill("xili") then skills:append(xili) end
sgs.LoadTranslationTable{
    ["huaman"] = "花鬘",  
    ["mansi"] = "蛮嗣",  
    [":mansi"] = "锁定技。你不会受到【南蛮入侵】的伤害。【南蛮入侵】结算完成后，你摸X张牌，X为受到该【南蛮入侵】伤害的角色数",  
    ["zhanyuan"] = "战缘",  
    [":zhanyuan"] = "限定技。出牌阶段，你可以选择一名其他角色，令你与其获得【系力】",  
    ["xili"] = "系力",  
    [":xili"] = "你使用杀指定目标时，其他拥有【系力】的角色可以弃置一张牌，令此杀伤害+1",
    ["@xili-discard"] = "你可以弃置1张牌，令此杀伤害+1",
    ["huaman3"] = "技能3",  
    [":huaman3"] = "出牌阶段限一次。你可以将所有手牌当作【南蛮入侵】使用",      
}
dongcheng = sgs.General(extension, "dongcheng", "qun", 4)  
dongcheng1 = sgs.CreateTriggerSkill{  
    name = "dongcheng1",  
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.Pindian},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then
            if skillTriggerable(player, self:objectName()) then
                local current = room:getCurrent()
                if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
                    local move_datas = data:toList()
                    for _, move_data in sgs.qlist(move_datas) do
                        local move = move_data:toMoveOneTime()
                        if move.to_place == sgs.Player_PlaceHand then
                            if move.to and move.to:isAlive() and player:objectName()==move.to:objectName() then
                                if move.card_ids:length() >= 2 then
                                    room:setPlayerFlag(player,"dongcheng1_active")
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish and not player:isKongcheng() then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and owner:hasFlag("dongcheng1_active") and not owner:isKongcheng() then
                return self:objectName(), owner:objectName()
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                return self:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish and ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true
        elseif event == sgs.Pindian then
            return true
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(ask_who)) do
                if not p:isKongcheng() then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end
            local target = room:askForPlayerChosen(ask_who, targets, self:objectName())
            if target then
                ask_who:pindian(target, self:objectName())
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            local winner = nil
            local loser = nil
            if pindian.from_number == pindian.to_number then
                return false
            end
            if pindian.from_number > pindian.to_number then
                winner = pindian.from
                loser = pindian.to
            elseif pindian.from_number < pindian.to_number then
                winner = pindian.to
                loser = pindian.from
            end
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:setSkillName(self:objectName())  
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = winner  
            use.to:append(loser)  
            room:useCard(use) 
            slash:deleteLater()
        end
        return false  
    end  
}
dongcheng:addSkill(dongcheng1)
sgs.LoadTranslationTable{
    ["dongcheng"] = "董承",
    ["dongcheng1"] = "技能1",
    [":dongcheng1"] = "你一次性获得过至少2张牌的回合结束时，你可以与一名其他角色拼点，赢的角色视为对输的角色使用杀",
}

sgs.Sanguosha:addSkills(skills)
return {extension}