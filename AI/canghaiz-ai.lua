--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  Mogara
*********************************************************************]]

--骆统
sgs.ai_skill_invoke.luaqinzheng = function(self, data)
    return true
end
sgs.ai_skill_playerchosen.luaqinzheng = function(self, targets)
    local effectslash, best_target, target, throw_weapon
	local defense = 6
	local weapon = self.player:getWeapon()
	if weapon and (weapon:isKindOf("Fan") or weapon:isKindOf("QinggangSword")) then 
        throw_weapon = true 
    end
    for _, enemy in sgs.qlist(targets) do
        if self:isFriend(enemy) then continue end
		local def = sgs.getDefenseSlash(enemy, self)
		local slash = sgs.cloneCard("slash")
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if not self.player:canSlash(enemy, slash, false) then
		elseif throw_weapon and enemy:hasArmorEffect("Vine") then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy, self.player) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
	end
    if best_target then return best_target end
    if target then return target end
    return ""
end

--虞翻
sgs.ai_skill_invoke.luazhiyan = function(self, data)
    return true
end
sgs.ai_skill_playerchosen.luazhiyan = function(self, targets)
    local friends = {}
    if self.player:getMark("luazongxuan_discard") > 0 then
        for _, p in sgs.qlist(targets) do
            if self.player:isFriendWith(p) then
                table.insert(friends, p)
            end
        end
        self:sort(friends, "hp")
    else
        self.room:sortByActionOrder(targets)
        for _, p in sgs.qlist(targets) do
            if self.player:isFriendWith(p) then
                table.insert(friends, p)
                break
            end
        end
    end
    return friends[1]
end

--曹植
sgs.ai_skill_invoke.lualuoying = function(self, data)
    return true
end
local luajiushi_skill = {}
luajiushi_skill.name = "luajiushi"
table.insert(sgs.ai_skills, luajiushi_skill)
luajiushi_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("#luajiushiCard") then return false end
    if not self.player:hasShownAllGenerals() or self.player:hasUsed("Analeptic") then return false end
    if self:getCardsNum("Slash") == 0 then return false end
    return sgs.Card_Parse("#luajiushiCard:.:&luajiushi")
end
sgs.ai_skill_use_func["#luajiushiCard"] = function(card, use, self)
    use.card = card
end
sgs.ai_use_priority.luajiushiCard = 6