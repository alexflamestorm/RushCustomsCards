
local s,id=GetID()
function s.initial_effect(c)
	-- Menciona a Femtron
	s.listed_names={49933816}
	
	-- Efecto 1: Activar y enviar al GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- Efecto 2: Excavar 3
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DECKDES)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.exctg)
	e2:SetOperation(s.excop)
	c:RegisterEffect(e2)
	
	-- Efecto 3: Bloqueo de Posición de Batalla
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetCondition(s.poscon)
	c:RegisterEffect(e3)
	
	-- Efecto 4: Reciclar desde el GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.setcon)
	e4:SetCost(s.setcost)
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)
end

-- Lógica Activación (Send to GY)
function s.tgfilter(c)
	return (c:IsCode(49933816) or (c:IsRace(RACE_CYBERSE) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))))
		and c:IsAbleToGrave()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoGrave(sg,REASON_EFFECT)
	end
end

-- Lógica Excavación
function s.excfilter(c)
	return (c:IsRace(RACE_CYBERSE) or c:ListsCode(49933816)) and c:IsAbleToGrave()
end
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,3) end
end
function s.excop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.ConfirmDecktop(tp,3)
	local g=Duel.GetDecktopGroup(tp,3)
	if #g>0 then
		local tg=g:Filter(s.excfilter,nil)
		if #tg>0 then
			Duel.DisableShuffleCheck()
			Duel.SendtoGrave(tg,REASON_EFFECT)
		end
		local rest=g:Filter(Card.IsLocation,nil,LOCATION_DECK)
		if #rest>0 then
			Duel.SortDecktop(tp,tp,#rest)
			for i=1,#rest do
				local tc=Duel.GetDecktopGroup(tp,1):GetFirst()
				Duel.MoveSequence(tc,SEQ_DECKBOTTOM)
			end
		end
	end
end

-- Lógica Bloqueo Posición
function s.poscon(e)
	return Duel.IsExistingMatchingCard(function(c) return c:IsType(TYPE_FUSION) and c:IsRace(RACE_CYBERSE) 
		and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK)) and c:IsFaceup() end, e:GetHandlerPlayer(), LOCATION_MZONE, 0, 1, nil)
end

-- Lógica Re-Set desde GY
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(function(c) return c:IsRace(RACE_CYBERSE) 
		and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK)) and c:IsFaceup() end, tp, LOCATION_MZONE, 0, 1, nil)
end
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp,c)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1)
	end
end