-- Equipment values use card class names; effect callbacks use object names.
local function hasAvailableSkill(player, name)
    if not player:hasSkill(name) then return false end
    local skill = sgs.Sanguosha:getSkill(name)
    if skill and skill:getFrequency() == sgs.Skill_Compulsory then return true end
    if player:getMark("skill_invalidity") > 0 then return false end
    if player:inHeadSkills(name) and player:getMark("skill_invalidity_head") > 0 then return false end
    if player:inDeputySkills(name) and player:getMark("skill_invalidity_deputy") > 0 then return false end
    return true
end

local weapons = {
    ShiXueJian = 2, AnShaJian = 2, YinLeiJian = 4,
    yuansuzhiren = 4, kuangzhanshi = 4,
}
for class_name, range in pairs(weapons) do
    sgs.weapon_range[class_name] = range
    sgs.ai_use_value[class_name] = 5
    sgs.ai_use_priority[class_name] = 2.6
    sgs.ai_keep_value[class_name] = 2.5
end

local armor_values = {
    QianKunDai = { "qiankundai", 3 },
    XiuliQiankun = { "XiuliQiankun", 3 },
    Bileizhen = { "Bileizhen", 4 },
    shengfan = { "shengfan", 4 },
    fantanjia = { "fantanjia", 4 },
    QiyiShouhu = { "QiyiShouhu", 3 },
}
for class_name, entry in pairs(armor_values) do
    local value = entry[2]
    sgs.ai_use_value[class_name] = 5
    sgs.ai_use_priority[class_name] = 2.5
    sgs.ai_keep_value[class_name] = 3
    sgs.ai_armor_value[entry[1]] = function(player, self)
        if entry[1] == "shengfan" and player:isWounded() then return value + 2 end
        return value
    end
end

sgs.ai_weapon_value.shixuejian = function(self, enemy, player)
    return player:isWounded() and 3 or 1
end
sgs.ai_weapon_value.anshajian = function(self, enemy, player)
    for name in sgs.masochism_skill:gmatch("[^|]+") do
        if enemy:hasShownSkill(name) and hasAvailableSkill(enemy, name) then return 4 end
    end
    return 2
end
sgs.ai_weapon_value.YinLeiJian = function(self, enemy, player)
    local value = 2
    if enemy:hasArmorEffect("Vine") then value = value + 2 end
    if enemy:isChained() and self:isGoodChainTarget(enemy, player, sgs.DamageStruct_Thunder) then
        value = value + 2
    end
    return value
end
sgs.ai_weapon_value.yuansuzhiren = function(self, enemy, player)
    for _, card in sgs.qlist(player:getHandcards()) do
        if card:isKindOf("ThunderSlash") or card:isKindOf("FireSlash") then
            return 4
        end
    end
    return 2
end
sgs.ai_weapon_value.kuangzhanshi = function(self, enemy, player)
    return player:getHp() > 2 and 2 or 0
end

