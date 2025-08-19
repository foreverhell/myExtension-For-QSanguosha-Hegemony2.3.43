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

--王平
--[[local jiejianglve_skill = {}
jiejianglve_skill.name = "jiejianglve"
table.insert(sgs.ai_skills, jiejianglve_skill)
jiejianglve_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@jiejianglve") < 1 then return end
    return sgs.Card_Parse("#jiejianglveCard:.&jiejianglve")
end

sgs.ai_skill_use_func.jiejianglveCard = function(card, use, self)
    use.card = card
end

sgs.ai_use_priority.jiejianglveCard = 3.2]]

--潘淑
sgs.ai_skill_choice.jiezhiren = function(self, choices, data)
    return "guanxing"
end

--关羽
sgs.ai_skill_invoke.jienuzhan = true

--诸葛亮
sgs.ai_skill_invoke.jieguanxing = true

--南华老仙
--[[local jiejinghe_skill = {}
jiejinghe_skill.name = "jiejinghe"
table.insert(sgs.ai_skills, jiejinghe_skill)
jiejinghe_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("jiejingheCard") then return end
    return sgs.Card_Parse("#jiejingheCard:.&jiejinghe")
end

sgs.ai_skill_use_func.jiejingheCard = function(card, use, self)
    use.card = card
    if use.to then
        for _, p in ipairs(self.friends) do
          if self.player:isFriendWith(p) and p:hasShownOneGeneral() then
              use.to:append(p)
              break
          end
        end
    end
end

sgs.ai_use_priority.jiejingheCard = 3.2]]

--祖茂
sgs.ai_skill_invoke.jieyinbing = true
sgs.ai_skill_playerchosen.jieyinbing = function(self, choices, data)
    return self
end

--沮授
--sgs.ai_skill_invoke.luaxuyuan = true