extension = sgs.Package("equip", sgs.Package_CardPack)  
local skills = sgs.SkillList()

qiankundai = sgs.CreateArmor{  
    name = "qiankundai",  
    class_name = "QianKunDai",  
    suit = sgs.Card_Club,  
    number = 2,  
    on_install = function(self, player)  
        -- 装备时的效果已通过手牌上限技能实现  
        local room = player:getRoom()
        room:acquireSkill(player,"qiankundai_maxcards", true, true)
    end,  
    on_uninstall = function(self, player)  
        local room = player:getRoom()
        room:drawCards(player, 1, "qiankundai")  
        room:detachSkillFromPlayer(player,"qiankundai_maxcards", true, false, true)
        -- 失去时摸一张牌  
    end  
}

qiankundai_maxcards = sgs.CreateMaxCardsSkill{  
    name = "qiankundai_maxcards",  
    extra_func = function(self, player)  
        local armor = player:getArmor()
        if armor and armor:isKindOf("QianKunDai") then
            return 1  
        end  
        return 0  
    end  
}

shixuejian = sgs.CreateWeapon{  
    name = "shixuejian",  
    class_name = "ShiXueJian",   
    suit = sgs.Card_Heart,  
    number = 5,  
    range = 2,  
    on_install = function(self, player)  
        -- 装备时无特殊效果  
        local room = player:getRoom()
        room:acquireSkill(player,"shixuejian_recover", true, true)
    end,  
    on_uninstall = function(self, player)  
        -- 失去时无特殊效果  
        local room = player:getRoom()
        room:detachSkillFromPlayer(player,"shixuejian_recover", true, false, true)
    end  
}

shixuejian_skill = sgs.CreateTriggerSkill{  
    name = "shixuejian_recover",  
    events = {sgs.Damage},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasWeapon("ShiXueJian")) then--and player:getWeapon():isKindOf("ShiXueJian")) then   
            return ""   
        end  
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName() == player:objectName() then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true--player:askForSkillInvoke(self:objectName(), data) -- 自动触发，无需消耗  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()
        if not (damage.card and damage.card:isKindOf("Slash")) then return false end
        local recover = sgs.RecoverStruct()  
        recover.who = damage.from  
        recover.recover = 1  --damage.damage
        --recover.reason = "shixuejian"  
        room:recover(damage.from, recover)  
        return false  
    end  
}

anshajian = sgs.CreateWeapon{  
    name = "anshajian",  
    class_name = "AnShaJian",   
    suit = sgs.Card_Spade,  
    number = 3,  
    range = 2,
    on_install = function(self, player)  
        -- 装备时无特殊效果  
        local room = player:getRoom()
        room:acquireSkill(player,"anshajian_loseHp", true, true)
    end,  
    on_uninstall = function(self, player)  
        -- 失去时无特殊效果  
        local room = player:getRoom()
        room:detachSkillFromPlayer(player,"anshajian_loseHp", true, false, true)
    end  
}

anshajian_skill = sgs.CreateTriggerSkill{  
    name = "anshajian_loseHp",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasWeapon("AnShaJian")) then--and player:getWeapon():isKindOf("AnShaJian")) then   
            return ""   
        end  
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName()== player:objectName() then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()
        if not (damage.card and damage.card:isKindOf("Slash")) then
            return false
        end
        -- 改为体力流失  
        room:loseHp(damage.to, damage.damage)  

        -- 阻止原伤害  
        damage.damage = 0  
        --data = sgs.QVariant_fromValue(damage) 
        data:setValue(damage) 
        return true  
    end  
}

jinxiuzhengpao = sgs.CreateArmor{  
    name = "jinxiuzhengpao",  
    class_name = "jinxiuzhengpao",   
    suit = sgs.Card_Heart,  
    number = 2,  
      
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "jinxiuzhengpao", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "jinxiuzhengpao", true, false, true)  
    end  
}
jinxiuzhengpao_skill = sgs.CreateTriggerSkill{  
    name = "jinxiuzhengpao",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        if not player:hasArmorEffect("jinxiuzhengpao") then return "" end
        local damage = data:toDamage()  
        local armor = damage.to:getArmor()
        if armor and armor:isKindOf("jinxiuzhengpao") and damage.card   
           and damage.card:getSuit() ~= sgs.Card_NoSuit and damage.card:getSuit() ~= sgs.Card_NoSuitBlack and damage.card:getSuit() ~= sgs.Card_NoSuitRed then  
            -- 检查手牌中是否没有该花色  
            local has_suit = false  
            local handcards = damage.to:getHandcards()  
            for _, card in sgs.qlist(handcards) do  
                if card:getSuit() == damage.card:getSuit() then  
                    has_suit = true  
                    break  
                end  
            end  
            if not has_suit then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        local prompt = string.format("@jinxiuzhengpao:%s::%s",   
                                    damage.from and damage.from:objectName() or "",   
                                    damage.card:getSuitString())  
        return room:askForSkillInvoke(damage.to, self:objectName(), data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 展示所有手牌  
        local handcards = player:getHandcards()  
        if not handcards:isEmpty() then  
            room:showAllCards(damage.to)  
        end  
          
        -- 获得该牌  
        damage.to:obtainCard(damage.card)  
          
        -- 检查是否包含所有花色  
        local suits = {}  
        local all_cards = damage.to:getHandcards()  
        for _, card in sgs.qlist(all_cards) do  
            local suit = card:getSuit()  
            if suit ~= sgs.Card_NoSuit then  
                suits[suit] = true  
            end  
        end  
          
        -- 检查是否有四种花色  
        local suit_count = 0  
        for suit = sgs.Card_Spade, sgs.Card_Diamond do  
            if suits[suit] then  
                suit_count = suit_count + 1  
            end  
        end  
          
        if suit_count >= 4 then  
            -- 免疫伤害  
            damage.damage = 0
            data:setValue(damage)
            --room:setEmotion(player, "armor/jinxiuzhengpao")  
              
            local log = sgs.LogMessage()  
            log.type = "#JinxiuZhengpaoNullify"  
            log.from = player  
            log.arg = self:objectName()  
            room:sendLog(log)  
              
            return true -- 阻止伤害  
        end  
          
        return false  
    end  
}

xiuliQiankun = sgs.CreateArmor{  
    name = "XiuliQiankun",  
    class_name = "XiuliQiankun",  
    suit = sgs.Card_Club,  
    number = 2,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "XiuliQiankun", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "XiuliQiankun", true, false, true)  
    end  
}

