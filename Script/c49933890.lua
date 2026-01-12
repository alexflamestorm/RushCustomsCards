
local s,id=GetID()
function s.initial_effect(c)
	-- Activar: Fusión desde Campo/GY regresando al Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Filtro para el Monstruo de Fusión (Debe listar Strike Dragon o Dragias)
function s.ffilter(c)
	return c:IsRace(RACE_DRAGON) and (c:IsCodeListed(49933885) or c:IsSetCard(0x871)) -- 10000052 = The Dragias
end

-- Filtro de materiales (Shuffling into Deck)
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCanBeFusionMaterial),tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_MZONE+LOCATION_GRAVE)
end

function s.filter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and s.ffilter(c) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,nil,chkf)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCanBeFusionMaterial),tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local sg=Duel.GetMatchingGroup(s.filter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,nil,chkf)
	if #sg>0 then
		local tc=sg:Select(tp,1,1,nil):GetFirst()
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
		tc:SetMaterial(mat)
		if #mat>0 then
			Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
				-- Si usó 3 o más materiales, aplicar inmunidad
				if #mat>=3 then
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetDescription(aux.Stringid(id,1))
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_IMMUNE_TO_EFFECTS)
					e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
					e1:SetValue(s.efilter)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e1)
				end
				tc:CompleteProcedure()
			end
		end
	end
end

function s.efilter(e,re)
	return e:GetHandlerPlayer()~=re:GetOwnerPlayer()
end