sgs.ai_skill_invoke["anshajian_skill"] = function(self, data)
    local damage = data:toDamage()
    local target = damage.to
    local source = damage.from or self.player
    if not target or not self:isEnemy(target) then return false end
    -- HP loss bypasses Tianxiang's damage transfer.
    if hasAvailableSkill(target, "tianxiang") then return true end
    if hasAvailableSkill(target, "yuanyu") and not source:inMyAttackRange(target) then
        return true
    end
    if hasAvailableSkill(target, "mingshi") and not source:hasShownAllGenerals() then
        return true
    end

    -- Convert to HP loss before armor can prevent or reduce the damage.
    if damage.nature ~= sgs.DamageStruct_Normal and target:hasArmorEffect("PeaceSpell") then
        return true
    end
    if damage.damage > target:getHp() and target:hasArmorEffect("Breastplate") then return true end
    if damage.damage > 1 and (target:hasArmorEffect("SilverLion")
        or target:hasArmorEffect("fantanjia") or hasAvailableSkill(target, "gongqing")) then return true end

    local effective = self:damageIsEffective(target, damage.nature, source, damage.card)
    -- Preserve a beneficial elemental chain that hits additional enemies.
    if effective and damage.nature ~= sgs.DamageStruct_Normal and target:isChained()
        and not damage.chain and not damage.transfer
        and self:isGoodChainTarget(target, source, damage.nature, damage.damage, damage.card) then
        local balance = 0
        for _, player in sgs.qlist(self.room:getAlivePlayers()) do
            if player:objectName() ~= target:objectName() and player:isChained()
                and self:damageIsEffective(player, damage.nature, source, damage.card) then
                if self:isEnemy(player) then balance = balance + 1
                elseif self:isFriend(player) then balance = balance - 1 end
            end
        end
        if balance > 0 and not (deathRetaliation and damage.damage >= target:getHp()) then
            return false
        end
    end

    -- Death skills that retaliate against the damage source. HP loss has
    -- no damage source, so it can avoid their killer-dependent effects.
    local deathRetaliation = false
    for _, name in ipairs({ "duanchang", "yanhuo", "huilei" }) do
        if hasAvailableSkill(target, name) then
            deathRetaliation = true
            break
        end
    end
    -- Require lethal damage even against an upper bound on hand-card saves.
    -- Unknown cards may be Peach, or Analeptic in the dying player's hand.
    local amount = damage.damage
    if target:hasArmorEffect("SilverLion") or target:hasArmorEffect("fantanjia") then
        amount = 1 -- Conservative while later damage-reduction triggers are pending.
    end
    if effective and not HasBuquEffect(target) and not HasNiepanEffect(target)
        and amount >= target:getHp() then
        local saves = 0
        for _, player in sgs.qlist(self.room:getAlivePlayers()) do
            saves = saves + player:getHandcardNum() + player:getHandPile():length()
        end
        if amount >= target:getHp() + saves then --能确定击杀
            return deathRetaliation 
        else
            return true
        end
    end
    return true
end
local function shengfanDiscard(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) and not card:isKindOf("Peach")
            and not (card:isKindOf("Jink") and self:getCardsNum("Jink") <= 1)
            and not (card:isKindOf("Analeptic") and self:isWeak()) then
            local value = self:getKeepValue(card)
            if self.player:hasEquip(card) and card:isKindOf("Armor") then
                value = math.max(value, self:evaluateArmor(card))
                if card:objectName() == "shengfan" and self.player:getLostHp() == 1
                    and not self:needToThrowArmor() then value = math.max(value, 5) end
            end
            if value < (self:isWeak() and 5 or 4) then return card:getEffectiveId() end
        end
    end
end
sgs.ai_skill_invoke["shengfan_skill"] = function(self)
    return self.player:isWounded() and shengfanDiscard(self) ~= nil
end
sgs.ai_skill_discard["shengfan_skill"] = function(self)
    local id = shengfanDiscard(self)
    if id then return { id } end
    -- Once invoked the discard is compulsory; use the standard fallback.
    return nil
end
sgs.ai_skill_invoke["kuangzhanshi_skill"] = function(self, data)
    local damage = data:toDamage()
    local target = damage.to
    if not target or not self:isEnemy(target) or self.player:getHp() < 2 then return false end
    if hasAvailableSkill(target, "tianxiang") then return false end
    if (damage.damage + 1 >= target:getHp() and target:hasArmorEffect("Breastplate")) or target:hasArmorEffect("fantanjia")
        or target:hasArmorEffect("SilverLion") then return false end
    if damage.nature ~= sgs.DamageStruct_Normal and target:hasArmorEffect("PeaceSpell") then
        return false
    end
    if damage.nature == sgs.DamageStruct_Thunder and target:hasArmorEffect("Bileizhen") then
        return false
    end
    return true
