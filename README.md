# 🤖 Hermes Agent 24/7 no Render

Deploy do **Hermes Agent** no Render Free com **Telegram**
rodando **24 horas por dia, 7 dias por semana** — sem nunca hibernar.

## 🧠 Como funciona

Render Free hiberna após **15 minutos de inatividade**. A solução:

1. Um **servidor de saúde minimalista** (`render-health.py`) roda junto com o gateway
2. Ele responde `ok | uptime: Xh Ym Zs` no endpoint `GET /`
3. O **Google Apps Script** pinga esse endpoint a cada 5 minutos
4. Render nunca detecta inatividade → **nunca hiberna** 🚀

```
  Google Apps Script ──ping a cada 5min──▶ Render (health:10000)
                                               ├── Health Server (ok + uptime)
                                               └── Hermes Gateway (Telegram)
```

---

## 📦 Passo 1: Criar repositório no GitHub

1. Acesse **https://github.com/new**
2. Nome: `hermes-render` (ou qualquer nome)
3. Marque **Public** ou **Private** (tanto faz)
4. Clique **Create repository**
5. Na página seguinte, você vai ver comandos como:

```bash
git remote add origin https://github.com/SEU_USUARIO/hermes-render.git
```

**Não precisa rodar esses comandos agora** — só deixe essa página aberta.

---

## 📁 Passo 2: Fazer upload dos arquivos

Ainda na página do repositório vazio no GitHub:

1. Clique em **"uploading an existing file"** (no meio da página)
2. Arraste os arquivos abaixo (criados na sua máquina):
   - `Dockerfile`
   - `render-health.py`
   - `render.yaml`
   - `docker/entrypoint.sh`

   **Pra achar os arquivos no Windows:**

   ```
   C:\Users\keila\Mateus\render-hermes\
   ├── Dockerfile
   ├── render-health.py
   ├── render.yaml
   ├── test_health.py
   └── docker/
       └── entrypoint.sh
   ```

3. Role pra baixo, escreva uma mensagem tipo "Initial commit"
4. Clique **Commit changes**

---

## ☁️ Passo 3: Deploy no Render

1. Acesse **https://dashboard.render.com**
2. Clique **New +** → **Blueprint**
3. Conecte com GitHub e selecione o repo `hermes-render`
4. O Render vai ler o `render.yaml` automaticamente

**Antes de deploy, configure as variáveis de ambiente:**

| Variável | Onde pegar | Obrigatório |
|----------|-----------|-------------|
| `OPENCODE_ZEN_API_KEY` | https://opencode.ai (OpenCode Zen) | ✅ |
| `TELEGRAM_BOT_TOKEN` | @BotFather no Telegram | ✅ |
| `TELEGRAM_WEBHOOK_URL` | `https://SEU-APP.onrender.com` | ✅ (cloud) |

> ⚠️ **WhatsApp foi removido** — o deploy agora funciona só com Telegram.

No Render Dashboard → Environment 📝, clique **Add Secret File** e cole:

```env
OPENCODE_ZEN_API_KEY=sk-or-...
TELEGRAM_BOT_TOKEN=8261195518:...
TELEGRAM_ALLOWED_USERS=8599666899
TELEGRAM_WEBHOOK_URL=https://seu-app.onrender.com
HERMES_HOME=/opt/data
```

5. **Adicione um Persistent Disk**:
   - Render Dashboard → seu service → **Disks**
   - Clique **Add Disk**
   - Mount path: `/opt/data`
   - Size: **1 GB**
   - Nome: `hermes-data`

6. Clique **Deploy** 🚀

---

## ⏰ Passo 4: Google Apps Script (keep-alive)

Crie um script no Google Apps Script pra pingar o health endpoint:

1. Acesse **https://script.google.com/**
2. Clique **New project**
3. Cole o código abaixo:

```javascript
function pingHealth() {
  // Troque pela URL do seu app no Render
  var url = 'https://SEU-APP.onrender.com/';
  try {
    var response = UrlFetchApp.fetch(url, {muteHttpExceptions: true});
    Logger.log('Status: ' + response.getResponseCode());
    Logger.log('Resposta: ' + response.getContentText());
  } catch (e) {
    Logger.log('Erro: ' + e.toString());
  }
}
```

4. Clique no relógio ⏰ (Triggers) → **Add Trigger**
   - Function: `pingHealth`
   - Time based: **Every 5 minutes**
   - Saiba mais: https://script.google.com/home/projects/.../triggers

5. Teste: clique **Run** (▶️) e veja o log em **Executions**

---

## ✅ Verificando se está funcionando

1. **Health endpoint**: acesse `https://SEU-APP.onrender.com/` no navegador
   - Deve mostrar: `ok | uptime: 0h 5m 23s`
2. **Telegram**: mande `/start` pro seu bot
3. **Render logs**: Dashboard → Logs → veja se está rodando sem erros

---

# ── Solução de problemas ────────────────────────────────────
|
| Problema | Causa | Solução |
|----------|-------|---------|
| Render caiu depois de 15 min | Apps Script não configurado | Configure o trigger a cada 5 min |
| Erro 502 no health endpoint | Health server não subiu | Ver logs do Render |
| Telegram não responde | Webhook URL errada | Confira `TELEGRAM_WEBHOOK_URL` |

---

## 📁 Estrutura do projeto

```
render-hermes/
├── Dockerfile            # Imagem customizada (base: hermes-agent)
├── render-health.py      # Servidor HTTP de saúde (stdlib, 0 dependências)
├── render.yaml           # Blueprint Render (deploy com 1 clique)
├── test_health.py        # Teste local do health server
└── docker/
    └── entrypoint.sh     # Entrypoint modificado (health + gateway + dashboard)
```
