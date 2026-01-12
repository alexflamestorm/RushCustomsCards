local s,id=GetID()
function s.initial_effect(c)
	-- Activar: Robar 3 y efectos de nivel 7
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_RECOVER+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Condición: Ataque de un nivel 7 o superior del oponente
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()
	return tc:IsControler(1-tp) and tc:IsLevelAbove(7)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,3) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,3)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Draw(tp,3,REASON_EFFECT)~=3 then return end
	local g=Duel.GetOperatedGroup()
	Duel.ConfirmCards(1-tp,g)
	
	-- Filtrar monstruos de nivel 7+ entre lo robado
	local sg=g:Filter(function(c) return c:IsType(TYPE_MONSTER) and c:IsLevelAbove(7) end,nil)
	local count=#sg
	
	if count>0 then
		-- Curar 1500 por cada uno
		if Duel.Recover(tp,count*1500,REASON_EFFECT)>0 then
			-- Invocación especial opcional de uno de ellos
			local spg=sg:Filter(Card.IsCanBeSpecialSummoned,nil,e,0,tp,false,false)
			if #spg>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sc=spg:Select(tp,1,1,nil)
				Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
	Duel.ShuffleHand(tp)
end