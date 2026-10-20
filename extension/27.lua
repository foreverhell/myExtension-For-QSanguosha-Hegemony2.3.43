extension = sgs.Package("27", sgs.Package_GeneralPack)
equip = sgs.Package("27Equip",sgs.Package_CardPack)
local equip27_skills = sgs.SkillList()

zhuling27 = sgs.General(extension, "zhuling27", "wei", 4)

-- 技能名称独立，音效仍复用原版朱灵，无需复制音频资源。
local function juejue27Targets(room, player)
    local targets = {}
    local count = player:getMark("juejue27_discard")
    for _, target in sgs.qlist(room:getOtherPlayers(player)) do
        if target:isAlive() and target:getHp() < count then
            table.insert(targets, target)
        end
    end
    return targets
end

-- 同项目 yumou、huaiju：客户端在处理击杀奖惩时检查此 flag。
-- DeathFinished 用于解除本次击杀的标记；不修改死亡伤害来源。
local reward_events = {sgs.BuryVictim}
if sgs.DeathFinished then table.insert(reward_events, sgs.DeathFinished) end

juejue27_reward = sgs.CreateTriggerSkill{
    name = "#juejue27-reward",
    global = true,
    events = reward_events,
    on_record = function(self, event, room, player, data)
        if event ~= sgs.DeathFinished then return end
        local victim = data:toDeath().who
        if victim and victim:getTag("juejue27_reward_owner"):toString() ~= "" then
            local killer_name = victim:getTag("juejue27_reward_owner"):toString()
            victim:removeTag("juejue27_reward_owner")
            for _, killer in sgs.qlist(room:getAllPlayers(true)) do
                if killer:objectName() == killer_name then
                    room:setPlayerFlag(killer, "-skip_game_rule_reward")
                    break
                end
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.BuryVictim then return "" end
        local death = data:toDeath()
        local killer = death.damage and death.damage.from
        if killer and killer:isAlive() and killer:hasSkill("juejue27")
            and death.who and killer:isFriendWith(death.who) then
            return self:objectName(), killer:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return ask_who:hasShownSkill("juejue27")
            or ask_who:askForSkillInvoke("juejue27", data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(ask_who, "juejue27")
        room:broadcastSkillInvoke("juejue", ask_who)
        if not sgs.DeathFinished then
            -- 仓库旧引擎没有免奖惩 flag 接口：只接管本次友方击杀的埋葬。
            -- 保留 game_rule 的埋葬、连杀统计和君主死亡变野处理，跳过奖惩。
            local victim = data:toDeath().who
            victim:bury()
            if room:getTag("SkipNormalDeathProcess"):toBool() then return true end
            room:addPlayerMark(ask_who, "multi_kill_count", 1)
            local count = ask_who:getMark("multi_kill_count")
            if count > 1 and count < 8 then
                room:setEmotion(ask_who, "multi_kill" .. tostring(count), false, 4000)
            elseif count > 7 then
                room:setEmotion(ask_who, "zylove", false, 4000)
            end
            if victim:getGeneral():isLord() then
                for _, other in sgs.qlist(room:getOtherPlayers(victim, true)) do
                    if other:getKingdom() == victim:getKingdom() then
                        if other:hasShownOneGeneral() then
                            room:setPlayerProperty(other, "role", sgs.QVariant("careerist"))
                        else
                            other:setRole("careerist")
                            room:notifyProperty(other, other, "role")
                        end
                    end
                end
            end
            return true
        end
        -- 不接管其他技能已设置的免奖惩标记。
        if not ask_who:hasFlag("skip_game_rule_reward") then
            data:toDeath().who:setTag("juejue27_reward_owner", sgs.QVariant(ask_who:objectName()))
            room:setPlayerFlag(ask_who, "skip_game_rule_reward")
        end
        return false
    end,
}

juejue27 = sgs.CreateTriggerSkill{
    name = "juejue27",
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.EventPhaseChanging, sgs.CardsMoveOneTime},
    on_record = function(self, event, room, player, data)
        if not player then return end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Discard or change.to == sgs.Player_Discard then
                room:setPlayerMark(player, "juejue27_active", 0)
                room:setPlayerMark(player, "juejue27_discard", 0)
            end
        elseif event == sgs.CardsMoveOneTime and player:getPhase() == sgs.Player_Discard
            and player:getMark("juejue27_active") > 0 then
            local function record(move)
                if not move.from or move.from:objectName() ~= player:objectName() then return end
                local reason = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                if reason ~= sgs.CardMoveReason_S_REASON_DISCARD then return end
                local count = 0
                for i = 0, move.card_ids:length() - 1 do
                    local place = move.from_places:at(i)
                    if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
                        count = count + 1
                    end
                end
                if count > 0 then room:addPlayerMark(player, "juejue27_discard", count) end
            end
            -- 本项目扩展使用批量移动数据；兼容旧引擎的单个移动数据。
            local moves = data:toList()
            if moves:isEmpty() then
                record(data:toMoveOneTime())
            else
                for _, move_data in sgs.qlist(moves) do record(move_data:toMoveOneTime()) end
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Discard) then return "" end
        if event == sgs.EventPhaseStart then return self:objectName() end
        if event == sgs.EventPhaseEnd and player:getMark("juejue27_active") > 0 then
            if #juejue27Targets(room, player) > 0 then return self:objectName() end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke("juejue", player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            room:setPlayerMark(player, "juejue27_discard", 0)
            -- 先记录发动，再失去体力，包含由此插入的弃牌结算。
            room:setPlayerMark(player, "juejue27_active", 1)
            room:loseHp(player, 1)
        else
            -- 先固定本次所有目标，不因前面目标的结算改变后续目标名单。
            local targets = juejue27Targets(room, player)
            room:setPlayerMark(player, "juejue27_active", 0)
            room:setPlayerMark(player, "juejue27_discard", 0)
            for _, target in ipairs(targets) do
                if not player:isAlive() then break end
                if target:isAlive() then
                    local damage = sgs.DamageStruct()
                    damage.from, damage.to = player, target
                    damage.damage, damage.reason = 1, self:objectName()
                    room:damage(damage)
                end
            end
        end
        return false
    end,
}

fangyuan27_summon = sgs.CreateArraySummonCard{name = "fangyuan27"}
fangyuan27_vs = sgs.CreateArraySummonSkill{
    name = "fangyuan27",
    array_summon_card = fangyuan27_summon,
}

fangyuan27 = sgs.CreateTriggerSkill{
    name = "fangyuan27",
    is_battle_array = true,
    battle_array_type = sgs.Siege,
    view_as_skill = fangyuan27_vs,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    can_preshow = false,
    can_trigger = function(self, event, room, player, data)
        if room:alivePlayerCount() < 4 then return "" end
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and player:hasShownSkill(self:objectName())) then return "" end
        local damage = data:toDamage()
        local target = damage.to
        if damage.from ~= player or not target or not target:isAlive()
            or player:isFriendWith(target) then return "" end
        if player:inSiegeRelation(player, target) or target:inSiegeRelation(target, player) then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        room:sendCompulsoryTriggerLog(player, self:objectName())
        room:broadcastSkillInvoke("fangyuan", player)
        return true
    end,
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        damage.damage = damage.damage + 1
        data:setValue(damage)
        return false
    end,
}

zhuling27:addSkill(juejue27)
zhuling27:addSkill(juejue27_reward)
zhuling27:addSkill(fangyuan27)
extension:insertRelatedSkills("juejue27", "#juejue27-reward")

sgs.LoadTranslationTable{
    ["27"] = "27国典",
    ["zhuling27"] = "朱灵",
    ["#zhuling27"] = "五子之亚",
    ["juejue27"] = "决绝",
    ["#juejue27-reward"] = "决绝",
    [":juejue27"] = "你杀死与你势力相同的角色不执行奖惩。弃牌阶段开始时，你可以失去1点体力，令你此阶段结束时，可以对所有体力值小于你此阶段弃牌数的其他角色造成1点伤害。",
    ["fangyuan27"] = "方圆",
    [":fangyuan27"] = "阵法技。若你处于围攻关系，你对该围攻关系的其他势力角色造成的伤害+1。",
}

