# SIGAA JSF Download Recipe

Reproduction of the exact technique used on **IFC SIGAA** (https://sig.ifc.edu.br/sigaa/) to download PDF files behind JSF `<a>` links.

## Context

SIGAA uses JSF with `h:commandLink` components. The rendered HTML has:
- `<a href="#" onclick="jsfcljs(...)">` — no direct URL
- `jsfcljs()` submits `formAva` via POST, opens response in `_blank`
- Form action: `https://sig.ifc.edu.br/sigaa/ava/index.jsf`
- Form method: POST, enctype: `application/x-www-form-urlencoded`

## Exact curl Command Template

### Get the form's hidden fields

```js
// Run in browser_console
const f = document.getElementById('formAva');
const inputs = f.querySelectorAll('input');
[...inputs].map(i => ({name: i.name, value: i.value, type: i.type}));
```

Typical values:
- `formAva` = `formAva` (the form component ID)
- `formAva:idTopicoSelecionado` = `0`
- `javax.faces.ViewState` = `j_id2` (varies)

### Get button param and file ID from onclick

Example onclick:
```
jsfcljs(document.getElementById('formAva'),{
  'formAva:j_id_jsp_1236623656_323:1:listaMateriais:1:j_id_jsp_1236623656_386':
  'formAva:j_id_jsp_1236623656_323:1:listaMateriais:1:j_id_jsp_1236623656_386',
  'id':'C85DEA539EC8D648DC2E8EDBB7EF140092A6E674'
},'_blank');
```

Button param = `formAva:j_id_jsp_1236623656_323:1:listaMateriais:1:j_id_jsp_1236623656_386`
File ID = `C85DEA539EC8D648DC2E8EDBB7EF140092A6E674`

### Execute download

```bash
curl -s -o "TRIANGULOS_parte_1.pdf" \
  -b "JSESSIONID=28E1153935CCD2D3B9CE53F3FD92256C.homologacao01; SERVERID=sigaa01" \
  -X POST \
  -d "formAva=formAva" \
  -d "formAva%3AidTopicoSelecionado=0" \
  -d "javax.faces.ViewState=j_id2" \
  -d "formAva%3Aj_id_jsp_1236623656_323%3A1%3AlistaMateriais%3A1%3Aj_id_jsp_1236623656_386=formAva%3Aj_id_jsp_1236623656_323%3A1%3AlistaMateriais%3A1%3Aj_id_jsp_1236623656_386" \
  -d "id=C85DEA539EC8D648DC2E8EDBB7EF140092A6E674" \
  "https://sig.ifc.edu.br/sigaa/ava/index.jsf"
```

## Two Download Paths

### Path A — Principal/Aulas View (hash IDs)

Used when clicking file links directly from lesson topics on the "Principal" tab. File IDs are **40-char hex hashes**.

### Path B — Arquivos Tab (numeric IDs)

Used when browsing the "Arquivos" tab under "Materiais". File IDs are **numeric** (e.g., `3394591`). The form action changes to `ava/ArquivoTurma/listar_discente.jsf`.

Key differences from Path A:
- Component IDs use `j_id_jsp_1721837501_309j_id_N` format (vs `listaMateriais:N:j_id_jsp_...`)
- The `javax.faces.ViewState` is different and needs to be extracted from the Arquivos page
- The form action URL is different (check `document.getElementById('formAva').action`)
- All files appear in a flat table (not nested under lessons)

### Extracting All Numeric IDs from the Arquivos Page

```javascript
// Run in browser_console on the Arquivos tab
var allLinks = document.querySelectorAll('a');
var results = [];
for(var i=0; i<allLinks.length; i++) {
    var onclick = allLinks[i].getAttribute('onclick') || '';
    if(onclick.includes("'id'")) {
        var id = onclick.match(/'id':'(\d+)'/);
        if(id) results.push({title: allLinks[i].textContent.trim(), id: id[1], onclick: onclick.substring(0,120)});
    }
}
console.table(results);
```

To get the full list with file names, run:
```javascript
var tables = document.querySelectorAll('table');
var lastTable = tables[tables.length-1];
var rows = lastTable.querySelectorAll('tr');
var files = [];
rows.forEach(row => {
    var cells = row.querySelectorAll('td');
    if(cells.length >= 4) {
        var title = cells[0].textContent.trim();
        var topic = cells[2].textContent.trim();
        var downloadLink = cells[3]?.querySelector('a');
        var onclick = downloadLink?.getAttribute('onclick') || '';
        var idMatch = onclick.match(/'id':'(\d+)'/);
        if(title && idMatch) {
            files.push({title, topic: topic.substring(0,80), id: idMatch[1]});
        }
    }
});
console.table(files);
```

## Python Examples

### Path A — Hash IDs (from Principal/Aulas view)

```python
import requests

cookies = {
    'JSESSIONID': '28E1153935CCD2D3B9CE53F3FD92256C.homologacao01',
    'SERVERID': 'sigaa01',
}

files = [
    ('03 - TRIANGULOS - parte 1',
     'C85DEA539EC8D648DC2E8EDBB7EF140092A6E674',
     'formAva:j_id_jsp_1236623656_323:1:listaMateriais:1:j_id_jsp_1236623656_386'),
    ('04 - TRIANGULOS - parte 2',
     '8F82D4C200E37089176C50E96C62D53E0F08BFCC',
     'formAva:j_id_jsp_1236623656_323:1:listaMateriais:0:j_id_jsp_1236623656_386'),
    ('05 - TRIANGULOS - parte 3',
     'D98A7B1D21136D3AA81792640607B054C82B775E',
     'formAva:j_id_jsp_1236623656_323:5:listaMateriais:0:j_id_jsp_1236623656_386'),
    ('06 - TRIANGULOS - gabarito parte 1',
     'A3CDE4EDD430A6FA755141AD69A87B6A84654489',
     'formAva:j_id_jsp_1236623656_323:7:listaMateriais:0:j_id_jsp_1236623656_386'),
    ('07 - TRIANGULOS - gabarito parte 2',
     'F35A1A2824746DCD983EEC72362804688165CAA8',
     'formAva:j_id_jsp_1236623656_323:7:listaMateriais:1:j_id_jsp_1236623656_386'),
    ('08 - TRIANGULOS - gabarito parte 3',
     '4BC915ACB487F89853AEA465605DB8682ACEDF9A',
     'formAva:j_id_jsp_1236623656_323:7:listaMateriais:2:j_id_jsp_1236623656_386'),
]

url = 'https://sig.ifc.edu.br/sigaa/ava/index.jsf'

for name, file_id, button_param in files:
    data = {
        'formAva': 'formAva',
        'formAva:idTopicoSelecionado': '0',
        'javax.faces.ViewState': 'j_id2',
        button_param: button_param,
        'id': file_id,
    }
    r = requests.post(url, data=data, cookies=cookies)
    fname = f"{name.replace(' ', '_')}.pdf"
    with open(fname, 'wb') as f:
        f.write(r.content)
    print(f'{fname}: {len(r.content)} bytes')
```

### Path B — Numeric IDs (from Arquivos tab)

```python
import requests, re

cookies = {
    'JSESSIONID': '3A90744532C9D593D1B63585BD66E0EF.homologacao01',
    'SERVERID': 'sigaa05',
}

# Step 1: Navigate to the turma virtual
s = requests.Session()
s.cookies.update(cookies)
s.headers['User-Agent'] = 'Mozilla/5.0'

r = s.get('https://sig.ifc.edu.br/sigaa/portais/discente/discente.jsf')
vs1 = re.search(r'javax\.faces\.ViewState[^>]*value="([^"]+)"', r.text).group(1)

data = {
    'formAtualizacoesTurmas': 'formAtualizacoesTurmas',
    'formAtualizacoesTurmas:j_id_jsp_1861693203_364j_id_6': 'formAtualizacoesTurmas:j_id_jsp_1861693203_364j_id_6',
    'idTurma': '73780',
    'javax.faces.ViewState': vs1,
}
r2 = s.post('https://sig.ifc.edu.br/sigaa/portais/discente/discente.jsf', data=data)

# Step 2: Navigate to Arquivos tab (component IDs vary — extract from page)
# The Arquivos link onclick contains a component ID; extract it
arquivos_comp = re.search(r"'formAva:([^']+)'[^>]*>[^<]*Arquivos[^<]*<", r2.text)
# Alternative: find the Arquivos tab by searching for the link text
# The form action may change to ava/ArquivoTurma/listar_discente.jsf

# Step 3: Download individual files
# component_id = 'formAva:j_id_jsp_1721837501_309j_id_N' (extract from onclick)
# file_id = numeric (e.g., '3394591')
# vs2 = current ViewState from the Arquivos page

download_data = {
    'formAva': 'formAva',
    component_id: component_id,  # key and value same
    'id': file_id,
    'javax.faces.ViewState': vs2,
}
r3 = s.post('https://sig.ifc.edu.br/sigaa/ava/ArquivoTurma/listar_discente.jsf',
            data=download_data)

# Check Content-Type — if PDF, save; if HTML, the download format doesn't match
if 'pdf' in r3.headers.get('Content-Type', ''):
    with open(f'{file_id}.pdf', 'wb') as f:
        f.write(r3.content)
```
