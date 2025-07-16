
-- 创建一个武将包  
extension = sgs.Package("hero", sgs.Package_GeneralPack)  

baiqi = sgs.General(extension, "baiqi", "qun", 4)  
  
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
        return true  
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
baosi = sgs.General(extension, "baosi", "qun", 3, false)  -- 群雄，3血  
  
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
baozhen = sgs.General(extension, "baozhen", "wei", 3)  -- 群雄，3血  


-- 技能1： - 血量变化时摸一张牌 
pingyuan = sgs.CreateTriggerSkill{  
    name = "pingyuan",
    frequency = sgs.Skill_Compulsory, --锁定技
    events = {sgs.HpChanged},  --集合，可以有多个触发条件
          
    can_trigger = function(self, event, room, player, data)  
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then  
            return false  
        end 
        return self.objectName()
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
        return #selected == 0 
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = shenduanCard:clone() -- 创建虚拟牌  
            card:setSkillName("shenduan")  
            card:addSubcard(cards[1])  
            return card  
        end  
    end,  
    enabled_at_play = function(self, player)  
        return true -- 出牌阶段可用  
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
            local suits = {"spade", "heart", "club", "diamond"}  
            new_suit = room:askForChoice(player, "shenduan_suit", table.concat(suits, "+"))  
            -- 这里需要创建新的判定牌  
        end  
          
        if choice == "number" or choice == "both" then  
            -- 让玩家选择新点数  
            local numbers = {}  
            for i = 1, 13 do  
                table.insert(numbers, tostring(i))  
            end  
            new_number = room:askForChoice(player, "shenduan_number", table.concat(numbers, "+"))  
            -- 这里需要创建新的判定牌  
        end  
        --local new_card = judge.card
        --new_card:setSuit(new_suit)
        --new_card:setNumber(new_number)
        
        --local new_card = sgs.Sanguosha:cloneCard(judge.card:objectName(), new_suit, new_number)

        -- 执行改判  
        --room:retrial(new_card, player, judge, self:objectName())  
        --judge:updateResult()

        judge.good = not judge.good
        data:setValue(judge)
        return false  
    end  
}

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
    [":shenduan"] = "出牌阶段，你可以弃置一张手牌，获得一个“神断”标记。判定生效前，你可以弃置一个“神断”，改变判定牌的花色或点数",
    ["~shenduan"] = "选择一张牌→点击确定",  
    ["#ShendaunChangeSuit"] = "%from 发动了【神断】，将判定牌的花色从 %arg 改为 %arg2"
}  