-- 当前仓库 General 接口仅支持单势力；魏吴设置待确认实际客户端接口。
wenqin27 = sgs.General(extension, "wenqin27", "wei", 4)

jinfa27Card = sgs.CreateSkillCard{
    name = "jinfa27Card",
    skill_name = "jinfa27",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, source)
        return #targets == 0 and to_select:objectName() ~= source:objectName()
            and not source:isKongcheng() and not to_select:isKongcheng()
    end,
    feasible = function(self, targets, source)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        if source:isAlive() and target and target:isAlive()
            and not source:isKongcheng() and not target:isKongcheng() then
            room:broadcastSkillInvoke("jinfa", source)
            source:pindian(target, "jinfa27")
        end
    end,
}

jinfa27VS = sgs.CreateZeroCardViewAsSkill{
    name = "jinfa27",
    view_as = function(self)
        local card = jinfa27Card:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        if player:hasUsed("#jinfa27Card") or player:isKongcheng() then return false end
        for _, target in sgs.qlist(player:getAliveSiblings()) do
            if not target:isKongcheng() then return true end
        end
        return false
    end,
}

jinfa27 = sgs.CreateTriggerSkill{
    name = "jinfa27",
    events = {sgs.Pindian},
    view_as_skill = jinfa27VS,
    can_trigger = function(self, event, room, player, data)
        local pindian = data:toPindian()
        if pindian.reason == self:objectName() then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return true
    end,
    on_effect = function(self, event, room, player, data)
        local pindian = data:toPindian()
        local winner, loser
        if pindian.from_number > pindian.to_number then
            winner, loser = pindian.from, pindian.to
        elseif pindian.from_number < pindian.to_number then
            winner, loser = pindian.to, pindian.from
        end
        -- 平局双方均没赢，没有“赢的角色”，不执行后续效果。
        if not (winner and loser) then return false end
        local has_spade = (pindian.from_card and pindian.from_card:getSuit() == sgs.Card_Spade)
            or (pindian.to_card and pindian.to_card:getSuit() == sgs.Card_Spade)

        -- 只有发动者赢才获得牌，目标赢不获得牌。
        if winner == pindian.from and winner:isAlive() and loser:isAlive()
            and winner:canGetCard(loser, "he") then
            local card_id = room:askForCardChosen(winner, loser, "he",
                self:objectName(), false, sgs.Card_MethodGet)
            room:obtainCard(winner, card_id, false)
        end
        if has_spade and winner:isAlive() and loser:isAlive() then
            local damage = sgs.DamageStruct()
            damage.from, damage.to = loser, winner
            damage.damage, damage.reason = 1, self:objectName()
            room:damage(damage)
        end
        return false
    end,
}

wenqin27:addSkill(jinfa27)

sgs.LoadTranslationTable{
    ["wenqin27"] = "文钦",
    ["#wenqin27"] = "勇而无算",
    ["jinfa27"] = "矜伐",
    ["jinfa27Card"] = "矜伐",
    [":jinfa27"] = "出牌阶段限一次，你可以拼点：若你赢，你获得对方一张牌；若拼点牌中包含黑桃牌，没赢的角色对赢的角色造成1点伤害。",
}

sufei27 = sgs.General(extension, "sufei27", "wu", 4)

lianpian27 = sgs.CreateTriggerSkill{
    name = "lianpian27",
    events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Start then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(), data)
    end,
    on_effect = function(self, event, room, player, data)
        room:broadcastSkillInvoke("lianpian", player)
        -- 先记录持续效果，摸牌插入的死亡结算可以正常将其清除。
        room:setPlayerMark(player, "@lianpian27", 1)
        local count = player:getMaxHp() - player:getHandcardNum()
        if count > 0 then player:drawCards(count, self:objectName()) end
        return false
    end,
}

local function lianpian27Owners(room, player)
    local owners = sgs.SPlayerList()
    for _, owner in sgs.qlist(room:getAlivePlayers()) do
        if owner ~= player and owner:getMark("@lianpian27") > 0
            and owner:isFriendWith(player) then
            owners:append(owner)
        end
    end
    return owners
end

-- 发动后持续至规定时机，不因技能被封锁、失去或武将暗置而提前失效。
lianpian27_effect = sgs.CreateTriggerSkill{
    name = "#lianpian27-effect",
    global = true,
    events = {sgs.TurnStart, sgs.Death, sgs.EventPhaseStart},-- sgs.EventPhaseProceeding
    on_record = function(self, event, room, player, data)
        if event == sgs.TurnStart and player then
            room:setPlayerMark(player, "@lianpian27", 0)
        elseif event == sgs.Death then
            local victim = data:toDeath().who
            if victim then room:setPlayerMark(victim, "@lianpian27", 0) end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player and player:isAlive()
            and player:getPhase() == sgs.Player_Draw
            and not lianpian27Owners(room, player):isEmpty() then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return true
    end,
    on_effect = function(self, event, room, player, data)
        local owners = lianpian27Owners(room, player)
        if owners:isEmpty() then return false end
        local owner = owners:first()
        -- 同场有多个效果时只替换一次，由摸牌角色选择采用哪位苏飞的手牌数。
        if owners:length() > 1 then
            owner = room:askForPlayerChosen(player, owners, "lianpian27", "@lianpian27-owner", false)
        end
        room:sendCompulsoryTriggerLog(owner, "lianpian27")
        local count = math.min(5, owner:getHandcardNum() - player:getHandcardNum())
        if count > 0 then player:drawCards(count, "lianpian27") end
        return true -- 中止阶段开始事件，不再进入常规阶段执行及 game_rule 摸牌。
    end,
}

sufei27:addSkill(lianpian27)
sufei27:addSkill(lianpian27_effect)
extension:insertRelatedSkills("lianpian27", "#lianpian27-effect")

sgs.LoadTranslationTable{
    ["sufei27"] = "苏飞",
    ["#sufei27"] = "诤友投明",
    ["lianpian27"] = "联翩",
    ["#lianpian27-effect"] = "联翩",
    ["@lianpian27"] = "联翩",
    ["@lianpian27-owner"] = "联翩：选择一名苏飞，将手牌摸至与其相同（至多摸5张）",
    [":lianpian27"] = "准备阶段，你可以将手牌摸至体力上限，若如此做，直到你下回合开始或死亡，与你势力相同的其他角色摸牌阶段改为将手牌数摸至与你相同（至多摸5张）。",
}

xuyou27 = sgs.General(extension, "xuyou27", "wei", 3)

shicai27Card = sgs.CreateSkillCard{
    name = "shicai27Card",
    skill_name = "shicai27",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select, source)
        return #targets == 0 and to_select ~= source and to_select:isKongcheng()
    end,
    feasible = function(self, targets, source)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local id = self:getSubcards():first()
        if not (source:isAlive() and target and target:isAlive() and target:isKongcheng()
            and room:getCardOwner(id) == source and room:getCardPlace(id) == sgs.Player_PlaceHand) then return end
        local card = sgs.Sanguosha:getCard(id)
        local mark = "shicai27_type_" .. tostring(card:getTypeId())
        if source:getMark(mark) > 0 then return end
        -- 展示和交牌可能插入结算，先占用本类别次数。
        room:setPlayerMark(source, mark, 1)
        room:broadcastSkillInvoke("shicai", source)
        room:showCard(source, id)
        if room:getCardOwner(id) == source and room:getCardPlace(id) == sgs.Player_PlaceHand
            and target:isAlive() then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                source:objectName(), target:objectName(), "shicai27", "")
            room:obtainCard(target, card, reason, true)
            if source:isAlive() then source:drawCards(2, "shicai27") end
        end
    end,
}

shicai27VS = sgs.CreateOneCardViewAsSkill{
    name = "shicai27",
    view_filter = function(self, card)
        return sgs.Self:getMark("shicai27_type_" .. tostring(card:getTypeId())) == 0
    end,
    view_as = function(self, card)
        local result = shicai27Card:clone()
        result:addSubcard(card)
        result:setSkillName(self:objectName())
        result:setShowSkill(self:objectName())
        return result
    end,
    enabled_at_play = function(self, player)
        local available = false
        for _, card in sgs.qlist(player:getHandcards()) do
            if player:getMark("shicai27_type_" .. tostring(card:getTypeId())) == 0 then
                available = true
                break
            end
        end
        if not available then return false end
        for _, target in sgs.qlist(player:getAliveSiblings()) do
            if target:isKongcheng() then return true end
        end
        return false
    end,
}

