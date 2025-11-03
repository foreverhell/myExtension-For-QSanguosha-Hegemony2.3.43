
-- 武将定义  
extension = sgs.Package("jinPackage", sgs.Package_GeneralPack)  
do
    require "lua.config"
    local config = config
    table.insert(config.kingdoms,"jin")
    config.kingdom_colors["jin"] = "#ff35e4ff"
end
--sgs.addNewKingdom("jin", "#ff35e4ff")  -- 使用橙红色作为火影势力的颜色
sgs.LoadTranslationTable{
    ["jin"] = "晋",
    ["jinPackage"] = "晋包"
}

xiahouhui = sgs.General(extension, "xiahouhui", "jin", 3, false)  --wu

yishi = sgs.CreateTriggerSkill{  
    name = "yishi",  
    events = {sgs.CardsMoveOneTime},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if skillTriggerable(player, self:objectName()) then
            if player:hasFlag("yishi_used") then return "" end
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() == sgs.Player_Play then
                if player:objectName()==current:objectName() then return "" end
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					--if reasonx ~= sgs.CardMoveReason_S_REASON_USE and reasonx ~= sgs.CardMoveReason_S_REASON_RESPONSE then
					if reasonx == sgs.CardMoveReason_S_REASON_DISCARD then
                        if move.from and move.from:isAlive() and move.from:objectName()==current:objectName() and move.from:contains(sgs.Player_PlaceHand) then
                            return self:objectName()
                        end
					end
				end
			end
		end
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then
            room:setPlayerFlag(player,"yishi_used")
            room:broadcastSkillInvoke(self:objectName(), player)  
            return true  
        end  
        return false  
    end,  
    
    on_effect = function(self, event, room, player, data)  
		local current = room:getCurrent()
        local move_datas = data:toList()
        local card_ids = sgs.IntList()
        for _, move_data in sgs.qlist(move_datas) do
            local move = move_data:toMoveOneTime()
            for _,card_id in sgs.qlist(move.card_ids) do
                card_ids:append(card_id)
            end 
        end

        -- 检查牌堆是否为空  
        if card_ids:length() == 0 then  
            return false
        end          
        -- 使用AG界面让玩家选择一张牌  
        room:fillAG(card_ids, player)  
        local card_id = room:askForAG(player, card_ids, true, self:objectName())  
        room:clearAG(player) 
        if card_id == nil then return false end
        local card = sgs.Sanguosha:getCard(card_id)
        if card == nil then return false end

        room:obtainCard(current,card_id)

        for _,id in sgs.qlist(card_ids) do
            if id~=card_id then
                room:obtainCard(player,id)
            end
        end
        return false  
    end  
}  
  
ShiduCard = sgs.CreateSkillCard{  
    name = "ShiduCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getHandcardNum() > 0  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 进行拼点  
        local success = source:pindian(target,"shidu")            
        if success then  
            -- 拼点成功，获得其所有手牌  
            local target_cards = target:handCards()  
            if not target_cards:isEmpty() then  
                local card_ids = {}  
                for _, id in sgs.qlist(target_cards) do  
                    table.insert(card_ids, id)  
                end  
                  
                -- 获得目标所有手牌  
                for _, id in ipairs(card_ids) do  
                    source:obtainCard(sgs.Sanguosha:getCard(id))  
                end  
                  
                -- 交给其一半手牌（向下取整）  
                local source_handcards = source:getHandcardNum()  
                local give_num = math.floor(source_handcards / 2)  
                  
                if give_num > 0 then  
                    local cards_to_give = room:askForExchange(source, "shidu", give_num, give_num, "@shidu-give", "", ".|.|.|hand")  
                    if cards_to_give:length() > 0 then  
                        for _, id in sgs.qlist(cards_to_give) do  
                            target:obtainCard(sgs.Sanguosha:getCard(id))  
                        end  
                    end  
                end  
            end  
        end  
    end  
}  
  
-- 识度视为技能  
shidu = sgs.CreateZeroCardViewAsSkill{  
    name = "shidu",  
    view_as = function(self)  
        local skill_card = ShiduCard:clone()  
        skill_card:setSkillName(self:objectName())  
        return skill_card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#ShiduCard") and player:getHandcardNum() > 0  
    end  
}
xiahouhui:addSkill(yishi)
xiahouhui:addSkill(shidu)

sgs.LoadTranslationTable{
["#xiahouhui"] = "明德皇后",  
["xiahouhui"] = "夏侯徽",  
["illustrator:xiahouhui"] = "画师名",  
["yishi"] = "宜室",  
[":yishi"] = "每回合限一次，当一名其他角色于其出牌阶段弃置手牌后，你可以令其获得其中一张，然后你获得其余的牌。",  
["shidu"] = "识度",   
[":shidu"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，你获得其所有手牌，然后你交给其你的一半（向下取整）手牌。",
}
simaliang = sgs.General(extension, "simaliang", "jin", 3)  
gongzhi = sgs.CreateTriggerSkill{  
    name = "gongzhi",  
    view_as_skill = gongZhiVS,  
    events = {sgs.EventPhaseStart}, 
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getPhase() == sgs.Player_Start then
                return self:objectName()
            end
        end  
        return false  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(),data) then  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        player:skip(sgs.Player_Draw)  

        local jin_players = {}  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if player:isFriendWith(p) then  
                table.insert(jin_players, p)  
            end  
        end  
          
        -- 轮流摸牌，共计4张  
        local draw_count = 0  
        local player_index = 1  
        while draw_count < 4 and #jin_players > 0 do  
            local current_player = jin_players[player_index]  
            if current_player and current_player:isAlive() then  
                current_player:drawCards(1, "gongzhi")  
                draw_count = draw_count + 1  
            end  
            player_index = player_index + 1  
            if player_index > #jin_players then  
                player_index = 1  
            end  
        end  
        return false  
    end  
}

shenju = sgs.CreateTriggerSkill{  
    name = "shenju",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.GeneralShown},  
    can_trigger = function(self, event, room, player, data)  
        local source = room:findPlayerBySkillName(self:objectName())  
        if source and source:isAlive() and source:hasSkill(self:objectName()) and player and player:isAlive() then  
            if source:isFriendWith(player) and player:objectName() ~= source:objectName() then
                if source:isWounded() then
                    return self:objectName(), source:objectName()
                end
            end
        end  
        return false  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)
        return ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)  
        local source = room:findPlayerBySkillName(self:objectName())  
        if source and source:isAlive() then  
            -- 恢复一点体力  
            local recover = sgs.RecoverStruct()  
            recover.who = source  
            recover.recover = 1  
            room:recover(source, recover)  
              
            -- 弃置所有手牌  
            if not source:isKongcheng() then  
                room:askForDiscard(source, self:objectName(), source:getHandcardNum(),   
                                 source:getHandcardNum(), false, false)  
            end  
        end  
        return false  
    end  
}

simaliang:addSkill(gongzhi)  
simaliang:addSkill(shenju)
sgs.LoadTranslationTable{
["#simaliang"] = "晋室宗亲",  
["simaliang"] = "司马亮",  
["illustrator:simaliang"] = "画师名",  
  
-- 技能翻译  
["gongzhi"] = "共执",  
[":gongzhi"] = "摸牌阶段开始时，你可以跳过摸牌阶段，然后令与你势力相同的角色轮流摸1张牌，共计摸4张。",  
["shenju"] = "慎惧",  
[":shenju"] = "锁定技，与你势力相同的其他角色明置武将牌后，若你已受伤，你恢复一点体力并弃置所有手牌。",  
  
-- 提示信息  
["@gongzhi"] = "共执：是否跳过摸牌阶段，令晋势力角色轮流摸4张牌？",  
["#shenju-recover"] = "慎惧[回复体力]",  
["#shenju-discard"] = "慎惧[弃置手牌]",
}
simalun = sgs.General(extension, "simalun", "jin", 3)  

luanchang = sgs.CreateTriggerSkill{  
    name = "luanchang",  
    frequency = sgs.Skill_Limited,  
    --limit_mark = "@luanchang",  
    events = {sgs.Damaged, sgs.EventPhaseEnd},  
      
    can_trigger = function(self, event, room, player, data)  
        if event == sgs.Damaged then  
            -- 监听伤害事件，给当前回合角色添加flag  
            local damage = data:toDamage()  
            if not damage.to then return "" end  
              
            local current = room:getCurrent()  
            if not current then return "" end  
              
            -- 检查是否有司马伦存在且技能可用  
            local simalun = room:findPlayerBySkillName(self:objectName())  
            if not (simalun and simalun:isAlive() and simalun:getMark("@luanchang") == 0) then return "" end  
              
            -- 检查受伤角色与司马伦势力相同  
            --if damage.to:getKingdom() == simalun:getKingdom() then  
            if damage.to:isFriendWith(simalun) then --必须明置，并且考虑野心家的情况
                room:setPlayerFlag(current, "luanchang_damaged")  
            end  
            return ""  
              
        elseif event == sgs.EventPhaseEnd then  
            -- 结束阶段检查flag并询问发动  
            if not (player and player:isAlive()) then return "" end  
            if player:getPhase() ~= sgs.Player_Finish then return "" end  
            if not player:hasFlag("luanchang_damaged") then return "" end  
              
            local simalun = room:findPlayerBySkillName(self:objectName())  
            if not (simalun and simalun:isAlive() and simalun:getMark("@luanchang") == 0) then return "" end  
            if player:getHandcardNum() == 0 then return "" end  
              
            return self:objectName(), simalun:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            if ask_who:askForSkillInvoke(self:objectName(), data) then  
                room:broadcastSkillInvoke(self:objectName())  
                room:removePlayerMark(ask_who, "@luanchang")  
                return true  
            end  
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.EventPhaseEnd then  
            room:setPlayerMark(ask_who,"@luanchang",1)
            -- 当前回合角色弃置所有手牌  
            --local handcards = player:getHandcards()  
            --if handcards:isEmpty() then return false end  
              
            player:throwAllHandCards()  
              
            -- 使用万箭齐发  
            local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)  
            archery_attack:setSkillName(self:objectName())  
            archery_attack:deleteLater()
            local use = sgs.CardUseStruct()  
            use.card = archery_attack  
            use.from = player  
              
            room:useCard(use)  
              
            -- 清除flag  
            room:setPlayerFlag(player, "-luanchang_damaged")  
        end  
        return false  
    end  
}
  
-- 司马伦 - 助澜技能    
zhulan = sgs.CreateTriggerSkill{  
    name = "zhulan",  
    events = {sgs.DamageInflicted},  
      
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive()) then return "" end  
        simalun = room:findPlayerBySkillName(self:objectName())
        if not (simalun and simalun:isAlive() and simalun:hasSkill(self:objectName())) then return "" end

        local damage = data:toDamage()  
        if not damage.from then return "" end  
        if damage.to:objectName() == simalun:objectName() then return "" end  
          
        -- 检查伤害来源与受伤角色势力相同  
        --if damage.from:getKingdom() == damage.to:getKingdom() then 
        if damage.from:isFriendWith(damage.to) then  --考虑野心家的情况
            if not simalun:isNude() then  
                return self:objectName(), simalun:objectName()
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        local _data = sgs.QVariant()  
        _data:setValue(damage.to)  
          
        if ask_who:askForSkillInvoke(self:objectName(), _data) then  
            room:broadcastSkillInvoke(self:objectName())  
            room:askForDiscard(ask_who, self:objectName(), 1, 1, false, true)  
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
  

simalun:addSkill(luanchang)  
simalun:addSkill(zhulan)

