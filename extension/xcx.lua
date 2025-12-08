extension = sgs.Package("xcx", sgs.Package_GeneralPack)  
local skills = sgs.SkillList()

-- 创建武将蒙恬  
bianfuren_xcx = sgs.General(extension, "bianfuren_xcx", "wei", 3, false) -- 蜀势力，4血，男性（默认）  

wanwaiDrawCard = sgs.CreateSkillCard{  
    name = "wanwaiDrawCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local cards = self:getSubcards()  
        local card_num = cards:length()  
          
        if card_num > 0 then  
            -- 令目标摸等量的牌  
            room:drawCards(target, card_num, "wanwaiDraw")  
              
            -- 检查弃置的牌类别是否各不相同  
            local types = {}  
            local all_different = true  
              
            for _, id in sgs.qlist(cards) do  
                local card = sgs.Sanguosha:getCard(id)  
                local card_type = card:getTypeId()  
                if types[card_type] then  
                    all_different = false  
                    break  
                else  
                    types[card_type] = true  
                end  
            end  
              
            -- 若类别各不相同，目标恢复1点体力  
            if all_different then  
                local recover = sgs.RecoverStruct()  
                recover.who = source  
                recover.recover = 1  
                room:recover(target, recover)  
            end  
        end  
    end  
}  
  
-- 挽危视为技  
wanwaiDraw = sgs.CreateViewAsSkill{  
    name = "wanwaiDraw",  
    view_filter = function(self, selected, to_select)  
        return #selected < 3  
    end,  
    view_as = function(self, cards)  
        if #cards > 0 and #cards <= 3 then  
            local skill_card = wanwaiDrawCard:clone()  
            for _, card in ipairs(cards) do  
                skill_card:addSubcard(card:getEffectiveId())  
            end  
            skill_card:setSkillName(self:objectName())  
            skill_card:setShowSkill(self:objectName())  
            return skill_card  
        end  
        return nil  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#wanwaiDrawCard") and not player:isKongcheng()  
    end  
}  

yuejianDraw = sgs.CreateTriggerSkill{  
    name = "yuejianDraw",  
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
           and player:getPhase() == sgs.Player_Finish then  
            local current_handcards = player:getHandcardNum()  
            local max_hp = player:getMaxHp()  
            if current_handcards < max_hp then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local current_handcards = player:getHandcardNum()  
        local max_hp = player:getMaxHp()  
        local need_draw = max_hp - current_handcards  
          
        if need_draw > 0 then  
            room:drawCards(player, need_draw, self:objectName())  
        end  
        return false  
    end  
}

bianfuren_xcx:addSkill(wanwaiDraw)  
bianfuren_xcx:addSkill(yuejianDraw)  
sgs.LoadTranslationTable{
    ["xcx"] = "小程序",
    ["bianfuren_xcx"] = "卞夫人",  
    ["#bianfuren_xcx"] = "武宣皇后",  
    ["wanwaiDraw"] = "挽危",  
    [":wanwaiDraw"] = "出牌阶段限一次，你可以弃置至多三张手牌，令一名其他角色摸等量的牌，若弃置的牌类别各不相同，其恢复1点体力。",  
    ["yuejianDraw"] = "约俭",  
    [":yuejianDraw"] = "结束阶段，你可以将手牌摸至体力上限。"  
}

caozhang_xcx = sgs.General(extension, "caozhang_xcx", "wei", 4) -- 蜀势力，4血，男性（默认）  

JiangChi = sgs.CreateTriggerSkill{  
    name = "jiangchi",  
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
           and player:getPhase() == sgs.Player_Play then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local choices = {"jiangchi_draw3", "jiangchi_draw1", "jiangchi_slash", "cancel"}  
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)  
        if choice ~= "cancel" then  
            room:setPlayerMark(player, "jiangchi_choice", choice == "jiangchi_draw3" and 1 or (choice == "jiangchi_draw1" and 2 or 3))  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local choice = player:getMark("jiangchi_choice")  
        room:setPlayerMark(player, "jiangchi_choice", 0)  
          
        if choice == 1 then  
            -- 选择1：摸3张牌，本回合不能使用杀  
            room:drawCards(player, 3, self:objectName())  
            room:setPlayerCardLimitation(player, "use", "Slash", true) 
        elseif choice == 2 then  
            -- 选择2：摸1张牌，本回合获得狂骨  
            room:drawCards(player, 1, self:objectName())  
            room:setPlayerFlag(player, "jiangchi_damage")  
            room:acquireSkill(player, "jiangchiDamage")  
        elseif choice == 3 then  
            -- 选择3：本回合使用杀次数+1，且无距离限制  
            room:setPlayerFlag(player, "jiangchi_slash_extra")  
            room:setPlayerFlag(player, "jiangchi_no_distance")  
        end  
        return false  
    end  
}
  
