# SIGAA / JSF Portal Download Workaround

SIGAA (and other Java Server Faces-based educational portals) use JSF forms with `jsfcljs()` JavaScript function for file downloads. Simple link clicks open `_blank` tabs that browser tools can't capture.

## Symptoms

- PDF links have `href="#"` with JSF `onclick` handlers
- Clicking opens a new tab/window (`_blank`) — download isn't captured
- Direct URL to PDF doesn't exist; it's a form POST to `/sigaa/ava/index.jsf`

## Workaround — Fetch with Session Cookies

### Step 1: Get session cookies from browser

```javascript
// In browser_console
document.cookie
// Returns: "JSESSIONID=XXXX.homologacao01; SERVERID=sigaa01"
```

### Step 2: Extract form parameters from onclick handler

Each link's onclick contains:
```
jsfcljs(document.getElementById('formAva'), {
  'formAva:button_param': 'formAva:button_param',
  'id': 'FILE_ID_HEX'
}, '_blank');
```

The parameters needed:
- **formAva**: static form name (always)
- **formAva:idTopicoSelecionado**: "0" (static)
- **javax.faces.ViewState**: "j_id2" (sometimes dynamic, but often static for file downloads)
- **button param**: the JSF command link parameter (unique per file)
- **id**: the file's hex ID (unique per file)

### Step 3: Download with curl

```bash
curl -s -o "output.pdf" \
  -b "JSESSIONID=XXXX.homologacao01; SERVERID=sigaa01" \
  -X POST \
  -d "formAva=formAva&formAva:idTopicoSelecionado=0&javax.faces.ViewState=j_id2&${BUTTON_PARAM}=${BUTTON_PARAM}&id=${FILE_ID}" \
  "https://sig.ifc.edu.br/sigaa/ava/index.jsf"
```

Or in bulk with Python's `subprocess.run()` and `curl`.

### Step 4: Verify

Check HTTP status (should be 200) and file size (>0 bytes). The response content-type should be `application/pdf`.

## JSF Form Structure

```
<form id="formAva" method="post" action="/sigaa/ava/index.jsf">
  <input type="hidden" name="formAva" value="formAva">
  <input type="hidden" name="formAva:idTopicoSelecionado" value="0">
  <input type="hidden" name="javax.faces.ViewState" value="j_id2">
  ...
  <a href="#" onclick="jsfcljs(f, {button_param, 'id':'FILE_ID'}, '_blank')">Nome do Arquivo</a>
  ...
</form>
```

## Notes

- The `jsfcljs` function sets `form.target = '_blank'` before submit — this is why clicks open new tabs
- Modifying the onclick to use `'_self'` before clicking can work in browser_console
- The `javax.faces.ViewState` value may be different across sessions; always check the current form state
- SERVERID cookie seems optional but include it to be safe
- The `formAva` hidden field with its own name is a JSF requirement (JSF 2.x)