sgs.LoadTranslationTable{
["simalun"] = "司马伦",  
["#simalun"] = "篡逆之王",  
["luanchang"] = "乱常",   
[":luanchang"] = "限定技，一名角色的结束阶段，若有与你势力相同的角色于此回合内受到过伤害，你可令当前回合角色将所有手牌视为使用【万箭齐发】。",  
--与你势力相同的角色受到伤害时，给当前回合角色添加一个flag，有flag的角色回合结束时，你可以令其弃置所有手牌，视为使用万箭齐发
["@luanchang"] = "乱常",  
["zhulan"] = "助澜",  
[":zhulan"] = "当一名其他角色受到伤害时，若伤害来源与其势力相同，你可以弃置一张牌，令此伤害值+1。"
}

simazhong = sgs.General(extension, "simazhong", "jin", 3) -- 蜀势力，4血，男性（默认）  

rouzuo = sgs.CreateTriggerSkill{  
    name = "rouzuo",  
    events = {sgs.EventPhaseStart},  
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
        local give_record = {}  
        -- 让所有其他角色依次交给你任意张牌  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if p:isAlive() and not p:isNude() then  
                local cards = room:askForExchange(p, self:objectName(), 999, 0, "@rouzuo-give:" .. player:objectName(), "", ".")  
                if cards:length() > 0 then  
                    local move = sgs.CardsMoveStruct()  
                    move.card_ids = cards  
                    move.to = player  
                    move.to_place = sgs.Player_PlaceHand  
                    move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(), "")  
                    room:moveCardsAtomic(move, true)  
                    give_record[p:objectName()] = cards:length()  
                end  
            end  
        end  
          
        -- 你须弃置1张牌并跳过出牌阶段和弃牌阶段  
        if not player:isNude() then  
            room:askForDiscard(player, self:objectName(), 1, 1, false, true, "@rouzuo-discard")  
        end  
        player:skip(sgs.Player_Play)  
        player:skip(sgs.Player_Discard)  
          
        -- 然后你可以弃置1张牌，令给你牌最多的角色获得一个额外回合  
        if not player:isNude() and player:askForSkillInvoke("@rouzuo-extra", data) then  
            room:askForDiscard(player, self:objectName(), 1, 1, false, true, "@rouzuo-extra")  
              
            -- 找到给牌最多的角色  
            local max_give = 0  
            local candidates = {}  
            
            -- 先找出最大给牌数  
            for name, count in pairs(give_record) do  
                if count > max_give then  
                    max_give = count  
                end  
            end  
            
            -- 收集所有给牌数等于最大值的角色  
            for name, count in pairs(give_record) do  
                if count == max_give and count > 0 then  
                    local p = room:findPlayer(name)  
                    if p and p:isAlive() then  
                        table.insert(candidates, p)  
                    end  
                end  
            end  
              
            if #candidates > 0 then  
                local target = nil
                if #candidates == 1 then  
                    target = candidates[1]  
                else  
                    -- 让玩家从候选者中选择一个  
                    local targets = sgs.SPlayerList()  
                    for _, p in ipairs(candidates) do  
                        targets:append(p)  
                    end  
                    local chosen = room:askForPlayersChosen(player, targets, self:objectName(), 1, 1, "@rouzuo-choose")  
                    if chosen:length() > 0 then  
                        target = chosen:first()  
                    end  
                end  
                
                if target then  
                    target:gainAnExtraTurn()  
                end  
            end  
        end  
          
        return false  
    end  
}

yunxi_draw = sgs.CreateDrawCardsSkill{  
    name = "yunxi",  
    draw_num_func = function(self, player, n)  
        local room = player:getRoom()  
        local has_yuxi = false  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:hasTreasure("JadeSeal") then  
                has_yuxi = true  
                break  
            end  
        end  
        if not has_yuxi then  
            room:sendCompulsoryTriggerLog(player, self:objectName())  
            return n + 1  
        end  
        return n  
    end  
}  
  
-- 允玺获得玉玺效果  
yunxi_get = sgs.CreateTriggerSkill{  
    name = "yunxi_get",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill("yunxi_get") then  
            if player:getPhase() == sgs.Player_Play then  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:hasTreasure("JadeSeal") then  
                        return self:objectName()  
                    end  
                end  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
    on_effect = function(self, event, room, player, data)  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:hasTreasure("JadeSeal") then  
                local yuxi = p:getTreasure()  
                room:obtainCard(player, yuxi)  
                break  
            end  
        end  
        return false  
    end  
}  

simazhong:addSkill(rouzuo)
simazhong:addSkill(yunxi_draw)
simazhong:addSkill(yunxi_get)
-- 翻译表  
sgs.LoadTranslationTable{        
["#simazhong"] = "愚帝",  
["simazhong"] = "司马衷",  
["illustrator:simazhong"] = "画师名",  
["rouzuo"] = "肉作",  
[":rouzuo"] = "准备阶段，你可以令所有其他角色依次交给你任意张牌，你须弃置1张牌并跳过出牌阶段和弃牌阶段。然后你可以弃置1张牌，令给你牌最多的角色获得一个额外回合。",  
["yunxi"] = "允玺",  
[":yunxi"] = "锁定技。若场上没有玉玺，你摸牌阶段摸牌数+1；出牌阶段开始时，若场上有玉玺，你获得之。",  
["@rouzuo-give"] = "肉作：请选择任意张牌交给%src",  
["@rouzuo-discard"] = "肉作：请弃置1张牌",  
["@rouzuo-extra"] = "肉作：你可以弃置1张牌，令给你牌最多的角色获得额外回合",  
["@rouzuo-choose"] = "肉作：请选择一名角色获得额外回合",
["rouzuo_extra"] = "肉作",
}  
simazhou = sgs.General(extension, "simazhou", "jin", 3)  
poJingCard = sgs.CreateSkillCard{  
    name = "poJingCard",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local choices = {"pojing_option1"}
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getRole()~="careerist" and p:getKingdom()==source:getKingdom() and not p:hasShownAllGenerals() then
                table.insert(choices,"pojing_option2")
                break
            end
        end
        local choice = room:askForChoice(target, "pojing", table.concat(choices, "+"))  
          
        if choice == "pojing_option1" then  
            -- 选项1：司马伷获得其区域内一张牌  
            local card_id = room:askForCardChosen(source, target, "hej", "pojing")  
            room:obtainCard(source, card_id, false)  
        else  
            -- 选项2：发起势力召唤  
            local jin_players = {}  
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if source:getRole()~="careerist" and p:getRole()~="careerist" and source:getKingdom()==p:getKingdom() and not p:hasShownAllGenerals() then  
                    table.insert(jin_players, p)  
                end  
            end  
              
            local damage_count = 0  
            for _, p in ipairs(jin_players) do  
                local choices = {}  
                if not p:hasShownGeneral1() then  
                    table.insert(choices, "show_head_general")  
                end  
                if not p:hasShownGeneral2() then  
                    table.insert(choices, "show_deputy_general")  
                end  
                table.insert(choices, "cancel")  
                  
                if #choices > 1 then  
                    local show_choice = room:askForChoice(p, "pojing_summon", table.concat(choices, "+"))  
                    if show_choice ~= "cancel" then  
                        if show_choice == "show_head_general" then  
                            p:showGeneral(true)  
                        else  
                            p:showGeneral(false)  
                        end  
                        damage_count = damage_count + 1  
                    end  
                end  
            end  
              
            -- 对目标造成等量伤害  
            if damage_count > 0 then  
                room:damage(sgs.DamageStruct("pojing", source, target, damage_count))  
            end  
        end  
    end  
}

poJing = sgs.CreateZeroCardViewAsSkill{  
    name = "pojing",  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#poJingCard")  
    end,  
    view_as = function(self)  
        card = poJingCard:clone()  
        card:setShowSkill(self:objectName())
        return card
    end  
}

simazhou:addSkill(poJing)

sgs.LoadTranslationTable{
    ["#simazhou"] = "晋室宗亲",  
    ["simazhou"] = "司马伷",  
    ["illustrator:simazhou"] = "画师名",  
    
    -- 技能翻译  
    ["pojing"] = "迫境",  
    [":pojing"] = "出牌阶段限一次，你可以令一名其他角色选择：1.你获得其区域内一张牌；2.令你发起势力召唤，所有（明置后）与你势力相同的角色可以依次明置与你势力相同的武将牌，然后对其造成等量伤害。若场上与你势力相同的角色均已明置所有武将，则移除该选项。",  
    
    -- 选项翻译  
    ["pojing_option1"] = "令司马伷获得你区域内一张牌",  
    ["pojing_option2"] = "令司马伷发起势力召唤",  
    ["@pojing"] = "迫境：请选择执行的选项",  
    ["pojing_summon"] = "势力召唤：是否明置武将牌",
}
jiachong_ol = sgs.General(extension, "jiachong_ol", "jin", 3)  
  
BeiniCard = sgs.CreateSkillCard{  
    name = "BeiniCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        return #targets == 0 and to_select:getHp() >= sgs.Self:getHp() and to_select:objectName()~=sgs.Self:objectName()
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
          
        -- 选择谁摸牌  
        local choice = room:askForChoice(source, "beini", "self+target",   
            sgs.QVariant(string.format("self:%s+target:%s", source:objectName(), target:objectName())))  
          
        local drawer, other  
        if choice == "self" then  
            drawer = source  
            other = target  
        else  
            drawer = target  
            other = source  
        end  
          
        -- 摸牌者摸两张牌  
        drawer:drawCards(2, "beini")  
          
        -- 未摸牌的角色选择  
        local choices = {}  
        if other:canSlash(drawer, nil, false) then  
            table.insert(choices, "slash")  
        end  
        if not drawer:isAllNude() then  
            table.insert(choices, "getcard")  
        end  
          
        if #choices > 0 then  
            local other_choice = room:askForChoice(other, "beini", table.concat(choices, "+"))  
            if other_choice == "slash" then  
                -- 视为使用杀  
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
                slash:setSkillName("beini")  
                local use = sgs.CardUseStruct()  
                use.card = slash  
                use.from = other  
                use.to:append(drawer)  
                room:useCard(use)  
                slash:deleteLater()
            elseif other_choice == "getcard" then  
                -- 获得一张牌  
                local card_id = room:askForCardChosen(other, drawer, "hej", "beini")  
                room:obtainCard(other, card_id, false)  
            end  
        end  
    end  
}  
  
-- 悖逆技能  
beini = sgs.CreateZeroCardViewAsSkill{  
    name = "beini",  
    view_as = function(self)  
        local card = BeiniCard:clone()  
        card:setShowSkill("beini")  
        return card  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#BeiniCard")  
    end  
}
  
-- 技能2：定法  
dingfa = sgs.CreateTriggerSkill{  
    name = "dingfa",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
          
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then  
            -- 弃牌阶段开始时检查是否获得'定'标记
            discard_num = player:getHandcardNum() - player:getMaxCards()
            if discard_num >= player:getHp() then
                room:setPlayerFlag(player,"ding4")
            end  
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then  
            -- 弃牌阶段结束时检查是否有'定'标记  
            if player:hasFlag("ding4") then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseEnd then  
            return player:askForSkillInvoke(self:objectName(),data)  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseEnd then                
            local choices = {}  
            if player:isWounded() then  
                table.insert(choices, "recover")  
            end  
              
            local others = room:getOtherPlayers(player)  
            for _, p in sgs.qlist(others) do  
                if not p:isAllNude() then  
                    table.insert(choices, "discard")
                    break  
                end  
            end                
            if #choices > 0 then  
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
                if choice == "recover" then  
                    local recover = sgs.RecoverStruct()  
                    recover.who = player  
                    recover.recover = 1  
                    room:recover(player, recover)  
                elseif choice == "discard" then  
                    local targets = sgs.SPlayerList()  
                    for _, p in sgs.qlist(others) do  
                        if not p:isAllNude() then  
                            targets:append(p)  
                        end  
                    end  
                      
                    local discarded = 0  
                    while discarded < 2 and not targets:isEmpty() do  
                        local target = room:askForPlayerChosen(player, targets, self:objectName(),   
                            "@dingfa-discard:" .. tostring(2 - discarded), true)  
                        if not target then break end  
                          
                        local card_id = room:askForCardChosen(player, target, "hej", self:objectName())  
                        room:throwCard(card_id, target, player)  
                        discarded = discarded + 1  
                          
                        if target:isAllNude() then  
                            targets:removeOne(target)  
                        end  
                    end  
                end  
            end  
        end  
        return false  
    end  
}  
  
  
-- 添加技能到武将  
jiachong_ol:addSkill(beini)  
jiachong_ol:addSkill(dingfa)  