shicai27 = sgs.CreateTriggerSkill{
    name = "shicai27",
    view_as_skill = shicai27VS,
    events = {sgs.EventPhaseChanging},
    on_record = function(self, event, room, player, data)
        if not player then return end
        local change = data:toPhaseChange()
        if change.from == sgs.Player_Play or change.to == sgs.Player_Play then
            for _, kind in ipairs({sgs.Card_TypeBasic, sgs.Card_TypeTrick, sgs.Card_TypeEquip}) do
                room:setPlayerMark(player, "shicai27_type_" .. tostring(kind), 0)
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        return ""
    end,
}

chenglve27 = sgs.CreateOneCardViewAsSkill{
    name = "chenglve27",
    filter_pattern = "BasicCard",
    view_as = function(self, card)
        local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", card:getSuit(), card:getNumber())
        fire_attack:addSubcard(card)
        fire_attack:setSkillName(self:objectName())
        fire_attack:setShowSkill(self:objectName())
        return fire_attack
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
        local available = card:isAvailable(player)
        card:deleteLater()
        return available
    end
}

-- 跟踪火攻结算栈，避免嵌套火攻把外层展示牌覆盖。
local chenglve27_effects = {}
chenglve27_effect = sgs.CreateTriggerSkill{
    name = "#chenglve27-effect",
    global = true,
    events = {sgs.CardEffect, sgs.PostCardEffected, sgs.ChoiceMade, sgs.Damage},
    on_record = function(self, event, room, player, data)
        if event == sgs.CardEffect then
            local effect = data:toCardEffect()
            if effect.card and effect.card:isKindOf("FireAttack") then
                table.insert(chenglve27_effects, {room = room, card = effect.card,
                    target = effect.to, source = effect.from})
            end
        elseif event == sgs.PostCardEffected then
            local effect = data:toCardEffect()
            for i = #chenglve27_effects, 1, -1 do
                local entry = chenglve27_effects[i]
                if entry.room == room and entry.card == effect.card and entry.target == effect.to then
                    table.remove(chenglve27_effects, i)
                    break
                end
            end
        elseif event == sgs.ChoiceMade then
            local shown = string.match(data:toString(), "^cardShow:fire_attack:_(.*)_$")
            if not shown then return end
            local card = sgs.Card_Parse(shown)
            if not card then return end
            for i = #chenglve27_effects, 1, -1 do
                local entry = chenglve27_effects[i]
                if entry.room == room and entry.target == player then
                    entry.shown = card:getEffectiveId()
                    break
                end
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.Damage then return "" end
        local damage = data:toDamage()
        if not (damage.card and damage.card:isKindOf("FireAttack")
            and damage.card:getSkillName() == "chenglve27" and damage.damage > 0
            and damage.to and damage.to:isAlive()) or damage.chain or damage.transfer then return "" end
        for i = #chenglve27_effects, 1, -1 do
            local entry = chenglve27_effects[i]
            if entry.room == room and entry.card == damage.card and entry.target == damage.to
                and entry.shown and room:getCardOwner(entry.shown) == damage.to
                and room:getCardPlace(entry.shown) == sgs.Player_PlaceHand then
                return self:objectName(), damage.to:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
        for i = #chenglve27_effects, 1, -1 do
            local entry = chenglve27_effects[i]
            if entry.room == room and entry.card == damage.card and entry.target == damage.to then
                local id = entry.shown
                entry.shown = nil
                if id and damage.to:isAlive() and room:getCardOwner(id) == damage.to
                    and room:getCardPlace(id) == sgs.Player_PlaceHand then
                    room:throwCard(id, damage.to, damage.to, "chenglve27")
                end
                break
            end
        end
        return false
    end,
}

xuyou27:addSkill(shicai27)
xuyou27:addSkill(chenglve27)
xuyou27:addSkill(chenglve27_effect)
extension:insertRelatedSkills("chenglve27", "#chenglve27-effect")

sgs.LoadTranslationTable{
    ["xuyou27"] = "许攸",
    ["#xuyou27"] = "毕方矫翼",
    ["shicai27"] = "恃才",
    ["shicai27Card"] = "恃才",
    [":shicai27"] = "出牌阶段每种类别限一次。你可以展示并交给一名没有手牌的其他角色一张牌，然后摸2张牌。",
    ["chenglve27"] = "成略",
    ["#chenglve27-effect"] = "成略",
    [":chenglve27"] = "你可以将基本牌当【火攻】使用，造成伤害后，目标弃置因此展示的牌。",
}

wujing27 = sgs.General(extension, "wujing27", "wu", 4)

diaogui27VS = sgs.CreateOneCardViewAsSkill{
    name = "diaogui27",
    filter_pattern = ".",
    view_as = function(self, card)
        local lure_tiger = sgs.Sanguosha:cloneCard("lure_tiger", card:getSuit(), card:getNumber())
        lure_tiger:addSubcard(card)
        lure_tiger:setSkillName(self:objectName())
        lure_tiger:setShowSkill(self:objectName())
        return lure_tiger
    end,
    enabled_at_play = function(self, player)
        if player:usedTimes("ViewAsSkill_diaogui27Card") > 0 then return false end
        local card = sgs.Sanguosha:cloneCard("lure_tiger", sgs.Card_NoSuit, 0)
        local available = card:isAvailable(player)
        card:deleteLater()
        return available
    end,
}

-- 记录原有相邻关系，只奖励本次调虎离山新连接起来的队列。
local function diaogui27Adjacent(room, source)
    local pairs = {}
    for _, first in sgs.qlist(room:getAlivePlayers()) do
        if not first:isRemoved() and source:isFriendWith(first) then
            for _, second in sgs.qlist(room:getAlivePlayers()) do
                if second ~= first and not second:isRemoved() and source:isFriendWith(second)
                    and first:isAdjacentTo(second) then
                    table.insert(pairs, first:objectName() .. ":" .. second:objectName())
                end
            end
        end
    end
    return pairs
end

local function diaogui27Targets(room, use)
    local targets, added = {}, {}
    if not (use.from and use.from:isAlive()) then return targets end
    local before = "|" .. use.card:getTag("diaogui27_adjacent"):toString() .. "|"
    for _, first in sgs.qlist(room:getAlivePlayers()) do
        if not first:isRemoved() and use.from:isFriendWith(first) then
            for _, second in sgs.qlist(room:getAlivePlayers()) do
                local key = "|" .. first:objectName() .. ":" .. second:objectName() .. "|"
                if second ~= first and not second:isRemoved() and use.from:isFriendWith(second)
                    and first:isAdjacentTo(second) and not string.find(before, key, 1, true) then
                    for _, member in sgs.qlist(first:getFormation()) do
                        if member:isAlive() and not member:isRemoved() and not added[member:objectName()] then
                            added[member:objectName()] = true
                            table.insert(targets, member)
                        end
                    end
                end
            end
        end
    end
    -- 依行动顺序结算，不采用上面的遍历发现顺序。
    local ordered = {}
    for _, member in sgs.qlist(room:getAlivePlayers()) do
        if added[member:objectName()] then table.insert(ordered, member) end
    end
    return ordered
end

diaogui27 = sgs.CreateTriggerSkill{
    name = "diaogui27",
    view_as_skill = diaogui27VS,
    events = {sgs.CardUsed, sgs.CardFinished},
    on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.from and use.card and use.card:isKindOf("LureTiger")
                and use.card:getSkillName() == self:objectName() then
                use.card:setTag("diaogui27_adjacent", sgs.QVariant(table.concat(diaogui27Adjacent(room, use.from), "|")))
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.CardFinished then return "" end
        local use = data:toCardUse()
        if use.from and use.from:isAlive() and use.card and use.card:isKindOf("LureTiger")
            and use.card:getSkillName() == self:objectName()
            and #diaogui27Targets(room, use) > 0 then
            return self:objectName(), use.from:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local targets = diaogui27Targets(room, data:toCardUse())
        room:broadcastSkillInvoke("diaogui", ask_who)
        for _, target in ipairs(targets) do
            if target:isAlive() then room:drawCards(target, 2, self:objectName()) end
        end
        return false
    end,
}