-- 临时狂骨技能  
JiangChiDamage = sgs.CreateTriggerSkill{  
    name = "jiangchiDamage",  
    events = {sgs.Damage},  
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.from and damage.from:hasFlag("jiangchi_damage") and damage.from:objectName() == player:objectName() then  
            return self:objectName()  
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
  
-- 杀次数修改技能  
JiangChiTargetMod = sgs.CreateTargetModSkill{  
    name = "#jiangchi_targetmod",  
    pattern = "Slash",  
    residue_func = function(self, from, card)  
        if from:hasFlag("jiangchi_slash_extra") then  
            return 1  
        end  
        return 0  
    end,  
    distance_limit_func = function(self, from, card)  
        if from:hasFlag("jiangchi_no_distance") then  
            return 1000  
        end  
        return 0  
    end  
}  
  
-- 回合结束时清理标记  
JiangChiClear = sgs.CreateTriggerSkill{  
    name = "#jiangchi_clear",  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() == sgs.Player_Finish then  
            if player:hasFlag("jiangchi_damage") or player:hasFlag("jiangchi_slash_extra") or player:hasFlag("jiangchi_no_distance") then  
                return "jiangchi_clear"  
            end  
        end  
        return ""  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 清理所有标记  
        room:setPlayerFlag(player, "-jiangchi_slash_extra")  
        room:setPlayerFlag(player, "-jiangchi_no_distance")  
          
        if player:hasFlag("jiangchi_damage") then  
            room:setPlayerFlag(player, "-jiangchi_damage")  
            room:detachSkillFromPlayer(player, "jiangchiDamage")  
        end  
        return false  
    end  
}
caozhang_xcx:addSkill(JiangChi)  
--caozhang_xcx:addSkill(JiangChiDamage)  
caozhang_xcx:addSkill(JiangChiTargetMod)  
caozhang_xcx:addSkill(JiangChiClear)  
  
-- 关联技能  
sgs.insertRelatedSkills(extension, "jiangchi", "#jiangchi_targetmod", "#jiangchi_clear")
if not sgs.Sanguosha:getSkill("jiangchiDamage") then
    skills:append(JiangChiDamage)
end
sgs.LoadTranslationTable{
    ["caozhang_xcx"] = "曹彰",  
    ["#caozhang_xcx"] = "黄须儿",  
    ["jiangchi"] = "将驰",  
    [":jiangchi"] = "出牌阶段开始时，你可以选择一项：1.摸三张牌，本回合不能使用【杀】；2.摸一张牌，本回合你造成伤害后摸一张牌；3.本回合使用【杀】的次数上限+1且无距离限制。",  
    ["jiangchi_draw3"] = "摸三张牌，本回合不能使用杀",  
    ["jiangchi_draw1"] = "摸一张牌，本回合造成伤害后摸1张牌",  
    ["jiangchi_slash"] = "本回合使用杀次数+1且无距离限制",  
    ["jiangchiDamage"] = "将驰-摸",  
    [":jiangchiDamage"] = "你造成伤害后摸一张牌", 
}

mou_huangyueying = sgs.General(extension, "mou_huangyueying", "shu", 3, false) -- 蜀势力，4血，男性（默认）  

lizi = sgs.CreateTriggerSkill{  
    name = "lizi",  
    events = {sgs.EventPhaseStart, sgs.Damaged},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseStart then  
            if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then  
                if not player:isNude() then  
                    return self:objectName()  
                end  
            end  
        elseif event == sgs.Damaged then  
            if not player:isNude() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if room:askForSkillInvoke(player, self:objectName(), data) then  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)            
        -- 选择要转换的手牌  
        local to_use = room:askForCard(player, ".", "@lizi-card", sgs.QVariant(), sgs.Card_MethodNone)  
        if not to_use then return false end  

        -- 选择要转换的牌类型  
        local patterns = {"ex_nihilo", "snatch", "dismantlement", "iron_chain"}  
        local choices = {}  
        for _, pattern in ipairs(patterns) do  
            table.insert(choices, pattern)  
        end  
          
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
        if choice == "" then return false end  

        -- 创建转换后的牌  
        local new_card = sgs.Sanguosha:cloneCard(choice)  
        new_card:addSubcard(to_use:getId())  
        new_card:setSkillName(self:objectName())  
        new_card:setShowSkill(self:objectName())  
        new_card:deleteLater()
        -- 使用转换后的牌  
        local use = sgs.CardUseStruct()  
        use.card = new_card  
        use.from = player  
          
        -- 根据牌的类型设置目标  
        if choice == "ex_nihilo" then  
            use.to:append(player)  
        elseif choice == "snatch" then 
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if player:distanceTo(p)<=1 then  
                    targets:append(p)  
                end  
            end  
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@lizi-dismantlement", false, true)  
            use.to:append(target)
        elseif choice == "dismantlement" then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@lizi-dismantlement", false, true)  
            use.to:append(target)
        elseif choice == "iron_chain" then
            -- 对于需要目标的牌，让玩家选择目标  
            local targets = room:askForPlayersChosen(player,  room:getAllPlayers(), self:objectName(), 1, 2, "@lizi-iron", true)  
            for _,target in sgs.qlist(targets) do
                use.to:append(target)
            end
        end  
          
        room:useCard(use, false)  
        return false  
    end  
}