sgs.LoadTranslationTable{
    ["jiachong_ol"] = "贾充-OL",
    ["beini"] = "悖逆",  
    [":beini"] = "出牌阶段限一次，选择一名体力≥你的角色，你或其摸两张牌，未摸牌的角色需选择：1.视为对摸牌者使用【杀】；2.获得摸牌者一张牌。",  
    ["@beini-target"] = "悖逆：选择一名体力不小于你的角色",  
    ["self"] = "你摸牌",  
    ["target"] = "其摸牌",  
    --["slash"] = "视为使用【杀】",  
    ["getcard"] = "获得一张牌",  
    
    -- 定法技能  
    ["dingfa"] = "定法",  
    [":dingfa"] = "弃牌阶段开始时，若需要弃置的牌数≥体力值，获得'定'标记；弃牌阶段结束时，若有'定'标记，可选择回复1点体力或弃置其他角色至多两张牌。",  
    ["ding4"] = '定',  
    ["recover"] = "回复1点体力",  
    ["discard"] = "弃置牌",  
    ["@dingfa-discard"] = "定法：选择一名其他角色，弃置其一张牌（还可弃置%arg张）",  
    ["#dingfa-clear"] = "定法",
}
jiachong_yingbian = sgs.General(extension, "jiachong_yingbian", "jin", 3) -- 蜀势力，4血，男性（默认）  

xiongshuCard = sgs.CreateSkillCard{  
    name = "xiongshuCard",  
    target_fixed = false,  
    will_throw = false,  
    filter = function(self, targets, to_select)  
        if #targets >= 1 then return false end  
        return to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        local handcards = source:getHandcards()  
        if not handcards:isEmpty() then  
            -- 将所有手牌交给目标角色  
            local move = sgs.CardsMoveStruct()  
            move.card_ids = sgs.IntList()  
            for _, card in sgs.qlist(handcards) do  
                move.card_ids:append(card:getEffectiveId())  
            end  
            move.from = source  
            move.to = target  
            move.to_place = sgs.Player_PlaceHand  
            move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "xiongshu", "")  
            room:moveCardsAtomic(move, true)  
              
            -- 令目标角色对其攻击范围内所有角色使用杀  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:setSkillName("xiongshu")  
            slash:deleteLater()
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = target  
            use.to = sgs.SPlayerList()  
              
            for _, p in sgs.qlist(room:getAlivePlayers()) do  
                if target:inMyAttackRange(p) then  
                    use.to:append(p)  
                end  
            end  
              
            if not use.to:isEmpty() then  
                -- 记录技能发动者，用于后续体力恢复判断  
                room:useCard(use)  
            end  
        end  
    end  
}  
  
-- 凶竖ViewAsSkill  
xiongshuVS = sgs.CreateViewAsSkill{  
    name = "xiongshu",  
    n = 0,  
    view_filter = function(self, selected, to_select)  
        return false  
    end,  
    view_as = function(self, cards)  
        card = xiongshuCard:clone()  
        card:setShowSkill(self:objectName())
        return card
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#xiongshuCard") and not player:isKongcheng()  
    end,  
    enabled_at_response = function(self, player, pattern)  
        return false  
    end  
}  
  
-- 凶竖主技能  
xiongshu = sgs.CreateTriggerSkill{  
    name = "xiongshu",  
    events = {sgs.Damage},  
    view_as_skill = xiongshuVS,  
      
    can_trigger = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        if damage.card and damage.card:getSkillName() == "xiongshu" then  
            return self:objectName()
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return true  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        --只恢复1次
        local owner = room:findPlayerBySkillName(self:objectName())
        local damage = data:toDamage()  
        -- 恢复1点体力  
        local recover = sgs.RecoverStruct()  
        recover.who = owner  
        recover.recover = 1  
        room:recover(owner, recover)  
        return false  
    end  
}

jianhuiYingbian = sgs.CreateTriggerSkill{  
    name = "jianhuiYingbian",  
    events = {sgs.Damage},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then return "" end
        local damage = data:toDamage()  
        if damage.from and damage.to and damage.from:isFriendWith(damage.to) then  
            return self:objectName(), owner:objectName()  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        local damage = data:toDamage()  
        local targets = sgs.SPlayerList()  
        targets:append(damage.from)  
        targets:append(damage.to) 
          
        local draw_target = room:askForPlayerChosen(ask_who, targets, self:objectName(), "@jianhuiYingbian-draw", true, true)  
        -- 创建弃牌目标列表（排除已选择的摸牌目标）  
        local discard_target = nil
        if damage.from == damage.to then
            discard_target = draw_target
        else
            if damage.from:objectName() ~= draw_target:objectName() then  
                discard_target = damage.from
            end  
            if damage.to:objectName() ~= draw_target:objectName() then  
                discard_target = damage.to
            end
        end           
        if draw_target then  
            draw_target:drawCards(1, self:objectName())  
        end  
          
        if discard_target and not discard_target:isNude() then  
            --room:askForDiscard(discard_target, self:objectName(), 1, 1, false, true)  
            local card_id = room:askForCardChosen(ask_who, discard_target, "he", self:objectName(), false)
            room:throwCard(card_id, discard_target, ask_who)  
        end  
          
        return false  
    end  
}

jiachong_yingbian:addSkill(xiongshu)  
jiachong_yingbian:addSkill(jianhuiYingbian)

-- 翻译表  
sgs.LoadTranslationTable{        
["#jiachong_yingbian"] = "弑君之臣",  
["jiachong_yingbian"] = "贾充-应变",  
["illustrator:jiachong_yingbian"] = "画师名",  
["xiongshu"] = "凶竖",  
[":xiongshu"] = "出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后令该角色视为对其攻击范围内所有角色使用一张杀，若此杀造成伤害，你恢复1点体力。",  
["jianhuiYingbian"] = "奸回",  
[":jianhuiYingbian"] = "当有角色对与其势力相同的角色造成伤害时，你可以令其中一名角色摸1张牌，然后弃置其中另一名角色1张牌。",
}  
jiananfeng = sgs.General(extension, "jiananfeng", "jin", 3, false) -- 蜀势力，4血，男性（默认）  

shanzhuan = sgs.CreateTriggerSkill{  
    name = "shanzhuan",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 展示所有手牌  
        room:showAllCards(player)  
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "", false, true)
          
          
        if target and target:isAlive() then  
            -- 发起军令  
            if player:askCommandto(self:objectName(), target) then
                -- 执行军令，交给其1张手牌  
                if not player:isKongcheng() then  
                    local card_id = room:askForCardChosen(player, player, "h", self:objectName())  
                    room:moveCardTo(sgs.Sanguosha:getCard(card_id), target, sgs.Player_PlaceHand,   
                                   sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""))  
                end  
            else  
                -- 不执行军令，造成1点伤害  
                local damage = sgs.DamageStruct()  
                damage.from = player  
                damage.to = target  
                damage.damage = 1  
                damage.nature = sgs.DamageStruct_Normal  
                damage.reason = self:objectName()  
                room:damage(damage)  
            end  
        end  
          
        return false  
    end  
}


chizheng = sgs.CreateTriggerSkill{  
    name = "chizheng",  
    events = {sgs.CardsMoveOneTime}, 
    frequency = sgs.Skill_Compulsory, 
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local move = data:toMoveOneTime()  
            if move.reason.m_reason == sgs.CardMoveReason_S_REASON_GIVE and   
               move.reason.m_playerId == player:objectName() and  
               move.to and move.to ~= player then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        -- 摸1张牌  
        player:drawCards(1)  
        return false  
    end  
}

dudu = sgs.CreateTriggerSkill{  
    name = "dudu",  
    events = {sgs.DamageCaused},  
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) then  
            local damage = data:toDamage()  
            if damage.from == player and damage.to and damage.to:hasShownOneGeneral() and damage.to:getGender() == sgs.General_Female then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)
    end,
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
        return false  
    end  
}

jiananfeng:addSkill(shanzhuan)
jiananfeng:addSkill(chizheng)
jiananfeng:addSkill(dudu)

-- 翻译表  
sgs.LoadTranslationTable{        
["#jiananfeng"] = "弄权皇后",  
["jiananfeng"] = "贾南风",  
["illustrator:jiananfeng"] = "绘聚艺堂",
["shanzhuan"] = "擅专",  
[":shanzhuan"] = "出牌阶段开始时，你可以展示所有手牌，然后对一名其他角色发起军令：若其执行，你交给其1张手牌；若其不执行，你对其造成1点伤害。",  
["chizheng"] = "持政",  
[":chizheng"] = "锁定技。当你交给其他角色牌后，你摸1张牌。",  
["dudu"] = "毒妒",  
[":dudu"] = "锁定技。你对女性角色造成的伤害+1。",  
["@shanzhuan-give"] = "擅专：选择一张手牌交给目标角色"
}  
  
jin_guohuai = sgs.General(extension, "jin_guohuai", "jin", 3, false)  
  
zhefu = sgs.CreateTriggerSkill{  
    name = "zhefu",  
    events = {sgs.CardUsed, sgs.CardResponded},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        if player:getPhase() ~= sgs.Player_NotActive then return "" end  
          
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
          
        if card and card:isKindOf("BasicCard") then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if not p:isKongcheng() then  
                targets:append(p)  
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhefu-invoke", false, true)  
        if target then  
            room:broadcastSkillInvoke(self:objectName())  
            player:setTag("zhefu_target", sgs.QVariant(target:objectName()))  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local target_name = player:getTag("zhefu_target"):toString()  
        local target = room:findPlayer(target_name)  
        if not target or target:isKongcheng() then return false end  
          
        local card = nil  
        if event == sgs.CardUsed then  
            local use = data:toCardUse()  
            card = use.card  
        else  
            local response = data:toCardResponse()  
            card = response.m_card  
        end  
        
        local card_id = room:askForCardChosen(player, target, "h", self:objectName(), true)
        if card_id==-1 then return false end
        local chosen_card = sgs.Sanguosha:getCard(card_id)
        if chosen_card and chosen_card:isKindOf("BasicCard") then
            room:throwCard(card_id, target, player)
        end

        --[[
        local same_cards = false
        for _, id in sgs.qlist(target:handCards()) do  
            local hand_card = sgs.Sanguosha:getCard(id)  
            if hand_card:objectName() == card:objectName() then  
                room:throwCard(id, target, player) 
                same_cards = true
                break
            end  
        end  
        if not same_cards then
            local damage = sgs.DamageStruct()  
            damage.from = player  
            damage.to = target  
            damage.damage = 1  
            room:damage(damage)  
        end  
        ]]
        player:removeTag("zhefu_target")  
        return false  
    end  
}  
  
-- 技能2：遗毒  
yidu = sgs.CreateTriggerSkill{  
    name = "yidu",  
    events = {sgs.SlashMissed},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        local effect = data:toSlashEffect()  
        local target = effect.to  
        if target and target:isAlive() and not target:isKongcheng() and target:getHandcardNum() >= 2 then  
            return self:objectName()  
        end  
        return self:objectName()  
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
          
        if target:getHandcardNum() < 2 then return false end  
          
        local cards = room:askForCardsChosen(player, target, "hh", self:objectName(), 2, 2)  
        if cards:length() ~= 2 then return false end  
          
        local card1 = sgs.Sanguosha:getCard(cards:at(0))  
        local card2 = sgs.Sanguosha:getCard(cards:at(1))  
          
        room:showCard(target, cards:at(0))  
        room:showCard(target, cards:at(1))  
          
        if card1:isRed() == card2:isRed() then  
            room:throwCard(card1, target, player)  
            room:throwCard(card2, target, player)  
        end  
          
        return false  
    end  
}  
  