xiuliQiankunSkill = sgs.CreateTriggerSkill{  
    name = "XiuliQiankun",  
    events = {sgs.CardEffected, sgs.TurnedOver},  
    frequency = sgs.Skill_Compulsory,  
            
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("XiuliQiankun")) then  
            return ""  
        end  
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
        return true  
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

bileizhen = sgs.CreateArmor{  
    name = "Bileizhen",  
    class_name = "Bileizhen",   
    suit = sgs.Card_Spade,  
    number = 3,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "Bileizhen", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "Bileizhen", true, false, true)  
    end  
}
--[[
--免疫雷属性伤害
bileizhenSkill = sgs.CreateTriggerSkill{  
    name = "Bileizhen",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("Bileizhen")) then  
            return ""  
        end  
          
        local damage = data:toDamage()  
        if damage.nature == sgs.DamageStruct_Thunder then  
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技，自动触发  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = 0
        data:setValue(damage)
        -- 记录日志  
        local log = sgs.LogMessage()  
        log.type = "#ArmorNullify"  
        log.from = player  
        log.arg = self:objectName()  
        log.arg2 = "thunder_nature"  
        room:sendLog(log)  
          
        -- 播放防具效果  
        --room:setEmotion(player, "armor/bileizhen")  
          
        return true -- 返回true阻止雷电伤害  
    end  
}
]]

--任意角色受到雷属性伤害时，若其不为你，你可以选择将该伤害转移给自己；若其为你，你可以免疫此伤害
--当你受到雷属性伤害后，你可以选择（1）恢复1点体力（2）获得1个摸牌阶段（3）获得一个出牌阶段
bileizhenSkill = sgs.CreateTriggerSkill{  
    name = "Bileizhen",  
    events = {sgs.DamageInflicted, sgs.Damaged},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)
        --[[
        local owner = nil
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasArmor() and p:getArmor():isKindOf("Bileizhen") then
                owner = nil
                break
            end
        end
        ]]
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasArmorEffect(self:objectName())) then return "" end
          
        local damage = data:toDamage()  
        if damage.nature == sgs.DamageStruct_Thunder then  
            if event == sgs.DamageInflicted then --任意角色受到伤害时
                return self:objectName(), owner:objectName()  
            elseif event == sgs.Damaged and damage.to == owner then --自己受到伤害后
                return self:objectName(), owner:objectName()  
            end
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        --return ask_who:askForSkillInvoke(self:objectName(),data) -- 锁定技，自动触发 
        local damage = data:toDamage()  
        if event == sgs.DamageInflicted then --任意角色受到伤害时
            if damage.to:objectName() ~= ask_who:objectName() then
                room:setPlayerFlag(ask_who,"bilenzhen-attrack")
                return ask_who:askForSkillInvoke("@bileizhen-attrack",data)  
            else
                room:setPlayerFlag(ask_who,"bilenzhen-immuse")
                return ask_who:askForSkillInvoke("@bileizhen-immuse",data)  
            end
        elseif event == sgs.Damaged and damage.to == ask_who then --自己受到伤害后
            --room:setPlayerFlag(ask_who,"bilenzhen-effect")
            return ask_who:askForSkillInvoke("@bileizhen-effect",data)  
        end

    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()  
        if event == sgs.DamageInflicted then --任意角色受到伤害时
            if damage.to:objectName() ~= ask_who:objectName() then
                new_damage = sgs.DamageStruct("bileizhen", damage.from, ask_who, damage.damage, sgs.DamageStruct_Thunder)
                room:damage(new_damage)
                return true
            else
                damage.damage = 0
                data:setValue(damage)
                return true
            end
        elseif event == sgs.Damaged and damage.to:objectName() == ask_who:objectName() then --自己受到伤害后
            local choice = room:askForChoice(ask_who, self:objectName(), "recover+draw+play") 
            if choice == "recover" then 
                local recover = sgs.RecoverStruct()  
                recover.who = ask_who  
                recover.recover = 1  
                room:recover(ask_who, recover)  
            elseif choice == "draw" then
                --[[
                local phases = sgs.PhaseList()
                phases:append(sgs.Player_Draw)
                --phases:append(sgs.Player_NotActive)
                ask_who:play(phases)
                ]]
                room:drawCards(ask_who, 2)  
            elseif choice == "play" then
                local phases = sgs.PhaseList()
                phases:append(sgs.Player_Play)
                phases:append(sgs.Player_NotActive)
                ask_who:play(phases)  
            end
        end
        return false -- 返回true阻止雷电伤害  
    end  
}

zhenkongzhao = sgs.CreateArmor{  
    name = "ZhenKongZhao",  
    class_name = "ZhenKongZhao",   
    suit = sgs.Card_Heart,  
    number = 2,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "ZhenKongZhao", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "ZhenKongZhao", true, false, true)  
    end  
}