-- 创建伯乐武将  
Bole = sgs.General(extension, "bole", "shu", 4)  
-- 创建相马技能卡  
xiangmaCard = sgs.CreateSkillCard{  
    name = "xiangmaCard",  
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
        room:notifySkillInvoked(source, "xiangma")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("xiangma")  
          
        -- 将手牌交给目标角色  
        local move = sgs.CardsMoveStruct()  
        move.card_ids = self:getSubcards()  
        move.to = target  
        move.to_place = sgs.Player_PlaceHand  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "xiangma", "")  
        room:moveCardsAtomic(move, true)  
          
        local victim = room:askForPlayerChosen(source,  room:getOtherPlayers(target), self:objectName())
        -- 询问目标是否对victim使用杀  
        local prompt = string.format("@xiangma-slash:%s:%s:", victim:objectName(), target:objectName())  
        if not room:askForUseSlashTo(target, victim, prompt, false, false, false) then  
            -- 如果目标不使用杀，则弃置其两张牌  
            --[[
            if not target:isNude() then  
                local count = math.min(2, target:getCardCount(true))  
                --room:askForDiscard(target, "xiangma", count, count, false, true)
                
                local dummy_reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, source:objectName(), target:objectName(), "xiangma", "")  
                card_ids = room:askForCardsChosen(source, target, "he", "xiangma", count, count)  
                
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
xiangmaViewAsSkill = sgs.CreateOneCardViewAsSkill{  
    name = "xiangma",  
    filter_pattern = ".",  
      
    view_as = function(self, card)  
        local xc = xiangmaCard:clone()  
        xc:addSubcard(card)  
        xc:setShowSkill(self:objectName())  
        return xc  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#xiangmaCard") and not player:isKongcheng()  
    end  
}  
  
-- 创建相马技能  
xiangma = sgs.CreateTriggerSkill{  
    name = "xiangma",  
    view_as_skill = xiangmaViewAsSkill,  
    events = {},  -- 没有触发事件，纯视为技  
}  
--创建拒马
function sgs.CreatejumaSkill(name) --创建拒马技能，在CreateDistanceSkill函数基础上建立的函数
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
juma = sgs.CreatejumaSkill("juma") 

Bole:addSkill(xiangma)  
Bole:addSkill(juma)  --或者直接使用飞影

-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
      
    ["bole"] = "伯乐",  
    ["#bole"] = "千里马知己",  
    ["xiangma"] = "相马",  
    [":xiangma"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色，令其对你指定的另一名角色使用【杀】，若其不使用【杀】，你弃置其两张牌。",  
    ["xiangmaCard"] = "相马",  
    ["@xiangma-slash"] = "请对 %src 使用一张【杀】，否则 %dest 将弃置你两张牌",  

    ["juma"] = "拒马",  
    [":juma"] = "锁定技，其他角色计算与你的距离+1。",  
}  


-- 创建武将：鬼谷子  
guiguzi = sgs.General(extension, "guiguzi", "qun", 3)  

yinju = sgs.CreateTriggerSkill{  
    name = "yinju",  
    events = {sgs.DamageInflicted},  
      
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
        return true
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

guiguzi:addSkill(yinju)
guiguzi:addSkill(guigu)

-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["guiguzi"] = "鬼谷子",
    ["#guiguzi"] = "纵横家", 
    ["yinju"] = "隐居",  
    [":yinju"] = "锁定技，当你受到伤害时，若伤害源与你的距离大于1，则伤害为0。",  

    ["guigu"] = "鬼谷",  
    [":guigu"] = "出牌阶段限1次。你可以将任意数量的杀给另一名角色，然后摸等量的牌",  
}

change = sgs.General(extension, "change", "qun", 3, false) -- 名字，势力，体力，性别(false=女)  
  
-- 技能1：奔月 - 出牌阶段限一次，将装备牌视为无中生有 
-- 为了限制次数，必须写成技能卡
benyueCard = sgs.CreateSkillCard{  
    name = "benyue",  
    target_fixed = true,  
    on_use = function(self, room, source, targets)  
        -- 无中生有的效果：摸两张牌  
        room:drawCards(source, 2, "benyue")  
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

daji = sgs.General(extension, "daji", "qun", 3, false)  -- 吴国，4血，男性  

meiguo = sgs.CreateProhibitSkill{  --不能指定为目标，不是取消目标
    name = "meiguo",  
    is_prohibited = function(self, from, to, card)  
        if to:hasSkill(self:objectName()) and card:isKindOf("Slash") and card:isBlack() then  
            return true  
        end  
        return false  
    end  
}

shixin = sgs.CreateTriggerSkill{  
    name = "shixin",  
    events = {sgs.EventPhaseEnd},  
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
                if not p:isNude() then  
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
                targets:append(p)  
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
    [":shixin"] = "回合结束时，你可以进行一次判定，若判定牌为黑色，你可以弃置一名角色一张牌；若判定牌为红色，你可以令一名角色从牌堆获得一张红桃牌。",  
    ["@shixin-discard"] = "请选择一名角色，弃置其一张牌",  
    ["@shixin-draw"] = "请选择一名角色，令其从牌堆获得一张红桃牌" 
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
        judge.pattern = "."  
        --judge.pattern = "black" -- 判定牌点数小于7。第一个点表示任意花色，第二个点表示任意类型
        judge.good = true -- 判定成功对玩家有利  
        judge.play_animation = true  
        judge.who = player  
        judge.reason = self:objectName()  
          
        room:judge(judge)  
          
        -- 如果判定牌为黑色，可以获得该判定牌  
        if judge.card:isBlack() then
            target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
            target:obtainCard(judge.card)
        elseif judge.card:isRed() then
            choice = room:askForChoice(player,"cifu","top+discard")
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
    [":cifu"] = "准备阶段，你可以进行一次判定，若判定牌为黑色，你可以令一名角色获得该判定牌；若为红色，你可以选择放在牌堆顶或弃牌堆",  
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
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
           and player:getPhase() == sgs.Player_Start then  
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
dufu:addSkill(shisheng)
sgs.LoadTranslationTable{
    ["dufu"] = "杜甫",  

    ["shisheng"] = "诗圣",  
    [":shisheng"] = "准备阶段，你可以查看牌堆顶4张牌，并以任意顺序排列，然后依次翻开，你获得花色互不相同的所有牌",  
      
}

goujian = sgs.General(extension, "goujian", "wu", 3)  --wu.liqingzhao的珠联璧合

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
            return true  -- 这是一个锁定技，不需要询问发动  
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
goujian:addSkill(tuqiang)

sgs.LoadTranslationTable{  
    ["goujian"] = "勾践",  
    ["#goujian"] = "卧薪尝胆",  
      
    ["yinren"] = "隐忍",  
    [":yinren"] = "若你的出牌阶段没有使用过杀，你跳过弃牌阶段。",  
      
    ["tuqiang"] = "图强",  
    [":tuqiang"] = "你的回合外，当你使用或打出基础牌时，你可以摸一张牌。",  
}

--[[
huangdi = sgs.General(extension, "huangdi", "qun", 4)  -- 吴国，4血，男性  
  
renzu = sgs.CreateDrawCardsSkill{  
    name = "renzu",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        local count = 0  
          
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
              
            return n + count  
        else  
            return n  
        end  
    end  
}  

-- 添加手牌上限修改效果  
renzuMaxCard = sgs.CreateMaxCardsSkill{  
    name = "#renzu-discard",  
    fixed_func = function(self, player)
        if player:hasSkill("renzu") then 
            return 0
        end
    end  
}  
-- 添加技能给武将  
huangdi:addSkill(renzu)  
huangdi:addSkill(renzuMaxCard)  
sgs.LoadTranslationTable{  
    ["huangdi"] = "黄帝",  
      
    ["renzu"] = "人祖",  
    [":renzu"] = "你摸牌阶段摸牌数+X，X为存活玩家数；你的手牌上限恒定为0",  
      
}
]]
-- 创建武将：
jifa = sgs.General(extension, "jifa", "wei", 4)  -- 吴国，4血，男性  

-- 创建讨伐技能卡  
TaofaCard = sgs.CreateSkillCard{  
    name = "taofaCard",  
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

jifa:addSkill(Taofa)  

sgs.LoadTranslationTable{  
    ["jifa"] = "姬发",
    ["#jifa"] = "周武王",
    ["taofa"] = "讨伐",  
    [":taofa"] = "出牌阶段，你可以将一张手牌交给一名角色，若其体力值大于等于你，你对其造成一点伤害。每回合只能对同一角色使用1次。",  
    ["taofaCard"] = "讨伐",  
}


-- 创建武将：唐伯虎  
kongzi = sgs.General(extension, "kongzi", "wu", 3)  -- 吴国，4血，男性  

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
        return #targets<=2   
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local card_id = room:askForCardChosen(source, source, "he", self:objectName(), false)  
        room:obtainCard(target, card_id)  
        if #targets==2 then
            target = targets[2]  
        end
        local card_id = room:askForCardChosen(source, source, "he", self:objectName(), false)  
        room:obtainCard(target, card_id)  
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

-- 创建武将：李白  
libai = sgs.General(extension, "libai", "shu", 3)  
  
-- 创建技能：邀月  
yaoyue = sgs.CreateTargetModSkill{  
    name = "yaoyue",   
    pattern = "Slash#SingleTargetTrick",  --同类模式用#并列，不同类用|并列  
    extra_target_func = function(self, player, card)  
        if player:hasSkill(self:objectName()) then  
            return 1
        else  
            return 0  
        end  
    end  
}  
-- 技能：酒仙 - 使用杀时触发（摸牌部分）  
jiuxian_draw = sgs.CreateTriggerSkill{  
    name = "jiuxian_draw",  
    events = {sgs.CardUsed},  
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
        return true -- 自动触发  
    end,  
    on_effect = function(self, event, room, player, data)  
        player:drawCards(1)  
        return false  
    end  
}  
  
-- 酒仙 - 免疫伤害部分  
jiuxian_immune = sgs.CreateTriggerSkill{  
    name = "jiuxian_immune",   
    events = {sgs.DamageInflicted},  
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
        return true -- 自动触发  
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

-- 创建武将：唐伯虎  
linxiangru = sgs.General(extension, "linxiangru", "qun", 3)  -- 吴国，4血，男性  

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
        local to_show = room:askForExchange(target, "exchange_show", target:getHandcardNum(), 1, "@exchange-show","","", ".|.|.|hand")  
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


linxiangru:addSkill(wanbi)
sgs.LoadTranslationTable{
    ["linxiangru"] = "蔺相如",  
      
    ["wanbi"] = "完璧",   
    [":wanbi"] = "出牌阶段限一次，你可以将全部手牌交给一名其他角色，令其展示任意数量的手牌，你选获得展示的或未展示的"  
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
          
        room:showCard(target, card_id)  
          
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
    [":shangli"] = "你的回合外，你使用、打出红色手牌时，你可以摸一张牌。",  

    ["yuci"] = "玉词",  
    [":yuci"] = "出牌阶段限一次。你可以弃置一名角色一张手牌，若此牌为基础牌，你弃置一张牌，无牌则不弃",        
    ["~liqingzhao"] = "生当作人杰，死亦为鬼雄。"  
}  

lizicheng = sgs.General(extension, "lizicheng", "qun", 4)  -- 吴国，4血，男性  


Lumang = sgs.CreateTriggerSkill{  
    name = "lumang",  
    events = {sgs.TargetConfirmed}, --SlashEffected
    frequency = sgs.Skill_Frequent,
      
    can_trigger = function(self, event, room, player, data)   
        --TargetConfirmed是卡牌使用
        local use = data:toCardUse()  
        if not (use.card:isNDTrick()) then return "" end 
        if use.card:isKindOf("Duel") then return "" end 
        local from = use.from
        local owners = room:findPlayerBySkillName(self:objectName())  
        for _, p in sgs.qlist(owners) do  
            if p:objectName() ~= from:objectName() and use.to:length()==1 then 
                return self:objectName() .. ":" .. p:objectName()
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
        if pattern == "slash" then  
            -- 检查当前的卡牌使用原因  
            local reason = sgs.Sanguosha:getCurrentCardUseReason()  
            -- 只允许在响应使用时生效（决斗需要响应使用杀）  
            return reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE  
        end  
        return false          
        --return pattern == "slash"  
    end  
}  
lizicheng:addSkill(Lumang)
lizicheng:addSkill(Yongchuang)

sgs.LoadTranslationTable{  
    ["hero"] = "英雄扩展包",  
      
    ["#lizicheng"] = "闯王",  
    ["lizicheng"] = "李自成",  
    ["lumang"] = "鲁莽",  
    [":lumang"] = "当你成为单体锦囊的目标时，你可以取消该锦囊，视为来源对你使用一张【决斗】。",  
    ["yongchuang"] = "勇闯",   
    [":yongchuang"] = "响应【决斗】时，你的任何一张牌都可以当【杀】使用或打出。"  
}
-- 创建武将：
luobingwang = sgs.General(extension, "luobingwang", "qun", 3)  -- 吴国，4血，男性 
yonge = sgs.CreateTriggerSkill{  
    name = "yonge",  
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseChanging},  

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
            return true  
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
sgs.LoadTranslationTable{
    ["luobingwang"] = "骆宾王",
    ["yonge"] = "咏鹅",
    [":yonge"] = "出牌阶段，当你使用的牌的点数为本回合最大点数时，你摸一张牌。"
}

-- 创建武将：
luzhishen = sgs.General(extension, "luzhishen", "wei", 4)  -- 吴国，4血，男性  

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
    frequency = sgs.Skill_Frequent, -- 设置为常规技能  
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then  
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
        if player:getHp() < 2 then 
            return false
        end
        -- 获取房间对象  
        local room = player:getRoom()  
          
        -- 询问玩家是否发动技能  
        --if player:askForSkillInvoke(self:objectName()) then  
        room:loseHp(player, 1) 
        --end  
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
    [":kuangchan"] = "准备阶段，若你的体力值不小于2，你可以失去一点体力",
}  


--[[ 
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
]]
-- 创建武将：吕雉  
lvzhi = sgs.General(extension, "lvzhi", "shu", 4, false)  

yangbing = sgs.CreateTriggerSkill{  
    name = "yangbing",  
    events = {sgs.EventPhaseEnd, sgs.Damage},  
      
    can_trigger = function(self, event, room, player, data)
        if event == sgs.Damage then  
            -- 记录造成伤害的角色  
            room:setPlayerFlag(player, "yangbing_damage")  
            return ""  
        elseif event == sgs.EventPhaseEnd and player and player:isAlive() and player:getPhase() == sgs.Player_Finish then  
            -- 回合结束时，检查是否有角色拥有养兵技能  
            owner = room:findPlayerBySkillName(self:objectName())
            if owner and owner:isAlive() and not player:hasFlag("yangbing_damage") then  
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
        for _, id in sgs.qlist(room:getDiscardPile()) do  
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
      
    can_trigger = function(self, event, room, player, data)  
        local dying = data:toDying()  
        local lvzhi = room:findPlayerBySkillName(self:objectName())  
        if lvzhi and lvzhi:isAlive() and dying.who:objectName() == player:objectName() and player:getHp() <= 0 then  
            return self:objectName(), lvzhi:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, lvzhi)  
        -- 检查是否有酒可以弃置  
        local analeptic = room:askForCard(lvzhi, "Analeptic", "@zhensha-discard:" .. player:objectName(), data, sgs.Card_MethodDiscard)  
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
        room:killPlayer(player)
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
    [":yangbing"] = "任何角色回合结束时，若其本回合内未造成伤害，你可令其随机获得一张弃牌堆的杀。",  
      
    ["zhensha"] = "鸩杀",  
    [":zhensha"] = "当一名角色进入濒死状态时，你可以弃置一张酒，令其跳过求桃阶段，立即死亡。",  
    ["@zhensha-discard"] = "你可以弃置一张酒，令 %src 跳过求桃阶段，立即死亡",  

    ["xumou"] = "蓄谋",  
    [":xumou"] = "回合结束时，你可以摸三张牌，然后进入叠置状态。",  
}

maosui = sgs.General(extension, "maosui", "qun", 3)  
  
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
            local cards = room:askForExchange(ask_who, self:objectName(), ask_who:getCardCount(true), 1)   
            for _,card in sgs.qlist(cards) do
                room:obtainCard(player, card, false)  
            end
            room:addPlayerMark(ask_who, "@zijian_draw", #cards)    
        end
        return false  
    end  
}

-- 自荐摸牌效果  
zijian_draw = sgs.CreateDrawCardsSkill{  
    name = "#zijian_draw",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n) 
        local count = player:getMark("@zijian_draw")
        player:setMark("@zijian_draw",0)
        return n + count
    end  
}  
--[[
-- 脱颖技能  
tuoying = sgs.CreateTriggerSkill{  
    name = "tuoying",  
    events = {sgs.TurnStart},  --sgs.TurnStart,全局触发
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive()) then--and player:getPhase() ~= sgs.Player_Start) then
            return ""
        end
        local maosui = room:findPlayerBySkillName(self:objectName())
        if not (maosui and maosui:isAlive()) then 
            return "" 
        end
        local my_handcard_num = maosui:getHandcardNum()
        local is_unique = true  
            
        for _, other in sgs.qlist(room:getOtherPlayers(maosui)) do  
            if other:getHandcardNum() == my_handcard_num then  
                is_unique = false  
                break  
            end  
        end  
            
        if is_unique then  
            return self:objectName(), maosui:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        room:drawCards(ask_who, 1, "tuoying")  
        return false  
    end  
}  
]]
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
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        ask_who:drawCards(1, self:objectName())  
        return false  
    end,  
}
-- 添加技能到武将  
maosui:addSkill(zijian)  
maosui:addSkill(tuoying)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["maosui"] = "毛遂",  
    ["zijian"] = "自荐",  
    [":zijian"] = "其他角色回合结束时，你可交给其X张牌",
    ["tuoying"] = "脱颖",
    [":tuoying"] = "任意角色回合开始时，若你的手牌数和所有角色都不相同，你可以摸一张牌"
}