-- 添加技能到武将  
jin_guohuai:addSkill(zhefu)  
jin_guohuai:addSkill(yidu)  

sgs.LoadTranslationTable{
    ["jin_guohuai"] = "郭槐",
    ["#jin_guohuai"] = "晋室贤后",  
    ["zhefu"] = "哲妇",  
    [":zhefu"] = "你的回合外，使用或打出基础牌后，你可以选择一名有手牌的角色，你观看其所有手牌，然后弃置1张基础牌",  
    ["@zhefu-invoke"] = "你可以发动'哲妇'，选择一名有手牌的角色",  
    ["yidu"] = "遗毒",  
    [":yidu"] = "你使用杀被闪避后，你可以展示目标2张手牌，若颜色相同，你弃置这两张牌。",  
}

jin_simafu_junba = sgs.General(extension, "jin_simafu_junba", "jin", 3)  

BeiyuCard = sgs.CreateSkillCard{  
    name = "BeiyuCard",  
    target_fixed = true,  
    will_throw = false,  
    on_use = function(self, room, source, targets)  
        -- 摸牌至体力上限  
        local max_hp = source:getMaxHp()  
        local current_cards = source:getHandcardNum()  
        if current_cards < max_hp then  
            source:drawCards(max_hp - current_cards, "beiyu")  
        end  
          
        -- 选择一种颜色  
        local handcards = source:getHandcards()  
        if handcards:isEmpty() then return end  
          
        local red_cards = {}  
        local black_cards = {}  
          
        for _, card in sgs.qlist(handcards) do  
            if card:isRed() then  
                table.insert(red_cards, card:getEffectiveId())  
            elseif card:isBlack() then  
                table.insert(black_cards, card:getEffectiveId())  
            end  
        end  
          
        local choices = {}  
        if #red_cards > 0 then table.insert(choices, "red") end  
        if #black_cards > 0 then table.insert(choices, "black") end  
          
        if #choices > 0 then  
            local choice = room:askForChoice(source, "beiyu", table.concat(choices, "+"))  
            local cards_to_bottom = {}  
              
            if choice == "red" then  
                cards_to_bottom = red_cards  
            else  
                cards_to_bottom = black_cards  
            end  
              
            if #cards_to_bottom > 0 then  
                -- 将选定的牌置于牌堆底  
                local move = sgs.CardsMoveStruct()  
                move.card_ids = sgs.IntList()  
                for _, id in ipairs(cards_to_bottom) do  
                    move.card_ids:append(id)  
                end  
                move.from = source  
                move.from_place = sgs.Player_PlaceHand  
                move.to = nil  
                move.to_place = sgs.Player_DrawPileBottom  
                move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "beiyu", "")  
                room:moveCardsAtomic(move, true)  
            end  
        end  
    end  
}  
  
-- 备预视为技能  
beiyu = sgs.CreateZeroCardViewAsSkill{  
    name = "beiyu",  
    view_as = function(self)  
        return BeiyuCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return not player:hasUsed("#BeiyuCard")  
    end  
}

duchi = sgs.CreateTriggerSkill{  
    name = "duchi",  
    events = {sgs.TargetConfirming}, --sgs.CardEffected
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  

        local use = data:toCardUse()
        if use.card:getTypeId()==sgs.Card_TypeSkill then return "" end --不能是技能卡
        if use.from and use.from ~= player and use.to:contains(player) and not player:hasFlag("duchi_used") then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if player:askForSkillInvoke(self:objectName(), data) then  
            room:broadcastSkillInvoke(self:objectName(), player)  
            player:setFlags("duchi_used")  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        -- 从牌堆底摸一张牌  
        local bottom_cards = room:getDrawPile()  
        if not bottom_cards:isEmpty() then  
            local bottom_card = bottom_cards:last()  
            player:obtainCard(sgs.Sanguosha:getCard(bottom_card))  
        end  
          
        -- 展示所有手牌  
        room:showAllCards(player)  
          
        -- 检查颜色是否相同  
        handcards = player:getHandcards()
        local first_color = handcards:first():getColor()  
        local same_color = true  
          
        for _, card in sgs.qlist(handcards) do  
            if card:getColor() ~= first_color then  
                same_color = false  
                break  
            end  
        end  
          
        -- 如果颜色相同，此牌对你无效  
        if same_color then  
            local use = data:toCardUse()    
            sgs.Room_cancelTarget(use, player)
            data:setValue(use)           
        end  
          
        return false  
    end  
}  
  
jin_simafu_junba:addSkill(beiyu)
jin_simafu_junba:addSkill(duchi)
sgs.LoadTranslationTable{
["#jin_simafu_junba"] = "安平献王",  
["jin_simafu_junba"] = "司马孚",  
["illustrator:jin_simafu_junba"] = "画师名",  
["beiyu"] = "备预",  
[":beiyu"] = "出牌阶段限一次，你可以将手牌摸至体力上限，然后将一种颜色的所有手牌以任意顺序置于牌堆底。",  
["duchi"] = "督持",  
[":duchi"] = "每回合限一次，当你成为其他角色使用牌的目标后，你可以从牌堆底摸一张牌并展示所有手牌，若颜色均相同，此牌对你无效。"
}
jin_simayi = sgs.General(extension, "jin_simayi", "jin", 3)  
  
-- 技能1：鹰视  
yingshi = sgs.CreateTriggerSkill{  
    name = "yingshi",  
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
        return player:askForSkillInvoke(self:objectName(),data)
    end,  
    on_effect = function(self, event, room, player, data)  
        targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            targets:append(p)  
        end   
        first_target = room:askForPlayerChosen(player, targets, self:objectName(),   
            "yingshi-invoke", false, true)  

        second_targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:objectName() ~= first_target:objectName() then  
                second_targets:append(p)  
            end  
        end  
        second_target = room:askForPlayerChosen(player, second_targets, self:objectName(),  
            "yingshi-target", false, true)  
          
        -- 视为first_target对second_target使用知己知彼  
        local zhiji_card = sgs.Sanguosha:cloneCard("known_both")  
        zhiji_card:setSkillName(self:objectName())  
        zhiji_card:deleteLater()
        local use = sgs.CardUseStruct()  
        use.card = zhiji_card  
        use.from = first_target  
        use.to:append(second_target)  
          
        room:useCard(use)  
          
        -- 若使用者非自己，则摸一张牌  
        if first_target:objectName() ~= player:objectName() then  
            room:drawCards(player, 1, self:objectName())  
        end            
        return false  
    end  
}  
  
-- 技能2：瞬覆  
shunfu_card = sgs.CreateSkillCard{  
    name = "shunfu_card",  
    target_fixed = false,  
    will_throw = true,  
    filter = function(self, targets, to_select)  
        -- 选择未确定势力的角色，最多3个  
        if #targets >= 3 then return false end  
        if to_select:hasShownOneGeneral() then return false end  
        return to_select:objectName() ~= sgs.Self:objectName()  
    end,  
    on_use = function(self, room, source, targets)  
        room:setPlayerMark(source,"@shunfu",0)
        -- 令目标角色各摸两张牌  
        for i=1, #targets do  
            room:drawCards(targets[i], 2, "shunfu")  
        end  
          
        -- 视为依次对它们使用无距离限制且不可响应的杀  
       for i=1, #targets do  
            local slash = sgs.Sanguosha:cloneCard("slash")  
            slash:setSkillName("shunfu")  
              
            local use = sgs.CardUseStruct()  
            use.card = slash  
            use.from = source  
            use.to:append(targets[i])  
                          
            room:useCard(use)  
            slash:deleteLater()
        end  
    end  
}  
  
shunfu = sgs.CreateZeroCardViewAsSkill{  
    name = "shunfu",  
    limit_mark = "@shunfu",
    view_as = function(self, cards)  
        return shunfu_card:clone()  
    end,  
    enabled_at_play = function(self, player)  
        return player:getMark("@shunfu") > 0  
    end  
}  
   
-- 为武将添加技能  
jin_simayi:addSkill(yingshi)  
jin_simayi:addSkill(shunfu)  
  
sgs.LoadTranslationTable{
    ["jin_simayi"] = "晋司马懿",
    ["yingshi"] = "鹰视",
    [":yingshi"] = "出牌阶段开始时，你可以令一名角色视为对另一名角色使用【知己知彼】，若使用者非自已，则摸一张牌。",
    ["shunfu"] = "瞬覆",
    [":shunfu"] = "限定技，主动技。出牌阶段，你可令至多三名未确定势力角色各摸两张牌，然后你视为依次对它们使用一张无距离限制的【杀】。"
}

jin_wenyang = sgs.General(extension, "jin_wenyang", "jin", 4)  --qun

duanqiu = sgs.CreateTriggerSkill{  
    name = "duanqiu",  
    events = {sgs.EventPhaseStart},  
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then  
            -- 检查是否有其他势力角色  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if p:hasShownOneGeneral() and not player:isFriendWith(p) then  --p:getKingdom() ~= player:getKingdom()
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
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if p:hasShownOneGeneral() and not player:isFriendWith(p) then  
                targets:append(p) 
            end  
        end  
          
        local target_player = room:askForPlayerChosen(player, targets, self:objectName(), true, true)  

        if target_player then  
            local target_kingdom = target_player:getKingdom()  
            local duel_targets = {}  
              
            -- 找到该势力的所有角色  
            for _, p in sgs.qlist(room:getAllPlayers()) do  
                if target_player:hasShownOneGeneral() and p:hasShownOneGeneral() and target_player:isFriendWith(p) then  
                    table.insert(duel_targets, p)  
                end  
            end  
              
            -- 对每个目标使用决斗  
            for _, target in ipairs(duel_targets) do  
                local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)  
                duel:setSkillName(self:objectName())  
                  
                local use = sgs.CardUseStruct()  
                use.card = duel  
                use.from = player  
                use.to:append(target)  
                  
                room:useCard(use)  
                duel:deleteLater()
            end  
        end  
          
        room:setPlayerProperty(player, "duanqiu_target", sgs.QVariant(""))  
    end  
}

jin_wenyang:addSkill(duanqiu)
sgs.LoadTranslationTable{
["#jin_wenyang"] = "断虬勇将",  
["jin_wenyang"] = "晋文鸯",  
["illustrator:jin_wenyang"] = "画师名",  
["duanqiu"] = "断虬",  
[":duanqiu"] = "准备阶段，你可以选择一名其他势力角色，视为对该势力所有角色使用一张决斗。",
}
jin_zhangchunhua = sgs.General(extension, "jin_zhangchunhua", "jin", 3, false)  
ejue = sgs.CreateTriggerSkill{  
    name = "ejue",  
    frequency = sgs.Skill_Compulsory,  
    events = {sgs.DamageCaused},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        local damage = data:toDamage()  
        -- 检查是否为杀造成的伤害  
        if damage.card and damage.card:isKindOf("Slash") then  
            -- 检查目标是否为未确定势力角色  
            if damage.to and damage.to:isAlive() and not damage.to:hasShownOneGeneral() then  
                return self:objectName()  
            end  
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        -- 锁定技无需询问，直接触发  
        return player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local damage = data:toDamage()  
          
        -- 记录日志  
        local log = sgs.LogMessage()  
        log.type = "#AddDamage"  
        log.from = player  
        log.to:append(damage.to)  
        log.arg = self:objectName()  
        log.arg2 = tostring(damage.damage + 1)  
        room:sendLog(log)  
          
        -- 增加1点伤害  
        damage.damage = damage.damage + 1  
        data:setValue(damage)  
          
        return false  
    end  
} 
shangshiJin = sgs.CreateTriggerSkill{  
    name = "shangshiJin",  
    events = {sgs.EventPhaseEnd},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        -- 检查技能拥有者是否存活且拥有此技能  
        owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then
            return ""
        end
        -- 检查是否为回合结束阶段  
        if player:getPhase() == sgs.Player_Finish and owner:getHandcardNum()<owner:getLostHp() then  
            return self:objectName(), owner:objectName()
        end  
          
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local lost_hp = ask_who:getLostHp()  
        local current_handcards = ask_who:getHandcardNum()  
            
        if lost_hp > current_handcards then  
            local draw_num = lost_hp - current_handcards  
            room:drawCards(ask_who, draw_num, self:objectName())  
        end  
        return false  
    end  
}
jin_zhangchunhua:addSkill(ejue)
jin_zhangchunhua:addSkill(shangshiJin)  
sgs.LoadTranslationTable{
    ["jin_zhangchunhua"] = "晋张春华",
    ["ejue"] = "扼绝",
    [":ejue"] = "锁定技，对未确定势力角色使用【杀】造成伤害时，伤害+1",
    ["shangshiJin"] = "伤逝-晋",
    [":shangshiJin"] = "任意角色回合结束时，你可将手牌摸至已失去体力值"
}