zhenkongzhaoSkill = sgs.CreateTriggerSkill{  
    name = "ZhenKongZhao",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("ZhenKongZhao")) then  
            return ""  
        end  
        local damage = data:toDamage()  
        if damage.nature ~= sgs.DamageStruct_Normal then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 记录日志  
        local log = sgs.LogMessage()  
        log.type = "#ZhenKongZhaoNatureDamage"  
        log.from = damage.from  
        log.to:append(damage.to)  
        log.arg = tostring(damage.damage)  
          
        local nature_name = "normal_nature"  
        if damage.nature == sgs.DamageStruct_Fire then  
            nature_name = "fire_nature"  
        elseif damage.nature == sgs.DamageStruct_Thunder then  
            nature_name = "thunder_nature"  
        end  
        log.arg2 = nature_name  
          
        room:sendLog(log)  
        --room:setEmotion(damage.to, "armor/zhenkongzhao")  
          
        -- 将属性伤害转换为无属性伤害  
        damage.nature = sgs.DamageStruct_Normal  
        data:setValue(damage)  
          
        return false -- 不阻止伤害，继续伤害流程  
    end  
}

yinleijian = sgs.CreateWeapon{  
    name = "YinLeiJian",  
    class_name = "YinLeiJian",  
    suit = sgs.Card_Spade,  
    number = 2,  
    range = 4,
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "YinLeiJian", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "YinLeiJian", true, false, true)  
    end  
}  
  
-- 引雷剑技能实现  
--[[
yinleijianSkill = sgs.CreateOneCardViewAsSkill{  
    name = "YinLeiJian",  
    filter_pattern = "%slash",  
    response_or_use = true,  
      
    enabled_at_play = function(self, player)  
        return sgs.Slash_IsAvailable(player) and player:getMark("Equips_Nullified_to_Yourself") == 0  
    end,  
      
    enabled_at_response = function(self, player, pattern)  
        return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE  
            and pattern == "slash" and player:getMark("Equips_Nullified_to_Yourself") == 0  
    end,  
      
    view_as = function(self, originalCard)  
        local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", originalCard:getSuit(), originalCard:getNumber())  
        thunder_slash:addSubcard(originalCard:getId())  
        thunder_slash:setSkillName("YinLeiJian")  
        return thunder_slash  
    end  
}  
]]

yinleijianSkill = sgs.CreateTriggerSkill{  
    name = "YinLeiJian",  
    events = {sgs.CardUsed},  
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local weapon = player:getWeapon()
            if not (weapon and weapon:isKindOf("YinLeiJian")) then return "" end
            local use = data:toCardUse()  
            if use.card and use.card:isKindOf("Slash") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local originalCard = use.card
        local new_card = sgs.Sanguosha:cloneCard("thunder_slash", originalCard:getSuit(), originalCard:getNumber())
        new_card:addSubcard(originalCard:getId()) 
        use.card = new_card
        data:setValue(use)
        return false  
    end  
}  

baiBaoXiang = sgs.CreateTreasure{  
    name = "baiBaoXiang",  
    class_name = "baiBaoXiang",  
    suit = sgs.Card_Heart,  
    number = 2,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "baibaoxiang", true, true) 
        room:acquireSkill(player, "baibaoxiang_trigger", true, true)          
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        local pile_cards = player:getPile("baibaoxiang")              
        -- 将牌堆转换为Lua表  
        for _, id in sgs.qlist(pile_cards) do  
            room:throwCard(id,player,player)
        end  
        room:detachSkillFromPlayer(player, "baibaoxiang", true, false, true)  
        room:detachSkillFromPlayer(player, "baibaoxiang_trigger", true, false, true)  
    end  
}

-- 百宝箱存储技能卡  
baibaoxiangStoreCard = sgs.CreateSkillCard{  
    name = "BaibaoxiangStoreCard",  
    target_fixed = true,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
    on_use = function(self, room, source, targets)  
        source:addToPile("baibaoxiang", self:getSubcards())  
    end  
}  
  
-- 百宝箱取出技能卡  
baibaoxiangRetrieveCard = sgs.CreateSkillCard{  
    name = "BaibaoxiangRetrieveCard",  
    target_fixed = true,  
    will_throw = false,  
    handling_method = sgs.Card_MethodNone,  
    on_use = function(self, room, source, targets)  
        local card_id = self:getSubcards():first()  
        local card = sgs.Sanguosha:getCard(card_id)  
        local player = source

        local old_equip = nil  
        if card:isKindOf("Weapon") then  
            old_equip = player:getWeapon()  
        elseif card:isKindOf("Armor") then  
            old_equip = player:getArmor()  
        elseif card:isKindOf("DefensiveHorse") then  
            old_equip = player:getDefensiveHorse()  
        elseif card:isKindOf("OffensiveHorse") then  
            old_equip = player:getOffensiveHorse()  
        elseif card:isKindOf("Treasure") then  
            old_equip = player:getTreasure()  
        end  
        if old_equip then  
            local old_equip_id = old_equip:getEffectiveId()
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), target:objectName(), self:objectName()) 
            player:addToPile("baibaoxiang", old_equip)--, true, sgs.SPlayerList(), reason)  
        end 
        room:useCard(sgs.CardUseStruct(card, player, player), false)     
        --[[
        if card then  
            local location = card:location()  
            local existing_equip = source:getEquip(location)  
            if existing_equip then  
                source:addToPile("baibaoxiang", existing_equip)  
            end
            room:useCard(sgs.CardUseStruct(card, source, source), false)     
        end  
        ]]
    end  
}  
  
