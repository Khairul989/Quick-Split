# Receipt Split Lite --- Complete Project Plan

## Phase 0: Preparation

-   Define core objective: fast bill splitting within 30--40 seconds.
-   Choose tech stack: Flutter + Riverpod + ML Kit + Hive.
-   Initialize repository and project structure.
-   Create CLAUDE.md for automated code generation support.

------------------------------------------------------------------------

## Phase 1: Core Foundations (Week 1)

### 1. Flutter Project Setup

-   Create Flutter project
-   Add core dependencies:
    -   `google_mlkit_text_recognition`
    -   `camera`
    -   `image_picker`
    -   `riverpod`, `hooks_riverpod`
    -   `go_router`
    -   `hive`, `hive_flutter`
    -   `share_plus`

### 2. Base Architecture

-   Implement folder structure:

```{=html}
<!-- -->
```
    lib/
      core/
        utils/
        widgets/
        services/
        error/
        theme/
      features/
        scan/
        ocr/
        items/
        assign/
        groups/
        history/

-   Set up Riverpod providers.
-   Set up GoRouter navigation.

------------------------------------------------------------------------

## Phase 2: OCR Pipeline (Week 2)

### 1. Image Input

-   Implement camera capture.
-   Implement gallery import.
-   Add loading state for image → OCR.

### 2. OCR Processing

-   Integrate ML Kit text recognition.
-   Extract full text blocks.
-   Parse into structured item lines:
    -   Item name
    -   Quantity
    -   Price

### 3. Item Editor

-   UI to edit item names.
-   Add/remove item rows.
-   Validate numeric input.

------------------------------------------------------------------------

## Phase 3: Assignment Engine (Week 3)

### 1. People Management

-   Create "Add Person" UI.
-   Allow editing name + emoji.
-   Implement "Frequent Groups" saved in Hive.

### 2. Assign Items

-   Tap item → choose person.
-   Multiple people per item.
-   Auto split shared items.

### 3. Calculator Logic

-   Per-person subtotal.
-   Shared item distribution.
-   Tax & service charge detection:
    -   SST
    -   Service Charge
    -   Rounding Adjustment

------------------------------------------------------------------------

## Phase 4: Export & Share (Week 4)

### 1. Summary Screen

-   Per-person total breakdown.
-   Receipt info (optional).

### 2. Share Options

-   WhatsApp formatted text:

```{=html}
<!-- -->
```
    Dinner Bill 🍽️
    Total: RM 122.70

    Khairul: RM 28.40
    Aiman: RM 41.30
    Syafiq: RM 53.00

    Pay Khairul:
    https://pay.duitnow.com/XXXXXX

-   Copy to clipboard.
-   Optional: save summary entry to history.

### 3. History Feature

-   Save recent splits (Hive).
-   View previous sessions.

------------------------------------------------------------------------

## Phase 5: Polishing & UX (Week 5)

-   Add dark mode.
-   Add animations + transitions.
-   Empty states for each module.
-   Implement fast flow:
    -   Scan → OCR → Assign → Share

Ensure whole flow ≤ 40 seconds.

------------------------------------------------------------------------

## Phase 6: Growth Mechanics (Week 6)

### 1. "Copy My Split" Link (Optional)

-   Generate encoded session JSON.
-   Open via universal link → reconstruct session.
-   Use Cloudflare Workers for lightweight API.

### 2. Group Templates

-   Save item templates per group.

------------------------------------------------------------------------

## Phase 7: Future Expansion

### A. Cloud Sync

-   Move user data to Supabase.
-   Enable multi-device sync.

### B. AI OCR Correction

-   Improve parsing using OpenAI/Gemini.

### C. Web App Version

-   Flutter Web or Next.js frontend.

------------------------------------------------------------------------

# Final Deliverables

-   Completed Flutter MVP app.
-   Clean modular architecture.
-   Offline-first functionality.
-   Extendable foundation for future AI & cloud features.