wangrui = sgs.General(extension, "wangrui", "jin", 4)  --wu

ChengliuCard = sgs.CreateSkillCard{  
    name = "ChengliuCard",  
    target_fixed = false,  
    will_throw = false,  
    
    filter = function(self, targets, to_select)  
        if #targets >= 1 then return false end  
        if to_select:objectName() == sgs.Self:objectName() then return false end  
        -- 检查目标装备区数是否小于自己  
        return to_select:getEquips():length() < sgs.Self:getEquips():length()  
    end,
    
    on_use = function(self, room, source, targets)  
        local target = targets[1]  
        while true do
            if target:getEquips():length() >= source:getEquips():length() then
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(room:getOtherPlayers(source)) do  
                    if p:getEquips():length() < source:getEquips():length() then  
                        targets:append(p)  
                    end  
                end 
                if targets:isEmpty() then break end
                target = room:askForPlayerChosen(source, targets, self:objectName(), "@chengliu", true, true)  
            end 
            
            -- 交换装备区  
            if source:isAlive() and target:isAlive() then  
                local source_equips = source:getEquips()  
                local target_equips = target:getEquips()  
                
                -- 移除双方装备区的牌  
                local source_cards = sgs.IntList()  
                local target_cards = sgs.IntList()  
                
                for _, card in sgs.qlist(source_equips) do  
                    source_cards:append(card:getEffectiveId())  
                end  
                
                for _, card in sgs.qlist(target_equips) do  
                    target_cards:append(card:getEffectiveId())  
                end  
                local move1 = sgs.CardsMoveStruct()
                move1.card_ids = source_cards
                move1.from = source
                move1.to = target
                move1.to_place = sgs.Player_PlaceEquip
                move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,   
                                            source:objectName(), target:objectName(), "chengliu", "") 

                local move2 = sgs.CardsMoveStruct()
                move2.card_ids = target_cards
                move2.from = target
                move2.to = source
                move2.to_place = sgs.Player_PlaceEquip
                move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,   
                                            target:objectName(), source:objectName(), "chengliu", "")  
                
                local moves = sgs.CardsMoveList()
                moves:append(move1)
                moves:append(move2)
                
                room:moveCardsAtomic(moves, true)
            end
            -- 造成1点伤害  
            local damage = sgs.DamageStruct("chengliu", source, target, 1, sgs.DamageStruct_Normal)  
            room:damage(damage) 
        end
    end  
}  
  
-- 乘流技能  
Chengliu = sgs.CreateZeroCardViewAsSkill{  
    name = "chengliu",  
    view_as = function(self)  
        return ChengliuCard:clone()  
    end,  
    enabled_at_play = function(self, player)  
        if player:hasUsed("#ChengliuCard") then return false end  
        return true  
    end  
}

chengfeng = sgs.CreateTriggerSkill{  
    name = "chengfeng",  
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
                        if move.from and move.from:isAlive() and move.from:objectName()~=player:objectName() then
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
		end     
        return ""
    end,  
      
    on_cost = function(self, event, room, player, data)            
        return player:askForSkillInvoke(self:objectName(), data) 
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
        if room:askForDiscard(player,self:objectName(),1,1,true,true) then
            -- 使用AG界面让玩家选择一张牌  
            room:fillAG(equips, player)  
            local card_id = room:askForAG(player, equips, true, self:objectName())  
            room:clearAG(player) 
            if card_id == nil then return false end
            local equip = sgs.Sanguosha:getCard(card_id)
            if equip == nil then return false end

            room:obtainCard(player,card_id)
            local choice = room:askForChoice(player,self:objectName(),"yes+no")
            if choice == "yes" then
                local card = player:getHandcards():last() --最后一张手牌
                room:useCard(sgs.CardUseStruct(card, player, player), false)   
            end
        end
        return false  
    end  
}  
wangrui:addSkill(Chengliu)
wangrui:addSkill(chengfeng)
sgs.LoadTranslationTable{
    ["wangrui"] = "王睿",
    ["chengliu"] = "乘流",
    [":chengliu"] = "出牌阶段限一次，你可以选择装备区数小于你的一名角色，你和该角色交换装备区，然后你对其造成1点伤害，你可以重复这个操作。",
    ["chengfeng"] = "乘风",
    [":chengfeng"] = "你的回合外，其他角色因弃置而失去装备牌时，你可以弃置1张牌，获得其中一张装备牌，然后你可以选择是否使用该装备牌"
}

wangxiang = sgs.General(extension, "wangxiang", "jin", 3)  

bingxin = sgs.CreateTriggerSkill{  
    name = "bingxin",  
    events = {sgs.CardsMoveOneTime, sgs.HpChanged},  
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        -- 检查手牌数是否等于体力值  
        if player:getHandcardNum() ~= player:getHp() or player:getHandcardNum() == 0 then  
            return ""  
        end  
          
        -- 检查手牌颜色是否相同  
        local handcards = player:getHandcards()  
        if handcards:isEmpty() then return "" end  
          
        local first_color = handcards:first():getColor()  
        for _, card in sgs.qlist(handcards) do  
            if card:getColor() ~= first_color then  
                return ""  
            end  
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
        -- 展示所有手牌  
        room:showAllCards(player)
          
        -- 摸一张牌  
        player:drawCards(1, self:objectName())  
          
        -- 视为使用一张基本牌  
        --choices = {"analeptic"}
        if sgs.Slash_IsAvailable(player) then
            table.insert(choices, "slash")
        end
        if player:isWounded() then
            table.insert(choices, "peach")
        end
        if sgs.Analeptic_IsAvailable(player) then
            table.insert(choices, "analeptic")
        end
        if #choices > 0 then  
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            if choice and choice ~= "" then  
                local virtual_card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, -1)  
                virtual_card:setSkillName(self:objectName())  
                virtual_card:deleteLater()

                local use = sgs.CardUseStruct()  
                use.card = virtual_card  
                use.from = player  
                  
                -- 根据卡牌类型设置目标  
                if choice == "slash" then  
                    local targets = sgs.SPlayerList()  
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                        if player:inMyAttackRange(p) and not player:isFriendWith(p) then  
                            targets:append(p) 
                        end  
                    end  
                    target=room:askForPlayerChosen(player, targets, self:objectName(), false, true)
                    use.to:append(target)  
                elseif choice == "peach" then  
                    if player:isWounded() then  
                        use.to:append(player)  
                    end  
                elseif choice == "analeptic" then  
                    use.to:append(player)  
                end  
                  
                if not use.to:isEmpty() and choice ~= "jink" then  
                    room:useCard(use)  
                end  
            end  
        end  
          
        return false  
    end  
}

wangxiang:addSkill(bingxin)
sgs.LoadTranslationTable{
["#wangxiang"] = "卧冰求鲤",  
["wangxiang"] = "王祥",  
["illustrator:wangxiang"] = "画师名",  
["bingxin"] = "冰心",  
[":bingxin"] = "你手牌数或体力值变化时，若你的手牌数量等于体力值且颜色相同，你可以展示所有手牌并摸一张牌，视为使用一张基本牌。",
}
weiguan = sgs.General(extension, "weiguan", "jin", 3)  
weiguan_ol = sgs.General(extension, "weiguan_ol", "jin", 3)  
  
zhongyun = sgs.CreateTriggerSkill{  
    name = "zhongyun",  
    events = {sgs.HpChanged, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end        
        if event == sgs.HpChanged then  
            -- 受伤或回复体力后，检查手牌数是否等于体力值  
            if player:getHandcardNum() == player:getHp() and not player:hasFlag("zhongyun_hp") then  
                return self:objectName()  
            end  
        elseif event == sgs.CardsMoveOneTime then
            if player:getHandcardNum() ~= player:getHp() or player:hasFlag("zhongyun_move")then return "" end

            local move_datas = data:toList()
            for _, move_data in sgs.qlist(move_datas) do
                local move = move_data:toMoveOneTime()
                if move.from and move.from:isAlive() and move.from:objectName()==player:objectName() then
                    return self:objectName()
                end
                if move.to and move.to:isAlive() and move.to:objectName()==player:objectName() then
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
        if event == sgs.HpChanged then
            room:setPlayerFlag(player,"zhongyun_hp")
            local choice = room:askForChoice(player, self:objectName(),"recover+damage")  
            if choice == "recover" then  
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(room:getAlivePlayers()) do  
                    if p:isWounded() then  
                        targets:append(p) 
                    end  
                end  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhongyun-recover", true, true)  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(target, recover)  
            elseif choice == "damage" then
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                    if player:inMyAttackRange(p) and not player:isFriendWith(p) then  
                        targets:append(p) 
                    end  
                end  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhongyun-damage", true, true)  
                room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))  
            end  
        else  
            room:setPlayerFlag(player,"zhongyun_move")
            -- 可摸一张牌或弃置一名其他角色一张牌  
            local choices = {"draw"}  
            local others = room:getOtherPlayers(player)  
            for _, p in sgs.qlist(others) do  
                if not p:isAllNude() then  
                    table.insert(choices, "discard")  
                    break  
                end  
            end  
              
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            if choice == "draw" then  
                player:drawCards(1, self:objectName())  
            elseif choice == "discard" then  
                local targets = sgs.SPlayerList()  
                for _, p in sgs.qlist(others) do  
                    if not p:isAllNude() then  
                        targets:append(p)  
                    end  
                end  
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zhongyun-discard", true, true)  
                if target then  
                    --room:askForDiscard(target, self:objectName(), 1, 1, false, true)
                    local card_id = room:askForCardChosen(player, target, "hej", self:objectName())
                    room:throwCard(card_id, target, player)  
                end 
            end 
        end  
        return false  
    end  
}  
  
-- 技能2：神品  
shenpin = sgs.CreateTriggerSkill{  
    name = "shenpin",  
    events = {sgs.AskForRetrial},  
    can_trigger = function(self, event, room, player, data)  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
        return self:objectName()  
    end,  
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data)  
        local judge = data:toJudge()  
        local card = nil
        if judge.card:isRed() then
            card = room:askForCard(player, ".|black", "@shenpin-retrial", data, sgs.Card_MethodDiscard)  
        elseif judge.card:isBlack() then
            card = room:askForCard(player, ".|red", "@shenpin-retrial", data, sgs.Card_MethodDiscard)  
        end
        if card then
            room:retrial(card, player, judge, self:objectName(), false)
            judge:updateResult()  
        end  
        return false  
    end  
}  