-- 创建武将：唐伯虎  
menghuo_zhurong = sgs.General(extension, "menghuo&zhurong", "shu", 4)  -- 吴国，4血，男性  

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

menghuo_zhurong:addSkill(manwang)
menghuo_zhurong:addSkill(manhou)
menghuo_zhurong:addSkill(zongheng)

sgs.LoadTranslationTable{
    ["menghuo&zhurong"] = "孟获&祝融",  

    ["manwang"] = "蛮王",  
    [":manwang"] = "出牌阶段，你可以使用两张杀视为使用一张【南蛮入侵】。",  
      
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

-- 创建武将：
miyue = sgs.General(extension, "miyue", "qun", 3, false)  -- 吴国，4血，男性  
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
        
        -- 检查伤害数据
        local damage = data:toDamage()
        if not damage or not damage.from or not damage.from:isAlive() then
            return ""
        end
        
        -- 伤害来源不能是芈月自己
        if damage.from:objectName() == player:objectName() then
            return ""
        end
        
        return self:objectName()
    end,
    
    on_cost = function(self, event, room, player, data)
        -- 询问是否发动技能
        local damage = data:toDamage()
        local prompt = string.format("@zhangquan-invoke:%s", damage.from:objectName())
        
        if room:askForSkillInvoke(player, "zhangquan", data, prompt) then
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
        local to_discard = room:askForDiscard(source, "zhangquan", 1, 0, true, false, prompt)--1,1
        
        if to_discard:length() > 0 then
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
            recover.reason = "zhangquan"
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

miyue:addSkill(yuumie)
miyue:addSkill(zhangquan)

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
    ["~miyue"] = "权势终有尽时...",
}

