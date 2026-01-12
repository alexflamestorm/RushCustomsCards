local s,id=GetID()
function s.initial_effect(c)
	-- Invocación Especial por Tributo
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Buscar Magia/Trampa "Dragonic"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Protección Quick Effect + Doble Ataque
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetCost(s.protcost)
	e4:SetOperation(s.protop)
	c:RegisterEffect(e4)
end

-- Lógica Procedimiento de Invocación
function s.spfilter(c)
	local n=c:GetCode()
	return c:IsRace(RACE_DRAGON) or (n==49933851 or n==49933852 or n==49933853 or n==49933854 or n==49933855 or n==49933856 or n==49933857 or n==49933858 or n==49933859 or n==49933860 or n==49933862 or n==49933863 or n==49933864 or n==49933865 or n==49933869 or n==49933870 or n==49933871 or n==49933874 or n==49933875 or n==49933882)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetReleaseGroup(tp):Filter(s.spfilter,nil)
	return #rg>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=Duel.GetReleaseGroup(tp):Filter(s.spfilter,nil)
	local g=aux.SelectUnselectGroup(rg,e,tp,1,1,nil,1,tp,HINTMSG_RELEASE,nil,nil,true)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST)
	g:Delete()
end

-- Lógica Búsqueda "Dragonic"
function s.thfilter(c)
	return c:IsSetCard(0x872) or c:IsCode(38109772, 78009994, 72549351, 32437102, 13035077, 71817640) -- Códigos de cartas "Dragonic" existentes o futuras
		or (c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSetCard(0x872)) -- Espacio para tus propias Dragonic
end
-- Filtro por nombre (Soporta cartas con "Dragonic" en el nombre)
function s.dragonic_filter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand() 
		and (c:IsSetCard(0x872) or c:IsCode(72549351)) -- Dragonic Tactics, etc.
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.dragonic_filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.dragonic_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Lógica Protección
function s.protcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsAbleToGrave,1,1,REASON_COST)
end
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Protección
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.prottg)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	Duel.RegisterEffect(e2,tp)
	
	-- Doble Ataque
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
		e3:SetValue(1)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e3)
	end
end
function s.prottg(e,c)
	local n=c:GetCode(0x871)
	return (n==49933851 or n==49933852 or n==49933853 or n==49933854 or n==49933855 or n==49933856 or n==49933857 or n==49933858 or n==49933859 or n==49933860) -- Strike Dragons
		or (c:IsType(TYPE_FUSION) and c:IsRace(RACE_DRAGON)) -- Dragon Fusion
end