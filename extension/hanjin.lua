extension = sgs.Package("hanjin", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

shenpei_hanjin = sgs.General(hanjin, "shenpei_hanjin", "qun", 3)

local function duceUseLureTiger(room, user, opponent)
    if not (user and user:isAlive()) then return end

    local lure_tiger = sgs.Sanguosha:cloneCard("lure_tiger", sgs.Card_NoSuit, 0)
    lure_tiger:setSkillName("duce")

    if user:isCardLimited(lure_tiger, sgs.Card_MethodUse) then
        lure_tiger:deleteLater()
        return
    end

    local candidates = sgs.SPlayerList()
    local empty_targets = sgs.PlayerList()
    for _, p in sgs.qlist(room:getOtherPlayers(user)) do
        if p:objectName() ~= opponent:objectName()
            and lure_tiger:targetFilter(empty_targets, p, user)
            and not user:isProhibited(p, lure_tiger) then
            candidates:append(p)
        end
    end

    if not candidates:isEmpty() then
        local max_num = math.min(2, candidates:length())
        local targets = room:askForPlayersChosen(user, candidates, "duce", 1, max_num,
            "@duce-lure:" .. opponent:objectName())
        local use = sgs.CardUseStruct()
        use.card = lure_tiger
        use.from = user
        for _, p in sgs.qlist(targets) do
            use.to:append(p)
        end
        room:useCard(use)
    end

    lure_tiger:deleteLater()
end

local function duceUseArcheryAttack(room, user)
    if not (user and user:isAlive()) then return end

    local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
    archery_attack:setSkillName("duce")
    if user:isCardLimited(archery_attack, sgs.Card_MethodUse) then
        archery_attack:deleteLater()
        return
    end
    local use = sgs.CardUseStruct()
    use.card = archery_attack
    use.from = user
    room:useCard(use)
    archery_attack:deleteLater()
end

duce = sgs.CreateTriggerSkill{
    name = "duce",
    events = {sgs.EventPhaseStart, sgs.Pindian},
    frequency = sgs.Skill_NotFrequent,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if not (player and player:isAlive() and player:hasSkill(self:objectName())
                and player:getPhase() == sgs.Player_Start and not player:isKongcheng()) then
                return ""
            end

            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isKongcheng() then
                    return self:objectName()
                end
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
        if event == sgs.Pindian then return true end

        local candidates = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if not p:isKongcheng() then
                candidates:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, candidates, self:objectName(), "@duce-pindian", true, true)
        if not target then return false end

        room:setPlayerProperty(player, "duce_target", sgs.QVariant(target:objectName()))
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            local target_name = player:property("duce_target"):toString()
            room:setPlayerProperty(player, "duce_target", sgs.QVariant(""))
            local target = nil
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:objectName() == target_name then
                    target = p
                    break
                end
            end
            if target and target:isAlive() and not player:isKongcheng() and not target:isKongcheng() then
                player:pindian(target,self:objectName())
            end
            return false
        end

        local pindian = data:toPindian()
        local from = pindian.from
        local to = pindian.to
        if pindian.from_number > pindian.to_number then
            duceUseLureTiger(room, to, from)
            duceUseArcheryAttack(room, from)
        elseif pindian.from_number < pindian.to_number then
            duceUseLureTiger(room, from, to)
            duceUseArcheryAttack(room, to)
        else
            duceUseLureTiger(room, from, to)
            duceUseLureTiger(room, to, from)
        end
        return false
    end,
}

shuairanSummonCard = sgs.CreateArraySummonCard{
    name = "shuairan",
    mute = true,
}

shuairanVS = sgs.CreateArraySummonSkill{
    name = "shuairan",
    array_summon_card = shuairanSummonCard,
}

shuairan = sgs.CreateTriggerSkill{
    name = "shuairan",
    is_battle_array = true,
    battle_array_type = sgs.Formation,
    view_as_skill = shuairanVS,
    can_preshow = false,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved,
        sgs.DFDebut, sgs.Death, sgs.EventAcquireSkill, sgs.EventLoseSkill,
        sgs.RemoveStateChanged},

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}

        for _, owner in sgs.qlist(room:getAllPlayers()) do
            if owner:hasSkill(self:objectName()) then
                local old_count = owner:getMark("shuairan_formation_count")
                local new_count = owner:isAlive() and owner:getFormation():length() or 0
                room:setPlayerMark(owner, "shuairan_formation_count", new_count)

                if event ~= sgs.GameStart and owner:isAlive()
                    and owner:hasShownSkill(self:objectName())
                    and room:alivePlayerCount() >= 4 and old_count > 0
                    and new_count ~= old_count then
                    room:setPlayerMark(owner, "shuairan_change", new_count > old_count and 1 or -1)
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
        end

        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(ask_who, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        room:doBattleArrayAnimate(ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local change = ask_who:getMark("shuairan_change")
        room:setPlayerMark(ask_who, "shuairan_change", 0)

        local formation = ask_who:getFormation()
        if change > 0 then
            for _, p in sgs.qlist(formation) do
                if p:isAlive() then room:drawCards(p, 1, self:objectName()) end
            end
        elseif change < 0 then
            for _, p in sgs.qlist(formation) do
                if p:isAlive() then
                    local recover = sgs.RecoverStruct()
                    recover.who = ask_who
                    recover.recover = 1
                    room:recover(p, recover)
                end
            end
        end
        return false
    end,
}

zhanglu_hanjin = sgs.General(hanjin, "zhanglu_hanjin", "qun", 3)

mijiaoCard = sgs.CreateSkillCard{
    name = "mijiaoCard",
    skill_name = "mijiao",
    target_fixed = false,
    will_throw = false,

    filter = function(self, targets, to_select, source)
        return #targets == 0 and to_select:objectName() ~= source:objectName()
            and math.abs(to_select:getHandcardNum() - source:getHandcardNum()) <= 2
    end,

    on_use = function(self, room, source, targets)
        local target = targets[1]
        if not (target and target:isAlive()) then return end

        local source_num = source:getHandcardNum()
        local target_num = target:getHandcardNum()
        if target_num < source_num then
            target:drawCards(source_num - target_num, "mijiao")
            if source:isAlive() and target:isAlive()
                and source:askForSkillInvoke("mijiao_damage",
                    sgs.QVariant("damage:" .. target:objectName())) then
                local damage = sgs.DamageStruct()
                damage.from = source
                damage.to = target
                damage.damage = 1
                damage.reason = "mijiao"
                room:damage(damage)
            end
        elseif target_num > source_num then
            room:askForDiscard(target, "mijiao", target_num - source_num,
                target_num - source_num, false, false)
            if source:isAlive() and target:isAlive() and target:isWounded()
                and source:askForSkillInvoke("mijiao_recover",
                    sgs.QVariant("recover:" .. target:objectName())) then
                local recover = sgs.RecoverStruct()
                recover.who = source
                recover.recover = 1
                room:recover(target, recover)
            end
        end
    end,
}

mijiao = sgs.CreateZeroCardViewAsSkill{
    name = "mijiao",
    view_as = function(self)
        local card = mijiaoCard:clone()
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        if player:hasUsed("#mijiaoCard") then return false end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if math.abs(p:getHandcardNum() - player:getHandcardNum()) <= 2 then
                return true
            end
        end
        return false
    end,
}

local function guianBigKingdomSignature(player)
    local kingdoms = player:getBigKingdoms("guian", sgs.Max)
    local names = {}
    for i = 1, #kingdoms do
        table.insert(names, tostring(kingdoms[i]))
    end
    table.sort(names)
    return table.concat(names, "+")
end

guian = sgs.CreateTriggerSkill{
    name = "guian",
    frequency = sgs.Skill_Frequent,
    events = {sgs.GameStart, sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved,
        sgs.DFDebut, sgs.Death, sgs.CardsMoveOneTime, sgs.EventAcquireSkill,
        sgs.EventLoseSkill, sgs.RemoveStateChanged},

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:getAllPlayers()) do
            if owner:hasSkill(self:objectName()) then
                local tag_name = "guian_big_kingdoms_" .. owner:objectName()
                local init_name = "guian_big_kingdoms_initialized_" .. owner:objectName()
                local initialized = room:getTag(init_name):toBool()
                local old_signature = room:getTag(tag_name):toString()
                local new_signature = guianBigKingdomSignature(owner)
                room:setTag(tag_name, sgs.QVariant(new_signature))
                room:setTag(init_name, sgs.QVariant(true))

                if event ~= sgs.GameStart and initialized
                    and old_signature ~= new_signature and owner:isAlive()
                    and owner:hasShownSkill(self:objectName()) then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local targets = room:askForPlayersChosen(ask_who, room:getAlivePlayers(),
            self:objectName(), 1, 2, "@guian-choose")
        if targets:isEmpty() then return false end

        for _, p in sgs.qlist(targets) do
            room:setPlayerMark(p, "guian_target_" .. ask_who:objectName(), 1)
        end
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local mark_name = "guian_target_" .. ask_who:objectName()
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getMark(mark_name) > 0 then
                room:setPlayerMark(p, mark_name, 0)
                if p:isAlive() then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
        return false
    end,
}

