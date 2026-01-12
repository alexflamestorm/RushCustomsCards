local s,id=GetID()
function s.initial_effect(c)
	-- Tratada como "Dragonic"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCARD)
	e0:SetValue(0x872) -- Se maneja por nombre o lógica de setcard en el mazo
	c:RegisterEffect(e0)

	-- Activar: Setear Magia/Trampa
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Bonus de ATK/DEF
	local e2=Effect.CreateEffect(c)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetValue(s.val)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- Efectos de Ignición
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1,id)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetTarget(s.efftg)
	e4:SetOperation(s.effop)
	c:RegisterEffect(e4)
end

-- Lógica de Setear Dragonic
function s.setfilter(c)
	return (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and (c:IsSetCard(0x872) or c:IsCode(49933857,49933866,49933867,49933868,49933872,49933876,49933877,49933884,49933890)) and c:IsSSetable()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local sg=g:Select(tp,1,1,nil)
		Duel.SSet(tp,sg)
	end
end

-- Cálculo de ATK/DEF dinámico
function s.is_strike(c)
	local code=c:GetCode()
	return (code>=49933851 and code<=49933906) or c:IsSetCard(0x871)
end
function s.val(e,c)
	return Duel.GetMatchingGroupCount(function(tc) return tc:IsFaceup() and s.is_strike(tc) end,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)*500
end

-- Lógica de selección de efectos
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local b1=Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	local b2=Duel.IsExistingTarget(function(c) return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsAttackPos() end,tp,LOCATION_MZONE,0,1,nil)
	if chk==0 then return b1 or b2 end
	
	-- No definimos targets aquí por la complejidad del "en secuencia"
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local has_strike=Duel.IsExistingMatchingCard(function(tc) return tc:IsFaceup() and s.is_strike(tc) end,tp,LOCATION_MZONE,0,1,nil)
	
	local b1=Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	local b2=Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsAttackPos() end,tp,LOCATION_MZONE,0,1,nil)

	local op=0
	if has_strike then op=3 -- Ambos
	elseif b1 and b2 then op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))+1
	elseif b1 then op=1
	elseif b2 then op=2 end

	-- Efecto 1: Debilitar y Bloquear
	if op==1 or op==3 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g1=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
		if #g1>0 then
			local tc=g1:GetFirst()
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(-1500)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			
			-- Chequeo de Atributo/Tipo
			local dg=Duel.GetMatchingGroup(function(dc) return dc:IsFaceup() and dc:IsRace(RACE_DRAGON) end,tp,LOCATION_MZONE,0,nil)
			if dg:IsExists(function(dc) return dc:GetAttribute()==tc:GetAttribute() or dc:GetRace()==tc:GetRace() end,1,nil) then
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_CANNOT_ACTIVATE_EFFECT)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e2)
			end
		end
	end

	if op==3 then Duel.BreakEffect() end

	-- Efecto 2: Doble Ataque
	if op==2 or op==3 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g2=Duel.SelectMatchingCard(tp,function(c) return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsAttackPos() end,tp,LOCATION_MZONE,0,1,1,nil)
		if #g2>0 then
			local tc=g2:GetFirst()
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
			e3:SetValue(1)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e3)
		end
	end
end