wujing27:addSkill(diaogui27)
wujing27:addSkill("fengyang")

sgs.LoadTranslationTable{
    ["wujing27"] = "吴景",
    ["#wujing27"] = "汗马鎏金",
    ["diaogui27"] = "调归",
    [":diaogui27"] = "出牌阶段限一次。你可以将一张牌当【调虎离山】使用，若你的势力因此成为队列，此队列的角色各摸2张牌。",
}

tangzi27 = sgs.General(extension, "tangzi27", "wei", 4)

xingzhao27Card = sgs.CreateSkillCard{
    name = "xingzhao27Card",
    skill_name = "xingzhao27",
    filter = function(self, targets, to_select, source)
        return #targets == 0
    end,
    feasible = function(self, targets, source)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        if not (source:isAlive() and target and target:isAlive()) then return end
        room:broadcastSkillInvoke("xingzhao", source)
        local damage = sgs.DamageStruct()
        damage.from, damage.to = source, target
        damage.damage, damage.reason = 1, "xingzhao27"
        room:damage(damage)
        if not target:isAlive() then return end

        local eligible = {}
        for _, card in sgs.qlist(target:getCards("he")) do
            if card:isKindOf("EquipCard") and target:canDiscard(target, card:getEffectiveId()) then
                table.insert(eligible, tostring(card:getEffectiveId()))
            end
        end
        if #eligible == 0 then return end
        -- 以可弃置装备的ID作为选择范围，避免 exchange 接口选中禁止弃置的牌。
        --local ids = room:askForExchange(target, "xingzhao27", math.min(2, #eligible), 0,
        --    "@xingzhao27-discard", "", table.concat(eligible, ",") .. "|.|.|hand,equipped")
        local ids = room:askForExchange(target, "xingzhao27", math.min(2, #eligible), 0,
            "@xingzhao27-discard", "", "EquipCard|.|.|hand,equipped")
        if ids:isEmpty() then return end
        local dummy = sgs.DummyCard()
        for _, id in sgs.qlist(ids) do
            local card = sgs.Sanguosha:getCard(id)
            if room:getCardOwner(id) == target and card:isKindOf("EquipCard")
                and (room:getCardPlace(id) == sgs.Player_PlaceHand
                    or room:getCardPlace(id) == sgs.Player_PlaceEquip)
                and target:canDiscard(target, id) then
                dummy:addSubcard(id)
            end
        end
        local count = dummy:subcardsLength()
        if count > 0 then
            room:throwCard(dummy, target, target, "xingzhao27")
            if target:isAlive() then target:drawCards(2 * count, "xingzhao27") end
        end
        dummy:deleteLater()
    end,
}

xingzhao27 = sgs.CreateZeroCardViewAsSkill{
    name = "xingzhao27",
    view_as = function(self)
        local card = xingzhao27Card:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#xingzhao27Card")
    end,
}

tangzi27:addSkill(xingzhao27)

sgs.LoadTranslationTable{
    ["tangzi27"] = "唐咨",
    ["#tangzi27"] = "得时识风",
    ["xingzhao27"] = "兴槕",
    ["xingzhao27Card"] = "兴槕",
    ["@xingzhao27-discard"] = "兴槕：你可以弃置至多两张装备牌，每弃置一张摸两张牌",
    [":xingzhao27"] = "出牌阶段限一次。你可以对一名角色造成1点伤害，然后其可以弃置至多2张装备牌，摸弃置数量两倍的牌。",
}

mengda27 = sgs.General(extension, "mengda27", "wei", 4)

qiuan27 = sgs.CreateTriggerSkill{
    name = "qiuan27",
    events = {sgs.DamageInflicted},
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPile("letter27"):isEmpty()) then return "" end
        local damage = data:toDamage()
        if damage.card and not room:getCardIdsOnTable(damage.card):isEmpty() then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(), data)
    end,
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        if not player:getPile("letter27"):isEmpty() then return false end
        local ids = room:getCardIdsOnTable(damage.card)
        if ids:isEmpty() then return false end
        local id = ids:first()
        if ids:length() > 1 then
            room:fillAG(ids, player)
            id = room:askForAG(player, ids, false, self:objectName())
            room:clearAG(player)
        end
        if not ids:contains(id) or room:getCardPlace(id) ~= sgs.Player_PlaceTable then return false end
        room:broadcastSkillInvoke("qiuan", player)
        player:addToPile("letter27", id, true)
        return true -- 防止本次全部伤害，不是受到伤害后回复体力。
    end,
}

liangfan27VS = sgs.CreateOneCardViewAsSkill{
    name = "liangfan27",
    response_pattern = "@@liangfan27",
    expand_pile = "letter27",
    view_filter = function(self, card)
        return sgs.Self:getPile("letter27"):contains(card:getEffectiveId())
            and card:isAvailable(sgs.Self)
    end,
    view_as = function(self, card)
        local result = sgs.Sanguosha:cloneCard(card:objectName(), card:getSuit(), card:getNumber())
        result:addSubcard(card)
        result:setSkillName(self:objectName())
        result:setShowSkill(self:objectName())
        return result
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@liangfan27"
    end,
}

liangfan27 = sgs.CreateTriggerSkill{
    name = "liangfan27",
    view_as_skill = liangfan27VS,
    events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Start and not player:getPile("letter27"):isEmpty() then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        -- 直接询问使用；取消或没有合法使用方式时保留“函”，也不失去体力。
        room:askForUseCard(player, "@@liangfan27", "@liangfan27-use")
        return false
    end,
}

liangfan27_effect = sgs.CreateTriggerSkill{
    name = "#liangfan27-effect",
    global = true,
    events = {sgs.Damage, sgs.CardFinished},
    on_record = function(self, event, room, player, data)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == "liangfan27" and damage.damage > 0 then
                damage.card:setTag("liangfan27_damaged", sgs.QVariant(true))
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == "liangfan27" and damage.damage > 0
                and damage.from and damage.from:isAlive() and damage.to and damage.to:isAlive()
                and damage.from:canGetCard(damage.to, "he") then
                return self:objectName(), damage.from:objectName()
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == "liangfan27" and use.from and use.from:isAlive()
                and not use.card:getTag("liangfan27_damaged"):toBool() then
                return self:objectName(), use.from:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return event == sgs.CardFinished or ask_who:askForSkillInvoke("liangfan27", data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.CardFinished then
            room:loseHp(ask_who, 1)
        else
            local target = data:toDamage().to
            if target:isAlive() and ask_who:canGetCard(target, "he") then
                local id = room:askForCardChosen(ask_who, target, "he", "liangfan27", false, sgs.Card_MethodGet)
                room:obtainCard(ask_who, id, false)
            end
        end
        return false
    end,
}

mengda27:addSkill(qiuan27)
mengda27:addSkill(liangfan27)
mengda27:addSkill(liangfan27_effect)
extension:insertRelatedSkills("liangfan27", "#liangfan27-effect")

sgs.LoadTranslationTable{
    ["mengda27"] = "孟达",
    ["#mengda27"] = "怠军反复",
    ["qiuan27"] = "求安",
    ["letter27"] = "函",
    [":qiuan27"] = "当你受到伤害时，若你没有“函”，你可以将其中一张造成伤害的实体牌置于武将牌上，称为“函”，然后防止此伤害。",
    ["liangfan27"] = "量反",
    ["#liangfan27-effect"] = "量反",
    ["@liangfan27-use"] = "量反：你可以使用“函”；造成伤害后可获得受伤角色一张牌，结算后未造成伤害则失去1点体力",
    [":liangfan27"] = "准备阶段，你可以使用“函”，对目标造成伤害后你可以获得其一张牌，结算后若没有造成伤害，你失去1点体力。",
}

zhanglu27 = sgs.General(extension, "zhanglu27", "qun", 3)

bushi27Card = sgs.CreateSkillCard{
    name = "bushi27Card",
    skill_name = "bushi27",
    filter = function(self, targets, to_select, source)
        return #targets == 0 and to_select:hasShownOneGeneral()
    end,
    feasible = function(self, targets, source)
        return #targets == 1
    end,
    on_use = function(self, room, source, targets)
        local representative = targets[1]
        if not (source:isAlive() and representative and representative:isAlive()) then return end
        local members = {}
        for _, member in sgs.qlist(room:getAlivePlayers()) do
            if representative:isFriendWith(member) then table.insert(members, member) end
        end
        local collected = sgs.IntList()
        room:broadcastSkillInvoke("bushi", source)
        for _, member in ipairs(members) do
            if not source:isAlive() then return end
            if member:isAlive() and source:canGetCard(member, "he") then
                local id = room:askForCardChosen(source, member, "he", "bushi27", false, sgs.Card_MethodGet)
                room:obtainCard(source, id, false)
                if room:getCardOwner(id) == source and room:getCardPlace(id) == sgs.Player_PlaceHand then
                    collected:append(id)
                end
            end
        end
        -- 只分配本次获得且仍在手中的牌；分配接口会从 collected 移除已分配的牌。
        while source:isAlive() and not collected:isEmpty() do
            local pending = sgs.IntList()
            for _, id in sgs.qlist(collected) do
                if room:getCardOwner(id) == source and room:getCardPlace(id) == sgs.Player_PlaceHand then
                    pending:append(id)
                end
            end
            collected = pending
            if collected:isEmpty() then break end
            local recipients = sgs.SPlayerList()
            for _, member in ipairs(members) do
                if member:isAlive() then recipients:append(member) end
            end
            if recipients:isEmpty() then break end
            local before = collected:length()
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                source:objectName(), "", "bushi27", "")
            local given = room:askForYiji(source, collected, "bushi27", false, false, false,
                -1, recipients, reason, "@bushi27-give")
            if not given or collected:length() >= before then
                -- AI没有提供分配方案时，也不能将别势力的牌留在自己手中。
                local target = room:askForPlayerChosen(source, recipients, "bushi27", "@bushi27-target", false)
                local dummy = sgs.DummyCard(collected)
                room:obtainCard(target, dummy, reason, false)
                dummy:deleteLater()
                break
            end
        end
    end,
}