moxi = sgs.General(extension, "moxi", "shu", 3, false)

yaoji_card = sgs.CreateSkillCard{
    name = "yaoji",
    mute = true,
    target_fixed = false,
    will_throw = false,
    can_recast = false,
    
    filter = function(self, targets, to_select)
        -- 只能选择一名其他角色
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    
    feasible = function(self, targets)
        -- 必须选择一名目标
        return #targets == 1
    end,
    
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local subcards = self:getSubcards()
        
        -- 播放技能音效
        room:broadcastSkillInvoke("yaoji", source)
        
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
                local target_cards = room:askForExchange(target, "yaoji", exchange_count, exchange_count, 
                                                       string.format("@yaoji-exchange:%s::%d", source:objectName(), exchange_count),"", ".|.|.|hand")--suit|number|color|place
                
                if target_cards:length() == exchange_count then
                    -- 创建卡牌移动结构
                    local move1 = sgs.CardsMoveStruct()
                    move1.card_ids = subcards
                    move1.from = source
                    move1.to = target
                    move1.to_place = sgs.Player_PlaceHand
                    move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                    source:objectName(), target:objectName(), "yaoji", "")
                    
                    local move2 = sgs.CardsMoveStruct()
                    move2.card_ids = target_cards
                    move2.from = target
                    move2.to = source
                    move2.to_place = sgs.Player_PlaceHand
                    move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                    target:objectName(), source:objectName(), "yaoji", "")
                    
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
                                                source:objectName(), target:objectName(), "yaoji", "")
                
                local move2 = sgs.CardsMoveStruct()
                move2.card_ids = target_handcards
                move2.from = target
                move2.to = source
                move2.to_place = sgs.Player_PlaceHand
                move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE,
                                                target:objectName(), source:objectName(), "yaoji", "")
                
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
yaoji = sgs.CreateViewAsSkill{
    name = "yaoji",
    n = 998,
    
    view_filter = function(self, selected, to_select)
        -- 只能选择手牌
        return not to_select:isEquipped()
    end,
    
    view_as = function(self, cards)
        local skillcard = yaoji_card:clone()
        if #cards > 0 then
            for i = 1, #cards do
                skillcard:addSubcard(cards[i]:getId())
            end
        end
        skillcard:setSkillName("yaoji")
        skillcard:setShowSkill("yaoji")
        return skillcard
    end,
    
    enabled_at_play = function(self, player)
        -- 每回合限用一次
        return not player:hasUsed("#yaoji")
    end
}