yacai = sgs.CreateTriggerSkill{  
    name = "yacai",  
    events = {sgs.CardUsed},  
    can_trigger = function(self, event, room, player, data)  
        -- 查找拥有亚才技能的角色  
        local yacai_owner = room:findPlayerBySkillName(self:objectName()) 
        if not (yacai_owner and yacai_owner:isAlive() and yacai_owner:hasSkill(self:objectName()) 
            and not yacai_owner:hasFlag("yacai_used") and not yacai_owner:isKongcheng()) then 
                return "" 
        end
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            if use.card:isKindOf("BasicCard") then  
                room:setPlayerFlag(yacai_owner, "yacai_used")  
                return self:objectName(), yacai_owner:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()            
        if ask_who:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), ask_who)  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local use = data:toCardUse()  
          
        -- 技能拥有者重铸一张牌  
        local to_recast = room:askForCard(ask_who, ".", "@yacai-recast", sgs.QVariant(), sgs.Card_MethodDiscard)  
        if to_recast then 
            room:drawCards(ask_who,1,self:objectName())
            -- 判断是否都是伤害牌或都是非伤害牌  

            local used_damage = use.card:isKindOf("Slash") or   
                    use.card:isKindOf("Duel") or   
                    use.card:isKindOf("SavageAssault") or   
                    use.card:isKindOf("ArcheryAttack") or  
                    use.card:isKindOf("FireAttack") or  
                    use.card:isKindOf("BurningCamps") or  
                    use.card:isKindOf("Drowning")

            local recast_damage = to_recast:isKindOf("Slash") or   
                    to_recast:isKindOf("Duel") or   
                    to_recast:isKindOf("SavageAssault") or   
                    to_recast:isKindOf("ArcheryAttack") or  
                    to_recast:isKindOf("FireAttack") or  
                    to_recast:isKindOf("BurningCamps") or  
                    to_recast:isKindOf("Drowning")

            if used_damage == recast_damage then  
                -- 额外结算一次基本牌  
                local new_use = sgs.CardUseStruct()  
                new_use.card = use.card  
                new_use.from = use.from  
                new_use.to = use.to  
                room:useCard(new_use, false)  
            end  
        end  
        return false  
    end,  
}
mou_huangyueying:addSkill(lizi)
mou_huangyueying:addSkill(yacai)
sgs.LoadTranslationTable{
["#mou_huangyueying"] = "归隐的杰女",  
["mou_huangyueying"] = "黄月英",  
["illustrator:mou_huangyueying"] = "木美人",  
["lizi"] = "理资",  
[":lizi"] = "准备阶段/结束阶段/当你受到伤害后，你可以将一张牌当无中生有/顺手牵羊/过河拆桥/铁索连环使用。",  
["yacai"] = "亚才",   
[":yacai"] = "每回合第一张基本牌被使用时，你可以重铸一张牌，若使用的基本牌和重铸的牌都是伤害牌或非伤害牌，则该基本牌额外结算一次。",
}

KuaiLiangKuaiYue_xcx = sgs.General(extension, "KuaiLiangKuaiYue_xcx", "jin", 3)  

JianXiang = sgs.CreateTriggerSkill{  
    name = "JianXiang",  
    events = {sgs.TargetConfirmed},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local use = data:toCardUse()  
            if use.to:contains(player) and use.from and use.from:objectName() ~= player:objectName() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 找到手牌数最少的角色  
        local all_players = room:getAlivePlayers()  
        local min_handcards = 1000  
          
        for _, p in sgs.qlist(all_players) do  
            local handcard_num = p:getHandcardNum()  
            if handcard_num < min_handcards then  
                min_handcards = handcard_num  
            end  
        end  
          
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(all_players) do  
            local handcard_num = p:getHandcardNum()  
            if handcard_num == min_handcards then  
                targets:append(p)  
            end  
        end  

        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@JianXiang-choose", true, true)  
          
        if target then  
            room:drawCards(target, 1, self:objectName())  
        end  
        return false  
    end  
}


ShenShiCard = sgs.CreateSkillCard{  
    name = "ShenShiCard",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)  
        local card = self:getSubcards():first()
          
        if card then  
            local targets = sgs.SPlayerList()
            -- 检查是否是手牌数最多的其他角色  
            local max_handcards = 0  
            local others = room:getOtherPlayers(source)  
            for _, p in sgs.qlist(others) do  
                if p:getHandcardNum() > max_handcards then  
                    max_handcards = p:getHandcardNum()  
                end  
            end  
            for _, p in sgs.qlist(others) do  
                if p:getHandcardNum() == max_handcards then  
                    targets:append(p)  
                end  
            end  
            local target = room:askForPlayerChosen(source, targets, "shenshi", "@shenshi-give", true)  

            -- 交给目标一张牌  
            room:obtainCard(target, card)  
              
            -- 对其造成1点伤害  
            local damage = sgs.DamageStruct()  
            damage.from = source  
            damage.to = target  
            damage.damage = 1  
            damage.reason = "shenshi"  
            room:damage(damage)  
            --[[
            --可以在这里检查是否因此死亡？ 
            if target:isDead() then  
                local all_players = room:getAlivePlayers()  
                local chosen = room:askForPlayerChosen(source, all_players, "shenshi", "@shenshi-draw", true)  
                if chosen then  
                    local need = 4 - chosen:getHandcardNum()  
                    if need > 0 then  
                        room:drawCards(chosen, need, "shenshi")  
                    end  
                end  
            end  
            ]]
        end  
    end  
}  
  