bushi27 = sgs.CreateZeroCardViewAsSkill{
    name = "bushi27",
    view_as = function(self)
        local card = bushi27Card:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#bushi27Card")
    end,
}

midao27 = sgs.CreateTriggerSkill{
    name = "midao27",
    events = {sgs.DamageCaused},
    can_trigger = function(self, event, room, player, data)
        local damage = data:toDamage()
        if not (damage.from and damage.from:isAlive() and damage.damage > 0
            and damage.nature ~= sgs.DamageStruct_Normal) then return "" end
        local skills, owners = {}, {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and not owner:hasFlag("midao27_used")
                and owner:isFriendWith(damage.from) then
                table.insert(skills, self:objectName())
                table.insert(owners, owner:objectName())
            end
        end
        return table.concat(skills, "|"), table.concat(owners, "|")
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if not (ask_who and ask_who:isAlive() and not ask_who:hasFlag("midao27_used")) then return false end
        if ask_who:askForSkillInvoke(self:objectName(), data) then
            room:setPlayerFlag(ask_who, "midao27_used")
            room:broadcastSkillInvoke("midao", ask_who)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local choice = room:askForChoice(ask_who, self:objectName(), "draw+damage", data)
        if choice == "draw" then
            ask_who:drawCards(2, self:objectName())
        else
            local damage = data:toDamage()
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
        return false
    end,
}

zhanglu27:addSkill(bushi27)
zhanglu27:addSkill(midao27)

sgs.LoadTranslationTable{
    ["zhanglu27"] = "张鲁",
    ["#zhanglu27"] = "政宽教惠",
    ["bushi27"] = "布施",
    ["bushi27Card"] = "布施",
    ["@bushi27-give"] = "布施：将本次获得的牌分配给所选势力的角色",
    ["@bushi27-target"] = "布施：选择一名所选势力的角色，获得剩余的牌",
    [":bushi27"] = "出牌阶段限一次。你可以获得一个势力所有角色各1张牌，然后将这些牌任意分配给该势力的角色。",
    ["midao27"] = "米道",
    ["#midao27-record"] = "米道",
    ["midao27:draw"] = "摸两张牌",
    ["midao27:damage"] = "令此伤害+1",
    [":midao27"] = "每回合限一次。与你势力相同的角色造成属性伤害时，你可以摸两张牌或令此伤害+1。",
}

liuqi27 = sgs.General(extension, "liuqi27", "qun", 3)

local function wenji27Records(player, card)
    local records = {}
    if not (player and card) then return records end
    for id, donor in string.gmatch(player:getTag("wenji27_records"):toString(), "(%d+):([^|]+)") do
        id = tonumber(id)
        if (not card:isVirtualCard() and card:getEffectiveId() == id)
            or card:getSubcards():contains(id) then
            table.insert(records, {id = id, donor = donor})
        end
    end
    return records
end

wenji27 = sgs.CreateTriggerSkill{
    name = "wenji27",
    events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Play) then return "" end
        for _, target in sgs.qlist(room:getOtherPlayers(player)) do
            if not target:isNude() then return self:objectName() end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        local targets = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getOtherPlayers(player)) do
            if not target:isNude() then targets:append(target) end
        end
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@wenji27-target", true)
        if target then
            player:setTag("wenji27_target", sgs.QVariant(target:objectName()))
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local target = room:findPlayer(player:getTag("wenji27_target"):toString())
        player:removeTag("wenji27_target")
        if not (target and target:isAlive() and not target:isNude()) then return false end
        local ids = room:askForExchange(target, self:objectName(), 1, 1,
            "@wenji27-give:" .. player:objectName(), "", ".|.|.|hand,equipped")
        if ids:isEmpty() then return false end
        local id = ids:first()
        if room:getCardOwner(id) ~= target then return false end
        room:broadcastSkillInvoke("wenji", player)
        room:showCard(target, id)
        if not (player:isAlive() and target:isAlive() and room:getCardOwner(id) == target) then return false end
        local old = player:getTag("wenji27_records"):toString()
        -- 同一实体牌再次被问计取得时，更新其返还对象，不重复记录。
        local records = {}
        for previous_id, donor in string.gmatch(old, "(%d+):([^|]+)") do
            if tonumber(previous_id) ~= id then table.insert(records, previous_id .. ":" .. donor) end
        end
        table.insert(records, tostring(id) .. ":" .. target:objectName())
        player:setTag("wenji27_records", sgs.QVariant(table.concat(records, "|")))
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
            target:objectName(), player:objectName(), self:objectName(), "")
        room:obtainCard(player, sgs.Sanguosha:getCard(id), reason, true)
        return false
    end,
}

wenji27_mod = sgs.CreateTargetModSkill{
    name = "#wenji27-mod",
    pattern = ".",
    residue_func = function(self, player, card)
        if #wenji27Records(player, card) > 0 then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, player, card)
        if #wenji27Records(player, card) > 0 then return 1000 end
        return 0
    end,
}