-- 妺喜武将定义
moxi:addSkill(yaoji)

-- 技能音效和翻译配置
sgs.LoadTranslationTable{
    ["hero"] = "英雄",
    ["moxi"] = "妺喜",
    ["&moxi"] = "妺喜",
    ["#moxi"] = "倾国倾城",
    ["designer:moxi"] = "自定义",
    ["cv:moxi"] = "无",
    ["illustrator:moxi"] = "无",
    
    ["yaoji"] = "妖姬",
    [":yaoji"] = "出牌阶段限一次，你可以选择：1.将任意数量的手牌和另一名角色交换等量的手牌；2.将所有手牌和另一名角色交换所有手牌。",
    ["@yaoji-exchange"] = "妖姬：请选择 %arg 张手牌与 %src 交换",
    ["#exchangePartial"] = "%from 与 %to 交换了 %arg 张手牌",
    ["#exchangeAll"] = "%from 与 %to 交换了所有手牌（%from: %arg 张，%to: %arg2 张）",
    ["$exchange1"] = "以手中牌，换君心意。",
    ["$exchange2"] = "此牌换彼牌，情深意更长。",
    ["~moxi"] = "红颜薄命，终是一场空...",
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
            local card = room:askForCard(ask_who, "he", "@feigongSlash-give:" .. target:objectName(),   
                                       sgs.QVariant(), sgs.Card_MethodNone)  
            if card then  
                room:obtainCard(target, card:getEffectiveId(), false)  
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


shangguan = sgs.General(extension, "shangguan", "qun", 3, false)  

nvxiang = sgs.CreateTriggerSkill{  
    name = "nvxiang",  
    events = {sgs.TargetConfirmed}, --SlashEffected
      
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
      
    on_cost = function(self, event, room, player, data, shangguan)  
        if shangguan:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), shangguan)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, shangguan)
        local use = data:toCardUse()
        local from = use.from
        --local effect = data:toSlashEffect()
        --local from = effect.from          
        -- 发起拼点  
        local success = shangguan:pindian(from, self:objectName())  
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
            msg.from = shangguan  
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
            --judge.pattern = "red"
            --judge.good = true  
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

shangguan:addSkill(nvxiang)  
shangguan:addSkill(yicai)

sgs.LoadTranslationTable{  
    ["shangguan"] = "上官婉儿",  
    ["#shangguan"] = "才女",  
      
    ["nvxiang"] = "女相",  
    [":nvxiang"] = "当一名角色成为杀的目标后，你可以与其拼点，若你赢，则该杀无效。",  
    ["#NvxiangEffect"] = "%from 发动了'%arg'，使 %to 的 %arg2 无效",  
      
    ["yicai"] = "绮才",  
    [":yicai"] = "准备阶段，你可以发起判定，直到判定牌为黑色，你获得所有判定牌，然后你弃置1张牌",  
}

 
-- 创建武将：唐伯虎  
shangzhou = sgs.General(extension, "shangzhou", "qun", 4)  -- 吴国，4血，男性  

zhongpan = sgs.CreateOneCardViewAsSkill{
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
        return not player:hasUsed("#zhongpan")  --参考袁绍，可以考虑不限制次数，红桃没那么多
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
        return true  -- 强制技能，无需询问  
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
        if player and player:isAlive() and player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then  
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
        judge.pattern = ".|.|1~6" -- 判定牌点数小于7。第一个点表示任意花色，第二个点表示任意类型
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

    can_trigger = function(self, event, room, player, data)  
        -- 任意角色回合结束时都可能触发
        owner = room:findPlayerBySkillName(self:objectName())
        if player:getPhase() == sgs.Player_Finish then  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if  p:getHandcardNum()<2   then  
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
            if  p:getHandcardNum()<2   then  
                targets:append(p)            
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(ask_who, targets, "jianlie", "@jianlie-choose", true)  

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
    [":jianlie"] = "任意角色回合结束时，你可以选择一名手牌数小于2的角色，你可令其摸一张牌。", 

}

-- 创建武将  
simayi_hero = sgs.General(extension, "simayi", "wei", 3)  
  
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
        return new_card  
    end,  
    enabled_at_play = function(self, player)  
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
    ["simayi"] = "司马懿",  
    ["zhuolue"] = "卓略",  
    [":zhuolue"] = "出牌阶段，你可以弃置所有黑色牌，视为使用一张【南蛮入侵】；你可以弃置所有红色牌，视为使用一张【桃】。",  
    ["langgu"] = "狼顾",  
    [":langgu"] = "你受到伤害时，你可以摸一张牌，然后展示所有手牌，若手牌颜色都相同，你回复一点体力。"  
}  
  

-- 创建武将：
sunce_hero = sgs.General(extension, "sunce_hero", "wu", 4)  -- 吴国，4血，男性  

-- 创建均衡技能卡  
JunhengCard = sgs.CreateSkillCard{  
    name = "junhengCard",  
    filter = function(self, targets, to_select)  
        -- 只能选择两名角色  
        return #targets < 2  
    end,  
      
    feasible = function(self, targets)  
        -- 必须选择两名角色  
        return #targets == 2  
    end,  
      
    on_use = function(self, room, source, targets)  
        -- 获取两个目标角色  
        local from = targets[2]  -- 失去手牌的角色  
        local to = targets[1]    -- 获得手牌的角色  
          
        -- 通知技能被触发  
        room:notifySkillInvoked(source, "junheng")  
          
        -- 播放技能配音  
        room:broadcastSkillInvoke("junheng")  
          
        -- 令to获得from的一张手牌  
        if not from:isKongcheng() then  
            local card_id = room:askForCardChosen(to, from, "h", "junheng")  
              
            -- 移动卡牌  
            local move = sgs.CardsMoveStruct()  
            move.card_ids:append(card_id)  
            move.to = to  
            move.to_place = sgs.Player_PlaceHand  
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, from:objectName(), to:objectName(), "junheng", "")  
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