chengxi = sgs.CreateTriggerSkill{  
    name = "chengxi",  
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
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data) 
        local chosen_target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@chengxi-choose", false, true)  
        if not chosen_target then return false end  
          
        -- 找到所有与选择角色势力相同的角色  
        local same_kingdom_players = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getAlivePlayers()) do  
            if p:isFriendWith(chosen_target) then  
                same_kingdom_players:append(p)  
            end  
        end  
          
        if same_kingdom_players:isEmpty() then return false end  
          
        -- 让这些角色摸2张牌然后弃2张牌  
        damage_count = 0 
        for _, p in sgs.qlist(same_kingdom_players) do  
            room:drawCards(p, 2, self:objectName())          
            for i = 1, 2 do  
                local card_id = room:askForCardChosen(p, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)  
                local card = sgs.Sanguosha:getCard(card_id)  
                
                -- 检查是否为非基本牌  
                if not card:isKindOf("BasicCard") then  
                    damage_count = damage_count + 1  
                end  
                
                -- 弃置该牌  
                room:throwCard(card, p, p) 
            end
        end  
          
        if damage_count > 0 then  
            for _, p in sgs.qlist(same_kingdom_players) do  
                local damage = sgs.DamageStruct()  
                damage.from = chosen_target  
                damage.to = p  
                damage.damage = 1 --damage_count  
                damage.reason = self:objectName()  
                room:damage(damage)  
            end  
        end  
          
        return false  
    end  
}

Jiantong = sgs.CreateTriggerSkill{  
    name = "jiantong",  
    events = {sgs.Damaged},  
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)
        local damage = data:toDamage()
        if damage.to and damage.to:isAlive() and damage.to:hasSkill(self:objectName()) then  
            return self:objectName(), damage.to:objectName()
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data, ask_who)  
        return ask_who:askForSkillInvoke(self:objectName(),data)  
    end,  
    on_effect = function(self, event, room, player, data, ask_who)  
        local targets = sgs.SPlayerList()  
        local all_players = room:getOtherPlayers(ask_who)  
        for _,p in sgs.qlist(all_players) do  
            if not p:isKongcheng() then  
                targets:append(p)  
            end  
        end  
          
        if targets:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(ask_who, targets, self:objectName(), "@jiantong-choose", false, true)  
        if not target or target:isKongcheng() then return false end  

        -- 查看并选择目标角色至多2张手牌  
        local chosen_cards = room:askForCardsChosen(ask_who, target, "hh", self:objectName(), 0, 2, true)            
        -- 检查自己是否有装备区的牌  
        local equips = ask_who:getEquips()  
        if equips:isEmpty() then return false end  
        -- 选择装备区的1张牌  
        local equip_id = room:askForCardChosen(ask_who, ask_who, "e", self:objectName())  
        if equip_id == -1 then return false end  

        for _,id in sgs.qlist(chosen_cards) do  
            room:obtainCard(ask_who, id) 
        end          
        room:obtainCard(target, equip_id)  
        return false  
    end  
}
-- 添加技能到武将  
weiguan_ol:addSkill(zhongyun)  
weiguan_ol:addSkill(shenpin)
weiguan:addSkill(chengxi)
weiguan:addSkill(Jiantong)  
sgs.LoadTranslationTable{
    ["weiguan"] = "卫瓘",
    ["weiguan_ol"] = "卫瓘-OL",
    ["zhongyun"] = "忠允",  
    [":zhongyun"] = "每回合每项限一次。你体力变化后，若手牌数等于体力值，可令一名角色回复1点体力或对攻击范围内一名其他势力角色造成1点伤害；你手牌数变化后，若手牌数等于体力值，可摸一张牌或弃置一名其他角色一张牌。",
    ["@zhongyun-recover"] = "忠允：选择一名角色，令其恢复1点体力",  
    ["@zhongyun-damage"] = "忠允：选择一名攻击范围内的其他势力角色，对其造成1点伤害",  
    ["@zhongyun-discard"] = "忠允：选择一名其他角色，弃置其一张牌",  
    
    -- 神品技能  
    ["shenpin"] = "神品",  
    [":shenpin"] = "判定牌生效前，你可打出一张颜色不同的牌代替之。",

    ["chengxi"] = "乘隙",
    [":chengxi"] = "准备阶段，你可选择一名角色，令所有与该角色势力相同的角色摸2张牌然后弃2张牌，若弃牌中包含非基本牌，则该角色对所有目标造成1点伤害。",

    ["jiantong"] = "监统",
    [":jiantong"] = "你受到伤害后，你可以观看一名角色的所有手牌，然后你可以用装备区的1张牌和该角色至多2张手牌交换"
}

xuangongzhu = sgs.General(extension, "xuangongzhu", "jin", 3, false)  
qimei = sgs.CreateTriggerSkill{  
    name = "qimei",  
    events = {sgs.HpChanged, sgs.MaxHpChanged, sgs.CardsMoveOneTime},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        --player是触发事件的角色
        local owner = room:findPlayerBySkillName(self:objectName())
        if not (owner and owner:isAlive() and owner:hasSkill(self:objectName())) then   
            return ""   
        end  
          
        if event == sgs.CardsMoveOneTime then  
            local move = data:toMoveOneTime()  
            -- 检查是否为手牌变化  
            if move.from and move.from:objectName() ~= owner:objectName() then 
                -- 其他角色手牌数变化  
                if move.from:getHandcardNum()==owner:getHandcardNum() then
                    return self:objectName(), owner:objectName()
                end  
            elseif move.to and move.to:objectName() ~= owner:objectName() then
                if move.to:getHandcardNum()==owner:getHandcardNum() then
                    return self:objectName(), owner:objectName()
                end
            --elseif move.from:objectName()~=owner:objectName() and move.to:objectName()~=owner:objectName() and player:getHandcardNum()==owner:getHandcardNum() then
            --    return self:objectName(), owner:objectName()
            end
        elseif event == sgs.HpChanged or event == sgs.MaxHpChanged then  
            -- 体力值变化事件
            if player==owner then --自己体力变化
                return self:objectName(), owner:objectName()
            elseif player:getHp()==owner:getHp() then --其他人体力变化，并且和自己体力相等
                return self:objectName(), owner:objectName()
            end
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data, ask_who)            
        if event == sgs.CardsMoveOneTime then  
            return ask_who:askForSkillInvoke(self:objectName(),data)
        elseif event == sgs.HpChanged or event == sgs.MaxHpChanged then
            return ask_who:askForSkillInvoke(self:objectName(),data)
        end  
        return false  
    end,  
      
    on_effect = function(self, event, room, player, data, ask_who)  
        if event == sgs.CardsMoveOneTime then  
            room:drawCards(ask_who, 1, self:objectName())
        elseif event == sgs.HpChanged or event == sgs.MaxHpChanged then
            if player==ask_who then  
                local targets = sgs.SPlayerList()  
                -- 自己体力变化，寻找体力相同的其他角色  
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                    if p:isAlive() and p:getHp() == player:getHp() then  
                        targets:append(p)  
                    end  
                end
                if targets:isEmpty() then  return false  end  
                local target = nil  
                if targets:length() == 1 then  
                    target = targets:first()  
                else  
                    target = room:askForPlayerChosen(player, targets, self:objectName(), "@qimei-choose", true, true)  
                end
                if target then
                    room:drawCards(target, 1, self:objectName())
                end
            else  
                room:drawCards(ask_who, 1, self:objectName())
            end
        end
        return false  
    end,  
}
zhuiji1 = sgs.CreateTriggerSkill{  
    name = "zhuiji1",  
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    --frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then  
            return ""  
        end  
          
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then  
            return self:objectName()  
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then  
            if player:getMark("zhuiji1_recover") > 0 or player:getMark("zhuiji1_draw") > 0 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            local choices = {"zhuiji1_recover", "zhuiji1_draw", "cancel"}  
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
            if choice ~= "cancel" then  
                room:setPlayerProperty(player, "zhuiji1_choice", sgs.QVariant(choice))  
                room:broadcastSkillInvoke(self:objectName(), player)  
                return true  
            end  
        else  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        if event == sgs.EventPhaseStart then  
            local choice = player:property("zhuiji1_choice"):toString()  
              
            if choice == "zhuiji1_recover" then  
                -- 恢复1点体力  
                local recover = sgs.RecoverStruct()  
                recover.who = player  
                recover.recover = 1  
                room:recover(player, recover)  
                room:setPlayerMark(player, "zhuiji1_recover", 1)  
            elseif choice == "zhuiji1_draw" then  
                -- 摸2张牌  
                player:drawCards(2, self:objectName())  
                room:setPlayerMark(player, "zhuiji1_draw", 1)  
            end  
              
            room:setPlayerProperty(player, "zhuiji1_choice", sgs.QVariant(""))  
        else  
            -- 出牌阶段结束时的效果  
            if player:getMark("zhuiji1_recover") > 0 then  
                -- 弃置2张牌  
                if player:getCardCount(true) >= 2 then  
                    room:askForDiscard(player, self:objectName(), 2, 2, false, true)  
                end  
                room:setPlayerMark(player, "zhuiji1_recover", 0)  
            elseif player:getMark("zhuiji1_draw") > 0 then  
                -- 失去1点体力  
                room:loseHp(player, 1)  
                room:setPlayerMark(player, "zhuiji1_draw", 0)  
            end  
        end  
          
        return false  
    end  
}

xuangongzhu:addSkill(qimei)
xuangongzhu:addSkill(zhuiji1)

sgs.LoadTranslationTable{
["#xuangongzhu"] = "举案齐眉",  
["xuangongzhu"] = "宣公主",  
["illustrator:xuangongzhu"] = "画师名",  
["qimei"] = "齐眉",  
[":qimei"] = "当其他角色手牌数变化后，若你的手牌数与其相同，你可以摸一张牌；当你的体力值变化后，你可以令一名体力值和你相同的角色摸一张牌；当其他角色体力值变化后，若你的体力值与其相同，你可以摸一张牌。",  
["zhuiji1"] = "追姬",  
[":zhuiji1"] = "出牌阶段开始时，你可以选择：1.恢复1点体力，出牌阶段结束时弃置2张牌；2.摸2张牌，出牌阶段结束时失去1点体力。",
}

yanghu_yingbian = sgs.General(extension, "yanghu_yingbian", "jin", 3) -- 蜀势力，4血，男性（默认）  

chongde = sgs.CreateTriggerSkill{  
    name = "chongde",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent,      
    can_trigger = function(self, event, room, player, data)  
        if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and not player:isChained() then  
            -- 检查是否有其他势力角色  
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
                if not p:hasShownOneGeneral() or not player:isFriendWith(p) then  
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
        local targets = sgs.SPlayerList()  
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do  
            if not p:hasShownOneGeneral() or not player:isFriendWith(p) then  
                targets:append(p)  
            end  
        end  
          
        if not targets:isEmpty() then  
            target = room:askForPlayerChosen(player, targets, self:objectName(), "@chongde-choose", false, true)  
        end   
          
        if target then  
            local source_hand = player:getHandcardNum()  
            local target_hand = target:getHandcardNum()  
            local diff = math.abs(source_hand - target_hand)  
            local x = math.min(diff, player:getMaxHp())  
              
            if x > 0 then  
                -- 使用askForExchange获取弃牌ID列表  
                local player_cards = room:askForExchange(player, self:objectName(), x, 0, "@chongde-discard", "", ".|.|.|hand,equipped")  
                local target_cards = room:askForExchange(target, self:objectName(), x, 0, "@chongde-discard", "", ".|.|.|hand,equipped")  
                  
                -- 弃置选择的牌  
                if not player_cards:isEmpty() then  
                    local dummy = sgs.DummyCard(player_cards)  
                    room:throwCard(dummy, player, player)  
                end  
                  
                if not target_cards:isEmpty() then  
                    local dummy = sgs.DummyCard(target_cards)  
                    room:throwCard(dummy, target, target)  
                end  
                  
                -- 根据实际弃置数量摸牌  
                if not player_cards:isEmpty() then  
                    player:drawCards(player_cards:length(), self:objectName())  
                end  
                if not target_cards:isEmpty() then  
                    target:drawCards(target_cards:length(), self:objectName())  
                end  
            end  
        end  
        -- 横置自己  
        if not player:isChained() then  
            player:setChained(true)  
            room:broadcastProperty(player, "chained")  
            room:setEmotion(player, "chain")  
        end 
        --player:setChained(not player:isChained()) 
        return false  
    end  
}