-- 百宝箱主动技能（出牌阶段使用）  
baibaoxiang = sgs.CreateViewAsSkill{  
    name = "baibaoxiang",  
    n = 1,  
    expand_pile = "baibaoxiang",  
    view_filter = function(self, selected, to_select)  
        if #selected >= 1 or to_select:hasFlag("using") then return false end  
          
        -- 可以选择手牌/装备区的装备放入百宝箱  
        if to_select:isKindOf("EquipCard") then  
            return true  
        end  
          
        -- 可以选择百宝箱中的装备取出  
        local pat = ".|.|.|baibaoxiang"  
        return sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = cards[1]  
              
            -- 如果选择的是百宝箱中的牌，创建取出技能卡  
            if sgs.Self:getPile("baibaoxiang"):contains(card:getEffectiveId()) then  
                --[[
                local retrieve_card = baibaoxiangRetrieveCard:clone()  
                retrieve_card:addSubcard(card)  
                retrieve_card:setSkillName("baibaoxiang")  
                return retrieve_card  
                ]]
                return card
            else  
                -- 否则创建存储技能卡  
                local store_card = baibaoxiangStoreCard:clone()  
                store_card:addSubcard(card)  
                store_card:setSkillName("baibaoxiang")  
                return store_card  
            end  
        end  
    end,  
    enabled_at_play = function(self, player)  
        -- 有装备可以存储，或者百宝箱中有装备可以取出  
        return true--not player:getCards("he"):isEmpty() or not player:getPile("baibaoxiang"):isEmpty()  
    end  
}  
  
-- 百宝箱触发技能（被指定为目标时）  
baibaoxiangTrigger = sgs.CreateTriggerSkill{  
    name = "baibaoxiang_trigger",  
    events = {sgs.TargetConfirmed},  --sgs.TargetConfirmed
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill("baibaoxiang") then  
            local use = data:toCardUse()  
            if use.from~=player and use.to:contains(player) and not player:getPile("baibaoxiang"):isEmpty() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  

        --收回一张
        if player:getCardCount(true)-player:getCardCount(false) > 1 then --不能只有百宝箱
            local retrive_id = room:askForCardChosen(player, player, "e", self:objectName(), true, sgs.Card_MethodNone)
            retrieve_card = sgs.Sanguosha:getCard(retrive_id)
            if not retrieve_card:isKindOf("baiBaoXiang") then
                player:addToPile("baibaoxiang", retrive_id)  
            end
        end

        local pile_cards = player:getPile("baibaoxiang")  
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
        local card_id = room:askForAG(player, card_ids, true, "baibaoxiang")  
        room:clearAG(player) 
        if card_id == nil then return false end
        local equip = sgs.Sanguosha:getCard(card_id)
        if equip == nil then return false end
        room:obtainCard(player,card_id)
        local card = player:getHandcards():last() --最后一张手牌
        room:useCard(sgs.CardUseStruct(card, player, player), false)     
        --[[
        local old_equip = nil  
        if card:isKindOf("Weapon") then  
            old_equip = player:getWeapon()  
        elseif card:isKindOf("Armor") then  
            old_equip = player:getArmor()  
        elseif card:isKindOf("DefensiveHorse") then  
            old_equip = player:getDefensiveHorse()  
        elseif card:isKindOf("OffensiveHorse") then  
            old_equip = player:getOffensiveHorse()  
        elseif card:isKindOf("Treasure") then  
            old_equip = player:getTreasure()  
        else --不是装备
            return false
        end  
            
        if old_equip then  
            local old_equip_id = old_equip:getEffectiveId()
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), target:objectName(), self:objectName()) 
            player:addToPile("baibaoxiang", old_equip)--, true, sgs.SPlayerList(), reason)  
        end 
        room:useCard(sgs.CardUseStruct(card, player, player), false)   
        ]]  
        --[[
        if card then  
            local location = card:location()  
            local existing_equip = player:getEquip(location)  
            if existing_equip then  
                player:addToPile("baibaoxiang", existing_equip)  
            end
            room:useCard(sgs.CardUseStruct(card, player, player), false)     
        end
        ]]
        return false  
    end  
}  

yuansuzhiren = sgs.CreateWeapon{  
    name = "yuansuzhiren",  
    class_name = "yuansuzhiren",  
    suit = sgs.Card_Spade,  
    number = 1,  
    range = 4,
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "yuansuzhiren", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "yuansuzhiren", true, false, true)  
    end  
}  
yuansuzhirenSkill = sgs.CreateTriggerSkill{  
    name = "yuansuzhiren",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local weapon = player:getWeapon()
        if not (weapon and weapon:isKindOf("yuansuzhiren")) then  
            return ""  
        end  
        if player and player:isAlive() then  
            local damage = data:toDamage()  
            if not (damage.card and damage.card:isKindOf("Slash")) then return "" end
            -- 只有属性伤害才触发  
            if damage.nature == sgs.DamageStruct_Fire or damage.nature == sgs.DamageStruct_Thunder then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 锁定技，无需询问  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
          
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
          
        -- 发送日志信息  
        local log = sgs.LogMessage()  
        log.type = "#WeaponDamage"  
        log.from = player  
        log.arg = self:objectName()  
        log.arg2 = tostring(1)  
        room:sendLog(log)  
          
        return false  
    end  
}  


