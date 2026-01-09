local s,id=GetID()
function s.initial_effect(c)
	-- Menciona a Femtron y Space Yggdrago
	s.listed_names={49933816,49933838}
	
	-- Efecto 1: Fusión + Destrucción
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)
	
	-- Efecto 2: Recuperación desde el GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Filtro de Materiales
function s.ffilter(c)
	return c:IsRace(RACE_CYBERSE) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg1=Duel.GetFusionMaterial(tp):Filter(s.ffilter,nil)
		return Duel.IsExistingMatchingCard(Card.IsFusionSummonableCard,tp,LOCATION_EXTRA,0,1,nil,mg1)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg1=Duel.GetFusionMaterial(tp):Filter(s.ffilter,nil)
	local sg=Duel.GetMatchingGroup(Card.IsFusionSummonableCard,tp,LOCATION_EXTRA,0,nil,mg1)
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=Duel.SelectMatchingCard(tp,Card.IsFusionSummonableCard,tp,LOCATION_EXTRA,0,1,1,nil,mg1):GetFirst()
		if tc then
			local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,tp)
			tc:SetMaterial(mat1)
			
			-- Verificar si se usó Femtron o Space Yggdrago
			local check = mat1:IsExists(function(c) return c:IsCode(49933816, 49933838) end, 1, nil)
			
			Duel.SendtoGrave(mat1,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP) then
				tc:CompleteProcedure()
				
				-- Efecto de destrucción opcional
				if check and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
					local dg=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
					Duel.Destroy(dg,REASON_EFFECT)
				end
			end
		end
	end
end

-- Lógica de Recuperación
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE) 
		and c:IsRace(RACE_CYBERSE) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK)) end, 1, nil)
end

function s.thfilter(c)
	return c:IsAbleToDeck()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() 
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,2,e:GetHandler()) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,2,2,c)
	if #g==2 then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3)) -- "Select order for top of deck"
		local og=g:Select(tp,2,2,nil)
		Duel.ToDeckTop(og)
		if c:IsRelateToEffect(e) then
			Duel.SendtoHand(c,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,c)
		end
	end
end