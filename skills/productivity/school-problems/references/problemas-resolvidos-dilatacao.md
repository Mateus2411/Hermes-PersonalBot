# Problemas Resolvidos — Dilatação Térmica (T1 - 2INFO1)

> **Fonte:** T1 de Física — Prof. Élder Mantovani  
> **Sessão:** 14/05/2026  
> **Aluno:** keila (2INFO1)

---

## Questão 7 — Concorde (Dilatação Linear)

**Dados:**
- Material: Alumínio → α = 2,4 × 10⁻⁵ °C⁻¹
- L₀ = 61,80 m
- T₀ = 17 °C
- ΔL = 233 mm = 0,233 m

**Resolução:**
```
ΔL = L₀ · α · ΔT
0,233 = 61,80 × 2,4×10⁻⁵ × ΔT
ΔT = 0,233 / (61,80 × 2,4×10⁻⁵)
ΔT = 0,233 / 0,0014832
ΔT = 157,09 °C

T = T₀ + ΔT
T = 17 + 157,09
T = 174,09 °C ✅
```

---

## Questão 9 — Chapa de Latão (Dilatação Superficial)

**Dados:**
- Material: Latão → α = 2,0 × 10⁻⁵ °C⁻¹ → β = 2α = 4,0 × 10⁻⁵ °C⁻¹
- A₀ = 1,60 m²
- A = 1,56 m²
- T_f = 12 °C
- Procurando: T_i

**Resolução (com sinal negativo!):**
```
ΔA = A − A₀
ΔA = 1,56 − 1,60
ΔA = −0,04 m²   ← negativo porque está resfriando

ΔA = A₀ · β · ΔT
−0,04 = 1,60 × 4,0×10⁻⁵ × (12 − T_i)
−0,04 = 6,4×10⁻⁵ × (12 − T_i)
(12 − T_i) = −0,04 / 6,4×10⁻⁵
(12 − T_i) = −625

12 − T_i = −625
−T_i = −625 − 12   ← 12 passa subtraindo
−T_i = −637
T_i = 637 °C        ← ×(−1) nos dois lados ✅
```

---

## Questão 10 — Cubo + Gráfico (Dilatação Volumétrica)

**Dados:**
- Aresta do cubo = 110 mm = 11 cm
- V₀ = 11³ = 1331 cm³ = 1331 mL
- T₀ = 25 °C
- V desejado = 1380 mL
- ΔV = 1380 − 1331 = 49 mL

**Fórmula geral:**
```
ΔV = V₀ · γ · ΔT
γ = 3α
β = 2α

T = T₀ + ΔV / (V₀ · γ)
```

**Resposta do gabarito:** T ≅ 270,43 °C

> Nota: O β é obtido do gráfico de ΔA × T da chapa (mesmo material). A inclinação da reta dá A₀·β. Com β, calcula-se γ = 3β/2, e então T.

---

## Dicas para o Trabalho (do PDF)

- Mostrar TODOS os cálculos — incompletos são desconsiderados
- Incluir unidades em cada passo
- Erro de unidade → −30% do valor do exercício
- Trabalho INDIVIDUAL — cópia/plágio anula
- Entrega presencial na data combinada

## Tabela de Coeficientes (Tabela 1 do PDF)

| Material | α (×10⁻⁵ °C⁻¹) |
|----------|-----------------|
| Aço | 1,1 |
| Alumínio | 2,4 |
| Chumbo | 2,9 |
| Cobre | 1,7 |
| Ferro | 1,2 |
| Latão | 2,0 |
| Ouro | 1,4 |
| Prata | 1,9 |
| Vidro comum | 0,9 |
| Vidro refratário | 0,3 |