-- 审时视为技  
ShenShiVS = sgs.CreateOneCardViewAsSkill{  
    name = "shenshi",  
    filter_pattern = ".|.|.|.",  
    view_as = function(self, card)  
        local skill_card = ShenShiCard:clone()  
        skill_card:addSubcard(card:getEffectiveId())  
        skill_card:setSkillName(self:objectName())
        skill_card:setShowSkill(self:objectName())
        return skill_card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#ShenShiCard") and not player:isNude()  
    end  
}  
--[[
ShenShi = sgs.CreateTriggerSkill{  
    name = "shenshi",  
    events = {sgs.Death},  
    view_as_skill = ShenShiVS,
    can_trigger = function(self, event, room, player, data)  
        local death = data:toDeath()  
        if death.damage and death.damage.reason=="shenshi" then  
            return self:objectName()  
        end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true 
    end,  
      
    on_effect = function(self, event, room, player, data)
        local owner = room:findPlayerBySkillName(self:objectName())
        local all_players = room:getAlivePlayers()  
        local chosen = room:askForPlayerChosen(owner, all_players, "shenshi", "@shenshi-draw", true)  
        if chosen then  
            local need = 4 - chosen:getHandcardNum()  
            if need > 0 then  
                room:drawCards(chosen, need, "shenshi")  
            end  
        end  
    end  
}
]]
KuaiLiangKuaiYue_xcx:addSkill(JianXiang)  
KuaiLiangKuaiYue_xcx:addSkill(ShenShiVS)
sgs.LoadTranslationTable{
    ["KuaiLiangKuaiYue_xcx"] = "蒯良蒯越",  
    ["#KuaiLiangKuaiYue_xcx"] = "荆襄智囊",  
    ["JianXiang"] = "荐降",  
    [":JianXiang"] = "当你成为其他角色使用牌的目标后，你可以令手牌数最少的一名角色摸1张牌。",  
    ["shenshi"] = "审时",  
    [":shenshi"] = "出牌阶段限一次，你可以交给手牌数最多的其他角色一张牌，对其造成1点伤害。",  
    ["@JianXiang-choose"] = "荐降：选择一名手牌数最少的角色摸牌",  
    ["@shenshi-draw"] = "审时：选择一名角色将手牌摸至4张"  
}

menghuo_xcx = sgs.General(extension, "menghuo_xcx", "shu", 4) -- 蜀势力，4血，男性（默认）  

HuoshouDamage = sgs.CreateTriggerSkill{  
    name = "huoshouDamage",  
    events = {sgs.DamageInflicted},  
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.card and damage.card:isKindOf("SavageAssault") and damage.to then  
            local menghuo = room:findPlayerBySkillName(self:objectName())  
            if menghuo and menghuo:isAlive() and menghuo:hasSkill(self:objectName()) and not menghuo:isNude() then  
                return self:objectName(),menghuo:objectName()
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return room:askForCard(ask_who, ".", "@huoshou-discard", data, sgs.Card_MethodDiscard)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}

ZaiqiDraw = sgs.CreateTriggerSkill{  
    name = "zaiqiDraw",  
    events = {sgs.DrawNCards},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then
           --and player:getPhase() == sgs.Player_Start then  
            local times = player:getMark("zaiqi_times")  
            if times < 7 then  
                return self:objectName()  
            end  
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
        local times = player:getMark("zaiqi_times")  
          
        -- 亮出牌堆顶X+1张牌  
        local cards = room:getNCards(times + 1)
          
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
                choice = room:askForChoice(player, self:objectName(), "red+black")  
            elseif not black_cards:isEmpty() then  
                choice = "black"  
            end  
              
            -- 获得选择颜色的所有牌  
            local chosen_cards = sgs.IntList()  
            if choice == "red" then  
                chosen_cards = red_cards  
            else  
                chosen_cards = black_cards  
            end  
              
            if not chosen_cards:isEmpty() then
                for _,card in sgs.qlist(chosen_cards) do
                    room:obtainCard(player, card) 
                end 
            end  
              
            -- 其余牌置入弃牌堆  
            for _, id in sgs.qlist(cards) do  
                if not chosen_cards:contains(id) then  
                    room:throwCard(id, nil) 
                end  
            end  

            room:clearAG()  
        end  
          
        -- 增加使用次数  
        room:addPlayerMark(player, "zaiqi_times", 1)  
        return true  
    end  
}  
  