shengfan = sgs.CreateArmor{  
    name = "shengfan",  
    class_name = "shengfan",  
    suit = sgs.Card_Club,  
    number = 2,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "shengfan", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "shengfan", true, false, true)  
    end  
}  
--[[
shengfanVS = sgs.CreateViewAsSkill{
	name = "shengfan",
	response_pattern = "@@shengfanDiscard",
	view_filter = function(self, selected, to_select)
		return not to_select:objectName()~="shengfan"
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			return cards[1]
		end
	end,
}
]]
shengfanSkill = sgs.CreateTriggerSkill{  
    name = "shengfan",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,  
    --view_as_skill = shengfanVS,
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("shengfan")) then  
            return ""  
        end  
        if player and player:isAlive() then  
            -- 只在准备阶段触发。考虑改成任意角色的准备阶段，或者自己的每一个阶段
            if player:getPhase() == sgs.Player_Start and player:isWounded() and not player:isNude() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 锁定技，无需询问  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
        --弃一张牌
        --local is_discard = room:askForCard(player, ".", "@shengfan-discard", data, sgs.Card_MethodDiscard)  
        local is_discard = room:askForDiscard(player,self:objectName(),1,1,false,true)
        if not is_discard then return false end
        -- 回复1点体力  
        local recover = sgs.RecoverStruct()  
        recover.who = player  
        recover.recover = 1  
        room:recover(player, recover)  
          
        -- 发送日志信息  
        local log = sgs.LogMessage()  
        log.type = "#ArmorRecover"  
        log.from = player  
        log.arg = self:objectName()  
        log.arg2 = tostring(1)  
        room:sendLog(log)  
          
        return false  
    end  
}  

fantanjia = sgs.CreateArmor{  
    name = "fantanjia",  
    class_name = "fantanjia",  
    suit = sgs.Card_Diamond,  
    number = 3,  
      
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "fantanjia", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "fantanjia", true, false, true)  
    end  
}  
  
-- 反弹甲技能实现 - 伤害分摊  
fantanjiaSkill = sgs.CreateTriggerSkill{  
    name = "fantanjia",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("fantanjia")) then  
            return ""  
        end  
        if player and player:isAlive() and player:hasArmorEffect(self:objectName()) then  
            local damage = data:toDamage()  
            -- 只有当有伤害来源且伤害来源不是自己时才触发  
            if damage.from and damage.from ~= player and damage.from:isAlive() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 锁定技，无需询问  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
          
        local damage = data:toDamage()  
        local original_damage = damage.damage  
        local half_damage = math.ceil(original_damage / 2)  --向上取整
        local remaining_damage = original_damage - half_damage  --相当于向下取整
          
        -- 修改原始伤害为一半。half_damage，向上取整，自己承担的伤害更高；remaining_damage，向下取整，自己承担的伤害更低
        damage.damage = half_damage --remaining_damage  
        data:setValue(damage)  
        
        if remaining_damage > 0 then --否则会触发卖血技
            -- 对伤害来源造成另一半伤害  
            local reflect_damage = sgs.DamageStruct()  
            reflect_damage.from = player  --这里可以考虑改为 damage.from 或 nil
            reflect_damage.to = damage.from  
            reflect_damage.damage = remaining_damage --half_damage  
            reflect_damage.nature = damage.nature  
            reflect_damage.reason = self:objectName()  
            
            -- 发送日志信息  
            local log = sgs.LogMessage()  
            log.type = "#FantanJia"  
            log.from = player  
            log.to:append(damage.from)  
            log.arg = tostring(original_damage)  
            log.arg2 = tostring(half_damage)  
            room:sendLog(log)  
            
            -- 延迟造成反弹伤害，避免递归  
            room:damage(reflect_damage)  
        end
        return false  
    end  
}  

kuangzhanshi = sgs.CreateWeapon{  
    name = "kuangzhanshi",  
    class_name = "kuangzhanshi",  
    suit = sgs.Card_Heart,  
    number = 1,  
    range = 4,  
      
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "kuangzhanshi", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "kuangzhanshi", true, false, true)  
    end  
}  
  
-- 狂战士技能实现 - 失去体力增加伤害  
kuangzhanshiSkill = sgs.CreateTriggerSkill{  
    name = "kuangzhanshi",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Frequent,  
      
    can_trigger = function(self, event, room, player, data)  
        local weapon = player:getWeapon()
        if not (weapon and weapon:isKindOf("kuangzhanshi")) then  
            return ""  
        end  
        if player and player:isAlive() then  
            local damage = data:toDamage()  
            -- 只有当玩家可以失去体力时才触发  
            if player:getHp() > 1 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 询问玩家是否发动技能  
        local damage = data:toDamage()  
        local _data = sgs.QVariant()  
        _data:setValue(damage.to)  
          
        if player:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            -- 失去1点体力  
            room:loseHp(player, 1)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
          
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
          
        -- 发送日志信息  
        local log = sgs.LogMessage()  
        log.type = "#WeaponDamageBuff"  
        log.from = player  
        log.to:append(damage.to)  
        log.arg = self:objectName()  
        log.arg2 = tostring(1)  
        room:sendLog(log)  
          
        return false  
    end  
}  

axiuluo = sgs.CreateWeapon{  
    name = "axiuluo",  
    class_name = "axiuluo",  
    suit = sgs.Card_Spade,  
    number = 1,  
    range = 4,  
      
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "axiuluo", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "axiuluo", true, false, true)  
    end  
}  
  
-- 阿修罗技能实现 - 判定修改伤害  
axiuluoSkill = sgs.CreateTriggerSkill{  
    name = "axiuluo",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_NotFrequent,  
      
    can_trigger = function(self, event, room, player, data)  
        local weapon = player:getWeapon()
        if not (weapon and weapon:isKindOf("axiuluo")) then  
            return ""  
        end  
        if player and player:isAlive() then  
            local damage = data:toDamage()  
            -- 只要造成伤害就可以触发  
            if damage.to and damage.to ~= player then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        -- 询问玩家是否发动技能  
        local damage = data:toDamage()  
        local _data = sgs.QVariant()  
        _data:setValue(damage.to)  
          
        if player:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        room:notifySkillInvoked(player, self:objectName())  
          
        -- 进行判定  
        local judge = sgs.JudgeStruct()  
        judge.good = true  
        judge.play_animation = false  
        judge.reason = self:objectName()  
        judge.who = player  
          
        room:judge(judge)  
          
        local damage = data:toDamage()  
        local original_damage = damage.damage  
          
        -- 根据判定结果修改伤害  
        if judge.card:isRed() then  
            -- 红色判定牌，伤害+1  
            damage.damage = damage.damage + 1  
        else  
            -- 黑色判定牌，伤害-1  
            damage.damage = damage.damage - 1
        end  
          
        data:setValue(damage)  
        if damage.damage <= 0 then
            return true
        end
        return false  
    end  
} 