rongwei = sgs.CreateTriggerSkill{  
    name = "rongwei",  
    events = {sgs.TargetConfirmed},  
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if not player:hasSkill(self:objectName()) or not player:isChained() then return "" end  
        if player:hasFlag("rongwei_used") then return "" end  
          
        local use = data:toCardUse()  
        if use.to:length() == 1 and use.to:contains(player) then  
            if use.card:isKindOf("Slash") or (use.card:isKindOf("TrickCard") and not use.card:isKindOf("DelayedTrick")) then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        return room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(use.from:objectName()))  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local use = data:toCardUse()  
        local from = use.from  
          
        -- 标记本回合已使用  
        room:setPlayerFlag(player, "rongwei_used")  
          
        -- 双方各摸1张牌  
        player:drawCards(1, self:objectName())  
        if from then  
            from:drawCards(1, self:objectName())  
        end  
          
        -- 令此牌对自己无效  
        sgs.Room_cancelTarget(use, player)
        data:setValue(use)  
          
        return false
    end  
}  
yanghu_yingbian:addSkill(chongde)
yanghu_yingbian:addSkill(rongwei)
-- 翻译表  
sgs.LoadTranslationTable{      
["#yanghu_yingbian"] = "德威并重",  
["yanghu_yingbian"] = "羊祜",  
["illustrator:yanghu_yingbian"] = "画师名",  
["chongde"] = "崇德",  
[":chongde"] = "出牌阶段开始时，若你不处于连环状态，你可以选择一名其他势力角色，你与其各弃置至多X张牌并摸等量张牌，然后你横置，X为你与其的手牌数之差且至多为你的体力上限。",  
["rongwei"] = "戎卫",  
[":rongwei"] = "每回合限一次，当你成为杀或非延时性锦囊的唯一目标时，若你处于连环状态，你可以与此牌使用者各摸1张牌，然后令此牌对你无效。",  
}  
yangjun = sgs.General(extension, "yangjun", "jin", 4)  
neiji = sgs.CreateTriggerSkill{  
    name = "neiji",  
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)  
        if player:getPhase() ~= sgs.Player_Play then return "" end  
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end  
          
        -- 检查是否有其他势力角色  
        local others = room:getOtherPlayers(player)  
        for _, p in sgs.qlist(others) do  
            if not player:isFriendWith(p) and p:getHandcardNum()>=2 and player:getHandcardNum()>=2 then  
                return self:objectName()  
            end  
        end  
        return ""  
    end,  
      
    on_cost = function(self, event, room, player, data)  
        return player:askForSkillInvoke(self:objectName(),data)  
    end,  
      
    on_effect = function(self, event, room, player, data)  
        local others = sgs.SPlayerList()  
        local all_others = room:getOtherPlayers(player)  
        for _, p in sgs.qlist(all_others) do  
            if not player:isFriendWith(p) and p:getHandcardNum()>=2 and player:getHandcardNum()>=2 then  
                others:append(p)  
            end  
        end  
          
        if others:isEmpty() then return false end  
          
        local target = room:askForPlayerChosen(player, others, self:objectName(), "@neiji-choose", false, true)  
          
        if not target then return false end  
          
        local player_show_num = math.min(2, player:getHandcardNum())  
        local player_cards = room:askForExchange(player, self:objectName(), player_show_num, player_show_num,   
            "@neiji-show:::" .. tostring(player_show_num), "", ".")  
          
        -- 目标选择要展示的手牌（最多2张）  
        local target_show_num = math.min(2, target:getHandcardNum())  
        local target_cards = room:askForExchange(target, self:objectName(), target_show_num, target_show_num,  
            "@neiji-show:::" .. tostring(target_show_num), "", ".")  
          
        -- 统计并弃置杀  
        local player_slash_count = 0  
        local target_slash_count = 0  
        local player_slash_cards = sgs.IntList()  
        local target_slash_cards = sgs.IntList()  
          
        for _, id in sgs.qlist(player_cards) do  
            local card = sgs.Sanguosha:getCard(id)  
            room:showCard(player,id)
            if card:isKindOf("Slash") then  
                player_slash_count = player_slash_count + 1  
                room:throwCard(card, player, player) 
            end  
        end  
          
        for _, id in sgs.qlist(target_cards) do  
            local card = sgs.Sanguosha:getCard(id)  
            room:showCard(target,id)
            if card:isKindOf("Slash") then  
                target_slash_count = target_slash_count + 1  
                room:throwCard(card, target, target)  
            end  
        end  
          
        local total_slash = player_slash_count + target_slash_count  
          
        if total_slash > 1 then  
            -- 各摸3张牌  
            room:drawCards(player, 3, self:objectName())  
            room:drawCards(target, 3, self:objectName())  
        elseif total_slash == 1 then  
            -- 未弃置杀的角色视为对弃置杀的角色使用决斗  
            local duel_user = nil  
            local duel_target = nil  
              
            if player_slash_count == 0 and target_slash_count == 1 then  
                duel_user = player  
                duel_target = target  
            elseif player_slash_count == 1 and target_slash_count == 0 then  
                duel_user = target    
                duel_target = player  
            end  
              
            if duel_user and duel_target then  
                local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)  
                duel:setSkillName("_" .. self:objectName())  
                duel:deleteLater()
                if not duel_user:isCardLimited(duel, sgs.Card_MethodUse) and not duel_user:isProhibited(duel_target, duel) then  
                    room:useCard(sgs.CardUseStruct(duel, duel_user, duel_target))  
                end  
            end  
        end   
          
        return false  
    end  
}  
yangjun:addSkill(neiji)
sgs.LoadTranslationTable{
["#yangjun"] = "权倾朝野",  
["yangjun"] = "杨骏",   
["illustrator:yangjun"] = "画师名",  
["neiji"] = "内忌",  
[":neiji"] = "出牌阶段开始时，你可以选择一名其他势力角色，你与其各展示2张手牌，然后你与其弃置展示的所有杀，若弃置的所有杀数量大于1，你与其各摸3张牌；等于1，未弃置杀的角色视为对弃置杀的角色使用一张决斗。",
["@neiji-choose"] = "内忌：选择一名其他势力角色"
}
zhouchu = sgs.General(extension, "zhouchu", "jin", 3)  

shanduan = sgs.CreateTriggerSkill{  
    name = "shanduan",  
    events = {sgs.EventPhaseStart},  
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)  
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then  
            return self:objectName()  
        end  
        return ""  
    end,  
    on_cost = function(self, event, room, player, data)  
        local choices = {"shanduan_draw", "shanduan_range", "shanduan_slash", "cancel"}  
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))  
        if choice ~= "cancel" then  
            room:setPlayerProperty(player, "shanduan_choice", sgs.QVariant(choice))  
            return true  
        end  
        return false  
    end,  
    on_effect = function(self, event, room, player, data)  
        local choice = player:property("shanduan_choice"):toString()  
        local hp = player:getHp()  
          
        if choice == "shanduan_draw" then  
            -- 调整摸牌数为体力值  
            room:setPlayerFlag(player, "shanduan_draw")  
        elseif choice == "shanduan_range" then  
            -- 调整攻击范围为体力值  
            room:setPlayerFlag(player, "shanduan_range")  
        elseif choice == "shanduan_slash" then  
            -- 调整杀的次数为体力值  
            room:setPlayerFlag(player, "shanduan_slash")  
        end  
          
        room:setPlayerProperty(player, "shanduan_choice", sgs.QVariant(""))  
        return false  
    end  
}  
  
-- 善断摸牌数调整  
shanduan_draw = sgs.CreateDrawCardsSkill{  
    name = "shanduan_draw",  
    draw_num_func = function(self, target, n)  
        if target:hasFlag("shanduan_draw") then  
            return target:getHp()
        end  
        return n
    end  
}  
  
-- 善断攻击范围调整  
shanduan_range = sgs.CreateAttackRangeSkill{  
    name = "shanduan_range",  
    extra_func = function(self, target, include_weapon)  
        if target:hasFlag("shanduan_range") then  
            return target:getHp()-target:getAttackRange()
        end  
        return 0 --target:getAttackRange()
    end  
}  
  
-- 善断杀次数调整  
shanduan_slash = sgs.CreateTargetModSkill{  
    name = "shanduan_slash",  
    pattern = "Slash",  
    residue_func = function(self, from, card)  
        if from:hasFlag("shanduan_slash") then  
            local extra = from:getHp() - 1  
            return extra  
        end  
        return 0  
    end  
}  


yilieCard = sgs.CreateSkillCard{  
    name = "yilieCard",  
    target_fixed = true,  
    will_throw = true,  
      
    on_use = function(self, room, source, targets) 
        --room:setPlayerFlag(source, "yilie_used")
        local choices = {}
        if sgs.Slash_IsAvailable(source) then
            table.insert(choices, "slash")
        end
        if sgs.Analeptic_IsAvailable(source) then
            table.insert(choices, "analeptic")
        end
        if source:isWounded() then
            table.insert(choices, "peach")
        end
        if #choices == 0 then return false end
        choice=room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
        card = sgs.Sanguosha:cloneCard(choice)  
        card:setSkillName("yilie")
        card:deleteLater()
        if choice=="slash" then
            local targets = sgs.SPlayerList()  
            for _, p in sgs.qlist(room:getOtherPlayers(source)) do  
                if source:canSlash(p,nil,false) and source:inMyAttackRange(p) then  
                    targets:append(p) 
                end  
            end  
            target=room:askForPlayerChosen(source, targets, self:objectName(), false, true)
            local use = sgs.CardUseStruct()  
            use.from = source  
            use.to:append(target)   
            use.card = card  
            room:useCard(use)
        else
            local use = sgs.CardUseStruct()  
            use.from = source  
            use.to:append(source)   
            use.card = card  
            room:useCard(use)
        end
    end  
}
yilie = sgs.CreateViewAsSkill{  
    name = "yilie",  
    n = 2,  
    response_or_use = true,   
    view_filter = function(self, selected, to_select)  
        if #selected == 0 then  
            return not to_select:isEquipped()  
        elseif #selected == 1 then  
            return not to_select:isEquipped() and to_select:sameColorWith(selected[1])  
        end  
        return false  
    end,  
    view_as = function(self, cards)  
        if #cards == 2 then 
            local card_name = ""  
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()  
            if pattern == "slash" then  
                card_name = "slash"  
            elseif pattern == "jink" then  
                card_name = "jink"  
            elseif string.find(pattern,"peach") then  
                card_name = "peach"  
            elseif string.find(pattern,"analeptic") then  
                card_name = "analeptic"  
            end  
            local view_as_card = nil
            if card_name ~= "" then
                view_as_card = sgs.Sanguosha:cloneCard(card_name)  
            else
                view_as_card = yilieCard:clone()
            end
            view_as_card:addSubcard(cards[1]:getId())  
            view_as_card:addSubcard(cards[2]:getId())  
            view_as_card:setSkillName(self:objectName())  
            view_as_card:setShowSkill(self:objectName())  
            return view_as_card  
            
        end  
        return nil  
    end,  
    enabled_at_play = function(self, player)  
        return player:getHandcardNum() >= 2 --and not player:hasFlag("yilie_used")
    end,  
    enabled_at_response = function(self, player, pattern)  
        if player:getHandcardNum() < 2 then return false end  
        return pattern=="slash" or pattern=="jink" or string.find(pattern,"peach") or  string.find(pattern,"analeptic") 
    end  
}
--sgs.insertRelatedSkills(extension, "shanduan", "#shanduan_draw", "#shanduan_range", "#shanduan_slash")
zhouchu:addSkill(shanduan)
zhouchu:addSkill(shanduan_draw)
zhouchu:addSkill(shanduan_range)
zhouchu:addSkill(shanduan_slash)
zhouchu:addSkill(yilie)
sgs.LoadTranslationTable{
["#zhouchu"] = "除三害",  
["zhouchu"] = "周处",  
["illustrator:zhouchu"] = "画师名",  
["shanduan"] = "善断",  
[":shanduan"] = "准备阶段，你可以令你本回合以下一项调整为你的体力值：1.本回合摸牌数；2.本回合攻击范围；3.本回合使用杀的次数。",  
["yilie"] = "义烈",  
[":yilie"] = "你可以将2张颜色相同的手牌当作一张基本牌使用或打出。",
}