huoyi_hanjin = sgs.General(hanjin, "huoyi_hanjin", "shu", 4)

sijuVS = sgs.CreateZeroCardViewAsSkill{
    name = "siju",
    guhuo_type = "t",
    view_as = function(self)
        local card_name = sgs.Self:getTag(self:objectName()):toString()
        if card_name == "" then return nil end

        local card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_NoSuit, 0)
        if not card then return nil end
        card:setCanRecast(false)
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,

    enabled_at_play = function(self, player)
        return player:faceUp()
    end,
    vs_card_names = function(self, selected)
        if #selected > 0 then return "" end
        return "duel+fire_attack+savage_assault+archery_attack+burning_camps+drowning"
    end,
}

siju = sgs.CreateTriggerSkill{
    name = "siju",
    view_as_skill = sijuVS,
    events = {sgs.PreCardUsed},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if use.card and use.card:getSkillName() == self:objectName() and player:faceUp() then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        player:turnOver()

        local has_friend = false
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:willBeFriendWith(p) then
                has_friend = true
                break
            end
        end
        if not has_friend then
            local use = data:toCardUse()
            use.card:setFlags("GlobalCardUseDisresponsive")
            data:setValue(use)
        end
        return false
    end,
}

zhongjue = sgs.CreateTriggerSkill{
    name = "zhongjue",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and (player:isChained() or not player:faceUp())) then
            return ""
        end
        if player:isNude() then return "" end
        local damage = data:toDamage()
        if damage.damage > 0 then return self:objectName() end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if not player:hasShownSkill(self:objectName())
            and not player:askForSkillInvoke(self:objectName(), data) then
            return false
        end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local max_num = math.min(damage.damage, player:getCards("he"):length())
        if max_num > 0 then
            local card_ids = room:askForExchange(player, self:objectName(), max_num, 1,
                "@zhongjue-discard:::" .. tostring(damage.damage), "", ".|.|.|hand,equipped")
            if not card_ids:isEmpty() then
                local dummy = sgs.DummyCard(card_ids)
                room:throwCard(dummy, player, player, self:objectName())
                dummy:deleteLater()

                damage.damage = damage.damage - card_ids:length()
                data:setValue(damage)
            end
        end

        if player:isAlive() and (player:isKongcheng() or player:getHp() == 1) then
            if player:isChained() then
                room:setPlayerProperty(player, "chained", sgs.QVariant(false))
            end
            if not player:faceUp() then
                player:turnOver()
            end
        end

        return damage.damage <= 0
    end,
}

liuba_hanjin = sgs.General(hanjin, "liuba_hanjin", "shu", 3)

local function liuzhuanDiamondDiscards(room, data)
    local card_ids = sgs.IntList()
    local move_datas = data:toList()
    for _, move_data in sgs.qlist(move_datas) do
        local move = move_data:toMoveOneTime()
        local basic_reason = bit32.band(move.reason.m_reason,
            sgs.CardMoveReason_S_MASK_BASIC_REASON)
        if move.to_place == sgs.Player_DiscardPile
            and basic_reason == sgs.CardMoveReason_S_REASON_DISCARD then
            for _, card_id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(card_id)
                if card and card:getSuit() == sgs.Card_Diamond
                    and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                    card_ids:append(card_id)
                end
            end
        end
    end
    return card_ids
end

liuzhuan = sgs.CreateTriggerSkill{
    name = "liuzhuan",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}

        if event == sgs.CardsMoveOneTime then
            if liuzhuanDiamondDiscards(room, data):isEmpty() then return "" end
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if owner:isAlive() then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
        elseif player and player:isAlive() and player:getPhase() == sgs.Player_Finish
            and player:hasSkill(self:objectName()) and not player:getPile("coin"):isEmpty() then
            return self:objectName()
        end

        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            if ask_who:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), ask_who)
                return true
            end
            return false
        end

        room:sendCompulsoryTriggerLog(ask_who, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            local card_ids = liuzhuanDiamondDiscards(room, data)
            if not card_ids:isEmpty() then
                ask_who:addToPile("coin", card_ids, true)
            end
            return false
        end

        local coin_num = ask_who:getPile("coin"):length()
        if coin_num < 1 then return false end
        ask_who:clearOnePrivatePile("coin")

        local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
        ex_nihilo:setSkillName(self:objectName())

        if ask_who:isCardLimited(ex_nihilo, sgs.Card_MethodUse) then
            ex_nihilo:deleteLater()
            return false
        end

        local candidates = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not ask_who:isProhibited(p, ex_nihilo) then
                candidates:append(p)
            end
        end

        if not candidates:isEmpty() then
            local max_num = math.min(coin_num, candidates:length())
            local targets = room:askForPlayersChosen(ask_who, candidates,
                self:objectName(), 1, max_num, "@liuzhuan-use:::" .. tostring(coin_num), false)
            local use = sgs.CardUseStruct()
            use.card = ex_nihilo
            use.from = ask_who
            for _, p in sgs.qlist(targets) do
                use.to:append(p)
            end
            room:useCard(use)
        end
        ex_nihilo:deleteLater()
        return false
    end,
}