sunce_hero:addSkill(Junheng)
sgs.LoadTranslationTable{  
    ["sunce_hero"] = "孙策",
    ["junheng"] = "均衡",  
    [":junheng"] = "出牌阶段限1次，你可以选择两名角色，令一名角色获得另一名角色一张手牌，若此时他们手牌数相等，你摸一张牌。",  
    ["junhengCard"] = "均衡",  

}


-- 创建武将：
sunwu = sgs.General(extension, "sunwu", "wei", 3)  -- 吴国，4血，男性  

-- 创建强行技能卡  
qijiCard = sgs.CreateSkillCard{  
    name = "qijiCard",  
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

sunwu:addSkill(qiji)
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["sunwu"] = "孙武",
    ["#sunwu"] = "孙武",
    ["qiji"] = "奇计",  
    [":qiji"] = "出牌阶段限1次，你可以弃置两张手牌，令一名角色体力值与你相同。",  
    ["qijiCard"] = "强行",  
}

-- 创建武将：唐伯虎  
tangbohu = sgs.General(extension, "tangbohu", "wei", 3)  -- 吴国，4血，男性  
  
-- 技能1：风流 - 摸牌阶段开始时，场上每多一名女性角色，你的摸牌数＋1  
fengliu = sgs.CreateDrawCardsSkill{  
    name = "fengliu",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        local female_count = 0  
          
        -- 计算场上女性角色数量  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if  p:hasShownGeneral1() and p:isFemale()  then  
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
              
            player:drawCards(lost_hp, self:objectName())  
        end  
          
        return false  
    end  
}  
  
-- 添加技能给武将  
tangbohu:addSkill(fengliu)  
tangbohu:addSkill(luobi)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["tangbohu"] = "唐伯虎",  
    ["#tangbohu"] = "风流才子",  
    ["fengliu"] = "风流",  
    [":fengliu"] = "锁定技，摸牌阶段开始时，场上每多一名女性角色，你的摸牌数+1。",  
    ["#FengliuDraw"] = "%from 的【%arg2】技能被触发，额外摸了 %arg 张牌",  
      
    ["luobi"] = "落笔",  
    [":luobi"] = "弃牌阶段结束后，你可以摸X张牌，X为你已损失的体力值。",  
    ["#LuobiDraw"] = "%from 发动了【%arg2】，摸了 %arg 张牌",  
      
    ["~tangbohu"] = "吾一生风流，今日竟折于此！"  
}  

-- 创建武将：王昭君  
wangzhaojun = sgs.General(extension, "wangzhaojun", "wu", 3, false)  -- 群雄，3血，女性  
-- 创建和亲技能卡  
HeqinCard = sgs.CreateSkillCard{  
    name = "heqin",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:isMale() and to_select:objectName() ~= sgs.Self:objectName()  
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
        if not source_handcards:isEmpty() then  
            local move1 = sgs.CardsMoveStruct()  
            move1.card_ids = source_handcards  
            move1.to = target  
            move1.to_place = sgs.Player_PlaceHand  
            room:moveCardsAtomic(move1, false)  
        end  
          
        if not target_handcards:isEmpty() then  
            local move2 = sgs.CardsMoveStruct()  
            move2.card_ids = target_handcards  
            move2.to = source  
            move2.to_place = sgs.Player_PlaceHand  
            room:moveCardsAtomic(move2, false)  
        end  

        -- 记录交换后的手牌数  
        local source_handcard_num = source:handCards():length()  
        local target_handcard_num = target:handCards():length()            
        -- 让手牌数较少的一方摸2张牌  
        if source_handcard_num < target_handcard_num then  
            source:drawCards(2)  
        elseif target_handcard_num > source_handcard_num then  
            target:drawCards(2)  
        else  
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
        return card  
    end,  
      
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#heqin") -- 出牌阶段限一次  
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
        if from and from:isAlive() and from:getWeapon() then  
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
            target:drawCards(source:getHandcardNum()-target:getHandcardNum())
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
    [":jingjian"] = "出牌阶段限一次，你可以选择一名角色，令其手牌数摸或弃至与你相同。",  

}

weizifu = sgs.General(extension, "weizifu", "shu", 4, false)  

jiangmen = sgs.CreateTriggerSkill{  
    name = "jiangmen",  
    events = {sgs.EventPhaseStart},  
      
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() ~= sgs.Player_Play then return "" end  
          
        local weizifu = room:findPlayerBySkillName(self:objectName())  
        if weizifu and weizifu:isAlive() and weizifu:getHp() > 0 then  
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
        -- 卫子夫失去一点体力  
        room:loseHp(weizifu, 1)  
          
        -- 卫子夫摸一张牌  
        weizifu:drawCards(1)  
          
        -- 如果卫子夫有手牌，则交给目标角色一张牌  
        if not weizifu:isKongcheng() then  
            local card_id = room:askForCardChosen(weizifu, weizifu, "h", self:objectName())  
            room:obtainCard(player, card_id, false)  
              
            -- 增加目标角色使用杀的次数  
            --room:addPlayerMark(player, "jiangmen_extra_slash")  
            room:setPlayerFlag(player, "jiangmen_extra_slash")  
              
            -- 设置标记，使目标角色本回合使用杀的次数+1  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            local residue = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, slash) + 1  
            room:setPlayerMark(player, "@jiangmen", residue)  
              
            -- 日志  
            local msg = sgs.LogMessage()  
            msg.type = "#jiangmenEffect"  
            msg.from = weizifu  
            msg.to:append(player)  
            msg.arg = self:objectName()  
            room:sendLog(msg)    
        end        
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
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local discard_num = player:getHandcardNum() - player:getMaxCards()
        discard_num = math.max(discard_num,0)
        if discard_num > 0 then
            card_id=room:askForDiscard(player, self:objectName(), discard_num, discard_num)
        end
        chosen_players = room:askForPlayersChosen(player,  room:getAlivePlayers(), self:objectName(), 0, discard_num+1, "请选择玩家", true)
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
        player:skip(sgs.Player_Discard)
        return false  
    end  
}

weizifu:addSkill(jiangmen)  
weizifu:addSkill(jiangmenMod)
weizifu:addSkill(jiade)

