-- 创建一个武将包  
extension = sgs.Package("hero", sgs.Package_GeneralPack)  

baiqi = sgs.General(extension, "baiqi", "wei", 4)  --wei,wu
  
-- 技能1：歼灭  
jianmie = sgs.CreateTriggerSkill{  
    name = "jianmie",  
    events = {sgs.Damage},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.from and damage.from:objectName() == player:objectName() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local _data = sgs.QVariant()  
        _data:setValue(damage.to)  
          
        if player:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local target = damage.to  
          
        target:addMark("jianmie")  
        return false  
    end  
}  
  
-- 歼灭摸牌减少效果  
jianmie_draw = sgs.CreateTriggerSkill{  
    name = "#jianmie-draw",  
    events = {sgs.DrawNCards},  
    global = true,  
    can_trigger = function(self, event, room, player, data)  
        if player:getMark("jianmie") > 0 then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        local count = data:toInt()  
        local jianmie_count = player:getMark("jianmie")  
        local new_count = math.max(0, count - jianmie_count)  
        data:setValue(new_count)  
          
        player:setMark("jianmie", 0)  
        return false  
    end  
}  
  
-- 技能2：追击  
zhuiji = sgs.CreateTriggerSkill{  
    name = "zhuiji",  
    events = {sgs.SlashEffected}, 
    frequency = sgs.Skill_Compulsory, 
    can_trigger = function(self, event, room, player, data)  
        local effect = data:toSlashEffect()  
        if effect.from and effect.from:hasSkill(self:objectName()) then  
            if effect.to:getHandcardNum() < 2 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local effect = data:toSlashEffect()  
          
        effect.jink_num = effect.jink_num + 1  
        data:setValue(effect)  
          
        room:notifySkillInvoked(effect.from, self:objectName())  
        return false  
    end  
}  
  
-- 添加技能到武将  
baiqi:addSkill(jianmie)  
baiqi:addSkill(jianmie_draw)  
baiqi:addSkill(zhuiji)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["baiqi"] = "白起",  
    ["jianmie"] = "歼灭",  
    [":jianmie"] = "你对一名角色造成伤害后，你可令其获得一个'歼灭'标记，则其下个摸牌阶段摸牌数-X，X为'歼灭'的数量。",  
    ["zhuiji"] = "追击",  
    [":zhuiji"] = "锁定技，你对角色使用【杀】时，若其手牌数小于2，其回闪量+1。"  
}  
  

-- 创建武将：褒姒  
baosi = sgs.General(extension, "baosi", "wei", 3, false)  --wei,wu,qun
-- 技能：烽火 - 将装备牌视为南蛮入侵  
fenghuo = sgs.CreateOneCardViewAsSkill{  
    name = "fenghuo",  
    filter_pattern = "EquipCard|.|.|hand,equipped",  -- 手牌或装备区的装备牌  
      
    view_filter = function(self, to_select)  
        return to_select:isKindOf("EquipCard")  
    end,  
      
    view_as = function(self, card)  
        local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", card:getSuit(), card:getNumber())  
        savage_assault:addSubcard(card:getId())  
        savage_assault:setSkillName(self:objectName())  
        savage_assault:setShowSkill(self:objectName())  
        return savage_assault  
    end  
}  
  
-- 添加技能给武将  
baosi:addSkill(fenghuo)  
baosi:addSkill("jieyin")    
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["baosi"] = "褒姒",  
    ["#baosi"] = "美人笑",
    ["fenghuo"] = "烽火",  
    [":fenghuo"] = "你可以将一张装备牌当做【南蛮入侵】使用。",  
      
    ["~baosi"] = "烽火戏诸侯，玩火自焚！"  
}  

-- 创建武将：
baozhen = sgs.General(extension, "baozhen", "wei", 3)  --wei 


-- 技能1： - 血量变化时摸一张牌 
pingyuan = sgs.CreateTriggerSkill{  
    name = "pingyuan",
    frequency = sgs.Skill_Compulsory, --锁定技
    events = {sgs.HpChanged},  --集合，可以有多个触发条件
          
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        return self:objectName()
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        room:drawCards(player, 1, self:objectName())  
        return false  
    end,
}  

shenduanCard = sgs.CreateSkillCard{
    name = "shenduanCard",
    target_fixed = true,--是否需要指定目标，默认false，即需要
    will_throw = true,
    on_use = function(self, room, source)
        source:gainMark("@shenduan", 1)
        return false
    end
}

shenduan_active = sgs.CreateViewAsSkill{  
    name = "shenduan",  --需要和触发技名字相同，然后不需要再添加给武将
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0 and not to_select:isEquipped()
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = shenduanCard:clone() -- 创建虚拟牌  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        local used_times = player:usedTimes("ViewAsSkill_shenduanCard")
        return not player:isKongcheng() and used_times < 2 -- 出牌阶段可用  
    end  
}

shenduan = sgs.CreateTriggerSkill{  
    name = "shenduan",  
    view_as_skill = shenduan_active,  
    events = {sgs.AskForRetrial},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getMark("@shenduan") > 0 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        local choices = {}  
          
        if player:getMark("@shenduan") >= 1 then  
            table.insert(choices, "suit") -- 改变花色  
            table.insert(choices, "number") -- 改变点数  
        end  
        if player:getMark("@shenduan") >= 2 then  
            table.insert(choices, "both") -- 同时改变  
        end  
        table.insert(choices, "cancel")  
          
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
        if choice ~= "cancel" then  
            player:setTag("shenduan_choice", sgs.QVariant(choice))  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        local choice = player:getTag("shenduan_choice"):toString()  
        player:removeTag("shenduan_choice")  
          
        local cost = (choice == "both") and 2 or 1  
        player:loseMark("@shenduan", cost)  
          
        -- 根据选择修改判定牌  
        local new_suit = judge.card:getSuit()
        local new_number = judge.card:getNumber()
        if choice == "suit" or choice == "both" then  
            -- 让玩家选择新花色  
            --[[
            local suits = {"spade", "heart", "club", "diamond"}  
            new_suit_string = room:askForChoice(player, "shenduan_suit", table.concat(suits, "+"))  
            local string2suits = {}
            string2suits["spade"] = sgs.Card_Spade
            string2suits["heart"] = sgs.Card_Heart
            string2suits["club"] = sgs.Card_Club
            string2suits["diamond"] = sgs.Card_Diamond
            new_suit = string2suits[new_suit_string]
            ]]
            new_suit = room:askForSuit(player, "shenduan_suit") --这个直接就可以选花色，不需要再转换一次
            -- 这里需要创建新的判定牌  
        end  
          
        if choice == "number" or choice == "both" then  
            -- 让玩家选择新点数  
            local numbers = {}  
            for i = 1, 13 do  
                table.insert(numbers, tostring(i))  
            end  
            new_number_string = room:askForChoice(player, "shenduan_number", table.concat(numbers, "+"))  
            new_number = tonumber(new_number_string)
            -- 这里需要创建新的判定牌  
        end  
        local new_card = sgs.Sanguosha:getWrappedCard(judge.card:getEffectiveId())  --sgs.Sanguosha:getWrappedCard(id)返回的是包装后的卡牌对象（WrappedCard），这是房间内实际使用的、可以被修改的卡牌实例
        new_card:setSuit(new_suit)--这里原本是字符串，改成了花色数据类型
        new_card:setNumber(new_number)--这里是字符串，需要改成int
        new_card:setModified(true) --设置已修改，否则会重置为原来的属性
        
        --第二种实现方法：WrappedCard接管cloneCard创造的虚拟卡
        --local clone_card = sgs.Sanguosha:cloneCard(judge.card:objectName(), new_suit, new_number)
        --new_card:takeOver(clone_card)

        judge.card = new_card
        room:broadcastUpdateCard(room:getPlayers(), judge.card:getEffectiveId(), new_card) --通知所有玩家，该判定牌变了
        -- 执行改判  
        --room:retrial(new_card, player, judge, self:objectName())  
        judge:updateResult()
        data:setValue(judge)
        return false  
    end  
}
--[[
shenduanCard = sgs.CreateSkillCard{  
    name = "ShenduanCard",  
    target_fixed = true,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
    on_use = function(self, room, source, targets)  
        source:addToPile("shenduan", self:getSubcards())  
    end  
}  
  
shenduanVS = sgs.CreateOneCardViewAsSkill{  
    name = "shenduan",  
    filter_pattern = ".|.|.|hand",  
    
    view_as = function(self, card)  
        local skillcard = shenduanCard:clone()  
        skillcard:addSubcard(card)  
        skillcard:setSkillName(self:objectName())  
        skillcard:setShowSkill(self:objectName())
        return skillcard  
    end,  
    enabled_at_play = function(self, player)  
        return not player:isKongcheng()  
    end
}  

-- 神断改判技能  
shenduan = sgs.CreateTriggerSkill{  
    name = "shenduan",  
    view_as_skill = shenduanVS,  
    events = {sgs.AskForRetrial},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if not player:getPile("shenduan"):isEmpty() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if not player:askForSkillInvoke(self:objectName(),data) then 
            return false
        end
        local judge = data:toJudge()  
        local pile_cards = player:getPile("shenduan")  
        if pile_cards:isEmpty() then return false end  
            
        local card_ids = sgs.IntList()  
        
        -- 将牌堆转换为Lua表  
        for _, id in sgs.qlist(pile_cards) do  
            card_ids:append(id)
        end  
        
        -- 检查牌堆是否为空  
        if card_ids:length() == 0 then  
            return false
        end  
        
        -- 使用AG界面让玩家选择一张牌  
        room:fillAG(card_ids, player)  
        local card_id = room:askForAG(player, card_ids, true, "shenduan")  
        room:clearAG(player) 

        if card_id >= 0 then  
            local card = sgs.Sanguosha:getCard(card_id)  
            room:broadcastSkillInvoke(self:objectName(), player)  
            room:retrial(card, player, judge, self:objectName(), false)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        judge:updateResult()  
        return false  
    end  
}
]]
-- 添加技能给武将  
baozhen:addSkill(pingyuan)  
baozhen:addSkill(shenduan)  

-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["baozhen"] = "包拯",  

    ["pingyuan"] = "平冤",  
    [":pingyuan"] = "锁定技，当你血量变化时，你摸一张牌。",
    ["shenduan"] = "神断",  
    [":shenduan"] = "出牌阶段，你可以将手牌放入“神断”牌堆。判定生效前，你可以使用该牌堆的牌改判",
    [":shenduan"] = "出牌阶段限2次，你可以将弃置一张手牌，获得一个“神断”标记。判定生效前，你可以（1）弃置1个“神断”标记改变判定牌的花色或点数（2）弃置2个“神断”标记同时改变判定牌的花色和点数",
    ["@shenduan"] = "神断",  
    ["suit"] = "花色",
    ["number"] = "数字",
    ["both"] = "花色+数字",
}  

-- 创建伯乐武将  
bole = sgs.General(extension, "bole", "shu", 4)  
-- 创建相马技能卡  
shicaiSlashCard = sgs.CreateSkillCard{  
    name = "shicaiSlashCard",  
    target_fixed = false,--是否需要指定目标，默认false，即需要
    will_throw = false,
    filter = function(self, targets, to_select)  
        -- 第一个目标是接收手牌并使用杀的角色  
        if #targets == 0 then  
            return to_select:objectName() ~= sgs.Self:objectName()  
        end
        --[[
        -- 第二个目标是被使用杀的角色  
        elseif #targets == 1 then  
            return to_select:objectName() ~= targets[1]:objectName() --and to_select:objectName() ~= sgs.Self:objectName() 
        end  
        ]]
        return false  
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1 --1
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 获取两个目标角色  
        local target = targets[1]  --  接收手牌并使用杀的角色 
        --local victim = targets[2]  --  被使用杀的角色
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "shicaiSlash")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("shicaiSlash")  
          
        -- 将手牌交给目标角色  
        local move = sgs.CardsMoveStruct()  
        move.card_ids = self:getSubcards()  
        move.to = target  
        move.to_place = sgs.Player_PlaceHand  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "shicaiSlash", "")  
        room:moveCardsAtomic(move, true)  
          
        local victim = room:askForPlayerChosen(source,  room:getOtherPlayers(target), self:objectName())
        -- 询问目标是否对victim使用杀  
        local prompt = string.format("@shicaiSlash-slash:%s:%s:", victim:objectName(), target:objectName())  
        if not room:askForUseSlashTo(target, victim, prompt, false, false, false) then  
            -- 如果目标不使用杀，则弃置其两张牌  
            --[[
            if not target:isNude() then  
                local count = math.min(2, target:getCardCount(true))  
                --room:askForDiscard(target, "shicaiSlash", count, count, false, true)
                
                local dummy_reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, source:objectName(), target:objectName(), "shicaiSlash", "")  
                card_ids = room:askForCardsChosen(source, target, "he", "shicaiSlash", count, count)  
                
                if #card_ids > 0 then  
                    room:throwCard(sgs.CardsMoveStruct(card_ids, target, source, sgs.Player_PlaceHand, sgs.Player_DiscardPile, dummy_reason))  
                end  
            end
            ]]
            if source:canDiscard(target, "he") then
                room:throwCard(room:askForCardChosen(source, target, "he", self:objectName(), false, sgs.Card_MethodDiscard), target, source)
            end
            if source:canDiscard(target, "he") then
                room:throwCard(room:askForCardChosen(source, target, "he", self:objectName(), false, sgs.Card_MethodDiscard), target, source)
            end  
        end  
    end  
}  
-- 创建相马视为技  
shicaiSlash = sgs.CreateOneCardViewAsSkill{  
    name = "shicaiSlash",  
    filter_pattern = ".|.|.|hand",  
      
    view_as = function(self, card)  
        local xc = shicaiSlashCard:clone()  
        xc:addSubcard(card)  
        xc:setShowSkill(self:objectName())  
        return xc  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#shicaiSlashCard") and not player:isKongcheng()  
    end  
}  
  
--创建拒马
function sgs.CreatexiangmaSkill(name) --创建拒马技能，在CreateDistanceSkill函数基础上建立的函数
	local xiangma_skill = {}
	xiangma_skill.name = name
	xiangma_skill.correct_func = function(self, from, to)
		if to:hasShownSkill(self) then --hasSkill
			return 1
		end
		return 0
	end
	return sgs.CreateDistanceSkill(xiangma_skill)
end
xiangma = sgs.CreatexiangmaSkill("xiangma") 

bole:addSkill(shicaiSlash)  
bole:addSkill(xiangma)  --或者直接使用飞影

-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
      
    ["bole"] = "伯乐",  
    ["#bole"] = "千里马知己",  
    ["shicaiSlash"] = "试才",  
    [":shicaiSlash"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色，令其对你指定的另一名角色使用【杀】，若其不使用【杀】，你弃置其两张牌。",  
    ["shicaiSlashCard"] = "试才",  
    ["@shicaiSlash-slash"] = "请对 %src 使用一张【杀】，否则 %dest 将弃置你两张牌",  

    ["xiangma"] = "相马",  
    [":xiangma"] = "锁定技，其他角色计算与你的距离+1。",  
}  


-- 创建武将：鬼谷子  
guiguzi = sgs.General(extension, "guiguzi", "shu", 3)  

yinju = sgs.CreateTriggerSkill{  
    name = "yinju",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        local damage = data:toDamage()  
        if damage.from and damage.from:distanceTo(player) > 1 then --距离计算方向不能反 
            return self:objectName()  
        end            
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  

        room:notifySkillInvoked(player, self:objectName())  
          
        local msg = sgs.LogMessage()  
        msg.type = "#guigu"  
        msg.from = player  
        msg.to:append(damage.from)  
        msg.arg = tostring(damage.damage)  
        msg.arg2 = self:objectName()  
        room:sendLog(msg)
          
        damage.damage = 0  
        damage.prevented = true
        data:setValue(damage)  
          
        return true  
          
    end,  
}

-- 创建传道技能卡  
guiguCard = sgs.CreateSkillCard{  
    name = "guiguCard",
    target_fixed = false,  
    will_throw = false,
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 获取目标角色  
        local target = targets[1]  
          
        -- 获取选择的杀牌数量  
        local slash_count = self:subcardsLength()  
          
        -- 如果没有选择杀牌，直接返回  
        if slash_count == 0 then return end  
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "guigu")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("guigu")  
          
        -- 将杀牌给目标角色  
        local move = sgs.CardsMoveStruct()  
        move.card_ids = self:getSubcards()  
        move.to = target  
        move.to_place = sgs.Player_PlaceHand  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "guigu", "")  
        room:moveCardsAtomic(move, true)  
          
        -- 摸等量的牌  
        source:drawCards(slash_count, "guigu")  
    end  
}  
  
-- 创建传道视为技  
guiguViewAsSkill = sgs.CreateViewAsSkill{  
    name = "guigu",  
      
    view_filter = function(self, selected, to_select)  
        -- 只能选择杀牌  
        return to_select:isKindOf("Slash")  
    end,  
      
    view_as = function(self, cards)  
        if #cards > 0 then  
            local card = guiguCard:clone()  
            for _, c in ipairs(cards) do  
                card:addSubcard(c)  
            end  
            return card  
        end  
        return nil  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 出牌阶段限一次  
        return not player:hasUsed("#guiguCard")  
    end  
}  
  
-- 创建传道技能  
guigu = sgs.CreateTriggerSkill{  
    name = "guigu",  
    view_as_skill = guiguViewAsSkill,  
    events = {},  -- 没有触发事件，纯视为技  
}

--guiguzi:addSkill(yinju)
guiguzi:addSkill(guigu)
guiguzi:addSkill("yuanyu")
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["guiguzi"] = "鬼谷子",
    ["#guiguzi"] = "纵横家", 
    ["yinju"] = "隐居",  
    [":yinju"] = "锁定技，当你受到伤害时，若伤害源与你的距离大于1，则伤害为0。",  

    ["guigu"] = "鬼谷",  
    [":guigu"] = "出牌阶段限1次。你可以将任意数量的杀给另一名角色，然后摸等量的牌",  
}

chairong = sgs.General(extension, "chairong", "wu", 4)

shenwuCard = sgs.CreateSkillCard{
    name = "shenwuCard",
    mute = true,
    target_fixed = false,
    will_throw = false,
    can_recast = false,
    
    filter = function(self, targets, to_select)
        -- 只能选择一名其他角色
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() --and not to_select:isKongcheng()
    end,
    
    feasible = function(self, targets)
        -- 必须选择一名目标
        return #targets == 1
    end,
    
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local subcards = self:getSubcards()
        local color = sgs.Sanguosha:getCard(subcards:first()):getColor()
        
        local target_cards = sgs.IntList()
        for _, card in sgs.qlist(target:getHandcards()) do
            if card:getColor()~=color then
                target_cards:append(card:getId())
            end
        end
        -- 创建卡牌移动结构
        local move1 = sgs.CardsMoveStruct()
        move1.card_ids = subcards
        move1.from = source
        move1.to = target
        move1.to_place = sgs.Player_PlaceHand
        move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                        source:objectName(), target:objectName(), "shenwuExchange", "")
        
        local move2 = sgs.CardsMoveStruct()
        move2.card_ids = target_cards
        move2.from = target
        move2.to = source
        move2.to_place = sgs.Player_PlaceHand
        move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                        target:objectName(), source:objectName(), "shenwuExchange", "")
        
        local moves = sgs.CardsMoveList()
        moves:append(move1)
        moves:append(move2)
        
        room:moveCardsAtomic(moves, true)
    end
}

shenwu = sgs.CreateViewAsSkill{  
    name = "shenwu",  
    n = 999,  
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then  
            return not to_select:isEquipped() and not to_select:hasFlag("using")  
        else  
            local first_color = selected[1]:isRed()  
            return to_select:isRed() == first_color and not to_select:hasFlag("using") and not to_select:isEquipped()
        end  
    end,  
    view_as = function(self, cards)  
        if #cards == 0 then return nil end  
          
        local first_color = cards[1]:isRed()  
        for _, card in ipairs(cards) do  
            if card:isRed() ~= first_color then  
                return nil  
            end  
        end  
          
        local hand_cards = sgs.Self:getHandcards()  
        local same_color_count = 0  
        for _, hand_card in sgs.qlist(hand_cards) do  
            if hand_card:isRed() == first_color then  
                same_color_count = same_color_count + 1  
            end  
        end  
          
        if #cards ~= same_color_count then  
            return nil  
        end  
          
        local new_card = shenwuCard:clone()
          
        for _, card in ipairs(cards) do  
            new_card:addSubcard(card)  
        end  
        new_card:setShowSkill(self:objectName())  
        new_card:setSkillName(self:objectName())  
        return new_card  
    end,  
    enabled_at_play = function(self, player)
        return not player:hasUsed("#shenwuCard") and not player:isKongcheng()
    end  
}  



shitu = sgs.CreateTriggerSkill{  
    name = "shitu",  
    events = {sgs.EventPhaseStart},  
    limit_mark = "@shitu",
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Start) then
            return ""
        end
        if player:hasSkill(self:objectName()) then
            room:setPlayerMark(player,"@shitu",0)
        else
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:getMark("@shitu")==0 and not owner:isKongcheng()) then 
                return ""
            end
            return self:objectName(), owner:objectName()
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            room:setPlayerMark(ask_who,"@shitu",1)
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local card_id = room:askForCardChosen(ask_who, ask_who, "h", self:objectName()) 
        room:obtainCard(player,card_id)
        room:setPlayerFlag(player,"shitu_target")
        room:setPlayerProperty(ask_who, "shitu_card_id", sgs.QVariant(tostring(card_id)))
        return false  
    end  
}
shitu_prohibit = sgs.CreateProhibitSkill{  
    name = "#shitu_prohibit",  
    is_prohibited = function(self, from, to, card)  
        if from and from:hasFlag("shitu_target") and to and to:hasSkill("shitu") and card then  
            local shitu_card_id = to:property("shitu_card_id"):toString()
            local color = sgs.Sanguosha:getCard(shitu_card_id):getColor() 
            if card:getColor() == color then  
                return true  
            end  
        end  
        return false  
    end  
}
chairong:addSkill(shenwu)
chairong:addSkill(shitu)
chairong:addSkill(shitu_prohibit)
sgs.LoadTranslationTable{
    ["chairong"] = "柴荣",
    ["shitu"] = "时图",
    [":shitu"] = "每轮限一次。其他角色的准备阶段，你可以交给其一张手牌，该角色本回合不能对你使用与此牌颜色相同的牌",
    ["shenwu"] = "神武",
    [":shenwu"] = "出牌阶段限一次。你可以将一种颜色的所有手牌交给另一名角色，然后获得其另一种颜色的所有手牌"
}

change = sgs.General(extension, "change", "wu", 3, false) --wu,qun  
  
-- 技能1：奔月 - 出牌阶段限一次，将装备牌视为无中生有 
-- 为了限制次数，必须写成技能卡
benyueCard = sgs.CreateSkillCard{  
    name = "benyue",  
    target_fixed = true,  
    will_throw = true,
    on_use = function(self, room, source, targets)  
        -- 无中生有的效果：摸两张牌  
        --room:drawCards(source, 2, "benyue")
        local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)  
        ex_nihilo:setSkillName("benyue")  
        local use = sgs.CardUseStruct(ex_nihilo, source, source)  
        room:useCard(use)  
        ex_nihilo:deleteLater()
    end  
}   
benyue = sgs.CreateOneCardViewAsSkill{  
    name = "benyue",  
    filter_pattern = "EquipCard",  
    view_as = function(self, card)  
        local ex_nihilo = benyueCard:clone() --sgs.Sanguosha:cloneCard("ex_nihilo")  
        ex_nihilo:addSubcard(card)  
        ex_nihilo:setSkillName(self:objectName())  
        return ex_nihilo  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#benyue")  
    end  
}  
  
-- 技能2：药引 - 将红桃牌视为桃  
yaoyin = sgs.CreateOneCardViewAsSkill{  
    name = "yaoyin",  
    filter_pattern = ".|heart",  
    view_as = function(self, card)  
        local peach = sgs.Sanguosha:cloneCard("peach")  
        peach:addSubcard(card)  
        peach:setSkillName(self:objectName())  
        return peach  
    end,  
    enabled_at_play = function(self, player)  
        return player:isWounded()  
    end,  
    enabled_at_response = function(self, player, pattern)  
        return string.find(pattern, "peach")  --pattern == "peach" or pattern == "peach+analeptic"
    end  
}  
  
-- 技能3：灵药 - 使用桃恢复体力后摸两张牌  
lingyao = sgs.CreateTriggerSkill{  
    name = "lingyao",  
    events = {sgs.HpRecover},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        change = room:findPlayerBySkillName(self:objectName())
        local recover = data:toRecover()  
        if change and change:isAlive() and recover.card and recover.card:isKindOf("Peach") and recover.who and recover.who:objectName()==change:objectName() then  
            -- 可以直接判断recover.who:hasSkill(self:objectName())  
            return self:objectName(), change:objectName()
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
        ask_who:drawCards(2, self:objectName())  
        return false  
    end  
}  
  
-- 将技能添加给武将  
change:addSkill(benyue)  
change:addSkill(yaoyin)  
change:addSkill(lingyao)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["change"] = "嫦娥",  
    ["#change"] = "月宫仙子", 

    ["benyue"] = "奔月",  
    [":benyue"] = "出牌阶段限一次，你可以将一张装备牌视为无中生有。",  
    ["yaoyin"] = "药引",  
    [":yaoyin"] = "你可以将红桃牌视为桃。",  
    ["lingyao"] = "灵药",  
    [":lingyao"] = "你使用桃后为任意角色恢复体力后，你可以摸两张牌。",  

    -- 技能台词
    ["$benyue1"] = "明月几时有，把酒问青天。",
    ["$benyue2"] = "嫦娥应悔偷灵药，碧海青天夜夜心。", 
    ["$yaoyin1"] = "此药可医百病，救人于危难。",
    ["$yaoyin2"] = "红桃入药，妙手回春。",
    ["$lingyao1"] = "灵药济世，功德无量。",
    ["$lingyao2"] = "药到病除，重获新生。",
    ["~change"] = "月宫虽美，终是寂寞…… ",
    
    -- 其他提示信息
    ["#lingyao"] = "%from 的技能【%arg】被触发，摸两张牌"
}  

chengyaojin = sgs.General(extension, "chengyaojin", "shu", 4)

kuangfuCard = sgs.CreateSkillCard{  
    name = "kuangfuCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:isNude()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local card_id = room:askForCardChosen(source, target, "he", self:objectName())
        room:throwCard(card_id, target, source)
        room:setPlayerFlag(source, "kuangfu")
    end  
}  
  
-- 拒绝谏言视为技  
kuangfuRange = sgs.CreateViewAsSkill{  
    name = "kuangfuRange",  
      
    view_filter = function(self, selected, to_select)  
        return #selected == 0  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = kuangfuCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())
            return card  
        end  
        return nil  
    end, 
    
    enabled_at_play = function(self, player)  
        return not player:isNude() and not player:hasUsed("#kuangfuCard")
    end  
}  
  
kuangfuRange_range = sgs.CreateAttackRangeSkill{  
    name = "#kuangfuRange-range",  
    extra_func = function(self, player, include_weapon)  
        if player:hasFlag("kuangfu") then  
            return 3  
        end  
        return 0  
    end  
}  

qixiKongcheng = sgs.CreateTriggerSkill{  
    name = "qixiKongcheng",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:hasSkill(self:objectName()) and damage.to and damage.to:isKongcheng() then --距离计算方向不能反 
            return self:objectName(), damage.from:objectName()
        end            
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()       
        damage.damage = damage.damage + 1
        data:setValue(damage)  
        return false  
    end,  
}

chengyaojin:addSkill(kuangfuRange)
chengyaojin:addSkill(kuangfuRange_range)
chengyaojin:addSkill(qixiKongcheng)
sgs.LoadTranslationTable{
    ["chengyaojin"] = "程咬金",
    ["kuangfuRange"] = "狂斧",
    [":kuangfuRange"] = "出牌阶段限一次，你可以弃置1张牌，然后弃置1名其他角色1张牌，并令本回合攻击距离+3",
    ["qixiKongcheng"] = "奇袭",
    [":qixiKongcheng"] = "你的杀造成伤害时，若目标没有手牌，你可以令该杀伤害+1"
}

daji = sgs.General(extension, "daji", "qun", 3, false)  -- 吴国，4血，男性  

meiguo = sgs.CreateProhibitSkill{  --不能指定为目标，不是取消目标
    name = "meiguo",  
    is_prohibited = function(self, from, to, card)  
        if to:hasShownSkill(self:objectName()) and card:isKindOf("Slash") and card:isBlack() then  
            return true  
        end  
        return false  
    end  
}

shixin = sgs.CreateTriggerSkill{  
    name = "shixin",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and   
           player:getPhase() == sgs.Player_Finish then  
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
        local judge = sgs.JudgeStruct()  
        judge.pattern = "."  
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = player  
          
        room:judge(judge)  
          
        if judge.card:isBlack() then  
            -- 黑色：弃置一名角色一张牌  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if not p:isNude() and not player:isFriendWith(p) then  
                    targets:append(p)  
                end  
            end  
              
            if not targets:isEmpty() then  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shixin-discard")  
                if target then  
                    local card_id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
                    room:throwCard(card_id, target, player)  
                end  
            end  
        else  
            -- 红色：令一名角色从牌堆获得一张红桃牌  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if player:isFriendWith(p) then
                    targets:append(p)  
                end
            end  
              
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shixin-draw")  
            if target then  
                local cards = sgs.IntList()  
                local ids = room:getNCards(10, false)  
                for _, id in sgs.qlist(ids) do  
                    local card = sgs.Sanguosha:getCard(id)  
                    if card:getSuit() == sgs.Card_Heart then  
                        cards:append(id)  
                        break  
                    end  
                end  
                  
                if cards:length() > 0 then  
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, target:objectName(), self:objectName(), "")  
                    room:obtainCard(target, cards:first())--, self:objectName(), true)  
                end  
                  
                -- 将其余牌放回牌堆底  
                room:returnToTopDrawPile(ids)  
            end  
        end  
          
        return false  
    end  
}

daji:addSkill(meiguo)
daji:addSkill(shixin)
sgs.LoadTranslationTable{
    ["#daji"] = "千年狐妖",  
    ["daji"] = "妲己",  
    ["meiguo"] = "媚国",  
    [":meiguo"] = "锁定技，你不能成为黑色【杀】的目标。",  
    ["shixin"] = "噬心",  
    [":shixin"] = "回合结束时，你可以进行一次判定，若判定牌为黑色，你可以弃置一名其他势力角色一张牌；若判定牌为红色，你可以令一名相同势力角色从牌堆获得一张红桃牌。",  
    ["@shixin-discard"] = "请选择一名角色，弃置其一张牌",  
    ["@shixin-draw"] = "请选择一名角色，令其从牌堆获得一张红桃牌" 
}

dayu = sgs.General(extension, "dayu", "wu", 3)  
  
zhuding = sgs.CreateTriggerSkill{  
    name = "zhuding",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.frequency,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and not player:isKongcheng() then  
            return self:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            --local card_id = room:askForCardChosen(player, player, "h", "@zhuding-discard")  
            --[[
            local card = sgs.Sanguosha:getCard(card_id)  
            if card:isBlack() then  
                room:broadcastSkillInvoke(self:objectName())  
                return true  
            end  
            ]]
            return room:askForCard(player, ".|black", "@zhuding-discard", data, sgs.Card_MethodDiscard)  
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
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhuding-target", false)  
        if target then  
            --room:addPlayerMark(target, "@ding", 1)  
            room:setPlayerMark(target, "@ding", target:getMark("@ding")+1)
            room:acquireSkill(target, "ding", false) 
        end  
        return false  
    end  
}

zhuding_draw = sgs.CreateDrawCardsSkill{  
    name = "ding",  
    draw_num_func = function(self, player, n)  
        return n + math.min(player:getMark("@ding"),3)
    end  
}  

-- 增鼎技能  
zhishui = sgs.CreateTriggerSkill{  
    name = "zhishui",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Start and player:getHandcardNum() >= 4 then  
            dayu = room:findPlayerBySkillName(self:objectName())
            if dayu and dayu:isAlive() then
                return self:objectName(), dayu:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local skill_owner = ask_who  
          
        if skill_owner and skill_owner:askForSkillInvoke("zhishui", data) then--sgs.QVariant():fromValue(player)) then  
            room:broadcastSkillInvoke("zhishui")  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local skill_owner = ask_who 
          
        if not player:isAllNude() then  
            local card_id = room:askForCardChosen(skill_owner, player, "hej", "zhishui")  
            room:throwCard(card_id, player, skill_owner)  
        end  
          
        if player:getMark("@ding") > 0 then  
            --player:addMark("@ding")  
            room:setPlayerMark(player, "@ding", player:getMark("@ding")+1) 
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
dayu:addSkill(zhuding)  
dayu:addSkill(zhuding_draw)  
dayu:addSkill(zhishui)  
--extension:insertRelatedSkills("zhuding", "#zhuding_draw")
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["dayu"] = "大禹",  
    ["zhuding"] = "铸鼎",  
    [":zhuding"] = "准备阶段，你可以弃置一张黑色手牌，令一名相同势力角色获得一个'鼎'标记。",  
    ["ding"] = "鼎",  
    [":ding"] = "拥有'鼎'的角色摸牌阶段摸牌数+X，X为'鼎'的数量，且至多为3",  
    ["zhishui"] = "治水",  
    [":zhishui"] = "任意一名角色准备阶段，若其手牌数大于等于4，你可以弃置其一张牌，若其有'鼎'，其'鼎'标记+1。",  
    ["@zhuding-discard"] = "铸鼎：弃置一张黑色手牌",  
    ["@zhuding-target"] = "铸鼎：选择一名角色获得'鼎'标记"  
}  

dianwei_hero = sgs.General(extension, "dianwei_hero", "wei", 3)  

zhonghu = sgs.CreateTriggerSkill{  
    name = "zhonghu",  
    events = {sgs.EventPhaseStart, sgs.Damaged},  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@zhonghu",  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            if not (player and player:isAlive()) then
                return ""
            end
            if player:hasSkill(self:objectName()) then
                if player:getPhase() == sgs.Player_Start then --自己准备阶段清除标记
                    room:setPlayerMark(player,"@zhonghu",1)
                    --把标记清除掉
                    for _,p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getMark("@hu") > 0 then
                            room:setPlayerMark(p,"@hu",0)
                        end
                    end
                end
            end
            if player:getPhase() == sgs.Player_Play then
                local source = room:findPlayerBySkillName(self:objectName())
                if not (source and source:isAlive() and source:getMark("@zhonghu")>0) then 
                    return ""
                end
                return self:objectName(), source:objectName()
            end
        elseif event == sgs.Damaged then  
            -- 当角色受到伤害后  
            local damage = data:toDamage()  
            if damage.from and damage.from:isAlive() and damage.to:getMark("@hu")>0 then  
                -- 寻找拥有此技能的角色  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:hasSkill(self:objectName()) and not p:isKongcheng() then  
                        return self:objectName(), p:objectName()
                    end  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            return ask_who:askForSkillInvoke(self:objectName(), data)
        elseif event == sgs.Damaged then  
            local damage = data:toDamage()  
            local _data = sgs.QVariant()  
            _data:setValue(damage.from)  
            if ask_who:askForSkillInvoke(self:objectName(), _data) then  
                room:broadcastSkillInvoke(self:objectName())  
                return true  
            end  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            local target = room:askForPlayerChosen(ask_who, room:getAlivePlayers(), self:objectName(), "@zhonghu-invoke", true, true)  
            if target then  
                room:setPlayerMark(ask_who, "@zhonghu", 0)
                room:setPlayerMark(target, "@hu", 1)  
            end  
        elseif event == sgs.Damaged then  
            local damage = data:toDamage()  
            -- 弃置1张手牌  
            if room:askForDiscard(ask_who, self:objectName(), 1, 1, true, false) then
                -- 视为对伤害来源使用1张杀  
                if damage.from and damage.from:isAlive() and not ask_who:isProhibited(damage.from, sgs.Sanguosha:cloneCard("slash")) then  
                    local slash = sgs.Sanguosha:cloneCard("slash")  
                    slash:setSkillName(self:objectName())  
                    local use = sgs.CardUseStruct()  
                    use.from = ask_who  
                    use.to:append(damage.from)  
                    use.card = slash  
                    room:useCard(use, false)
                    slash:deleteLater()
                end  
            end
        end  
        return false  
    end  
}

kuangzhan = sgs.CreateTriggerSkill{  
    name = "kuangzhan",  
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
        elseif event == sgs.CardResponded then  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        if card and card:isKindOf("Slash") then  
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
        player:drawCards(1, self:objectName())  
        return false  
    end  
}

dianwei_hero:addSkill(zhonghu)  
dianwei_hero:addSkill(kuangzhan)


sgs.LoadTranslationTable{
    ["#dianwei_hero"] = "古之恶来",  
    ["dianwei_hero"] = "典韦",  
    ["illustrator:dianwei_hero"] = "未知",  
    ["zhonghu"] = "忠护",  
    [":zhonghu"] = "每轮限一次，任意角色出牌阶段开始时，你可以指定1名角色，令其获得1个'护'标记，直到你下回合开始。该角色受到伤害后，你可以弃置1张手牌，视为对伤害来源使用1张杀。",  
    ["@zhonghu"] = "忠护",  
    ["@zhonghu-invoke"] = "忠护：你可以选择一名角色，令其获得'护'标记",  
    ["kuangzhan"] = "狂战",  
    [":kuangzhan"] = "你每使用或打出1张杀，摸1张牌。",  
}

diaochan_hero = sgs.General(extension, "diaochan_hero", "qun", 3, false)  -- 群雄，3血  
lijianSlashCard = sgs.CreateSkillCard{  
    name = "lijianSlash",  
    target_fixed = false,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:hasShownOneGeneral() and to_select:isMale()
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 将牌交给目标角色  
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "lijianSlash", "")  
        room:moveCardTo(self, target, sgs.Player_PlaceHand, reason)  
                  
        -- 选择拼点的另一名角色  
        local others = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(target)) do  
            if p:objectName() ~= source:objectName() and not p:isKongcheng() and p:hasShownOneGeneral() and p:isMale() then  
                others:append(p)  
            end  
        end  
          
        if others:isEmpty() then return end  
          
        local pindian_target = room:askForPlayerChosen(source, others, "lijianSlash", "@lijianSlash-pindian", false)  
        if pindian_target then  
            -- 进行拼点  
            target:pindian(pindian_target, "lijianSlash", nil)  
        end  
    end  
}  
  
-- 密诏视为技  
lijianSlashViewAsSkill = sgs.CreateViewAsSkill{  
    name = "lijianSlash",  
      
    view_filter = function(self, selected, to_select)  
        return #selected < sgs.Self:getHandcardNum()
    end,  
      
    view_as = function(self, cards)  
        if #cards ~= sgs.Self:getHandcardNum() then return nil end  
                    
        local card = lijianSlashCard:clone()  
        for _, c in ipairs(cards) do  
            card:addSubcard(c)  
        end  
        card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#lijianSlash") and not player:isKongcheng()
    end  
}  
  
-- 密诏触发技能（处理拼点后的效果）  
lijianSlash = sgs.CreateTriggerSkill{  
    name = "#lijianSlash-trigger",  
    events = {sgs.Pindian},  
    --global = true,  
      
    can_trigger = function(self, event, room, player, data)  
        local pindian = data:toPindian()  
        if pindian.reason == "lijianSlash" then  
            local winner = nil  
            local loser = nil  
            if pindian.from_number == pindian.to_number then  
                return false
            end
              
            if pindian.from_number > pindian.to_number then  
                winner = pindian.from  
                loser = pindian.to  
            else  
                winner = pindian.to  
                loser = pindian.from  
            end  
              
            if winner and loser and winner:isAlive() and loser:isAlive() then  
                -- 赢家视为对输家使用一张杀  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName("lijianSlash")  
                if winner:canSlash(loser, slash, false) then  
                    local use = sgs.CardUseStruct()  
                    use.from = winner  
                    use.to:append(loser)  
                    use.card = slash  
                      
                    room:useCard(use, false)    
                end  
                slash:deleteLater()
            end  
        end  
          
        return false  
    end  
} 

--diaochan_hero:addSkill("mizhao")
diaochan_hero:addSkill(lijianSlash)
diaochan_hero:addSkill(lijianSlashViewAsSkill)
diaochan_hero:addSkill("jieming")
sgs.LoadTranslationTable{  
    ["diaochan_hero"] = "貂蝉",
    ["lijianSlash"] = "离间",
    [":lijianSlash"] = "出牌阶段限1次。你可以将所有手牌交给一名其他男性角色，令其与另一名男性角色拼点，赢的角色视为对输的角色使用1张杀"
}

direnjie = sgs.General(extension, "direnjie", "qun", 3)  -- 吴国，4血，男性  

jujianSnatchCard = sgs.CreateSkillCard{
    name = "jujianSnatchCard",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:isKongcheng() 
    end,  
      
    on_use = function(self, room, source, targets)
        local card = room:askForCardChosen(source, targets[1], "h", self:objectName())
        room:setPlayerMark(source, "jujian_card1", card)
        room:obtainCard(source, card)
        --local give_target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), "@jujianSnatch", true)
        --room:obtainCard(give_target, card)
    end
}

jujianSnatch = sgs.CreateOneCardViewAsSkill{
    name = "jujianSnatch",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skill_card = jujianSnatchCard:clone()
        skill_card:addSubcard(card:getId())
        skill_card:setShowSkill(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#jujianSnatchCard") and not player:isKongcheng()
    end
}

jujianAsk = sgs.CreateTriggerSkill{
    name = "#jujianAsk",
    events = {sgs.CardsMoveOneTime},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) and player:getPhase() == sgs.Player_Play then
            local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move and move.to and move.to:objectName() == player:objectName()then
                    local ids = sgs.IntList()
                    local isCard = false
					for _, id in sgs.qlist(move.card_ids) do
						if not isCard then
                            if player:getMark("jujian_card1") == id then
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

shentan = sgs.CreateOneCardViewAsSkill{  
    name = "shentan",  
    filter_pattern = ".|.|.|hand",  -- 梅花手牌  
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
--direnjie:addSkill(shentan) 
direnjie:addSkill("kanpo") 
direnjie:addSkill(jujianSnatch)
direnjie:addSkill(jujianAsk)
extension:insertRelatedSkills("jujianSnatch", "#jujianAsk")  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["direnjie"] = "狄仁杰",
    ["jujianSnatch"] = "举荐",
    [":jujianSnatch"] = "出牌阶段限一次，你可以弃置一张手牌，选择1名角色一张手牌，然后你可以将这张牌交给任意一名角色",
    ["shentan"] = "神探",
    [":shentan"] = "你的任意一张手牌可以视为无懈可击"
}  
  
-- 创建武将：东方朔  
dongfangshuo = sgs.General(extension, "dongfangshuo", "qun", 3)  -- 群雄，3血  
  
-- 技能1：谋略 - 准备阶段，你可以进行一次判定，若判定牌为黑色，你可以获得该判定牌  
cifu = sgs.CreateTriggerSkill{  
    name = "cifu",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        if player:getPhase() == sgs.Player_Start then  
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
        -- 进行判定  
        local judge = sgs.JudgeStruct()  
        judge.pattern = ".|black" -- 判定牌点数小于7。第一个点表示任意类型，第二个点表示任意花色
        judge.good = true -- 判定成功对玩家有利  
        judge.play_animation = true  
        judge.who = player  
        judge.reason = self:objectName()  
          
        room:judge(judge)  
          
        -- 如果判定牌为黑色，可以获得该判定牌  
        if judge.card:isBlack() then
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if player:isFriendWith(p) then
                    targets:append(p)  
                end
            end  
            target = room:askForPlayerChosen(player, targets, self:objectName())
            target:obtainCard(judge.card)
        elseif judge.card:isRed() then
            choice = room:askForChoice(player,"cifu","top+to_discard")
            if choice == "top" then
                room:moveCardTo(judge.card, nil, sgs.Player_DrawPile, true) 
            end
        end  
          
        return false  
    end  
}  
  
-- 技能2：智谋 - 若你的判定牌的点数小于7，你可以摸一张牌  
zhisheng = sgs.CreateTriggerSkill{  
    name = "zhisheng",  
    events = {sgs.FinishJudge},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not player then  
            return false  
        end  
          
        local judge = data:toJudge() 
        owner = room:findPlayerBySkillName(self:objectName()) 
        if judge.card:getNumber() < 7 then  
            return self:objectName(), owner:objectName()
        end  
          
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 摸一张牌  
        ask_who:drawCards(1)  
          
        -- 显示摸牌提示  
        local msg = sgs.LogMessage()  
        msg.type = "#zhishengDraw"  
        msg.from = ask_who  
        msg.arg = 1  
        msg.arg2 = self:objectName()  
        room:sendLog(msg)  
          
        return false  
    end  
}  
  
-- 添加技能给武将  
dongfangshuo:addSkill(cifu)  
dongfangshuo:addSkill(zhisheng)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["dongfangshuo"] = "东方朔",  
    ["#dongfangshuo"] = "东方朔",
    ["cifu"] = "辞赋",  
    [":cifu"] = "准备阶段，你可以进行一次判定，若判定牌为黑色，你可以令一名相同势力角色获得该判定牌；若为红色，你可以选择放在牌堆顶或弃牌堆",  
    ["cifu_obtain"] = "谋略获得",  
      
    ["zhisheng"] = "智圣",  
    [":zhisheng"] = "若判定牌的点数小于7，你可以摸一张牌。",  
    ["#zhishengDraw"] = "%from 发动了【%arg2】，摸了 %arg 张牌",  
      
    ["~dongfangshuo"] = "智谋万千，终难逃此劫。"  
}


-- 创建武将  
dufu = sgs.General(extension, "dufu", "shu", 3)  --libai珠联璧合

shisheng = sgs.CreateTriggerSkill{  
    name = "shisheng",  
    events = {sgs.DrawNCards},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
           --and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        --player:skip(sgs.Player_Draw)
        local count = data:toInt()
        data:setValue(0)

        top_cards=room:getNCards(4)
        room:askForGuanxing(player, top_cards, sgs.Room_GuanxingUpOnly)-- GuanxingUpOnly, GuanxingBothSides, GuanxingDownOnly
        
        local drawn_suits = {}  -- 记录已获得的花色  
        local drawn_cards = {}  -- 记录获得的卡牌  
        --循环方法一
        for i=1,4 do  
            -- 从牌堆顶获得一张牌  
            local card_id = room:drawCard()  
            if not card_id then break end  -- 牌堆空了  
            
            local card = sgs.Sanguosha:getCard(card_id)  
            local suit = card:getSuit()  
            -- 检查是否已经获得过这个花色  
            if drawn_suits[suit] then  
                -- 出现重复花色，结束循环  
                --room:obtainCard(player, card_id)  
                --card = player:getHandcards():last()
                --room:moveCardTo(card, nil, sgs.Player_DrawPile, true)
                break  
            else  
                -- 记录新花色  
                drawn_suits[suit] = true  
            end                  
            -- 将卡牌加入手牌  
            room:obtainCard(player, card_id)  
            table.insert(drawn_cards, card)  
        end  
        return false  
    end,  
}
beimin = sgs.CreateTriggerSkill{  
    name = "beimin",  
    events = {sgs.EventPhaseEnd},  
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
        if player:askForSkillInvoke(self:objectName(),data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        -- 进行判定  
        local judge = sgs.JudgeStruct()  
        judge.pattern = ".|.|1~6" -- 判定牌点数小于7。第一个点表示任意花色，第二个点表示任意类型
        judge.good = true -- 判定成功对玩家有利  
        judge.reason = self:objectName()  
        judge.who = player  
        judge.play_animation = false  
          
        room:judge(judge)  
          
        -- 如果判定牌小于7，获得摸牌堆2张大于等于7的牌  
        if judge.card:getNumber() < 7 then  
            local cards_to_get = sgs.IntList()  
            local draw_pile = room:getDrawPile()  
            local count = 0  
              
            -- 从摸牌堆中寻找大于等于7的牌  
            for i = 0, draw_pile:length() - 1 do  
                if count >= 2 then break end  
                local card_id = draw_pile:at(i)  
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:getNumber() >= 7 then  
                    cards_to_get:append(card_id)  
                    count = count + 1  
                end  
            end  
              
            -- 获得找到的牌  
            if not cards_to_get:isEmpty() then  
                local dummy = sgs.DummyCard()  
                for i = 0, cards_to_get:length() - 1 do  
                    dummy:addSubcard(cards_to_get:at(i))  
                end  
                  
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD,   
                    player:objectName(), self:objectName(), "")  
                room:obtainCard(player, dummy, reason)  
                dummy:deleteLater()  
            end  
        end  
          
        return false  
    end  
}
dufu:addSkill(shisheng)
dufu:addSkill(beimin)
sgs.LoadTranslationTable{
    ["dufu"] = "杜甫",  

    ["shisheng"] = "诗圣",  
    [":shisheng"] = "摸牌阶段，你可以改为查看牌堆顶4张牌，以任意顺序排列，然后依次翻开，你获得花色互不相同的所有牌",  
    ["beimin"] = "悲悯",
    [":beimin"] = "回合结束时，你可以发起一次判定，若判定牌小于7，你从牌堆获得2张大于等于7的牌"
}

fanli = sgs.General(extension, "fanli", "wu", 3)  
--[[
quancaiVS = sgs.CreateViewAsSkill{  
    name = "quancai",  
    n = 2,  
    view_filter = function(self, selected, to_select)  
        if to_select:isEquipped() then return false end --必须是手牌，不能是装备区的牌
        if #selected == 0 then 
            if sgs.Self:hasFlag("quancai_black") and sgs.Self:hasFlag("quancai_mix") and to_select:isBlack() then return false end
            if sgs.Self:hasFlag("quancai_red") and sgs.Self:hasFlag("quancai_mix") and to_select:isRed() then return false end
            return true
        end
        if #selected >= 2 then return false end
        if #selected == 1 then
            if selected[1]:isBlack() then --第一张是黑色
                if to_select:isBlack() and sgs.Self:hasFlag("quancai_black") then return false end
                if to_select:isRed() and sgs.Self:hasFlag("quancai_mix") then return false end
                return true
            elseif selected[1]:isRed() then --第一张是红色
                if to_select:isBlack() and sgs.Self:hasFlag("quancai_mix") then return false end
                if to_select:isRed() and sgs.Self:hasFlag("quancai_red") then return false end
                return true
            end
        end
    end,  
    view_as = function(self, cards)  
        if #cards == 2 then  
            local card_name = ""
            if cards[1]:getColor() == cards[2]:getColor() then
                if cards[1]:isBlack() then 
                    if not sgs.Self:hasFlag("quancai_black") then card_name = "snatch" end
                elseif cards[1]:isRed() then
                    if not sgs.Self:hasFlag("quancai_red") then card_name = "ex_nihilo" end
                end
            else
                if not sgs.Self:hasFlag("quancai_mix") then card_name = "duel" end
            end
            if card_name == "" then return nil end
            local card = sgs.Sanguosha:cloneCard(card_name)
            for _, c in ipairs(cards) do  
                card:addSubcard(c:getId())  
            end  
            card:setSkillName("quancai")  
            card:setShowSkill("quancai")  
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return not (player:hasFlag("quancai_black") and player:hasFlag("quancai_red") and player:hasFlag("quancai_mix"))
    end,  
}  

quancai = sgs.CreateTriggerSkill{  
    name = "quancai",  
    events = {sgs.CardUsed},
    view_as_skill = quancaiVS,
    --frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local use = data:toCardUse()  
            if use.card and use.card:getSkillName() == "quancai" then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()
        local card = use.card
        if card:isKindOf("snatch") then
            room:setPlayerFlag(player,"quancai_black")
        elseif card:isKindOf("ex_nihilo") then
            room:setPlayerFlag(player,"quancai_red")
        elseif card:isKindOf("duel") then
            room:setPlayerFlag(player,"quancai_mix")
        end
        return false  
    end  
}  
]]


quancaiRedCard = sgs.CreateSkillCard{  
    name = "quancaiRedCard",  
    target_fixed = true,  
    will_throw = true,  
    on_use = function(self, room, source, targets)  
        --room:drawCards(source, 2, "quancai")  
        local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)  
        ex_nihilo:setSkillName("quancai")  
        local use = sgs.CardUseStruct(ex_nihilo, source, source)  
        room:useCard(use)  
        ex_nihilo:deleteLater()
    end  
}  
  
quancaiBlackCard = sgs.CreateSkillCard{  
    name = "quancaiBlackCard",   
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:isAllNude() and sgs.Self:distanceTo(to_select) == 1
    end,  
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        --local card_id = room:askForCardChosen(effect.from, effect.to, "hej", "quancai")  
        --room:obtainCard(effect.from, card_id, false)
        local snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0)  
        snatch:setSkillName("quancai")  
        local use = sgs.CardUseStruct(snatch, effect.from, effect.to)  
        room:useCard(use)  
        snatch:deleteLater()
    end  
}  
  
quancaiMixCard = sgs.CreateSkillCard{  
    name = "quancaiMixCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)  
        duel:setSkillName("quancai")  
        local use = sgs.CardUseStruct(duel, effect.from, effect.to)  
        room:useCard(use)  
        duel:deleteLater()
    end  
}  

quancai = sgs.CreateViewAsSkill{  
    name = "quancai",  
    n = 2,  
    view_filter = function(self, selected, to_select)  
        if to_select:isEquipped() then return false end --必须是手牌，不能是装备区的牌
        if #selected == 0 then 
            if sgs.Self:hasUsed("#quancaiBlackCard") and sgs.Self:hasUsed("#quancaiMixCard") and to_select:isBlack() then return false end
            if sgs.Self:hasUsed("#quancaiRedCard") and sgs.Self:hasUsed("#quancaiMixCard") and to_select:isRed() then return false end
            return true
        end
        if #selected >= 2 then return false end
        if #selected == 1 then
            if selected[1]:isBlack() then --第一张是黑色
                if to_select:isBlack() and sgs.Self:hasUsed("#quancaiBlackCard") then return false end
                if to_select:isRed() and sgs.Self:hasUsed("#quancaiMixCard") then return false end
                return true
            elseif selected[1]:isRed() then --第一张是红色
                if to_select:isBlack() and sgs.Self:hasUsed("#quancaiMixCard") then return false end
                if to_select:isRed() and sgs.Self:hasUsed("#quancaiRedCard") then return false end
                return true
            end
        end
    end,  
    view_as = function(self, cards)  
        if #cards == 2 then  
            local card = nil
            if cards[1]:getColor() == cards[2]:getColor() then
                if cards[1]:isBlack() then 
                    if not sgs.Self:hasUsed("#quancaiBlackCard") then card = quancaiBlackCard:clone() end
                elseif cards[1]:isRed() then
                    if not sgs.Self:hasUsed("#quancaiRedCard") then card = quancaiRedCard:clone() end
                end
            else
                if not sgs.Self:hasUsed("#quancaiMixCard") then card = quancaiMixCard:clone() end
            end
            if card == nil then return card end
            for _, c in ipairs(cards) do  
                card:addSubcard(c:getId())  
            end  
            --card:setSkillName("quancai")  
            card:setShowSkill("quancai")  
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return not (player:hasUsed("#quancaiRedCard") and player:hasUsed("#quancaiBlackCard") and player:hasUsed("#quancaiMixCard"))
    end,  
}  

shiyong4 = sgs.CreateTriggerSkill{  
    name = "shiyong4",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local use = data:toCardUse()  
            if use.card and use.card:getSkillName() ~= "" and use.card:getTypeId() ~= sgs.Card_TypeSkill then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        room:drawCards(player, 1, self:objectName())  
        return false  
    end  
}  
  
-- 添加技能到武将  
fanli:addSkill(quancai)  
fanli:addSkill(shiyong4)  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["fanli"] = "范蠡",  
    ["quancai"] = "全才",  
    [":quancai"] = "出牌阶段每项限一次。你可以将两张红色手牌视为【无中生有】，两张黑色手牌视为【顺手牵羊】，一红一黑两张手牌视为【决斗】。",  
    
    ["shiyong4"] = "时用",  
    [":shiyong4"] = "锁定技，你使用转化牌时，你摸一张牌。"  
}  

-- 创建范增武将  
fanzeng = sgs.General(extension, "fanzeng", "wei", 3) -- 群雄，3血  
  
-- 奇谋技能实现  
qimou = sgs.CreateTriggerSkill{  
    name = "qimou",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        local fanzeng_player = room:findPlayerBySkillName(self:objectName())
		local current = room:getCurrent()
        if fanzeng_player:objectName()==current:objectName() then
            room:setPlayerMark(fanzeng_player,"@qimou",0)
            return ""
        end
        if fanzeng_player and fanzeng_player:isAlive() and fanzeng_player:getMark("@qimou")==0 and current:getPhase() == sgs.Player_Play and not current:isKongcheng() then  
            return self:objectName(), fanzeng_player:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local fanzeng_player = ask_who--room:findPlayerBySkillName(self:objectName())  
        if fanzeng_player:askForSkillInvoke(self:objectName(), data) then  
            room:setPlayerMark(fanzeng_player,"@qimou",1)
            room:notifySkillInvoked(fanzeng_player, self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local fanzeng_player = ask_who--room:findPlayerBySkillName(self:objectName())  
          
        local card_id = room:askForCardChosen(fanzeng_player, player, "h", self:objectName())  
        room:showCard(player, card_id)
        local card = sgs.Sanguosha:getCard(card_id)  
          
        local choice = room:askForChoice(fanzeng_player, self:objectName(), "top+to_discard")  
        if choice == "top" then  
            room:moveCardTo(card, nil, sgs.Player_DrawPile, true)   
        else
            --room:moveCardTo(card, nil, sgs.Player_DiscardPile, true)   
            room:throwCard(card_id, player, player)  
        end  
          
        return false  
    end  
}  
  
-- 设伏技能实现  
shefu2 = sgs.CreateTriggerSkill{  
    name = "shefu2",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local fanzeng_player = room:findPlayerBySkillName(self:objectName())  
        if fanzeng_player and fanzeng_player:isAlive() and player:getPhase() == sgs.Player_Finish and not fanzeng_player:willBeFriendWith(player) then  
            return self:objectName(), fanzeng_player:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local fanzeng_player = ask_who--room:findPlayerBySkillName(self:objectName())  
        if fanzeng_player:askForSkillInvoke(self:objectName(), data) then  
            room:notifySkillInvoked(fanzeng_player, self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local card_ids = room:getNCards(1)  
        card = sgs.Sanguosha:getCard(card_ids:first())
        
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
        room:moveCardTo(card, nil, sgs.Player_DrawPile, true)                 

        local fanzeng_player = ask_who--room:findPlayerBySkillName(self:objectName())  
        if card:getTypeId() == sgs.Card_TypeBasic then  
            if fanzeng_player:isNude() or room:askForDiscard(fanzeng_player, self:objectName(), 1, 1, false, true) then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)  
                slash:setSkillName(self:objectName())  
                if fanzeng_player:canSlash(player, slash, false) then  
                    room:useCard(sgs.CardUseStruct(slash, fanzeng_player, player))  
                end
                slash:deleteLater()
            end
        end  
        return false  
    end  
}  
-- 为武将添加技能  
fanzeng:addSkill(qimou)  
fanzeng:addSkill(shefu2)  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄扩展包",  
      
    ["fanzeng"] = "范增",  
    ["#fanzeng"] = "亚父",  
      
    ["qimou"] = "奇谋",  
    [":qimou"] = "每轮限一次。任意一名角色的出牌阶段开始时，你可以展示其一张手牌，决定放在牌堆顶或弃牌堆。",  
    ["top"] = "置于牌堆顶",  
    ["to_discard"] = "置于弃牌堆",  
      
    ["shefu2"] = "设伏",  
    [":shefu2"] = "其他势力角色的结束阶段，你可以展示牌堆顶一张牌，若为基本牌，你可以弃置1张牌（无牌则不弃），视为你对该角色使用一张杀。",  
}  

gaojianli = sgs.General(extension, "gaojianli", "shu", 3)  

zhuji_vs = sgs.CreateViewAsSkill{  
    name = "zhuji",  
    n = 999, -- 可以选择所有手牌  
    view_filter = function(self, selected, to_select)  
        return #selected < sgs.Self:getHandcardNum() and not to_select:isEquipped() 
    end,  
    view_as = function(self, cards)  
        if #cards ~= sgs.Self:getHandcardNum() then return nil end  
        local slash = sgs.Sanguosha:cloneCard("slash")  
        slash:setSkillName("zhuji")  
        slash:setShowSkill("zhuji")  
        for _, card in ipairs(cards) do  
            slash:addSubcard(card)  
        end  
        return slash  
    end,  
    enabled_at_play = function(self, player)  
        return not player:isKongcheng() and sgs.Slash_IsAvailable(player)  
    end,  
    enabled_at_response = function(self, player, pattern)  
        return not player:isKongcheng() and pattern == "slash"  
    end  
}  
  
-- 易水触发技（处理造成伤害后的效果）  
zhuji = sgs.CreateTriggerSkill{  
    name = "zhuji",  
    events = {sgs.Damage},  
    view_as_skill = zhuji_vs,  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        --if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local damage = data:toDamage()  
        if damage.card and damage.card:getSkillName() == "zhuji" and damage.to and damage.to:isAlive() and not damage.to:isKongcheng() then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local _data = sgs.QVariant()  
        _data:setValue(damage.to)  
        if player:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.to and damage.to:isAlive() and not damage.to:isKongcheng() then  
            --room:throwCard(damage.to:getHandcards(), damage.to, player)
            damage.to:throwAllHandCards()
        end  
        return false  
    end  
}

lige = sgs.CreateTriggerSkill{  
    name = "lige",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local gaojianli = room:findPlayerBySkillName(self:objectName())  
        if gaojianli and gaojianli:isAlive() and gaojianli:isKongcheng()   
           and player:getPhase() == sgs.Player_Finish then  
            return self:objectName(), gaojianli:objectName()
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
        local discardPile = room:getDiscardPile()  
        --if discardPile:length() < 3 then return false end  
          
        -- 随机选择3张牌  
        local cards = sgs.IntList()  
        local pile_list = sgs.QList2Table(discardPile)  
          
        -- 随机打乱  
        for i = #pile_list, 2, -1 do  
            local j = math.random(i)  
            pile_list[i], pile_list[j] = pile_list[j], pile_list[i]  
        end  
          
        -- 取前3张  
        for i = 1, math.min(3, #pile_list) do  
            cards:append(pile_list[i])  
        end  
          
        -- 让玩家选择其中1张  
        room:fillAG(cards, ask_who)  
        local card_id = room:askForAG(ask_who, cards, false, self:objectName())  
        room:clearAG(ask_who)  
          
        if card_id ~= -1 then  
            -- 选择目标角色  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if ask_who:isFriendWith(p) then
                    targets:append(p) 
                end 
            end  

            local target = room:askForPlayerChosen(ask_who, targets, self:objectName(),   
                                                   "lige-invoke", false, true)  
            if target then  
                room:obtainCard(target, card_id, false)  
            end  
        end  
          
        return false  
    end  
}

gaojianli:addSkill(zhuji)  
gaojianli:addSkill(lige)

sgs.LoadTranslationTable{        
    ["gaojianli"] = "高渐离",  
    ["zhuji"] = "筑击",
    [":zhuji"] = "你可以将所有手牌当作杀使用或打出。若为使用，此杀造成伤害后，你可以弃置目标所有手牌。",
    ["lige"] = "离歌",
    [":lige"] = "任意角色回合结束时，若你没有手牌，你可以从弃牌堆随机3张牌选择1张交给任意一名相同势力角色"
}  

gehong = sgs.General(extension, "gehong", "qun", 4) -- 群势力，4体力

YangshengCard = sgs.CreateSkillCard{  
    name = "YangshengCard",  
    skill_name = "yangsheng",  
    target_fixed = true,  
    will_throw = true,  
    on_use = function(self, room, source, targets)  
        -- 增加体力上限  
        room:addPlayerMark(source, "maxhp", 1)  
        room:broadcastProperty(source, "maxhp")  
        --source:setMaxHp(source:getMaxHp()+1)  --这么实现没有问题，只是不显示
        --room:broadcastProperty(source,"maxhp") --告诉所有人，从而显示
        room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1)) --等于上面2行
        -- 恢复体力  
        local recover = sgs.RecoverStruct()  
        recover.who = source  
        recover.recover = 1  
        room:recover(source, recover)  
          
        -- 摸两张牌  
        source:drawCards(2, "yangsheng")  
    end  
}  
  
-- 养生主动技能  
yangsheng_active = sgs.CreateViewAsSkill{  
    name = "yangsheng",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return to_select:isKindOf("Peach") and not to_select:isEquipped()  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = YangshengCard:clone()  
            card:addSubcard(cards[1])  
            card:setShowSkill(self:objectName())  
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return player:getHp() == player:getMaxHp() and not player:isKongcheng()  
    end  
}

yangsheng_passive = sgs.CreateTriggerSkill{  
    name = "yangsheng",  
    events = {sgs.DamageInflicted},
    view_as_skill = yangsheng_active,
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill("yangsheng")) then   
            return ""   
        end  
          
        local damage = data:toDamage()  
        -- 检查是否为致命伤害且体力上限>=2  
        if damage.damage >= player:getHp() and player:getMaxHp() >= 2 then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke("yangsheng", data) then  
            room:broadcastSkillInvoke("yangsheng")  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 减少一点体力上限  
        room:loseMaxHp(player, 1)  
          
        -- 伤害-1  
        damage.damage = damage.damage - 1  
        data = sgs.QVariant()  
        data:setValue(damage)  
        if damage.damage <= 0 then
            return true
        end
        return false  
    end  
}

-- 添加技能到武将  
gehong:addSkill(yangsheng_passive)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["gehong"] = "葛洪",  
    ["yangsheng"] = "养生",  
    [":yangsheng"] = "当你体力等于体力上限时，你可以弃置一张桃，增加一点体力上限，恢复一点体力，摸两张牌；受到致命伤害时，若体力上限大于等于2，你可以减少一点体力上限，令此伤害-1。",  
    ["#yangsheng"] = "养生",  
    ["YangshengCard"] = "养生"  
}  


goujian = sgs.General(extension, "goujian", "wu", 3)  --wu

-- 创建隐忍触发技能  
yinren = sgs.CreateTriggerSkill{  
    name = "yinren",  
    events = {sgs.EventPhaseChanging, sgs.CardUsed},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseChanging then  
            local change = data:toPhaseChange()  
            if change.to == sgs.Player_Discard and not player:hasFlag("YinrenSlashUsed") then  
                return self:objectName()  
            end  
        elseif event == sgs.CardUsed then  
            local use = data:toCardUse()  
            if use.card and use.card:isKindOf("Slash") and use.from and use.from:objectName() == player:objectName()   
               and player:getPhase() == sgs.Player_Play then  
                room:setPlayerFlag(player, "YinrenSlashUsed")  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseChanging then  
            return false  -- 这是一个锁定技，不需要询问发动  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseChanging then  
            room:notifySkillInvoked(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
              
            -- 发送日志  
            local msg = sgs.LogMessage()  
            msg.type = "#Yinren"  
            msg.from = player  
            msg.arg = self:objectName()  
            room:sendLog(msg)  
              
            -- 跳过弃牌阶段  
            player:skip(sgs.Player_Discard)  
        end  
          
        return false  
    end,  
}

yinren_maxcards = sgs.CreateMaxCardsSkill{  
    name = "#yinren_maxcards",  
    extra_func = function(self, player)  
        if player:hasShownSkill("yinren") and not player:hasFlag("YinrenSlashUsed") then
            return 4
        end
        return 0
    end  
}

tuqiang = sgs.CreateTriggerSkill{  
    name = "tuqiang",  
    events = {sgs.CardResponded, sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then 
            return false
        end  
        if player:getPhase() ~= sgs.Player_NotActive then  --非回合外，不发动
            return false  
        end  
        local card = nil  
        if event == sgs.CardResponded then  
            card = data:toCardResponse().m_card  
        else  
            card = data:toCardUse().card  
        end  
        if card and (card:isKindOf("Slash") or card:isKindOf("Jink") or card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
            return self:objectName()
        end  
          
        return false
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
        room:broadcastSkillInvoke(self:objectName(), player)  
          
        player:drawCards(1)  
          
        return false  
    end  
}

goujian:addSkill(yinren)  
goujian:addSkill(yinren_maxcards)
goujian:addSkill(tuqiang)

sgs.LoadTranslationTable{  
    ["goujian"] = "勾践",  
    ["#goujian"] = "卧薪尝胆",  
      
    ["yinren"] = "隐忍",  
    [":yinren"] = "若你的出牌阶段没有使用过杀，你本回合手牌上限+4",  
      
    ["tuqiang"] = "图强",  
    [":tuqiang"] = "你的回合外，当你使用或打出基础牌时，你可以摸一张牌。",  
}

-- 创建武将：
guanyu_hero = sgs.General(extension, "guanyu_hero", "shu", 4)  -- 吴国，4血，男性  

-- 创建补刀触发技能  
Budao = sgs.CreateTriggerSkill{  
    name = "budao",  
    events = {sgs.Damage},  
      
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.to and damage.to:isAlive() and damage.card and damage.card:isKindOf("Slash") then  
            -- 找出拥有此技能的角色  
            owner = room:findPlayerBySkillName(self:objectName())
            return self:objectName(), owner:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        local prompt = string.format("@budao-slash:%s:%s:", damage.to:objectName(), ask_who:objectName())  
        if room:askForUseSlashTo(ask_who, damage.to, prompt, false, false, false) then  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 补刀的效果已经在on_cost中通过askForUseSlashTo实现  
        return false  
    end,  
}

wushengSlash = sgs.CreateTriggerSkill{  
    name = "wushengSlash",  
    events = {sgs.CardResponded},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        local source = room:findPlayerBySkillName(self:objectName())  
        if not (source and source:isAlive() and source:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        -- 检查是否是其他角色  
        if player:objectName() == source:objectName() then  
            return ""  
        end  
          
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        -- 检查是否是杀  
        if card and card:isKindOf("Slash") then  
            return self:objectName(), source:objectName()
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        --local source = room:findPlayerBySkillName(self:objectName())  
        if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:notifySkillInvoked(ask_who, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        --local source = room:findPlayerBySkillName(self:objectName())  
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
        ask_who:obtainCard(card)
        return false  
    end  
}
guanyu_hero:addSkill(Budao)
guanyu_hero:addSkill(wushengSlash)
--guanyu_hero:addSkill("wusheng")
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["guanyu_hero"] = "关羽",
    ["budao"] = "补刀",  
    [":budao"] = "当一名角色受到【杀】的伤害时，你可以对其使用【杀】，直到其死亡或者打出【闪】或者你不想再出【杀】。",  
    ["@budao"] = "你可以对 %src 使用一张【杀】（补刀）",  
    ["@budao-continue"] = "你可以继续对 %src 使用一张【杀】（补刀）",  
    ["wushengSlash"] = "武圣",
    [":wushengSlash"] = "其他角色打出杀时，你获得之"
}

-- 创建管仲武将  
guanzhong = sgs.General(extension, "guanzhong", "qun", 3) -- 群势力，3体力

KuangheCard = sgs.CreateSkillCard{  
    name = "KuangheCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() and not to_select:hasFlag("kuanghe")
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        room:setPlayerFlag(target, "kuanghe")
        -- 进行拼点  
        local success = source:pindian(target, "kuanghe")  
        if success then  
            source:drawCards(1, "kuanghe")  
            --room:setPlayerFlag(source, "kuanghe_win")
        --else
            --room:setPlayerFlag(source, ".")
        end  
    end  
}  
  
-- 匡合技能  
kuanghe = sgs.CreateZeroCardViewAsSkill{  
    name = "kuanghe",  
    view_as = function(self, cards)  
        local card = KuangheCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:isKongcheng()  --(not player:hasUsed("#KuangheCard") or player:hasFlag("kuanghe_win")) and 
    end  
}

zunwang = sgs.CreateTriggerSkill{  
    name = "zunwang",  
    events = {sgs.Pindian},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:hasFlag("zunwang_used") then  
            local pindian = data:toPindian()  
            if pindian.from:objectName() == player:objectName() or   
               pindian.to:objectName() == player:objectName() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then  
            room:notifySkillInvoked(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        player:drawCards(1, self:objectName())  
        room:setPlayerFlag(player,"zunwang_used")
        return false  
    end  
}

guanzhong:addSkill(kuanghe)  
guanzhong:addSkill(zunwang)  
  
  
-- 返回扩展包  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["guanzhong"] = "管仲",  
    ["kuanghe"] = "匡合",  
    [":kuanghe"] = "出牌阶段每名角色限一次，你可以与一名角色拼点，若你赢，你摸一张牌。",  
    ["zunwang"] = "尊王",   
    [":zunwang"] = "每回合限一次。你拼点结算后，你摸一张牌。"  
}  

guoziyi = sgs.General(extension, "guoziyi", "qun", 4) -- 蜀势力，4血，男性（默认）  

wenwu = sgs.CreateTriggerSkill{  
    name = "wenwu",  
    events = {sgs.CardFinished},  
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        local use = data:toCardUse()  
        local card = use.card  
          
        if not card then return "" end  
          
        -- 获取上一张牌的类型  
        local last_card_type = player:getTag("wenwu_last_card_type"):toString()  
        --记录这张牌的类型
        if card then  
            local card_type = ""  
            if card:isKindOf("BasicCard") then  
                card_type = "BasicCard"  
            elseif card:isKindOf("TrickCard") then  
                card_type = "TrickCard"  
            else --不管是什么类型，都得记录。上一张牌既不是基础牌、也不是锦囊牌，就不应该触发
                card_type = "Invalid"
            end  
                
            if card_type ~= "" then  
                local tag = sgs.QVariant(card_type)  
                player:setTag("wenwu_last_card_type", tag)  
            end  
        end  
        -- 检查是否满足文武条件  
        if card:isKindOf("BasicCard") and last_card_type == "TrickCard" and not player:hasFlag("wenwu_extra_basic") then  
            return self:objectName()  
        elseif card:isKindOf("TrickCard") and last_card_type == "BasicCard" and not player:hasFlag("wenwu_extra_trick") then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 额外结算一次  
        if event == sgs.CardFinished then  
            local use = data:toCardUse()  
            local card = use.card  
            if card:isKindOf("BasicCard") then  
                room:setPlayerFlag(player,"wenwu_extra_basic") 
            elseif card:isKindOf("TrickCard") then  
                room:setPlayerFlag(player,"wenwu_extra_trick")  
            end
            local new_use = sgs.CardUseStruct()  
            new_use.card = use.card  
            new_use.from = use.from  
            new_use.to = use.to  
            room:useCard(new_use) --额外结算。直接用use，方天画戟杀不会再次生效
        end  
        return false  
    end  
}

qing2guo = sgs.CreateTriggerSkill{  
    name = "qing2guo",  
    events = {sgs.EventPhaseEnd, sgs.CardUsed}, 
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        if event == sgs.EventPhaseEnd then  
            if player:getPhase() == sgs.Player_Finish then  
                -- 检查本回合是否使用过基本牌或锦囊牌  
                local used_basic = player:hasFlag("qing2guo_used_basic")  
                local used_trick = player:hasFlag("qing2guo_used_trick")  
                  
                if not used_basic or not used_trick then  
                    return self:objectName()  
                end  
            end  
        elseif event == sgs.CardUsed then  
            -- 记录使用的牌类型  
            local use = data:toCardUse()  
            if use.from and use.from:objectName() == player:objectName() then  
                local card = use.card  
                if card:isKindOf("BasicCard") then  
                    room:setPlayerFlag(player, "qing2guo_used_basic")  
                elseif card:isKindOf("TrickCard") then  
                    room:setPlayerFlag(player, "qing2guo_used_trick")  
                end  
            end  
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseEnd then  
            return player:askForSkillInvoke(self:objectName(), data)  
        end  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseEnd then  
            room:drawCards(player, 1, self:objectName())  
        end  
        return false  
    end  
}

guoziyi:addSkill(wenwu)  
guoziyi:addSkill(qing2guo)  
-- 翻译表  
sgs.LoadTranslationTable{  
["#guoziyi"] = "汾阳王",  
["guoziyi"] = "郭子仪",  
["illustrator:guoziyi"] = "待定",  
["wenwu"] = "文武",  
[":wenwu"] = "每回合每项限一次。①当你使用基本牌结算后，若你使用的上一张牌是锦囊牌，此基本牌额外结算一次。②当你使用锦囊牌结算后，若你使用或打出的上一张牌是基本牌，此锦囊牌额外结算一次。",  
["qing2guo"] = "擎国",   
[":qing2guo"] = "结束阶段开始时，若你于此回合内未使用过基本牌或未使用过锦囊牌，你摸一张牌。",
}  


hanfeizi = sgs.General(extension, "hanfeizi", "qun", 3)  -- 吴国，4血，男性  

-- 拒绝谏言技能卡  
junfaCard = sgs.CreateSkillCard{  
    name = "junfaCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return to_select:objectName() ~= sgs.Self:objectName()   
    end,  
      
    on_use = function(self, room, source, targets)  
        for _, target in ipairs(targets) do
            local card_id = room:askForCard(target, ".|.|.|hand,equipped", self:objectName())
            if card_id then
                room:obtainCard(source, card_id)
                -- 标记该角色，表示本回合你使用牌对其无效  
                local mark = string.format("@junfa_%s", source:objectName())  
                room:setPlayerFlag(target, mark)  
            end
        end
    end  
}  
  
-- 拒绝谏言视为技  
junfaVS = sgs.CreateViewAsSkill{  
    name = "junfa",  
      
    view_filter = function(self, selected, to_select)  
        return #selected == 0  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = junfaCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())
            return card  
        end  
        return nil  
    end,

    enabled_at_play = function(self, player)  
        -- 出牌阶段限一次  
        return not player:hasUsed("#junfaCard")  
    end  
}  
  
-- 拒绝谏言主技能  
junfa = sgs.CreateTriggerSkill{  
    name = "junfa",  
    events = {sgs.CardEffected},  
    view_as_skill = junfaVS,  
      
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.CardEffected then  
            -- 处理无效效果  
            local effect = data:toCardEffect()  
            if effect.card and effect.from and effect.from:hasSkill(self:objectName()) then  
                -- 检查目标中是否包含有标记的角色  
                local mark = string.format("@junfa_%s", effect.from:objectName())  
                if effect.to and effect.to:hasFlag(mark) then  
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 强制触发  
    end,  
    
    on_effect = function(self, event, room, player, data)        
        return true  --返回true，终止效果结算
    end
}



zhudaoCard = sgs.CreateSkillCard{  
    name = "zhudaoCard",  
    target_fixed = true,  
    will_throw = true,  
      
    on_use = function(self, room, source, targets)  
        -- 获取弃置的牌  
        local discard_ids = self:getSubcards()  
        local discard_sum = 0  
          
        -- 计算弃置牌点数之和  
        for _, id in sgs.qlist(discard_ids) do  
            local card = sgs.Sanguosha:getCard(id)  
            discard_sum = discard_sum + card:getNumber()  
        end  
          
        -- 摸2X张牌  
        local draw_num = discard_ids:length() * 2  
        source:drawCards(draw_num)  
          
        -- 记录弃置牌点数之和  
        room:setPlayerMark(source,"@zhudao_discard_sum", discard_sum)
        local log = sgs.LogMessage()
		log.type = "111"
		log.from = source
		log.to:append(source)
		room:sendLog(log)
    end  
}  
  
-- 主道视为技  
zhudaoVS = sgs.CreateViewAsSkill{  
    name = "zhudao",  
    n = 3,  
      
    view_filter = function(self, selected, to_select)  
        -- 只能选择手牌  
        if to_select:isEquipped() then return false end  
        -- 最多选择3张  
        return #selected < 3  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 0 then return nil end  
          
        local card = zhudaoCard:clone()  
        for _, c in ipairs(cards) do  
            card:addSubcard(c:getId())  
        end  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 出牌阶段限一次  
        return not player:hasUsed("#zhudaoCard")  
    end  
}  
  
-- 主道触发技(用于检查使用牌点数并结束出牌阶段)  
zhudao = sgs.CreateTriggerSkill{  
    name = "zhudao",  
    events = {sgs.CardUsed, sgs.EventPhaseChanging},  
    view_as_skill = zhudaoVS,  
      
    can_trigger = function(self, event, room, player, data)  
        --if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return "" end  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()
            if use.card:getTypeId()==sgs.Card_TypeSkill then return "" end
            -- 检查是否在使用主道后的出牌阶段  
            if use.from:getMark("@zhudao_discard_sum") > 0 and use.from:getPhase() == sgs.Player_Play then  
                return self:objectName()  
            end  
        elseif event == sgs.EventPhaseChanging then  
            -- 清除标记  
            local change = data:toPhaseChange()  
            if change.to == sgs.Player_NotActive and player:getMark("@zhudao_discard_sum") > 0 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            local card = use.card  
            player = use.from
            -- 累加使用牌的点数  
            local current_sum = player:getMark("@zhudao_used_sum") + card:getNumber()  
            room:setPlayerMark(player,"@zhudao_used_sum", current_sum)  

            -- 检查是否达到条件  
            local discard_sum = player:getMark("@zhudao_discard_sum")  
            if current_sum >= discard_sum then                    
                -- 清除标记  
                room:setPlayerMark(player,"@zhudao_discard_sum", 0)  
                room:setPlayerMark(player,"@zhudao_used_sum", 0)  
                -- 设置标志位结束出牌阶段  
                room:setPlayerFlag(player, "Global_PlayPhaseTerminated")  
            end  
        elseif event == sgs.EventPhaseChanging then  
            -- 清除标记  
            room:setPlayerMark(player,"@zhudao_discard_sum", 0)  
            room:setPlayerMark(player,"@zhudao_used_sum", 0)  
        end  
          
        return false  
    end  
}
hanfeizi:addSkill(junfa)
hanfeizi:addSkill(zhudao)
sgs.LoadTranslationTable{
    ["hanfeizi"] = "韩非子",
    ["junfa"] = "君法",
    [":junfa"] = "出牌阶段限一次。你可以弃置一张牌，然后选择任意名其他角色，其可以交给你1张牌，令本回合你对其使用牌无效",
    ["zhudao"] = "主道",
    [":zhudao"] = "出牌阶段限一次。你可以弃置X手牌，摸2X张牌（X至多为3），然后若你使用牌点数之和大于等于弃置牌点数之和，你结束出牌阶段",
}

--[[
hanxin = sgs.General(extension, "hanxin", "wu", 3)  -- 吴国，4血，男性  

gongxinFire = sgs.CreateZeroCardViewAsSkill{
    name = "gongxinFire",  
    view_as = function(self)  
        local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)  
        fire_attack:setSkillName(self:objectName())  --设置转化牌的技能名
        fire_attack:setShowSkill(self:objectName())  --使用时亮将
        return fire_attack  
    end,
    enabled_at_play = function(self, player)  
        return not player:hasUsed("ViewAsgongxinFireCard")  
    end  
}     

bingxian = sgs.CreateTriggerSkill{
	name = "bingxian",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName())  then
			if event == sgs.CardsMoveOneTime then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local now_handcard_ids = CardList2Table(player:getHandcards())
					if #now_handcard_ids - player:getMark("bingxian_hNum") >= 2 then return false end
					if move.to and move.to:objectName() == player:objectName() then
						return self:objectName()
					end
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, player, data)
        room:drawCards(player,1,self:objectName())
		return false
	end
}

bingxian_setHNum = sgs.CreateTriggerSkill{
	name = "#bingxian_setHNum",
	events = {sgs.EventPhaseEnd, sgs.Player_Draw, sgs.BeforeCardsMove},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.BeforeCardsMove then
			room:setPlayerMark(player, "bingxian_hNum", #CardList2Table(player:getHandcards()))
		end
		return false
	end,
}

hanxin:addSkill(gongxinFire)
hanxin:addSkill(bingxian)

sgs.LoadTranslationTable{
    ["hanxin"] = "韩信",  

    ["gongxinFire"] = "攻心",  
    [":gongxinFire"] = "出牌阶段限一次，你可以视为使用一张【火攻】。",  
      
    ["bingxian"] = "兵仙",   
    [":bingxian"] = "每当你一次性获得两张或以上牌时，你可以摸一张牌。"  
}
]]

hongfunv = sgs.General(extension, "hongfunv", "qun", 3, false)  -- 吴国，4血，男性  
zishu = sgs.CreateTriggerSkill{  
    name = "zishu",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)    
        -- 寻找拥有诗怨技能的角色  
        local zishu_player = room:findPlayerBySkillName(self:objectName())  
        if not (zishu_player and zishu_player:isAlive() and zishu_player:hasSkill(self:objectName())) then return "" end

        local use = data:toCardUse()  
        local source = use.from
        if not (source and source:isAlive()) then return "" end
        if use.card:getTypeId()==sgs.Card_TypeSkill then return "" end --不能是技能卡
        if use.to:length() ~= 1 then return "" end --唯一目标

        local is_involved = false  
        local other_player = nil  
            
        -- 检查是否为使用者或目标  
        if source and source:objectName() == zishu_player:objectName() then  
            -- 技能拥有者使用牌指定其他角色  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() ~= zishu_player:objectName() then  
                    is_involved = true  
                    other_player = target  
                    break  
                end  
            end  
        elseif source and source:objectName() ~= zishu_player:objectName() then  
            -- 其他角色使用牌指定技能拥有者  
            for _, target in sgs.qlist(use.to) do  
                if target:objectName() == zishu_player:objectName() then  
                    is_involved = true  
                    other_player = source  
                    break  
                end  
            end  
        end
        if is_involved then
            if zishu_player:hasFlag("zishu_used" .. other_player:objectName()) then return "" end --每回合每名角色限一次
            if zishu_player:getHandcardNum() ~= other_player:getHandcardNum() then return "" end --这里可能有问题
            return self:objectName(), zishu_player:objectName()
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
          
        if other_player and ask_who:getHandcardNum() == other_player:getHandcardNum() then  
            room:setPlayerFlag(ask_who, "zishu_used" .. other_player:objectName())  
            local choice = room:askForChoice(ask_who, self:objectName(), "draw+discard",   
                data, "@zishu-choose:" .. other_player:objectName()) 
            if choice == "draw" then
                other_player:drawCards(1,self:objectName())
            elseif choice == "discard" then
                local card_id = room:askForCardChosen(ask_who, other_player, "hej", self:objectName())
                if card_id then  
                    room:throwCard(card_id, other_player, ask_who) 
                end
            end
        end  
          
        return false  
    end  
}  



hongfu = sgs.CreateTriggerSkill{  
    name = "hongfu",  
    events = {sgs.CardsMoveOneTime},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            if player:hasFlag("hongfu_used") then return "" end
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
                if player:objectName()==current:objectName() then return "" end
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from and move.from:isAlive() and move.from~=player then
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
        should_draw = false
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            for _,card_id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:isRed() then  
                    should_draw = true
                    break
                end
            end 
        end
        if should_draw then
            player:drawCards(1, self:objectName())
            room:setPlayerFlag(player,"hongfu_used")
        end
        return false  
    end  
}  

hongfunv:addSkill(zishu)
hongfunv:addSkill(hongfu)

sgs.LoadTranslationTable{
    ["hongfunv"] = "红拂女",
    ["zishu"] = "自殊",
    [":zishu"] = "你使用牌指定其他角色为唯一目标或成为其他角色使用牌的唯一目标时，若你与其手牌数相等，你可以令其摸一张牌或者弃置其区域内1张牌。每回合每名角色限一次。",
    ["hongfu"] = "红拂",
    [":hongfu"] = "每回合限一次。你的回合外，其他角色因弃置而失去红色牌时，你摸1张牌"
}

houyi = sgs.General(extension, "houyi", "wu", 4)  --或者把虞姬放到qun？
sheri = sgs.CreateTriggerSkill{
	name = "sheri",
	events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from == player then
				local target_list = {}
				for _, p in sgs.qlist(use.to) do
					if p ~= player then
						table.insert(target_list, p:objectName())
					end
				end
				if #target_list > 0 then
					return self:objectName() .. "->" .. table.concat(target_list, "+")
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, skill_target, data, player)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, skill_target, data, player)          
        -- 获取目标的红色手牌  
        local red_cards = sgs.IntList()  
        local heart_cards = sgs.IntList()
          
        for _, card in sgs.qlist(skill_target:getHandcards()) do  
            if card:isRed() then  
                red_cards:append(card:getEffectiveId())
                if card:getSuit() == sgs.Card_Heart then  
                    heart_cards:append(card:getEffectiveId()) 
                end  
            end  
        end  
          
        if not red_cards:isEmpty() then  
            -- 弃置红色手牌  
            local dummy = sgs.DummyCard(red_cards)  
            room:throwCard(dummy, skill_target, player)  
            dummy:deleteLater()  
              
            -- 摸等量牌  
            skill_target:drawCards(red_cards:length(), self:objectName())  
              
            -- 如果有红桃牌，使用askForYiji分配  
            if not heart_cards:isEmpty() then  
                room:setPlayerMark(player, "sheri_card1", heart_cards:at(0))
                for _,card_id in sgs.qlist(heart_cards) do
                    if room:getCardPlace(card_id) ~= sgs.Player_DiscardPile then
                        heart_cards:removeOne(card_id)
                    end
                end
                local dummy = sgs.DummyCard(heart_cards)  
                player:obtainCard(dummy)
                dummy:deleteLater()
            end  
        end     
    end
}

sheriAsk = sgs.CreateTriggerSkill{
    name = "#sheriAsk",
    events = {sgs.CardsMoveOneTime},
    can_trigger = function(self, event, room, player, data)
        if skillTriggerable(player, self:objectName()) then
            local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				if move and move.to and move.to:objectName() == player:objectName()then
                    local ids = sgs.IntList()
                    local isCard = false
					for _, id in sgs.qlist(move.card_ids) do
						if not isCard then
                            if player:getMark("sheri_card1") == id then
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

houyi:addSkill(sheri)
houyi:addSkill(sheriAsk)
extension:insertRelatedSkills("sheri", "#sheriAsk")
sgs.LoadTranslationTable{
["houyi"] = "后羿",
["sheri"] = "射日",  
[":sheri"] = "当你使用杀指定目标后，你可以令目标弃置所有红色手牌，并摸等量牌，然后你可以任意分配因此弃置进入弃牌堆的红桃牌",
}

huamulan = sgs.General(extension, "huamulan", "wu", 3, false)  
  
-- 变装技能实现  
yi4rong = sgs.CreateTriggerSkill{  
    name = "yi4rong",  
    events = {sgs.Death},  
    relate_to_place = "head",
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local death = data:toDeath()  
        local dead = death.who  
        return self:objectName() .. "->" .. dead:objectName()
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local death = data:toDeath()  
        local dead = death.who  
        local _data = sgs.QVariant()  
        _data:setValue(dead)  
          
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 失去变装技能  
        if ask_who:inHeadSkills(self:objectName()) then
            room:detachSkillFromPlayer(ask_who, "xiaoji", false, false, true)--第三个参数表示该技能的位置是否在主将上，默认true，位置不对移除不了
            room:detachSkillFromPlayer(ask_who, self:objectName(), false, false, true)--第三个参数表示该技能的位置是否在主将上，默认true，位置不对移除不了
        else
            room:detachSkillFromPlayer(ask_who, "xiaoji", false, false, false)--第三个参数表示该技能的位置是否在主将上，默认true，位置不对移除不了
            room:detachSkillFromPlayer(ask_who, self:objectName(), false, false, false)--第三个参数表示该技能的位置是否在主将上，默认true，位置不对移除不了
        end
        local death = data:toDeath()  
        local dead = death.who  
          
        -- 选择获得主将还是副将的技能  
        local choice = room:askForChoice(ask_who, self:objectName(), "head+deputy+cancel")  
        if choice == "cancel" then return false end
        -- 获得技能  
        local skills = nil
        if choice == "head" then  
            skills = dead:getHeadSkillList()  
        elseif choice == "deputy" then
            skills = dead:getDeputySkillList()  
        end  
          
        for _, skill in sgs.qlist(skills) do  
            if not skill:isAttachedLordSkill() then  
                room:acquireSkill(ask_who, skill:objectName(), true, true)
                --room:attachSkillToPlayer(ask_who, skill:objectName())  
            end  
        end
        if ask_who:canTransform() then
            local choice = room:askForChoice(ask_who, "是否变更副将", "yes+no")
            if choice == "yes" then
                room:transformDeputyGeneral(ask_who) 
            end
        end
        return false  
    end  
}  

-- 添加技能到武将  
huamulan:addSkill(yi4rong)  
huamulan:addSkill("xiaoji")  

-- 翻译表  
sgs.LoadTranslationTable{  
    ["extension"] = "英雄扩展包",  
    ["huamulan"] = "花木兰",  
    ["yi4rong"] = "易容",  
    [":yi4rong"] = "主将技。任意一名角色死亡时，你可以失去该武将上的所有技能，获得其一个武将上的所有技能。然后你可以变更副将。",
}  

huangdi = sgs.General(extension, "huangdi", "wu", 3)  --wu,qun  
  
renzu = sgs.CreateDrawCardsSkill{  
    name = "renzu",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        local count = -1  
          
        -- 计算场上女性角色数量  
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            count = count + 1  
        end  
          
        if count > 0 then  
            room:sendCompulsoryTriggerLog(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName(), player)  
              
            -- 显示增加摸牌数的提示  
            local msg = sgs.LogMessage()  
            msg.type = "#renzuDraw"  
            msg.from = player  
            msg.arg = count  
            msg.arg2 = self:objectName()  
            room:sendLog(msg)  
              
            return n + math.min(count,3)  
        else  
            return n  
        end  
    end  
}  

-- 添加手牌上限修改效果
--有了zu，就不需要 renzuMaxCard，二选一
renzuMaxCard = sgs.CreateMaxCardsSkill{  
    name = "renzu_maxCard",  
    extra_func = function(self, player)
        if player:hasShownSkill("renzu") then 
            return -player:getMaxCards()
        else
            return 0
        end
    end  
}  

zu = sgs.CreateTriggerSkill{  
    name = "zu",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() then  
            if player:hasShownSkill(self:objectName()) and player:getPhase() == sgs.Player_Discard then  
                -- 弃牌阶段开始时，拥有技能的角色触发  
                return self:objectName()  
            elseif player:getPhase() == sgs.Player_Start then  
                -- 其他角色的准备阶段，检查是否有"祖"牌堆  
                local renzuer = room:findPlayerBySkillName(self:objectName())  
                if renzuer:getPile("zu"):length() > 0 then--and player:objectName() ~= renzuer:objectName() then  
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:hasShownSkill(self:objectName()) and player:getPhase() == sgs.Player_Discard then  
            -- 锁定技，无需询问  
            return true--player:askForSkillInvoke(self:objectName(),data)  
        elseif player:getPhase() == sgs.Player_Start then  
            -- 其他角色准备阶段，也是锁定效果  
            --local renzuer = room:findPlayerBySkillName(self:objectName())
            return true--renzuer:askForSkillInvoke(self:objectName(),data)   
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Discard then  
            -- 弃牌阶段开始时，将所有手牌置于"祖"牌堆  
            local handcards = player:getHandcards()  
            if handcards:length() > 0 then  
                for _, card in sgs.qlist(handcards) do  
                    player:addToPile("zu", card)  
                end  
                -- 可以让玩家选择顺序，这里简化为直接添加  
                room:broadcastSkillInvoke(self:objectName(), player)  
            end  
        elseif player:getPhase() == sgs.Player_Start then  
            -- 其他角色准备阶段，获得"祖"牌堆第一张牌  
            local renzuer = room:findPlayerBySkillName(self:objectName())  
            local zu_pile = renzuer:getPile("zu")  
            if zu_pile:length() > 0 then--and player:objectName() ~= renzuer:objectName() then  
                local first_card_id = zu_pile:first()  
                local card = sgs.Sanguosha:getCard(first_card_id)  
                room:obtainCard(player, card, false)  
            end  
        end  
        return false  
    end,  
}

neijingCard = sgs.CreateSkillCard{  
    name = "neijingCard",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)  
        local handcards = source:getHandcards()  
        if handcards:length() == 0 then return end  
          
        -- 展示所有手牌  
        room:showAllCards(source)  
          
        -- 统计花色数量  
        local suits = {}  
        local suit_count = 0  
        for _, card in sgs.qlist(handcards) do  
            local suit = card:getSuitString()  
            if not suits[suit] then  
                suits[suit] = true  
                suit_count = suit_count + 1  
            end  
        end  
          
        -- 根据花色数量执行效果  
        if suit_count <= 1 then  
            -- 花色数为0或1，摸2张牌  
            room:drawCards(source, 2, "neijing")  
        elseif suit_count <= 3 then  
            -- 花色数为2或3，回复1点体力  
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 1  
            room:recover(source, recover)  
        elseif suit_count == 4 then  
            -- 花色数为4，回复2点体力  
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 2  
            room:recover(source, recover)  
        end  
    end,  
}  
  
neijing = sgs.CreateZeroCardViewAsSkill{  
    name = "neijing",  
    n = 0,  
    view_as = function(self, cards)  
        return neijingCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#neijingCard")  
    end,  
}  

longzheng = sgs.CreateTriggerSkill{
    name = "longzheng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    
    can_trigger = function(self, event, room, player, data)
        -- 检查是否是芈月且存活
        if not player or not player:hasSkill(self:objectName()) or not player:isAlive() then
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
        local zu_pile = player:getPile("zu")  
        for i=1,player:getLostHp() do
            if zu_pile:length() > 0 then  
                local first_card_id = zu_pile:first()  
                local card = sgs.Sanguosha:getCard(first_card_id)  
                room:obtainCard(player, card, false)  
            end
        end
        return false
    end
}
-- 添加技能给武将  
huangdi:addSkill(renzu)  
--huangdi:addSkill(renzuMaxCard)  
huangdi:addSkill(zu)  
huangdi:addSkill(neijing)  
huangdi:addSkill(longzheng)
sgs.LoadTranslationTable{  
    ["huangdi"] = "黄帝",  
      
    ["renzu"] = "人祖",  
    [":renzu"] = "你摸牌阶段摸牌数+X，X为存活玩家数-1，且至多为3；你的手牌上限恒定为0",  
    ["zu"] = "祖",  
    [":zu"] = "锁定技。弃牌阶段开始时，你将所有手牌置于'祖'牌堆。任意角色的准备阶段，若'祖'牌堆有牌，其获得'祖'牌堆的第一张牌。",
    ["neijing"] = "内经",  
    [":neijing"] = "出牌阶段限一次，你可以展示所有手牌。若花色数为0或1，你摸2张牌；花色数为2或3，你回复1点体力；花色数为4，你回复2点体力。",   
    ["longzheng"] = "龙征",
    [":longzheng"] = "你受到伤害后，你可以从“祖”牌堆获得X张牌，X为你已失去的体力值"   
}

huoqubing = sgs.General(extension, "huoqubing", "wu", 3) 

guanjunhou = sgs.CreateDrawCardsSkill{  
    name = "guanjunhou",  
    draw_num_func = function(self, player, n)  
        return n + 2  
    end,  
}  
  
-- 冠军侯弃牌效果  
guanjunhou_discard = sgs.CreateTriggerSkill{  
    name = "#guanjunhou-discard",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasShownSkill("guanjunhou")   
           and player:getPhase() == sgs.Player_Draw then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return true -- 强制执行，无需询问  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if not player:isNude() then  
            room:askForDiscard(player, "guanjunhou", 1, 1, false, true)  
        end  
        return false  
    end,  
}  
  
-- 将附属技能关联到主技能  
extension:insertRelatedSkills("guanjunhou", "#guanjunhou-discard")

huoqubing:addSkill(guanjunhou)
huoqubing:addSkill(guanjunhou_discard)
huoqubing:addSkill("kurou")
sgs.LoadTranslationTable{
["huoqubing"] = "霍去病",
["guanjunhou"] = "冠军侯",  
[":guanjunhou"] = "摸牌阶段，你令额定摸牌数+2；摸牌阶段结束时，你弃置1张牌。",
}

jiangziya = sgs.General(extension, "jiangziya", "wu", 3)  -- 吴国，4血，男性  
dudiaoCard = sgs.CreateSkillCard{  
    name = "dudiaoCard",  
    target_fixed = true,  
    will_throw = false,  
      
    on_use = function(self, room, source, targets)  
        local card_id = self:getSubcards():first()  
        local card = sgs.Sanguosha:getCard(card_id)  
          
        -- 展示手牌  
        --source:showHiddenSkill("dudiao")  
        room:showCard(source, card_id)  
          
        -- 记录花色到下回合开始  
        local suit = card:getSuit()+1
        source:setMark("dudiao_suit", suit)  
          
        -- 显示技能效果日志  
        local log = sgs.LogMessage()  
        log.type = "#dudiaoRecord"  
        log.from = source  
        log.arg = card:getSuitString()  
        room:sendLog(log)  
    end  
}  
  
-- 垂钓视为技  
dudiaoVS = sgs.CreateOneCardViewAsSkill{  
    name = "dudiao",  
    filter_pattern = ".|.|.|hand",  
      
    view_as = function(self, card)  
        local vs_card = dudiaoCard:clone()  
        vs_card:addSubcard(card)  
        vs_card:setSkillName("dudiao")  
        return vs_card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#dudiaoCard")  
    end  
}  
  
  
-- 注册技能  
dudiao = sgs.CreateTriggerSkill{  
    name = "dudiao",  
    view_as_skill = dudiaoVS,  
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then
            return ""
        end
        if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start then
            if player:hasSkill(self:objectName()) then
                player:setMark("dudiao_suit", 0)
            end
            return ""
        end
        local owner = room:findPlayerBySkillName(self:objectName())  
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then
            return ""
        end
        if player == owner then return "" end
        local card = nil
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
        if card==nil then return "" end
        if card:isKindOf("EquipCard") or card:isKindOf("DelayedTrick") then return "" end
        local recorded_suit = owner:getMark("dudiao_suit")-1
        if card:getSuit() == recorded_suit then  
            return self:objectName(), owner:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data) -- 自动触发  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 获得使用的牌  
        local card = nil
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()  
            card = response.m_card  
        end              
        if ask_who and ask_who:isAlive() and card then  
            --ask_who:obtainCard(card)  
            room:moveCardTo(card, ask_who, sgs.Player_PlaceHand)  
        end  
          
        return false  
    end  
}  


taolue = sgs.CreateTriggerSkill{  
    name = "taolue",  
    events = {sgs.EventPhaseStart},  
    limit_mark = "@taolue",
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:getPhase() == sgs.Player_Start) then
            return ""
        end
        if player:hasSkill(self:objectName()) then
            room:setPlayerMark(player,"@taolue",0)
        else
            local owner = room:findPlayerBySkillName(self:objectName())
            if not (owner and owner:isAlive() and owner:getMark("@taolue")==0 and not owner:isKongcheng()) then 
                return ""
            end
            return self:objectName(), owner:objectName()
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            room:setPlayerMark(ask_who,"@taolue",1)
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local handcards = ask_who:getHandcards()  
        --交换任意张
        if handcards:length() == 0 then return false end  
          
        -- 让玩家选择要交换的手牌  
        local to_exchange = room:askForExchange(ask_who, self:objectName(),   
                                               handcards:length(), 0,   
                                               "@taolue-exchange", "", ".|.|.|hand")  
          
        if to_exchange:length() == 0 then return false end  
        local exchange_num = to_exchange:length()  
        ask_who:drawCards(exchange_num)
        -- 将手牌和牌堆顶牌合并，让玩家重新排列  
        local all_cards = sgs.IntList()  
        for _, id in sgs.qlist(to_exchange) do  
            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, sgs.Player_DrawPile, true)
        end          
        -- 使用askForGuanxing让玩家排列卡牌  
        -- 注意：这里只能使用GuanxingUpOnly，因为我们需要所有牌都放回牌堆顶  
        local cards = room:getNCards(exchange_num)  
        room:askForGuanxing(ask_who, cards, sgs.Room_GuanxingUpOnly)
        return false  
    end  
}

jiangziya:addSkill(dudiao)  
jiangziya:addSkill(taolue)  
sgs.LoadTranslationTable{
["jiangziya"] = "姜子牙",  
["dudiao"] = "独钓",  
[":dudiao"] = "出牌阶段限一次，你可以展示一张手牌，然后记录该牌的花色，直到你的下回合开始前，其余角色使用该花色的非装备非延时性锦囊牌时，你获得该牌。",  
["dudiaoCard"] = "独钓",  
["#dudiaoRecord"] = "%from 发动了【独钓】，记录了 %arg 花色",  
["#dudiaoGet"] = "%from 的【独钓】效果触发，从 %to 处获得了 %card",  
["taolue"] = "韬略",
[":taolue"] = "每轮限一次。任意角色的准备阶段，你可以将任意张手牌以任意顺序与牌堆顶等量的牌交换"
}

-- 创建武将：
jifa = sgs.General(extension, "jifa", "wei", 4)  --wei,jin  

-- 创建讨伐技能卡  
TaofaCard = sgs.CreateSkillCard{  
    name = "taofaCard",
    target_fixed = false,  
    will_throw = false,
    filter = function(self, targets, to_select)  
        -- 检查是否已经对该角色使用过讨伐  
        if to_select:hasFlag("TaofaTarget_" .. sgs.Self:objectName()) then  
            return false  
        end  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 获取目标角色  
        local target = targets[1]  
          
        -- 标记该角色已被讨伐过  
        room:setPlayerFlag(target, "TaofaTarget_" .. source:objectName())  
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "taofa")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("taofa")  
          
        -- 将手牌交给目标角色  
        local move = sgs.CardsMoveStruct()  
        move.card_ids = self:getSubcards()  
        move.to = target  
        move.to_place = sgs.Player_PlaceHand  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "taofa", "")  
        room:moveCardsAtomic(move, true)  
          
        -- 检查目标角色的体力值是否大于等于你  
        if target:getHp() >= source:getHp() then  
            -- 发送日志  
            local msg = sgs.LogMessage()  
            msg.type = "#TaofaDamage"  
            msg.from = source  
            msg.to:append(target)  
            msg.arg = "taofa"  
            room:sendLog(msg)  
              
            -- 造成伤害  
            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = target  
            damage.damage = 1  
            damage.reason = "taofa"  
            room:damage(damage)  
        end  
    end  
}

-- 创建讨伐视为技  
TaofaViewAsSkill = sgs.CreateViewAsSkill{  
    name = "taofa",  
      
    view_filter = function(self, selected, to_select)  
        -- 只能选择一张手牌  
        return not to_select:isEquipped() and #selected < 1  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = TaofaCard:clone()  
            card:addSubcard(cards[1])  
            return card  
        end  
        return nil  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 需要有手牌才能发动  
        return not player:isKongcheng()  
    end  
}  

Taofa = sgs.CreateTriggerSkill{  
    name = "taofa",  
    view_as_skill = TaofaViewAsSkill,  
    events = {sgs.EventPhaseStart},  -- 添加回合开始事件  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart then  
            -- 在回合开始时清除所有与该玩家相关的讨伐标记  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:hasFlag("TaofaTarget_" .. player:objectName()) then  
                    room:setPlayerFlag(p, "-TaofaTarget_" .. player:objectName())  
                end  
            end  
        end  
        return ""  
    end,  
}

zhubao = sgs.CreateTriggerSkill{  
    name = "zhubao",  
    events = {sgs.EventPhaseEnd, sgs.DamageDone},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.DamageDone then  
            -- 记录伤害  
            local damage = data:toDamage()  
            if damage.from and damage.from:getPhase() ~= sgs.Player_NotActive then  
                -- 在伤害来源的回合内造成伤害时记录  
                local current_damage = damage.from:getMark("@zhubao_damage_count")  
                room:setPlayerMark(damage.from, "@zhubao_damage_count", current_damage + damage.damage)  
            end  
            return ""  
        elseif event == sgs.EventPhaseEnd then  
            -- 回合结束时检查是否可以发动  
            if player:getPhase() == sgs.Player_Finish then  
                local damage_count = player:getMark("@zhubao_damage_count")  
                room:setPlayerMark(player, "@zhubao_damage_count", 0)  
                if damage_count >= 2 then  
                    -- 寻找拥有诛暴技能的角色  
                    local zhubao_player = room:findPlayerBySkillName("zhubao")  
                    if zhubao_player and zhubao_player:isAlive() and not zhubao_player:willBeFriendWith(player) then  
                        return self:objectName(),zhubao_player:objectName()  
                    end  
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            local zhubao_player = ask_who  
              
            local _data = sgs.QVariant()  
            _data:setValue(player)  
              
            if zhubao_player:askForSkillInvoke(self:objectName(), _data) then  
                room:doAnimate(sgs.QSanProtocol_S_ANIMATE_INDICATE, zhubao_player:objectName(), player:objectName())  
                room:broadcastSkillInvoke(self:objectName(), zhubao_player)  
                return true  
            end  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            -- 令目标失去一点体力  
            room:loseHp(player, 1)  
        end  
        return false  
    end  
}  

jifa:addSkill(Taofa)  
jifa:addSkill(zhubao)
sgs.LoadTranslationTable{  
    ["jifa"] = "姬发",
    ["#jifa"] = "周武王",
    ["taofa"] = "讨伐",  
    [":taofa"] = "出牌阶段，你可以将一张手牌交给一名角色，若其体力值大于等于你，你对其造成一点伤害。每回合只能对同一角色使用1次。",  
    ["taofaCard"] = "讨伐",  
    ["zhubao"] = "诛暴",  
    [":zhubao"] = "其他势力角色回合结束时，若其本回合造成的伤害大于等于2，你可以令其失去一点体力。",  
}


jingke = sgs.General(extension, "jingke", "shu", 4)  
  
cike = sgs.CreateTriggerSkill{
	name = "cike",
	events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from == player then
				local target_list = {}
				for _, p in sgs.qlist(use.to) do
					if p ~= player then
						table.insert(target_list, p:objectName())
					end
				end
				if #target_list > 0 then
					return self:objectName() .. "->" .. table.concat(target_list, "+")
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, skill_target, data, player)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, skill_target, data, player)          
        local judge = sgs.JudgeStruct()  
        judge.pattern = ".|black"  --虽然没有明显好坏，先设置一个默认好判定
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = player  
        
        room:judge(judge)  
        
        -- 若判定牌为黑色，获得目标一张牌  
        if judge:isBlack() and not skill_target:isNude() then  
            local card_id = room:askForCardChosen(player, skill_target, "he", self:objectName())  
            room:throwCard(card_id, skill_target, player)  
        elseif judge:isRed() then
            room:obtainCard(player,judge.card)
        end  
    end
}

jingke:addSkill(cike)
jingke:addSkill("qiangxi")
sgs.LoadTranslationTable{
    ["jingke"] = "荆轲",
    ["cike"] = "刺客",
    [":cike"] = "你使用杀指定目标后，你可以发起一次判定，若判定牌为红色，你获得判定牌；若判定牌为黑色，你弃置目标1张牌"
}

-- 创建武将：唐伯虎  
kangxi = sgs.General(extension, "kangxi", "wu", 3)  -- 吴国，4血，男性  
  
xuefan = sgs.CreateDrawCardsSkill{  
    name = "xuefan",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        local count = 0  
          
        -- 计算场上女性角色数量  
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHp()>player:getHp() then  --性别包括男性、女性、无性别，不是男性不等于女性，之前不是男性就＋1，所以暗置的也计数
                count = count + 1  
            end  
        end  
          
        if count > 0 then  
            room:sendCompulsoryTriggerLog(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName(), player)  
              
            -- 显示增加摸牌数的提示  
            local msg = sgs.LogMessage()  
            msg.type = "#xuefanDraw"  
            msg.from = player  
            msg.arg = count  
            msg.arg2 = self:objectName()  
            room:sendLog(msg)  
              
            return n + math.min(count,3)  
        else  
            return n  
        end  
    end  
}  


mingcha_card = sgs.CreateSkillCard{  
    name = "mingcha",  
    target_fixed = false,  
    will_throw = true,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:isKongcheng()
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]   
        discard_num = math.min(self:subcardsLength(),target:getHandcardNum())
        local all_cards = room:askForCardsChosen(source, target, string.rep("h",discard_num), self:objectName(), discard_num, discard_num)  

        local to_get = sgs.IntList()  
        local suits = {}  --已经使用的花色
        -- 选择至多4张花色不同的牌  
        for i = 1, 4 do  
            room:fillAG(all_cards, source)  
            local card_id = room:askForAG(source, all_cards, true, "mingcha")  
            if card_id == -1 then 
                room:clearAG(source)
                break 
            end  
              
            local card = sgs.Sanguosha:getCard(card_id)  
            local suit = card:getSuitString()  
              
            if not suits[suit] then  
                suits[suit] = true  
                to_get:append(card_id)  
                all_cards:removeOne(card_id)  
                room:clearAG(source)
            else  
                room:sendCompulsoryTriggerLog(source, "mingcha", true)  
                room:clearAG(source)
                break  
            end  
        end 
          
        -- 弃置选择的牌  
        if not to_get:isEmpty() then  
            local dummy = sgs.DummyCard(to_get)  
            room:obtainCard(source, dummy)  
            dummy:deleteLater()
        end  
    end  
}  
mingcha = sgs.CreateViewAsSkill{  
    name = "mingcha",  
    filter_pattern = "h",  
    view_filter = function(self, selected, to_select)  
        return true  
    end,  
    view_as = function(self, cards)  
        if #cards == 0 then return nil end
        local card = mingcha_card:clone()  
        for _, c in ipairs(cards) do  
            card:addSubcard(c)  
        end  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#mingcha") and not player:isKongcheng()
    end  
}  

-- 添加技能给武将  
kangxi:addSkill(xuefan)  
kangxi:addSkill(mingcha)  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["kangxi"] = "康熙",
    ["xuefan"] = "削藩",
    [":xuefan"] = "摸牌阶段，每有1名角色血量大于你，你摸牌量+1，至多+3",
    ["mingcha"] = "明察",
    [":mingcha"] = "出牌阶段限一次。你可以弃置X张手牌，查看一名角色的至多X张手牌，获得其中花色互不相同的任意张"
}  
  
-- 创建武将：唐伯虎  
kongzi = sgs.General(extension, "kongzi", "qun", 3)  -- 吴国，4血，男性  

shouli_card = sgs.CreateSkillCard{  
    name = "shouli",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select)  
        if #targets == 0 then  
            return to_select:objectName() ~= sgs.Self:objectName()  
        elseif #targets == 1 then  
            return to_select:objectName() ~= sgs.Self:objectName() and targets[1]:objectName()  ~= to_select:objectName()
        end  
        return false  
    end,  
    feasible = function(self, targets)  
        return #targets==1 or #targets==2   
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        --[[
        --local card_id = room:askForCardChosen(source, source, "he", self:objectName(), false)  
        local card_id = room:askForCard(source, ".|.|.|hand,equipped", self:objectName())  
        room:obtainCard(target, card_id)  
        if #targets==2 then
            target = targets[2]  
        end
        --local card_id = room:askForCardChosen(source, source, "he", self:objectName(), false)  
        local card_id = room:askForCard(source, ".|.|.|hand,equipped", self:objectName())  
        room:obtainCard(target, card_id)  
        ]]
        local card_ids = room:askForExchange(source, self:objectName(), 2, 2)   
        for _,card_id in sgs.qlist(card_ids) do
            room:obtainCard(target, card_id)  
            if #targets==2 then
                target = targets[2]  
            end
        end
        source:drawCards(#targets) 
    end  
}  
  
shouli = sgs.CreateZeroCardViewAsSkill{  
        name = "shouli",  
          
        view_as = function(self)  
            local card = shouli_card:clone()
            card:setSkillName(self:objectName())  
            return card  
        end,  
          
        enabled_at_play = function(self, player)  
            return not player:hasUsed("#shouli") and player:getHandcardNum() >= 2
        end  
    }  




chongru_card = sgs.CreateSkillCard{  
    name = "chongru",  
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
        room:showCard(target, card1:getId())  
        local card2 = room:askForCardShow(source, source, self:objectName())  
        room:showCard(source, card2:getId())  
        if card1:getColor() == card2:getColor() then --颜色相同
            local recover = sgs.RecoverStruct()  
            recover.who = source  --恢复来源
            room:recover(source, recover)
            source:drawCards(1) --游戏里是目标摸一张牌
        else --颜色不同
            local card_id = room:askForCardChosen(source, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
            room:throwCard(card_id, target, source)  
        end    
    end  
}  
  
chongru = sgs.CreateZeroCardViewAsSkill{  
        name = "chongru",  
          
        view_as = function(self)  
            local card = chongru_card:clone()
            card:setSkillName(self:objectName())  
            return card  
        end,  
          
        enabled_at_play = function(self, player)  
            return not player:hasUsed("#chongru") 
        end  
    }  

kongzi:addSkill(shouli)
kongzi:addSkill(chongru)

sgs.LoadTranslationTable{
    ["kongzi"] = "孔子",
    ["shouli"] = "授礼",  
    [":shouli"] = "出牌阶段限一次。你可以选择X名角色(X为1-2)，将2张牌分给他们，然后你摸X张牌",
    ["chongru"] = "崇儒",  
    [":chongru"] = "出牌阶段限一次。你可以选择一名角色，令其展示一张手牌，然后你展示一张手牌。若展示的手牌颜色相同，你恢复一点体力，摸一张牌；若颜色不同，你弃置该角色一张牌",    
}

lanlingwang = sgs.General(extension, "lanlingwang", "shu", 4)

yushuai = sgs.CreateTriggerSkill{  
    name = "yushuai",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then  
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
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:hasShownOneGeneral() and p:isFemale() then  
                local card = room:askForCard(p, ".", "@yushuai-give", data, sgs.Card_MethodNone) --".|.|.|hand,equipped"
                if card then
                    room:obtainCard(player, card:getId())
                end
            end  
        end  

        return false  
    end  
}

zhubei = sgs.CreateTriggerSkill{  
    name = "zhubei",  
    events = {sgs.Damage},
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.from and damage.from:objectName() == player:objectName() then  
                --room:setPlayerFlag(player,"zhubei")  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShowSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,  
    on_effect = function(self, event, room, player, data)    
        room:setPlayerFlag(player,"zhubei")  
        return false  
    end  
}  
zhubeiMod = sgs.CreateTargetModSkill{  
    name = "#zhubei-mod",  
    pattern = "Slash",  
    residue_func = function(self, player, card)  
        if player:hasFlag("zhubei") then  
            return 1  
        else  
            return 0  
        end  
    end  
}

lanlingwang:addSkill(yushuai)
lanlingwang:addSkill(zhubei)
lanlingwang:addSkill(zhubeiMod)
sgs.LoadTranslationTable{
    ["lanlingwang"] = "兰陵王",
    ["yushuai"] = "玉帅",
    [":yushuai"] = "你的出牌阶段开始时，其他女性角色可以交给你1张牌",
    ["zhubei"] = "逐北",
    [":zhubei"] = "每回合限一次。你造成伤害后，你本回合出杀次数+1"
}

lianpo = sgs.General(extension, "lianpo", "wu", 4)  --wei 

fujingCard = sgs.CreateSkillCard{  
    name = "fujingCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
      
    feasible = function(self, targets)  
        -- 必须选择两名角色  
        return #targets == 1  
    end,    
    on_use = function(self, room, source, targets)  
        room:loseHp(source,1)

        local slash_ids = sgs.IntList()  
        for _, id in sgs.qlist(room:getDrawPile()) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:isKindOf("TrickCard") then  
                slash_ids:append(id)  
            end  
        end  
          
        if not slash_ids:isEmpty() then  
            -- 随机选择一张杀  
            local index = math.random(0, slash_ids:length() - 1)  
            local id = slash_ids:at(index)  
              
            -- 将杀移动给目标角色  
            local card = sgs.Sanguosha:getCard(id)  
            room:obtainCard(targets[1], card, false)  
        end  
    end  
}  
  
fujing = sgs.CreateZeroCardViewAsSkill{  
    name = "fujing",        
    view_as = function(self)  
        local vs_card = fujingCard:clone()  
        vs_card:setSkillName("fujing")  
        vs_card:setShowSkill("fujing")  
        return vs_card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#fujingCard")
    end  
}  
  
  
lianpo4 = sgs.CreateTriggerSkill{  
    name = "lianpo4",  
    events = {sgs.Damage},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.from and damage.from:objectName() == player:objectName() and not player:hasFlag("lianpo_used") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data) and room:askForDiscard(player, self:objectName(), 1, 1, true, true)
    end,  
    on_effect = function(self, event, room, player, data)    
        room:setPlayerFlag(player,"lianpo_used")  

        local damage = data:toDamage()
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
        slash:setSkillName("lianpo4")  
        local use = sgs.CardUseStruct()  
        use.card = slash  
        use.from = player  
        use.to:append(damage.to)  
        room:useCard(use) 
        slash:deleteLater()
        return false  
    end  
}  
lianpo:addSkill(fujing)
lianpo:addSkill(lianpo4)
sgs.LoadTranslationTable{
    ["lianpo"] = "廉颇",
    ["fujing"] = "负荆",
    [":fujing"] = "出牌阶段限一次。你可以失去1点体力，令一名角色从摸牌堆获得1张锦囊",
    ["lianpo4"] = "连破",
    [":lianpo4"] = "每回合限一次。你造成伤害后，你可以弃置1张牌，视为对伤害目标使用一张杀"
}

-- 创建武将：李白  
libai = sgs.General(extension, "libai", "shu", 3)  
  
-- 创建技能：邀月  
yaoyue = sgs.CreateTargetModSkill{  
    name = "yaoyue",   
    pattern = "Slash#SingleTargetTrick",  --同类模式用#并列，不同类用|并列  
    extra_target_func = function(self, player, card)  
        if player:hasShownSkill(self:objectName()) then  
            return 1
        else  
            return 0  
        end  
    end  
}  
--[[
yaoyue = sgs.CreateTriggerSkill{  
    name = "yaoyue",  
    events = {sgs.CardUsed},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local use = data:toCardUse()  
        -- 检查是否有角色使用了杀  
        if not (use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard"))) then return "" end  
          
        -- 检查使用杀的角色手牌数是否小于等于2  
        if use.to:length()==1 then  
            -- 寻找拥有背袭技能的角色  
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
        local use = data:toCardUse()  
        local target = use.to:first()
          
        local extra_target = room:askForPlayerChosen(player, room:getOtherPlayers(target), self:objectName())
        use.to:append(extra_target) --无中生有不知道能不能生效；延时锦囊不能生效
        data:setValue(use)
        return false  
    end  
}  
]]

-- 技能：酒仙 - 使用杀时触发（摸牌部分）  
jiuxian_draw = sgs.CreateTriggerSkill{  
    name = "jiuxian_draw",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local use = data:toCardUse()  
            if use.card:isKindOf("Slash") and use.card:getNumber() >= 9 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) -- 自动触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        player:drawCards(1)  
        return false  
    end  
}  

--[[
jiuxian_draw = sgs.CreateTriggerSkill{
	name = "jiuxian_draw",
	events = {sgs.CardUsed},
    frequency = sgs.SKill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:getNumber() >= 9 and use.from == player then
				local target_list = {}
				for _, p in sgs.qlist(use.to) do
					if p ~= player then
						table.insert(target_list, p:objectName())
					end
				end
				if #target_list > 0 then
					return self:objectName() .. "->" .. table.concat(target_list, "+")
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, skill_target, data, player)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, skill_target, data, player) 
        room:drawCards(player,1,self:objectName())
    end
}
]]
-- 酒仙 - 免疫伤害部分  
jiuxian_immune = sgs.CreateTriggerSkill{  
    name = "jiuxian_immune",   
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.card and damage.card:isKindOf("Slash") and damage.card:getNumber() <= 9 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) -- 自动触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        return true -- 返回true表示阻止伤害  
    end  
}  
  

-- 添加技能到李白  
libai:addSkill(yaoyue)  
-- 将技能添加到武将  
libai:addSkill(jiuxian_draw)  
libai:addSkill(jiuxian_immune) 
-- 添加技能到李白  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["libai"] = "李白", 
    ["#libai"] = "诗仙",  
      
    ["yaoyue"] = "邀月",  
    [":yaoyue"] = "你使用杀或者单体锦囊时，你可选择两名角色成为该牌的目标。",  
    ["@yaoyue-select"] = "请选择【%arg】的额外目标",  

    ["jiuxian_draw"] = "酒仙1",  
    [":jiuxian"] = "你使用大于等于9的杀时，你摸一张牌；你免疫小于等于9的杀的伤害。",  

    ["jiuxian_immune"] = "酒仙2",  
    [":jiuxian"] = "你使用大于等于9的杀时，你摸一张牌；你免疫小于等于9的杀的伤害。",  

    ["~libai"] = "仰天大笑出门去，我辈岂是蓬蒿人！"  
}  

liji = sgs.General(extension, "liji", "shu", 4, false)  

dihui = sgs.CreateTriggerSkill{  
    name = "dihui",  
    events = {sgs.Damage, sgs.DamageInflicted},  --DamageInflicted 先于 Damage
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() then--or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        local damage = data:toDamage()  
        -- 检查伤害源是否有该技能，伤害牌是否是杀  
        if event==sgs.Damage and damage.card and damage.card:isKindOf("Slash") and damage.from:hasSkill(self:objectName()) then  
            return self:objectName()  
        elseif event==sgs.DamageInflicted and damage.to and damage.to:getMark("@zhui") > 0 then
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        --有标记，先增伤，并去除标记
        if event==sgs.DamageInflicted and damage.to and damage.to:getMark("@zhui") > 0 then
            damage.damage = damage.damage + 1
            data:setValue(damage)
            room:setPlayerMark(damage.to,"@zhui",0)
        end
        --伤害源有该技能，伤害牌是杀
        if event==sgs.Damage and damage.card and damage.card:isKindOf("Slash") and damage.from:hasSkill(self:objectName()) then  
            room:setPlayerMark(damage.to, "@zhui", 1)  
        end
        return false  
    end  
}  

liji:addSkill(dihui)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["liji"] = "骊姬",  
    ["dihui"] = "诋毁",  
    [":dihui"] = "你使用杀对一名角色造成伤害后，其获得'追'标记，令其下次受到伤害时，伤害值+1，然后失去'追'标记。",  
    ["@zhui"] = "追",  
    ["#dihuiDamage"] = "%from 的'%arg'效果被触发，伤害从 %arg2 点增加至 %arg3 点"  
}

lijing = sgs.General(extension, "lijing", "wu", 4)  --wei 

junshenCard = sgs.CreateSkillCard{  
    name = "junshenCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and sgs.Self:distanceTo(to_select) <= 1 and to_select:getHandcardNum() ~= sgs.Self:getHandcardNum()
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1  
    end,    
    on_use = function(self, room, source, targets)  
        local target = targets[1]
        if target:getHandcardNum() < source:getHandcardNum() then
            target:drawCards(1,self:objectName())
        elseif target:getHandcardNum() > source:getHandcardNum() then
            room:askForDiscard(target, self:objectName(), 1, 1, false, false)
        elseif target:getHandcardNum() == source:getHandcardNum() then
            return false
        end
        if target:getHandcardNum() == source:getHandcardNum() then
            local choice = room:askForChoice(source,self:objectName(),"snatch+duel")

            local slash = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)  
            slash:setSkillName(self:objectName())  
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = source  
            use.to:append(target)  
            room:useCard(use) 
            slash:deleteLater()
        end
    end  
}  
  
junshen = sgs.CreateZeroCardViewAsSkill{  
    name = "junshen",        
    view_as = function(self)  
        local vs_card = junshenCard:clone()  
        vs_card:setSkillName("junshen")  
        vs_card:setShowSkill("junshen")  
        return vs_card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#junshenCard")
    end  
}  
  
  
bingshi = sgs.CreateTriggerSkill{  
    name = "bingshi",  
    events = {sgs.TurnStart},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive()  then  
            if player:hasSkill(self:objectName()) and not player:hasFlag("bingshi_used") then  --自己回合
                for _,p in sgs.qlist(room:getAlivePlayers()) do --把标记都清掉
                    room:setPlayerMark(p,"@bingshi",0)
                end
                return self:objectName()  
            elseif player:getMark("@bingshi") > 0 then --有标记角色的回合
                return self:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:hasSkill(self:objectName()) then
            return player:askForSkillInvoke(self:objectName(), data)
        elseif player:getMark("@bingshi") > 0 then
            return true
        end
    end,  
    on_effect = function(self, event, room, player, data)    
        if player:hasSkill(self:objectName()) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "bingshi", "@bingshi-choose", false)  
            target:drawCards(2,self:objectName())
            room:setPlayerMark(target,"@bingshi",1)
            room:setPlayerFlag(player,"bingshi_used")
        elseif player:getMark("@bingshi") > 0 then
            room:setPlayerMark(player,"@bingshi",0)
            if player:getCardCount(true) >= 2 then
                room:askForDiscard(player, self:objectName(), 2, 2, false, true)
            else
                room:loseHp(player,1)
            end
        end
        return false  
    end  
}  
lijing:addSkill(junshen)
lijing:addSkill(bingshi)
sgs.LoadTranslationTable{
    ["lijing"] = "李靖",
    ["junshen"] = "军神",
    [":junshen"] = "出牌阶段限1次。你可以选择一名距离1以内且手牌数与你不相等的其他角色，若其手牌数：大于你，则其弃置1张手牌；小于你，则其摸1张牌。若其因此手牌数与你相等，视为你对其使用决斗或顺手牵羊",
    ["bingshi"] = "兵势",
    [":bingshi"] = "你的回合开始时，你可以令1名其他角色摸2张牌；其回合开始时，其需弃置2张牌，不足则失去1点血量。"
}

limu = sgs.General(extension, "limu", "shu", 4) -- 吴苋，蜀势力，3血，女性
lianque = sgs.CreateTriggerSkill{  
    name = "lianque",  
    events = {sgs.SlashHit},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local effect = data:toSlashEffect() 
        --削弱方向：该技能视为使用的杀不能再次触发
        if effect.slash:getSkillName() == self:objectName() then return "" end
        local target = effect.to  
        if target and target:isAlive() then  
            return self:objectName()  
        end  
        return ""  
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
          
        local judge = sgs.JudgeStruct()  
        judge.pattern = "."  
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = player  
        
        room:judge(judge)  
        
        -- 若判定牌为黑色，获得目标一张牌  
        if not judge.card:isKindOf("BasicCard") then  
            --[[
            --削弱方向：实体杀
            local prompt = string.format("@lianque-slash:%s:%s:", target:objectName(), player:objectName())  
            room:askForUseSlashTo(player, target, prompt, false, false, false)
            ]]
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:setSkillName(self:objectName())  
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = player  
            use.to:append(target)  
            room:useCard(use) 
            slash:deleteLater()
        else
            room:obtainCard(player, judge.card)
        end  
        return false  
    end  
}  

poluDamage = sgs.CreateTriggerSkill{  
    name = "poluDamage",  
    events = {sgs.Damage, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,    
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end
        if room:getCurrent() ~= player then return "" end
        if event == sgs.Damage then
            room:setPlayerFlag(player,"polu_damage")
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and not player:hasFlag("polu_damage") then
            return self:objectName() 
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        player:drawCards(1, self:objectName())
        return false  
    end  
}  
limu:addSkill(lianque)
limu:addSkill(poluDamage)
sgs.LoadTranslationTable{
    ["limu"] = "李牧",
    ["lianque"] = "连却",
    [":lianque"] = "你不因此技能使用的杀命中后，你可以进行一次判定，若判定牌不为基本牌，可视为对该目标继续出杀，否则你获得该判定牌",--削弱方向：出实体杀；不能反复触发
    ["poluDamage"] = "破虏",
    [":poluDamage"] = "回合结束时，若你本回合未造成伤害，你摸一张牌",
}

linchong = sgs.General(extension, "linchong", "wu", 4)  --或者把虞姬放到qun？
baotou = sgs.CreateTriggerSkill{
	name = "baotou",
	events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from == player then
				local target_list = {}
				for _, p in sgs.qlist(use.to) do
					if p ~= player then
						table.insert(target_list, p:objectName())
					end
				end
				if #target_list > 0 then
					return self:objectName() .. "->" .. table.concat(target_list, "+")
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, skill_target, data, player)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, skill_target, data, player)          
        -- 获取目标的红色手牌  
        local jinks = sgs.IntList()            
        for _, card in sgs.qlist(skill_target:getHandcards()) do  
            if card:isKindOf("Jink") then  
                jinks:append(card:getEffectiveId())
            end  
        end  
          
        if not jinks:isEmpty() then  
            -- 弃置红色手牌  
            local dummy = sgs.DummyCard(jinks)  
            room:throwCard(dummy, skill_target, player)  
            dummy:deleteLater()  
        end     
    end
}
linchong:addSkill(baotou)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["linchong"] = "林冲",  
    ["baotou"] = "豹头",  
    [":baotou"] = "当你使用杀指定目标后，你可以令目标弃置手牌中所有闪",  
}

-- 创建武将：唐伯虎  
linxiangru = sgs.General(extension, "linxiangru", "wu", 3)  -- 吴国，4血，男性  

wanbiCard = sgs.CreateSkillCard{  
    name = "wanbi",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        --source
        --local card_ids = source:gethandcards()
        local source_handcards = source:handCards()  
        if not source_handcards:isEmpty() then  
            local move1 = sgs.CardsMoveStruct()  
            move1.card_ids = source_handcards  
            move1.to = target  
            move1.to_place = sgs.Player_PlaceHand  
            room:moveCardsAtomic(move1, false)  
        end  

        -- 让目标角色选择展示的牌  
        local to_show = room:askForExchange(target, "exchange_show", target:getHandcardNum(), 1, "@exchange-show","", ".|.|.|hand")  
        local shown_ids = {}  
        local hidden_ids = {}  
          
        for _, card in sgs.qlist(target:getHandcards()) do  
            local id = card:getEffectiveId()  
            if to_show:contains(id) then  
                room:showCard(target, id)
                table.insert(shown_ids, id)  
            else  
                table.insert(hidden_ids, id)  
            end  
        end  
          

          
        -- 让源角色选择获得展示的牌还是未展示的牌  
        local choice = room:askForChoice(source, "exchange_choice", "shown+hidden")  
        local to_get = (choice == "shown") and shown_ids or hidden_ids  
        

        if #to_get > 0 then  
            for _,id in ipairs(to_get) do
                room:obtainCard(source, id)
            end
        end  
    end  
}  
  
-- 视为技实现  
wanbi = sgs.CreateZeroCardViewAsSkill{  
    name = "wanbi",  
    view_as = function(self)  
        local skill_card = wanbiCard:clone()  
        skill_card:setSkillName(self:objectName())  
        skill_card:setShowSkill(self:objectName())  
        return skill_card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#wanbi") and not player:isKongcheng()  
    end  
}  

jianghe = sgs.CreateTriggerSkill{
	name = "jianghe",
	events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					if move.to_places:contains(sgs.Player_PlaceHand) then
						if move.to and move.to:isAlive() and move.to:hasSkill(self:objectName()) then
                            for _,card_id in sgs.qlist(move.card_ids) do
                                local card = sgs.Sanguosha:getCard(card_id)
                                if card:isKindOf("TrickCard") then 
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
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if  player:isFriendWith(p) then  
                targets:append(p)
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, targets, "jianghe", "@jianghe-choose", false)  
		target:drawCards(1)
        return false
	end
}

jianghe = sgs.CreateTriggerSkill{
	name = "jianghe",
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
                        if move.to_places:contains(sgs.Player_PlaceHand) then
                            if move.to and move.to:isAlive() and move.to:hasSkill(self:objectName()) then
                                for _,card_id in sgs.qlist(move.card_ids) do
                                    local card = sgs.Sanguosha:getCard(card_id)
                                    if card:isKindOf("TrickCard") then 
                                        room:setPlayerFlag(player,"jianghe_obtain")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
            local owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and owner:hasSkill(self:objectName()) and owner:hasFlag("jianghe_obtain") then
                return self:objectName(), owner:objectName()
            end
        end
		return ""
	end,
    on_cost = function(self, event, room, player, data, ask_who)
		return ask_who:askForSkillInvoke(self:objectName(),data) --player:hasShownSkill(self:objectName())
	end,
    on_effect = function(self, event, room, player, data, ask_who)
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getOtherPlayers(ask_who)) do
            if  ask_who:isFriendWith(p) then  
                targets:append(p)
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(ask_who, targets, "jianghe", "@jianghe-choose", false)  
		target:drawCards(1)
        return false
	end
}

linxiangru:addSkill(wanbi)
--linxiangru:addSkill(jianghe)
sgs.LoadTranslationTable{
    ["linxiangru"] = "蔺相如",  
      
    ["wanbi"] = "完璧",   
    [":wanbi"] = "出牌阶段限一次，你可以将全部手牌交给一名其他角色，令其展示任意数量的手牌，你选获得展示的或未展示的",
    ["jianghe"] = "将和",
    [":jianghe"] = "你获得锦囊牌后，你可以令一名势力相同的其他角色摸一张牌"
}

-- 创建武将：李清照  
liqingzhao = sgs.General(extension, "liqingzhao", "wu", 3, false)  -- 吴国，3血，女性   
-- 创建技能：词赋  
shangli = sgs.CreateTriggerSkill{  
    name = "shangli",  
    frequency = sgs.Skill_Frequent,  
    events = {sgs.CardsMoveOneTime, sgs.CardResponded, sgs.CardUsed},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then  --不是该角色，或者该角色无该技能
            return false  
        end  
          
        if player:getPhase() ~= sgs.Player_NotActive then  --非回合外，不发动
            return false  
        end  
        
        local trigger_times = 0
        if event == sgs.CardResponded or event == sgs.CardUsed then  
            local card = nil  
            if event == sgs.CardResponded then  
                card = data:toCardResponse().m_card  
            else  
                card = data:toCardUse().card  
            end  
              
            if card and card:isRed() then
                return self:objectName()  
                --trigger_times = 1 
            end  
        elseif event == sgs.CardsMoveOneTime then  
            local move = data:toMoveOneTime()                  
            -- 检查是否有红色牌被移走  
            for i = 1, move.card_ids:length() do  
                local card_id = move.card_ids:at(i)  
                local card = sgs.Sanguosha:getCard(card_id)  
                if card:isRed() then  
                    return self:objectName()
                    --trigger_times = trigger_times + 1 
                end  
                --[[
                local place = move.from_places:at(i)  
                if place == sgs.Player_PlaceHand then  
                    local card = sgs.Sanguosha:getCard(card_id)  
                    if card:isRed() then  
                        return self:objectName()
                        --trigger_times = trigger_times + 1 
                    end  
                end  
                ]]
            end  
        end
        if trigger_times > 0 then  
            -- 返回多次技能名，用加号连接  
            local result = ""  
            for i = 1, trigger_times do  
                if i > 1 then  
                    result = result .. "+"  
                end  
                result = result .. self:objectName()  
            end  
            return result  
        end
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        player:drawCards(1)  
        return false  
    end  
}  
shangli = sgs.CreateTriggerSkill{
	name = "shangli",
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
						if move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_NotActive and player:objectName()==move.from:objectName() then
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
		return player:askForSkillInvoke(self:objectName(),data) --player:hasShownSkill(self:objectName())
	end,
    on_effect = function(self, event, room, player, data)
		--player:drawCards(1)
		local red_count = 0
		local move_datas = data:toList()
		for _, move_data in sgs.qlist(move_datas) do
			local move = move_data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
				if move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_NotActive and player:objectName()==move.from:objectName() then
					for _,card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						if card:isRed() then 
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
yuci = sgs.CreateZeroCardViewAsSkill{  
        name = "yuci",  

        view_as = function(self)  
            local card = yuci_card:clone()
            card:setSkillName("yuci")  
            return card  
        end,  
          
        enabled_at_play = function(self, player)  
            return not player:hasUsed("#yuci")  
        end  
    }  
  
-- 窥心卡牌类  
yuci_card = sgs.CreateSkillCard{  
    name = "yuci",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:isKongcheng()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local handcards = target:getHandcards()  
        if handcards:isEmpty() then return end  
          
        local card_id = room:askForCardChosen(source, target, "h", "yuci")  
        local card = sgs.Sanguosha:getCard(card_id)  
          
        --room:showCard(target, card_id)  
        room:throwCard(card_id, target, target, self:objectName())
          
        if card:isKindOf("BasicCard") and not source:isNude() then  
            -- 红色牌，获得该牌  
            room:askForDiscard(source, self:objectName(), 1, 1, false, true)
        end  
    end  
}  


-- 添加技能给武将  
liqingzhao:addSkill(shangli)  
liqingzhao:addSkill(yuci)

-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["liqingzhao"] = "李清照",  
    ["#liqingzhao"] = "第一女词人",   
    ["shangli"] = "伤离",  
    [":shangli"] = "你的回合外，你每使用、打出、失去一张红色牌，你可以摸一张牌。",  

    ["yuci"] = "玉词",  
    [":yuci"] = "出牌阶段限一次。你可以弃置一名角色一张手牌，若此牌为基础牌，你弃置一张牌，无牌则不弃",        
    ["~liqingzhao"] = "生当作人杰，死亦为鬼雄。"  
}  

liubei_hero = sgs.General(extension, "liubei_hero", "shu", 3)  --shu,jin  

jieyi1 = sgs.CreateTriggerSkill{  
    name = "jieyi1",  
    events = {sgs.DamageInflicted, sgs.Damaged},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive()) then-- and player:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        local damage = data:toDamage()  
        if damage.reason == self:objectName() then return "" end --之前直接扣到死的原因是，效果会互相触发

        local liubei = room:findPlayerBySkillName(self:objectName())
        if not (liubei and liubei:isAlive()) then return "" end

        if event == sgs.DamageInflicted then  
            -- 当其他角色受到伤害时，你可以选择替他受到伤害 
            --伤害源是自己，不触发。AOE呢？
            if damage.from and damage.from:objectName() == liubei:objectName() then
                return ""
            end 
            if damage.to:objectName() ~= liubei:objectName() and damage.to:isAlive() then  
                return self:objectName()  
            end  
        elseif event == sgs.Damaged then  
            -- 当你受到伤害时，你可以弃置一张手牌，令伤害来源受到等量伤害。伤害来源是自己，也会扣到死
            if damage.from and damage.from:isAlive() and damage.from:objectName() ~= liubei:objectName() and damage.to:objectName()==liubei:objectName() and not liubei:isKongcheng() then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local liubei = room:findPlayerBySkillName(self:objectName())          
        if event == sgs.DamageInflicted then  
            -- 询问是否替其他角色受到伤害  
            local _data = sgs.QVariant()  
            _data:setValue(damage.to)  
            if liubei:askForSkillInvoke(self:objectName(), _data) then  
                room:broadcastSkillInvoke(self:objectName(), 1, liubei)  
                return true  
            end  
        elseif event == sgs.Damaged then  
            -- 询问是否弃置手牌反击  
            if liubei:askForSkillInvoke(self:objectName(), data) then  
                local card = room:askForCard(liubei, ".", "@jieyi1-discard", data, sgs.Card_MethodDiscard)  
                if card then  
                    room:broadcastSkillInvoke(self:objectName(), 2, liubei)  
                    return true  
                end  
            end  
        end  
          
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local liubei = room:findPlayerBySkillName(self:objectName())                    
        if event == sgs.DamageInflicted then  
            -- 转移伤害给自己  
            --[[
            damage.transfer = true  
            damage.to = liubei  
            damage.transfer_reason = self:objectName()  
            data:setValue(damage)
            ]]
            local new_damage = sgs.DamageStruct()  
            new_damage.from = damage.from --伤害源如果是自己，再选择替他受到伤害，也会直接扣到死  
            new_damage.to = liubei  
            new_damage.damage = damage.damage  
            new_damage.nature = sgs.DamageStruct_Normal  
            new_damage.reason = self:objectName()  
            room:damage(new_damage)  
            return true  
        elseif event == sgs.Damaged then  
            -- 对伤害来源造成等量伤害  
            local new_damage = sgs.DamageStruct()  
            new_damage.from = nil --伤害源如果是自己，再选择替他受到伤害，也会直接扣到死  
            new_damage.to = damage.from  
            new_damage.damage = damage.damage  
            new_damage.nature = sgs.DamageStruct_Normal  
            new_damage.reason = self:objectName()  
              
            room:damage(new_damage)  
        end  
          
        return false  
    end  
}

--避免相互触发，也限制强度，可以每回合限一次，给liubei设置Flag
jieyi2 = sgs.CreateTriggerSkill{  
    name = "jieyi2",  
    events = {sgs.HpRecover},  
    can_trigger = function(self, event, room, player, data)  
        local recover = data:toRecover()  
          
        -- 寻找拥有此技能的角色  
        local owner = room:findPlayerBySkillName(self:objectName())
        if owner:isAlive() and not owner:isKongcheng() and owner:getMark("@jieyi2-Clear")==0 then  --recover.who:objectName() ~= owner:objectName() then
            return self:objectName(), owner:objectName()
        end  
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local recover = data:toRecover()  
          
        if ask_who:objectName() ~= player:objectName() and ask_who:isWounded() then  
            -- 其他角色回复体力时，询问是否弃牌回复  
            local prompt = string.format("@jieyi2-self:%s::%d", player:objectName(), recover.recover)  
            if ask_who:askForSkillInvoke(self:objectName(), data) then  
                local card = room:askForCard(ask_who, ".", prompt, data, sgs.Card_MethodDiscard)  
                if card then  
                    room:broadcastSkillInvoke(self:objectName(), 1, ask_who)  
                    return true  
                end  
            end  
        else  
            -- 自己回复体力时，询问是否弃牌让其他角色回复  
            local others = {}  
            for _, p in sgs.qlist(room:getOtherPlayers(ask_who)) do  
                if p:isAlive() and p:isWounded() then  
                    table.insert(others, p)  
                end  
            end  
              
            if #others > 0 then  
                local prompt = string.format("@jieyi2-other::%d", recover.recover)  
                if ask_who:askForSkillInvoke(self:objectName(), data) then  
                    local card = room:askForCard(ask_who, ".", prompt, data, sgs.Card_MethodDiscard)  
                    if card then  
                        room:broadcastSkillInvoke(self:objectName(), 2, ask_who)  
                        return true
                    end  
                end  
            end  
        end  
          
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        --先加标记，否则会先触发恢复事件
        --room:setPlayerFlag(ask_who,"jieyi2_used")
        room:setPlayerMark(ask_who,"@jieyi2-Clear",1)

        local recover = data:toRecover()            
        if ask_who:objectName() ~= player:objectName() then  
            -- 其他角色回复体力时，自己回复等量体力  
            local new_recover = sgs.RecoverStruct()  
            new_recover.recover = recover.recover  
            new_recover.who = ask_who  
            room:recover(ask_who, new_recover)  
        else  
            -- 自己回复体力时，让选择的其他角色回复等量体力 
            --[[ 
            local others = {}  
            for _, p in sgs.qlist(room:getOtherPlayers(ask_who)) do  
                if p:isAlive() and p:isWounded() then  
                    table.insert(others, p)  
                end  
            end 
            ]] 
            local target = room:askForPlayerChosen(ask_who, room:getOtherPlayers(ask_who), self:objectName(),   
                string.format("jieyi2-choose::%d", recover.recover), false, true)                
            if target and target:isAlive() then  
                local new_recover = sgs.RecoverStruct()  
                new_recover.recover = recover.recover  
                new_recover.who = ask_who  
                room:recover(target, new_recover)  
            end  
        end  
        return false  
    end  
}

liubei_hero:addSkill(jieyi1)
liubei_hero:addSkill(jieyi2)
sgs.LoadTranslationTable{  
    ["liubei_hero"] = "义刘备",
    ["jieyi1"] = "结义-共死",
    [":jieyi1"] = "当其他角色受到来源不为你的伤害时，你可以选择替他受到伤害；当你受到伤害时，你可以弃置一张牌，令伤害来源受到无伤害来源的等量伤害。以上效果不可相互触发",
    ["jieyi2"] = "结义-同生",
    [":jieyi2"] = "每回合限一次。当其他角色回复体力时，你可以弃置一张手牌，回复等量体力；当你回复体力时，你可以弃置一张牌，选择一名其他角色回复等量体力。",
}  

liuche = sgs.General(extension, "liuche", "wu", 4)

zhengfaCard = sgs.CreateSkillCard{  
    name = "zhengfaCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:hasFlag("zhengfaTarget")  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        -- 标记该角色，表示已经对其使用过技能  
        room:setPlayerFlag(target, "zhengfaTarget")  
        -- 标记该角色，表示本轮其使用的锦囊对你无效  
        room:setPlayerMark(target, "@zhengfa", 1)  
    end  
}  
  
-- 拒绝谏言视为技  
zhengfaViewAsSkill = sgs.CreateViewAsSkill{  
    name = "zhengfa",  
      
    view_filter = function(self, selected, to_select)  
        return not to_select:isEquipped() and #selected == 0  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = zhengfaCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())
            return card  
        end  
        return nil  
    end,  
}  
  
-- 拒绝谏言主技能  
zhengfa = sgs.CreateTriggerSkill{  
    name = "zhengfa",  
    events = {sgs.EventPhaseEnd},  
    view_as_skill = zhengfaViewAsSkill,  
      
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:getMark("@zhengfa") > 0 then  
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 强制触发  
    end,  
    
    on_effect = function(self, event, room, player, data)
        room:askForDiscard(player,self:objectName(),1,1,false,false)
        room:setPlayerMark(player,"@zhengfa",0)
        return false
    end
}

liuche:addSkill(zhengfa)
liuche:addSkill("guzheng")
sgs.LoadTranslationTable{
    ["liuche"] = "刘彻",
    ["zhengfa"] = "征伐",
    [":zhengfa"] = "出牌阶段每名角色限一次，你可以弃置1张手牌，令其获得1个“征”标记，其下个弃牌阶段结束后，弃置1张手牌"
}

lishimin = sgs.General(extension, "lishimin", "wu", 4)  --wu,jin

kongju = sgs.CreateProhibitSkill{  --不能指定为目标，不是取消目标
    name = "kongju",  
    is_prohibited = function(self, from, to, card)  
        if to:hasShownSkill(self:objectName()) and (card:isKindOf("Snatch") or card:isKindOf("dismantlement") or card:isKindOf("DelayedTrick")) then  
            return true  
        end  
        return false  
    end  
}
lishimin:addSkill(kongju)
lishimin:addSkill("yingzi_zhouyu")
lishimin:addSkill("xiaoyaoTurned")
sgs.LoadTranslationTable{  
    ["lishimin"] = "李世民",  
      
    ["kongju"] = "控局",  
    [":kongju"] = "你不能成为顺手牵羊、过河拆桥、延时性锦囊的目标",  
}

lishishi = sgs.General(extension, "lishishi", "wu", 3, false)  --wu,jin
manwu = sgs.CreateTriggerSkill{  
    name = "manwu",  
    events = {sgs.DamageInflicted},  
    can_preshow = true,  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:canDiscard(player, "h") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data) and room:askForCard(player, ".|heart,spade", self:objectName(), data, sgs.Card_MethodDiscard)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        --[[
        local card_id = room:askForCardChosen(player, player, "h", self:objectName(), false, sgs.Card_MethodDiscard)  
        local card = sgs.Sanguosha:getCard(card_id)
        if card:getSuit()~=sgs.Card_Spade and card:getSuit()~=sgs.Card_Heart then
            return false
        end
        room:throwCard(card_id, player, player, self:objectName())
        ]]
        --local card_id = room:askForCard(player, ".|heart,spade", self:objectName(), data, sgs.Card_MethodDiscard)  
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
        local new_damage = sgs.DamageStruct()  
        local damage = data:toDamage()
        new_damage.from = damage.from --伤害源如果是自己，再选择替他受到伤害，也会直接扣到死  
        new_damage.to = target  
        new_damage.damage = damage.damage  
        new_damage.nature = damage.nature  
        new_damage.reason = self:objectName()  
        room:damage(new_damage)  
        
        -- 此时目标已经受到伤害，摸牌基于受伤后的体力值  
        if target:isAlive() then  
            local choice = room:askForChoice(player, self:objectName(), "Hp+lostHp", data)  
            if choice == "Hp" then
                target:drawCards(target:getHp())  
            elseif choice == "lostHp" then
                target:drawCards(target:getLostHp())  
            end
        end               
        return true  
    end  
}  
  
lishishi:addSkill(manwu)
lishishi:addSkill("hongyan")
sgs.LoadTranslationTable{
    ["lishishi"] = "李师师",
    ["manwu"] = "曼舞",
    [":manwu"] = "你受到伤害时，你可以弃置一张红桃或黑桃手牌，将伤害转移给一名其他角色，然后你选择令其摸X张牌，X为其体力值或失去的体力值",
}

lizicheng = sgs.General(extension, "lizicheng", "qun", 4)  -- 吴国，4血，男性  

Lumang = sgs.CreateTriggerSkill{  
    name = "lumang",  
    events = {sgs.TargetConfirming}, --TargetConfirmed
    --frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)   
        --TargetConfirmed是卡牌使用
        local use = data:toCardUse()  
        if not (use.card:isNDTrick()) then return "" end 
        if use.card:isKindOf("Duel") then return "" end 
        owner = room:findPlayerBySkillName(self:objectName())  
        if owner:objectName() ~= use.from:objectName() and use.to:length()==1 and use.to:contains(owner) then 
            return self:objectName(),owner:objectName()
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
        local from = use.from
   
        for _, p in sgs.qlist(use.to) do  
            use.to:removeOne(p)
        --    room:cancelTarget(use, p)
        --    sgs.Room_cancelTarget(use, p)
        end  
        data:setValue(use) --用以上方式修改use后，需要setValue
        -- 日志  
        local msg = sgs.LogMessage()  
        msg.type = "#LumangEffect"  
        msg.from = ask_who  
        msg.to:append(player)  
        msg.arg = self:objectName()  
        msg.arg2 = use.card:objectName()  
        room:sendLog(msg)  
        --return true --终止杀结算

        -- 视为来源对自己使用决斗  
        local duel = sgs.Sanguosha:cloneCard("duel")  
        duel:setSkillName(self:objectName())  

        local use = sgs.CardUseStruct()  
        use.from = from  
        use.to:append(ask_who)   
        use.card = duel  
        room:useCard(use) 
        duel:deleteLater()
        return false  
    end  
}

Yongchuang = sgs.CreateViewAsSkill{  
    name = "yongchuang",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:addSubcard(cards[1])  
            slash:setSkillName(self:objectName())  
            return slash  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return false  
    end,  
    enabled_at_response = function(self, player, pattern)    
        return pattern == "slash"  
    end  
}  
lizicheng:addSkill(Lumang)
lizicheng:addSkill(Yongchuang)

sgs.LoadTranslationTable{  
    ["hero"] = "英雄扩展包",  
      
    ["#lizicheng"] = "闯王",  
    ["lizicheng"] = "李自成",  
    ["lumang"] = "鲁莽",  
    [":lumang"] = "当你成为非延时性锦囊的唯一目标时，你可以取消该锦囊，视为来源对你使用一张【决斗】。",  
    ["yongchuang"] = "勇闯",   
    [":yongchuang"] = "响应【决斗】【南蛮入侵】时，你的任何一张牌都可以当【杀】打出。"  
}

luban = sgs.General(extension, "luban", "wu", 3)  -- 吴国，4血，男性  

-- 创建鬼斧技能卡  
GuifuCard = sgs.CreateSkillCard{  
    name = "guifuCard",  
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:getEquips():isEmpty()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "guifu")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("guifu")  
          
        -- 选择并弃置目标角色的一张装备  
        local equip = room:askForCardChosen(source, target, "e", "guifu")  
        room:throwCard(equip, target, source)  
          
        -- 双方各摸一张牌  
        source:drawCards(1, "guifu")  
        target:drawCards(1, "guifu")  
    end  
}  
  
-- 创建鬼斧视为技  
GuifuViewAsSkill = sgs.CreateZeroCardViewAsSkill{  
    name = "guifu",  
      
    view_as = function(self)  
        local card = GuifuCard:clone()  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#guifuCard")  
    end  
}  
  
-- 创建鬼斧技能  
Guifu = sgs.CreateTriggerSkill{  
    name = "guifu",  
    view_as_skill = GuifuViewAsSkill,  
    events = {},  -- 没有触发事件，纯视为技  
}  

-- 创建神工技能卡  
ShengongCard = sgs.CreateSkillCard{  
    name = "shengongCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:getEquips():isEmpty()
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "shengong")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("shengong")  
          
        -- 获取目标角色的装备区装备  
        local card_id=room:askForCardChosen(source, target, "e", "shengong")

        -- 创建对应的装备牌  
        --local equip = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(card_id):objectName(), sgs.Card_NoSuit, 0)  
        --equip:addSubcard(self:getSubcards():first())  
        --equip:setSkillName("shengong")  
        
        local shengong_target = room:askForPlayerChosen(source,  room:getAlivePlayers(), "shengong")
        -- 使用装备  
        --room:useCard(equip, shengong_target)  
        --room:useCard(sgs.CardUseStruct(equip, source, source))  
        room:moveCardTo(sgs.Sanguosha:getCard(card_id), shengong_target, sgs.Player_PlaceEquip, true)  

    end  
}  
  
-- 创建神工视为技  
ShengongViewAsSkill = sgs.CreateOneCardViewAsSkill{  
    name = "shengong",  
    filter_pattern = ".",  
      
    view_as = function(self, card)  
        local sc = ShengongCard:clone()
        sc:addSubcard(card)  
        sc:setShowSkill(self:objectName())  
        return sc  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#shengongCard") and not player:isKongcheng()  
    end  
}  

--[[
shengongCard = sgs.CreateSkillCard{  
    name = "shengongCard",  
    target_fixed = false,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
      
    filter = function(self, targets, to_select)  
        -- 只选择第一个目标：要复制装备的角色            
        -- 必须有装备才能被选择  
        return #targets == 0 and not to_select:getEquips():isEmpty()
    end,  
      
    feasible = function(self, targets)  
        -- 只需要选择一个目标（装备来源角色）  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        local from_player = targets[1]  -- 装备来源角色  
        local hand_card_id = self:getSubcards():first()  -- 手牌ID  
          
        -- 1. 让玩家从装备来源角色的装备区选择一张装备  
        local equip_id = room:askForCardChosen(source, from_player, "e", "shengong")  
        local equip_card = sgs.Sanguosha:getCard(equip_id)  
                    
        -- 5. 克隆要模拟的装备牌  
        local new_equip = sgs.Sanguosha:cloneCard(equip_card:objectName(),   
            equip_card:getSuit(), equip_card:getNumber())  
        new_equip:setSkillName("shengong")  
          
        -- 6. 获取手牌对应的 WrappedCard  
        local wrapped = sgs.Sanguosha:getWrappedCard(hand_card_id)  
          
        -- 7. 让 WrappedCard 接管新装备的效果  
        wrapped:takeOver(new_equip)  
          
        -- 8. 广播更新给所有玩家  
        room:broadcastUpdateCard(room:getPlayers(), hand_card_id, wrapped)  

        -- 4. 让玩家选择要放置装备的目标角色  
        local to_player = room:askForPlayerChosen(source, room:getAlivePlayers(), "shengong")  

        -- 9. 移动到目标的装备区  
        room:moveCardTo(wrapped, to_player,   
            sgs.Player_PlaceEquip,  
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,   
                source:objectName(), "shengong", ""))  
          
        -- 发送日志  
        local log = sgs.LogMessage()  
        log.type = "#shengong"  
        log.from = source  
        log.to = {to_player}  
        log.card_str = tostring(hand_card_id)  
        log.arg = equip_card:objectName()  
        room:sendLog(log)  
    end  
}  
  
-- 视为技定义  
ShengongViewAsSkill = sgs.CreateViewAsSkill{  
    name = "shengong",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0 and not to_select:isEquipped()
    end,  
      
    view_as = function(self, cards)  
        if #cards ~= 1 then return nil end  
          
        local card = shengongCard:clone()  
        card:addSubcard(cards[1])  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 出牌阶段限一次  
        return not player:hasUsed("#shengongCard") and not player:isKongcheng()
    end  
}  
]]
-- 创建神工技能  
Shengong = sgs.CreateTriggerSkill{  
    name = "shengong",  
    view_as_skill = ShengongViewAsSkill,  
    events = {},  -- 没有触发事件，纯视为技  
}  

luban:addSkill(Guifu)  
luban:addSkill(Shengong)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
      
    ["luban"] = "鲁班",  
    ["#luban"] = "巧匠",  
    ["guifu"] = "鬼斧",  
    [":guifu"] = "出牌阶段限1次，你可以弃置任意一名角色装备区的一张装备，然后你与其各摸一张牌。",  
    ["shengong"] = "神工",  
    [":shengong"] = "出牌阶段限1次，你可以弃置一张手牌，将任意一名角色装备区的一张装备，置入一名角色的装备区。",  
      
    ["guifuCard"] = "鬼斧",  
    ["shengongCard"] = "神工",  
}  

-- 创建武将：
luobingwang = sgs.General(extension, "luobingwang", "qun", 3)  -- 吴国，4血，男性 
yonge = sgs.CreateTriggerSkill{  
    name = "yonge",  
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseChanging},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseChanging then  
            local change = data:toPhaseChange()  
            if change.from == sgs.Player_Play then  
                -- 清除出牌阶段结束时的记录  
                return self:objectName()  
            end  
        elseif player:getPhase() == sgs.Player_Play then  
            local card = nil  
            if event == sgs.CardUsed then  
                local use = data:toCardUse()  
                if use.from:objectName() == player:objectName() then  
                    card = use.card  
                end  
            elseif event == sgs.CardResponded then  
                local resp = data:toCardResponse()  
                if resp.m_isUse and resp.m_from:objectName() == player:objectName() then  
                    card = resp.m_card  
                end  
            end  
              
            if card and card:getTypeId() ~= sgs.Card_TypeSkill then  
                local current_number = card:getNumber()  
                local max_number = player:getMark("@max_number_this_turn")  
                  
                -- 如果当前牌点数为本回合最大点数，触发摸牌  
                if current_number > max_number then  
                    room:setPlayerMark(player, "@max_number_this_turn", current_number)
                    if max_number > 0 then
                        return self:objectName()  
                    end
                end  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseChanging then  
            return true  
        else  
            -- 自动触发，无需询问  
            return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
        end  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseChanging then  
            -- 清除记录  
            room:setPlayerMark(player, "@max_number_this_turn", 0)  
        else  
            -- 摸一张牌  
            room:drawCards(player, 1, self:objectName())  
        end  
        return false  
    end  
}  
 
luobingwang:addSkill(yonge)
luobingwang:addSkill("fenxun")
sgs.LoadTranslationTable{
    ["luobingwang"] = "骆宾王",
    ["yonge"] = "咏鹅",
    [":yonge"] = "出牌阶段，当你使用的牌的点数为本回合最大点数时，你摸一张牌。"
}

-- 创建武将：
luzhishen = sgs.General(extension, "luzhishen", "wei", 4)  --wei,jin  

dili = sgs.CreateDrawCardsSkill{  
    name = "dili",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        local lost_hp = player:getLostHp() 
        return n + lost_hp  
    end  
}  

kuangchan = sgs.CreatePhaseChangeSkill{  
    name = "kuangchan", -- 技能名称  
    --frequency = sgs.Skill_Frequent, -- 设置为常规技能  
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and player:getHp() >= 2 then  
            return self:objectName()
        end  
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    -- 在阶段变化时触发的函数  
    on_phasechange = function(self, player)  
        -- 获取房间对象  
        local room = player:getRoom()  
        
        --room:loseHp(player, 1) 

        local damage = sgs.DamageStruct()  
        damage.from = player  
        damage.to = player  
        damage.damage = 1  
        damage.reason = self:objectName() 
        room:damage(damage)  
        return false  
    end,  
}


luzhishen:addSkill(dili)
luzhishen:addSkill(kuangchan)

-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["luzhishen"] = "鲁智深",
    ["#luzhishen"] = "花和尚",
    ["dili"] = "底力",
    [":dili"] = "摸牌阶段，你多摸X张牌，X为你已失去的体力数",
    ["kuangchan"] = "狂禅",
    [":kuangchan"] = "准备阶段，若你的体力值不小于2，你可以对自己造成1点伤害",
}  



lvbuwei = sgs.General(extension, "lvbuwei", "qun", 3)  -- 吴国，4血，男性  

zongquan = sgs.CreateOneCardViewAsSkill{  
    name = "zongquan",  
    response_pattern = "jink",  
    response_or_use = true,  
    view_filter = function(self, to_select)  
        -- 检查是否已选择2张牌  
        --if #selected >= 1 then return false end  
        return to_select:getNumber()>=10 and not to_select:isEquipped()  
    end, 
    view_as = function(self, card)  
        local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())  
        jink:addSubcard(card:getId())  
        jink:setSkillName(self:objectName())  --设置转化牌的技能名
        jink:setShowSkill(self:objectName())  --使用时亮将
        return jink  
    end,
    enabled_at_play = function(self, player)  
        return false -- 只能在响应时使用  
    end,    
    enabled_at_response = function(self, player, pattern)  
        return pattern == "jink"  
    end  
}  

zongquanMaxCards = sgs.CreateMaxCardsSkill{  
    name = "#zongquan_maxcards",  
    extra_func = function(self, player)
        if not player:hasShownSkill("zongquan") then
            return 0
        end
        local handcards = player:getHandcards()  
        local count = 0  
          
        -- 计算点数大于等于10的手牌数量
        -- 满足条件的卡不计入卡牌上限，即每有一张满足条件的卡，卡牌上限加1
        for _, card in sgs.qlist(handcards) do  
            if card:getNumber() >= 10 then  
                count = count + 1  
            end  
        end  
          
        return count  
    end  
}  

juqiCard = sgs.CreateSkillCard{  
    name = "juqi",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        --source
        local card_id1 = room:askForExchange(source, self:objectName(), source:getHandcardNum(), 1, "", "", ".|.|.|hand")
        --target
        local card_id2 = room:askForExchange(target, self:objectName(), target:getHandcardNum(), 1, "", "", ".|.|.|hand")

        local source_card_id = {}  
        local target_card_id = {}  
        for _, card in sgs.qlist(source:getHandcards()) do  
            local id = card:getEffectiveId()  
            if card_id1:contains(id) then  
                table.insert(source_card_id, id)  
            end  
        end  
        for _, card in sgs.qlist(target:getHandcards()) do  
            local id = card:getEffectiveId()  
            if card_id2:contains(id) then  
                table.insert(target_card_id, id)  
            end  
        end 
        -- 执行交换  
        for _,id in ipairs(source_card_id) do
            room:obtainCard(target, id)
        end
          
        for _,id in ipairs(target_card_id) do
            room:obtainCard(source, id)
        end

        if #source_card_id > #target_card_id then
            room:loseHp(target, #source_card_id - #target_card_id)
        elseif #source_card_id == #target_card_id then
            source:drawCards(1)
        end
    end  
}  
  
-- 视为技实现  
juqi = sgs.CreateZeroCardViewAsSkill{  
    name = "juqi",  
    view_as = function(self)  
        local skill_card = juqiCard:clone()  
        skill_card:setSkillName(self:objectName())  
        skill_card:setShowSkill(self:objectName())  
        return skill_card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#juqi") and not player:isKongcheng()  
    end  
}  


lvbuwei:addSkill(zongquan)
lvbuwei:addSkill(zongquanMaxCards)
lvbuwei:addSkill(juqi)
sgs.LoadTranslationTable{
    ["lvbuwei"] = "吕不韦",  

    ["zongquan"] = "纵权",  
    [":zongquan"] = "你大于等于10的手牌不计入手牌上限，且可视为闪",  
      
    ["juqi"] = "居奇",   
    [":juqi"] = "出牌阶段限一次，你可以选择一名其他角色，你与其各选择任意数量的手牌交换。若交换手牌数相等，你摸一张牌；若你给出的手牌数大于其给出的手牌数，其失去X点体力，X为你与其给出的手牌数的差。"  
}

-- 创建武将：吕雉  
lvzhi = sgs.General(extension, "lvzhi", "qun", 4, false)  

yangbing = sgs.CreateTriggerSkill{  
    name = "yangbing",  
    events = {sgs.EventPhaseEnd, sgs.Damage},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.Damage then  
            -- 记录造成伤害的角色  
            room:setPlayerFlag(player, "yangbing_damage")  
            return ""  
        elseif event == sgs.EventPhaseEnd and player and player:isAlive() and player:getPhase() == sgs.Player_Finish then  
            -- 回合结束时，检查是否有角色拥有养兵技能  
            owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and not player:hasFlag("yangbing_damage") and owner:willBeFriendWith(player) then  
                return self:objectName(), owner:objectName()
            end  
        end  
        return ""  
    end,  
    
    on_cost = function(self, event, room, player, data, lvzhi)  
        return lvzhi:askForSkillInvoke(self:objectName(), sgs.QVariant("give:" .. player:objectName()))  
    end,  
      
    on_effect = function(self, event, room, player, data, lvzhi)  
        room:notifySkillInvoked(lvzhi, self:objectName())  
        room:broadcastSkillInvoke(self:objectName(), lvzhi)  
          
        -- 从弃牌堆随机获取一张杀  
        local slash_ids = sgs.IntList()  
        for _, id in sgs.qlist(room:getDrawPile()) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:isKindOf("Slash") then  
                slash_ids:append(id)  
            end  
        end  
          
        if not slash_ids:isEmpty() then  
            -- 随机选择一张杀  
            local index = math.random(0, slash_ids:length() - 1)  
            local id = slash_ids:at(index)  
              
            -- 将杀移动给目标角色  
            local card = sgs.Sanguosha:getCard(id)  
            room:obtainCard(player, card, false)  
              
            -- 日志  
            local msg = sgs.LogMessage()  
            msg.type = "#YangbingGive"  
            msg.from = lvzhi  
            msg.to:append(player)  
            msg.arg = self:objectName()  
            msg.arg2 = card:objectName()  
            room:sendLog(msg)  
        end  
          
        return false  
    end  
}

zhensha = sgs.CreateTriggerSkill{  
    name = "zhensha",  
    events = {sgs.Dying},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local dying = data:toDying()  
        local lvzhi = room:findPlayerBySkillName(self:objectName())  
        if lvzhi and lvzhi:isAlive() and dying.who:objectName() == player:objectName() and player:getHp() <= 0 and not lvzhi:willBeFriendWith(player) then  
            return self:objectName(), lvzhi:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, lvzhi)  
        -- 检查是否有酒可以弃置  
        local analeptic = room:askForCard(lvzhi, "Analeptic,Peach", "@zhensha-discard:" .. player:objectName(), data, sgs.Card_MethodDiscard)  
        if analeptic then  
            lvzhi:setTag("zhensha_target", data)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, lvzhi)  
        room:notifySkillInvoked(lvzhi, self:objectName())  
        room:broadcastSkillInvoke(self:objectName(), lvzhi)  
          
        -- 设置标记，使目标跳过求桃阶段  
        --room:setPlayerFlag(player, "Global_PreventPeach")  
        --player:skip(sgs.AskForPeaches)
        local dying = data:toDying()
        room:killPlayer(player, dying.damage)
        -- 日志  
        local msg = sgs.LogMessage()  
        msg.type = "#zhenshaEffect"  
        msg.from = lvzhi  
        msg.to:append(player)  
        msg.arg = self:objectName()  
        room:sendLog(msg)  
          
        return false  
    end  
}

-- 创建蓄谋触发技能  
xumou = sgs.CreateTriggerSkill{  
    name = "xumou",  
    events = {sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
        room:broadcastSkillInvoke(self:objectName())  
          
        -- 摸三张牌  
        player:drawCards(3)  
          
        -- 进入叠置状态  
        player:turnOver()  
          
        return false  
    end,  
}

lvzhi:addSkill(yangbing)  
lvzhi:addSkill(zhensha)
lvzhi:addSkill(xumou)

sgs.LoadTranslationTable{  
    ["lvzhi"] = "吕雉",  
    ["#lvzhi"] = "汉高后",  
      
    ["yangbing"] = "养兵",  
    [":yangbing"] = "与你势力相同的角色回合结束时，若其本回合内未造成伤害，你可令其随机获得一张摸牌堆的杀。",  
      
    ["zhensha"] = "鸩杀",  
    [":zhensha"] = "当一名其他势力角色进入濒死状态时，你可以弃置一张桃或酒，令其跳过求桃阶段，立即死亡。",  
    ["@zhensha-discard"] = "你可以弃置一张酒，令 %src 跳过求桃阶段，立即死亡",  

    ["xumou"] = "蓄谋",  
    [":xumou"] = "回合结束时，你可以摸三张牌，然后进入叠置状态。",  
}

maosui = sgs.General(extension, "maosui", "wu", 3)  --jin,qun
  
zijian = sgs.CreateTriggerSkill{  
    name = "zijian",  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        local zijian_player = room:findPlayerBySkillName(self:objectName())
        if not zijian_player or not zijian_player:isAlive() then
            return ""
        end
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then  
            -- 其他角色回合结束时
            if zijian_player == player then
                room:setPlayerMark(player,"@zijian_draw",0)
            end
            if zijian_player ~= player and zijian_player:getCardCount(true) > 0 then
                return self:objectName(), zijian_player:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            if ask_who:askForSkillInvoke(self:objectName()) then  
                return true
            end  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            local cards = room:askForExchange(ask_who, self:objectName(), ask_who:getCardCount(true), 0)   
            for _,card in sgs.qlist(cards) do
                room:obtainCard(player, card, false)  
            end
            room:addPlayerMark(ask_who, "@zijian_draw", cards:length())    
        end
        return false  
    end  
}

-- 自荐摸牌效果  
zijian_draw = sgs.CreateDrawCardsSkill{  
    name = "zijian_draw",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n) 
        return n + math.min(player:getMark("@zijian_draw"),3)
    end  
}  

tuoying = sgs.CreateTriggerSkill{  
    name = "tuoying",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Start then  
            local source = room:findPlayerBySkillName(self:objectName())  
            if source and source:isAlive() then  
                local hand_num = source:getHandcardNum()  
                local unique = true  
                for _, p in sgs.qlist(room:getOtherPlayers(source)) do  
                    if p:getHandcardNum() == hand_num then  
                        unique = false  
                        break  
                    end  
                end  
                if unique then  
                    return self:objectName(), source:objectName()
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who) 
        --[[ 
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        ]]
        return ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(), data)
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        ask_who:drawCards(1, self:objectName())  
        return false  
    end,  
}
-- 添加技能到武将  
maosui:addSkill(zijian) 
maosui:addSkill(zijian_draw)  
maosui:addSkill(tuoying)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["maosui"] = "毛遂",  
    ["zijian"] = "自荐",  
    [":zijian"] = "其他角色回合结束时，你可交给其X张牌，然后你获得X个“荐”标记，你的下个摸牌阶段摸牌数增加标记数（至多+3）",
    ["tuoying"] = "脱颖",
    [":tuoying"] = "任意角色回合开始时，若你的手牌数和所有角色都不相同，你可以摸一张牌"
}

-- 创建武将：唐伯虎  
menghuo_hero = sgs.General(extension, "menghuo_hero", "shu", 4)  -- 吴国，4血，男性  
menghuo_hero_duan = sgs.General(extension, "menghuo_hero_duan", "shu", 4)  -- 吴国，4血，男性  
zhurong_hero = sgs.General(extension, "zhurong_hero", "shu", 3, false)  -- 吴国，4血，男性  

manwang = sgs.CreateViewAsSkill{  
    name = "manwang",  
    n = 2,  -- 需要选择2张牌  
    view_filter = function(self, selected, to_select)  
        -- 检查是否已选择2张牌  
        if #selected >= 2 then return false end  
        -- 检查牌是否正在使用中  
        if to_select:hasFlag("using") then return false end  
        -- 检查是否为【杀】  
        return to_select:isKindOf("Slash") and not to_select:isEquipped()  
    end,  
    view_as = function(self, cards)  
        -- 必须选择2张牌  
        if #cards ~= 2 then return nil end  
          
        -- 创建南蛮入侵卡牌  
        local savage = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, 0)  
          
        -- 添加子牌  
        for _, card in ipairs(cards) do  
            savage:addSubcard(card:getId())  
        end  
          
        -- 设置技能名称  
        savage:setSkillName(self:objectName())  
        savage:setShowSkill(self:objectName())  
          
        return savage  
    end,  
    enabled_at_play = function(self, player)  
        -- 在出牌阶段可以使用  
        return true  
    end  
}

manhou = sgs.CreateOneCardViewAsSkill{  
    name = "manhou",  
    filter_pattern = "Slash|.|.|hand",  -- 梅花手牌  
    view_as = function(self, card)  
        local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())  
        duel:addSubcard(card:getId())  
        duel:setSkillName(self:objectName())  --设置转化牌的技能名
        duel:setShowSkill(self:objectName())  --使用时亮将
        return duel  
    end  
}  

zongheng_card = sgs.CreateSkillCard{
    name = "zongheng",
    mute = true,
    target_fixed = true,
    will_throw = true,
    can_recast = false,
    
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@zongheng")  
        -- 播放技能音效
        room:broadcastSkillInvoke("zongheng", source)
        
        local subcards = self:getSubcards()
        if subcards:length() ~= 2 then
            return
        end
        
        -- 获取弃置牌的花色
        local card1 = sgs.Sanguosha:getCard(subcards:at(0))
        local card2 = sgs.Sanguosha:getCard(subcards:at(1))
        local target_suit = card1:getSuit()
        
        -- 记录技能发动日志
        local log = sgs.LogMessage()
        log.type = "#TriggerSkill"
        log.from = source
        log.arg = "zongheng"
        room:sendLog(log)
        
        -- 获取花色名称用于提示
        local suit_names = {
            [sgs.Card_Spade] = "spade",
            [sgs.Card_Heart] = "heart", 
            [sgs.Card_Club] = "club",
            [sgs.Card_Diamond] = "diamond"
        }
        local suit_name = suit_names[target_suit] or "unknown"
        
        -- 对所有其他角色进行处理
        local all_players = room:getOtherPlayers(source)
        for _, player in sgs.qlist(all_players) do
            if player:isAlive() then
                -- 询问是否弃置相同花色的牌

                local has_same_suit = false  
                for _, card in sgs.qlist(player:getHandcards()) do  
                    if card:getSuit() == suit then  
                        has_same_suit = true  
                        break  
                    end  
                end  
                local card_id = nil
                if has_same_suit then
                    local pattern = string.format(".|%s|.|hand", suit_name)  
                    local prompt = string.format("@discard-player:%s::%s",   
                                            source:objectName(), suit_name)  
                    
                    card_id = room:askForDiscard(player, self:objectName() .. "_player", 1, 1,   
                                    false, false, prompt, false, pattern) 
                end
                 
                if (not has_same_suit) or (card_id == nil) then
                    -- 玩家没有相同花色的牌或选择不弃，受到1点伤害
                    local damage = sgs.DamageStruct()
                    damage.from = source
                    damage.to = player
                    damage.damage = 1
                    damage.reason = "zongheng"
                    room:damage(damage)
                    
                    local log3 = sgs.LogMessage()
                    log3.type = "#ZonghengDamage"
                    log3.from = source
                    log3.to:append(player)
                    log3.arg = "zongheng"
                    room:sendLog(log3)
                end
            end
        end
    end
}

-- 纵横技能定义
zongheng = sgs.CreateViewAsSkill{
    name = "zongheng",
    n = 2,
    frequency = sgs.Skill_Limited,  
    limit_mark = "@zongheng",  

    view_filter = function(self, selected, to_select)
        -- 只能选择手牌，且需要选择两张相同花色的牌
        if to_select:isEquipped() then
            return false
        end
        
        if #selected == 0 then
            return true
        elseif #selected == 1 then
            -- 第二张牌必须与第一张牌花色相同
            return selected[1]:getSuit() == to_select:getSuit()
        else
            return false
        end
    end,
    
    view_as = function(self, cards)
        if #cards == 2 then
            local skillcard = zongheng_card:clone()
            skillcard:setSkillName("zongheng")
            for i = 1, #cards do
                skillcard:addSubcard(cards[i]:getId())
            end
            return skillcard
        end
        return nil
    end,
    
    enabled_at_play = function(self, player) 
        -- 检查是否已经使用过限定技（通过标记判断）
        if player:getMark("@zongheng") <= 0 then
            return false
        end
        
        -- 检查是否有至少两张相同花色的手牌
        local handcards = player:getHandcards()
        local suit_count = {}
        
        for _, card in sgs.qlist(handcards) do
            local suit = card:getSuit()
            if suit ~= sgs.Card_NoSuit then
                suit_count[suit] = (suit_count[suit] or 0) + 1
            end
        end
        
        for _, count in pairs(suit_count) do
            if count >= 2 then
                return true
            end
        end
        
        return false
    end
}

qizong = sgs.CreateTriggerSkill{  
    name = "qizong",
    frequency = sgs.Skill_Compulsory, --锁定技
    events = {sgs.HpChanged},  --集合，可以有多个触发条件
          
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        return self:objectName()
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        local slash_ids = sgs.IntList()  
        for _, id in sgs.qlist(room:getDrawPile()) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:isKindOf("Slash") then  
                slash_ids:append(id)  
            end  
        end  
          
        if not slash_ids:isEmpty() then  
            -- 随机选择一张杀  
            local index = math.random(0, slash_ids:length() - 1)  
            local id = slash_ids:at(index)  
              
            -- 将杀移动给目标角色  
            local card = sgs.Sanguosha:getCard(id)  
            room:obtainCard(player, card, false)  
              
            -- 日志  
            local msg = sgs.LogMessage()  
            msg.type = "#m1"  
            msg.from = player  
            msg.to:append(player)  
            msg.arg = self:objectName()  
            msg.arg2 = card:objectName()  
            room:sendLog(msg)  
        end  
        return false  
    end,
}  
menghuo_hero:addSkill(manwang)
menghuo_hero:addSkill(qizong)
menghuo_hero:addSkill("huoshou")
menghuo_hero_duan:addSkill(zongheng)
menghuo_hero_duan:addSkill("huoshou")
zhurong_hero:addSkill(manhou)
zhurong_hero:addSkill("juxiang")
sgs.LoadTranslationTable{
    ["menghuo_hero"] = "孟获",  
    ["menghuo_hero_duan"] = "孟获",  
    ["zhurong_hero"] = "祝融",  
    ["menghuo&zhurong"] = "孟获&祝融",  

    ["manwang"] = "蛮王",  
    [":manwang"] = "出牌阶段，你可以使用两张杀视为使用一张【南蛮入侵】。",  
    ["qizong"] = "七纵",
    [":qizong"] = "你体力值变化时，获得摸牌堆的一张杀",

    ["manhou"] = "蛮后",   
    [":manhou"] = "出牌阶段，你可以使用一张杀视为使用一张【决斗】。",

    ["zongheng"] = "纵横",
    [":zongheng"] = "限定技，出牌阶段，你可以弃置两张花色相同的手牌，令所有其他角色选择一项：1.弃置一张相同花色的牌；2.受到你造成的1点伤害。",
    ["@zongheng-discard"] = "纵横：你须弃置一张 %arg 牌，否则受到 %src 造成的1点伤害",
    ["@zongheng_used"] = "纵横",
    ["#ZonghengDiscard"] = "%from 因【纵横】弃置了一张 %arg 牌",
    ["#ZonghengDamage"] = "%from 因【%arg】对 %to 造成了1点伤害",
    ["spade"] = "♠",
    ["heart"] = "♥", 
    ["club"] = "♣",
    ["diamond"] = "♦",
    ["$zongheng1"] = "纵横天下，谁与争锋！",
    ["$zongheng2"] = "南蛮之力，不可小觑！",
    ["~menghuo"] = "南中...终将重新崛起...",
}

mengtian = sgs.General(extension, "mengtian", "shu", 4) -- 蜀势力，4血，男性（默认）  
zhengzhao = sgs.CreateZeroCardViewAsSkill{  
    name = "zhengzhao",  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#zhengzhaoCard") and not player:isKongcheng()
    end,  
    view_as = function(self)  
        local card = zhengzhaoCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end  
}  
  
-- 征召卡牌  
zhengzhaoCard = sgs.CreateSkillCard{  
    name = "zhengzhaoCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() 
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 交换手牌  
        if source:getHandcardNum() > 0 and target:getHandcardNum() > 0 then  
            local source_card = room:askForCardChosen(source, source, "h", self:objectName())  
            local target_card = room:askForCardChosen(target, target, "h", self:objectName())  
            room:obtainCard(source, target_card)
            room:obtainCard(target, source_card)
        end  
          
        local slash_ids = sgs.IntList()  
        for _, id in sgs.qlist(room:getDrawPile()) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:isKindOf("Slash") then  
                slash_ids:append(id)  
            end  
        end  
          
        if not slash_ids:isEmpty() then  
            -- 随机选择一张杀  
            local index = math.random(0, slash_ids:length() - 1)  
            local id = slash_ids:at(index)  
              
            -- 将杀移动给目标角色  
            local card = sgs.Sanguosha:getCard(id)  
            room:obtainCard(target, card, false)  
              
            -- 日志  
            local msg = sgs.LogMessage()  
            msg.type = "#YangbingGive"  
            msg.from = lvzhi  
            msg.to:append(player)  
            msg.arg = self:objectName()  
            msg.arg2 = card:objectName()  
            room:sendLog(msg)  
        end  
    end  
}  
haoling = sgs.CreateTriggerSkill{
	name = "haoling",
	events = {sgs.CardUsed},
    frequency = sgs.SKill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from == player then
				local target_list = {}
				for _, p in sgs.qlist(use.to) do
					if p ~= player then
						table.insert(target_list, p:objectName())
					end
				end
				if #target_list > 0 then
					return self:objectName() .. "->" .. table.concat(target_list, "+")
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, skill_target, data, player)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, skill_target, data, player)
		local use = data:toCardUse()
		local target_inRange = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:inMyAttackRange(skill_target) and p:objectName() ~= player:objectName() then
				target_inRange:append(p)
			end
		end
		if not target_inRange:isEmpty() then
			local target_askSlash = room:askForPlayerChosen(player, target_inRange, self:objectName(), "@JieAskto", false)
			if target_askSlash then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
				slash:deleteLater()
				local log = sgs.LogMessage()
				if slash:isAvailable(target_askSlash) then
					local log = sgs.LogMessage()
					if room:askForUseSlashTo(target_askSlash, skill_target, "@jieAskForSlash", true, false, false) then
						target_askSlash:drawCards(1, self:objectName())
					end
				end
			end
		end
		return false
	end
}

mengtian:addSkill(zhengzhao)  
mengtian:addSkill(haoling)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
      
    ["mengtian"] = "蒙恬",  
    ["#mengtian"] = "北地长城",  
    ["illustrator:mengtian"] = "未知",  
      
    ["zhengzhao"] = "征召",  
    [":zhengzhao"] = "出牌阶段限一次，你可与一名角色交换1张手牌，然后令其获得牌堆中的一张杀。",  
    ["zhengzhao_card"] = "征召",  
    ["@haoling-choose"] = "你可以选择一名角色，令其也对该目标出杀",  
      
    ["haoling"] = "号令",  
    [":haoling"] = "你使用杀指定目标后，你可以选择一名攻击范围内有该目标的其他角色，让其也对该目标出杀，若其出杀，其摸一张牌。",  
    ["@haoling-slash"] = "你可以对 %src 使用一张杀，若如此做，你摸一张牌",  
}  

-- 创建武将：
miyue = sgs.General(extension, "miyue", "qun", 3, false)  --qun,jin  
YuumieCard = sgs.CreateSkillCard{  
    name = "YuumieCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local subcard = sgs.Sanguosha:getCard(self:getSubcards():first())  
        local suit = subcard:getSuit() 
        
        local to_get = {}
        for _, card in sgs.qlist(target:getHandcards()) do  
            local id = card:getEffectiveId()  
            if card:getSuit() == suit then  
                table.insert(to_get, id)  
            end  
        end  
        if #to_get > 0 then  
            for _,id in ipairs(to_get) do
                room:obtainCard(source, id)
            end
        else  
            -- 若获得数为0，目标失去1点体力  
            room:loseHp(target, 1)  
        end  
    end  
}  
  
-- 诱灭视为技  
yuumie_vs = sgs.CreateViewAsSkill{  
    name = "yuumie",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0 and not to_select:isEquipped()  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = YuumieCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName("yuumie")  
            card:setShowSkill("yuumie")  
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#YuumieCard") and not player:isKongcheng()  
    end  
}  
  
-- 诱灭技能定义  
yuumie = sgs.CreateTriggerSkill{  
    name = "yuumie",  
    view_as_skill = yuumie_vs,  
    events = {}  
}

zhangquan = sgs.CreateTriggerSkill{
    name = "zhangquan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    
    can_trigger = function(self, event, room, player, data)
        -- 检查是否是芈月且存活
        if not player or not player:hasSkill("zhangquan") or not player:isAlive() then
            return ""
        end
        
        -- 检查伤害数据。这个可以去掉，没有伤害源，直接回血
        local damage = data:toDamage()
        if not damage or not damage.from or not damage.from:isAlive() then
            return ""
        end
        
        return self:objectName()
    end,
    
    on_cost = function(self, event, room, player, data)
        -- 询问是否发动技能
        local damage = data:toDamage()
        local prompt = string.format("@zhangquan-invoke:%s", damage.from:objectName())
        
        if room:askForSkillInvoke(player, "zhangquan", data) then
            room:broadcastSkillInvoke("zhangquan", player)
            return true
        end
        return false
    end,
    
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local source = damage.from
        
        -- 创建日志信息
        local log = sgs.LogMessage()
        log.type = "#TriggerSkill"
        log.from = player
        log.to:append(source)
        log.arg = self:objectName()
        room:sendLog(log)
        
        -- 询问伤害来源是否弃置一张手牌
        local prompt = string.format("@zhangquan-discard:%s", player:objectName())
        
        if source and source:isAlive() and not source:isKongcheng() and room:askForDiscard(source, "zhangquan", 1, 1, true, false, prompt) then --返回bool值
            -- 伤害来源选择弃置手牌
            local log2 = sgs.LogMessage()
            log2.type = "#ZhangquanDiscard"
            log2.from = source
            log2.to:append(player)
            log2.arg = self:objectName()
            room:sendLog(log2)
        else
            -- 伤害来源选择不弃置，芈月回复1点体力
            local recover = sgs.RecoverStruct()
            recover.who = player
            recover.recover = 1
            --recover.reason = "zhangquan"
            room:recover(player, recover)
            
            local log3 = sgs.LogMessage()
            log3.type = "#ZhangquanRecover"
            log3.from = player
            log3.arg = self:objectName()
            log3.arg2 = tostring(1)
            room:sendLog(log3)
        end
        
        return false
    end
}

zhangzheng = sgs.CreateTriggerSkill{  
    name = "zhangzheng",  
    events = {sgs.AskForRetrial},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if not player:isKongcheng() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local card = room:askForCardShow(player, player, self:objectName())  
        room:showCard(target, card:getId()) 

        local judge = data:toJudge()  
        local new_card = sgs.Sanguosha:getWrappedCard(judge.card:getEffectiveId())  --sgs.Sanguosha:getWrappedCard(id)返回的是包装后的卡牌对象（WrappedCard），这是房间内实际使用的、可以被修改的卡牌实例
        new_card:setNumber(card:getNumber())--这里是字符串，需要改成int
        new_card:setModified(true) --设置已修改，否则会重置为原来的属性

        judge.card = new_card
        room:broadcastUpdateCard(room:getPlayers(), judge.card:getEffectiveId(), new_card) --通知所有玩家，该判定牌变了
        -- 执行改判  
        --room:retrial(new_card, player, judge, self:objectName())  
        judge:updateResult()
        data:setValue(judge)
        return false  
    end  
}

miyue:addSkill(yuumie)
miyue:addSkill(zhangquan)
miyue:addSkill(zhangzheng)

sgs.LoadTranslationTable{
    ["hero"] = "英雄",  
    ["miyue"] = "芈月",
    ["#miyue"] = "权倾朝野",
    ["designer:miyue"] = "自定义",
    ["cv:miyue"] = "无",
    ["illustrator:miyue"] = "无",

    ["yuumie"] = "诱灭",
    [":yuumie"] = "出牌阶段限一次。你可以弃置一张手牌，获得一名角色手牌中所有和该牌花色相同的牌，若获得数为0，其失去一点体力。",

    ["zhangquan"] = "掌权",
    [":zhangquan"] = "当你受到伤害后，你可以令伤害来源弃置一张手牌，否则你回复1点体力。",
    ["@zhangquan-invoke"] = "掌权：你可以令 %src 弃置一张手牌，否则你回复1点体力",
    ["@zhangquan-discard"] = "掌权：你须弃置一张手牌，否则 %src 回复1点体力",
    ["#ZhangquanDiscard"] = "%from 因【%arg】弃置了一张手牌",
    ["#ZhangquanRecover"] = "%from 因【%arg】回复了 %arg2 点体力",
    ["$zhangquan1"] = "权柄在握，谁敢不从？",
    ["$zhangquan2"] = "掌权者，当以威服人！",
    ["zhangzheng"] = "掌政",
    [":zhangzheng"] = "判定生效前，你可以展示一张手牌，令判定牌点数改为与你展示的手牌相等",
    ["~miyue"] = "权势终有尽时...",
}

moxi = sgs.General(extension, "moxi", "shu", 3, false)
moxi_duan = sgs.General(extension, "moxi_duan", "shu", 3, false)

lieboCard = sgs.CreateSkillCard{
    name = "liebo",  
    target_fixed = true,  --不用选择目标
    will_throw = false,  
      
    on_use = function(self, room, source, targets)  
        source:drawCards(1)
        room:addPlayerMark(source, "@liebo")--没有回合开始前清除标记
        return false
    end
}

liebo = sgs.CreateZeroCardViewAsSkill{
    name = "liebo",  
    view_as = function(self)  
        local card = lieboCard:clone()
        card:setSkillName(self:objectName())  --设置转化牌的技能名
        card:setShowSkill(self:objectName())  --使用时亮将
        return card  
    end,
    enabled_at_play = function(self, player)  
        return player:getMaxCards() > 0
    end  
}     

-- 添加手牌上限修改效果  
lieboMaxCards = sgs.CreateMaxCardsSkill{  
    name = "#liebo_maxcards",  
    extra_func = function(self, player)
        return -player:getMark("@liebo")
    end  
}  

yaoji = sgs.CreateTriggerSkill{  
    name = "yaoji",  
    events = {sgs.EventPhaseStart},  
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        -- 检查是否为结束阶段且手牌数小于等于2  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        if player:getPhase() == sgs.Player_Play and  player:getMark("@liebo") > 0  then  
            room:setPlayerMark(player,"@liebo",0)
        elseif player:getPhase() == sgs.Player_Finish and player:getHandcardNum() < 2 then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        -- 选择两个目标：使用者和被使用者  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)  
        local source = room:askForPlayerChosen(player,  room:getAlivePlayers(), self:objectName())
        local target = room:askForPlayerChosen(player,  room:getOtherPlayers(source), self:objectName())  
          
        if source and target then  
            -- 创建【杀】并使用  
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:setSkillName(self:objectName())  
              
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = source  
            use.to:append(target)  
              
            room:useCard(use)  
            slash:deleteLater()
        end            
        return false  
    end  
}

lieboEndPlayPhase = sgs.CreateTriggerSkill{  
    name = "lieboEndPlayPhase",  
    events = {sgs.Damaged},  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local current = room:getCurrent()  
            -- 检查当前是否有回合角色且处于出牌阶段  
            if current and current:getPhase() == sgs.Player_Play then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 询问是否发动技能  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local current = room:getCurrent()  
        if current and current:getPhase() == sgs.Player_Play then  
            -- 设置 Global_PlayPhaseTerminated 标志位  
            room:setPlayerFlag(current, "Global_PlayPhaseTerminated")  
        end  
        return false  
    end  
}


yaojiExchange_card = sgs.CreateSkillCard{
    name = "yaojiExchange",
    mute = true,
    target_fixed = false,
    will_throw = false,
    can_recast = false,
    
    filter = function(self, targets, to_select)
        -- 只能选择一名其他角色
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    
    feasible = function(self, targets)
        -- 必须选择一名目标
        return #targets == 1
    end,
    
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local subcards = self:getSubcards()
        
        -- 播放技能音效
        room:broadcastSkillInvoke("yaojiExchange", source)
        
        -- 获取用户字符串来判断是部分交换还是全部交换
        local exchange_type = nil --self:getUserString()
        
        if subcards:length() == 0 or subcards:length() == source:getHandcardNum() then
            exchange_type = "all"
        else
            exchange_type = "partial"
        end
        if exchange_type == "partial" then
            -- 部分交换：交换等量手牌
            local exchange_count = subcards:length()
            exchange_count = math.min(target:getHandcardNum(), exchange_count)
            if exchange_count > 0 and target:getHandcardNum() >= exchange_count then
                -- 让目标角色选择等量的手牌
                local target_cards = room:askForExchange(target, "yaojiExchange", exchange_count, exchange_count, 
                                                       string.format("@yaojiExchange-exchange:%s::%d", source:objectName(), exchange_count),"", ".|.|.|hand")--suit|number|color|place
                
                if target_cards:length() == exchange_count then
                    -- 创建卡牌移动结构
                    local move1 = sgs.CardsMoveStruct()
                    move1.card_ids = subcards
                    move1.from = source
                    move1.to = target
                    move1.to_place = sgs.Player_PlaceHand
                    move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                    source:objectName(), target:objectName(), "yaojiExchange", "")
                    
                    local move2 = sgs.CardsMoveStruct()
                    move2.card_ids = target_cards
                    move2.from = target
                    move2.to = source
                    move2.to_place = sgs.Player_PlaceHand
                    move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                    target:objectName(), source:objectName(), "yaojiExchange", "")
                    
                    local moves = sgs.CardsMoveList()
                    moves:append(move1)
                    moves:append(move2)
                    
                    room:moveCardsAtomic(moves, true)
                    
                    -- 记录日志
                    local log = sgs.LogMessage()
                    log.type = "#exchangePartial"
                    log.from = source
                    log.to:append(target)
                    log.arg = tostring(exchange_count)
                    room:sendLog(log)
                end
            end
        else
            -- 全部交换：交换所有手牌
            local source_handcards = sgs.IntList()
            local target_handcards = sgs.IntList()
            
            -- 获取双方所有手牌
            for _, card in sgs.qlist(source:getHandcards()) do
                source_handcards:append(card:getId())
            end
            
            for _, card in sgs.qlist(target:getHandcards()) do
                target_handcards:append(card:getId())
            end
            
            if not source_handcards:isEmpty() or not target_handcards:isEmpty() then
                local move1 = sgs.CardsMoveStruct()
                move1.card_ids = source_handcards
                move1.from = source
                move1.to = target
                move1.to_place = sgs.Player_PlaceHand
                move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                source:objectName(), target:objectName(), "yaojiExchange", "")
                
                local move2 = sgs.CardsMoveStruct()
                move2.card_ids = target_handcards
                move2.from = target
                move2.to = source
                move2.to_place = sgs.Player_PlaceHand
                move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                target:objectName(), source:objectName(), "yaojiExchange", "")
                
                local moves = sgs.CardsMoveList()
                moves:append(move1)
                moves:append(move2)
                
                room:moveCardsAtomic(moves, true)
                
                -- 记录日志
                local log = sgs.LogMessage()
                log.type = "#exchangeAll"
                log.from = source
                log.to:append(target)
                log.arg = tostring(source_handcards:length())
                log.arg2 = tostring(target_handcards:length())
                room:sendLog(log)
            end
        end
    end
}

-- 换牌技能定义
yaojiExchange = sgs.CreateViewAsSkill{
    name = "yaojiExchange",
    n = 998,
    
    view_filter = function(self, selected, to_select)
        -- 只能选择手牌
        return not to_select:isEquipped()
    end,
    
    view_as = function(self, cards)
        local skillcard = yaojiExchange_card:clone()
        if #cards > 0 then
            for i = 1, #cards do
                skillcard:addSubcard(cards[i]:getId())
            end
        end
        skillcard:setSkillName("yaojiExchange")
        skillcard:setShowSkill("yaojiExchange")
        return skillcard
    end,
    
    enabled_at_play = function(self, player)
        -- 每回合限用一次
        return not player:hasUsed("#yaojiExchange") and not player:isKongcheng()
    end
}
-- 妺喜武将定义
moxi:addSkill(liebo)
moxi:addSkill(lieboMaxCards)
moxi:addSkill(yaoji)
moxi_duan:addSkill(lieboEndPlayPhase)
moxi_duan:addSkill(yaojiExchange)
-- 技能音效和翻译配置
sgs.LoadTranslationTable{
    ["hero"] = "英雄",
    ["moxi"] = "妺喜",
    ["moxi_duan"] = "妺喜",
    ["&moxi"] = "妺喜",
    ["#moxi"] = "倾国倾城",
    ["designer:moxi"] = "自定义",
    ["cv:moxi"] = "无",
    ["illustrator:moxi"] = "无",
    
    ["yaojiExchange"] = "妖姬",
    [":yaojiExchange"] = "出牌阶段限一次，你可以选择：1.将任意数量的手牌和另一名角色交换等量的手牌；2.将所有手牌和另一名角色交换所有手牌。",
    ["@yaojiExchange-exchange"] = "妖姬：请选择 %arg 张手牌与 %src 交换",
    ["#exchangePartial"] = "%from 与 %to 交换了 %arg 张手牌",
    ["#exchangeAll"] = "%from 与 %to 交换了所有手牌（%from: %arg 张，%to: %arg2 张）",
    ["$exchange1"] = "以手中牌，换君心意。",
    ["$exchange2"] = "此牌换彼牌，情深意更长。",

    ["liebo"] = "裂帛",  
    [":liebo"] = "出牌阶段，你可以令本回合手牌上限-1，然后你摸一张牌。",  
      
    ["yaoji"] = "妖姬",   
    [":yaoji"] = "结束阶段，若你的手牌数小于2，你可令一名角色视为对另一名角色使用杀。",

    ["lieboEndPlayPhase"] = "裂帛",
    [":lieboEndPlayPhase"] = "当你受到伤害后，你可以令当前回合角色结束出牌阶段",

    ["~moxi"] = "红颜薄命，终是一场空..."
}


mozi = sgs.General(extension, "mozi", "qun", 3)  -- 群雄，3血  
  
-- 技能：烽火 - 将装备牌视为南蛮入侵  
jianai = sgs.CreateOneCardViewAsSkill{  
    name = "jianai",  
    filter_pattern = ".|heart|.|hand",  -- 手牌或装备区的装备牌  
            
    view_as = function(self, card)  
        local AmazingGrace = sgs.Sanguosha:cloneCard("AmazingGrace", card:getSuit(), card:getNumber())  
        AmazingGrace:addSubcard(card:getId())  
        AmazingGrace:setSkillName(self:objectName())  
        AmazingGrace:setShowSkill(self:objectName())  
        return AmazingGrace  
    end,
    
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#jianai") and not player:isKongcheng()  
    end  
}  

feigong = sgs.CreateOneCardViewAsSkill{  
    name = "feigong",  
    filter_pattern = ".|diamond|.|hand",  -- 手牌或装备区的装备牌  
            
    view_as = function(self, card)  
        local AllianceFeast = sgs.Sanguosha:cloneCard("AllianceFeast", card:getSuit(), card:getNumber())  
        AllianceFeast:addSubcard(card:getId())  
        AllianceFeast:setSkillName(self:objectName())  
        AllianceFeast:setShowSkill(self:objectName())  
        return AllianceFeast  
    end,

    enabled_at_play = function(self, player)  
        return not player:hasUsed("#feigong") and not player:isKongcheng()  
    end  
}  

feigongSlash = sgs.CreateTriggerSkill{  
    name = "feigongSlash",  
    events = {sgs.SlashEffected},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        local effect = data:toSlashEffect()  
        owner = room:findPlayerBySkillName(self:objectName())
        -- 检查是否是技能拥有者使用的杀  
        if effect.to and effect.to:isAlive() then  
            return self:objectName(), owner:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local effect = data:toSlashEffect()  
        local target = effect.to  
          
        -- 询问是否发动技能  
        local ai_data = sgs.QVariant()  
        ai_data:setValue(target)  
          
        if room:askForSkillInvoke(ask_who, self:objectName(), ai_data) then  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local effect = data:toSlashEffect()  
        local target = effect.to  
          
        -- 摸一张牌  
        room:drawCards(ask_who, 1, self:objectName())  
          
        -- 如果有牌，交给目标一张牌  
        if not ask_who:isNude() then  
            --local card_id = room:askForCard(ask_who, ".|.|.|hand,equipped", "@feigongSlash-give:" .. target:objectName(), sgs.QVariant(), sgs.Card_MethodNone)  
            --local card_id = room:askForCardChosen(ask_who, ask_who, "he", self:objectName())  
            local card_ids = room:askForExchange(ask_who, "feigongSlash", 1, 1)  
            for _,card_id in sgs.qlist(card_ids) do  
                room:obtainCard(target, card_id, false)  
            end  
        end  
          
        return false  
    end  
}

-- 添加技能给武将  
mozi:addSkill(jianai)  
mozi:addSkill(feigong)  
mozi:addSkill(feigongSlash)  

sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["mozi"] = "墨子",  
    ["#mozi"] = "墨家",   
    ["jianai"] = "兼爱",  
    [":jianai"] = "出牌阶段限一次。你可以将一张红桃手牌当做【五谷丰登】使用。",  
      
    ["feigong"] = "非攻",  
    [":feigong"] = "出牌阶段限一次。你可以将一张方块手牌当做【联军盛宴】使用。",  
      
    ["feigongSlash"] = "非攻-杀",  
    [":feigongSlash"] = "任意角色成为杀的目标时，你可以摸一张牌，然后交给其一张牌。",  
    ["@feigongSlash-give"] = "你可以交给 %src 一张手牌"  
}

murong = sgs.General(extension, "murong", "wei", 4)  --或者把虞姬放到qun？

diehun = sgs.CreateTriggerSkill{  
    name = "diehun",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local use = data:toCardUse()  
            local card = use.card  
            -- 检查是否为锦囊牌且目标数大于1  
            if card and card:isKindOf("TrickCard") and use.to:length() > 1 then  
                -- 检查当前玩家是否在目标列表中  
                for _, target in sgs.qlist(use.to) do  
                    if target:objectName() == player:objectName() then  
                        return self:objectName()  
                    end  
                end  
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
        -- 选择一名角色摸牌  
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end  
          
        if targets:isEmpty() then return false end  
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "diehun-invoke")  
        if target then  
            target:drawCards(1, self:objectName())  
        end  
        local use = data:toCardUse()  
        --room:cancelTarget(use, player)  
        sgs.Room_cancelTarget(use, player)
        data:setValue(use)  
        return false  
    end,  
}

murong:addSkill(diehun)
sgs.LoadTranslationTable{
["murong"] = "慕容",
["diehun"] = "蝶魂",  
[":diehun"] = "当你成为锦囊的目标时，若目标数大于1，你可以令任意一名势力相同的角色摸1张牌，并令该锦囊对自己无效",
}

-- 创建武将：聂隐娘，蜀势力，女性，3血  
nieyinniang = sgs.General(extension, "nieyinniang", "shu", 3, false)

yingxi = sgs.CreateTriggerSkill{  
    name = "yingxi",  
    events = {sgs.EventPhaseStart, sgs.Damaged, sgs.DamageInflicted},--, sgs.DrawNCards, sgs.AttackRange, sgs.DamageCaused},  
    frequency = sgs.SKill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        if event == sgs.EventPhaseStart then  
            -- 准备阶段开始时  
            if player:getPhase() == sgs.Player_Start then  
                return self:objectName()  
            end  
        elseif event == sgs.Damaged then  
            -- 受到伤害后  
            return self:objectName()  
        elseif event == sgs.DamageInflicted then  
            -- 受到伤害时，可以移除隐匿标记免疫伤害  
            if player:getMark("@yinni") > 0 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart or event == sgs.Damaged then  
            -- 询问是否弃置黑色牌获得隐匿标记  
            if player:askForSkillInvoke(self:objectName(), data) then  
                --local card_id = room:askForCardChosen(player, player, "he", "@yingxi-discard")  
                local card_id = room:askForCard(player, ".|black", "@yingxi-discard", data, sgs.Card_MethodDiscard)  
                if card_id then  
                    --[[
                    local card = sgs.Sanguosha:getCard(card_id)  
                    if card:isBlack() then 
                        room:throwCard(card_id, player, player)  
                        room:broadcastSkillInvoke(self:objectName())  
                        return true  
                    end  
                    ]]
                    return true
                end  
            end  
        elseif event == sgs.DamageInflicted then  
            -- 询问是否移除隐匿标记免疫伤害  
            if player:askForSkillInvoke(self:objectName() .. "_immune", data) then  
                room:broadcastSkillInvoke(self:objectName())  
                return true  
            end  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart or event == sgs.Damaged then  
            -- 获得隐匿标记  
            room:addPlayerMark(player, "@yinni", 1)  
            --room:setPlayerMark(player, "@yinni", player:getMark("yinni"))  
        elseif event == sgs.DamageInflicted then  
            -- 移除隐匿标记，免疫伤害  
            room:removePlayerMark(player, "@yinni", 1)  
            --room:setPlayerMark(player, "@yinni", player:getMark("yinni"))  
            return true -- 返回true阻止伤害  
        end  
        return false  
    end  
}  
  
-- 创建摸牌阶段摸牌+1的技能  
yingxi_draw = sgs.CreateDrawCardsSkill{  
    name = "#yingxi-draw",  
    draw_num_func = function(self, player, n)  
        if player:getMark("@yinni") > 0 then  
            return n + 1  
        end  
        return n  
    end  
}  
  
-- 创建攻击范围+1的技能  
yingxi_range = sgs.CreateAttackRangeSkill{  
    name = "#yingxi-range",  
    extra_func = function(self, player)  
        if player:getMark("@yinni") > 0 then  
            return 1  
        end  
        return 0  
    end  
}  
  
-- 创建杀造成伤害+1的技能  
yingxi_damage = sgs.CreateTriggerSkill{  
    name = "#yingxi-damage",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill("yingxi") and player:getMark("@yinni") > 1 then  
            local damage = data:toDamage()  
            if damage.card and damage.card:isKindOf("Slash") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}

nieyinniang:addSkill(yingxi)  
nieyinniang:addSkill(yingxi_draw)  
nieyinniang:addSkill(yingxi_range)  
nieyinniang:addSkill(yingxi_damage)  
extension:insertRelatedSkills("yingxi","#yingxi-draw")
extension:insertRelatedSkills("yingxi","#yingxi-range")
extension:insertRelatedSkills("yingxi","#yingxi-damage")
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
      
    ["nieyinniang"] = "聂隐娘",  
    ["#nieyinniang"] = "刺客之魂",  
    ["illustrator:nieyinniang"] = "未知",  
      
    ["yingxi"] = "影袭",  
    [":yingxi"] = "准备阶段或受到伤害后，你可以弃置一张黑色牌，获得一个'隐匿'标记；若你的'隐匿'标记：大于0，摸牌阶段摸牌量+1，攻击范围+1；大于1，杀造成的伤害+1；受到伤害时，你可以移除一个'隐匿'标记，免疫此次伤害。",  
      
    ["@yinni"] = "隐匿",  
    ["@yingxi-discard"] = "你可以弃置一张黑色牌发动'影袭'",  
    ["yingxi_immune"] = "影袭免疫",  
}  

panan = sgs.General(extension, "panan", "wu", 4)  -- 群雄，4血  
panan:addSkill("fangquan")
panan:addSkill("xingshang")
sgs.LoadTranslationTable{  
    ["panan"] = "潘安"
}
-- 创建武将：齐桓公  
qihuangong = sgs.General(extension, "qihuangong", "qun", 4)  -- 群雄，4血  
  
-- 技能1：制霸 - 出牌阶段限一次，你可以选择一名角色进行拼点，若你赢，该回合你的手牌上限+2  
zhibaCard = sgs.CreateSkillCard{  
    name = "zhiba",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 显示技能发动效果  
        room:notifySkillInvoked(source, "zhiba")  
          
        -- 进行拼点  
        local success = source:pindian(target, "zhiba")  
          
        -- 如果拼点成功，增加手牌上限  
        if success then  
            --room:setPlayerMark(source, "@zhiba_win", 1)  
            room:setPlayerFlag(source, "zhiba_win")  
              
            -- 显示增加手牌上限的提示  
            local msg = sgs.LogMessage()  
            msg.type = "#ZhibaSuccess"  
            msg.from = source  
            msg.arg = 2  
            msg.arg2 = "zhiba"  
            room:sendLog(msg)  
        else
            --room:setPlayerMark(source, "@zhiba_win", 0)
            room:setPlayerFlag(source, ".")  --自动清除？
        end  
    end  
}  
  
zhiba = sgs.CreateZeroCardViewAsSkill{  
    name = "zhiba",  
      
    view_as = function(self)  
        local card = zhibaCard:clone()  
        card:setSkillName(self:objectName())  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#zhiba") and not player:isKongcheng()  
    end  
}  

-- 技能2：霸业 - 当你的拼点结算后，你获得点数大的牌  
baye = sgs.CreateTriggerSkill{  
    name = "baye",  
    events = {sgs.Pindian},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        local pindian = data:toPindian()  
        if pindian.from:objectName() == player:objectName() or pindian.to:objectName() == player:objectName() then  
            return self:objectName()  
        end  
          
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  -- 强制技能，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local pindian = data:toPindian()  
        local winner, loser  
          
        -- 确定赢家和输家  
        if pindian.from_number == pindian.to_number then  
            return false
        end
        if pindian.from_number > pindian.to_number then  
            winner = pindian.from  
            loser = pindian.to  
        else  
            winner = pindian.to  
            loser = pindian.from  
        end  
          
        -- 如果玩家是拼点的参与者，获得点数大的牌  
        if winner:objectName() == player:objectName() or loser:objectName() == player:objectName() then  
            local card = (winner:objectName() == pindian.from:objectName()) and pindian.from_card or pindian.to_card
              
            room:sendCompulsoryTriggerLog(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName(), player)  
              
            -- 获得点数大的牌  
            if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceTable then  
                player:obtainCard(card)  
                  
                -- 显示获得牌的提示  
                local msg = sgs.LogMessage()  
                msg.type = "#BayeObtain"  
                msg.from = player  
                msg.arg = card:getNumber()  
                msg.arg2 = self:objectName()  
                room:sendLog(msg)  
            end  
        end  
          
        return false  
    end  
}  
  
-- 添加手牌上限修改效果  
zhibaMaxCards = sgs.CreateMaxCardsSkill{  
    name = "#zhiba_maxcards",  
    extra_func = function(self, player)  
        if player:hasFlag("zhiba_win") then  --卡牌上限技是全场生效，所以一定要加条件，如技能、标记
            return 2  
        else  
            return 0  
        end  
    end  
}  
  
-- 添加技能给武将  
qihuangong:addSkill(zhiba)  
qihuangong:addSkill(baye)  
qihuangong:addSkill(zhibaMaxCards)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["qihuangong"] = "齐桓公",  
    ["#qihuangong"] = "春秋五霸",
    ["zhiba"] = "制霸",  
    [":zhiba"] = "出牌阶段限一次，你可以选择一名角色进行拼点，若你赢，该回合你的手牌上限+2。",  
    ["#ZhibaSuccess"] = "%from 的【%arg2】技能被触发，手牌上限+%arg",  
      
    ["baye"] = "霸业",  
    [":baye"] = "锁定技，当你的拼点结算后，你获得点数大的牌。",  
    ["#BayeObtain"] = "%from 发动了【%arg2】，获得了点数为 %arg 的拼点牌",  
      
    ["~qihuangong"] = "寡人竟败于此，悔不该骄傲自满！"  
}  

qijiguang = sgs.General(extension, "qijiguang", "wu", 4)  -- 吴国，4血，男性  
-- 技能1：纪效  
jixiao = sgs.CreateZeroCardViewAsSkill{  
    name = "jixiao",  
    view_as = function(self)  
        local card = JixiaoCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#JixiaoCard") and player:getAttackRange() >= 1  
    end  
}  
  
-- 纪效卡牌类  
JixiaoCard = sgs.CreateSkillCard{  
    name = "JixiaoCard",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)  
        local max_range = source:getAttackRange()  
        if max_range < 1 then return end  
          
        -- 让玩家选择减少的攻击范围  
        local choices = {}  
        for i = 1, max_range do  
            table.insert(choices, tostring(i))  
        end  
          
        local choice = room:askForChoice(source, "jixiao", table.concat(choices, "+"))  
        local reduce_range = tonumber(choice)  
          
        -- 设置攻击范围减少标记  
        room:setPlayerMark(source, "@jixiao_reduce", reduce_range)  
          
        -- 摸X张牌  
        source:drawCards(reduce_range, "jixiao")  
          
        room:broadcastSkillInvoke("jixiao", source)  
    end  
}  
  
-- 纪效攻击范围技能  
jixiao_range = sgs.CreateAttackRangeSkill{  
    name = "#jixiao-range",  
    extra_func = function(self, player, include_weapon)  
        local reduce = player:getMark("@jixiao_reduce")  
        if reduce > 0 then  
            return -reduce  
        end  
        return 0  
    end  
}  
  
-- 技能2：狼羌  
--[[
langqiang = sgs.CreateViewAsSkill{  
    name = "langqiang",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0   
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = LangqiangCard:clone()  
            card:setSkillName(self:objectName())
            card:setShowSkill(self:objectName())  
            card:addSubcard(cards[1])  
            return card  
        end  
        return nil  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#LangqiangCard") and not player:isNude()  
    end  
}  
  
-- 狼羌卡牌类  
LangqiangCard = sgs.CreateSkillCard{  
    name = "LangqiangCard",  
    target_fixed = true,  
    will_throw = true,  
    on_use = function(self, room, source, targets)  
        local subcard_id = self:getSubcards():first()  
        local subcard = sgs.Sanguosha:getCard(subcard_id)  
          
        if subcard:isKindOf("EquipCard") then  
            -- 如果是装备牌，则使用之  
            local use = sgs.CardUseStruct()  
            use.card = subcard  
            use.from = source  
            use.to:append(source)  
            room:useCard(use, false)  
        else  
            -- 否则弃置  
            room:throwCard(self, source)  
        end  
          
        -- 增加攻击范围  
        room:setPlayerMark(source, "@langqiang_add", 1)  
          
        room:broadcastSkillInvoke("langqiang", source)  
    end  
}  
  
-- 狼羌攻击范围技能  
langqiang_range = sgs.CreateAttackRangeSkill{  
    name = "#langqiang-range",  
    extra_func = function(self, player, include_weapon)  
        return player:getMark("@langqiang_add")  
    end  
}  

-- 回合结束时清除标记的技能  
qijiguang_clear = sgs.CreateTriggerSkill{  
    name = "qijiguang-clear",  
    events = {sgs.EventPhaseChanging},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local change = data:toPhaseChange()  
        if change.to == sgs.Player_NotActive and 
        (player:getMark("@jixiao_reduce") > 0 or player:getMark("@langqiang_add") > 0) then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:setPlayerMark(player, "@jixiao_reduce", 0)  
        room:setPlayerMark(player, "@langqiang_add", 0)  
        return false  
    end  
}  
]]

langqiang = sgs.CreateTriggerSkill{  
    name = "langqiang",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},  
    frequency = sgs.SKill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            if player:getPhase() == sgs.Player_Play then  
                local invoker = room:findPlayerBySkillName(self:objectName())  
                if invoker and invoker:isAlive() and not invoker:isNude() and invoker:willBeFriendWith(player) then  
                    return self:objectName(), invoker:objectName()
                end  
            end  
        elseif event == sgs.EventPhaseChanging then  
            local change = data:toPhaseChange()  
            if change.to == sgs.Player_NotActive then  
                -- 回合结束时清除标记
                -- 另一个技能的标记也在这里清除
                if player:getMark("@langqiang_range") > 0 then  
                    room:setPlayerMark(player, "@langqiang_range", 0)  
                end  
                if player:getMark("@langqiang_slash") > 0 then  
                    room:setPlayerMark(player, "@langqiang_slash", 0)  
                end  
                if player:getMark("@jixiao_reduce") > 0 then
                    room:setPlayerMark(player, "@jixiao_reduce", 0) 
                end
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            return ask_who:askForSkillInvoke(self:objectName(),data)
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then
            local card_id = room:askForCardChosen(ask_who,ask_who,"he",self:objectName())
            local card = sgs.Sanguosha:getCard(card_id)
            if card:isKindOf("EquipCard") then  
                -- 如果是装备牌,目标使用之  
                local use = sgs.CardUseStruct()  
                use.card = card  
                use.from = player  
                use.to:append(player)  
                room:useCard(use, false)  
            else  
                -- 否则弃置  
                room:throwCard(card_id, ask_who)  
            end  
            
            -- 增加攻击范围  
            room:addPlayerMark(player, "@langqiang_range")  
            
            -- 增加使用杀次数  
            room:addPlayerMark(player, "@langqiang_slash")
        end  
        return false  
    end  
}  
  
-- 狼羌攻击范围技能  
langqiang_range = sgs.CreateAttackRangeSkill{  
    name = "#langqiang-range",  
    extra_func = function(self, player, include_weapon)  
        return player:getMark("@langqiang_range")  
    end  
}  

-- 狼羌杀次数技能  
langqiang_targetmod = sgs.CreateTargetModSkill{  
    name = "#langqiang-slash",  
    residue_func = function(self, player, card)  
        if player:getMark("@langqiang_slash") > 0 and card and card:isKindOf("Slash") then  
            return player:getMark("@langqiang_slash")  
        end  
        return 0  
    end  
}
  
-- 添加技能到武将  
qijiguang:addSkill(jixiao)  
qijiguang:addSkill(jixiao_range)  
qijiguang:addSkill(langqiang)  
qijiguang:addSkill(langqiang_range)  
qijiguang:addSkill(langqiang_targetmod)
--qijiguang:addSkill(qijiguang_clear)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["qijiguang"] = "戚继光",  
    ["#qijiguang"] = "抗倭名将",  
    ["jixiao"] = "纪效",  
    [":jixiao"] = "出牌阶段限一次，你可以令本回合攻击范围-X，然后摸X张牌，X最大为你的攻击范围。",  
    ["JixiaoCard"] = "纪效",  
    ["langqiang"] = "狼羌",  
    --[":langqiang"] = "出牌阶段限一次，你可以弃置1张牌，令本回合攻击范围+1，若弃置的牌为装备牌，则改为使用之。",  
    [":langqiang"] = "与你势力相同的角色出牌阶段开始时，你可以弃置1张牌，令其本回合攻击范围+1，使用杀次数+1，若弃置的牌为装备牌，则改为其使用之。",
    ["LangqiangCard"] = "狼羌"  
}

qinqiong = sgs.General(extension, "qinqiong", "wei", 4)  --shu  

-- 创建补刀触发技能  
fanji = sgs.CreateTriggerSkill{  
    name = "fanji",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data) 
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local damage = data:toDamage()  
        if damage.from and damage.from:isAlive() and damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then                
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        local source = damage.from  

        if source then  
            --[[
            local prompt = string.format("@fanji-slash:%s:%s:", source:objectName(), player:objectName())  
            room:askForUseSlashTo(player, source, prompt, false, false, false)
            ]]
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            slash:setSkillName("fanji")  
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = player  
            use.to:append(source)  
            room:useCard(use) 
            slash:deleteLater()
        end  
        return false  
    end  
}  

menshen = sgs.CreateTriggerSkill{  
    name = "menshen",  
    events = {sgs.EventPhaseStart, sgs.CardEffected},  
    frequency = sgs.Skill_Limited,
    limit_mark = "@menshen",
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            if not (player and player:isAlive()) then
                return ""
            end
            if player:hasSkill(self:objectName()) then
                if player:getPhase() == sgs.Player_Start then --自己准备阶段清除标记
                    room:setPlayerMark(player,"@menshen",1)
                    --把标记清除掉
                    for _,p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getMark("@menshen_target") > 0 then
                            room:setPlayerMark(p,"@menshen_target",0)
                        end
                    end
                end
            end
            if player:getPhase() == sgs.Player_Play then
                local source = room:findPlayerBySkillName(self:objectName())
                if not (source and source:isAlive() and source:getMark("@menshen")>0) then 
                    return ""
                end
                return self:objectName(), source:objectName()
            end
        elseif event == sgs.CardEffected then  
            -- 当有角色成为杀或决斗目标时检查重定向  
            local effect = data:toCardEffect()  
            if effect.card and (effect.card:isKindOf("Slash") or effect.card:isKindOf("Duel")) 
                and effect.to and effect.to:getMark("@menshen_target") > 0 then  
                local source = room:findPlayerBySkillName(self:objectName())  
                if source and source:isAlive() and source ~= effect.to then  
                    return self:objectName(), source:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            return ask_who:askForSkillInvoke(self:objectName(),data)
        else  
            return true -- 重定向不需要额外消耗  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(ask_who)) do  
                if p:isAlive() then  
                    targets:append(p)  
                end  
            end  
            if targets:isEmpty() then return false end  
              
            local target = room:askForPlayerChosen(ask_who, targets, self:objectName(),   
                                                 "menshen-invoke", true, true)  
            if target and target:isAlive() then  
                -- 设置新标记  
                room:setPlayerMark(target, "@menshen_target", 1)  
                room:setPlayerMark(ask_who,"@menshen",0)
            end  
        elseif event == sgs.CardEffected then  
            local effect = data:toCardEffect()  
            local source = ask_who  
            if source and source:isAlive() then  
                -- 重定向目标  
                effect.to = source  
                --data = sgs.QVariant()  
                data:setValue(effect)  
            end  
        end  
        return false  
    end  
}  

qinqiong:addSkill(fanji)
qinqiong:addSkill(menshen)
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["qinqiong"] = "秦琼",
    ["fanji"] = "反击",  
    [":fanji"] = "当你受到杀或者决斗的伤害后，你可以视为对伤害来源使用一张杀。",  
    ["menshen"] = "门神",
    [":menshen"] = "每轮限一次。任意角色出牌阶段开始时，你可以指定一名角色获得“门神”标记，则直到你的下回合开始前，其成为杀或决斗的目标时，目标改为你。"
}

shangguanwaner = sgs.General(extension, "shangguanwaner", "qun", 3, false)  

nvxiang = sgs.CreateTriggerSkill{  
    name = "nvxiang",  
    events = {sgs.TargetConfirming}, --SlashEffected
      
    can_trigger = function(self, event, room, player, data)   
        --TargetConfirmed是卡牌使用
        local use = data:toCardUse()  
        if not use.card:isKindOf("Slash") then return "" end  
        local from = use.from
        --SlashEffected是杀生效
        --local effect = data:toSlashEffect()
        --local from = effect.from

        local owner = room:findPlayerBySkillName(self:objectName())  
        if owner and owner:isAlive() and not owner:isKongcheng() and   
        not from:isKongcheng() and owner:objectName() ~= from:objectName() then  
            return self:objectName(), owner:objectName()
        end  

        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, shangguanwaner)  
        if shangguanwaner:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), shangguanwaner)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, shangguanwaner)
        local use = data:toCardUse()
        local from = use.from
        --local effect = data:toSlashEffect()
        --local from = effect.from          
        -- 发起拼点  
        local success = shangguanwaner:pindian(from, self:objectName())  
        if success then  
            -- 上官婉儿拼点赢，使杀无效  
            for _, p in sgs.qlist(use.to) do  
                use.to:removeOne(p)
            --    room:cancelTarget(use, p)
            --    sgs.Room_cancelTarget(use, p)
            end  
            data:setValue(use) --用以上方式修改use后，需要setValue
            -- 日志  
            local msg = sgs.LogMessage()  
            msg.type = "#NvxiangEffect"  
            msg.from = shangguanwaner  
            msg.to:append(player)  
            msg.arg = self:objectName()  
            msg.arg2 = use.card:objectName()  
            room:sendLog(msg)  
            --return true --终止杀结算
        end  
        return false  
    end  
}

yicai = sgs.CreateTriggerSkill{  
    name = "yicai",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then return "" end  
        if player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName())  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
          
        local red_cards = {}  
          
        repeat  
            local judge = sgs.JudgeStruct()  
            judge.pattern = ".|red"  --第一个点表示任意类型，第二个点表示任意花色
            judge.good = true  
            judge.play_animation = false  
            judge.who = player  
            judge.reason = self:objectName()  
              
            room:judge(judge)  
            table.insert(red_cards, judge.card:getId()) 
            --[[
            if judge.card:isRed() then  
                table.insert(red_cards, judge.card:getId())  
            end 
            ]] 
        until judge.card:isBlack()  
          
        if #red_cards > 0 then  
            -- 获得所有红色判定牌  
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            for _, id in ipairs(red_cards) do  
                dummy:addSubcard(id)  
            end  
              
            room:obtainCard(player, dummy, false)  
            dummy:deleteLater()  
        end  
        room:askForDiscard(player, self:objectName(), 1, 1, false, true)  
        return false  
    end  
}

shangguanwaner:addSkill(nvxiang)  
shangguanwaner:addSkill(yicai)

sgs.LoadTranslationTable{  
    ["shangguanwaner"] = "上官婉儿",  
    ["#shangguanwaner"] = "才女",  
      
    ["nvxiang"] = "女相",  
    [":nvxiang"] = "当一名角色成为杀的目标时，你可以与其拼点，若你赢，则该杀无效。",  
    ["#NvxiangEffect"] = "%from 发动了'%arg'，使 %to 的 %arg2 无效",  
      
    ["yicai"] = "绮才",  
    [":yicai"] = "准备阶段，你可以发起判定，直到判定牌为黑色，你获得所有判定牌，然后你弃置1张牌",  
}

 
-- 创建武将：唐伯虎  
shangzhou = sgs.General(extension, "shangzhou", "qun", 4)  -- 吴国，4血，男性  

zhongpanVS = sgs.CreateOneCardViewAsSkill{
    name = "zhongpan",  
    filter_pattern = ".|heart|.|hand",  -- 梅花手牌  
    view_as = function(self, card)  
        local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())  
        archery_attack:addSubcard(card:getId())  
        archery_attack:setSkillName(self:objectName())  --设置转化牌的技能名
        archery_attack:setShowSkill(self:objectName())  --使用时亮将
        return archery_attack  
    end,
    enabled_at_play = function(self, player)  
        return not player:hasFlag("zhongpan_used")  --参考袁绍，可以考虑不限制次数，红桃没那么多
    end  
}
zhongpan = sgs.CreateTriggerSkill{  
    name = "zhongpan",  
    events = {sgs.CardUsed},  
    view_as_skill = zhongpanVS,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill("zhongpan")) then return "" end  
        -- 当使用衔镜技能时设置标记  
        local use = data:toCardUse()  
        card = use.card  
        if card:getSkillName() == "zhongpan" then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 自动触发  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:setPlayerFlag(player, "zhongpan_used")  
        return false  
    end  
}
shangzhou:addSkill(zhongpan)
sgs.LoadTranslationTable{
    ["shangzhou"] = "商纣",  

    ["zhongpan"] = "众叛",   
    [":zhongpan"] = "出牌阶段限一次，你可以使用一张红桃手牌视为使用一张【万箭齐发】。"  
}

-- 创建武将：时迁  
shiqian = sgs.General(extension, "shiqian", "wu", 3)  -- 群雄，3血  
  
-- 技能1：神偷 - 将梅花手牌视为顺手牵羊  
shentou = sgs.CreateOneCardViewAsSkill{  
    name = "shentou",  
    filter_pattern = ".|club|.|hand",  -- 梅花手牌  
    view_as = function(self, card)  
        local snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())  
        snatch:addSubcard(card:getId())  
        snatch:setSkillName(self:objectName())  
        snatch:setShowSkill(self:objectName())  
        return snatch  
    end  
}  
  
-- 技能2：飞贼 - 顺手牵羊无距离限制  
feizei = sgs.CreateTargetModSkill{  
    name = "feizei",   
    pattern = "Snatch",  -- 针对顺手牵羊  
    distance_limit_func = function(self, player, card)  
        --这是距离限制的函数
        --目标数限制的函数名：extra_target_func
        --次数限制的函数名：residue_func
        --传入参数都是self, player, card
        if player:hasSkill("shentou") then  
            return 1000  -- 实际上相当于无限距离  
        else  
            return 0  
        end  
    end  
}  
  
-- 技能3：隐匿 - 不能成为顺手牵羊的目标  
--可以考虑写成类似仁王盾/妲己的形式
qingmin = sgs.CreateTriggerSkill{  
    name = "qingmin",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        local use = data:toCardUse()  
        if not use.card or not use.to:contains(player) then  
            return false  
        end  
          
        if use.card:isKindOf("Snatch") then  
            return self:objectName()  
        end  
          
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  -- 强制技能，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
          
        room:sendCompulsoryTriggerLog(player, self:objectName())  
        room:broadcastSkillInvoke(self:objectName(), player)  
          
        -- 取消目标  
        room:cancelTarget(use, player)  
        data:setValue(use)  
          
        return false  
    end  
}  
qingmin = sgs.CreateProhibitSkill{  --不能指定为目标，不是取消目标
    name = "qingmin",  
    is_prohibited = function(self, from, to, card)  
        if to:hasShownSkill(self:objectName()) and card:isKindOf("Snatch") then  
            return true  
        end  
        return false  
    end  
}
-- 添加技能给武将  
shiqian:addSkill(shentou)  
shiqian:addSkill(feizei)  
shiqian:addSkill(qingmin)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["shiqian"] = "时迁",  
    ["#shiqian"] = "飞贼",  
    ["shentou"] = "神偷",  
    [":shentou"] = "你可以将一张梅花手牌当做【顺手牵羊】使用。",  
      
    ["feizei"] = "飞贼",  
    [":feizei"] = "你使用【顺手牵羊】无距离限制。",  
      
    ["qingmin"] = "轻敏",  
    [":qingmin"] = "锁定技，你不能成为【顺手牵羊】的目标。"  
}  


simaxiangru = sgs.General(extension, "simaxiangru", "qun", 3)  

qiuhuang = sgs.CreatePhaseChangeSkill{  
    name = "qiuhuang", -- 技能名称  
    frequency = sgs.Skill_Frequent, -- 设置为常规技能  
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then  
            return self:objectName()
        end  
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    -- 在阶段变化时触发的函数  
    on_phasechange = function(self, player)  
        -- 检查是否是准备阶段  
        if player:getPhase() ~= sgs.Player_Start then  
            return false  
        end  
          
        -- 获取房间对象  
        local room = player:getRoom()  
          
        -- 询问玩家是否发动技能  
        --if player:askForSkillInvoke(self:objectName()) then  
        -- 播放技能音效  
        room:broadcastSkillInvoke(self:objectName(), player)  
            
        -- 创建判定结构  
        local judge = sgs.JudgeStruct()  
        judge.pattern = ".|.|1~6"  -- 判定牌点数小于7。第一个点表示任意类型，第二个点表示任意花色
        judge.good = true -- 判定成功对玩家有利  
        judge.reason = self:objectName()  
        judge.who = player  
            
        -- 执行判定  
        room:judge(judge)  
            
        -- 判断判定结果  
        if judge:isGood() then  
            -- 创建回复结构  
            local recover = sgs.RecoverStruct()  
            recover.who = player  
            -- 执行回复  
            room:recover(player, recover)
        else
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
            target:drawCards(1)
            local select_card_ids = room:askForExchange(target, self:objectName(), 2, 1, "", "", ".|.|.|hand")  
            for _,card in sgs.qlist(select_card_ids) do
                room:obtainCard(player, card, false)  
            end
        end  
        --end  
          
        return false  
    end,  
}

jianlie = sgs.CreateTriggerSkill{
    name = "jianlie",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        -- 任意角色回合结束时都可能触发
        owner = room:findPlayerBySkillName(self:objectName())
        if player:getPhase() == sgs.Player_Finish then  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if p:getHandcardNum()<2 and owner:willBeFriendWith(p) then  
                    return self:objectName(), owner:objectName()
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName()) then
            return true
        end
        return false  
    end,  
      
    on_effect = function(self, event, room, player, dat, ask_who)
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  p:getHandcardNum()<2 and ask_who:isFriendWith(p) then  
                targets:append(p)            
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(ask_who, targets, "jianlie", "@jianlie-choose", false)  

        target:drawCards(1)
        return false  
    end, 
}

simaxiangru:addSkill(qiuhuang)  
simaxiangru:addSkill(jianlie)

sgs.LoadTranslationTable{  
    ["simaxiangru"] = "司马相如",  
    ["#simaxiangru"] = "文君才子",  
      
    ["qiuhuang"] = "求凰",  
    [":qiuhuang"] = "准备阶段，你可以发起一次判定，若判定牌点数小于7，你回复一点体力；否则，你可令一名角色摸一张牌，然后交给你1-2张手牌",  
      
    ["jianlie"] = "谏猎",  
    [":jianlie"] = "任意角色回合结束时，你可以选择一名手牌数小于2的相同势力角色，你可令其摸一张牌。", 

}

-- 创建武将  
simayi_hero = sgs.General(extension, "simayi_hero", "wei", 3)  --wei,jin
  
-- 技能1：鬼才  
zhuolue = sgs.CreateViewAsSkill{  
    name = "zhuolue",  
    n = 999,  
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then  
            return not to_select:hasFlag("using")  
        else  
            local first_color = selected[1]:isRed()  
            return to_select:isRed() == first_color and not to_select:hasFlag("using")  
        end  
    end,  
    view_as = function(self, cards)  
        if #cards == 0 then return nil end  
          
        local first_color = cards[1]:isRed()  
        for _, card in ipairs(cards) do  
            if card:isRed() ~= first_color then  
                return nil  
            end  
        end  
          
        local hand_cards = sgs.Self:getHandcards()  
        local same_color_count = 0  
        for _, hand_card in sgs.qlist(hand_cards) do  
            if hand_card:isRed() == first_color then  
                same_color_count = same_color_count + 1  
            end  
        end  
          
        if #cards ~= same_color_count then  
            return nil  
        end  
          
        local new_card  = nil
        if first_color then  
            new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)  
        else  
            new_card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, -1)  
        end  
          
        for _, card in ipairs(cards) do  
            new_card:addSubcard(card)  
        end  
        new_card:setSkillName(self:objectName())
        new_card:setShowSkill(self:objectName())
        return new_card  
    end,  
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
        --[[
        local room = player:getRoom()
        local can_use = false
        for _,p in room:getOtherPlayers(player) do
            if p:getHp() > player:getHp() then
                can_use = true
            end
        end
        if not can_use then return false end
        local hand_cards = sgs.QList2Table(player:getHandcards())  
        if #hand_cards == 0 then return false end  
          
        local red_count = 0  
        local black_count = 0  
        for _, card in ipairs(hand_cards) do  
            if card:isRed() then  
                red_count = red_count + 1  
            else  
                black_count = black_count + 1  
            end  
        end  
          
        return red_count > 0 or black_count > 0  
        ]]
    end  
}  
  
-- 技能2：反馈  
langgu = sgs.CreateTriggerSkill{  
    name = "langgu",  
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
        room:drawCards(player, 1, self:objectName())  
        room:showAllCards(player)  
          
        local hand_cards = player:getHandcards()  
        if hand_cards:length() > 0 then  
            local same_color = true  
            local first_color = hand_cards:first():isRed()  
              
            for _, card in sgs.qlist(hand_cards) do  
                if card:isRed() ~= first_color then  
                    same_color = false  
                    break  
                end  
            end  
              
            if same_color then  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(player, recover)  
            end  
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
simayi_hero:addSkill(zhuolue)  
simayi_hero:addSkill(langgu)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["simayi_hero"] = "司马懿",  
    ["zhuolue"] = "卓略",  
    [":zhuolue"] = "出牌阶段：你可以弃置所有黑色牌，视为使用一张【南蛮入侵】；你可以弃置所有红色牌，视为使用一张【桃】。",  
    ["langgu"] = "狼顾",  
    [":langgu"] = "你受到伤害后，你可以摸一张牌，然后展示所有手牌，若手牌颜色都相同，你回复一点体力。"  
}  
  
songci = sgs.General(extension, "songci", "wu", 3)  

yangu = sgs.CreateDrawCardsSkill{  
    name = "yangu",  
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        local dead_count = 0  
        for _, p in sgs.qlist(room:getAllPlayers(true)) do  
            if p:isDead() then  
                dead_count = dead_count + 1  
            end  
        end  
        local extra = math.min(dead_count, 3)  
        return n + extra  
    end  
}

xiyuan = sgs.CreateTriggerSkill{  
    name = "xiyuan",  
    events = {sgs.Dying},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        local dying = data:toDying()  
        return self:objectName() .. "->" .. dying.who:objectName()
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local dying = data:toDying()  
        local _data = sgs.QVariant()  
        _data:setValue(dying.who)  
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local dying = data:toDying()  
        local target = dying.who  
          
        -- 摸4张牌  
        target:drawCards(4, self:objectName())  
          
        -- 使用askForExchange弃置4张手牌  
        if target:getHandcardNum() >= 4 then  
            local to_discard = room:askForExchange(target, self:objectName(), 4, 4, "@xiyuan-discard", "", ".|.|.|hand")  
              
            if to_discard:length() == 4 then  
                -- 检查花色  
                local suits = {}  
                for _, id in sgs.qlist(to_discard) do  
                    local card = sgs.Sanguosha:getCard(id)  
                    local suit = card:getSuitString()  
                    suits[suit] = true  
                end  
                  
                -- 弃置这些牌  
                local dummy = sgs.Sanguosha:cloneCard("slash")  
                for _, id in sgs.qlist(to_discard) do  
                    dummy:addSubcard(id)  
                end  
                room:throwCard(dummy, target, target, self:objectName())  
                dummy:deleteLater()
                -- 检查是否有4种花色  
                local suit_count = 0  
                for _ in pairs(suits) do  
                    suit_count = suit_count + 1  
                end  
                  
                if suit_count == 4 then  
                    -- 恢复1点体力  
                    local recover = sgs.RecoverStruct()  
                    recover.who = ask_who  
                    recover.recover = 1  
                    room:recover(target, recover)  
                end  
            end  
        end  
          
        return false  
    end  
}

songci:addSkill(yangu)  
songci:addSkill(xiyuan)

sgs.LoadTranslationTable{
    ["#songci"] = "法医鼻祖",  
    ["songci"] = "宋慈",  
    ["illustrator:songci"] = "未知",  
    ["yangu"] = "验骨",  
    [":yangu"] = "摸牌阶段，你摸牌数+X，X为场上已死亡的角色数，且至多为3。",  
    ["xiyuan"] = "洗冤",  
    [":xiyuan"] = "任意角色濒死时，你可以令其摸4张牌并弃置4张手牌，若弃置的牌包含4种花色，其恢复一点体力。",  
    ["@xiyuan-discard"] = "洗冤：请选择4张手牌弃置",  
}

-- 创建武将：
sunquan_hero = sgs.General(extension, "sunquan_hero", "wu", 4)  -- 吴国，4血，男性  

-- 创建均衡技能卡  
JunhengCard = sgs.CreateSkillCard{  
    name = "junhengCard",  
    filter = function(self, targets, to_select)  
        -- 只能选择两名角色  
        return #targets < 1  
    end,  
      
    feasible = function(self, targets)  
        -- 必须选择两名角色  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 获取两个目标角色  
        local from = targets[1]  -- 获得手牌的角色  
        local to = room:askForPlayerChosen(source,  room:getOtherPlayers(from), self:objectName())-- 获得手牌的角色  
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "junheng")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("junheng")  
          
        -- 令 from 获得 to 的一张手牌  
        if not to:isKongcheng() then  
            local card_id = room:askForCardChosen(from, to, "h", "junheng")  
              
            -- 移动卡牌  
            local move = sgs.CardsMoveStruct()  
            move.card_ids:append(card_id)  
            move.to = from  
            move.to_place = sgs.Player_PlaceHand  
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, to:objectName(), from:objectName(), "junheng", "")  
            room:moveCardsAtomic(move, true)  
              
            -- 发送日志  
            local msg = sgs.LogMessage()  
            msg.type = "#Junheng"  
            msg.from = source  
            msg.to:append(from)  
            msg.to:append(to)  
            msg.arg = "junheng"  
            room:sendLog(msg)  
              
            -- 检查两名角色的手牌数是否相等  
            if from:getHandcardNum() == to:getHandcardNum() then  
                -- 发送日志  
                local draw_msg = sgs.LogMessage()  
                draw_msg.type = "#JunhengDraw"  
                draw_msg.from = source  
                draw_msg.arg = "junheng"  
                room:sendLog(draw_msg)  
                  
                -- 你摸一张牌  
                source:drawCards(1, "junheng")  
            end  
        end  
    end  
}  
  
-- 创建均衡视为技  
JunhengViewAsSkill = sgs.CreateZeroCardViewAsSkill{  
    name = "junheng",  
      
    view_as = function(self)  
        local card = JunhengCard:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 出牌阶段限一次  
        return not player:hasUsed("#junhengCard")  
    end  
}  
  
-- 创建均衡技能  
Junheng = sgs.CreateTriggerSkill{  
    name = "junheng",  
    view_as_skill = JunhengViewAsSkill,  
    events = {},  -- 没有触发事件，纯视为技  
}

beixi = sgs.CreateTriggerSkill{  
    name = "beixi",  
    events = {sgs.CardUsed},  
    frequency = sgs.SKill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        -- 检查是否有角色使用了杀  
        if not (use.card and use.card:isKindOf("Slash")) then return "" end  
          
        -- 检查使用杀的角色手牌数是否小于等于2  
        if use.from and use.from:isAlive() and use.from:getHandcardNum() <= 2 then  
            -- 寻找拥有背袭技能的角色  
            local beixi_player = room:findPlayerBySkillName(self:objectName())
            if beixi_player and beixi_player:isAlive() and beixi_player:hasSkill(self:objectName()) and not beixi_player:willBeFriendWith(use.from) then
                if use.from:objectName()==beixi_player:objectName() then return "" end
                return self:objectName(), beixi_player:objectName()
            end
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        local _data = sgs.QVariant()  
        _data:setValue(use.from)  
          
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
        local target = use.from  
          
        -- 询问是否使用杀。这里会处理杀的效果
        local slash_str = room:askForUseSlashTo(ask_who, target, "@beixi-slash:" .. target:objectName(), false) 
        --[[ 
            local slash = sgs.Sanguosha:cloneCard("slash")  
            local slash_use = sgs.CardUseStruct()  
            slash_use.card = slash  
            slash_use.from = ask_who  
            slash_use.to:append(target)  
            room:useCard(slash_use)  
            slash:deleteLater()
        ]]
        return false  
    end  
}  
sunquan_hero:addSkill(Junheng)
sunquan_hero:addSkill(beixi)
sgs.LoadTranslationTable{  
    ["sunquan_hero"] = "孙权",
    ["junheng"] = "均衡",  
    [":junheng"] = "出牌阶段限1次，你可以选择两名角色，令一名角色获得另一名角色一张手牌，若此时他们手牌数相等，你摸一张牌。(先选的获得牌)",  
    ["junhengCard"] = "均衡",  
    ["beixi"] = "背袭",  
    [":beixi"] = "当其他势力角色使用【杀】时，若其手牌数小于等于2，你可以对其使用一张【杀】。",  
    ["@beixi-slash"] = "背袭：你可以对 %src 使用一张【杀】",  
}


-- 创建武将：
sunwu = sgs.General(extension, "sunwu", "wei", 3)  --wei,jin  

-- 创建强行技能卡  
qijiCard = sgs.CreateSkillCard{  
    name = "qijiCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
      
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 获取目标角色  
        local target = targets[1]  
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "qiji")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("qiji")  
          
        -- 发送日志  
        local msg = sgs.LogMessage()  
        msg.type = "#qiji"  
        msg.from = source  
        msg.to:append(target)  
        msg.arg = "qiji"  
        room:sendLog(msg)  
          
        -- 设置目标角色的体力值与你一致  
        room:setPlayerProperty(target, "hp", sgs.QVariant(source:getHp()))  
    end  
}  
  
-- 创建强行视为技  
qijiViewAsSkill = sgs.CreateViewAsSkill{  
    name = "qiji",  
      
    view_filter = function(self, selected, to_select)  
        -- 只能选择手牌，且最多选择两张  
        return not to_select:isEquipped() and #selected < 2  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 2 then  
            local card = qijiCard:clone()  
            for _, c in ipairs(cards) do  
                card:addSubcard(c)  
            end  
            return card  
        end  
        return nil  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 出牌阶段限一次，且需要有至少两张手牌  
        return not player:hasUsed("#qijiCard") and player:getHandcardNum() >= 2  
    end  
}  
  
-- 创建强行技能  
qiji = sgs.CreateTriggerSkill{  
    name = "qiji",  
    view_as_skill = qijiViewAsSkill,  
    events = {},  -- 没有触发事件，纯视为技  
}

bingsheng = sgs.CreateTriggerSkill{  
    name = "bingsheng",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local source = room:findPlayerBySkillName(self:objectName())  
        if not (source and source:isAlive() and source:hasSkill(self:objectName())) then  
            return ""  
        end            
        local current = room:getCurrent()
        local use = data:toCardUse()  
        if current ~= use.from then return "" end
        -- 检查是否是杀  
        local card = use.card            
        if card and card:isKindOf("Slash") and card:isRed() then  
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
        --local source = room:findPlayerBySkillName(self:objectName())  
        ask_who:drawCards(1, self:objectName())  
        local use = data:toCardUse()
        if not use.from:hasFlag("bingsheng_slash") and room:askForDiscard(ask_who, self:objectName(), 1, 1, true, true) then
            room:setPlayerFlag(use.from, "bingsheng_slash")
        end
        return false  
    end  
}

bingsheng_targetmod = sgs.CreateTargetModSkill{  
    name = "#bingsheng-slash",  
    residue_func = function(self, player, card)  
        if player:hasFlag("bingsheng_slash") and card and card:isKindOf("Slash") then  
            return 1 
        end  
        return 0  
    end  
}
sunwu:addSkill(qiji)
sunwu:addSkill(bingsheng)  
sunwu:addSkill(bingsheng_targetmod)
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["sunwu"] = "孙武",
    ["#sunwu"] = "孙武",
    ["qiji"] = "奇计",  
    [":qiji"] = "出牌阶段限1次，你可以弃置两张手牌，令一名角色体力值与你相同。",  
    ["qijiCard"] = "强行",  
    ["bingsheng"] = "兵圣",  
    [":bingsheng"] = "任意角色在其出牌阶段使用红色杀时，你可以摸1张牌；然后你可以弃置1张牌，令其本回合使用杀次数+1（至多+1）",  
}

suqin = sgs.General(extension, "suqin", "shu", 3)  

hezong = sgs.CreateTriggerSkill{  
    name = "hezong",  
    events = {sgs.EventPhaseStart, sgs.CardEffected},  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@hezong",  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            -- 回合开始时，寻找拥有此技能的角色  
            if not (player and player:isAlive()) then
                return ""
            end
            if player:hasSkill(self:objectName()) then
                if player:getPhase() == sgs.Player_Start then --自己准备阶段清除标记
                    room:setPlayerMark(player,"@hezong",1)
                    --把标记清除掉
                    for _,p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getMark("@zong") > 0 then
                            room:setPlayerMark(p,"@zong",0)
                        end
                    end
                end
            end
            if player:getPhase() == sgs.Player_Play then
                local source = room:findPlayerBySkillName(self:objectName())
                if not (source and source:isAlive() and source:getMark("@hezong")>0) then 
                    return ""
                end
                return self:objectName(), source:objectName()
            end
        elseif event == sgs.CardEffected then  
            -- 当角色成为目标时  
            local effect = data:toCardEffect()  
            if effect.to:getMark("@zong") > 0 and effect.to:objectName() ~= effect.from:objectName() and effect.card:getTypeId()==sgs.Card_TypeSkill then  
                -- 寻找拥有此技能的角色  
                local source = room:findPlayerBySkillName(self:objectName())  
                if source and source:isAlive() then  
                    return self:objectName(), source:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            return ask_who:askForSkillInvoke(self:objectName(),data)
        elseif event == sgs.CardEffected then  
            return ask_who:askForSkillInvoke(self:objectName(),data)  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then  
            local target = room:askForPlayerChosen(ask_who, room:getOtherPlayers(ask_who), self:objectName(), "@hezong-invoke", true, true)  
            if target then  
                room:setPlayerMark(ask_who, "@hezong", 0)  
                room:setPlayerMark(target, "@zong", 1)  
            end  
        elseif event == sgs.CardEffected then  
            -- 摸1张牌  
            ask_who:drawCards(1, self:objectName())  
            -- 若手牌数不为1，弃置1张牌  
            if ask_who:getHandcardNum() ~= 1 and not ask_who:isNude() then  
                room:askForDiscard(ask_who, self:objectName(), 1, 1, false, true)  
            end  
        end  
        return false  
    end  
}

wangji = sgs.CreateTriggerSkill{  
    name = "wangji",  
    events = {sgs.Death},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local death = data:toDeath()  
        if death.who and death.who:hasSkill(self:objectName()) and death.who==player then  
            return self:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  not player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end  
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@wangji-invoke", false, true)  
        if target then  
            room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))  
        end  
        return false  
    end  
}

suqin:addSkill(hezong)  
suqin:addSkill(wangji)


sgs.LoadTranslationTable{
    ["#suqin"] = "纵横家",  
    ["suqin"] = "苏秦",  
    ["illustrator:suqin"] = "未知",  
    ["hezong"] = "合纵",  
    [":hezong"] = "每轮限一次，任意角色出牌阶段开始时，你可以指定1名其他角色，令其获得1个'纵'标记，直到你下回合开始，该角色成为其他角色使用牌的目标时，你摸1张牌，然后若你的手牌数不为1，你弃置1张牌。",  
    ["@hezong"] = "合纵",  
    ["@hezong-invoke"] = "合纵：你可以选择一名其他角色，令其获得'纵'标记",  
    ["zong"] = '纵',  
    ["wangji"] = "亡计",  
    [":wangji"] = "你死亡时，你可以对一名其他势力角色造成1点伤害。",  
    ["@wangji-invoke"] = "亡计：你可以选择一名角色，对其造成1点伤害",  
}

-- 创建武将：唐伯虎  
tangbohu = sgs.General(extension, "tangbohu", "wei", 3)  --wei,jin  
  
-- 技能1：风流 - 摸牌阶段开始时，场上每多一名女性角色，你的摸牌数＋1  
fengliu = sgs.CreateDrawCardsSkill{  
    name = "fengliu",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        local female_count = 0  
          
        -- 计算场上女性角色数量  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  p:hasShownOneGeneral() and p:isFemale()  then  
                female_count = female_count + 1  
            end  
        end  
          
        if female_count > 0 then  
            room:sendCompulsoryTriggerLog(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName(), player)  
              
            -- 显示增加摸牌数的提示  
            local msg = sgs.LogMessage()  
            msg.type = "#FengliuDraw"  
            msg.from = player  
            msg.arg = female_count  
            msg.arg2 = self:objectName()  
            room:sendLog(msg)  
              
            return n + female_count  
        else  
            return n  
        end  
    end  
}  
  
-- 技能2：落笔 - 弃牌阶段结束后，你摸x张牌，x为你失去的体力值  
luobi = sgs.CreateTriggerSkill{  
    name = "luobi",  
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
            msg.type = "#LuobiDraw"  
            msg.from = player  
            msg.arg = lost_hp  
            msg.arg2 = self:objectName()  
            room:sendLog(msg)  
              
            local ids = sgs.IntList()
            ids = room:getNCards(lost_hp)
            room:setPlayerMark(player, "lb_card1", ids:at(0))
            local dummy = sgs.DummyCard(ids)  
            player:obtainCard(dummy)
            dummy:deleteLater()
        end  
          
        return false  
    end  
}  
luobiAsk = sgs.CreateTriggerSkill{
    name = "#luobiAsk",
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
                            if player:getMark("lb_card1") == id then
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
-- 添加技能给武将  
tangbohu:addSkill(fengliu)  
tangbohu:addSkill(luobi)  
tangbohu:addSkill(luobiAsk)
extension:insertRelatedSkills("luobi", "#luobiAsk")
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["tangbohu"] = "唐伯虎",  
    ["#tangbohu"] = "风流才子",  
    ["fengliu"] = "风流",  
    [":fengliu"] = "锁定技，摸牌阶段开始时，场上每多一名女性角色，你的摸牌数+1。",  
    ["#FengliuDraw"] = "%from 的【%arg2】技能被触发，额外摸了 %arg 张牌",  
      
    ["luobi"] = "落笔",  
    [":luobi"] = "弃牌阶段结束后，你可以摸X张牌（X为你已损失的体力值），并可以任意分配。",  
    ["#LuobiDraw"] = "%from 发动了【%arg2】，摸了 %arg 张牌",  
      
    ["~tangbohu"] = "吾一生风流，今日竟折于此！"  
}  

tianji4 = sgs.General(extension, "tianji4", "qun", 3)  --wei 

saimaCard = sgs.CreateSkillCard{  
    name = "saimaCard",  
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)  
        -- 第一个目标是接收手牌并使用杀的角色  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() and to_select:hasFlag("saima_target")
    end,
    on_use = function(self, room, source, targets)  
        local target = targets[1]
        if target and not source:isKongcheng() and not target:isKongcheng() then
            source:pindian(target,"saima")
        end
    end  
}  
  
saimaVS = sgs.CreateZeroCardViewAsSkill{  
    name = "saima",  
    view_as = function(self)  
        local vs_card = saimaCard:clone()  
        vs_card:setSkillName("saima")  
        vs_card:setShowSkill("saima")  
        return vs_card  
    end,  
      
    enabled_at_play = function(self, player)  
        local used_times = player:usedTimes("ViewAsSkill_saimaCard")
        return not player:isKongcheng() and used_times < 3 --出牌阶段，最多拼点3次
    end  
}  
  
  
-- 注册技能  
saima = sgs.CreateTriggerSkill{  
    name = "saima",  
    view_as_skill = saimaVS,  
    events = {sgs.EventPhaseStart, sgs.Pindian},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase()==sgs.Player_Start then --准备阶段，选择拼点目标
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
                room:setPlayerFlag(target,"saima_target")
            elseif player:getPhase()==sgs.Player_Finish then --结束阶段，找到赢次数多的人
                return self:objectName()
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                return self:objectName()
            end
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true 
    end,  
      
    on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            local target = nil --准备阶段选择的目标
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasFlag("saima_target") then
                    target = p
                    break
                end
            end
            if not target then return false end
            local winner = nil
            local loser = nil
            if player:getMark("@saima_win") > target:getMark("@saima_win") then
                winner = player
                loser = target
            elseif player:getMark("@saima_win") < target:getMark("@saima_win") then
                winner = target
                loser = player
            else --平局，没有后续效果
                return false
            end
            if not winner then return false end
            local choice = room:askForChoice(winner, "saima", "draw+damage")
            if choice == "draw" then
                winner:drawCards(winner:getMark("@saima_win"),self:objectName())
            else
                local damage = sgs.DamageStruct()  
                damage.from = winner  
                damage.to = loser  
                damage.damage = winner:getMark("@saima_win")
                damage.reason = self:objectName()  
                room:damage(damage)  
            end
            room:setPlayerMark(player,"@saima_win",0)
            room:setPlayerMark(target,"@saima_win",0)
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
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
                room:addPlayerMark(winner,"@saima_win")
            end
        end
        return false  
    end  
}  


weijiuCard = sgs.CreateSkillCard{  
    name = "weijiuCard",  
    target_fixed = false,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        if not target then return end  
        source:drawCards(1,self:objectName())
        local to_give = room:askForExchange(source, self:objectName(),   
                                               1, 1,   
                                               "@weijiu-give", "", ".|.|.|.")  
          
        for _,card_id in sgs.qlist(to_give) do  
            room:obtainCard(target, card_id, false)  
        end  

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)  
        slash:setSkillName("weijiu")  
        local use = sgs.CardUseStruct()  
        use.card = slash  
        use.from = source  
        use.to:append(target)  
        room:useCard(use)  
        slash:deleteLater()
    end  
}  
  
-- 平讨视为技能  
weijiu = sgs.CreateZeroCardViewAsSkill{  
    name = "weijiu",  
    view_as = function(self)  
        local card = weijiuCard:clone()  
        card:setShowSkill("weijiu")  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#weijiuCard")  
    end  
}

tianji4:addSkill(saima)
tianji4:addSkill(weijiu)
sgs.LoadTranslationTable{
    ["tianji4"] = "田忌",
    ["saima"] = "赛马",
    [":saima"] = "准备阶段，你可以选择一名其他角色，出牌阶段你可以与其拼点至多3次，结束阶段，获胜更多者执行：摸x张牌或对另一方造成x点伤害（x为其获胜次数）。",
    ["weijiu"] = "围救",
    [":weijiu"] = "出牌阶段限1次，你可以摸1张牌并交给其他角色1张手牌，视为你对其使用1张杀"
}

tiemuzhen = sgs.General(extension, "tiemuzhen", "shu", 4)  
  
-- 技能2：遗毒  
qianglve = sgs.CreateTriggerSkill{  
    name = "qianglve",  
    events = {sgs.SlashMissed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local effect = data:toSlashEffect() 
        local target = effect.to  
        if target and target:isAlive() then  
            return self:objectName()  
        end  
        --[[
        local use = data.toCardUse() 
        if not (use.card and use.card:isKindOf("Slash")) then return "" end
        if use.from and use.from:objectName()==player:objectName() then
           return self:objectName()
        end
        ]]
        return ""  
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
          
        local judge = sgs.JudgeStruct()  
        judge.pattern = ".|red"  --虽然没有明显好坏，先设置一个默认好判定
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = player  
        
        room:judge(judge)  
        
        -- 若判定牌为黑色，获得目标一张牌  
        if judge.card:isBlack() and not target:isAllNude() then  
            local card_id = room:askForCardChosen(player, target, "hej", self:objectName())  
            room:obtainCard(player,card_id)  
        elseif judge.card:isRed() then
            local damage = sgs.DamageStruct()  
            damage.from = player  
            damage.to = target  
            damage.damage = 1  
            damage.reason = "qianglve"  
            room:damage(damage)  
        end  
        return false  
    end  
}  

qianglve = sgs.CreateTriggerSkill{
	name = "qianglve",
	events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from == player then
				local target_list = {}
				for _, p in sgs.qlist(use.to) do
					if p ~= player then
						table.insert(target_list, p:objectName())
					end
				end
				if #target_list > 0 then
					return self:objectName() .. "->" .. table.concat(target_list, "+")
				end
			end
		end
		return false
	end,

	on_cost = function(self, event, room, skill_target, data, player)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,

	on_effect = function(self, event, room, skill_target, data, player)          
        local judge = sgs.JudgeStruct()  
        judge.pattern = ".|red"  --虽然没有明显好坏，先设置一个默认好判定
        judge.good = true  
        judge.reason = self:objectName()  
        judge.who = player  
        
        room:judge(judge)  
        
        -- 若判定牌为黑色，获得目标一张牌  
        if judge.card:isBlack() and not skill_target:isAllNude() then  
            local card_id = room:askForCardChosen(player, skill_target, "hej", self:objectName())  
            room:obtainCard(player,card_id)  
        elseif judge.card:isRed() then
            local damage = sgs.DamageStruct()  
            damage.from = player  
            damage.to = skill_target  
            damage.damage = 1  
            damage.reason = "qianglve"  
            room:damage(damage)  
        end  
    end
}
function sgs.CreatemashuSkill(name) --创建拒马技能，在CreateDistanceSkill函数基础上建立的函数
	local mashu_skill = {}
	mashu_skill.name = name
	mashu_skill.correct_func = function(self, from, to)
		if from:hasShownSkill(self) then --hasSkill
			return -1
		end
		return 0
	end
	return sgs.CreateDistanceSkill(mashu_skill)
end
mashuTiemuzhen = sgs.CreatemashuSkill("mashuTiemuzhen") 
tiemuzhen:addSkill(qianglve)
tiemuzhen:addSkill(mashuTiemuzhen)
sgs.LoadTranslationTable{
    ["tiemuzhen"] = "铁木真",
    ["qianglve"] = "强掠",
    --[":qianglve"] = "当你的杀被闪避后，你可以发起一次判定，若判定牌为黑色，你可以获得目标一张牌；若判定牌为红色，你对目标造成一点伤害",
    [":qianglve"] = "当你使用杀指定目标后，你可以发起一次判定，若判定牌为黑色，你可以获得目标一张牌；若判定牌为红色，你对目标造成一点伤害",
    ["mashuTiemuzhen"] = "马术",
    [":mashuTiemuzhen"] = "你计算到其他角色的距离-1"
}

wanganshi = sgs.General(extension, "wanganshi", "wu", 3)  -- 群雄，3血  

xinxue = sgs.CreateViewAsSkill{  
    name = "xinxue",  
    n = 2,  
    view_filter = function(self, selected, to_select)  
        -- 只能选择手牌，且不能选择正在使用的牌  
        if #selected >= 2 or to_select:hasFlag("using") then   
            return false   
        end  
        if to_select:isEquipped() then  
            return false  
        end  
        return true --not sgs.Self:isJilei(to_select)  --鸡肋，不能被弃置
    end,  
      
    view_as = function(self, cards)  
        if #cards == 2 then  
            local dismantlement = sgs.Sanguosha:cloneCard("dismantlement")  
            dismantlement:setSkillName("xinxue")  
            dismantlement:setShowSkill("xinxue")  
            dismantlement:addSubcard(cards[1])  
            dismantlement:addSubcard(cards[2])  
            return dismantlement  
        end  
        return nil  
    end,  
      
    enabled_at_play = function(self, player)  
        -- 每回合限一次检查  
        if player:usedTimes("ViewAsSkill_xinxueCard") > 0 then  
            return false  
        end  
        -- 需要至少2张手牌  
        return player:getHandcardNum() >= 2  
    end,  
      
    enabled_at_response = function(self, player, pattern)  
        return false  
    end  
}

qingmiao = sgs.CreateTriggerSkill{  
    name = "qingmiao",  
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.CardResponded, sgs.CardsMoveOneTime},  --sgs.CardsMoveOneTime这个可以考虑削弱
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
            return false  
        end  
        --我的实现。手牌数也可以用player:getHandcardNum(), player:isKongcheng()
        local times = player:getMark("@bianfa_used-Clear") + 1 --Clear标记会在每个角色回合结束时自动清除
        if player:isKongcheng() and player:getCardCount(true)+player:getMaxHp()>times  then
            return self:objectName() --必须返回技能名
        end
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local times = player:getMark("@bianfa_used-Clear") + 1 --Clear标记会在每个角色回合结束时自动清除
        player:setMark("@bianfa_used-Clear",times)
        if player:getMaxHp() > player:getHandcardNum() then
            player:drawCards(player:getMaxHp()-player:getHandcardNum())
            local discard_num = math.min(times, player:getCardCount(true))  
            room:askForDiscard(player, self:objectName(), discard_num, discard_num, false, true)  
        end  
        return false
    end  
}  
  
-- 添加技能给武将  
wanganshi:addSkill(xinxue)
wanganshi:addSkill(qingmiao)  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["wanganshi"] = "王安石",  
    ["xinxue"] = "新学",
    [":xinxue"] = "出牌阶段限一次，你可以将2张手牌视为过河拆桥使用",
    ["qingmiao"] = "青苗",  
    [":qingmiao"] = "每当你使用、打出、失去最后一张手牌时，你可以摸至手牌上限，然后弃置X张牌，X为本回合使用本技能的次数",  
}  

-- 创建武将：唐伯虎  
wangyangming = sgs.General(extension, "wangyangming", "wu", 3)  -- 吴国，4血，男性  

gewu = sgs.CreateTriggerSkill{  
    name = "gewu",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then
            player:setMark("gewu_suit", 0)
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local card_ids = room:getNCards(1)  
        card = sgs.Sanguosha:getCard(card_ids:first())
        
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

        -- 将牌放回牌堆顶  
        room:moveCardTo(card, nil, sgs.Player_DrawPile, true)

        -- 记录花色到玩家标记  
        local suit = card:getSuit()+1
        player:setMark("gewu_suit", suit)               
        return false  
    end  
}

gewu_prohibit = sgs.CreateProhibitSkill{  
    name = "#gewu_prohibit",  
    is_prohibited = function(self, from, to, card)  
        if to and to:hasSkill("gewu") and from and from:objectName() ~= to:objectName() and card then  
            local suit = to:getMark("gewu_suit")-1
            if card:getSuit() == suit then  
                return true  
            end  
        end  
        return false  
    end  
}

zhixing = sgs.CreateTriggerSkill{  
    name = "zhixing",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.SKill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local wangyangming = room:findPlayerBySkillName(self:objectName())  
        if wangyangming and wangyangming:isAlive() and wangyangming:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start   
           and not wangyangming:isKongcheng() then  
            return self:objectName(), wangyangming:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        --交换1张
        -- 选择一张手牌  
        local card_id = room:askForCardChosen(ask_who, ask_who, "h", self:objectName())
        -- 获取牌堆顶的牌  
        ask_who:drawCards(1)
        -- 执行交换  
        room:moveCardTo(sgs.Sanguosha:getCard(card_id), nil, sgs.Player_DrawPile, true)
        return false  
    end  
}

wangyangming:addSkill(gewu)  
wangyangming:addSkill(gewu_prohibit)  
wangyangming:addSkill(zhixing)
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["wangyangming"] = "王阳明",
    ["gewu"] = "格物",
    [":gewu"] = "你的准备阶段，你可以展示牌堆顶的一张牌，然后记录该牌的花色，本轮其他角色对你使用该花色的牌无效。",
    ["zhixing"] = "知行",
    [":zhixing"] = "任意角色的准备阶段，你可以将1张手牌与牌堆顶等量的牌交换"
}  
  
-- 创建武将：王昭君  
wangzhaojun = sgs.General(extension, "wangzhaojun", "wu", 3, false)  -- 群雄，3血，女性  
-- 创建和亲技能卡  
HeqinCard = sgs.CreateSkillCard{  
    name = "heqin",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:isMale() and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 显示技能发动效果  
        room:notifySkillInvoked(source, "heqin")  
          
        -- 交换手牌  
        local source_handcards = source:handCards()  
        local target_handcards = target:handCards()  
          
        if source_handcards:isEmpty() and target_handcards:isEmpty() then  
            return  
        end  
          
        -- 执行交换  
        if not source_handcards:isEmpty() or not target_handcards:isEmpty() then  
            local move1 = sgs.CardsMoveStruct()  
            move1.card_ids = source_handcards  
            move1.from = source
            move1.to = target  
            move1.to_place = sgs.Player_PlaceHand  
            move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                source:objectName(), target:objectName(), "heqin", "")

            local move2 = sgs.CardsMoveStruct()  
            move2.card_ids = target_handcards  
            move2.from = target
            move2.to = source  
            move2.to_place = sgs.Player_PlaceHand  
            move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                target:objectName(), source:objectName(), "heqin", "")

            local moves = sgs.CardsMoveList()
            moves:append(move1)
            moves:append(move2)
            
            room:moveCardsAtomic(moves, true)
        end  

        -- 记录交换后的手牌数  
        local source_handcard_num = source:getHandcardNum()  
        local target_handcard_num = target:getHandcardNum()            
        -- 让手牌数较少的一方摸2张牌  
        if source_handcard_num < target_handcard_num then  
            room:drawCards(source,2,self:objectName())  
        elseif target_handcard_num < source_handcard_num then  
            room:drawCards(target,2,self:objectName())  
        --else  
            -- 手牌数相等，双方都不摸牌  
        end  
    end  
}  
  
  
-- 创建和亲视为技  
heqin = sgs.CreateZeroCardViewAsSkill{  
    name = "heqin",  
      
    view_as = function(self)  
        local card = HeqinCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#heqin") and not player:isKongcheng()-- 出牌阶段限一次  
    end  
}  

luoyan = sgs.CreateTriggerSkill{  
    name = "luoyan",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then   
            return ""   
        end 
        local damage = data:toDamage()  
        local from = damage.from
        if from and from:isAlive() and from:getWeapon() and not player:willBeFriendWith(from) then  
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
        local damage = data:toDamage()  
        local from = damage.from  
        if from and from:isAlive() and from:getWeapon() then  
            local card_id = from:getWeapon():getEffectiveId()
            room:throwCard(card_id, from, player)  
        end  

        return false  
    end  
}

  
-- 添加技能给武将  
wangzhaojun:addSkill(heqin)  
wangzhaojun:addSkill(luoyan)

-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["wangzhaojun"] = "王昭君",  
    ["#wangzhaojun"] = "落雁",  
    ["heqin"] = "和亲",  
    [":heqin"] = "出牌阶段限一次，你可以与一名男性角色交换手牌，然后令手牌数较少的一方摸两张牌。",  

    ["luoyan"] = "落雁",  
    [":luoyan"] = "当你受到伤害时，若伤害来源有武器，你可以令其失去武器。",

    ["~wangzhaojun"] = "汉使断肠对河梦，胡笳一曲向天愁。"  
}

weizheng = sgs.General(extension, "weizheng", "wu", 4)  -- 吴国，4血，男性  

jingjian_card = sgs.CreateSkillCard{  
    name = "jingjian_card",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select)  
        if #targets == 0 then  
            return to_select:objectName() ~= sgs.Self:objectName()  
        end  
        return false  
    end,  
    feasible = function(self, targets)  
        return #targets==1 
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]
        if source:getHandcardNum() > target:getHandcardNum() then
            local count = math.min(source:getHandcardNum()-target:getHandcardNum(), 5)
            target:drawCards(count)
        elseif source:getHandcardNum() < target:getHandcardNum() then
            to_discard = target:getHandcardNum()-source:getHandcardNum()
            room:askForDiscard(target, self:objectName(), to_discard, to_discard, false, false)
        end
        return false
    end  
}  

jingjian = sgs.CreateZeroCardViewAsSkill{  
        name = "jingjian",  
          
        view_as = function(self)  
            local card = jingjian_card:clone()
            card:setSkillName("jingjian")  
            return card  
        end,  
          
        enabled_at_play = function(self, player)  
            return not player:hasUsed("#jingjian_card")
        end  
    }  

weizheng:addSkill(jingjian)

sgs.LoadTranslationTable{
    ["weizheng"] = "魏征",
    ["jingjian"] = "镜鉴",  
    [":jingjian"] = "出牌阶段限一次，你可以选择一名角色，令其手牌数摸或弃至与你相同。若为摸牌，则至多为5",  

}

weizifu = sgs.General(extension, "weizifu", "wu", 4, false)  

jiangmen = sgs.CreateTriggerSkill{  
    name = "jiangmen",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.SKill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() ~= sgs.Player_Play then return "" end  
          
        local weizifu = room:findPlayerBySkillName(self:objectName())  
        if weizifu and weizifu:isAlive() and weizifu:getHp() > 0 and weizifu:isFriendWith(player) then  
            return self:objectName(),weizifu:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, weizifu)  
        if weizifu:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), weizifu)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, weizifu)            
        -- 卫子夫摸一张牌  
        weizifu:drawCards(1)  
          
        -- 如果卫子夫有手牌，则交给目标角色一张牌  
        if not weizifu:isKongcheng() and player~=weizifu then  
            --local card_id = room:askForCardChosen(weizifu, weizifu, "h", self:objectName())
            --local card_id = room:askForCard(weizifu, ".|.|.|hand,equipped", self:objectName())  
            local card_ids = room:askForExchange(weizifu, self:objectName(), 1,1)   
            for _,card_id in sgs.qlist(card_ids) do
                room:obtainCard(player, card_id, false)  
            end
        end
        -- 增加目标角色使用杀的次数  
        room:setPlayerFlag(player, "jiangmen_extra_slash")  
        -- 卫子夫失去一点体力  
        room:loseHp(weizifu, 1)              
        --以下这部分可能不要
        local slash = sgs.Sanguosha:cloneCard("slash")  
        local residue = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, slash) + 1  
        room:setPlayerMark(player, "@jiangmen", residue)  
        slash:deleteLater() 
        return false  
    end  
}

jiangmenMod = sgs.CreateTargetModSkill{  
    name = "#jiangmen-mod",  
    pattern = "Slash",  
    residue_func = function(self, player, card)  
        if player:hasFlag("jiangmen_extra_slash") then  
            return 1  
        else  
            return 0  
        end  
    end  
}


jiade = sgs.CreateTriggerSkill{  
    name = "jiade",  
    events = {sgs.EventPhaseChanging},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        local change = data:toPhaseChange()  
        if change.to == sgs.Player_Discard then 
            local discard_num = player:getHandcardNum() - player:getMaxCards()
            discard_num = math.max(discard_num,0) 
            room:setPlayerMark(player,"@jiade",discard_num)
        elseif change.from == sgs.Player_Discard then
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local discard_num = player:getMark("@jiade")
        room:setPlayerMark(player,"@jiade",0)

        local targets = sgs.SPlayerList()  
        -- 收集可选目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  player:isFriendWith(p) then  
                targets:append(p)            
            end  
        end  
        chosen_players = room:askForPlayersChosen(player,  targets, self:objectName(), discard_num+1, discard_num+1, "请选择玩家", false)
        --room:drawCards(player, 1)
        -- 让选中的玩家各摸一张牌  
        if chosen_players and not chosen_players:isEmpty() then  
            room:drawCards(chosen_players, 1)  
        end  
        --[[
        -- 或者逐个让玩家摸牌  
        for _, chosen_player in sgs.qlist(chosen_players) do  
            room:drawCards(chosen_player, 1)  
        end
        ]]
        --player:skip(sgs.Player_Discard)
        return false  
    end  
}

weizifu:addSkill(jiangmen)  
weizifu:addSkill(jiangmenMod)
weizifu:addSkill(jiade)

sgs.LoadTranslationTable{  
    ["weizifu"] = "卫子夫",  
      
    ["jiangmen"] = "将门",  
    [":jiangmen"] = "与你势力相同的角色出牌阶段开始时，你可以摸一张牌，并交给该角色一张牌，令其本回合使用杀的次数+1，然后失去一点体力，。",  

    ["jiade"] = "嘉德",  
    [":jiade"] = "弃牌阶段结束时，你可令至多X+1名相同势力角色各摸一张牌，X为你本回合的弃牌数",  
}

wenjiang = sgs.General(extension, "wenjiang", "wei", 3, false) 

beide = sgs.CreateTriggerSkill{  
    name = "beide",  
    events = {sgs.TargetConfirming},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player:hasSkill("beide") then return "" end  
          
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
          
        local target = room:askForPlayerChosen(player, targets, "beide", "@beide-choose", true)  
        if target then  
            player:setTag("beide_target", sgs.QVariant(target:objectName()))  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local target_name = player:getTag("beide_target"):toString()  
        player:removeTag("beide_target")  
          
        local target = room:findPlayer(target_name)  
        if target then  
            -- 将新目标添加到杀的目标列表中  
            use.to:append(target)  
            room:sortByActionOrder(use.to)  
            data:setValue(use)  
              
            -- 触发新目标的TargetConfirming事件  
            room:getThread():trigger(sgs.TargetConfirming, room, target, data)  
        end  
          
        return false  
    end  
}
  
 
wenjiang:addSkill(beide)  
wenjiang:addSkill("jieguanxing")
-- 翻译表  
sgs.LoadTranslationTable{  
    ["wenjiang"] = "文姜",
    ["beide"] = "背德",  
    [":beide"] = "当你成为杀的目标时，你可以指定一名其他角色也成为杀的目标。",  
    ["@beide-choose"] = "背德：你可以指定一名其他角色也成为此杀的目标"  
}

wuyong = sgs.General(extension, "wuyong", "qun", 3)  

-- 神算触发  
Shensuan = sgs.CreateTriggerSkill{  
    name = "shensuan",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill("shensuan")   
            and player:getPhase() == sgs.Player_Finish   
            and not player:isKongcheng() then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)  
        local card = room:askForCard(player, ".|.|.|hand", self:objectName(), data, sgs.Card_MethodDiscard)
        if not card then return false end
        -- 获取弃置牌的花色
        local sum = 0
        local point = card:getNumber()
        local judge_cards = sgs.IntList()
        repeat  
            local judge = sgs.JudgeStruct()  
            judge.pattern = "."  
            judge.who = player  
            judge.reason = self:objectName()  
            room:judge(judge)  

            sum = sum + judge.card:getNumber()
            judge_cards:append(judge.card:getId())  
        until sum >= point
        if not judge_cards:isEmpty() then  
            -- 获得所有红色判定牌  
            --[[
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
            for _, id in sgs.qlist(judge_cards) do  
                dummy:addSubcard(id)  
            end  
            ]]
            local dummy = sgs.DummyCard(judge_cards)  
            room:obtainCard(player, dummy, false)  
            dummy:deleteLater()  
        end

        return false  
    end  
}  
  
-- 天机技能  
Tianji = sgs.CreateTriggerSkill{  
    name = "tianji",  
    events = {sgs.CardFinished, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        local card = nil  
        if event == sgs.CardFinished then  
            card = data:toCardUse().card  
        --[[
        elseif event == sgs.CardResponded then  
            local response = data:toCardResponse()  
            if response.m_isUse then  
                card = response.m_card  
            end  
        ]]
        end  

        if card and not card:hasFlag("tianji_used") then  
            card:setFlags("tianji_used")

            local sum = player:getMark("@tianji_sum") + card:getNumber()  
            room:setPlayerMark(player, "@tianji_sum", sum)  
              
            if sum >= 13 then  
                -- 重置点数和  
                room:setPlayerMark(player, "@tianji_sum", 0)
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        --local ids = room:getNCards(3, false)  
        --[[
        --从摸牌堆3张选1张
        local card_ids = sgs.IntList()  
        for _, id in sgs.qlist(ids) do  
            card_ids:append(id)  
        end  
          
        room:fillAG(card_ids, player)  
        local id = room:askForAG(player, card_ids, false, self:objectName())  
        room:clearAG(player)  
          
        if id ~= -1 then  
            room:obtainCard(player, id)  
        end
        ]]
        --观星3，然后摸1张
        --room:askForGuanxing(player, ids, sgs.Room_GuanxingUpOnly)
        room:drawCards(player,1,self:objectName())
        return false  
    end  
}  
  
wuyong:addSkill(Shensuan)
wuyong:addSkill(Tianji)
sgs.LoadTranslationTable{
["#wuyong"] = "智多星",  
["wuyong"] = "吴用",  
["illustrator:wuyong"] = "待定",  
["shensuan"] = "神算",  
[":shensuan"] = "回合结束时，你可以弃置一张手牌，然后进行判定，直到判定牌点数和大于等于你弃置的牌，你获得所有判定牌。",  
["@shensuan"] = "你可以发动'神算'，弃置一张手牌",  
["tianji"] = "天机",  
--[":tianji"] = "每当你使用牌结算后，若点数和达到13，你可以观看牌堆顶3张牌并以任意顺序牌列，然后摸1张牌。",
[":tianji"] = "每当你使用牌结算后，若点数和达到13，你可以摸1张牌。",
}

wuzetian = sgs.General(extension, "wuzetian", "qun", 4, false)  

nvhuang = sgs.CreateTriggerSkill{  
    name = "nvhuang",  
    events = {sgs.EventPhaseStart},  
      
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Start then    
            local wuzetian = room:findPlayerBySkillName(self:objectName())  
            if wuzetian and wuzetian:isAlive() and not wuzetian:isKongcheng() and   
            not player:isKongcheng() and wuzetian:objectName() ~= player:objectName() then  
                return self:objectName(), wuzetian:objectName()
            end  
        --elseif player:getPhase() == sgs.Player_Finish then
            --清除标记。单回合标记会自动清除
            --room:removePlayerCardLimitation(player, "use", "TrickCard", true)
            --或
            --room:clearPlayerCardLimitation(player, true)
        end
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, wuzetian)  
        if wuzetian:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), wuzetian)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, wuzetian)  
        -- 发起拼点  
        local success = wuzetian:pindian(player, self:objectName())  
        if success then  
            -- 武则天拼点赢，设置标记，禁止使用锦囊牌。需要清除标记
            room:setPlayerCardLimitation(player, "use", "TrickCard", true)  --true表示单回合标记，会自动清除
              
            -- 日志  
            local msg = sgs.LogMessage()  
            msg.type = "#NvhuangEffect"  
            msg.from = wuzetian  
            msg.to:append(player)  
            msg.arg = self:objectName()  
            room:sendLog(msg)  
        end  
        return false  
    end  
}

qiandu = sgs.CreateTriggerSkill{  
    name = "qiandu",  
    events = {sgs.StartJudge},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        local wuzetian = room:findPlayerBySkillName(self:objectName())  
        if wuzetian and wuzetian:isAlive() then  
            return self:objectName(), wuzetian:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, wuzetian)  
        if wuzetian:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), wuzetian)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, wuzetian)  
        local judge = data:toJudge()  
          
        -- 查看牌堆顶的2张牌  
        local cards = room:getNCards(2)  
        room:askForGuanxing(wuzetian, cards, sgs.Room_GuanxingUpOnly)
          
        -- 日志  
        local msg = sgs.LogMessage()  
        msg.type = "#QianduEffect"  
        msg.from = wuzetian  
        msg.to:append(player)  
        msg.arg = self:objectName()  
        room:sendLog(msg)  
          
        return false  
    end  
}


qiaoqianCard = sgs.CreateSkillCard{  
    name = "qiaoqian",  
    target_fixed = false,  
    will_throw = true,
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        room:swapSeat(source, target)
    end  
}  

qiaoqian = sgs.CreateViewAsSkill{  
    name = "qiaoqian",  
    view_filter = function(self, selected, to_select)  
        return #selected < 2 and not to_select:isEquipped() 
    end,  
    view_as = function(self, cards)  
        if #cards ~= 2 then return nil end  
        local card = qiaoqianCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        for _, c in ipairs(cards) do  
            card:addSubcard(c)  
        end  
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#qiaoqian") and player:getHandcardNum()>=2
    end  
}  

wuzetian:addSkill(nvhuang)  
wuzetian:addSkill(qiandu)
wuzetian:addSkill(qiaoqian)

sgs.LoadTranslationTable{  
    ["wuzetian"] = "武则天",  
    ["#wuzetian"] = "一代女皇",  
      
    ["nvhuang"] = "女皇",  
    [":nvhuang"] = "一名角色的准备阶段，你可以与其拼点，若你赢，其本回合不能使用锦囊牌。",  
    ["#NvhuangEffect"] = "%from 发动了'%arg'，%to 本回合不能使用锦囊牌",  
      
    ["qiandu"] = "迁都",  
    [":qiandu"] = "一名角色开始判定前，你可以查看牌堆顶的2张牌，并改变这两张牌的顺序。",  
    ["#QianduEffect"] = "%from 发动了'%arg'，调整了牌堆顶的牌",  

    ["qiaoqian"] = "乔迁",  
    [":qiaoqian"] = "出牌阶段限一次。你可以弃置两张手牌，和一名角色交换座位",      
}

-- 创建武将：
xiajie = sgs.General(extension, "xiajie", "shu", 4)  -- 吴国，4血，男性  

-- 创建暴政触发技能  
shenli = sgs.CreateTriggerSkill{  
    name = "shenli",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Compulsory,  -- 锁定技  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName() == player:objectName() then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，自动触发  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local lost_hp = player:getLostHp()  
          
        if lost_hp > 0 then  
            room:notifySkillInvoked(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
              
            -- 发送日志  
            local msg = sgs.LogMessage()  
            msg.type = "#shenli"  
            msg.from = player  
            msg.to:append(damage.to)  
            msg.arg = self:objectName()  
            msg.arg2 = tostring(lost_hp)  
            room:sendLog(msg)  
              
            -- 增加伤害  
            damage.damage = damage.damage + lost_hp  
            data:setValue(damage)  
        end  
          
        return false  
    end,  
}

tianfa = sgs.CreateTriggerSkill{  
    name = "tianfa",  
    events = {sgs.Death},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then return "" end  
        local death = data:toDeath()  
        if death.who ~= player then return "" end  
        return self:objectName()  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, 2, "@tianfa-choose", true)            
        for _, target in sgs.qlist(targets) do  
            if target and target:isAlive() then  
                local judge = sgs.JudgeStruct()  
                judge.pattern = ".|spade"  
                judge.good = false  
                judge.negative = true  
                judge.reason = self:objectName()  
                judge.who = target  
                  
                room:judge(judge)  
                  
                if judge:isBad() then  
                    local damage = sgs.DamageStruct()  
                    damage.from = player  
                    damage.to = target  
                    damage.damage = 3  
                    damage.reason = self:objectName()  
                    room:damage(damage)  
                end  
            end  
        end  
        return false  
    end  
}
xiajie:addSkill(shenli)
xiajie:addSkill(tianfa)
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["xiajie"] = "夏桀",
    ["#xiajie"] = "暴君-夏",
    ["shenli"] = "神力",  
    [":shenli"] = "锁定技，你使用【杀】造成伤害时，增加你已失去体力值的伤害。",  
    ["tianfa"] = "天罚",
    [":tianfa"] = "当你死亡时，你可以选择至多两名角色，令他们分别进行判定，若判定牌为黑桃，则该角色受到3点伤害。",  
    ["@tianfa-choose"] = "天罚：选择两名角色进行判定",
}

xiangyu = sgs.General(extension, "xiangyu", "wei", 4)  --或者把虞姬放到qun？

pofu = sgs.CreateViewAsSkill{  
    name = "pofu",  
    n = 999, -- 可以选择所有手牌  
    view_filter = function(self, selected, to_select)  
        return #selected < sgs.Self:getHandcardNum() and not to_select:isEquipped() 
    end,  
    view_as = function(self, cards)  
        if #cards ~= sgs.Self:getHandcardNum() then return nil end  
        local duel = sgs.Sanguosha:cloneCard("duel")  
        duel:setSkillName("pofu")  
        duel:setShowSkill("pofu")  
        for _, card in ipairs(cards) do  
            duel:addSubcard(card)  
        end  
        return duel  
    end,  
    enabled_at_play = function(self, player)  
        return not player:isKongcheng()  
    end,  
}  

xiangyu:addSkill(pofu)
xiangyu:addSkill("wushuang")

sgs.LoadTranslationTable{  
    ["xiangyu"] = "项羽",  
      
    ["pofu"] = "破釜",  
    [":pofu"] = "出牌阶段，你可以将所有手牌当作决斗使用",  
}

xiaohe = sgs.General(extension, "xiaohe", "wu", 3)  

yuefa = sgs.CreateTriggerSkill{
	name = "yuefa",
	events = {sgs.TargetChoosing},
    can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetChoosing and player and player:isAlive() then
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and use.card:isKindOf("TrickCard") and use.to:length()>=room:getAlivePlayers():length()-1 then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skill_owner and skill_owner:isAlive() and skill_owner:hasSkill(self:objectName()) then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, skill_owner)
		if skill_owner:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), skill_owner)
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, skill_owner)
		if skill_owner:isAlive() then
			local use = data:toCardUse()
			local targets = room:getUseExtraTargets(use, false)
			for _, p in sgs.qlist(use.to) do
				if p:isAlive() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local prompt = "@yuefa-target:" .. player:objectName() .. "::" .. use.card:objectName()
				skill_owner:setTag("yuefaUsedata", data)
				local target = room:askForPlayerChosen(skill_owner, targets, "yuefa_target", prompt)
				skill_owner:removeTag("yuefaUsedata")
				room:doAnimate(1, skill_owner:objectName(), target:objectName())
				if use.to:contains(target) then
					sgs.Room_cancelTarget(use, target)
				else
					use.to:append(target)
					room:sortByActionOrder(use.to)
				end
				data:setValue(use)
			end
		end
		return false
	end,
}


yunliangCard = sgs.CreateSkillCard{
	name = "yunliangCard",
	will_throw = true,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
    on_effect = function(self, effect)
        effect.to:drawCards(2,"yunliang")
	end,
}

yunliang = sgs.CreateViewAsSkill{   
	name = "yunliang",
	view_filter = function(self, selected, to_select)
		return #selected < 2 --and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
        if #cards ~= 2 then return false end
		local skillcard = yunliangCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		for _,card in ipairs(cards) do
			skillcard:addSubcard(card)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#yunliangCard")
	end,
}

xiaohe:addSkill(yuefa)
xiaohe:addSkill(yunliang)

sgs.LoadTranslationTable{
    ["xiaohe"] = "萧何",
    ["yuefa"] = "约法",
    [":yuefa"] = "当群体锦囊指定目标时，你可以减少一个目标",

    ["yunliang"] = "运粮",
    [":yunliang"] = "出牌阶段限一次。你可以弃置2张牌，令一名角色摸2张牌",
}

xiaoqiao_hero = sgs.General(extension, "xiaoqiao_hero", "wu", 3, false)  -- 吴国，4血，男性  

tianxiangSkip = sgs.CreateTriggerSkill{  
    name = "tianxiangSkip",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Start then  
            return ""  
        end  
          
        -- 检查是否有判定区有牌  
        --[[
        if player:getJudgingArea():isEmpty() then  
            return ""  
        end  
        ]]
        -- 查找拥有天香技能的角色  
        local tianxiangSkiper = room:findPlayerBySkillName(self:objectName())  
        if tianxiangSkiper and tianxiangSkiper:isAlive() then  
            return self:objectName(), tianxiangSkiper:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        --local prompt = "@tianxiangSkip-invoke:" .. player:objectName()  
        if room:askForSkillInvoke(ask_who, self:objectName(), data) then  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 跳过判定阶段
        local choice = room:askForChoice(ask_who, self:objectName(),"start+judge+both+cancel")
        if choice=="start" then
            player:skip(sgs.Player_Start)   
        elseif choice=="judge" then
            player:skip(sgs.Player_Judge)
        elseif choice=="both" then
            player:skip(sgs.Player_Start)   
            player:skip(sgs.Player_Judge)
        end
        return false  
    end,  
}

xiaoqiao_hero:addSkill(tianxiangSkip)
xiaoqiao_hero:addSkill("bazhen")
sgs.LoadTranslationTable{
    ["xiaoqiao_hero"] = "小乔",
    ["tianxiangSkip"] = "天香-跳",  
    [":tianxiangSkip"] = "任意角色的准备阶段，你可以令其跳过准备阶段或判定阶段。",  
    ["@tianxiangSkip-invoke"] = "天香：你可以令 %src 跳过判定阶段",
}

xiaozhuangtaihou = sgs.General(extension, "xiaozhuangtaihou", "qun", 3, false)  

youshuo_card = sgs.CreateSkillCard{  
    name = "YouShuoCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets < 1 and to_select:isAlive()  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local first = targets[1]  
        local second = room:askForPlayerChosen(source, room:getOtherPlayers(first), self:objectName(), "youshuo", false)  
          
        -- 设置标记记录关系，直到下回合开始  
        local mark_name = "youshuo_" .. source:objectName()  
        room:setPlayerMark(first, mark_name .. "_from", 1)  
        room:setPlayerMark(second, mark_name .. "_to", 1)  
    end  
}  
  
youshuoVS= sgs.CreateViewAsSkill{  
    name = "youshuo",  
    view_filter = function(self, selected, to_select)
        -- 只能选择手牌
        if to_select:isEquipped() then
            return false
        end        
        return #selected < 2
    end,
    view_as = function(self, cards)  
        if #cards == 2 then  
            local card = youshuo_card:clone()  
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
        return not player:hasUsed("#YouShuoCard") and player:getHandcardNum() >= 2  
    end  
}  

-- 游说伤害触发技能  
youshuo = sgs.CreateTriggerSkill{  
    name = "youshuo",  
    events = {sgs.Damage},  
    --frequency = sgs.Skill_Compulsory,
    view_as_skill = youshuoVS,      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() then return "" end  
          
        -- 检查是否有游说标记  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            local mark_name = "youshuo_" .. p:objectName()  
            if player:getMark(mark_name .. "_from") > 0 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 找到对应的回复目标  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            local mark_name = "youshuo_" .. p:objectName()  
            if player:getMark(mark_name .. "_from") > 0 then  
                for _, target in sgs.qlist(room:getAlivePlayers()) do  
                    if target:getMark(mark_name .. "_to") > 0 then  
                        local recover = sgs.RecoverStruct()  
                        recover.who = p  
                        recover.recover = damage.damage  
                        room:recover(target, recover)  
                        break  
                    end  
                end  
                break  
            end  
        end  
          
        return false  
    end  
}  
  
-- 游说清理技能  
youshuo_clear = sgs.CreateTriggerSkill{  
    name = "#youshuo-clear",  
    events = {sgs.TurnStart},  
    --frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:hasSkill("youshuo") then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        -- 清理所有相关标记  
        local mark_name = "youshuo_" .. player:objectName()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            room:setPlayerMark(p, mark_name .. "_from", 0)  
            room:setPlayerMark(p, mark_name .. "_to", 0)  
        end  
        return false  
    end  
}  

-- 技能2：天命 - 比较花色给予标记  
renming_card = sgs.CreateSkillCard{  
    name = "renmingCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:isAlive() and not to_select:isKongcheng()  
    end,  
    feasible = function(self, targets)  
        return #targets == 1  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        -- 各弃一张手牌  
        local source_card = room:askForCardChosen(source, source, "h", "renming")  
        local target_card = room:askForCardChosen(target, target, "h", "renming")  
          
        local source_suit = sgs.Sanguosha:getCard(source_card):getSuit()  
        local target_suit = sgs.Sanguosha:getCard(target_card):getSuit()  
          
        room:throwCard(sgs.Sanguosha:getCard(source_card), source, source)  
        room:throwCard(sgs.Sanguosha:getCard(target_card), target, target)  
        -- 比较花色  
        if source_suit == target_suit then  
            room:setPlayerMark(target, "@ming", 1)  
        end  
    end  
}  
  
renmingVS = sgs.CreateZeroCardViewAsSkill{  
    name = "renming",  
    view_as = function(self)  
        local card = renming_card:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#renmingCard") and not player:isKongcheng()  
    end  
}  
  
-- 天命跳过摸牌阶段  
renming = sgs.CreateTriggerSkill{  
    name = "renming",  
    events = {sgs.EventPhaseStart},  
    --frequency = sgs.Skill_Compulsory,  
    view_as_skill = renmingVS,        
    can_trigger = function(self, event, room, player, data)  
        if player and player:getMark("@ming") > 0 and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        player:skip(sgs.Player_Draw)  
        room:setPlayerMark(player, "@ming", 0)  
        return false  
    end  
}  
  

xiaozhuangtaihou:addSkill(youshuo)  
xiaozhuangtaihou:addSkill(youshuo_clear)  
xiaozhuangtaihou:addSkill(renming)  
extension:insertRelatedSkills("youshuo","#youshuo-clear")
-- 翻译表  
sgs.LoadTranslationTable{  
    ["xiaozhuangtaihou"] = "孝庄太后",  
    ["youshuo"] = "游说",  
    [":youshuo"] = "出牌阶段限一次，你可弃置两张手牌，指定两名角色，则直到你的下回合开始前，前者造成伤害时，后者回复等量的体力。",  
    ["renming"] = "认命",  
    [":renming"] = "出牌阶段限一次，你可以选择一名目标，令其和你各弃一张手牌，若你们弃牌的花色相同，则该目标获得一个'命'标记，下回合跳过摸牌阶段，并移除'命'标记。",  
    ["YouShuoCard"] = "游说",  
    ["renmingCard"] = "认命",  
    ["@ming"] = "命"  
}

xuanzang = sgs.General(extension, "xuanzang", "wu", 3)  -- 吴国，4血，男性  

puduCard = sgs.CreateSkillCard{  
    name = "puduCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 --and to_select:objectName() ~= self.Self:objectName()
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local x = source:getEquips():length()  
        source:throwAllEquips()            
        -- 询问选择摸牌还是弃牌  
        local choice = room:askForChoice(source, self:objectName(),   
            "draw:" .. x .. "+discard:" .. x)  
            
        if choice:startsWith("draw") then  
            target:drawCards(x, self:objectName())  
        else  
            room:askForDiscard(target, self:objectName(), x, x, false, true)  
        end  
    end  
}  
  
-- 视为技实现  
pudu = sgs.CreateZeroCardViewAsSkill{  
    name = "pudu",  
    view_as = function(self)  
        local skill_card = puduCard:clone()  
        skill_card:setSkillName(self:objectName())  
        skill_card:setShowSkill(self:objectName())  
        return skill_card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#puduCard") and not player:getEquips():isEmpty()  
    end  
}  

jiasha = sgs.CreateTriggerSkill{  
    name = "jiasha",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then   
            return ""   
        end  
        return self:objectName()  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        player:drawCards(1)
        local damage = data:toDamage()  
        local from = damage.from  
        if from and from:isAlive() and not from:isAllNude() then  
            --isKongcheng()检查手牌，isNude()检查手牌+装备区，isAllNude()检查手牌+装备区+判定区
            local card_id = room:askForCardChosen(player, from, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
            room:throwCard(card_id, from, player)  
        end  
        return false  
    end  
}

xuanzang:addSkill(pudu)
xuanzang:addSkill(jiasha)

sgs.LoadTranslationTable{
    ["xuanzang"] = "玄奘",
    ["pudu"] = "普渡",  
    [":pudu"] = "出牌阶段限一次，你可以弃置装备区所有装备，令一名角色摸X张牌或弃X张牌，X为弃置的装备数量。",  
    ["draw:%arg"] = "摸%arg张牌",  
    ["discard:%arg"] = "弃%arg张牌",
    ["jiasha"] = "袈裟",  
    [":jiasha"] = "当你受到伤害时，你可以摸一张牌，弃置伤害来源一张牌。"
}

-- 创建武将：唐伯虎  
xunzi = sgs.General(extension, "xunzi", "qun", 3)  -- 吴国，4血，男性  


-- 技能1：教化  
quyongCard = sgs.CreateSkillCard{  
    name = "quyongCard",  
    target_fixed = true,  
    on_use = function(self, room, source, targets)  
        local allPlayers = room:getAlivePlayers()  
        source:drawCards(1)
        for _, target in sgs.qlist(allPlayers) do  
            if target:objectName() ~= source:objectName() and not target:isAllNude() then  
                local card_id = room:askForCardChosen(source, target, "hej", "quyong")  
                room:obtainCard(source, card_id, false)  
            end  
        end  
          
        for _, target in sgs.qlist(allPlayers) do  
            if target:objectName() ~= source:objectName() and not source:isNude() then  
                local card_id = room:askForCardChosen(source, source, "he", "quyong", false)  
                --local card_id = room:askForExchange(source, self:objectName(), 1,1)   
                --room:moveCardTo(sgs.Sanguosha:getCard(card_id), target, sgs.Player_PlaceHand, false)  
                room:obtainCard(target, card_id, false)
            end  
        end  
    end  
}  
  
quyong = sgs.CreateZeroCardViewAsSkill{  
    name = "quyong",  
    view_as = function(self, cards)  
        local card = quyongCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#quyongCard")  
    end  
}  
-- 添加技能到武将  
xunzi:addSkill(quyong)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["xunzi"] = "荀子",  
    ["quyong"] = "取用",  
    [":quyong"] = "出牌阶段限一次，你可以摸一张牌，获得所有角色各一张牌，然后交给他们各一张牌。",  
}  

xuxiake = sgs.General(extension, "xuxiake", "wu", 4)  -- 吴国，4血，男性  
chuyou = sgs.CreateTriggerSkill{  
    name = "chuyou",  
    events = {sgs.EventPhaseChanging},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) or not player:isAlive() then  
            return ""  
        end  
          
        local change = data:toPhaseChange()  
        if change.to == sgs.Player_Draw or change.to == sgs.Player_Play then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local change = data:toPhaseChange()  
        local phase_name = ""  
        if change.to == sgs.Player_Draw then  
            phase_name = "摸牌阶段"  
        elseif change.to == sgs.Player_Play then  
            phase_name = "出牌阶段"  
        end  
          
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local change = data:toPhaseChange()  
          
        -- 跳过阶段  
        player:skip(change.to)  
          
        -- 摸一张牌  
        player:drawCards(1, self:objectName())  
          
        -- 增加手牌上限+2（永久效果）  
        room:addPlayerMark(player, "@chuyou_maxcards", 2)  
          
        return false  
    end  
}  
  
-- 手牌上限技能  
chuyou_maxcards = sgs.CreateMaxCardsSkill{  
    name = "#chuyou_maxcards",  
    extra_func = function(self, player)  
        return math.min(player:getMark("@chuyou_maxcards"),8)
    end  
}

suyuan = sgs.CreateTriggerSkill{  
    name = "suyuan",  
    events = {sgs.EventPhaseSkipping},  
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        return self:objectName()  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName()) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local alive_count = room:getAlivePlayers():length()  
        local guanxing_num = alive_count + 1  
        local guanxing = room:getNCards(guanxing_num)  
          
        -- 执行观星  
        room:askForGuanxing(player, guanxing, sgs.Room_GuanxingUpOnly)  
          
        -- 自己摸2张牌  
        room:drawCards(player, 2, self:objectName())  

        local others = {}  
        for _, other in sgs.qlist(room:getOtherPlayers(player)) do  
            --room:getOtherPlayers(player) 返回的玩家列表就是按照从当前行动角色开始的行动顺序排列
            room:drawCards(other, 1, self:objectName())  
        end          
        return false  
    end  
}
xuxiake:addSkill(chuyou)  
xuxiake:addSkill(chuyou_maxcards)  
xuxiake:addSkill(suyuan)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
      
    ["#xuxiake"] = "游圣",  
    ["xuxiake"] = "徐霞客",  
    ["illustrator:xuxiake"] = "未知",  
      
    ["chuyou"] = "出游",  
    [":chuyou"] = "你可以跳过摸牌阶段或者出牌阶段，然后你摸一张牌，使手牌上限永久+2，至多＋8",  
      
    ["suyuan"] = "溯源",   
    [":suyuan"] = "当你主动或被动跳过任意阶段时，你可以发动观星，查看牌堆顶X+1张牌并以任意顺序放在牌堆顶，X为场上存活玩家数，然后你摸2张牌，其余玩家各摸一张牌。",  
      
    ["skip_draw"] = "跳过摸牌阶段",  
    ["skip_play"] = "跳过出牌阶段"  
}  

-- 创建武将：
yangguang = sgs.General(extension, "yangguang", "wei", 3)  -- 吴国，4血，男性  

-- 拒绝谏言技能卡  
JujueJianyanCard = sgs.CreateSkillCard{  
    name = "jujue_jianyan_card",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:hasFlag("JujueJianyanTarget")  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        -- 给予手牌  
        room:obtainCard(target, self, false)  
        -- 标记该角色，表示已经对其使用过技能  
        room:setPlayerFlag(target, "JujueJianyanTarget")  
        -- 标记该角色，表示本轮其使用的锦囊对你无效  
        local mark = string.format("@jujue_jianyan_%s", source:objectName())  
        room:setPlayerMark(target, mark, 1)  
    end  
}  
  
-- 拒绝谏言视为技  
JujueJianyanViewAsSkill = sgs.CreateViewAsSkill{  
    name = "jujuejianyan",  
      
    view_filter = function(self, selected, to_select)  
        return not to_select:isEquipped() and #selected == 0  
    end,  
      
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = JujueJianyanCard:clone()  
            card:addSubcard(cards[1])  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())
            return card  
        end  
        return nil  
    end,  
}  
  
-- 拒绝谏言主技能  
JujueJianyan = sgs.CreateTriggerSkill{  
    name = "jujuejianyan",  
    events = {sgs.CardEffected, sgs.EventPhaseStart},  
    view_as_skill = JujueJianyanViewAsSkill,  
      
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.CardEffected then  
            -- 处理锦囊无效效果  
            local effect = data:toCardEffect()  
            if effect.card and effect.card:isKindOf("TrickCard") and effect.to and effect.to:hasSkill(self:objectName()) then  
                -- 检查目标中是否包含有标记的角色  
                local mark = string.format("@jujue_jianyan_%s", effect.to:objectName())  
                if effect.from and effect.from:getMark(mark) > 0 then  
                    return self:objectName(), effect.to:objectName()  
                end  
            end  
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then  
            -- 回合开始时清除标记  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                room:setPlayerFlag(p, "-JujueJianyanTarget")  
                -- 清除所有与该角色相关的标记  
                for _, p2 in sgs.qlist(room:getAlivePlayers()) do  
                    local mark = string.format("@jujue_jianyan_%s", p2:objectName())  
                    if p:getMark(mark) > 0 then  
                        room:setPlayerMark(p, mark, 0)  
                    end  
                end  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return true -- 强制触发  
    end,  
    
    on_effect = function(self, event, room, player, data, ask_who)        
        return true  --返回true，终止效果结算
    end
}

-- 创建徭役触发技能  
yaoyi = sgs.CreateTriggerSkill{  
    name = "yaoyi",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        return self:objectName()  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data) 
    end,  
      
    on_effect = function(self, event, room, player, data)  
        -- 计算场上已受伤的角色数  
        local wounded_count = 0
        local kingdoms = {}  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:isWounded() then
                if not p:hasShownOneGeneral() or p:getRole() == 'careerist' then --野心家视为不同势力
                    wounded_count = wounded_count+1
                else
                    kingdoms[p:getKingdom()] = true  
                end
            end
        end  
        kingdoms[player:getKingdom()] = true  
          
        for _ in pairs(kingdoms) do  
            wounded_count = wounded_count + 1  
        end  

        if wounded_count > 0 then  
            room:notifySkillInvoked(player, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
              
            -- 发送日志  
            local msg = sgs.LogMessage()  
            msg.type = "#yaoyi"  
            msg.from = player  
            msg.arg = self:objectName()  
            msg.arg2 = tostring(wounded_count)  
            room:sendLog(msg)  
              
            -- 摸X张牌  
            player:drawCards(math.min(wounded_count,5))  
        end  
          
        return false  
    end,  
}

yangguang:addSkill(JujueJianyan)
yangguang:addSkill(yaoyi)

sgs.LoadTranslationTable{  
    ["yangguang"] = "杨广",
    ["jujuejianyan"] = "拒谏",  
    [":jujuejianyan"] = "出牌阶段，你可以将一张手牌交给一名角色，令本轮该角色对你使用的锦囊无效。",  
    ["jujuejianyan"] = "拒谏",  

    
    ["yaoyi"] = "徭役",  
    [":yaoyi"] = "当你受到伤害后，你摸X张牌，X为场上已受伤角色的确定势力数+未确定势力数，且至多为5。",  
}

-- 创建武将：杨玉环
yangyuhuan = sgs.General(extension, "yangyuhuan", "wei", 3, false)  -- 群雄，3血  


-- 技能1：羞花 - 当你的手牌数小于失去的体力时，你摸一张牌  
xiuhua = sgs.CreateTriggerSkill{  
    name = "xiuhua",
    frequency = sgs.Skill_Compulsory, --锁定技
    events = {sgs.CardsMoveOneTime, sgs.HpChanged, sgs.MaxHpChanged},  --集合，可以有多个触发条件
          
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        local lost_hp = player:getLostHp()  
        local handcard_num = player:getHandcardNum()  
        local draw_num = lost_hp - handcard_num  
        if draw_num > 0 then
            return self:objectName()
        end
        return false
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        local lost_hp = player:getLostHp()  
        local handcard_num = player:getHandcardNum()  
        local draw_num = lost_hp - handcard_num  
          
        if draw_num > 0 then  
            room:drawCards(player, draw_num, self:objectName())  
        end  
          
        return false  
    end,
}  

fengyan = sgs.CreateTriggerSkill{  
    name = "fengyan",  
    events = {sgs.FinishJudge},  
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)  
        if not player then  
            return false  
        end  
          
        local judge = data:toJudge() 
        owner = room:findPlayerBySkillName(self:objectName()) 
        if judge.who:isMale() and judge.card:isBlack() and room:getCardPlace(judge.card:getId()) == sgs.Player_DiscardPile then  
            return self:objectName(), owner:objectName()
        end  
          
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local judge = data:toJudge()
        if room:getCardPlace(judge.card:getId()) == sgs.Player_DiscardPile then
            room:obtainCard(ask_who,judge.card:getId())            
        end
        return false  
    end  
}  
-- 添加技能给武将  
yangyuhuan:addSkill(xiuhua)  
yangyuhuan:addSkill(fengyan)
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["yangyuhuan"] = "杨玉环",  

    ["xiuhua"] = "羞花",  
    [":xiuhua"] = "锁定技，当你的手牌数小于失去的体力时，你摸一张牌。",
    ["fengyan"] = "丰艳",  
    [":fengyan"] = "男性角色判定牌进入弃牌堆后，若判定牌为黑色，你可以获得判定牌",
}  

yuanshitianzun = sgs.General(extension, "yuanshitianzun", "wei", 3)  --wei,jin

yuanshiCard = sgs.CreateSkillCard{  
    name = "yuanshiCard",  
    target_fixed = true,  
    on_use = function(self, room, source, targets)  
        local x = source:getHp() + 1
        x = math.min(x, source:getHandcardNum())
        local to_discard = room:askForDiscard(source, "yuanshi", x, x, false, false)  
        local recover = sgs.RecoverStruct()  
        recover.who = source  
        recover.recover = 1  
        room:recover(source, recover)  
    end  
}  
  
yuanshi = sgs.CreateZeroCardViewAsSkill{  
    name = "yuanshi",  
    view_as = function(self, cards)  
        local card = yuanshiCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#yuanshiCard") and not player:isKongcheng()
    end  
}  
  
-- 技能2：天尊 - 失去体力摸牌  
tianzunCard = sgs.CreateSkillCard{  
    name = "tianzunCard",   
    target_fixed = true,  
    on_use = function(self, room, source, targets)  
        room:loseHp(source, 1)  
        local x = source:getMaxHp()  
        local need = x - source:getHandcardNum()  
        if need > 0 then  
            source:drawCards(need, "tianzun")  
        end  
    end  
}  
  
tianzun = sgs.CreateZeroCardViewAsSkill{  
    name = "tianzun",  
    view_as = function(self, cards)  
        local card = tianzunCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        if player:hasUsed("#tianzunCard") then return false end  
        return player:getHp() > 0  
    end  
}  
  

yuanshitianzun:addSkill(yuanshi)  
yuanshitianzun:addSkill(tianzun)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["yuanshitianzun"] = "元始天尊",  
    ["yuanshi"] = "元始",  
    [":yuanshi"] = "出牌阶段限一次，你可以弃置X+1张手牌，回复一点体力，X为当前体力值。不足则全弃。",  
    ["tianzun"] = "天尊",   
    [":tianzun"] = "出牌阶段限一次，你可以失去一点体力，摸牌至体力上限",  
    ["yuanshiCard"] = "元始",  
    ["tianzunCard"] = "天尊"  
}

yuantiangang = sgs.General(extension, "yuantiangang", "qun", 3)  --wei 

xiangshuCard = sgs.CreateSkillCard{  
    name = "xiangshuCard",  
    target_fixed = true,  
    will_throw = true,  
      
    on_use = function(self, room, source, targets)  
        top_cards=room:getNCards(2)
        room:askForGuanxing(source, top_cards, sgs.Room_GuanxingBothSides)-- GuanxingUpOnly, GuanxingBothSides, GuanxingDownOnly
        source:drawCards(1,self:objectName())
        -- 标记最后摸到的牌 
        local last_card_id = source:handCards():last()  
        local last_card = sgs.Sanguosha:getCard(last_card_id)  
        last_card:setFlags("xiangshu_obtain")  
        -- 获得标记的牌，那么这张牌一定没有用出去，所以要把 xiangshu_used 标记清掉
        room:setPlayerFlag(source,"-xiangshu_used")
    end  
}  
  
xiangshuVS = sgs.CreateOneCardViewAsSkill{  
    name = "xiangshu",  
    filter_pattern = ".|.|.|hand",  
      
    view_as = function(self, card)  
        local vs_card = xiangshuCard:clone()  
        vs_card:addSubcard(card)  
        vs_card:setSkillName("xiangshu")  
        vs_card:setShowSkill("xiangshu")  
        return vs_card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#xiangshuCard") or player:hasFlag("xiangshu_used")
    end  
}  
  
  
-- 注册技能  
xiangshu = sgs.CreateTriggerSkill{  
    name = "xiangshu",  
    view_as_skill = xiangshuVS,  
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase()==sgs.Player_Finish then
                for _, card_id in sgs.qlist(player:handCards()) do  
                    local hand_card = sgs.Sanguosha:getCard(card_id)  
                    if hand_card:hasFlag("xiangshu_obtain") then  
                        hand_card:removeFlag("xiangshu_obtain")
                    end  
                end  
            end
            return ""
        end
        local card = nil
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
        if card==nil then return "" end
        if card:hasFlag("xiangshu_obtain") then
            room:setPlayerFlag(player,"xiangshu_used")
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

quji2 = sgs.CreateTriggerSkill{  
    name = "quji2",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.EventPhaseStart},  --集合，可以有多个触发条件
          
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        if event == sgs.CardUsed then
            local use = data:toCardUse()  
            if use.from~=player or use.card:getTypeId()==sgs.Card_TypeSkill then return "" end 
            room:addPlayerMark(player,"@quji2",1)
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            local mark = player:getMark("@quji2")
            room:setPlayerMark(player,"@quji2",0) --不管数量够不够，都要清0
            if mark >= player:getMaxHp() then
                return self:objectName()
            end
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        room:drawCards(player, 2, self:objectName())  
        return false  
    end,
}  
yuantiangang:addSkill(xiangshu)
yuantiangang:addSkill(quji2)
sgs.LoadTranslationTable{
    ["yuantiangang"] = "袁天罡",
    ["xiangshu"] = "相术",
    [":xiangshu"] = "出牌阶段限一次。你可以弃置一张手牌，观看牌堆顶2张牌并以任意顺序放在牌堆顶或牌堆底，然后摸1张牌；本回合你使用或打出该牌后，你可以重置此技能",
    ["quji2"] = "趋吉",
    [":quji2"] = "结束阶段，若你本回合使用的牌数>=你的体力上限，你摸2张牌"
}

yuchigong = sgs.General(extension, "yuchigong", "wei", 4)  --wei,shu
huwei = sgs.CreateTriggerSkill{  
    name = "huwei",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        -- 检查是否有杀造成的伤害，且尉迟恭存活且拥有此技能  
        if damage.card and damage.card:isKindOf("Slash") then  
            local yuchigong = room:findPlayerBySkillName(self:objectName())  
            if yuchigong and yuchigong:isAlive() and yuchigong:hasSkill(self:objectName()) and yuchigong:isFriendWith(damage.to) then  
                return self:objectName(), yuchigong:objectName()
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local yuchigong = ask_who --room:findPlayerBySkillName(self:objectName())  
        if not yuchigong then return false end  
          
        local damage = data:toDamage()  
        local _data = sgs.QVariant()  
        _data:setValue(damage.to)  
          
        if yuchigong:askForSkillInvoke(self:objectName(), _data) then  
            -- 选择弃置装备牌或失去体力  
            if not room:askForCard(yuchigong,"EquipCard","@huwei-discard",sgs.QVariant(),sgs.Card_MethodDiscard) then
                room:loseHp(yuchigong, 1)  
            end                
            room:broadcastSkillInvoke(self:objectName(), yuchigong)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local yuchigong = ask_who --room:findPlayerBySkillName(self:objectName())  
        if not yuchigong then return false end  
          
        local damage = data:toDamage()  
        -- 减少1点伤害  
        damage.damage = damage.damage - 1  
        data:setValue(damage)  
          
        -- 摸X张牌，X为已失去的体力值  
        local lost_hp = yuchigong:getLostHp()  
        if lost_hp > 0 then  
            yuchigong:drawCards(lost_hp, self:objectName())  
        end  
        if damage.damage <= 0 then
            return true
        end
        return false  
    end  
}  
  
-- 创建尉迟恭武将  
yuchigong:addSkill(huwei)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["yuchigong"] = "尉迟恭",  
    ["huwei"] = "护卫",  
    [":huwei"] = "与你势力相同的角色受到杀的伤害时，你可以弃置一张装备牌或失去一点体力，令该杀的伤害-1，然后你摸X张牌，X为你已失去的体力值。",  
    ["discard_equip"] = "弃置装备牌",  
    ["lose_hp"] = "失去体力"  
}

-- 创建武将：岳飞  
yuefei = sgs.General(extension, "yuefei", "shu", 4)  -- 蜀国，4血  

wumu = sgs.CreateOneCardViewAsSkill{  
    name = "wumu",  
    guhuo_type = "b",  -- 显示基础牌选择框  
    filter_pattern = "BasicCard",  -- 只能选择基础牌
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
        return not player:isKongcheng()  
    end,
    
    enabled_at_response = function(self, player, pattern)  
        return pattern == "slash" or pattern == "jink" or string.find(pattern,"peach") or string.find(pattern,"analeptic")  
    end  
}



longnuSlash = sgs.CreateTriggerSkill{  
    name = "longnuSlash",  
    events = {sgs.SlashMissed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local effect = data:toSlashEffect() 
        local target = effect.to  
        if target and target:isAlive() then  
            return self:objectName()  
        end  
        return ""  
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
        local prompt = string.format("@longnu-slash:%s:%s:", target:objectName(), player:objectName())  
        room:askForUseSlashTo(player, target, prompt, false, false, false)
        return false  
    end  
}  
yuefei:addSkill(wumu)  
yuefei:addSkill(longnuSlash)
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["yuefei"] = "岳飞",  
      
    ["wumu"] = "武穆",  
    [":wumu"] = "你可以将一张基础牌当做一张基础牌使用或打出。",  

    ["@wumu"] = "请选择【武穆】要转化的牌",  
    ["~wumu"] = "选择一张基础牌→选择要视为的牌→确定",  

    ["longnuSlash"] = "龙怒",
    [":longnuSlash"] = "你的杀被抵消后，你可以继续对目标使用杀"
}  

yuji1 = sgs.General(extension, "yuji1", "wei", 3, false)  -- 吴国，4血，男性  

juebie = sgs.CreateTriggerSkill{  
    name = "juebie",  
    events = {sgs.Death},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        -- 寻找拥有运枢技能的角色  
        local death = data:toDeath()  
        local dead_player = death.who  
        if dead_player and dead_player:hasSkill(self:objectName()) and dead_player == player then  
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local death = data:toDeath()  
        local dead_player = death.who  
          
        -- 检查死亡角色是否有牌可以转移  
        if dead_player:isAllNude() then  
            return false  
        end  
          
        if dead_player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), dead_player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local death = data:toDeath()  
        local dead_player = death.who  
          
        -- 获取死亡角色的所有牌  
        local all_cards = sgs.IntList()  
        for _, card_id in sgs.qlist(dead_player:handCards()) do  
            all_cards:append(card_id)  
        end  
        for _, card in sgs.qlist(dead_player:getEquips()) do  
            all_cards:append(card:getId())  
        end  
        for _, card in sgs.qlist(dead_player:getJudgingArea()) do  
            all_cards:append(card:getId())  
        end  
          
        if all_cards:length() > 0 then  
            -- 选择一名其他角色  
            local targets = sgs.SPlayerList()  
            -- 收集可选目标  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if  dead_player:isFriendWith(p) then  
                    targets:append(p)            
                end  
            end  
            local target = room:askForPlayerChosen(dead_player, targets, self:objectName(), "@juebie-give")  
            if target then  
                -- 将所有牌交给目标角色  
                local move = sgs.CardsMoveStruct()  
                move.card_ids = all_cards  
                move.to = target  
                move.to_place = sgs.Player_PlaceHand  
                move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, target:objectName(), self:objectName(), "")  
                room:moveCardsAtomic(move, true)  
            end  
        end  
          
        return false  
    end  
}
yuji1:addSkill("yiji")  
yuji1:addSkill(juebie)  
  
-- 翻译表  
sgs.LoadTranslationTable{        
    ["yuji1"] = "虞姬",  
    ["juebie"] = "诀别",
    [":juebie"] = "你死亡时，你可以选择一名相同势力角色，获得你所有区域的牌"
}  
  
-- 创建武将：唐伯虎  
yuwenhuaji = sgs.General(extension, "yuwenhuaji", "qun", 4)  -- 吴国，4血，男性 
cuanni = sgs.CreateTriggerSkill{  
    name = "cuanni",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.from and damage.from:objectName() == player:objectName() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data) -- 锁定技，自动触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        -- 取消伤害  
        room:loseHp(damage.to, damage.damage)  
        return true -- 返回true阻止原伤害  
    end  
}

jiandi = sgs.CreateTriggerSkill{  
    name = "jiandi",  
    events = {sgs.DrawNCards},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:isNude() and not player:hasFlag("ni") then  
            --if player:getPhase() == sgs.Player_Start then  
                return self:objectName()  
            --end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:setPlayerFlag(player,"ni")
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)            
        --弃置1张牌
        if room:askForDiscard(player, self:objectName(), 1, 1, false, true) then
            -- 失去1点体力 
            room:loseHp(player, 1)
            -- 获得所有角色各一张牌  
            local targets = room:getAlivePlayers()  
            for _, target in sgs.qlist(targets) do  
                if target:objectName() ~= player:objectName() and not target:isAllNude() then  
                    local card_id = room:askForCardChosen(player, target, "hej", self:objectName())  
                    room:obtainCard(player, card_id, false)  
                end  
            end
            -- 跳过摸牌阶段  
            --player:skip(sgs.Player_Draw)
            local count = data:toInt()
            data:setValue(0)  
        end
        return false  
    end  
}

cuanquan = sgs.CreateTriggerSkill{
    name = "cuanquan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:isKongcheng() and not player:hasFlag("ni") then
            if player:getPhase() == sgs.Player_Start then  
                return self:objectName()  
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:setPlayerFlag(player,"ni")
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false 
    end,
    on_effect = function(self, event, room, player, data)
        --local card_id = room:askForCardChosen(player, player, "h", self:objectName(), false, sgs.Card_MethodDiscard)  
        --room:throwCard(card_id, player, player, self:objectName())  
        --local card = sgs.Sanguosha:getCard(card_id)
        local choice = room:askForChoice(player, self:objectName(), "color+suit")
        local card = room:askForCard(player, ".|.|.|hand", self:objectName(), data, sgs.Card_MethodDiscard)
        if not card then return false end
        -- 获取弃置牌的花色
        if choice == "color" then
            local discarded_suit = card:getColor()
            local judge_cards = {}  
            repeat  
                local judge = sgs.JudgeStruct()  
                judge.pattern = "."  
                judge.who = player  
                judge.reason = self:objectName()  
                room:judge(judge)  
                if judge.card:getColor()~=discarded_suit then
                    table.insert(judge_cards, judge.card:getId())  
                end  
            until judge.card:getColor()==discarded_suit
            if #judge_cards > 0 then  
                -- 获得所有红色判定牌  
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                for _, id in ipairs(judge_cards) do  
                    dummy:addSubcard(id)  
                end  
                room:obtainCard(player, dummy, false)  
                dummy:deleteLater()  
            end
        elseif choice == "suit" then
            local discarded_suit = card:getSuit()
            local judge_cards = {}  
            repeat  
                local judge = sgs.JudgeStruct()  
                judge.pattern = "."  
                judge.who = player  
                judge.reason = self:objectName()  
                room:judge(judge)  
                if judge.card:getSuit()~=discarded_suit then
                    table.insert(judge_cards, judge.card:getId())  
                end  
            until judge.card:getSuit()==discarded_suit
            if #judge_cards > 0 then  
                -- 获得所有红色判定牌  
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                for _, id in ipairs(judge_cards) do  
                    dummy:addSubcard(id)  
                end  
                room:obtainCard(player, dummy, false)  
                dummy:deleteLater()  
            end  
            player:skip(sgs.Player_Draw)
            --local count = data:toInt()
            --data:setValue(0)
        end
        return false
    end
}


-- 添加触发技能
yuwenhuaji:addSkill(cuanni)  
yuwenhuaji:addSkill(jiandi)  
yuwenhuaji:addSkill(cuanquan)
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["yuwenhuaji"] = "宇文化及",  
    ["cuanni"] = "篡逆",  
    [":cuanni"] = "你造成的伤害可以视为体力流失。",
    ["jiandi"] = "僭帝",  
    [":jiandi"] = "摸牌阶段，你可以改为失去一点体力，弃置一张牌，获得所有角色各一张牌。【僭帝】和【篡权】只能发动一个。",  
    ["cuanquan"] = "篡权",
    [":cuanquan"] = "准备阶段，你可以弃置一张手牌，你可以选择并发起判定，直到满足以下条件：（1）判定牌和弃置的该牌颜色相同，你获得所有判定牌。（2）判定牌和弃置的该牌花色相同，你获得所有判定牌，然后跳过摸牌阶段。【僭帝】和【篡权】只能发动一个。",
    ["@cuanquan-discard"] = "篡权：请弃置一张手牌",
    ["$cuanquan1"] = "天下大乱，正是我等崛起之时！",
    ["$cuanquan2"] = "君王无道，理当另立新主！",
    ["~yuwenhuaji"] = "篡逆之心，终遭天谴……"    
}  

yuxuanji = sgs.General(extension, "yuxuanji", "wei", 3, false)  --wei,jin
-- 折柳技能实现 - 准备阶段和结束阶段的体力变化  
zheliu = sgs.CreateTriggerSkill{  
    name = "zheliu",  
    events = {sgs.EventPhaseStart},  
    --frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            -- 在准备阶段和结束阶段触发  
            if player:getPhase() == sgs.Player_Start then  
                return self:objectName()  
            elseif player:getPhase() == sgs.Player_Finish and player:hasFlag("zheliu") then
                return self:objectName()
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Start then                                   -- 准备阶段询问  
            return player:askForSkillInvoke(self:objectName(),data)  
        elseif player:getPhase() == sgs.Player_Finish and player:hasFlag("zheliu") then -- 若准备阶段发动，结束阶段不询问
            return true
        end  
        return false
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
          
        local others = room:getOtherPlayers(player)  
          
        if player:getPhase() == sgs.Player_Start then 
            room:setPlayerFlag(player,"zheliu") 
            -- 准备阶段，所有其他角色失去一点体力  
            for _, other in sgs.qlist(others) do  
                if other:isAlive() then  
                    room:loseHp(other, 1)  
                end  
            end  
              
            local log = sgs.LogMessage()  
            log.type = "#ZheliuStart"  
            log.from = player  
            log.arg = self:objectName()  
            room:sendLog(log)  
        else  
            -- 结束阶段，所有其他角色恢复一点体力  
            for _, other in sgs.qlist(others) do  
                if other:isAlive() and other:isWounded() then  
                    local recover = sgs.RecoverStruct()  
                    recover.who = player  
                    recover.recover = 1  
                    room:recover(other, recover)  
                end  
            end  
              
            local log = sgs.LogMessage()  
            log.type = "#ZheliuFinish"  
            log.from = player  
            log.arg = self:objectName()  
            room:sendLog(log)  
        end  
          
        return false  
    end  
}  
  
FeiqingCard = sgs.CreateSkillCard{  
    name = "FeiqingCard",  
    target_fixed = false,  
    will_throw = true,  
    handling_method = sgs.Card_MethodNone,  
      
    filter = function(self, targets, to_select)  
        -- 只能选择一名男性角色  
        return #targets == 0 and to_select:hasShownOneGeneral() and to_select:isMale() and to_select:isWounded() and to_select ~= sgs.Self  
    end,  
      
    on_effect = function(self, effect)  
        local room = effect.from:getRoom()  
        local target = effect.to  
          
        -- 目标角色恢复一点体力  
        if target:isWounded() then  
            local recover = sgs.RecoverStruct()  
            recover.who = effect.from  
            recover.recover = 1  
            room:recover(target, recover)  
        end  
          
        -- 选择效果  
        local choices = {}  
        if target:getHandcardNum() > 0 then  
            table.insert(choices, "get_card")  
        end  
        table.insert(choices, "draw_cards")  
          
        if #choices == 0 then  
            return  
        end  
          
        local choice = "draw_cards"  
        if #choices > 1 then  
            choice = room:askForChoice(effect.from, "feiqing", table.concat(choices, "+"))  
        end  
          
        if choice == "get_card" then  
            -- 获得其1张手牌  
            local card_id = room:askForCardChosen(effect.from, target, "h", "feiqing")  
            room:obtainCard(effect.from, card_id, false)  
        else  
            -- 你与其各摸1张牌  
            local drawers = sgs.SPlayerList()  
            drawers:append(effect.from)  
            drawers:append(target)  
            room:drawCards(drawers, 1, "feiqing")  
        end  
    end  
}  
  
-- 飞卿视为技能实现  
feiqing = sgs.CreateZeroCardViewAsSkill{  
    name = "feiqing",  
      
    view_as = function(self)  
        local card = FeiqingCard:clone()  
        card:setShowSkill("feiqing")  
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#FeiqingCard")  
    end  
}  

yuxuanji:addSkill(zheliu)  
yuxuanji:addSkill(feiqing)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["yuxuanji"] = "鱼玄机",  
    ["zheliu"] = "折柳",  
    [":zheliu"] = "准备阶段，你可以所有其他角色失去1点体力；若如此做，结束阶段，所有其他角色恢复1点体力。",  
    ["feiqing"] = "飞卿",  
    [":feiqing"] = "出牌阶段限一次，你可以令一名男性角色恢复1点体力，然后你选择：1.获得其1张手牌；2.你与其各摸1张牌。",  
    ["@feiqing"] = "飞卿",  
    ["@feiqing-target"] = "飞卿：选择一名男性角色",  
    ["get_card"] = "获得其1张手牌",  
    ["draw_cards"] = "你与其各摸1张牌",  
    ["#ZheliuStart"] = "%from 的【%arg】被触发，所有其他角色失去1点体力",  
    ["#ZheliuFinish"] = "%from 的【%arg】被触发，所有其他角色恢复1点体力"  
}

zhangliao_hero = sgs.General(extension, "zhangliao_hero", "wei", 3)  

lianxi = sgs.CreateTriggerSkill{  
    name = "lianxi",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() ~= sgs.Player_NotActive then  
            local use = data:toCardUse()  
            -- 只对基本牌和锦囊牌生效  
            if use.card and (use.card:getTypeId() == sgs.Card_TypeBasic or use.card:getTypeId() == sgs.Card_TypeTrick) and use.card:getSkillName()~=self:objectName() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
          
        -- 发起判定  
        local judge = sgs.JudgeStruct()  
        judge.pattern = ".|red" -- 判定牌点数小于7。第一个点表示任意花色，第二个点表示任意类型
        judge.good = true -- 判定成功对玩家有利  
        judge.reason = self:objectName()  
        judge.who = player  
          
        room:judge(judge)  
          
        if judge.card:isRed() then  
            -- 红色：此牌结算2次  
            -- 在CardFinished后再次使用此牌  
            local extra_use = sgs.CardUseStruct()  
            extra_use.card = use.card  --设置标记避免再次触发
            extra_use.card:setSkillName(self:objectName())
            extra_use.from = use.from  
            extra_use.to = use.to  
            room:useCard(extra_use, false)
        else  
            -- 黑色：此牌无效  
            return true
        end  
          
        return false  
    end  
}  
liaodiCard = sgs.CreateSkillCard{  
    name = "liaodiCard",  
    target_fixed = true,  
    will_throw = true,  
          
    on_use = function(self, room, source, targets)  
        local card_ids = self:getSubcards()
        room:askForGuanxing(source, card_ids, sgs.Room_GuanxingUpOnly)
        room:setPlayerMark(source, "@liaodi",card_ids:length())
    end
}
liaodiVS = sgs.CreateViewAsSkill{  
    name = "liaodi",  
    filter_pattern = "h",  
    view_filter = function(self, selected, to_select)  
        return true  
    end,  
    view_as = function(self, cards)  
        local liaodi_card = liaodiCard:clone()  
        for _, c in ipairs(cards) do  
            liaodi_card:addSubcard(c)  
        end  
        liaodi_card:setSkillName(self:objectName())  
        liaodi_card:setShowSkill(self:objectName())  
        return liaodi_card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#liaodiCard")  
    end  
}  
liaodi = sgs.CreateTriggerSkill{  
    name = "liaodi",  
    events = {sgs.DamageInflicted},  
    view_as_skill = liaodiVS,
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
        
        -- 检查是否为红色牌造成的伤害  
        if player:getMark("@liaodi")>0 then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 锁定技，无需询问  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:setPlayerMark(player,"@liaodi",player:getMark("@liaodi")-1)
        local damage = data:toDamage()  
        damage.damage = damage.damage - 1
        data:setValue(damage)
        -- 如果伤害减为0，则防止伤害  
        if damage.damage <= 0 then  
            return true  
        end  
        return false  
    end  
}  
zhangliao_hero:addSkill(lianxi)
zhangliao_hero:addSkill(liaodi)
sgs.LoadTranslationTable{
    ["zhangliao_hero"] = "张辽",
    ["lianxi"] = "连袭",
    [":lianxi"] = "你使用牌时，可以发起一次判定。若判定牌为红色，该牌结算2次；若判定牌为黑色，该牌无效",
    ["liaodi"] = "料敌",
    [":liaodi"] = "出牌阶段限一次。你可以将X张手牌以任意顺序置于牌堆顶，然后获得X个“料”标记。你受到伤害时，你可以移除一个“料”标记，令此伤害-1",
}

-- 创建武将：
zhangsanfeng = sgs.General(extension, "zhangsanfeng", "shu", 4)  -- 吴国，4血，男性  

-- 创建太极触发技能  
Taiji = sgs.CreateTriggerSkill{  
    name = "taiji",  
    events = {sgs.CardResponded, sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,      
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if player:getPhase() ~= sgs.Player_NotActive then  --非回合外，不发动
            return false  
        end  
        local card = nil  
        if event == sgs.CardResponded then  
            card = data:toCardResponse().m_card  
        else  
            card = data:toCardUse().card  
        end  

        if card:isKindOf("Jink") then  
            -- 检查玩家是否有杀可以使用  
            if player:isKongcheng() or not player:canSlash(false) then  
                return ""  
            end  
              
            -- 检查是否有合法目标  
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if player:canSlash(p, nil, false) then  
                    targets:append(p)  
                end  
            end  
              
            if targets:isEmpty() then  
                return ""  
            end  
              
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName())
    end,  
      
    on_effect = function(self, event, room, player, data)  
        --local prompt = "@taiji-slash"  
        --return room:askForUseCard(player, "slash", prompt, -1, sgs.Card_MethodUse, false)  
        -- 由于使用杀的逻辑已经在on_cost中完成，这里不需要额外处理  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if player:inMyAttackRange(p) then
                targets:append(p)  
            end
        end  
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "taiji", true)  
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
        slash:setSkillName("taiji")  
        local use = sgs.CardUseStruct()  
        use.card = slash  
        use.from = player  
        use.to:append(target)  
        room:useCard(use) 
        slash:deleteLater()
        return false  
    end,  
}

zhangsanfeng:addSkill(Taiji)
zhangsanfeng:addSkill("yingzi_zhouyu")
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["zhangsanfeng"] = "张三丰",
    ["#zhangsanfeng"] = "太极真人",
    ["taiji"] = "太极",  
    [":taiji"] = "回合外，每当你使用或打出【闪】时，你可以视为对攻击范围内的一名角色使用一张【杀】。",  
    ["@taiji-slash"] = "你可以对攻击范围内的一名角色使用一张【杀】",  
}

zhangsunhuanghou = sgs.General(extension, "zhangsunhuanghou", "wu", 3, false)  
  
-- 技能1：恩泽  
xianzhuCard = sgs.CreateSkillCard{  
    name = "xianzhuCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0  
    end,  
    on_effect = function(self, effect)  
        local room = effect.to:getRoom()  
        local source = effect.from  
        local target = effect.to  
          
        local equip_ids = {}  
        local drawpile = room:getDrawPile()  
        for _, id in sgs.qlist(drawpile) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:isKindOf("EquipCard") then  
                table.insert(equip_ids, id)  
            end  
        end  
          
        if #equip_ids > 0 then  
            local chosen_id = equip_ids[math.random(1, #equip_ids)]  
            room:obtainCard(target, chosen_id, false)  
            local card = target:getHandcards():last() --最后一张手牌
            if card:isKindOf("EquipCard") then  
                -- 移除展示的牌  
                -- 使用装备牌  
                room:useCard(sgs.CardUseStruct(card, target, target), false)    
            end  
        end  
          
        room:drawCards(target, 1, "xianzhu")  
    end  
}  
  
xianzhu = sgs.CreateOneCardViewAsSkill{  
    name = "xianzhu",  
    filter_pattern = ".|.|.|hand",  
    view_as = function(self, card)  
        local skill_card = xianzhuCard:clone()  
        skill_card:addSubcard(card)  
        skill_card:setSkillName(self:objectName())  
        return skill_card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#xianzhuCard") and not player:isKongcheng()  
    end  
}  
jiandie = sgs.CreateTriggerSkill{  
    name = "jiandie",  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
        if player:getPhase() == sgs.Player_Finish then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@jiandie", true)  
        if target then  
            local _data = sgs.QVariant()  
            _data:setValue(target)  
            player:setTag("jiandie_target", _data)  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local target = player:getTag("jiandie_target"):toPlayer()  
        player:removeTag("jiandie_target")  
          
        -- 交换手牌  
        local source_handcards = player:handCards()  
        local target_handcards = target:handCards()  
        if source_handcards:isEmpty() and target_handcards:isEmpty() then  
            return false
        end  
        if not source_handcards:isEmpty() or not target_handcards:isEmpty() then  
            local move1 = sgs.CardsMoveStruct()  
            move1.card_ids = source_handcards  
            move1.from = player
            move1.to = target  
            move1.to_place = sgs.Player_PlaceHand  
            move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                player:objectName(), target:objectName(), "jiandie", "")

            local move2 = sgs.CardsMoveStruct()  
            move2.card_ids = target_handcards  
            move2.from = target
            move2.to = player  
            move2.to_place = sgs.Player_PlaceHand  
            move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                target:objectName(), player:objectName(), "jiandie", "")

            local moves = sgs.CardsMoveList()
            moves:append(move1)
            moves:append(move2)
            
            room:moveCardsAtomic(moves, true)
        end  

        -- 手牌数较少的角色摸牌至相等  
        local new_n1 = player:getHandcardNum()  
        local new_n2 = target:getHandcardNum()  
        
        if new_n1 < new_n2 then  
            room:drawCards(player, new_n2 - new_n1, self:objectName())  
        elseif new_n2 < new_n1 then  
            room:drawCards(target, new_n1 - new_n2, self:objectName())  
        end  
          
        return false  
    end  
}
  
-- 添加技能到武将  
zhangsunhuanghou:addSkill(xianzhu)  
zhangsunhuanghou:addSkill(jiandie)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["zhangsunhuanghou"] = "长孙皇后",  
    ["xianzhu"] = "贤助",  
    [":xianzhu"] = "出牌阶段限一次，你可以弃置一张手牌，令一名角色获得牌堆中的一张装备，并摸一张牌。",  
    ["jiandie"] = "鹣鲽",  
    [":jiandie"] = "结束阶段，你可与一名角色交换手牌，然后手牌数较少的角色摸至和手牌数较多的角色相等。",  
    ["@jiandie-target"] = "鹣鲽：选择一名角色交换手牌"  
}  
  
zhaokuo = sgs.General(extension, "zhaokuo", "qun", 4)  -- 吴国，4血，男性  

zhishangtanbing = sgs.CreateTriggerSkill{  
    name = "zhishangtanbing",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() then   
            return ""   
        end  
        owner = room:findPlayerBySkillName(self:objectName())
        return self:objectName(), owner:objectName()
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        local to = damage.to  
        if to==ask_who then
            if not owner:hasFlag("zhishangtanbing_discard") then
                room:askForDiscard(ask_who, self:objectName(), 1, 1, false, true)
                room:setPlayerFlag(ask_who,"zhishangtanbing_discard")
            end
        else
            if not owner:hasFlag("zhishangtanbing_draw") then
                ask_who:drawCards(1)
                room:setPlayerFlag(ask_who,"zhishangtanbing_draw")
            end
        end
        return false  
    end  
}

zhaokuo:addSkill(zhishangtanbing)

sgs.LoadTranslationTable{
    ["zhaokuo"] = "赵括",
    ["zhishangtanbing"] = "纸上谈兵",  
    [":zhishangtanbing"] = "每回合限一次，当其他角色受到伤害时，你摸一张牌；每回合限一次，当你受到伤害时，你弃置一张牌"
}

zhouchu_hero = sgs.General(extension, "zhouchu_hero", "qun", 4)  
  
-- 技能1：改过  
gaiguo = sgs.CreateTriggerSkill{  
    name = "gaiguo",  
    events = {sgs.Damage, sgs.Damaged},  
    frequency = sgs.SKill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        room:addPlayerMark(player, "@guo", damage.damage)  
        room:broadcastSkillInvoke(self:objectName(), player)  
            
        -- 检查是否为3的倍数  
        local guo_count = player:getMark("@guo")  
        if guo_count > 0 and guo_count % 3 == 0 then  
            room:drawCards(player, 3, self:objectName())  
            room:setPlayerMark(player,"@guo",0)
        end  
        return false  
    end  
}  
  
-- 技能2：除害  
chuhai = sgs.CreateTriggerSkill{  
    name = "chuhai",  
    events = {sgs.DrawNCards},  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        --if player:getPhase() == sgs.Player_Start then  
        return self:objectName()  
        --end  
        --return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        -- 视为使用决斗  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if not player:isFriendWith(p) then
                targets:append(p)  
            end
        end  
            
        if not targets:isEmpty() then  
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@chuhai-target")  
            if target then  
                local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)  
                duel:setSkillName(self:objectName())  
                local use = sgs.CardUseStruct()  
                use.card = duel  
                use.from = player  
                use.to:append(target)  
                room:useCard(use)  
                duel:deleteLater()
            end
            --room:setPlayerFlag(player,"chuhai_used")
            --player:skip(sgs.Player_Draw)
            local count = data:toInt()
            data:setValue(0)
        end
        return false  
    end  
}  
--[[
chuhai_draw = sgs.CreateDrawCardsSkill{  
    name = "chuhai_draw",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        if player:hasFlag("chuhai_used") then
            return 0
        else
            return n
        end
    end  
}  
]]
-- 添加技能到武将  
zhouchu_hero:addSkill(gaiguo)  
zhouchu_hero:addSkill(chuhai)  
--zhouchu_hero:addSkill(chuhai_draw)  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄传",  
    ["zhouchu_hero"] = "周处",  
    ["#zhouchu_hero"] = "改过除害",  
      
    ["gaiguo"] = "改过",  
    [":gaiguo"] = "你造成或受到1点伤害时，获得1个'过'标记。你的'过'标记为3的倍数时，摸三张牌。",  
      
    ["chuhai"] = "除害",   
    [":chuhai"] = "摸牌阶段，你可以改为视为对一名其他势力角色使用1张【决斗】。",  
    ["@chuhai-target"] = "除害：选择【决斗】的目标",  
}  
  

-- 创建武将：
zhuowenjun = sgs.General(extension, "zhuowenjun", "qun", 3, false)  -- 吴国，4血，男性  

qinxin = sgs.CreateZeroCardViewAsSkill{  
    name = "qinxin",          
    view_as = function(self)  
        local card = qinxin_card:clone()  
        card:setSkillName("qinxin")  
        return card  
    end,  
        
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#qinxin_card")  
    end  
}   
-- 窥心卡牌类  
qinxin_card = sgs.CreateSkillCard{  
    name = "qinxin_card",  
    target_fixed = false,  
    will_throw = false,  
      
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
               and not to_select:isKongcheng()  
    end,  
      
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local handcards = target:getHandcards()  
        if handcards:isEmpty() then return end  
          
        local card_id = room:askForCardChosen(source, target, "h", "qinxin")  
        local card = sgs.Sanguosha:getCard(card_id)  
          
        room:showCard(target, card_id)  
          
        if card:isRed() then  
            -- 红色牌，获得该牌  
            room:obtainCard(source, card_id, false)  
        else  
            -- 黑色牌，造成1点伤害  
            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = target  
            damage.damage = 1  
            room:damage(damage)  
        end  
    end  
}  


xiangshou = sgs.CreateTriggerSkill{  
    name = "xiangshou",  
    events = {sgs.HpRecover},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        local recover = data:toRecover()  
        --local source = player--recover.to  --恢复体力的角色source就是player
          
        -- 其他角色恢复体力时触发  
        owner = room:findPlayerBySkillName(self:objectName())
        if player and player:objectName() ~= owner:objectName() and not owner:isKongcheng() then  
            return self:objectName(), owner:objectName() 
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local recover = data:toRecover()  
        --local card_id = room:askForCardChosen(ask_who, ask_who, "h", "xiangshou")  
        --local card = sgs.Sanguosha:getCard(card_id)            
        local card = room:askForCard(ask_who, ".|.|.|hand", self:objectName()) 
        if not card then return false end 
        -- 交给目标角色  
        room:obtainCard(player, card, false)  
          
        -- 如果是红色牌，自己回复1点体力  
        if card:isRed() then  
            local self_recover = sgs.RecoverStruct()  
            self_recover.who = ask_who  
            self_recover.recover = 1  
            room:recover(ask_who, self_recover)  
        end            
    end  
}

zhuowenjun:addSkill(qinxin)
zhuowenjun:addSkill(xiangshou)
sgs.LoadTranslationTable{
    ["hero"] = "英雄",  
    ["zhuowenjun"] = "卓文君",  
    ["qinxin"] = "琴心",  
    [":qinxin"] = "出牌阶段限一次，你可以查看一名角色一张手牌，若该牌为红色，你获得该牌；若该牌为黑色，你对该角色造成1点伤害。",  
    ["xiangshou"] = "相守",   
    [":xiangshou"] = "任意一名其他角色恢复体力时，你可以交给他一张手牌，若该牌为红色，你回复1点体力。",  
    ["@xiangshou-give"] = "你可以交给 %src 一张手牌发动'慰心'"  
}

zhuangzhou = sgs.General(extension, "zhuangzhou", "qun", 3) --qun,jin  

mengdie = sgs.CreateTriggerSkill{  
    name = "mengdie",  
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return "" end  
        return self:objectName()
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        elseif event == sgs.CardResponded then  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        -- 检查是否为'蝶'牌  
        local is_butterfly = card:hasFlag("butterfly_card")        -- 检查是否为'蝶'牌  
          
        if is_butterfly then  
            -- 使用'蝶'牌时，弃置所有'蝶'牌  
            for _, card_id in sgs.qlist(player:handCards()) do  
                local hand_card = sgs.Sanguosha:getCard(card_id)  
                if hand_card:hasFlag("butterfly_card") then  
                    room:throwCard(hand_card,player,player)  
                end  
            end  
        else  
            -- 使用非'蝶'牌时，摸一张牌并标记为'蝶'牌  
            player:drawCards(1, self:objectName())  
              
            -- 标记最后摸到的牌为'蝶'牌  
            local last_card_id = player:handCards():last()  
            local last_card = sgs.Sanguosha:getCard(last_card_id)  
            last_card:setFlags("butterfly_card")  
        end  
          
        return false  
    end  
}

xiaoyaoMaxCards = sgs.CreateMaxCardsSkill{  
    name = "xiaoyao_maxCards",  
    extra_func = function(self, player)
        if not player:hasShownSkill("xiaoyao_maxCards") then
            return 0
        end
        local handcards = player:getHandcards()  
        local count = 0  
          
        -- 计算点数大于等于10的手牌数量
        -- 满足条件的卡不计入卡牌上限，即每有一张满足条件的卡，卡牌上限加1
        for _, card in sgs.qlist(handcards) do  
            if card:hasFlag("butterfly_card") then  
                count = count + 1  
            end  
        end  
          
        return count  
    end  
}  
xiaoyaoTargetMod = sgs.CreateTargetModSkill{  
    name = "xiaoyao_targetmod",  
    distance_limit_func = function(self, player, card)  
        if not player:hasSkill("xiaoyao_targetmod") then
            return 0
        end
        local handcards = player:getHandcards()  
        local count = 0  
          
        -- 计算点数大于等于10的手牌数量
        -- 满足条件的卡不计入卡牌上限，即每有一张满足条件的卡，卡牌上限加1
        for _, card in sgs.qlist(handcards) do  
            if card:hasFlag("butterfly_card") then  
                count = count + 1  
            end  
        end  
        -- 当'蝶'牌数≥3时，无距离限制  
        if count >= 3 then  
            return 1000  
        end  
        return 0  
    end,  
    residue_func = function(self, player, card)  
        if not player:hasSkill("xiaoyao_targetmod") then
            return 0
        end
        local handcards = player:getHandcards()  
        local count = 0  
          
        -- 计算点数大于等于10的手牌数量
        -- 满足条件的卡不计入卡牌上限，即每有一张满足条件的卡，卡牌上限加1
        for _, card in sgs.qlist(handcards) do  
            if card:hasFlag("butterfly_card") then  
                count = count + 1  
            end  
        end  
        -- 当'蝶'牌数≥3时，无距离限制  
        if count >= 3 then  
            return 1000  
        end  
        return 0  
    end  
}
xiaoyaoTurned = sgs.CreateTriggerSkill{  
    name = "xiaoyaoTurned",  
    events = {sgs.CardEffected, sgs.TurnedOver},  
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
-- 组合技能  
zhuangzhou:addSkill(mengdie)
zhuangzhou:addSkill(xiaoyaoMaxCards)
zhuangzhou:addSkill(xiaoyaoTargetMod)
zhuangzhou:addSkill(xiaoyaoTurned)
sgs.LoadTranslationTable{
["#zhuangzhou"] = "逍遥游者",  
["zhuangzhou"] = "庄周",  
["illustrator:zhuangzhou"] = "画师名",  
["mengdie"] = "梦蝶",  
[":mengdie"] = "当你使用或打出1张非'蝶'牌时，你摸一张牌并标记为'蝶'牌；当你使用或打出'蝶'牌时，你弃置所有'蝶'牌。",
["xiaoyao"] = "逍遥-蝶",  
[":xiaoyao"] = "锁定技，你的'蝶'牌不计入手牌上限；若你的'蝶'牌数大于等于3，你使用牌无距离和次数限制；",
["xiaoyaoTurned"] = "逍遥",  
[":xiaoyaoTurned"] = "锁定技，当延时性锦囊生效时，取消之；当你被叠置时，你平置。"
}
zhubajie = sgs.General(extension, "zhubajie", "wu", 3) --wu,jin  

tianpeng = sgs.CreateTriggerSkill{  
    name = "tianpeng",  
    events = {sgs.CardUsed, sgs.CardResponded},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local source = room:findPlayerBySkillName(self:objectName())  
        if not (source and source:isAlive() and source:hasSkill(self:objectName())) then  
            return ""  
        end  
          
        -- 检查是否在自己回合外  
        if source:getPhase() ~= sgs.Player_NotActive then  
            return ""  
        end  
          
        -- 检查是否是其他角色  
        if player:objectName() == source:objectName() then  
            return ""  
        end  
          
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        -- 检查是否是杀  
        if card and card:isKindOf("Slash") then  
            return self:objectName(), source:objectName()
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        --local source = room:findPlayerBySkillName(self:objectName())  
        if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:notifySkillInvoked(ask_who, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        --local source = room:findPlayerBySkillName(self:objectName())  
        ask_who:drawCards(1, self:objectName())  
        return false  
    end  
}

zhubajie:addSkill(tianpeng)
sgs.LoadTranslationTable{
    ["zhubajie"] = "猪八戒",  
    ["#zhubajie"] = "天蓬元帅",  
    ["tianpeng"] = "天蓬",  
    [":tianpeng"] = "你的回合外，其他角色使用或打出【杀】时，你摸一张牌。",  
}  
-- 创建武将：朱元璋
zhuyuanzhang = sgs.General(extension, "zhuyuanzhang", "wu", 4)  -- 群雄，3血  


-- 技能1：强运 - 你失去最后一张手牌时，你摸一张牌  
qiangyun = sgs.CreateTriggerSkill{  
    name = "qiangyun",  
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime, sgs.CardResponded, sgs.CardUsed},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then
            return false  
        end  
        --我的实现。手牌数也可以用player:getHandcardNum(), player:isKongcheng(), player:handCards():length()
        if player:getHandcardNum() == 0 then
            return self:objectName() --必须返回技能名
        end
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
        room:sendCompulsoryTriggerLog(player, self:objectName())  
        -- 摸一张牌  
        player:drawCards(2)  
    end  
}  

-- 添加技能给武将  
zhuyuanzhang:addSkill(qiangyun)  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["zhuyuanzhang"] = "朱元璋",  
    ["#zhuyuanzhang"] = "明太祖",

    ["qiangyun"] = "强运",  
    [":qiangyun"] = "锁定技，每当你使用、打出、失去最后一张手牌时，你摸2张牌",  
      
    ["~zhuyuanzhang"] = "国运，完了"  
}  

zhuzhishan = sgs.General(extension, "zhuzhishan", "wu", 3)  --wu, wei

caoshu = sgs.CreateTriggerSkill{  
    name = "caoshu",  
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then --准备阶段开始时，标记清0
                room:setPlayerMark(player, "caoshu_count", 0)
                return ""
            end
            if player:getPhase() == sgs.Player_Play then  
                local card = nil  
                if event == sgs.CardUsed then  
                    local use = data:toCardUse()  
                    card = use.card  
                elseif event == sgs.CardResponded then  
                    local response = data:toCardResponse()  
                    card = response.m_card  
                end  
                  
                if card and card:isBlack() then  
                    -- 检查手牌区  
                    return self:objectName()  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，自动触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        local count = player:getMark("caoshu_count") + 1  
        room:setPlayerMark(player, "caoshu_count", count)  
          
        if count >= 2 then  
            room:setPlayerMark(player, "caoshu_count", 0)  
            player:drawCards(1, self:objectName())  
            room:broadcastSkillInvoke(self:objectName())  
        end  
        return false  
    end  
}

linmo = sgs.CreateTriggerSkill{  
    name = "linmo",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:getPhase() == sgs.Player_Play then  
            -- 寻找拥有此技能的角色  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if p:hasSkill(self:objectName()) and p:isAlive() then  
                    if not player:isKongcheng() then  
                        return self:objectName(), p:objectName()
                    end  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local _data = sgs.QVariant()  
        _data:setValue(player)  
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        -- 展示一张手牌  
        local card_id = room:askForCardChosen(ask_who, player, "h", self:objectName())  
        room:showCard(player, card_id)  
          
        local card = sgs.Sanguosha:getCard(card_id)  
        if card:isBlack() then  
            -- 获得该牌  
            room:obtainCard(ask_who, card_id, false)  
        else
            if not ask_who:isNude() then
                room:askForDiscard(ask_who, self:objectName(), 1, 1, false, true)
            end
        end  
        return false  
    end  
}

zhuzhishan:addSkill(caoshu)  
zhuzhishan:addSkill(linmo)

sgs.LoadTranslationTable{
    ["#zhuzhishan"] = "江南第一风流才子",  
    ["zhuzhishan"] = "祝枝山",  
    ["illustrator:zhuzhishan"] = "未知",  
    ["caoshu"] = "草书",  
    [":caoshu"] = "出牌阶段，你每使用或打出2张黑色手牌，你摸1张牌。",  
    ["linmo"] = "临摹",  
    [":linmo"] = "其他角色出牌阶段开始时，你可以展示其1张手牌：若该牌为黑色，你获得之；若该牌为红色，你需要弃置1张牌（无牌则不弃）",  
}

zuchongzhi = sgs.General(extension, "zuchongzhi", "wei", 3)  --wei,jin

YuanzhouCard = sgs.CreateSkillCard{  
    name = "YuanzhouCard",  
    target_fixed = true,  
    will_throw = true,  
    on_use = function(self, room, source, targets)  
        local players = room:getAlivePlayers()  
        local count = players:length()  
        if count < 2 then return end  
          
        -- 记录每个玩家给出和收到的牌的点数  
        local given_points = {}  
        local received_points = {}  
        local cards_to_move = {}  
          
        -- 从技能发动者开始，按行动顺序排列  
        local ordered_players = sgs.SPlayerList()  
        local start_index = -1  
        for i = 0, count - 1 do  
            local p = players:at(i)  
            if p:objectName() == source:objectName() then  
                start_index = i  
                break  
            end  
        end  
          
        -- 重新排列玩家顺序  
        for i = 0, count - 1 do  
            local index = (start_index + i) % count  
            ordered_players:append(players:at(index))  
        end  
          
        -- 第一阶段：所有玩家选择要给出的牌  
        for i = 0, count - 1 do  
            local current = ordered_players:at(i)  
            local next_player = ordered_players:at((i + 1) % count)  
              
            if current:isAlive() and not current:isKongcheng() then  
                local card_id = room:askForCardChosen(current, current, "h", "yuanzhou")  
                local card = sgs.Sanguosha:getCard(card_id)  
                given_points[current:objectName()] = card:getNumber()  
                received_points[next_player:objectName()] = card:getNumber()  
                  
                -- 记录卡牌移动信息  
                table.insert(cards_to_move, {  
                    card_id = card_id,  
                    from = current,  
                    to = next_player  
                })  
            else  
                given_points[current:objectName()] = 0  
                received_points[ordered_players:at((i + 1) % count):objectName()] = 0  
            end  
        end  
          
        -- 第二阶段：执行卡牌移动  
        for _, move_info in ipairs(cards_to_move) do  
            room:obtainCard(move_info.to, move_info.card_id,  false)  
        end  
          
        -- 第三阶段：判断体力损失  
        for i = 0, count - 1 do  
            local current = ordered_players:at(i)  
            local current_name = current:objectName()  
              
            if current:isAlive() and given_points[current_name] and received_points[current_name] then  
                --if given_points[current_name] > 0 and received_points[current_name] > 0 then  
                    if given_points[current_name] < received_points[current_name] then  
                        room:loseHp(current, 1)  
                    end  
                --end  
            end  
        end  
    end,  
}  
  
-- 圆周视为技  
Yuanzhou = sgs.CreateZeroCardViewAsSkill{  
    name = "yuanzhou",  
    view_as = function(self)  
        local card = YuanzhouCard:clone()  
        card:setSkillName(self:objectName())  
        card:setShowSkill(self:objectName())  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#YuanzhouCard")  
    end,  
}  


Jingsuan = sgs.CreateTriggerSkill{  
    name = "jingsuan",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
        local damage = data:toDamage()
        if not player:hasFlag("jingsuan_damage") and damage.damage==1 then --第一次受到伤害，且伤害值为1，直接加标记，避免触发技能
            room:setPlayerFlag(player, "jingsuan_damage")  
        else --不是第一次受到伤害；或者第一次受到伤害值大于1
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data) -- 锁定技，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()            
        -- 如果本回合已经受到1点伤害，则防止所有后续伤害  
        if player:hasFlag("jingsuan_damage") then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            room:sendCompulsoryTriggerLog(player, self:objectName())  
              
            local log = sgs.LogMessage()  
            log.type = "#JingsuanProtect"  
            log.from = player  
            log.arg = tostring(damage.damage)  
            room:sendLog(log)  
              
            return true -- 防止伤害  
        else  
            -- 如果本回合未受到伤害，限制为1点  
            if damage.damage > 1 then  
                room:broadcastSkillInvoke(self:objectName(), player)  
                room:sendCompulsoryTriggerLog(player, self:objectName())  
                  
                local log = sgs.LogMessage()  
                log.type = "#JingsuanReduce"  
                log.from = player  
                log.arg = tostring(damage.damage)  
                log.arg2 = "1"  
                room:sendLog(log)  
                  
                damage.damage = 1  
                data = sgs.QVariant()  
                data:setValue(damage)  
            end  
              
            -- 记录本回合受到伤害  
            room:setPlayerFlag(player, "jingsuan_damage")  
        end  
          
        return false  
    end,  
}  
zuchongzhi:addSkill(Yuanzhou)
zuchongzhi:addSkill(Jingsuan)
sgs.LoadTranslationTable{
    ["zuchongzhi"] = "祖冲之",
    ["yuanzhou"] = "圆周",
    [":yuanzhou"] = "出牌阶段限一次。所有角色选择一张手牌交给下一名角色，并记录该牌点数，若没有手牌或给出牌的点数小于收到牌的点数，则失去一点体力",
    ["jingsuan"] = "精算",
    [":jingsuan"] = "锁定技。你一回合最多受到1点伤害"
}

zudi = sgs.General(extension, "zudi", "qun", 3) --击揖，和沮授接近；置酒，吕雉需要酒
jiyi = sgs.CreateTriggerSkill{  
    name = "jiyi",  
    events = {sgs.DamageCaused, sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,    
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end  
        return self:objectName() 
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        damage = data:toDamage()
        if event == sgs.DamageCaused and damage.from:hasSkill(self:objectName()) then --伤害源是自己
            player = damage.from
            if player:getMark("damage_add") == 0 then --没有加伤标记
                damage.damage = damage.damage - 1 --伤害-1
                room:setPlayerMark(player,"damage_add",1) --下次伤害+1
            else --有加伤标记
                damage.damage = damage.damage + 1 --伤害+1
                room:setPlayerMark(player,"damage_add",0) --下次伤害-1
            end
        elseif event == sgs.DamageInflicted and damage.to:hasSkill(self:objectName()) then --伤害目标是自己
            player = damage.to
            if player:getMark("damaged_add") == 0 then --没有加伤标记
                damage.damage = damage.damage - 1 --伤害-1
                room:setPlayerMark(player,"damaged_add",1) --下次伤害+1
            else --有加伤标记
                damage.damage = damage.damage + 1 --伤害+1
                room:setPlayerMark(player,"damaged_add",0) --下次伤害-1
            end
        end
        data:setValue(damage)
        if damage.damage <= 0 then
            return true
        end
        return false  
    end  
}  


fuji = sgs.CreateTriggerSkill{  
    name = "fuji",  
    events = {sgs.Damage, sgs.Damaged},  
    frequency = sgs.Skill_Frequent,    
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then  
            return ""  
        end
        local damage = data:toDamage()
        if damage.from:hasFlag("fuji_used") or damage.to:hasFlag("fuji_used") then return "" end
        return self:objectName() 
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()
        if damage.damage > 0  then
            if damage.from:hasSkill(self:objectName()) and not damage.from:hasFlag("fuji_used") then
                damage.from:drawCards(damage.damage, self:objectName())
                room:setPlayerFlag(damage.from, "fuji_used")
            elseif damage.to:hasSkill(self:objectName()) and not damage.to:hasFlag("fuji_used") then
                damage.to:drawCards(damage.damage, self:objectName())
                room:setPlayerFlag(damage.to, "fuji_used")
            end
        end
        return false  
    end  
}  


zhijiu = sgs.CreateOneCardViewAsSkill{  
    name = "zhijiu",  
    filter_pattern = "Slash|.|.|.",  
    view_as = function(self, card)  
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())  
        analeptic:addSubcard(card:getId())  
        analeptic:setSkillName(self:objectName())  --设置转化牌的技能名
        analeptic:setShowSkill(self:objectName())  --使用时亮将
        return analeptic  
    end,
    enabled_at_play = function(self, player)   
        return sgs.Analeptic_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)   
        return string.find(pattern,"analeptic")
    end,
}  
zudi:addSkill(jiyi)
zudi:addSkill(fuji)
zudi:addSkill(zhijiu)
sgs.LoadTranslationTable{
    ["zudi"] = "祖狄",
    ["jiyi"] = "击揖",
    [":jiyi"] = "锁定技。你造成/受到的伤害-1，然后你下次造成/受到的伤害+1",
    ["fuji"] = "复济",
    [":fuji"] = "每回合限一次。你造成或受到伤害后，你摸X张牌，X为伤害值",
    ["zhijiu"] = "置酒",
    [":zhijiu"] = "你的杀可以视为酒",
}

--添加珠联璧合
--人物关系联动
lvzhi:addCompanion("lvbuwei")
change:addCompanion("houyi")
direnjie:addCompanion("wuzetian")
guiguzi:addCompanion("suqin")
huoqubing:addCompanion("weizifu")
--诸子百家
kongzi:addCompanion("mozi")
kongzi:addCompanion("xunzi")
kongzi:addCompanion("zhuangzhou")
mozi:addCompanion("xunzi")
mozi:addCompanion("zhuangzhou")
xiangyu:addCompanion("yuji")
xunzi:addCompanion("zhuangzhou")
zhubajie:addCompanion("change")
zhubajie:addCompanion("xuanzang")
--技能联动
--bole:addCompanion("guiguzi")
--判定系
dongfangshuo:addCompanion("simaxiangru")
dongfangshuo:addCompanion("shangguanwaner")
--回合外出牌系
goujian:addCompanion("liqingzhao")
--屯牌换牌系
goujian:addCompanion("wangzhaojun")
goujian:addCompanion("zhangsunhuanghou")
--拼点系
guanzhong:addCompanion("qihuangong")
guanzhong:addCompanion("shangguanwaner")
guanzhong:addCompanion("wuzetian")
houyi:addCompanion("linchong")
qihuangong:addCompanion("shangguanwaner")
qihuangong:addCompanion("wuzetian")
jiangziya:addCompanion("wangyangming")
simaxiangru:addCompanion("wuzetian")
wangzhaojun:addCompanion("zhangsunhuanghou")
xuxiake:addCompanion("zhangsunhuanghou")
--都联动
daji:addCompanion("shangzhou")
dufu:addCompanion("libai")
fanzeng:addCompanion("xiangyu")
gaojianli:addCompanion("jingke")
liuche:addCompanion("huoqubing")
liuche:addCompanion("weizifu")
moxi:addCompanion("xiajie")
qinqiong:addCompanion("yuchigong")
shangguanwaner:addCompanion("wuzetian")
simaxiangru:addCompanion("zhuowenjun")
--[[
menghuo_hero:addCompanion("menghuo")
menghuo_hero:addCompanion("zhurong")
menghuo_hero:addCompanion("zhurong_hero")
zhurong_hero:addCompanion("menghuo")
zhurong_hero:addCompanion("zhurong")
]]
return {extension}