langji = sgs.CreateTriggerSkill{
    name = "langji",
    events = {sgs.CardUsed},

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasShownSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if use.to:contains(player) then
            room:setPlayerFlag(player, "ji")--成为牌的目标，添加标记
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

langjiMod = sgs.CreateDistanceSkill{
    name = "#langji-distance",
    correct_func = function(self, from, to)
        if from:hasShownSkill("langji") and not from:hasFlag("ji") then
			return 1
		end
        if to:hasShownSkill("langji") and not to:hasFlag("ji") then
			return 1
		end
        return 0
	end
}

sunlang_hanjin = sgs.General(hanjin, "sunlang_hanjin", "shu", 4, true)

local function juyiIsDamageTrick(card)
    if not (card and card:isKindOf("TrickCard") and not card:isKindOf("DelayedTrick")) then
        return false
    end
    local damage_tricks = {
        "Duel", "ArcheryAttack", "SavageAssault",
        "BurningCamps", "Drowning", "FireAttack"
    }
    for _, class_name in ipairs(damage_tricks) do
        if card:isKindOf(class_name) then return true end
    end
    return false
end

juyi = sgs.CreateTriggerSkill{
    name = "juyi",
    events = {sgs.TargetConfirming},
    frequency = sgs.Skill_NotFrequent,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return "" end
        local use = data:toCardUse()
        if not (use.card and juyiIsDamageTrick(use.card) and use.to:contains(player)) then
            return ""
        end

        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and (owner:objectName() == player:objectName()
                or player:getHp() == 1) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
        if not use.to:contains(player) then return false end
        if ask_who:askForSkillInvoke(self:objectName(),
            sgs.QVariant("invoke:" .. player:objectName() .. ":" .. use.card:objectName())) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
        if not use.to:contains(player) then return false end

        sgs.Room_cancelTarget(use, player)
        data:setValue(use)

        local choices = {"juyi_losehp"}
        if use.from and use.from:isAlive()
            and use.from:objectName() ~= ask_who:objectName()
            and ask_who:canSlash(use.from, nil, false) then --false表示无距离限制
            table.insert(choices, 1, "juyi_slash")
        end

        local choice = room:askForChoice(ask_who, self:objectName(),
            table.concat(choices, "+"), data)
        if choice == "juyi_slash" then
            local slash = room:askForUseSlashTo(ask_who, use.from,
                "@juyi-slash:" .. use.from:objectName(), false, false, false)--是否距离限制，是否禁止额外目标，是否计入次数
            if not slash and ask_who:isAlive() then
                room:loseHp(ask_who, 1)
            end
        elseif ask_who:isAlive() then
            room:loseHp(ask_who, 1)
        end
        return false
    end,
}

yingshou = sgs.CreateOneCardViewAsSkill{  
    name = "yingshou",  
    filter_pattern = "TrickCard|heart|.|.",  --red heart trick cards
    view_as = function(self, card)  
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())  
        slash:addSubcard(card:getId())  
        slash:setSkillName(self:objectName())  
        slash:setShowSkill(self:objectName())  
        return slash  
    end  
}

xiahoulan_hanjin = sgs.General(extension, "xiahoulan_hanjin", "shu", 3, false)

local function lanqieDiscardedCards(room, data, owner)
    local card_ids = sgs.IntList()
    for _, move_data in sgs.qlist(data:toList()) do
        local move = move_data:toMoveOneTime()
        local basic_reason = bit32.band(move.reason.m_reason,
            sgs.CardMoveReason_S_MASK_BASIC_REASON)
        if move.to_place == sgs.Player_DiscardPile
            and basic_reason == sgs.CardMoveReason_S_REASON_DISCARD
            and move.reason.m_playerId == owner:objectName() then
            for _, card_id in sgs.qlist(move.card_ids) do
                if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                    card_ids:append(card_id)
                end
            end
        end
    end
    return card_ids
end

lanqie = sgs.CreateTriggerSkill{
    name = "lanqie",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.EventPhaseStart,
        sgs.CardUsed, sgs.Damage, sgs.CardFinished},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player and player:isAlive()
            and player:getPhase() == sgs.Player_RoundStart
            and player:hasSkill(self:objectName()) then
            room:setPlayerMark(player, "lanqie_disabled", 0)
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from and use.card and use.card:getSkillName() == self:objectName() then
                local serial = use.from:getMark("lanqie_serial") + 1
                room:setPlayerMark(use.from, "lanqie_serial", serial)
                use.card:setTag("lanqie_serial", sgs.QVariant(serial))
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.to and damage.card
                and damage.card:getSkillName() == self:objectName() then
                local serial = damage.card:getTag("lanqie_serial"):toInt()
                if serial > 0 then
                    room:setPlayerMark(damage.to,
                        "lanqie_damaged_" .. damage.from:objectName() .. "_" .. tostring(serial), 1)
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then
            local skill_list = {}
            local owner_list = {}
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if owner:isAlive() and owner:getMark("lanqie_disabled") == 0
                    and not lanqieDiscardedCards(room, data, owner):isEmpty() then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
            return table.concat(skill_list, "|"), table.concat(owner_list, "|")
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then return "" end
            local skill_list = {}
            local owner_list = {}
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if owner:isAlive() and owner:getMark("lanqie_disabled") == 0
                    and not owner:getPile("storm"):isEmpty() then
                    table.insert(skill_list, self:objectName())
                    table.insert(owner_list, owner:objectName())
                end
            end
            return table.concat(skill_list, "|"), table.concat(owner_list, "|")
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from and use.from:isAlive() and use.card
                and use.card:getSkillName() == self:objectName() then
                return self:objectName(), use.from:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            if ask_who:askForSkillInvoke(self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), ask_who)
                return true
            end
            return false
        end
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.CardsMoveOneTime then
            local card_ids = lanqieDiscardedCards(room, data, ask_who)
            if not card_ids:isEmpty() then
                ask_who:addToPile("storm", card_ids, true)
            end
            return false
        elseif event == sgs.EventPhaseChanging then
            local pile = ask_who:getPile("storm")
            if pile:isEmpty() then return false end

            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:setSkillName(self:objectName())
            for _, card_id in sgs.qlist(pile) do
                slash:addSubcard(card_id)
            end

            local candidates = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(ask_who)) do
                if ask_who:canSlash(p, slash, true) then
                    candidates:append(p)
                end
            end
            if not candidates:isEmpty() then
                local max_num = math.min(pile:length(), candidates:length())
                local targets = room:askForPlayersChosen(ask_who, candidates,
                    self:objectName(), 1, max_num,
                    "@lanqie-slash:::" .. tostring(pile:length()), false)
                local use = sgs.CardUseStruct()
                use.card = slash
                use.from = ask_who
                for _, p in sgs.qlist(targets) do
                    use.to:append(p)
                end
                room:useCard(use, false)
            end
            slash:deleteLater()
            return false
        end

        local use = data:toCardUse()
        local serial = use.card:getTag("lanqie_serial"):toInt()
        local all_damaged = serial > 0 and not use.to:isEmpty()
        for _, p in sgs.qlist(use.to) do
            local damage_mark = "lanqie_damaged_" .. ask_who:objectName()
                .. "_" .. tostring(serial)
            if p:getMark(damage_mark) == 0 then all_damaged = false end
            room:setPlayerMark(p, damage_mark, 0)
        end
        if all_damaged then
            room:setPlayerMark(ask_who, "lanqie_disabled", 1)
        end

        local available_ids = sgs.IntList()
        for _, card_id in sgs.qlist(use.card:getSubcards()) do
            if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                available_ids:append(card_id)
            end
        end
        local recipients = room:getOtherPlayers(ask_who)
        if ask_who:isAlive() and not available_ids:isEmpty() and not recipients:isEmpty()
            and ask_who:askForSkillInvoke("lanqie_give", data) then
            for _, card_id in sgs.qlist(available_ids) do
                if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                    local target = room:askForPlayerChosen(ask_who, recipients,
                        "lanqie_give", "@lanqie-give:::" ..
                        sgs.Sanguosha:getCard(card_id):objectName(), false, false)
                    room:obtainCard(target, card_id, true)
                end
            end
        end
        return false
    end,
}