sgs.LoadTranslationTable{  
    ["weizifu"] = "卫子夫",  
      
    ["jiangmen"] = "将门",  
    [":jiangmen"] = "一名角色出牌阶段开始时，你可以失去一点体力，摸一张牌，然后交给该角色一张牌，令其本回合使用杀的次数+1。",  

    ["jiade"] = "嘉德",  
    [":jiade"] = "弃牌阶段结束时，你可令至多X+1名角色各摸一张牌，X为你本回合的弃牌数",  
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
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["wenjiang"] = "文姜",
    ["beide"] = "背德",  
    [":beide"] = "当你成为杀的目标时，你可以指定一名其他角色也成为杀的目标。",  
    ["@beide-choose"] = "背德：你可以指定一名其他角色也成为此杀的目标"  
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
    will_throw = false,
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()   
    end,  
    on_use = function(self, room, source, targets)  
        room:askForDiscard(source, self:objectName(), 2, 2)
        local target = targets[1]  
        room:swapSeat(source, target)
    end  
}  
  
qiaoqian = sgs.CreateZeroCardViewAsSkill{  
    name = "qiaoqian",  
    view_as = function(self, cards)  
        --if #cards ~= 2 then return nil end  
        local card = qiaoqianCard:clone()  
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#qiaoqian") and not player:isKongcheng()
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
        return true  -- 锁定技，自动触发  
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

xiajie:addSkill(shenli)
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["xiajie"] = "夏桀",
    ["#xiajie"] = "暴君-夏",
    ["shenli"] = "神力",  
    [":shenli"] = "锁定技，你使用【杀】造成伤害时，增加你已失去体力值的伤害。",  
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
          
        if player:askForSkillInvoke(self, data) then  
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
        return player:getMark("@chuyou_maxcards")  
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
    [":chuyou"] = "你可以跳过摸牌阶段或者出牌阶段，然后你摸一张牌，使手牌上限永久+2。",  
      
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
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:isWounded() then  
                wounded_count = wounded_count + 1  
            end  
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
            player:drawCards(wounded_count)  
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
    [":yaoyi"] = "当你受到伤害时，你摸X张牌，X为场上已受伤的角色数。",  
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
            return self.objectName()
        end
        return false
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
  
-- 添加技能给武将  
yangyuhuan:addSkill(xiuhua)  
  
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["yangyuhuan"] = "杨玉环",  

    ["xiuhua"] = "羞花",  
    [":xiuhua"] = "锁定技，当你的手牌数小于失去的体力时，你摸一张牌。",
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
        end  
        return new_card  
    end,  

    enabled_at_play = function(self, player)  
        return not player:isKongcheng()  
    end,

    enabled_at_response = function(self, player, pattern)  
        return pattern == "slash" or pattern == "jink" or pattern == "peach" or pattern == "analeptic"  
    end  
}
yuefei:addSkill(wumu)  

-- 添加翻译  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄包",  
    ["yuefei"] = "岳飞",  
      
    ["wumu"] = "武穆",  
    [":wumu"] = "你可以将一张基础牌当做一张基础牌使用或打出。",  

    ["@wumu"] = "请选择【武穆】要转化的牌",  
    ["~wumu"] = "选择一张基础牌→选择要视为的牌→确定",  
}  

-- 创建武将：唐伯虎  
yuwenhuaji = sgs.General(extension, "yuwenhuaji", "qun", 4)  -- 吴国，4血，男性 

jiandi = sgs.CreateTriggerSkill{  
    name = "jiandi",  
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
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName())  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 跳过摸牌阶段  
        --player:skip(sgs.Player_Draw)  
        -- 失去1点体力  
        room:loseHp(player, 1)  
        --弃置1张牌
        room:askForDiscard(player, self:objectName(), 1, 1, false, true)

        -- 获得所有角色各一张牌  
        local targets = room:getAlivePlayers()  
        for _, target in sgs.qlist(targets) do  
            if target:objectName() ~= player:objectName() and not target:isAllNude() then  
                local card_id = room:askForCardChosen(player, target, "hej", self:objectName())  
                room:obtainCard(player, card_id, false)  
            end  
        end  
        return false  
    end  
}

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
yuwenhuaji:addSkill(jiandi)  
yuwenhuaji:addSkill(cuanni)  
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄",  
    ["yuwenhuaji"] = "宇文化及",  
    ["jiandi"] = "僭帝",  
    [":jiandi"] = "准备阶段，你可以失去一点体力，弃置一张牌，获得所有角色各一张牌。",  
    ["cuanni"] = "篡逆",  
    [":cuanni"] = "你造成的伤害可以视为体力流失。"  
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
        local prompt = "@taiji-slash"  
        return room:askForUseCard(player, "slash", prompt, -1, sgs.Card_MethodUse, false)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        -- 由于使用杀的逻辑已经在on_cost中完成，这里不需要额外处理  
        return false  
    end,  
}

zhangsanfeng:addSkill(Taiji)
-- 添加技能翻译  
sgs.LoadTranslationTable{  
    ["zhangsanfeng"] = "张三丰",
    ["#zhangsanfeng"] = "太极真人",
    ["taiji"] = "太极",  
    [":taiji"] = "回合外，每当你使用或打出【闪】时，你可以对攻击范围内的一名角色使用一张【杀】。",  
    ["@taiji-slash"] = "你可以对攻击范围内的一名角色使用一张【杀】",  
}

zhangsunhuanghou = sgs.General(extension, "zhangsunhuanghou", "wu", 3, false)  
  
-- 技能1：恩泽  
xianzhuCard = sgs.CreateSkillCard{  
    name = "xianzhuCard",  
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
          
        local n1 = player:getHandcardNum()  
        local n2 = target:getHandcardNum()  
          
        -- 交换手牌  
        --[[
        local exchangeMove = {}  
        local move1 = sgs.CardsMoveStruct(player:handCards(), target, sgs.Player_PlaceHand,  
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), target:objectName(), "jiandie", ""))  
        local move2 = sgs.CardsMoveStruct(target:handCards(), player, sgs.Player_PlaceHand,  
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), player:objectName(), "jiandie", ""))  
        table.insert(exchangeMove, move1)  
        table.insert(exchangeMove, move2)  
        room:moveCards(exchangeMove, false)  
        ]]
        local source_handcards = player:handCards()  
        local target_handcards = target:handCards()  
        if source_handcards:isEmpty() and target_handcards:isEmpty() then  
            return  false
        end  
        if not source_handcards:isEmpty() then  
            local move1 = sgs.CardsMoveStruct()  
            move1.card_ids = source_handcards  
            move1.to = target  
            move1.to_place = sgs.Player_PlaceHand  
            room:moveCardsAtomic(move1, false)  
        end  

        if not target_handcards:isEmpty() then  
            local move1 = sgs.CardsMoveStruct()  
            move1.card_ids = target_handcards  
            move1.to = player  
            move1.to_place = sgs.Player_PlaceHand  
            room:moveCardsAtomic(move1, false)  
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
  