------------------------------------------
--沧海中修改为晋势力的武将------------------
------------------------------------------
wangyi_canghai = sgs.General(extension, "wangyi_canghai", "jin", 3) -- 吴苋，蜀势力，3血，女性  
wenyang_canghai = sgs.General(extension, "wenyang_canghai", "jin", 3) -- 吴苋，蜀势力，3血，女性  
zhangchangpu_canghai = sgs.General(extension, "zhangchangpu_canghai", "jin", 3, false)  
zhonghui_canghai = sgs.General(extension, "zhonghui_canghai", "jin", 3)  -- 吴国，4血，男性  

wangyi_canghai:addSkill("zhenlie")
wangyi_canghai:addSkill("miji")

wenyang_canghai:addSkill("qili")  
wenyang_canghai:addSkill("duoqi")  
  
zhangchangpu_canghai:addSkill("xingshen")  
zhangchangpu_canghai:addSkill("yanjiao")  

zhonghui_canghai:addSkill("fushu")
  
-- 翻译表  
sgs.LoadTranslationTable{  
    ["wangyi_canghai"] = "王异",
    ["wenyang_canghai"] = "文鸯-沧海",
    ["zhangchangpu_canghai"] = "张昌蒲",  
    ["zhonghui_canghai"] = "钟会",
}  

------------------------------------------
--军八中修改为晋势力的武将------------------
------------------------------------------
caofang_junba = sgs.General(extension, "caofang_junba", "jin", 3)  -- 吴国，4血，男性  
caomao_junba = sgs.General(extension, "caomao_junba", "jin", 3)  -- 吴国，4血，男性  
haozhao_junba = sgs.General(extension, "haozhao_junba", "jin", 4)  -- 吴国，4血，男性  
jianshi_junba = sgs.General(extension, "jianshi_junba", "jin", 3, false)  -- 吴国，4血，男性  
jikang_junba = sgs.General(extension, "jikang_junba", "jin", 3)  
simahui_junba = sgs.General(extension, "simahui_junba", "jin", 3)  
simafu_junba = sgs.General(extension, "simafu_junba", "jin", 3)  -- 吴国，4血，男性  
wangxu_junba = sgs.General(extension, "wangxu_junba", "jin", 3)  
xiahoushi_junba = sgs.General(extension, "xiahoushi_junba", "jin", 3, false)  -- 吴国，4血，男性  
zhangchunhua_junba = sgs.General(extension, "zhangchunhua_junba", "jin", 3, false)  -- 吴国，4血，男性  
zhaoyun_jin = sgs.General(extension, "zhaoyun_jin", "jin", 3)  -- 吴国，4血，男性  

caofang_junba:addSkill("zhimin")

caomao_junba:addSkill("qianlong")  
caomao_junba:addSkill("fensi")

haozhao_junba:addSkill("zhengu")

jianshi_junba:addSkill("jiusi")

jikang_junba:addSkill("qingxian")  
jikang_junba:addSkill("juexiang")

simahui_junba:addSkill("longfeng")  
simahui_junba:addSkill("longfengYehuo")  
simahui_junba:addSkill("yinshi")  

simafu_junba:addSkill("panxiang")
simafu_junba:addSkill("chenjie")

wangxu_junba:addSkill("shepan")
wangxu_junba:addSkill("kaiji")

xiahoushi_junba:addSkill("qiaoshi")
xiahoushi_junba:addSkill("yanyu")

zhangchunhua_junba:addSkill("liangyan")  
zhangchunhua_junba:addSkill("minghui")  

zhaoyun_jin:addSkill("sushou")
zhaoyun_jin:addSkill("zhongjie")

sgs.LoadTranslationTable{        
    ["caofang_junba"] = "曹芳",  
    ["caomao_junba"] = "曹髦",
    ["caoren_junba"] = "星曹仁",
    ["haozhao_junba"] = "郝昭",
    ["jianshi_junba"] = "剑侍",
    ["jikang_junba"] = "嵇康",  
    ["simahui_junba"] = "司马徽",  
    ["simafu_junba"] = "司马孚",  
    ["wangxu_junba"] = "王旭",
    ["xiahoushi_junba"] = "夏侯氏",
    ["zhangchunhua_junba"] = "星张春华",  
    ["zhaoyun_jin"] = "晋赵云",
}  

zhangchunhua_jiang1 = sgs.General(extension, "zhangchunhua_jiang1", "jin", 3, false)  -- 吴国，4血，男性 

zhangchunhua_jiang1:addSkill("xiuhua")
zhangchunhua_jiang1:addSkill("cuanni")

sgs.LoadTranslationTable{        
    ["zhangchunhua_jiang1"] = "张春华",  
}  

--caoren_junba = sgs.General(extension, "caoren_junba", "jin", 3)  -- 吴国，4血，男性  

------------------------------------------
--hero中修改为晋势力的武将------------------
------------------------------------------
baozhen_jin = sgs.General(extension, "baozhen_jin", "jin", 3)  --wei,jin
jifa_jin = sgs.General(extension, "jifa_jin", "jin", 4)  --wei,jin
liubei_jin = sgs.General(extension, "liubei_jin", "jin", 3)  --shu,jin  
luzhishen_jin = sgs.General(extension, "luzhishen_jin", "jin", 4)  --wei,jin  
maosui_jin = sgs.General(extension, "maosui_jin", "jin", 3)  --jin,qun
miyue_jin = sgs.General(extension, "miyue_jin", "jin", 3, false)  --qun,jin  
simayi_jin = sgs.General(extension, "simayi_jin", "jin", 3)  --wei,jin
sunwu_jin = sgs.General(extension, "sunwu_jin", "jin", 3)  --wei,jin  
tangbohu_jin = sgs.General(extension, "tangbohu_jin", "jin", 3)  --wei,jin  
--weizifu_jin = sgs.General(extension, "weizifu_jin", "jin", 4, false)  
yuanshitianzun_jin = sgs.General(extension, "yuanshitianzun_jin", "jin", 3)  --wei,jin
yuxuanji_jin = sgs.General(extension, "yuxuanji_jin", "jin", 3, false)  --wei,jin
zhuangzhou_jin = sgs.General(extension, "zhuangzhou_jin", "jin", 3) --qun,jin  
zhubajie_jin = sgs.General(extension, "zhubajie_jin", "jin", 3) --wu,jin  
zuchongzhi_jin = sgs.General(extension, "zuchongzhi_jin", "jin", 3)  --wei,jin

dianwei_jin = sgs.General(extension, "dianwei_jin", "jin", 3)
mozi_jin = sgs.General(extension, "mozi_jin", "jin", 3)
suqin_jin = sgs.General(extension, "suqin_jin", "jin", 3)
--wangyangming_jin = sgs.General(extension, "wangyangming_jin", "jin", 3)
xunzi_jin = sgs.General(extension, "xunzi_jin", "jin", 3)
yuchigong_jin = sgs.General(extension, "yuchigong_jin", "jin", 4)
yuwenhuaji_jin = sgs.General(extension, "yuwenhuaji_jin", "jin", 4)
zhaokuo_jin = sgs.General(extension, "zhaokuo_jin", "jin", 4)
zhouchu_jin = sgs.General(extension, "zhouchu_jin", "jin", 4)
zhuowenjun_jin = sgs.General(extension, "zhuowenjun_jin", "jin", 3)
zhuzhishan_jin = sgs.General(extension, "zhuzhishan_jin", "jin", 3)

baozhen_jin:addSkill("pingyuan")
baozhen_jin:addSkill("shenduan")

jifa_jin:addSkill("taofa")
jifa_jin:addSkill("zhubao")

liubei_jin:addSkill("jieyi1")
liubei_jin:addSkill("jieyi2")

luzhishen_jin:addSkill("dili")
luzhishen_jin:addSkill("kuangchan")

maosui_jin:addSkill("tuoying")
maosui_jin:addSkill("zijian")

miyue_jin:addSkill("yuumie")
miyue_jin:addSkill("zhangquan")

simayi_jin:addSkill("zhuolue")
simayi_jin:addSkill("langgu")

sunwu_jin:addSkill("qiji")
sunwu_jin:addSkill("bingsheng")

tangbohu_jin:addSkill("fengliu")
tangbohu_jin:addSkill("luobi")

yuanshitianzun_jin:addSkill("yuanshi")
yuanshitianzun_jin:addSkill("tianzun")

yuxuanji_jin:addSkill("zheliu")
yuxuanji_jin:addSkill("feiqing")

zhuangzhou_jin:addSkill("mengdie")
zhuangzhou_jin:addSkill("xiaoyao_maxCards")
zhuangzhou_jin:addSkill("xiaoyao_targetmod")
zhuangzhou_jin:addSkill("xiaoyaoTurned")

zhubajie_jin:addSkill("tianpeng")

zuchongzhi_jin:addSkill("yuanzhou")
zuchongzhi_jin:addSkill("jingsuan")

dianwei_jin:addSkill("zhonghu")  
dianwei_jin:addSkill("kuangzhan")

mozi_jin:addSkill("jianai")  
mozi_jin:addSkill("feigong")  
mozi_jin:addSkill("feigongSlash")  

suqin_jin:addSkill("hezong")  
suqin_jin:addSkill("wangji")

xunzi_jin:addSkill("quyong")  

yuchigong_jin:addSkill("huwei")  

yuwenhuaji_jin:addSkill("cuanni")  
yuwenhuaji_jin:addSkill("jiandi")  
yuwenhuaji_jin:addSkill("cuanquan")

zhaokuo_jin:addSkill("zhishangtanbing")

zhouchu_jin:addSkill("gaiguo")  
zhouchu_jin:addSkill("chuhai")  

zhuowenjun_jin:addSkill("qinxin")
zhuowenjun_jin:addSkill("xiangshou")

zhuzhishan_jin:addSkill("caoshu")  
zhuzhishan_jin:addSkill("linmo")
sgs.LoadTranslationTable{        
    ["baozhen_jin"] = "包拯",  
    ["jifa_jin"] = "姬发",
    ["liubei_jin"] = "义刘备",
    ["luzhishen_jin"] = "鲁智深",  
    ["maosui_jin"] = "毛遂",  
    ["miyue_jin"] = "芈月",  
    ["simayi_jin"] = "司马懿",
    ["sunwu_jin"] = "孙武",  
    ["tangbohu_jin"] = "唐伯虎",
    ["yuanshitianzun_jin"] = "元始天尊",
    ["yuxuanji_jin"] = "鱼玄机",
    ["zhuangzhou_jin"] = "庄周",
    ["zhubajie_jin"] = "猪八戒",
    ["zuchongzhi_jin"] = "祖冲之",
    ["dianwei_jin"] = "典韦",
    ["mozi_jin"] = "墨子",
    ["suqin_jin"] = "苏秦",
    ["xunzi_jin"] = "荀子",
    ["yuchigong_jin"] = "尉迟恭",
    ["yuwenhuaji_jin"] = "宇文化及",
    ["zhaokuo_jin"] = "赵括",
    ["zhouchu_jin"] = "周处",
    ["zhuowenjun_jin"] = "卓文君",
    ["zhuzhishan_jin"] = "祝枝山",
}  
return {extension}