menghuo_xcx:addSkill("huoshou")  
menghuo_xcx:addSkill(HuoshouDamage)  
menghuo_xcx:addSkill(ZaiqiDraw)  
sgs.LoadTranslationTable{
    ["menghuo_xcx"] = "孟获",
    ["huoshouDamage"] = "祸首",  
    [":huoshouDamage"] = "其他角色受到【南蛮入侵】的伤害时，你可以弃置一张牌，令此伤害+1。",  
    ["zaiqiDraw"] = "再起",  
    [":zaiqiDraw"] = "每局游戏限7次，摸牌阶段，你可以改为亮出牌堆顶X+1张牌，然后获得其中一种颜色的所有牌（X为本技能发动的次数）。",  
    ["@huoshou-discard"] = "祸首：你可以弃置一张牌令此【南蛮入侵】伤害+1",  
    ["red"] = "红色",  
    ["black"] = "黑色"  
}

mifuren_xcx = sgs.General(extension, "mifuren_xcx", "shu", 3, false) -- 蜀势力，4血，男性（默认）  

guixiuXCX = sgs.CreateTriggerSkill{  
    name = "guixiuXCX",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
               and player:getPhase() == sgs.Player_Finish  then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)-- 锁定技无需消耗  
    end,  
    on_effect = function(self, event, room, player, data)  
        local hp = player:getHp()  
        if hp % 2 == 1 then -- 奇数体力值  
            player:drawCards(1, self:objectName())  
        else -- 偶数体力值  
            local recover = sgs.RecoverStruct()  
            recover.who = player  
            recover.recover = 1  
            room:recover(player, recover)  
        end  
        return false  
    end  
}


qingyu = sgs.CreateTriggerSkill{  
    name = "qingyu",  
    events = {sgs.DamageInflicted},  
    frequency = sgs.Skill_Compulsory,  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getHandcardNum() >= 2 then-- 需要至少2张手牌 
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)-- 锁定技无需消耗  
    end,  
    on_effect = function(self, event, room, player, data)  
        room:askForDiscard(player, self:objectName(), 2, 2, false, false)  
        return true -- 防止伤害  
    end  
}

xuancun = sgs.CreateTriggerSkill{  
    name = "xuancun",  
    events = {sgs.EventPhaseEnd},  
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or player:getPhase() ~= sgs.Player_Finish then  
            return ""  
        end  
          
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:hasSkill(self:objectName()) and p ~= player then  
                if p:getHp() > p:getHandcardNum() then  
                    return self:objectName(), p:objectName()  
                end  
            end  
        end  
        return false  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return room:askForSkillInvoke(ask_who, self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local draw_num = ask_who:getHp() - ask_who:getHandcardNum()  
        if draw_num > 0 then  
            player:drawCards(draw_num, self:objectName())  
        end  
        return false  
    end  
}
mifuren_xcx:addSkill(guixiuXCX)  
mifuren_xcx:addSkill(qingyu)  
mifuren_xcx:addSkill(xuancun)
sgs.LoadTranslationTable{
["#mifuren_xcx"] = "乱世沉香",  
["mifuren_xcx"] = "糜夫人",  
["illustrator:mifuren_xcx"] = "画师名",  
["guixiuXCX"] = "闺秀",  
[":guixiuXCX"] = "锁定技，结束阶段，若你的体力值为奇数，你摸1张牌；若你的体力值为偶数，你恢复1点体力。",  
["qingyu"] = "清玉",  
[":qingyu"] = "锁定技，当你受到伤害时，你需弃置2张手牌，防止此伤害。",  
["xuancun"] = "悬存",  
[":xuancun"] = "其他角色回合结束时，若你的体力值大于手牌数，你可以令其摸X张牌（X为你的体力值-手牌数）。"
}

shen_zhugeliang_xcx = sgs.General(extension, "shen_zhugeliang_xcx", "shu", 3) -- 蜀势力，4血，男性（默认）  

qixingXCX = sgs.CreateTriggerSkill{  
    name = "qixingXCX",  
    events = {sgs.EventPhaseStart,sgs.Dying},  
    frequency = sgs.Skill_Limited,  
    limit_mark = "@qixingXCX",  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if (player and player:isAlive() and player:hasSkill(self:objectName())) then
                room:setPlayerMark(player,"@qixingXCX",1)
            end
            return ""
        end
        local dying = data:toDying()  
        if dying.who and dying.who:objectName() == player:objectName()   
               and player:hasSkill(self:objectName()) and player:getMark("@qixingXCX") > 0  then
            return self:objectName()
        end
        return ""
    end,  
    on_cost = function(self, event, room, player, data)  
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        room:removePlayerMark(player, "@qixingXCX")  
        local judge = sgs.JudgeStruct()  
        judge.who = player  
        judge.pattern = "."  
        judge.good = true  
        judge.reason = self:objectName()  
        room:judge(judge)  
          
        if judge.card:getNumber() > 7 then  
            local recover = sgs.RecoverStruct()  
            recover.who = player  
            recover.recover = 1  
            room:recover(player, recover)  
        end  
        return false  
    end  
}

-- 天罚技能实现（结算部分）  
tianfaTrick = sgs.CreateTriggerSkill{  
    name = "tianfaTrick",  
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.EventPhaseEnd},  
    --frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start  then  
            room:setPlayerMark(player, "tianfaTrick_trick_count", 0)
            room:setPlayerMark(player, "@tianfaTrick_mark", 0)  
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()  
            if player:getPhase() == sgs.Player_Play and use.card and use.card:getTypeId() == sgs.Card_TypeTrick then
                local count = player:getMark("tianfaTrick_trick_count") + 1  
                room:setPlayerMark(player, "tianfaTrick_trick_count", count)  
                
                if count % 2 == 0 then  
                    room:addPlayerMark(player, "@tianfaTrick_mark")  
                end  
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish  then  
            if player:getMark("@tianfaTrick_mark") > 0  then
                return self:objectName()
            end
            return ""
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local mark_count = player:getMark("@tianfaTrick_mark")  
        if mark_count > 0 then  
            targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if p:isAlive() then  
                    targets:append(p)  
                end  
            end  
              
            chosen = room:askForPlayersChosen(player, targets, self:objectName(), 0, mark_count,   
                                                   "@tianfaTrick-choose:::" .. tostring(mark_count), true)  
 
            for _, target in sgs.qlist(chosen) do  
                if target:isAlive() then  
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Normal))  
                end  
            end  
        end
        room:setPlayerMark(player, "tianfaTrick_trick_count", 0)
        room:setPlayerMark(player, "@tianfaTrick_mark", 0)  
        return false  
    end  
}