jinqi = sgs.CreateTriggerSkill{
    name = "jinqi",
    events = {sgs.GameStart},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:hasSkill(self:objectName())
            and player:getMark("jinqi_maxhp") == 0) then
            return ""
        end

        local head = player:getActualGeneral1()
        local deputy = player:getActualGeneral2()
        local other = nil
        if head and head:ownSkill(self:objectName()) then
            other = deputy
        elseif deputy and deputy:ownSkill(self:objectName()) then
            other = head
        end
        if other and other:isFemale() then
            room:setPlayerMark(player, "jinqi_maxhp", 1)
            room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
            room:setPlayerProperty(player, "hp", sgs.QVariant(player:getHp() + 1))
        end
        return ""
    end,
}

zulang_hanjin = sgs.General(extension, "zulang_hanjin", "qun", 4, true)

raoxi = sgs.CreateTriggerSkill{
    name = "raoxi",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_RoundStart then
            if player:hasSkill(self:objectName()) then
                room:setPlayerMark(player, "raoxi_used_round", 0)
            end
        elseif event == sgs.CardsMoveOneTime then
            local current = room:getCurrent()
            if not (current and current:getPhase() ~= sgs.Player_NotActive) then return end

            for _, move_data in sgs.qlist(data:toList()) do
                local move = move_data:toMoveOneTime()
                if move.from and (move.from_places:contains(sgs.Player_PlaceHand)
                    or move.from_places:contains(sgs.Player_PlaceEquip)) then
                    for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if move.from:objectName() == owner:objectName() then
                            room:setPlayerFlag(owner, "raoxi_lost_turn")
                        end
                    end
                end
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (event == sgs.EventPhaseEnd and player and player:isAlive()
            and player:getPhase() == sgs.Player_Finish) then
            return ""
        end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:objectName() ~= player:objectName()
                and not owner:hasFlag("raoxi_lost_turn")
                and owner:getMark("raoxi_used_round") < 2
                and not owner:isCardLimited(slash, sgs.Card_MethodUse)
                and owner:canSlash(player, slash, false)
                and not owner:isProhibited(player, slash) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        slash:deleteLater()
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            room:addPlayerMark(ask_who, "raoxi_used_round")
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if not (ask_who:isAlive() and player:isAlive()) then return false end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        if not ask_who:isCardLimited(slash, sgs.Card_MethodUse)
            and ask_who:canSlash(player, slash, false)
            and not ask_who:isProhibited(player, slash) then
            local use = sgs.CardUseStruct()
            use.card = slash
            use.from = ask_who
            use.to:append(player)
            room:useCard(use, false)
        end
        slash:deleteLater()
        return false
    end,
}

jiangji_hanjin = sgs.General(extension, "jiangji_hanjin", "wei", 3)

xuxieVS = sgs.CreateOneCardViewAsSkill{
    name = "xuxie",
    filter_pattern = ".|.|.|hand,equipped",
    response_pattern = "nullification",
    response_or_use = true,

    view_as = function(self, card)
        local nullification = sgs.Sanguosha:cloneCard("nullification",
            card:getSuit(), card:getNumber())
        nullification:addSubcard(card:getId())
        nullification:setSkillName(self:objectName())
        nullification:setShowSkill(self:objectName())
        return nullification
    end,

    enabled_at_play = function(self, player)
        return false
    end,

    enabled_at_response = function(self, player, pattern)
        return pattern == "nullification" and player:getMark("xuxie_used_round") == 0
    end,

    enabled_at_nullification = function(self, player)
        return player:getMark("xuxie_used_round") == 0 and not player:isNude()
    end,
}

xuxie = sgs.CreateTriggerSkill{
    name = "xuxie",
    events = {sgs.CardUsed, sgs.CardFinished, sgs.EventPhaseStart},
    view_as_skill = xuxieVS,
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_RoundStart then
            room:setPlayerMark(player, "xuxie_used_round", 0)
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())) then
            return ""
        end
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Nullification")
                and use.card:getSkillName() == self:objectName()
                and not room:getOtherPlayers(player):isEmpty() then
                return self:objectName()
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Nullification")
                and use.card:getSkillName() == self:objectName()
                and use.card:getTag("xuxie_target"):toString() ~= "" then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if event == sgs.CardFinished then return true end

        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player),
            self:objectName(), "@xuxie-give", false, false)
        if not target then return false end
        local use = data:toCardUse()
        use.card:setTag("xuxie_target", sgs.QVariant(target:objectName()))
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            room:addPlayerMark(player, "xuxie_used_round")
            local target = room:findPlayer(use.card:getTag("xuxie_target"):toString())
            if not (target and target:isAlive()) then return false end

            local pattern = nil
            if use.card:isRed() then
                pattern = ".|red"
            elseif use.card:isBlack() then
                pattern = ".|black"
            end
            if pattern then
                room:setPlayerCardLimitation(player, "use", pattern, true)
                room:setPlayerCardLimitation(target, "use", pattern, true)
            end
            return false
        end

        local target = room:findPlayer(use.card:getTag("xuxie_target"):toString())
        if not (target and target:isAlive()) then return false end
        local card_ids = sgs.IntList()
        for _, card_id in sgs.qlist(use.card:getSubcards()) do
            if room:getCardPlace(card_id) == sgs.Player_DiscardPile
                or room:getCardPlace(card_id) == sgs.Player_PlaceTable then
                card_ids:append(card_id)
            end
        end
        if not card_ids:isEmpty() then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                player:objectName(), target:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(card_ids, target, sgs.Player_PlaceHand, reason)
            room:moveCardsAtomic(move, true)
        end
        return false
    end,
}

