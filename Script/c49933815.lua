local s,id=GetID()
function s.initial_effect(c)
	-- Tratada como "War-Lion Ritual"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetValue(54539105) -- ID de War-Lion Ritual
	c:RegisterEffect(e0)

	-- Proceso de Ritual
	local e1=Ritual.AddProcGreater({
		handler=c,
		filter=s.ritual_filter,
		matfilter=s.mat_filter,
		stage2=s.stage2
	})
	c:RegisterEffect(e1)

	-- Protección desde el GY (Efecto de reemplazo)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

-- Filtro: Solo monstruos Ritual de tipo Bestia
function s.ritual_filter(c)
	return c:IsRace(RACE_BEAST) and c:IsRitualMonster()
end

-- Filtro: Solo materiales de tipo Bestia
function s.mat_filter(c)
	return c:IsRace(RACE_BEAST)
end

-- Efecto adicional si se invoca a Super War-Lion
function s.stage2(mg,tc,tp,is_button)
	if tc:IsCode(33951077) then -- ID de Super War-Lion
		local e1=Effect.CreateEffect(tc)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- Lógica de Protección (Super War-Lion o cartas que lo mencionen)
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
		and (c:ListsCode(33951077))
		and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>-1
		and eg:IsExists(s.repfilter,1,nil,tp) and e:GetHandler():IsAbleToDeck() end
	if Duel.SelectEffectYesNo(tp,e:GetHandler(),96) then
		return true
	end
	return false
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECORATE,REASON_EFFECT)
end