wenji27_effect = sgs.CreateTriggerSkill{
    name = "#wenji27-effect",
    global = true,
    events = {sgs.CardUsed, sgs.TargetChosen, sgs.CardFinished, sgs.TurnStart, sgs.EventPhaseChanging},
    on_record = function(self, event, room, player, data)
        if event == sgs.TurnStart or (event == sgs.EventPhaseChanging
            and data:toPhaseChange().to == sgs.Player_NotActive) then
            for _, owner in sgs.qlist(room:getAllPlayers(true)) do
                owner:removeTag("wenji27_records")
            end
        elseif event == sgs.CardUsed or event == sgs.TargetChosen then
            local use = data:toCardUse()
            if not (use.from and use.card) then return end
            -- 包括技能牌；只要曾经指定过其他角色，就不满足新版屯江。
            for _, target in sgs.qlist(use.to) do
                if target ~= use.from then
                    room:setPlayerFlag(use.from, "tunjiang27_targeted")
                    break
                end
            end
            if event ~= sgs.CardUsed then return end
            local records = wenji27Records(use.from, use.card)
            if #records == 0 then return end
            local bound = {}
            for _, entry in ipairs(records) do table.insert(bound, tostring(entry.id) .. ":" .. entry.donor) end
            use.card:setTag("wenji27_return", sgs.QVariant(table.concat(bound, "|")))
            -- 沿用项目已有的不可响应接口，覆盖所有角色而不只是目标。
            local blocked = use.disresponsive_list
            for _, other in sgs.qlist(room:getAlivePlayers()) do
                if not table.contains(blocked, other:objectName()) then table.insert(blocked, other:objectName()) end
            end
            use.disresponsive_list = blocked
            data:setValue(use)
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.CardFinished then return "" end
        local use = data:toCardUse()
        if use.from and use.from:isAlive() and use.card
            and use.card:getTag("wenji27_return"):toString() ~= "" then
            return self:objectName(), use.from:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local card = data:toCardUse().card
        local records = card:getTag("wenji27_return"):toString()
        card:removeTag("wenji27_return")
        for id, donor in string.gmatch(records, "(%d+):([^|]+)") do
            if not ask_who:isAlive() then break end
            local target = room:findPlayer(donor)
            if target and target:isAlive() then
                local eligible = false
                for _, other in sgs.qlist(ask_who:getCards("he")) do
                    if other:getEffectiveId() ~= tonumber(id) then eligible = true break end
                end
                if eligible then
                    local ids = room:askForExchange(ask_who, "wenji27", 1, 1,
                        "@wenji27-return:" .. donor, "", ".+^" .. id .. "|.|.|hand,equipped")
                    if not ids:isEmpty() then
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                            ask_who:objectName(), donor, "wenji27", "")
                        room:obtainCard(target, sgs.Sanguosha:getCard(ids:first()), reason, true)
                    end
                end
            end
        end
        return false
    end,
}

tunjiang27 = sgs.CreateTriggerSkill{
    name = "tunjiang27",
    events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName())
            and player:getPhase() == sgs.Player_Finish and not player:hasFlag("tunjiang27_targeted") then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return player:askForSkillInvoke(self:objectName(), data)
    end,
    on_effect = function(self, event, room, player, data)
        local kingdoms, count = {}, 0
        for _, other in sgs.qlist(room:getAlivePlayers()) do
            if other:hasShownOneGeneral() then
                if other:getRole() == "careerist" then
                    count = count + 1
                elseif not kingdoms[other:getKingdom()] then
                    kingdoms[other:getKingdom()] = true
                    count = count + 1
                end
            end
        end
        room:broadcastSkillInvoke("tunjiang", player)
        if count > 0 then player:drawCards(count, self:objectName()) end
        return false
    end,
}

liuqi27:addSkill(wenji27)
liuqi27:addSkill(wenji27_mod)
liuqi27:addSkill(wenji27_effect)
liuqi27:addSkill(tunjiang27)
extension:insertRelatedSkills("wenji27", "#wenji27-mod")
extension:insertRelatedSkills("wenji27", "#wenji27-effect")

sgs.LoadTranslationTable{
    ["liuqi27"] = "刘琦",
    ["#liuqi27"] = "居外而安",
    ["wenji27"] = "问计",
    ["#wenji27-mod"] = "问计",
    ["#wenji27-effect"] = "问计",
    ["@wenji27-target"] = "问计：你可以令一名其他角色展示并交给你一张牌",
    ["@wenji27-give"] = "问计：展示并交给%src一张牌",
    ["@wenji27-return"] = "问计：交给%src另一张牌（不能交回本次使用的问计牌）",
    [":wenji27"] = "出牌阶段开始时，你可以令一名其他角色展示并交给你一张牌，你于此回合使用此牌无距离次数限制且不可响应，结算后你交给其另一张牌。",
    ["tunjiang27"] = "屯江",
    [":tunjiang27"] = "结束阶段，若你于此回合没有使用牌指定过其他角色，你可以摸X张牌（X为场上势力数）。",
}

pengyang27 = sgs.General(extension, "pengyang27", "qun", 3)

-- 仅在本次以逸待劳结算期间记录弃牌，嵌套的普通以逸待劳不混入。
local tongling27_effects = {}
local tongling27_uses = {}

tongling27 = sgs.CreateTriggerSkill{
    name = "tongling27",
    events = {sgs.Damage},
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasSkill(self:objectName())
            and not player:hasFlag("tongling27_used")) then return "" end
        local damage = data:toDamage()
        if damage.from ~= player then return "" end
        local card = sgs.Sanguosha:cloneCard("await_exhausted", sgs.Card_NoSuit, 0)
        local available = card:isAvailable(player)
        card:deleteLater()
        if available then return self:objectName() end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if player:hasFlag("tongling27_used") then return false end
        if player:askForSkillInvoke(self:objectName(), data) then
            room:setPlayerFlag(player, "tongling27_used")
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local victim = data:toDamage().to
        local card = sgs.Sanguosha:cloneCard("await_exhausted", sgs.Card_NoSuit, 0)
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        local context = {room = room, card = card, owner = player, slashes = {}}
        table.insert(tongling27_uses, context)
        room:broadcastSkillInvoke("tongling", player)
        -- 内置牌负责同势力目标、摸牌、弃牌和无懈等完整流程。
        room:useCard(sgs.CardUseStruct(card, player, sgs.SPlayerList()), false)
        for i = #tongling27_uses, 1, -1 do
            if tongling27_uses[i] == context then table.remove(tongling27_uses, i) break end
        end
        card:deleteLater()
        for _, id in ipairs(context.slashes) do
            if not (player:isAlive() and victim and victim:isAlive()) then break end
            if room:getCardPlace(id) == sgs.Player_DiscardPile then
                local original = sgs.Sanguosha:getCard(id)
                local slash = sgs.Sanguosha:cloneCard(original:objectName(), original:getSuit(), original:getNumber())
                slash:addSubcard(id)
                slash:setSkillName(self:objectName())
                slash:setShowSkill(self:objectName())
                if not player:isCardLimited(slash, sgs.Card_MethodUse)
                    and player:canSlash(victim, slash, true) then
                    local prompt = sgs.QVariant()
                    prompt:setValue(victim)
                    player:setTag("tongling27_slash_id", sgs.QVariant(id))
                    if player:askForSkillInvoke("tongling27_slash", prompt) then
                        -- 询问后再次检查，以免插入结算改变牌或目标状态。
                        if player:isAlive() and victim:isAlive() and room:getCardPlace(id) == sgs.Player_DiscardPile
                            and not player:isCardLimited(slash, sgs.Card_MethodUse)
                            and player:canSlash(victim, slash, true) then
                            room:useCard(sgs.CardUseStruct(slash, player, victim), false)
                        end
                    end
                    player:removeTag("tongling27_slash_id")
                end
                slash:deleteLater()
            end
        end
        return false
    end,
}