local function liuluTarget(event, data, owner)
    if event == sgs.Damaged then
        local damage = data:toDamage()
        if damage.to and damage.to:objectName() == owner:objectName()
            and damage.from and damage.from:isAlive()
            and damage.from:objectName() ~= owner:objectName() then
            return damage.from
        end
        return nil
    end

    for _, move_data in sgs.qlist(data:toList()) do
        local move = move_data:toMoveOneTime()
        if move.to and move.to:isAlive()
            and move.to:objectName() ~= owner:objectName()
            and (move.to_place == sgs.Player_PlaceHand
                or move.to_place == sgs.Player_PlaceEquip) then
            local directly_from_owner = move.from
                and move.from:objectName() == owner:objectName()
            local given_by_xuxie = move.reason.m_skillName == "xuxie"
                and move.reason.m_playerId == owner:objectName()
            if directly_from_owner or given_by_xuxie then
                return move.to
            end
        end
    end
    return nil
end

liulu = sgs.CreateTriggerSkill{
    name = "liulu",
    events = {sgs.Damaged, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and liuluTarget(event, data, owner) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        local target = liuluTarget(event, data, ask_who)
        if not target then return false end
        ask_who:setTag("liulu_target", sgs.QVariant(target:objectName()))
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        ask_who:removeTag("liulu_target")
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        local target = room:findPlayer(ask_who:getTag("liulu_target"):toString())
        ask_who:removeTag("liulu_target")
        if not (target and target:isAlive()) then return false end

        target:drawCards(1, self:objectName())
        if ask_who:isAlive() and target:isAlive() and not target:isNude() then
            local card_id = room:askForCardChosen(ask_who, target, "he",
                self:objectName(), false, sgs.Card_MethodNone)
            room:obtainCard(ask_who, card_id, false)
        end
        return false
    end,
}

chengpu_hanjin = sgs.General(extension, "chengpu_hanjin", "wu", 4)

lihuoVS = sgs.CreateViewAsSkill{
    name = "lihuo",
    n = 2,

    view_filter = function(self, selected, to_select)
        return #selected < 2 and not sgs.Self:isJilei(to_select)
    end,

    view_as = function(self, cards)
        if #cards ~= 2 then return nil end
        local fire_slash = sgs.Sanguosha:cloneCard("fire_slash",
            sgs.Card_SuitToBeDecided, -1)
        for _, card in ipairs(cards) do
            fire_slash:addSubcard(card)
        end
        fire_slash:setSkillName(self:objectName())
        fire_slash:setShowSkill(self:objectName())
        return fire_slash
    end,

    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and player:getCardCount(true) >= 2
    end,
}

lihuo = sgs.CreateTriggerSkill{
    name = "lihuo",
    events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
    view_as_skill = lihuoVS,
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("FireSlash")
                and use.card:getSkillName() == self:objectName() then
                use.card:setTag("lihuo_damage", sgs.QVariant(0))
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("FireSlash")
                and damage.card:getSkillName() == self:objectName() then
                local total = damage.card:getTag("lihuo_damage"):toInt()
                damage.card:setTag("lihuo_damage", sgs.QVariant(total + damage.damage))
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (event == sgs.CardFinished and player and player:isAlive()
            and player:hasSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if not (use.card and use.card:isKindOf("FireSlash")
            and use.card:getSkillName() == self:objectName()
            and use.card:getTag("lihuo_damage"):toInt() > 1) then
            return ""
        end
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:isFriendWith(p) then return self:objectName() end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        local candidates = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:isFriendWith(p) then candidates:append(p) end
        end
        if candidates:isEmpty() then return false end

        local target = room:askForPlayerChosen(player, candidates, self:objectName(),
            "@lihuo-yinyang", true, true)
        if not target then return false end
        player:setTag("lihuo_target", sgs.QVariant(target:objectName()))
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local target = room:findPlayer(player:getTag("lihuo_target"):toString())
        player:removeTag("lihuo_target")
        if not (target and target:isAlive()) then return false end
        room:addPlayerMark(player, "@halfmaxhp")
        room:addPlayerMark(target, "@halfmaxhp")
        return false
    end,
}

lihuoMod = sgs.CreateTargetModSkill{
    name = "#lihuo-target",
    pattern = "Slash",

    extra_target_func = function(self, player, card)
        if card and card:getSkillName() == "lihuo" then return 1 end
        return 0
    end,
}

chunlaoAttachVS = sgs.CreateZeroCardViewAsSkill{
    name = "chunlao_attach",
    response_pattern = "analeptic",

    view_as = function(self)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
        analeptic:setSkillName(self:objectName())
        return analeptic
    end,

    enabled_at_play = function(self, player)
        return player:getMark("@halfmaxhp") > 0 and sgs.Analeptic_IsAvailable(player)
    end,

    enabled_at_response = function(self, player, pattern)
        return player:getMark("@halfmaxhp") > 0
            and string.find(pattern, "analeptic") ~= nil
    end,
}

chunlaoAttach = sgs.CreateTriggerSkill{
    name = "chunlao_attach",
    events = {sgs.PreCardUsed},
    view_as_skill = chunlaoAttachVS,

    on_record = function(self, event, room, player, data)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Analeptic")
            and use.card:getSkillName() == self:objectName()
            and player:getMark("@halfmaxhp") > 0 then
            room:removePlayerMark(player, "@halfmaxhp")
        end
    end,

    can_trigger = function(self, event, room, player, data)
        return ""
    end,
}

local function refreshChunlaoAttach(room)
    local owners = room:findPlayersBySkillName("chunlao")
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        local eligible = false
        for _, owner in sgs.qlist(owners) do
            if owner:isAlive() and owner:hasShownSkill("chunlao")
                and (p:objectName() == owner:objectName() or p:isFriendWith(owner)) then
                eligible = true
                break
            end
        end
        if eligible and not p:hasSkill("chunlao_attach") then
            room:attachSkillToPlayer(p, "chunlao_attach")
        elseif not eligible and p:hasSkill("chunlao_attach") then
            room:detachSkillFromPlayer(p, "chunlao_attach")
        end
    end
end

chunlao = sgs.CreateTriggerSkill{
    name = "chunlao",
    events = {sgs.GameStart, sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved,
        sgs.DFDebut, sgs.Death, sgs.EventAcquireSkill, sgs.EventLoseSkill,
        sgs.RemoveStateChanged},
    frequency = sgs.Skill_Compulsory,

    on_record = function(self, event, room, player, data)
        refreshChunlaoAttach(room)
    end,

    can_trigger = function(self, event, room, player, data)
        return ""
    end,
}

guyong_hanjin = sgs.General(extension, "guyong_hanjin", "wu", 3)

mizhong = sgs.CreateTriggerSkill{
    name = "mizhong",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,

    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getHandcardNum() == player:getHp() then
            local damage = data:toDamage()
            if damage.damage > 0 then return self:objectName() end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if not player:hasShownSkill(self:objectName())
            and not player:askForSkillInvoke(self:objectName(), data) then
            return false
        end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke(self:objectName(), player)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        damage.damage = damage.damage - 1
        data:setValue(damage)
        return damage.damage <= 0
    end,
}

local function bingyiHandcardsSameColor(player)
    local handcards = player:getHandcards()
    if handcards:isEmpty() then return false end
    local color = handcards:first():getColor()
    for _, card in sgs.qlist(handcards) do
        if card:getColor() ~= color then return false end
    end
    return true
end

local function bingyiDiscardedByOwner(data, owner)
    for _, move_data in sgs.qlist(data:toList()) do
        local move = move_data:toMoveOneTime()
        local basic_reason = bit32.band(move.reason.m_reason,
            sgs.CardMoveReason_S_MASK_BASIC_REASON)
        if basic_reason == sgs.CardMoveReason_S_REASON_DISCARD
            and move.from and move.from:objectName() == owner:objectName()
            and not move.card_ids:isEmpty() then
            return true
        end
    end
    return false
end

bingyi = sgs.CreateTriggerSkill{
    name = "bingyi",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_RoundStart then
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:setPlayerMark(owner, "bingyi_used_turn", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.CardsMoveOneTime then return "" end
        local skill_list = {}
        local owner_list = {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:getMark("bingyi_used_turn") == 0
                and bingyiDiscardedByOwner(data, owner)
                and bingyiHandcardsSameColor(owner) then
                table.insert(skill_list, self:objectName())
                table.insert(owner_list, owner:objectName())
            end
        end
        return table.concat(skill_list, "|"), table.concat(owner_list, "|")
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:setPlayerMark(ask_who, "bingyi_used_turn", 1)
            room:broadcastSkillInvoke(self:objectName(), ask_who)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if not (ask_who:isAlive() and bingyiHandcardsSameColor(ask_who)) then
            return false
        end
        room:showAllCards(ask_who)
        local max_num = math.min(ask_who:getHandcardNum(), room:alivePlayerCount())
        if max_num <= 0 then return false end
        local targets = room:askForPlayersChosen(ask_who, room:getAlivePlayers(),
            self:objectName(), 0, max_num,
            "@bingyi-draw:::" .. tostring(max_num), true)
        for _, target in sgs.qlist(targets) do
            target:drawCards(1, self:objectName())
        end
        return false
    end,
}

zhanghong_hanjin = sgs.General(extension, "zhanghong_hanjin", "wu", 3, true)

shuoshanCard = sgs.CreateSkillCard{
    name = "shuoshanCard",
    skill_name = "shuoshan",
    target_fixed = false,
    will_throw = false,

    filter = function(self, targets, to_select, source)
        return #targets == 0
            and to_select:objectName() ~= source:objectName()
            and not source:isKongcheng() and not to_select:isKongcheng()
    end,

    on_use = function(self, room, source, targets)
        local target = targets[1]
        if target and target:isAlive() and not source:isKongcheng()
            and not target:isKongcheng() then
            source:pindian(target, "shuoshan")
        end
    end,
}

shuoshanVS = sgs.CreateZeroCardViewAsSkill{
    name = "shuoshan",

    view_as = function(self)
        local card = shuoshanCard:clone()
        card:setShowSkill(self:objectName())
        return card
    end,

    enabled_at_play = function(self, player)
        if player:hasUsed("#shuoshanCard") or player:isKongcheng() then
            return false
        end
        return true
    end,
}

shuoshan = sgs.CreateTriggerSkill{
    name = "shuoshan",
    events = {sgs.Pindian},
    view_as_skill = shuoshanVS,
    frequency = sgs.Skill_Frequent,

    can_trigger = function(self, event, room, player, data)
        local pindian = data:toPindian()
        if pindian.reason == self:objectName() then return self:objectName() end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        return true
    end,

    on_effect = function(self, event, room, player, data)
        local pindian = data:toPindian()
        local winner = nil
        local loser = nil
        if pindian.from_number > pindian.to_number then
            winner = pindian.from
            loser = pindian.to
        elseif pindian.from_number < pindian.to_number then
            winner = pindian.to
            loser = pindian.from
        else
            return false
        end

        if not (winner and winner:isAlive() and loser and loser:isAlive()) then
            return false
        end
        local draw_num = math.max(0,
            winner:getHandcardNum() - loser:getHandcardNum())
        if draw_num > 0 then
            loser:drawCards(draw_num, self:objectName())
        elseif loser:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who = pindian.from
            recover.recover = 1
            room:recover(loser, recover)
        end
        return false
    end,
}

local function roufuIsDamageCard(card)
    if not card then return false end
    local damage_cards = {
        "Slash", "Duel", "ArcheryAttack", "SavageAssault",
        "BurningCamps", "Drowning", "FireAttack"
    }
    for _, class_name in ipairs(damage_cards) do
        if card:isKindOf(class_name) then return true end
    end
    return false
end

roufu = sgs.CreateTriggerSkill{
    name = "roufu",
    events = {sgs.TargetConfirmed, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player
            and player:getPhase() == sgs.Player_RoundStart then
            for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:setPlayerMark(owner, "roufu_used_turn", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if not (event == sgs.TargetConfirmed and player and player:isAlive()
            and player:hasSkill(self:objectName())) then
            return ""
        end
        local use = data:toCardUse()
        if use.from and use.from:isAlive()
            and use.from:objectName() ~= player:objectName()
            and roufuIsDamageCard(use.card)
            and use.to:length() == 1 and use.to:contains(player)
            and not player:willBeFriendWith(use.from) then
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
        local use = data:toCardUse()
        local source = use.from
        if not (source and source:isAlive()) then return false end

        room:addPlayerMark(player, "roufu_used_turn")
        local x = player:getMark("roufu_used_turn")
        source:drawCards(1, self:objectName())

        if player:isAlive() and source:isAlive() and not source:isNude() then
            local give_num = math.min(x, source:getCardCount(true))
            local card_ids = room:askForExchange(source, self:objectName(),
                give_num, give_num,
                "@roufu-give:" .. player:objectName() .. "::" .. tostring(give_num),
                "", ".|.|.|hand,equipped")
            if not card_ids:isEmpty() then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                    source:objectName(), player:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(card_ids, player,
                    sgs.Player_PlaceHand, reason)
                room:moveCardsAtomic(move, false)
            end
        end
        return false
    end,
}

zhuling_hanjin = sgs.General(extension, "zhuling_hanjin", "wei", 4, true)

local function jixianConditionCount(source, target)
    local count = 0
    if target:getFormation():length() > 1 then count = count + 1 end
    if target:getVisibleSkillList():length()
        > source:getVisibleSkillList():length() then
        count = count + 1
    end
    if not target:isWounded() then count = count + 1 end
    return count
end

local function jixianCandidates(room, source)
    local candidates = sgs.SPlayerList()
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:setSkillName("jixian")
    if not source:isCardLimited(slash, sgs.Card_MethodUse)
        and sgs.Slash_IsAvailable(source) then
        for _, target in sgs.qlist(room:getOtherPlayers(source)) do
            if jixianConditionCount(source, target) > 0
                and source:canSlash(target, slash, false)
                and not source:isProhibited(target, slash) then
                candidates:append(target)
            end
        end
    end
    slash:deleteLater()
    return candidates
end

jixian = sgs.CreateTriggerSkill{
    name = "jixian",
    events = {sgs.EventPhaseStart, sgs.Damage, sgs.CardFinished},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event ~= sgs.Damage then return end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash")
            and damage.card:getSkillName() == self:objectName() then
            local total = damage.card:getTag("jixian_damage"):toInt()
            damage.card:setTag("jixian_damage",
                sgs.QVariant(total + damage.damage))
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player and player:isAlive() and player:hasSkill(self:objectName())
                and player:getPhase() == sgs.Player_Play
                and not jixianCandidates(room, player):isEmpty() then
                return self:objectName()
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from and use.from:isAlive() and use.from:hasSkill(self:objectName())
                and use.card and use.card:isKindOf("Slash")
                and use.card:getSkillName() == self:objectName() then
                return self:objectName(), use.from:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.CardFinished then return true end
        local target = room:askForPlayerChosen(ask_who,
            jixianCandidates(room, ask_who), self:objectName(),
            "@jixian-target", true, true)
        if not target then return false end
        ask_who:setTag("jixian_target", sgs.QVariant(target:objectName()))
        room:setPlayerMark(ask_who, "jixian_draw",
            jixianConditionCount(ask_who, target))
        room:broadcastSkillInvoke(self:objectName(), ask_who)
        return true
    end,

    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:getTag("jixian_damage"):toInt() == 0
                and ask_who:isAlive() then
                room:loseHp(ask_who, 1)
            end
            return false
        end

        local target = room:findPlayer(ask_who:getTag("jixian_target"):toString())
        ask_who:removeTag("jixian_target")
        local draw_num = ask_who:getMark("jixian_draw")
        room:setPlayerMark(ask_who, "jixian_draw", 0)
        if not (target and target:isAlive()) then return false end

        if draw_num > 0 then ask_who:drawCards(draw_num, self:objectName()) end
        if not (ask_who:isAlive() and target:isAlive()) then return false end

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        slash:setTag("jixian_damage", sgs.QVariant(0))
        if not ask_who:isCardLimited(slash, sgs.Card_MethodUse)
            and ask_who:canSlash(target, slash, false)
            and not ask_who:isProhibited(target, slash) then
            local use = sgs.CardUseStruct()
            use.card = slash
            use.from = ask_who
            use.to:append(target)
            room:useCard(use)
        end
        slash:deleteLater()
        return false
    end,
}

qianshuo_hanjin = sgs.General(extension, "qianshuo_hanjin", "qun", 4, true)

jibing = sgs.CreateTriggerSkill{
    name = "jibing",
    events = {sgs.DrawNCards, sgs.Damage, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Frequent,

    on_record = function(self, event, room, player, data)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:getMark("jibing_x") > 0
                and damage.damage > 0 then
                room:addPlayerMark(damage.from, "jibing_damage", damage.damage)
            end
        elseif event == sgs.EventPhaseChanging and player then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and player:getMark("jibing_x") > 0
                and player:getMark("jibing_damage") >= player:getMark("jibing_x") then
                room:setPlayerMark(player, "jibing_x", 0)
                room:setPlayerMark(player, "jibing_damage", 0)
            end
        end
    end,

    can_trigger = function(self, event, room, player, data)
        if event == sgs.DrawNCards then
            if player and player:isAlive() and player:hasSkill(self:objectName()) then
                return self:objectName()
            end
        elseif event == sgs.EventPhaseChanging and player and player:isAlive() then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and player:getMark("jibing_x") > 0
                and player:getMark("jibing_damage") < player:getMark("jibing_x") then
                return self:objectName()
            end
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then return true end
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,

    on_effect = function(self, event, room, player, data)
        if event == sgs.DrawNCards then
            local x = math.max(1,
                player:getPlayerNumWithSameKingdom(self:objectName()))
            room:setPlayerMark(player, "jibing_x", x)
            room:setPlayerMark(player, "jibing_damage", 0)
            data:setValue(data:toInt() + x)
            return false
        end

        room:setPlayerMark(player, "jibing_x", 0)
        room:setPlayerMark(player, "jibing_damage", 0)
        room:loseHp(player, 1)
        return false
    end,
}

shenpei_hanjin:addSkill(duce)
shenpei_hanjin:addSkill(shuairan)
zhanglu_hanjin:addSkill(mijiao)
zhanglu_hanjin:addSkill(guian)
huoyi_hanjin:addSkill(siju)
huoyi_hanjin:addSkill(zhongjue)
liuba_hanjin:addSkill(liuzhuan)
liuba_hanjin:addSkill(langji)
liuba_hanjin:addSkill(langjiMod)
extension:insertRelatedSkills("langji", "#langji-distance")
sunlang_hanjin:addSkill(juyi)
sunlang_hanjin:addSkill(yingshou)
xiahoulan_hanjin:addSkill(lanqie)
xiahoulan_hanjin:addSkill(jinqi)
zulang_hanjin:addSkill(raoxi)
jiangji_hanjin:addSkill(xuxie)
jiangji_hanjin:addSkill(liulu)
chengpu_hanjin:addSkill(lihuo)
chengpu_hanjin:addSkill(lihuoMod)
chengpu_hanjin:addSkill(chunlao)
extension:insertRelatedSkills("lihuo", "#lihuo-target")
if not sgs.Sanguosha:getSkill("chunlao_attach") then skills:append(chunlaoAttach) end
guyong_hanjin:addSkill(mizhong)
guyong_hanjin:addSkill(bingyi)
zhanghong_hanjin:addSkill(shuoshan)
zhanghong_hanjin:addSkill(roufu)
zhuling_hanjin:addSkill(jixian)
qianshuo_hanjin:addSkill(jibing)

sgs.LoadTranslationTable{
    ["hanjin"] = "汉晋",

    ["shenpei_hanjin"] = "审配",
    ["#shenpei_hanjin"] = "正南义烈",
    ["duce"] = "度策",
    [":duce"] = "准备阶段，你可以与一名其他角色拼点。没赢的角色视为使用一张不指定对方为目标的【调虎离山】，赢的角色视为使用一张【万箭齐发】。",
    ["@duce-pindian"] = "度策：你可以选择一名其他角色与其拼点",
    ["@duce-lure"] = "度策：请选择一至两名角色作为【调虎离山】的目标（不能选择 %src）",
    ["shuairan"] = "率然",
    [":shuairan"] = "阵法技。与你处于同一队列的角色数增加后，当前队列角色各摸一张牌；减少后，当前队列角色各回复1点体力。",

    ["zhanglu_hanjin"] = "张鲁",
    ["#zhanglu_hanjin"] = "米道师君",
    ["mijiao"] = "米教",
    [":mijiao"] = "出牌阶段限一次。你可以令一名与你手牌数相差不大于2的其他角色将手牌调整至与你相同，若其因此摸牌，你可以对其造成1点伤害；若其因此弃牌，你可以令其回复1点体力。",
    ["mijiao_damage"] = "米教",
    ["mijiao_recover"] = "米教",
    ["mijiao_damage:damage"] = "你可以对其造成1点伤害",
    ["mijiao_recover:recover"] = "你可以令其回复1点体力",
    ["guian"] = "归安",
    [":guian"] = "当作为大势力的势力变化后，你可以令至多两名角色各摸一张牌。",
    ["@guian-choose"] = "归安：你可以令至多两名角色各摸一张牌",

    ["huoyi_hanjin"] = "霍弋",
    ["#huoyi_hanjin"] = "孤城忠烈",
    ["siju"] = "死拒",
    [":siju"] = "出牌阶段，若你平置，你可以叠置，然后视为使用一张伤害类锦囊；若没有与你势力相同的其他角色，该锦囊不可响应。",
    ["zhongjue"] = "忠绝",
    [":zhongjue"] = "锁定技。当你受到伤害时，若你横置或叠置，你弃置至少一张牌并防止等量伤害，然后若你没有手牌或体力值为1，你复原武将牌。",
    ["@zhongjue-discard"] = "忠绝：请弃置至少一张牌，防止等量伤害（当前伤害为 %arg 点）",

    ["liuba_hanjin"] = "刘巴",
    ["#liuba_hanjin"] = "财理政通",
    ["liuzhuan"] = "流转",
    [":liuzhuan"] = "当牌因弃置进入弃牌堆时，你可以将其中的方片牌置于武将牌上，称为“币”；结束阶段，你移去所有“币”，视为对至多等量名角色使用一张【无中生有】。",
    ["coin"] = "币",
    ["@liuzhuan-use"] = "流转：请选择至多 %arg 名角色，视为对这些角色使用【无中生有】",
    ["langji"] = "浪迹",
    [":langji"] = "锁定技。若你本回合未成为过牌的目标，你与其他角色的距离以及其他角色与你的距离+1。",

    ["sunlang_hanjin"] = "孙狼",
    ["#sunlang_hanjin"] = "危途义烈",
    ["juyi"] = "拒役",
    [":juyi"] = "当你或体力值为1的其他角色成为伤害类锦囊牌的目标时，你可以取消之并选择一项：1.对使用者使用一张【杀】；2.失去1点体力。",
    ["juyi:juyi_slash"] = "对使用者使用一张【杀】",
    ["juyi:juyi_losehp"] = "失去1点体力",
    ["@juyi-slash"] = "拒役：请对 %src 使用一张【杀】，否则你失去1点体力",
    ["yingshou"] = "应绶",
    [":yingshou"] = "你可以将一张红桃锦囊牌当【杀】使用或打出。",

    ["xiahoulan_hanjin"] = "夏侯岚",
    ["#xiahoulan_hanjin"] = "惊风掠阵",
    ["lanqie"] = "岚切",
    [":lanqie"] = "当你弃置任意角色的牌后，你可以将弃置的牌置于武将牌上，称为“岚”；每回合结束时，你将所有“岚”当指定至多等量目标的【杀】使用。若此【杀】对所有目标均造成过伤害，此技能本轮失效。然后你可以将转化所用的牌交给任意名其他角色。",
    ["storm"] = "岚",
    ["@lanqie-slash"] = "岚切：请选择至多 %arg 名角色作为【杀】的目标",
    ["lanqie_give"] = "岚切",
    ["@lanqie-give"] = "岚切：请选择一名其他角色获得转化所用的【%arg】",
    ["jinqi"] = "金契",
    [":jinqi"] = "若你的另一个武将是女性，你计算体力上限时增加2个单独的阴阳鱼。",

    ["zulang_hanjin"] = "祖郎",
    ["#zulang_hanjin"] = "山越桀帅",
    ["raoxi"] = "扰袭",
    [":raoxi"] = "每轮限两次。其他角色的结束阶段，若你本回合未失去过牌，你可以视为对其使用一张【杀】。",

    ["jiangji_hanjin"] = "蒋济",
    ["#jiangji_hanjin"] = "筹画明达",
    ["xuxie"] = "虚懈",
    [":xuxie"] = "每轮限一次。你可以将一张牌当【无懈可击】使用并交给一名其他角色，本回合你与其不能使用此牌颜色的牌。",
    ["@xuxie-give"] = "虚懈：请选择一名其他角色，结算后将转化所用的牌交给其",
    ["liulu"] = "流赂",
    [":liulu"] = "当你受到其他角色的伤害后，或其他角色得到你的牌后，你可以令其摸一张牌，然后你获得其一张牌。",

    ["chengpu_hanjin"] = "程普",
    ["#chengpu_hanjin"] = "三朝虎臣",
    ["lihuo"] = "疠火",
    [":lihuo"] = "你可以将两张牌当目标数上限+1的【火杀】使用。若此【杀】造成的伤害大于1，你可以令你与一名与你势力相同的其他角色各获得一个阴阳鱼标记。",
    ["@lihuo-yinyang"] = "疠火：你可以选择一名与你势力相同的其他角色，你与其各获得一个阴阳鱼标记",
    ["chunlao"] = "醇醪",
    [":chunlao"] = "与你势力相同的角色可以将一个阴阳鱼标记当【酒】使用。",
    ["chunlao_attach"] = "醇醪",
    [":chunlao_attach"] = "你可以将一个阴阳鱼标记当【酒】使用。",

    ["guyong_hanjin"] = "顾雍",
    ["#guyong_hanjin"] = "庙堂股肱",
    ["mizhong"] = "密重",
    [":mizhong"] = "锁定技。当你受到伤害时，若你的手牌数等于体力值，此伤害-1。",
    ["bingyi"] = "秉壹",
    [":bingyi"] = "每回合限一次。当你因弃置而失去牌后，若你的手牌颜色均相同，你可以展示所有手牌，令至多等同于你手牌数的角色各摸一张牌。",
    ["@bingyi-draw"] = "秉壹：请选择至多 %arg 名角色各摸一张牌",

    ["zhanghong_hanjin"] = "张纮",
    ["#zhanghong_hanjin"] = "江东谋主",
    ["shuoshan"] = "说善",
    [":shuoshan"] = "出牌阶段限一次。你可以与一名其他角色拼点，输的角色将手牌摸至与赢的角色相等；若其以此法摸牌数为0，则改为回复1点体力。",
    ["roufu"] = "柔服",
    [":roufu"] = "当你成为其他势力角色使用伤害牌的唯一目标后，你可以令其摸一张牌，然后其交给你X张牌（X为你本回合发动此技能的次数）。",
    ["@roufu-give"] = "柔服：请交给 %src %arg 张牌",

    ["zhuling_hanjin"] = "朱灵",
    ["#zhuling_hanjin"] = "历战陷阵",
    ["jixian"] = "急陷",
    [":jixian"] = "出牌阶段开始时，你可以指定一名符合以下任意项条件的其他角色并摸X张牌（X为其符合的条件数），然后视为对其使用一张【杀】：1.处于队列；2.技能数多于你；3.未受伤。若此【杀】未造成伤害，你失去1点体力。",
    ["@jixian-target"] = "急陷：你可以选择一名符合条件且能成为【杀】目标的其他角色",

    ["qianshuo_hanjin"] = "骞硕",
    ["#qianshuo_hanjin"] = "西园上军",
    ["jibing"] = "集兵",
    [":jibing"] = "摸牌阶段，你可以多摸X张牌（X为与你势力相同的角色数）。若如此做，回合结束时，若你本回合造成的伤害点数小于X，你失去1点体力。",
}

sgs.Sanguosha:addSkills(skills)

return {extension}
