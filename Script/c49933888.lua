
local s,id=GetID()
function s.initial_effect(c)
	-- Tratada como "Dragonic"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCARD)
	e0:SetValue(0x872) 
	c:RegisterEffect(e0)

	-- Efecto de Activación
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Filtro para identificar Strike Dragons
function s.is_strike(c)
	local code=c:GetCode()
	-- Rango de IDs de Strike Dragons creados en esta sesión
	return (code>=49933851 and code<=49933906) or c:IsSetCard(0x871)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.is_strike,tp,LOCATION_MZONE,0,1,nil)
end

-- Filtro para el monstruo a invocar (mismo nombre original que uno en campo)
function s.spfilter(c,e,tp)
	local names={}
	local g=Duel.GetMatchingGroup(s.is_strike,tp,LOCATION_MZONE,0,nil)
	local tc=g:GetFirst()
	while tc do
		table.insert(names,tc:GetOriginalCode())
		tc=g:GetNext()
	end
	return c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
		and aux.IsCodeListed(c,table.unpack(names)) -- Simplificado: chequear si el código original coincide
end

-- Función manual para chequear nombre original en campo
function s.check_original_name(c,tp)
	local g=Duel.GetMatchingGroup(s.is_strike,tp,LOCATION_MZONE,0,nil)
	return g:IsExists(Card.IsOriginalCode,1,nil,c:GetOriginalCode())
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(function(c,e,tp) return c:IsCanBeSpecialSummoned(e,0,tp,false,false) and s.check_original_name(c,tp) end,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(function(c,e,tp) return c:IsCanBeSpecialSummoned(e,0,tp,false,false) and s.check_original_name(c,tp) end),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Efecto adicional: Equipar Vice Slasher
		if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,49933887),tp,LOCATION_MZONE,0,1,nil) then
			local eqg=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCode),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil,49933887)
			local target_drag=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil):Filter(Card.IsRace,nil,RACE_DRAGON)
			if #eqg>0 and #target_drag>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
				local eq=eqg:Select(tp,1,1,nil):GetFirst()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
				local tc=target_drag:Select(tp,1,1,nil):GetFirst()
				if tc then
					Duel.Equip(tp,eq,tc)
				end
			end
		end
	end
end