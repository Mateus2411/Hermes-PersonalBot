# Multi-Source Course Note Creation

Workflow for when a user provides **multiple independent sources** (video + PDF + website) about the same topic and asks you to learn + store in the vault with structured notes.

## Sources to Expect

| Source | Extraction Method | Pitfalls |
|--------|------------------|----------|
| YouTube video | transcript tool → browser fallback (desc extraction) | No captions on live streams / new uploads |
| PDF | pymupdf → detect image-only → find alternative source | No OCR available, model lacks vision |
| Website (Lovable, Notion, Carrd, etc.) | browser_navigate + snapshot + click accordions | Accordion sections collapse hidden content |
| Google Drive / SendFlow links | browser_navigate to download/view | Links often behind YouTube redirects |

## Workflow

### Phase 1: Parallel Extraction
Start all sources simultaneously — they're independent. Use `mcp_youtube_transcript_get_transcript` for videos, `pymupdf` for PDFs, `browser_navigate` for websites.

**For YouTube (no captions):** Navigate to video page → expand description → extract full redirect URLs via browser_console → follow companion links.

**For PDF (image-only):** Detect with `text_len=0, images>0` → extract embedded images → search for same content via web/companion sites → copy PDF to vault regardless.

**For websites:** Click all accordion/collapse buttons before the full snapshot.

### Phase 2: Content Synthesis
Cross-reference content across sources to avoid duplication:
- Video description often lists the same tools/exercises as the companion website
- The PDF title often matches the course name — use web search to find an online-equivalent page
- Compensate for failed sources by deepening extraction from working ones

## Phase 3: Vault Note Structure

Dual-layer pattern — light notes in `Cursos/` with materials, deep notes in `knowledge/`:

### Standalone Guides Within a Course

When the user shares a **standalone external guide** (e.g., a Lovable app page, a companion site with a self-contained framework), create a dedicated study note inside the corresponding course module folder:

```
Cursos/{course-slug}/{module}/solucionador-problemas.md
```

This note should:
- 📝 Have full frontmatter (date, source URL, status, tags, title)
- 📖 Contain the extracted framework/methodology in structured form (tables, numbered steps, blockquotes)
- 💭 Include a personal reflection section (`Minha Reflexão`) analyzing whether the concepts make sense and whether you'll apply them
- 🔗 Cross-link back to the module INDEX.md and the course INDEX.md
- 🏷️ Get a unique tag for the guide (`#solucionador-problemas`)

### Standard Module Structure
Cursos/{course-slug}/
├── INDEX.md                       # Course overview: progress bar, aula schedule, links
├── 01-module-topic/
│   ├── INDEX.md                   # Module note: summary, tools, materials list
│   └── materiais/                 # PDFs, XLSX, DOCX, MP4, PPTX
├── 02-module-topic/
│   ├── INDEX.md
│   └── materiais/
├── presentes/                     # Bonus/gift materials from instructor
└── compartilhados/                # Cross-module resources

knowledge/{course-slug}/
├── Curso {Course Name}.md         # Index note (may overlap with Cursos/ INDEX.md)
├── Aula 01 - Topic Subtitle.md    # Per-class deep study notes
├── Aula 02 - Topic Subtitle.md
└── Guia de {Topic}.md            # Complementary guides
```

Each note should have:
1. **YAML frontmatter** with: `date`, `tags` (including source platform, domain), `status`, and source-specific metadata (`instrutor`, `version`, etc.)
2. **Heading hierarchy**: H1 = Title of the note. H2 = Major sections. H3 = Subsections.
3. **Cross-links**: Use `[[wikilinks]]` between related notes. The index note links to all children.
4. **Code blocks** (```) for prompts, commands, or structured data
5. **Tables** for comparative data (class schedules, tool comparisons)
6. **Blockquotes** for quoted prompts or instructions
7. **External links** as plain markdown links with descriptive text
8. **Progress bars** for course status: `▓▓▓▓░░░░░░  40%  (2/4 aulas)`
9. **Status badges**: ✅ completo, 🔴 pendente, ⏳ futura, 📝 rascunho
10. **Checklists**: `- [x]` for completed items, `- [ ]` for pending
11. **Material Extra section**: At the bottom of each aula INDEX.md, a `## 🔗 Links Úteis` or `## 📚 Material Extra` section listing:
    - External URLs (companion sites, resumo pages, guide pages)
    - Internal wiki-links to related knowledge notes
    - Links to standalone guide notes (e.g., `solucionador-problemas.md`)

### Phase 4: Git Commit

After ALL notes are written, do a single `git add` + `git commit`:
```bash
git add -A
git commit -m "Adiciona notas IA Express Aula 02 — prompts, ferramentas e guia solucionador"
```
Use descriptive messages in Portuguese. Be specific about scope rather than generic "update vault".

## Pitfalls

- **Wiki-link alias inside markdown tables**: `[[file.pdf|alias]]` inside `| col1 | col2 |` breaks the table because `|` is both the wiki-link separator and the table column delimiter. Avoid aliases inside table cells, or write tables without aliases and add them afterward with `patch`.
- **YouTube transcripts unavailable for live streams**: New/recent live streams may not have captions. Companion sites and material PDFs are the fallback sources.
- **Accordion content**: Lovable and similar sites often collapse content behind accordion sections. Click them before taking the full `browser_snapshot`.

## Vault Conventions (this user)

- Language: Portuguese (Brazilian) for all note content
- Course INDEX.md goes under `Cursos/{course-slug}/`, deep notes under `knowledge/{course-slug}/`
- Index notes use `Curso {Name}.md` naming in knowledge/, `INDEX.md` in Cursos/
- Tags are lowercase, hyphenated, consistent within a course
- Content from external tools/companion sites is fully quoted/cited with source URLs
- PDF and media materials are copied into `Cursos/{course-slug}/{module}/materiais/`
- Presentes (gifts/bonus) go in `Cursos/{course-slug}/presentes/`
- Use emojis for visual hierarchy: 📚🎯🛠️✅🔴⏳📊📝🎁
- Frontmatter always includes: date, status (completo/pendente/futura), tags, title, instrutor
- After any vault changes, commit to git with descriptive message