shenmishouhu = sgs.CreateArmor{  
    name = "shenmishouhu",  
    class_name = "shenmishouhu",  
    suit = sgs.Card_Heart,  
    number = 3,  
      
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "shenmishouhu", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "shenmishouhu", true, false, true)  
    end  
}  
shenmishouhuSkill = sgs.CreateTriggerSkill{  
    name = "shenmishouhu",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("shenmishouhu")) then  
            return ""  
        end  
        if player and player:isAlive() then  
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
        return true
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

QiyiShouhu = sgs.CreateArmor{  
    name = "QiyiShouhu",
    class_name = "QiyiShouhu",  
    suit = sgs.Card_Club,  
    number = 2,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "QiyiShouhu", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "QiyiShouhu", true, false, true)  
    end  
}  
  
-- 奇异守护技能  
QiyiShouhuSkill = sgs.CreateTriggerSkill{  
    name = "QiyiShouhu",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("QiyiShouhu")) then  
            return ""  
        end  
          
        local damage = data:toDamage()  
        -- 只有当伤害不是由牌造成时才触发 
        if damage.card then --普通卡，不免伤
            return "" 
        end
        if not damage.card then  --没有卡；有卡，但是是技能卡
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 显示防具效果日志  
        local log = sgs.LogMessage()  
        log.type = "#ArmorNullify"  
        log.from = player  
        log.arg = self:objectName()  
        log.arg2 = damage.reason or "skill_damage"  
        room:sendLog(log)  
          
        -- 播放防具音效  
        --room:setEmotion(player, "armor/" .. string.lower(self:objectName()))  
          
        -- 防止伤害  
        return true  
    end  
}  

xinlingganying = sgs.CreateArmor{  
    name = "xinlingganying",
    class_name = "xinlingganying",  
    suit = sgs.Card_Club,  
    number = 2,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "xinlingganying", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "xinlingganying", true, false, true)  
    end  
}  
  
-- 奇异守护技能  
xinlingganyingSkill = sgs.CreateTriggerSkill{  
    name = "xinlingganying",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
      
    can_trigger = function(self, event, room, player, data)  
        local armor = player:getArmor()
        if not (armor and armor:isKindOf("xinlingganying")) then  
            return ""  
        end  
          
        local damage = data:toDamage()  
        if damage.from and damage.from:isFriendWith(player) then  --没有卡；有卡，但是是技能卡
            return self:objectName()  
        end  
          
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true -- 锁定技，无需询问  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 显示防具效果日志  
        local log = sgs.LogMessage()  
        log.type = "#ArmorNullify"  
        log.from = player  
        log.arg = self:objectName()  
        log.arg2 = damage.reason or "skill_damage"  
        room:sendLog(log)  
          
        -- 播放防具音效  
        --room:setEmotion(player, "armor/" .. string.lower(self:objectName()))  
          
        -- 防止伤害  
        return true  
    end  
}  

ZhiyuZhijian = sgs.CreateWeapon{  
    name = "ZhiyuZhijian",  
    class_name = "ZhiyuZhijian",
    suit = sgs.Card_Heart,  
    number = 1,  
    range = 2,  
    on_install = function(self, player)  
        local room = player:getRoom()  
        room:acquireSkill(player, "ZhiyuZhijian", true, true)  
    end,  
      
    on_uninstall = function(self, player)  
        local room = player:getRoom()  
        room:detachSkillFromPlayer(player, "ZhiyuZhijian", true, false, true)  
    end  
}  
  
-- 治愈之剑技能  
ZhiyuZhijianSkill = sgs.CreateTriggerSkill{  
    name = "ZhiyuZhijian",  
    events = {sgs.DamageInflicted},  
      
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage() 
        if damage.from and damage.from:getWeapon() and damage.from:getWeapon():isKindOf("ZhiyuZhijian")  then  
            return self:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.from then  
            return damage.from:askForSkillInvoke(self:objectName(), data)  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 创建恢复结构体  
        local recover = sgs.RecoverStruct()  
        recover.recover = damage.damage  
        recover.who = damage.from  
          
        -- 执行恢复  
        room:recover(damage.to, recover)  
          
        -- 防止原伤害  
        return true  
    end  
}  
-- 将防具牌添加到扩展包
qiankundai:setParent(extension)
shixuejian:setParent(extension)
anshajian:setParent(extension)
--jinxiuzhengpao:setParent(extension)  --放到二代君包

xiuliQiankun:setParent(extension)  --通过
bileizhen:setParent(extension)
--zhenkongzhao:setParent(extension) --通过。但是太弱，在这个包里意义不明，可以考虑放到pokemon包
yinleijian:setParent(extension)
--baiBaoXiang:setParent(extension)

yuansuzhiren:setParent(extension) --通过
shengfan:setParent(extension) --通过
fantanjia:setParent(extension) --通过
kuangzhanshi:setParent(extension) --通过
--axiuluo:setParent(extension) --通过。但是不稳定，几乎不会用
--shenmishouhu:setParent(extension) --通过。但是太强，作为pokemon的技能比较合适

QiyiShouhu:setParent(extension)
--xinlingganying:setParent(extension) --用的不多
--ZhiyuZhijian:setParent(extension) --用的不多

