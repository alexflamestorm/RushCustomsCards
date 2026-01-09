local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon: 2+ Ciberso LUZ/OSC
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,s.matfilter,2,99)
	
	-- Efecto 1: Link Summon (Mill 3 + Send to GY)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DECKDES+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_LINK_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)
	
	-- Efecto 2: Invocación Masiva (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	
	-- Efecto 3: Revivir desde GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.selfspcon)
	e3:SetTarget(s.selfsptg)
	e3:SetOperation(s.selfspop)
	c:RegisterEffect(e3)
end

s.listed_names={49933816}

function s.matfilter(c,lc,sumtype,tp)
	return c:IsRace(RACE_CYBERSE,lc,sumtype,tp) and (c:IsAttribute(ATTRIBUTE_LIGHT,lc,sumtype,tp) or c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp))
end

-- Lógica E1 (Mill + Removal)
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,3) 
		and Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,3)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.DiscardDeck(tp,3,REASON_EFFECT)==3 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end

-- Lógica E2 (Invocación Masiva)
function s.fmtronfilter(c)
	return c:ListsCode(49933816) and c:IsRace(RACE_CYBERSE)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetMatchingGroupCount(s.fmtronfilter,tp,LOCATION_GRAVE,0,nil)>=5
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,nil,1,false,nil,nil) end
	local g=Duel.SelectReleaseGroupCost(tp,nil,1,1,false,nil,nil)
	Duel.Release(g,REASON_COST)
end
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) and c:IsRace(RACE_CYBERSE)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>3 then ft=3 end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,nil,e,tp)
	if #g>0 then
		local sg=aux.SelectUnselectGroup(g,e,tp,1,ft,aux.dncheck,1,tp,HINTMSG_SPSUMMON)
		if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)>0 then
			-- Efecto de Daño en End Phase
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PHASE+PHASE_END)
			e1:SetCountLimit(1)
			e1:SetOperation(s.damop)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(Card.IsRace,tp,LOCATION_MZONE,0,nil,RACE_CYBERSE)
	Duel.Damage(tp,ct*1000,REASON_EFFECT)
end

-- Lógica E3 (Autorevivir)
function s.selfspfilter(c,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_GRAVE) and c:IsPreviousLocation(LOCATION_DECK)
end
function s.selfspcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.selfspfilter,1,nil,tp)
end
function s.selfsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.selfspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