pengyang27_record = sgs.CreateTriggerSkill{
    name = "#pengyang27-record",
    global = true,
    priority = 5,
    events = {sgs.GeneralShown, sgs.CardEffect, sgs.PostCardEffected, sgs.ChoiceMade},
    on_record = function(self, event, room, player, data)
        if event == sgs.GeneralShown and player then
            local current = room:getCurrent()
            if not current or current:getPhase() == sgs.Player_NotActive then return end
            room:setPlayerFlag(player, "jinxian27_shown")
            if player:hasSkill("jinxian27") then
                local shown = data:toString()
                local head = player:inHeadSkills("jinxian27")
                local own_shown
                if shown == "h" or shown == "d" or shown == "hd" then
                    own_shown = (head and string.find(shown, "h", 1, true))
                        or (not head and string.find(shown, "d", 1, true))
                else
                    -- 项目实际客户端的 GeneralShown 使用布尔值。
                    own_shown = data:toBool() == head
                end
                if own_shown then room:setPlayerFlag(player, "jinxian27_self_shown") end
            end
        elseif event == sgs.CardEffect then
            local effect = data:toCardEffect()
            if effect.card and effect.card:isKindOf("AwaitExhausted") then
                table.insert(tongling27_effects, {room = room, card = effect.card, target = effect.to})
            end
        elseif event == sgs.PostCardEffected then
            local effect = data:toCardEffect()
            for i = #tongling27_effects, 1, -1 do
                local entry = tongling27_effects[i]
                if entry.room == room and entry.card == effect.card and entry.target == effect.to then
                    table.remove(tongling27_effects, i)
                    break
                end
            end
        elseif event == sgs.ChoiceMade then
            -- askForDiscard 的移动原因不一定携带牌名，ChoiceMade 则明确记录弃牌来源。
            local discarded = string.match(data:toString(), "^cardDiscard:await_exhausted:(.*)$")
            if not discarded then return end
            local effect
            for i = #tongling27_effects, 1, -1 do
                if tongling27_effects[i].room == room then effect = tongling27_effects[i] break end
            end
            if not effect or effect.card:getSkillName() ~= "tongling27" then return end
            local context
            for i = #tongling27_uses, 1, -1 do
                if tongling27_uses[i].room == room and tongling27_uses[i].card == effect.card then
                    context = tongling27_uses[i] break
                end
            end
            if not context or effect.target == context.owner or effect.target ~= player then return end
            local discarded_card = sgs.Card_Parse(discarded)
            if not discarded_card then return end
            local ids = discarded_card:getSubcards()
            if not discarded_card:isVirtualCard() then
                ids = sgs.IntList()
                ids:append(discarded_card:getEffectiveId())
            end
            for _, id in sgs.qlist(ids) do
                if sgs.Sanguosha:getCard(id):isKindOf("Slash") and not table.contains(context.slashes, id) then
                    table.insert(context.slashes, id)
                end
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        return ""
    end,
}

jinxian27 = sgs.CreateTriggerSkill{
    name = "jinxian27",
    events = {sgs.EventPhaseChanging},
    can_trigger = function(self, event, room, player, data)
        if data:toPhaseChange().to ~= sgs.Player_NotActive then return "" end
        local skills, owners = {}, {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:hasFlag("jinxian27_self_shown") then
                for _, target in sgs.qlist(room:getOtherPlayers(owner)) do
                    if target:hasFlag("jinxian27_shown") then
                        table.insert(skills, self:objectName())
                        table.insert(owners, owner:objectName())
                        break
                    end
                end
            end
        end
        return table.concat(skills, "|"), table.concat(owners, "|")
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        local candidates = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getOtherPlayers(ask_who)) do
            if target:hasFlag("jinxian27_shown") then candidates:append(target) end
        end
        local selected = room:askForPlayersChosen(ask_who, candidates, self:objectName(),
            0, candidates:length(), "@jinxian27-target", true)
        if selected:isEmpty() then return false end
        local names = {}
        for _, target in sgs.qlist(selected) do table.insert(names, target:objectName()) end
        ask_who:setTag("jinxian27_targets", sgs.QVariant(table.concat(names, "|")))
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        local names = ask_who:getTag("jinxian27_targets"):toString()
        ask_who:removeTag("jinxian27_targets")
        room:setPlayerFlag(ask_who, "-jinxian27_self_shown")
        room:broadcastSkillInvoke("jinxian", ask_who)
        for name in string.gmatch(names, "[^|]+") do
            if not ask_who:isAlive() then break end
            local target = room:findPlayer(name)
            if target and target:isAlive() then
                local damage = sgs.DamageStruct()
                damage.from, damage.to = ask_who, target
                damage.damage, damage.reason = 1, self:objectName()
                room:damage(damage)
            end
        end
        return false
    end,
}

pengyang27:addSkill(tongling27)
pengyang27:addSkill(jinxian27)
pengyang27:addSkill(pengyang27_record)
extension:insertRelatedSkills("tongling27", "#pengyang27-record")
extension:insertRelatedSkills("jinxian27", "#pengyang27-record")

sgs.LoadTranslationTable{
    ["pengyang27"] = "彭羕",
    ["#pengyang27"] = "误身的狂士",
    ["tongling27"] = "通令",
    ["#pengyang27-record"] = "通令/近陷",
    ["tongling27_slash"] = "通令：对原受伤角色使用这张弃置的【杀】",
    [":tongling27"] = "每回合限一次。当你造成伤害后，你可以视为使用一张【以逸待劳】，然后你可以对该受伤角色依次使用其他角色因此弃置的【杀】。",
    ["jinxian27"] = "近陷",
    ["@jinxian27-target"] = "近陷：选择任意名本回合明置过武将牌的其他角色，各对其造成1点伤害",
    [":jinxian27"] = "你明置该武将牌的回合结束时，你可以对任意名本回合明置过武将牌的其他角色各造成1点伤害。",
}

liuba27 = sgs.General(extension, "liuba27", "shu", 3)

tongdu27 = sgs.CreateTriggerSkill{
    name = "tongdu27",
    global = true,
    events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_record = function(self, event, room, player, data)
        if not player then return end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Discard or change.to == sgs.Player_Discard then
                room:setPlayerMark(player, "tongdu27_discard", 0)
            end
        elseif event == sgs.CardsMoveOneTime and player:getPhase() == sgs.Player_Discard then
            local function record(move)
                if not move.from or move.from:objectName() ~= player:objectName() then return end
                if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                    ~= sgs.CardMoveReason_S_REASON_DISCARD then return end
                local count = 0
                for i = 0, move.card_ids:length() - 1 do
                    local place = move.from_places:at(i)
                    if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
                        count = count + 1
                    end
                end
                if count > 0 then room:addPlayerMark(player, "tongdu27_discard", count) end
            end
            local moves = data:toList()
            if moves:isEmpty() then
                record(data:toMoveOneTime())
            else
                for _, move_data in sgs.qlist(moves) do record(move_data:toMoveOneTime()) end
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event ~= sgs.EventPhaseEnd or not player or not player:isAlive()
            or player:getPhase() ~= sgs.Player_Discard
            or player:getMark("tongdu27_discard") == 0 then return "" end
        local skills, owners = {}, {}
        for _, owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if owner:isAlive() and owner:hasShownSkill(self:objectName()) and owner:isFriendWith(player) then
                table.insert(skills, self:objectName())
                table.insert(owners, owner:objectName())
            end
        end
        return table.concat(skills, "|"), table.concat(owners, "|")
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        local owner_data = sgs.QVariant()
        owner_data:setValue(ask_who)
        if player:askForSkillInvoke(self:objectName(), owner_data) then
            room:broadcastSkillInvoke("tongdu", ask_who)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        if player:isAlive() then
            player:drawCards(math.min(player:getMark("tongdu27_discard"), 2), self:objectName())
        end
        return false
    end,
}

qingyin27Card = sgs.CreateSkillCard{
    name = "qingyin27Card",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        if source:getMark("@qingyin27") == 0 then return end
        local head = source:inHeadSkills("qingyin27")
        room:removePlayerMark(source, "@qingyin27")
        room:broadcastSkillInvoke("qingyin", source)
        local friends = sgs.SPlayerList()
        for _, target in sgs.qlist(room:getAlivePlayers()) do
            if source:isFriendWith(target) then friends:append(target) end
        end
        for _, target in sgs.qlist(friends) do
            if target:isAlive() and target:isWounded() then
                local recover = sgs.RecoverStruct()
                recover.who, recover.recover = source, 1
                room:recover(target, recover)
            end
        end
        if source:isAlive() then source:removeGeneral(head) end
    end,
}

qingyin27 = sgs.CreateZeroCardViewAsSkill{
    name = "qingyin27",
    frequency = sgs.Skill_Limited,
    limit_mark = "@qingyin27",
    view_as = function(self)
        local card = qingyin27Card:clone()
        card:setSkillName(self:objectName())
        card:setShowSkill(self:objectName())
        return card
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@qingyin27") > 0
    end,
}

liuba27:addSkill(tongdu27)
liuba27:addSkill(qingyin27)

sgs.LoadTranslationTable{
    ["liuba27"] = "刘巴",
    ["tongdu27"] = "统度",
    ["tongdu27_discard"] = "统度弃牌数",
    [":tongdu27"] = "与你势力相同的角色弃牌阶段结束时，其可以摸X张牌（X为其此阶段弃牌数，且至多为2）。",
    ["qingyin27"] = "清隐",
    ["@qingyin27"] = "清隐",
    [":qingyin27"] = "限定技。出牌阶段，你可以令所有与你势力相同的角色各回复1点体力，然后你移除此武将牌。",
}