if not sgs.Sanguosha:getSkill("qiankundai_maxcards") then
    skills:append(qiankundai_maxcards)
end
if not sgs.Sanguosha:getSkill("shixuejian_recover") then
    skills:append(shixuejian_skill)
end
if not sgs.Sanguosha:getSkill("anshajian_loseHp") then
    skills:append(anshajian_skill)
end
--[[
--放到二代君包
if not sgs.Sanguosha:getSkill("jinxiuzhengpao") then
    skills:append(jinxiuzhengpao_skill)
end
]]
if not sgs.Sanguosha:getSkill("Bileizhen") then
    skills:append(bileizhenSkill)
end
if not sgs.Sanguosha:getSkill("XiuliQiankun") then
    skills:append(xiuliQiankunSkill)
end
if not sgs.Sanguosha:getSkill("YinLeiJian") then
    skills:append(yinleijianSkill)
end
if not sgs.Sanguosha:getSkill("yuansuzhiren") then
    skills:append(yuansuzhirenSkill)
end
if not sgs.Sanguosha:getSkill("shengfan") then
    skills:append(shengfanSkill)
end
if not sgs.Sanguosha:getSkill("fantanjia") then
    skills:append(fantanjiaSkill)
end
if not sgs.Sanguosha:getSkill("kuangzhanshi") then
    skills:append(kuangzhanshiSkill)
end
if not sgs.Sanguosha:getSkill("QiyiShouhu") then
    skills:append(QiyiShouhuSkill)