jifeng = sgs.CreateViewAsSkill{  
    name = "jifeng",  
    n = 1,  
    view_filter = function(self, selected, to_select)  
        return #selected == 0 and not to_select:isEquipped()  
    end,  
    view_as = function(self, cards)  
        if #cards == 1 then  
            local card = jifeng_card:clone() 
            card:addSubcard(cards[1]:getId())  
            card:setSkillName(self:objectName())  
            card:setShowSkill(self:objectName())  
            return card  
        end  
        return nil  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#jifeng")
    end  
}  
  
-- 祭风技能卡  
jifeng_card = sgs.CreateSkillCard{  
    name = "jifeng",  
    target_fixed = true,  
    will_throw = true,  
    on_use = function(self, room, source, targets)  
        for _, id in sgs.qlist(room:getDrawPile()) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:getTypeId() == sgs.Card_TypeTrick then  
                room:obtainCard(source, id) 
                break 
            end  
        end  
    end  
}
shen_zhugeliang_xcx:addSkill(qixingXCX)  
shen_zhugeliang_xcx:addSkill(tianfaTrick)  
shen_zhugeliang_xcx:addSkill(jifeng)  
sgs.LoadTranslationTable{
["#shen_zhugeliang_xcx"] = "神机妙算",  
["shen_zhugeliang_xcx"] = "神诸葛亮",  
["illustrator:shen_zhugeliang_xcx"] = "画师名",  
["qixingXCX"] = "七星",  
[":qixingXCX"] = "每轮限一次，当你进入濒死状态时，你可以进行判定，若判定牌大于7，你回复1点体力。",  
["@qixingXCX"] = "七星",  
["tianfaTrick"] = "天罚",  
[":tianfaTrick"] = "你的出牌阶段，你每使用2张锦囊，你获得1个'罚'标记；回合结束时，你可以对至多X名其他角色造成1点伤害，X为'罚'标记的数量，然后你移除所有'罚'标记。",  
["@tianfaTrick_mark"] = '罚',  
["@tianfaTrick-choose"] = "天罚：你可以选择至多%arg名其他角色，对其造成1点伤害",  
["jifeng"] = "祭风",  
[":jifeng"] = "出牌阶段限一次，你可以弃置1张手牌，然后从牌堆随机获得一张锦囊。"
}

wangcan = sgs.General(extension, "wangcan", "jin", 3) -- 蜀势力，4血，男性（默认）  

QiAiCard = sgs.CreateSkillCard{  
    name = "QiAiCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        local move = sgs.CardsMoveStruct()  
        move.card_ids = self:getSubcards()  
        move.to = target  
        move.to_place = sgs.Player_PlaceHand  
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "qiai", "")  
        room:moveCardsAtomic(move, true)  
              
        -- 让源角色选择效果  
        local choices = {"qiai:recover_draw", "qiai:draw_recover"}  
        local choice = room:askForChoice(source, "qiai", table.concat(choices, "+"))  
            
        if choice == "qiai:recover_draw" then  
            -- 选择1：你恢复1点体力，其摸2张牌  
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 1  
            room:recover(source, recover)  
            room:drawCards(target, 2, "qiai")  
        else  
            -- 选择2：你摸2张牌，其恢复1点体力  
            room:drawCards(source, 2, "qiai")  
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 1  
            room:recover(target, recover)  
        end  
    end  
}  
  