zhaokuo = sgs.General(extension, "zhaokuo", "qun")  -- 吴国，4血，男性  


zhishangtanbing = sgs.CreateTriggerSkill{  
    name = "zhishangtanbing",  
    events = {sgs.Damaged},  
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
            local card_id = room:askForCardChosen(ask_who, ask_who, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
            room:throwCard(card_id, ask_who, ask_who)  
        else
            ask_who:drawCards(1)
        end
        return false  
    end  
}

zhaokuo:addSkill(zhishangtanbing)

sgs.LoadTranslationTable{
    ["zhaokuo"] = "赵括",
    ["zhishangtanbing"] = "纸上谈兵",  
    [":zhishangtanbing"] = "当其他角色受到伤害时，你摸一张牌；当你受到伤害时，你弃置一张牌"
}

zhouchu = sgs.General(extension, "zhouchu", "qun", 4)  
  
-- 技能1：改过  
gaiguo = sgs.CreateTriggerSkill{  
    name = "gaiguo",  
    events = {sgs.Damage, sgs.Damaged},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        room:addPlayerMark(player, "@guo", damage.damage)  
        room:broadcastSkillInvoke(self:objectName(), player)  
            
        -- 检查是否为3的倍数  
        local guo_count = player:getMark("@guo")  
        if guo_count > 0 and guo_count % 3 == 0 then  
            room:drawCards(player, 3, self:objectName())  
        end  
        return false  
    end  
}  
  
-- 技能2：除害  
chuhai = sgs.CreateTriggerSkill{  
    name = "chuhai",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return false  
        end  
          
        if player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  

        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        -- 视为使用决斗  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            targets:append(p)  
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
            end  
        end  
        player:skip(sgs.Player_Draw)
        return false  
    end  
}  
--[[
chuhai_draw = sgs.CreateDrawCardsSkill{  
    name = "chuhai_draw",  
    frequency = sgs.Skill_Compulsory,  
      
    draw_num_func = function(self, player, n)  
        if player:hasFlag("@chuhai") then
            return math.max(n-2,0)
        else
            return name
        end
    end  
}  
]]
-- 添加技能到武将  
zhouchu:addSkill(gaiguo)  
zhouchu:addSkill(chuhai)  
--zhouchu:addSkill(chuhai_draw)  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["hero"] = "英雄传",  
    ["zhouchu"] = "周处",  
    ["#zhouchu"] = "改过除害",  
      
    ["gaiguo"] = "改过",  
    [":gaiguo"] = "你造成或受到1点伤害时，获得1个'过'标记。你的'过'标记为3的倍数时，摸三张牌。",  
      
    ["chuhai"] = "除害",   
    [":chuhai"] = "摸牌阶段，你可以跳过摸牌阶段，视为对一名角色使用1张【决斗】。",  
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
        local source = recover.to  --恢复体力的角色source就是player
          
        -- 其他角色恢复体力时触发  
        owner = room:findPlayerBySkillName(self:objectName())
        if source and source:objectName() ~= owner:objectName() and not owner:isKongcheng() then  
            return self:objectName(), owner:objectName() 
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local recover = data:toRecover()  
        local target = recover.to  
          
        local card = room:askForCard(ask_who, ".", "@xiangshou-give:" .. target:objectName(),   
                                   sgs.QVariant(), sgs.Card_MethodNone)  
        if card then  
            ask_who:setTag("xiangshou_card", sgs.QVariant(card:getEffectiveId()))  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local recover = data:toRecover()  
        local target = recover.to  
        local card_id = ask_who:getTag("xiangshou_card"):toInt()  
        local card = sgs.Sanguosha:getCard(card_id)  
          
        -- 交给目标角色  
        room:obtainCard(target, card_id, false)  
          
        -- 如果是红色牌，自己回复1点体力  
        if card:isRed() then  
            local self_recover = sgs.RecoverStruct()  
            self_recover.who = ask_who  
            self_recover.recover = 1  
            room:recover(ask_who, self_recover)  
        end  
          
        ask_who:removeTag("xiangshou_card")  
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


  
-- 创建武将：朱元璋
zhuyuanzhang = sgs.General(extension, "zhuyuanzhang", "wu", 4)  -- 群雄，3血  


-- 技能1：强运 - 你失去最后一张手牌时，你摸一张牌  
qiangyun = sgs.CreateTriggerSkill{  
    name = "qiangyun",  
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime, sgs.CardResponded, sgs.CardUsed},  
      
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:hasSkill(self:objectName()) then
            return false  
        end  
        --我的实现。手牌数也可以用player:getHandcardNum(), player:isKongcheng(), player:handCards():length()
        if player:getHandcardNum() == 0 then
            return self:objectName() --必须返回技能名
        end
        return false  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true
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



--添加珠联璧合
--人物关系联动
--lvzhi:addCompanion("lvbuwei")
moxi:addCompanion("xiajie")
--技能联动
dongfangshuo:addCompanion("simaxiangru")
dongfangshuo:addCompanion("shangguan")
goujian:addCompanion("liqingzhao")
goujian:addCompanion("wangzhaojun")
goujian:addCompanion("zhangsunhuanghou")
simaxiangru:addCompanion("wuzetian")
wangzhaojun:addCompanion("zhangsunhuanghou")
xuxiake:addCompanion("zhangsunhuanghou")
--都联动
daji:addCompanion("shangzhou")
dufu:addCompanion("libai")
shangguan:addCompanion("wuzetian")
simaxiangru:addCompanion("zhuowenjun")
return {extension}