end
local function bileizhenHasDamageBenefit(self, data)
    local damage = data:toDamage()
    local player = self.player
    local source = damage.from

    local function available(name)
        return hasAvailableSkill(player, name)
    end

    -- Respect skill invalidation and the AI's willingness to invoke.
    local function wantsSkill(name)
        return available(name) and self:askForSkillInvoke(name, data) == true
    end
    if wantsSkill("yiji") or wantsSkill("zhiyu") or wantsSkill("quanji")
        or wantsSkill("shicai") then return true end

    if source and source:isAlive() then
        if player:canGetCard(source, "he") and wantsSkill("fankui") then return true end
        if self:isEnemy(source) and wantsSkill("ganglie") then return true end
    end

    -- Jianxiong only obtains the damage card while all its physical cards
    -- are still on the table; redirected cardless damage gives no cards.
    if damage.card and available("jianxiong") then
        local ids = damage.card:getSubcards()
        local obtainable = not damage.card:isVirtualCard()
            and self.room:getCardPlace(damage.card:getEffectiveId()) == sgs.Player_PlaceTable
        if damage.card:isVirtualCard() and not ids:isEmpty() then
            obtainable = true
            for _, id in sgs.qlist(ids) do
                if self.room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                    obtainable = false
                    break
                end
            end
        end
        if obtainable and wantsSkill("jianxiong") then return true end
    end

    if available("jieming") and self:willShowForMasochism() then
        for _, friend in ipairs(self.friends) do
            if friend:isAlive() and friend:getHandcardNum() < math.min(5, friend:getMaxHp())
                and not self:needKongcheng(friend, true) then return true end
        end
    end

    -- Fangzhu can help a face-down ally without paying its turnover cost.
    if (available("fangzhu") or available("fangzhu_lordcaopi"))
        and self:willShowForMasochism() then
        for _, friend in ipairs(self.friends_noself) do
            if friend:isAlive() and not friend:faceUp() then return true end
        end
    end

    -- Qianhuan requires a hand card of a suit not already in its pile.
    if wantsSkill("qianhuan") then
        local suits = {}
        for _, id in sgs.qlist(player:getPile("sorcery")) do
            suits[sgs.Sanguosha:getCard(id):getSuit()] = true
        end
        for _, card in sgs.qlist(player:getHandcards()) do
            if not suits[card:getSuit()] then return true end
        end
    end
    return false
end

sgs.ai_skill_invoke["@bileizhen_immuse"] = function(self, data)
    local damage = data:toDamage()
    if damage.damage == 1 and self.player:getHp() > damage.damage
        and bileizhenHasDamageBenefit(self, data) then
        return false
    end
    return true
end
sgs.ai_skill_invoke["@bileizhen_effect"] = true
sgs.ai_skill_invoke["@bileizhen_attract"] = function(self, data)
    local damage = data:toDamage()
    return damage.to and self:isFriend(damage.to)
end
sgs.ai_skill_choice["Bileizhen_skill"] = function(self, choices)
    if self.player:isWounded() and choices:match("recover") then return "recover" end
    return "draw"
end

-- The visible view-as skill was renamed so it does not intercept equip clicks.
local yinleijian_skill = { name = "YinLeiJianSkill" }
table.insert(sgs.ai_skills, yinleijian_skill)
yinleijian_skill.getTurnUseCard = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") and not card:isKindOf("ThunderSlash")
            and not card:isKindOf("FireSlash") then
            local thunder = sgs.Card_Parse(("thunder_slash:YinLeiJian[%s:%s]=%d&")
                :format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
            for _, enemy in ipairs(self.enemies) do
                if self.player:canSlash(enemy, thunder, true)
                    and self:slashIsEffective(thunder, enemy, self.player)
                    and (not enemy:isChained() or self:isGoodChainTarget(enemy,
                        self.player, sgs.DamageStruct_Thunder, nil, thunder))
                    and (enemy:hasArmorEffect("Vine") or not self:slashIsEffective(card, enemy, self.player)
                        or enemy:isChained()) then
                    return thunder
                end
            end
        end
    end
end
