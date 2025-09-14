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
luajiushi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#luajiushiCard") then return false end
    if not self.player:hasShownAllGenerals() and self.player:hasUsed("Analeptic") then return false end
    local cards = sgs.QList2Table(self.player:getHandcards())
    if self:getCardsNum("Slash") == 0 then return false end
    return sgs.Card_Parse("#luajiushiCard:.:&luajiushi")
end
sgs.ai_skill_use_func["#luajiushiCard"] = function(card, use, self)
    use.card = card
end
sgs.ai_view_as.luajiushi = function(card, player, card_place)
    if player:hasShownAllGenerals() and player:getHp() <= 0 then
        return "#luajiushiCard:.:&luajiushi"
    end
end
sgs.ai_use_priority.luajiushiCard = 4.2