end
sgs.Sanguosha:addSkills(skills)
--[[
skills:append(qiankundai_maxcards)
skills:append(shixuejian_skill)
skills:append(anshajian_skill)
skills:append(jinxiuzhengpao_skill)
skills:append(bileizhenSkill)
skills:append(xiuliQiankunSkill)
--skills:append(zhenkongzhaoSkill)
skills:append(yinleijianSkill)
--skills:append(baibaoxiang)
--skills:append(baibaoxiangTrigger)
skills:append(yuansuzhirenSkill)
skills:append(shengfanSkill)
skills:append(fantanjiaSkill)
skills:append(kuangzhanshiSkill)
--skills:append(axiuluoSkill)
--skills:append(shenmishouhuSkill)
skills:append(QiyiShouhuSkill)
--skills:append(xinlingganyingSkill)
--skills:append(ZhiyuZhijianSkill)

sgs.Sanguosha:addSkills(skills)
]]
--[[
--用来绑定装备技能的临时武将。extension是个卡牌包，不是武将包
equip_tmp = sgs.General(extension,"equip_tmp","god",4)
equip_tmp:addSkill(qiankundai_maxcards)
equip_tmp:addSkill(shixuejian_skill)
equip_tmp:addSkill(anshajian_skill)
equip_tmp:addSkill(jinxiuzhengpao_skill)

equip_tmp:addSkill(bileizhenSkill)
equip_tmp:addSkill(xiuliQiankunSkill)
--equip_tmp:addSkill(zhenkongzhaoSkill)
equip_tmp:addSkill(yinleijianSkill)
--equip_tmp:addSkill(baibaoxiang)
--equip_tmp:addSkill(baibaoxiangTrigger)

equip_tmp:addSkill(yuansuzhirenSkill)
equip_tmp:addSkill(shengfanSkill)
equip_tmp:addSkill(fantanjiaSkill)
equip_tmp:addSkill(kuangzhanshiSkill)
--equip_tmp:addSkill(axiuluoSkill)
--equip_tmp:addSkill(shenmishouhuSkill)

equip_tmp:addSkill(QiyiShouhuSkill)
--equip_tmp:addSkill(xinlingganyingSkill)
--equip_tmp:addSkill(ZhiyuZhijianSkill)
]]
-- 添加翻译  
sgs.LoadTranslationTable{  
    ["equip"] = "装备",  
    ["qiankundai"] = "乾坤袋",  
    [":qiankundai"] = "装备牌·防具\n\n技能：你的手牌上限+1；当你失去装备区里的【乾坤袋】后，你摸一张牌。",  
    ["qiankundai_maxcards"] = "乾坤袋",  
    [":qiankundai_maxcards"] = "你的手牌上限+1；当你失去装备区里的【乾坤袋】后，你摸一张牌。",  

    ["shixuejian"] = "嗜血剑",  
    [":shixuejian"] = "装备牌·武器\n\n攻击范围：2\n技能：每当你使用【杀】造成伤害后，你回复1点体力。",  
    ["shixuejian_recover"] = "嗜血剑",  
    [":shixuejian_recover"] = "每当你使用【杀】造成伤害后，你回复1点体力。",

    ["anshajian"] = "暗杀剑",  
    [":anshajian"] = "装备牌·武器\n\n攻击范围：2\n技能：你可以令你使用【杀】造成的伤害改为令目标失去等量的体力。",  
    ["anshajian_loseHp"] = "暗杀剑",  
    [":anshajian_loseHp"] = "你可以令你使用【杀】造成的伤害改为令目标失去等量的体力。",

    ["jinxiuzhengpao"] = "锦绣征袍",  
    [":jinxiuzhengpao"] = "装备牌·防具\n\n技能：当你受到牌的伤害时，若你手牌中没有此花色的牌，你可以展示所有手牌并获得该牌，然后若你手牌包含所有花色，你免疫该牌的伤害。",  
    ["jinxiuzhengpao_skill"] = "锦绣征袍",  
    [":jinxiuzhengpao_skill"] = "当你受到牌的伤害时，若你手牌中没有此花色的牌，你可以展示所有手牌并获得该牌，然后若你手牌包含所有花色，你免疫该牌的伤害。",  
    ["@jinxiuzhengpao"] = "你可以发动【锦绣征袍】，展示所有手牌并获得 %arg 的 %arg2",  
    ["#JinxiuZhengpaoNullify"] = "%from 的【%arg】效果被触发，免疫了此次伤害",

    ["XiuliQiankun"] = "袖里乾坤",  
    [":XiuliQiankun"] = "装备牌·防具\n\n技能：锁定技，你不会成为延时锦囊的目标；当延时性锦囊生效时，取消之；当你被叠置时，你平置。",

    ["Bileizhen"] = "避雷针",  
    [":Bileizhen"] = "装备牌·防具\n\n技能：\
                    任意角色受到雷属性伤害时，若其不为你，你可以选择将该伤害转移给自己；若其为你，你可以免疫此伤害\
                    当你受到雷属性伤害后，你可以选择（1）恢复1点体力（2）摸2张牌（3）获得一个出牌阶段",
    ["@bileizhen-attrack"] = "是否将本次雷属性伤害转移到自己身上",
    ["@bileizhen-immuse"] = "是否免疫此次雷属性伤害",
    ["@bileizhen-effect"] = "是否引动避雷针的蓄电/电力引擎效果，选择恢复/摸牌/出牌",

    ["ZhenKongZhao"] = "真空罩",  
    [":ZhenKongZhao"] = "装备牌·防具\n\n技能：锁定技，每当你受到属性伤害时，你将此伤害视为无属性伤害。",  
    ["#ZhenKongZhaoNatureDamage"] = "%from 对 %to 造成的 %arg 点%arg2被【真空罩】转换为无属性伤害",  

    ["YinLeiJian"] = "引雷剑",  
    [":YinLeiJian"] = "装备牌·武器\n\n攻击范围：4\n技能：你可以将一张普通【杀】当雷【杀】使用",  
    ["yinleijian"] = "引雷剑",

    ["baiBaoXiang"] = "百宝箱",
    [":baiBaoXiang"] = "装备牌·宝物\n\n技能：出牌阶段，你可以将一张装备放进“百宝箱”牌堆，或者从“百宝箱”中将一张装备放入装备区；当你被其他角色指定为目标时，你可以将装备区的一张非百宝箱装备放入“百宝箱”，并可以将“百宝箱”中的一张装备放入装备区",

    ["yuansuzhiren"] = "元素之刃",  
    [":yuansuzhiren"] = "装备牌·武器\n\n攻击范围：4\n技能：锁定技，你的属性杀伤害+1。",  
    ["#WeaponDamage"] = "%from 的【%arg】效果被触发，伤害+%arg2",

    ["shengfan"] = "剩饭",  
    [":shengfan"] = "装备牌·防具\n\n技能：锁定技，准备阶段，你可以弃置一张牌，回复1点体力。",  
    ["#ArmorRecover"] = "%from 的【%arg】效果被触发，回复了%arg2点体力",

    ["fantanjia"] = "反弹甲",  
    [":fantanjia"] = "装备牌·防具\n\n技能：锁定技，当你受到伤害时，你和伤害来源各承担一半伤害（你受到的伤害向上取整）。",  
    ["#FantanJia"] = "%from 的【反弹甲】效果被触发，将 %arg 点伤害分摊，对 %to 造成 %arg2 点伤害",

    ["kuangzhanshi"] = "狂战士",  
    [":kuangzhanshi"] = "装备牌·武器\n\n攻击范围：4\n技能：当你造成伤害时，若你的体力值大于1，你可以失去1点体力，令此伤害+1。",  
    ["#WeaponDamageBuff"] = "%from 的【%arg】效果被触发，对 %to 的伤害+%arg2",  
    ["@kuangzhanshi"] = "你可以失去1点体力，令此伤害+1",

    ["axiuluo"] = "阿修罗",  
    [":axiuluo"] = "装备牌·武器\n\n攻击范围：4\n技能：当你造成伤害时，你可以进行一次判定。若判定牌为红色，此伤害+1；若判定牌为黑色，此伤害-1。",  
    ["#WeaponJudgeGood"] = "%from 的【%arg】判定为%arg2色，伤害从%arg3点增加到%arg4点",  
    ["#WeaponJudgeBad"] = "%from 的【%arg】判定为%arg2色，伤害从%arg3点减少到%arg4点",  
    ["@axiuluo"] = "你可以进行一次判定来修改此次伤害",

    ["shenmishouhu"] = "神秘守护",  
    [":shenmishouhu"] = "装备牌·防具\n\n技能：锁定技，你不会受到普通伤害",  

    ["QiyiShouhu"] = "奇异守护",  
    [":QiyiShouhu"] = "装备牌·防具\n\n技能：锁定技，你只会受到牌的伤害",  
    ["#ArmorNullify"] = "%from 的防具【<font color=\"yellow\"><b>%arg</b></font>】效果被触发，防止了来自 %arg2 的伤害",  

    ["xinlingganying"] = "心灵感应",  
    [":xinlingganying"] = "装备牌·防具\n\n技能：锁定技，你不会受到势力相同角色的伤害",  
    ["#ArmorNullify"] = "%from 的防具【<font color=\"yellow\"><b>%arg</b></font>】效果被触发，防止了来自 %arg2 的伤害",  

    ["ZhiyuZhijian"] = "治愈之剑",  
    [":ZhiyuZhijian"] = "装备牌·武器\n\n攻击范围：2\n\n技能：当你造成伤害时，你可以防止此伤害，改为令目标角色回复等量的体力。",  
    ["#ZhiyuZhijian"] = "%from 的武器【<font color=\"yellow\"><b>治愈之剑</b></font>】效果被触发，将 %arg 点伤害转换为体力恢复",  

}  
  
-- 返回扩展包  
return {extension}