-- 七哀视为技  
QiAi = sgs.CreateOneCardViewAsSkill{  
    name = "qiai",  
    filter_pattern = "^BasicCard|.|.|hand,equipped",  
    view_as = function(self, card)  
        local skill_card = QiAiCard:clone()  
        skill_card:addSubcard(card:getEffectiveId())  
        skill_card:setSkillName(self:objectName())  
        skill_card:setShowSkill(self:objectName())  
        return skill_card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#QiAiCard") and not player:isNude()  
    end  
}  

ShanXi = sgs.CreateTriggerSkill{  
    name = "shanxi",  
    events = {sgs.EventPhaseStart, sgs.HpRecover},  
    --frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then
            if player and player:isAlive() and player:hasSkill(self:objectName())   
            and player:getPhase() == sgs.Player_Play then  
                return self:objectName(), player:objectName()
            end
        elseif event == sgs.HpRecover then
            if player and player:isAlive() and player:getMark("@xi")>0 then  --0是true
                local wangcan = room:findPlayerBySkillName(self:objectName())  
                if wangcan and wangcan:isAlive() and wangcan:hasSkill(self:objectName()) then  
                    return self:objectName(), wangcan:objectName()
                end  
            end  
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseStart then 
            local others = room:getOtherPlayers(player)  
            local target = room:askForPlayerChosen(player, others, self:objectName(), "@shanxi-choose", true)  
            if target then  
                room:setPlayerMark(target, "@xi", 1)  
            end
        else
            local choices = {"shanxi:give_cards", "shanxi:lose_hp"}  
            local choice = room:askForChoice(player, "shanxi", table.concat(choices, "+"))  
              
            if choice == "shanxi:give_cards" then  
                -- 选择1：交给王粲2张牌  
                if player:getCardCount(true) >= 2 then  
                    --这个函数这么写有问题
                    local cards = room:askForExchange(player, "shanxi", 2, 2, "@shanxi-give", "", ".|.|.|hand,equipped")  
                    if not cards:isEmpty() then  
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), wangcan:objectName(), "shanxi", "")  
                        --for _,card in sgs.qlist(cards) do
                        --    room:obtainCard(ask_who, card, reason, false)  
                        --end
                        --local dummy = sgs.DummyCard(cards)  
                        --room:obtainCard(ask_who, dummy, reason, false)  
                        --dummy:deleteLater() 

                        local move = sgs.CardsMoveStruct()  
                        move.card_ids = cards  
                        move.to = ask_who  
                        move.to_place = sgs.Player_PlaceHand  
                        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), ask_who:objectName(), "shanxi", "")  
                        room:moveCardsAtomic(move, true)  
                    end  
                else  
                    -- 如果牌数不足2张，失去1点体力  
                    room:loseHp(player, 1)
                end  
            else  
                -- 选择2：失去1点体力  
                room:loseHp(player, 1)  
            end  
        end
        return false  
    end  
}  
  

wangcan:addSkill(QiAi)  
wangcan:addSkill(ShanXi)  
sgs.LoadTranslationTable{
    ["wangcan"] = "王粲",  
    ["#wangcan"] = "七子之冠冕",  
    ["qiai"] = "七哀",  
    [":qiai"] = "出牌阶段限一次，你可以将一张非基本牌交给一名其他角色，然后你选择：1.你恢复1点体力，其摸2张牌；2.你摸2张牌，其恢复1点体力。",  
    ["shanxi"] = "善檄",  
    [":shanxi"] = "出牌阶段开始时，你可以令一名其他角色获得'檄'标记；拥有'檄'标记的角色恢复体力后，你可以令其选择：1.交给你2张牌；2.失去1点体力。",  
    ["qiai:recover_draw"] = "你恢复1点体力，其摸2张牌",  
    ["qiai:draw_recover"] = "你摸2张牌，其恢复1点体力",  
    ["shanxi:give_cards"] = "交给王粲2张牌",  
    ["shanxi:lose_hp"] = "失去1点体力",  
    ["@shanxi-choose"] = "善檄：选择一名其他角色获得'檄'标记",  
    ["@shanxi-give"] = "善檄：请选择2张牌交给王粲",  
    ["@xi"] = '檄'  
}

xiangxiu = sgs.General(extension, "xiangxiu", "jin", 3) -- 蜀势力，4血，男性（默认）  

MiaoXiCard = sgs.CreateSkillCard{  
    name = "MiaoXiCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]

        local card1 = room:askForCardShow(target, source, "miaoxi")  
        room:showCard(target, card1:getId())  
        local card2 = room:askForCardShow(source, source, "miaoxi")  
        room:showCard(source, card2:getId()) 

        if card1:getColor() == card2:getColor() then --颜色相同
            -- 颜色相同，获得其展示的牌  
            room:obtainCard(source, card1:getId())  
            room:setPlayerFlag(source,"sijiu_obtained")
        end
        if card1:getTypeId() == card2:getTypeId() then--类别相同
            room:loseHp(target, 1)
        end    
    end  
}  
  