yanwangxuezhou = sgs.CreateArmor{
    name = "yanwangxuezhou",
    class_name = "yanwangxuezhou",
    suit = sgs.Card_Heart,
    number = 2,
}

yanwangxuezhou_skill = sgs.CreateTriggerSkill{
    name = "yanwangxuezhou_skill",
    global = true,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted},
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and player:hasArmorEffect("yanwangxuezhou")) then
            return ""
        end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then return self:objectName() end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return true
    end,
    on_effect = function(self, event, room, player, data)
        if not player:isKongcheng() then
            return room:askForDiscard(player, "yanwangxuezhou", 1, 1, false, false,
                "@yanwangxuezhou-discard")
        end
        local damage = data:toDamage()
        damage.damage = damage.damage + 1
        data:setValue(damage)
        return false
    end,
}

siming = sgs.CreateTreasure{
    name = "siming",
    class_name = "siming",
    suit = sgs.Card_Diamond,
    number = 2,
    on_install = function(self, player)
        if not player:isAlive() then return end
        local room = player:getRoom()
        if player:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.who, recover.recover = player, player:getMaxHp() - player:getHp()
            room:recover(player, recover)
        end
        if player:isAlive() then
            local count = 5 - player:getHandcardNum()
            if count > 0 then player:drawCards(count, self:objectName()) end
        end
    end,
    on_uninstall = function(self, player)
        if player:isAlive() and player:getHp() > 0 then
            player:getRoom():loseHp(player, player:getHp())
        end
    end,
}

tianxingluji = sgs.CreateWeapon{
    name = "tianxingluji",
    class_name = "tianxingluji",
    suit = sgs.Card_Club,
    number = 12,
    range = 3,
}

local tianxingluji_uses = {}
local function tianxinglujiUse(room, card)
    for i = #tianxingluji_uses, 1, -1 do
        local entry = tianxingluji_uses[i]
        if entry.room == room and entry.card == card then return entry, i end
    end
end

tianxingluji_skill = sgs.CreateTriggerSkill{
    name = "tianxingluji_skill",
    global = true,
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetChosen, sgs.DamageCaused, sgs.DamageDone, sgs.CardFinished},
    on_record = function(self, event, room, player, data)
        if event == sgs.TargetChosen then
            local use = data:toCardUse()
            if not (use.card and use.card:isKindOf("Slash") and use.from) then return end
            local entry = tianxinglujiUse(room, use.card)
            if not entry and use.from:hasWeapon("tianxingluji") then
                entry = {room = room, card = use.card, owner = use.from,
                    id = use.from:getWeapon():getEffectiveId(), damaged = false}
                table.insert(tianxingluji_uses, entry)
            end
            if entry then entry.target = use.to:length() == 1 and use.to:first() or nil end
        elseif event == sgs.DamageDone then
            local damage = data:toDamage()
            local entry = damage.card and tianxinglujiUse(room, damage.card)
            if entry and damage.damage > 0 then entry.damaged = true end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            local entry = damage.card and tianxinglujiUse(room, damage.card)
            if entry and entry.target == damage.to and damage.from == entry.owner
                and not damage.chain and not damage.transfer
                and entry.owner:hasWeapon("tianxingluji") then
                return self:objectName(), entry.owner:objectName()
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            local entry = use.card and tianxinglujiUse(room, use.card)
            if entry then return self:objectName(), entry.owner:objectName() end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        return true
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            damage.damage = damage.damage + 1
            data:setValue(damage)
        else
            local use = data:toCardUse()
            local entry, index = tianxinglujiUse(room, use.card)
            if not entry then return false end
            table.remove(tianxingluji_uses, index)
            if not entry.damaged and entry.target and entry.target:isAlive()
                and room:getCardOwner(entry.id) == entry.owner
                and room:getCardPlace(entry.id) == sgs.Player_PlaceEquip then
                room:obtainCard(entry.target, entry.id, true)
            end
        end
        return false
    end,
}

xuesezhixi = sgs.CreateTreasure{
    name = "xuesezhixi",
    class_name = "xuesezhixi",
    suit = sgs.Card_Spade,
    number = 12,
}

local function xuesezhixiCanUse(room, player, target)
    if not (player:isAlive() and not player:hasShownOneGeneral() and target:isAlive()
        and target ~= player and target:hasTreasure("xuesezhixi")) then return false end
    local card = sgs.Sanguosha:cloneCard("known_both")
    card:setSkillName("xuesezhixi")
    local available = not player:isCardLimited(card, sgs.Card_MethodUse)
        and not room:isProhibited(player, target, card)
        and card:targetFilter(sgs.PlayerList(), target, player)
    card:deleteLater()
    return available
end

xuesezhixi_skill = sgs.CreateTriggerSkill{
    name = "xuesezhixi_skill",
    global = true,
    events = {sgs.DrawNCards, sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive()) then return "" end
        if event == sgs.DrawNCards then
            if player:hasTreasure("xuesezhixi") then return self:objectName() end
        elseif player:getPhase() == sgs.Player_Play and not player:hasShownOneGeneral() then
            local skills, owners = {}, {}
            for _, target in sgs.qlist(room:getOtherPlayers(player)) do
                if xuesezhixiCanUse(room, player, target) then
                    table.insert(skills, self:objectName())
                    table.insert(owners, target:objectName())
                end
            end
            return table.concat(skills, "|"), table.concat(owners, "|")
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, ask_who)
        if event == sgs.DrawNCards then return true end
        local target_data = sgs.QVariant()
        target_data:setValue(ask_who)
        return player:askForSkillInvoke("xuesezhixi", target_data)
    end,
    on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.DrawNCards then
            data:setValue(data:toInt() + 2)
        elseif xuesezhixiCanUse(room, player, ask_who) then
            local card = sgs.Sanguosha:cloneCard("known_both")
            card:setSkillName("xuesezhixi")
            local use = sgs.CardUseStruct()
            use.card, use.from = card, player
            use.to:append(ask_who)
            room:useCard(use, false)
            card:deleteLater()
        end
        return false
    end,
}

yanwangxuezhou:setParent(equip)
xuesezhixi:setParent(equip)
tianxingluji:setParent(equip)
siming:setParent(equip)
if not sgs.Sanguosha:getSkill("yanwangxuezhou_skill") then
    equip27_skills:append(yanwangxuezhou_skill)
end
if not sgs.Sanguosha:getSkill("tianxingluji_skill") then
    equip27_skills:append(tianxingluji_skill)
end
if not sgs.Sanguosha:getSkill("xuesezhixi_skill") then
    equip27_skills:append(xuesezhixi_skill)
end
sgs.Sanguosha:addSkills(equip27_skills)

sgs.LoadTranslationTable{
    ["27Equip"] = "27国典装备",
    ["yanwangxuezhou"] = "燕王血胄",
    ["yanwangxuezhou_skill"] = "燕王血胄",
    [":yanwangxuezhou"] = "装备牌·防具\n\n锁定技。当你受到【杀】的伤害时，若你有手牌，你须弃置一张手牌，防止此伤害；若你没有手牌，此伤害+1。",
    ["@yanwangxuezhou-discard"] = "燕王血胄：弃置一张手牌，防止此次【杀】的伤害",
    ["siming"] = "司命",
    ["xuesezhixi"] = "血色之玺",
    ["xuesezhixi_skill"] = "血色之玺",
    [":xuesezhixi"] = "装备牌·宝物\n\n摸牌阶段，你多摸两张牌；未确定势力的其他角色出牌阶段开始时，其可以视为对你使用一张【知己知彼】。",
    ["tianxingluji"] = "天刑戮脊",
    ["tianxingluji_skill"] = "天刑戮脊",
    [":tianxingluji"] = "装备牌·武器\n\n攻击范围：3\n锁定技。你使用【杀】对唯一目标造成的伤害+1；结算后，若此【杀】未造成伤害，唯一目标获得此装备。",
    [":siming"] = "装备牌·宝物\n\n锁定技。此牌进入你的装备区时，你回复所有体力并将手牌摸至五张；此牌离开你的装备区时，你失去所有体力。",
}

return {extension, equip}