-- 妙析视为技  
miaoxi = sgs.CreateZeroCardViewAsSkill{  
    name = "miaoxi",  
    view_as = function(self)  
        local card = MiaoXiCard:clone()  
        card:setSkillName("miaoxi")  
        card:setShowSkill("miaoxi")  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#MiaoXiCard") and not player:isKongcheng()
    end  
}  



SiJiu = sgs.CreateTriggerSkill{  
    name = "sijiu",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    on_recoder = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then  
            local move = data:toMoveOneTime()  
            if move.to and move.to:hasSkill("sijiu") then  
                if move.from and move.from:objectName() ~= move.to:objectName() then  
                    room:setPlayerFlag(move.to, "sijiu_obtained")  
                end  
            end  
        end  
    end,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName())   
           and player:getPhase() == sgs.Player_Finish then  
            -- 检查本回合是否获得过其他角色的牌  
            if player:hasFlag("sijiu_obtained") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 摸一张牌  
        room:drawCards(player, 1, self:objectName())  
          
        -- 观看一名其他角色的手牌  
        local others = room:getOtherPlayers(player)  
        local target = room:askForPlayerChosen(player, others, self:objectName(), "@sijiu-choose")  
        if target then  
            local handcards = target:getHandcards()  
            room:showAllCards(target, player)  
        end  
        return false  
    end  
}  

xiangxiu:addSkill(miaoxi)  
xiangxiu:addSkill(SiJiu)  
sgs.LoadTranslationTable{
    ["xiangxiu"] = "向秀",  
    ["#xiangxiu"] = "竹林名士",  
    ["miaoxi"] = "妙析",  
    [":miaoxi"] = "出牌阶段限一次，你可以选择一名其他角色，你与其同时展示一张手牌：若颜色相同，你获得其展示的牌；若类别相同，其失去一点体力。",  
    ["sijiu"] = "思旧",  
    [":sijiu"] = "你的回合结束时，若你本回合因【妙析】获得过其他角色的牌，你可以摸一张牌并观看一名其他角色的手牌。",  
    ["@miaoxishow"] = "妙析：请选择一张手牌展示",  
    ["@sijiu-choose"] = "思旧：选择一名其他角色观看其手牌"  
}

zhugeguo_xcx = sgs.General(extension, "zhugeguo_xcx", "shu", 3, false) -- 蜀势力，4血，男性（默认）  

qidaoXCX = sgs.CreateTriggerSkill{  
    name = "qidaoXCX",  
    events = {sgs.CardUsed},  
    frequency = sgs.Skill_Frequent,  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:getTypeId()==sgs.Card_TypeEquip then
                return self:objectName()  
            end
        end
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return room:askForSkillInvoke(player, self:objectName(), data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        for _, id in sgs.qlist(room:getDrawPile()) do  
            local card = sgs.Sanguosha:getCard(id)  
            if card:getTypeId() == sgs.Card_TypeTrick then  
                card:setFlags("qidaoXCX_qi")
                room:obtainCard(player, id) 
                break 
            end  
        end  
        return false  
    end  
}  
  
-- 祈祷技能实现（使用有"祈"标记的锦囊时额外指定目标）  
qidaoXCX_target = sgs.CreateTargetModSkill{  
    name = "qidaoXCX_target",  
    pattern = "TrickCard",  
    extra_target_func = function(self, player, card)  
        if player:hasSkill("qidaoXCX") and card:hasFlag("qidaoXCX_qi")   
           and not card:isKindOf("DelayedTrick") then  
            return 1  
        end  
        return 0  
    end  
}  
  

yuhuaXCX = sgs.CreateMaxCardsSkill{  
    name = "yuhuaXCX",  
    extra_func = function(self, player)  
        if player:hasSkill(self:objectName()) then  
            local extra = 0  
            for _, card in sgs.qlist(player:getHandcards()) do  
                if card:getTypeId() ~= sgs.Card_TypeBasic then  
                    extra = extra + 1  
                end  
            end  
            return extra  
        end  
        return 0  
    end  
}

zhugeguo_xcx:addSkill(qidaoXCX)  
zhugeguo_xcx:addSkill(qidaoXCX_target)  
zhugeguo_xcx:addSkill(yuhuaXCX)  
sgs.LoadTranslationTable{
["#zhugeguo_xcx"] = "通幽达灵",  
["zhugeguo_xcx"] = "诸葛果",  
["illustrator:zhugeguo"] = "画师名",  
["qidaoXCX"] = "祈祷",  
[":qidaoXCX"] = "你使用装备牌时，你可以从牌堆随机获得1张锦囊，并标记为'祈'；你使用有'祈'的非延时性锦囊时可以额外指定一个目标。",  
["yuhuaXCX"] = "羽化",  
[":yuhuaXCX"] = "你的非基本牌不计入手牌上限。"
}
sgs.Sanguosha:addSkills(skills)
return {extension}