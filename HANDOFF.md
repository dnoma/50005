# HANDOFF.md — Second-wave PR playbook (C2–C6, P1–P2)

> **What this is.** A per-PR tactical spec for finishing the OS-weeks-1–8 improvement series. One PR per branch. Read §1–§7 of `AGENT.md` first, then pick the next ◻ row in `AGENT.md §8.2` and open the matching section below.
>
> **What this is not.** A finished draft. Each section below is a *directional spec*, not final prose — the next agent reads the actual chapter (line numbers may have drifted after upstream merges) and adapts.
>
> **Done? Delete this file.** Once C6 + P1 + P2 are merged upstream, this playbook is spent. Drop the file in a `chore(local):` commit on `main` and close the loop in `AGENT.md §8.2`.

---

## Ground rules (read before every PR)

1. **Branch from `upstream/main`**, not `origin/main`. The fork's `main` carries `AGENT.md` + `serve.sh` + `HANDOFF.md`; branching off `origin/main` will drag them into the PR diff. See `AGENT.md §9`.
2. **Verify line numbers.** Every line number below was confirmed against `upstream/main @ b151b9f` on 2026-04-19. Upstream merges will drift them — re-grep for the section heading before editing.
3. **One concern per PR.** If you discover a second issue mid-edit, open a separate branch for it.
4. **Stage → stop → preview.** Do not `git commit` until the user has opened the page in a browser and confirmed the render. `AGENT.md §12` rule 10.
5. **No `Co-Authored-By` trailer. No AI attribution.** `AGENT.md §12` rule 9.
6. **Use theme callouts, never inline `<span style="color:…">`.** Available: `highlight`, `important`, `new`, `info`, `note`, `warning`, `error`, `task`. See `AGENT.md §4`.
7. **Mermaid is available** (`mermaid:` block configured in `_config.yml`). Use ` ```mermaid ` fences for diagrams that would otherwise need an image asset.
8. **Code fences**: label C code `c`, not `cpp`. Mislabelling is a pre-existing bug (see P2).

---

## C2 — Unify the four OS-design diagrams (Ch 04)

- **Branch**: `docs/os-design-unified-diagram`
- **File**: `docs/OS/04-os-design-structure.md`
- **Problem.** Ch 04 presents four OS structure styles — Monolithic (L205), Layered (L232), Microkernel (L262), Hybrid (L285) — each with its own diagram in isolation. A novice sees four disjoint pictures and cannot *compare* them on the axes that matter (where the dual-mode line sits, which components run in kernel mode, how requests flow). The "which one should I pick" intuition never forms.
- **Target insertion point.** A new H2 `## Comparing the Four Structures` inserted **after** the existing Hybrid section (ends around L295) and **before** `## Java Operating System (JX)` (L296). Alternatively a new H3 at the *top* of `# OS Structures` (L199) as a map-of-territory preview — pick whichever reads better on render.
- **Proposed content (~60–90 lines).**
  1. A **single mermaid flowchart or comparison matrix** showing, for each of the four structures, three axes: (a) which components run in kernel mode (below the dual-mode line), (b) how a user request reaches a hardware device, (c) one concrete OS example (MS-DOS / original UNIX / MINIX or L4 / macOS or Windows NT).
  2. A short decision-tree paragraph: *"Pick monolithic for raw speed at the cost of safety; pick microkernel when fault isolation matters more than IPC latency; hybrid is what every mainstream OS ships in practice because neither extreme survives real workloads."*
  3. One callback sentence to the Ch 01 syscall trace (§8.2 C1): *"Regardless of the structure, every user→kernel transition still follows the seven-step trace from Ch 01 — the structures only change what lives on the kernel side of step 4."*
- **Acceptance.** A first-time reader should be able to say, in one sentence, **what changes** between the four structures. Currently they cannot.
- **Non-goals.** Do not rewrite the four existing per-structure sections. Add a comparison layer on top; leave the originals alone.
- **Commit**: `docs(os-design): unify the four OS-structure diagrams into one comparison`

---

## C3 — Traced `fork()` walkthrough + program-vs-process table (Ch 05)

- **Branch**: `docs/os-processes-fork-trace`
- **File**: `docs/OS/05-processes.md`
- **Problem.** Two gaps compound. (a) "Process vs Program" at L47 is prose-only; a side-by-side table would make the distinction stick. (b) `## How fork works` at L287 shows the API but does not *trace* what happens to the PCB — novices cannot picture that `fork()` returns twice because two PCBs now exist.
- **Target insertion points.**
  1. **Before L78** (`### Concurrency and Protection`): insert a small two-column table "Program vs Process" with rows for *storage location, lifetime, uniqueness, resources held, example*.
  2. **Between L327 and L328** (end of `## How fork works`, before `### fork return value`): insert a new subsection `### Tracing fork() — two PCBs, one instruction`.
- **Proposed content for the fork trace (~40–60 lines).** Six numbered steps, ending with the diagram. A minimal example:
  ```c
  pid_t pid = fork();
  printf("Hello from pid=%d\n", getpid());
  ```
  Then:
  1. **Before the call.** One PCB (the parent), one `printf` in its code segment.
  2. **Trap into kernel.** Steps 1–4 of the Ch 01 syscall trace; handler is `sys_fork`.
  3. **Kernel allocates a new PCB.** Copies parent's memory layout (copy-on-write), file descriptors, signal handlers; assigns a new PID.
  4. **Both PCBs are now runnable.** The kernel returns from the syscall **twice** — once into the parent (returning the child's PID), once into the child (returning `0`).
  5. **Schedule is undefined.** Either process may run first — this is the first place in the course where non-determinism shows up. Name-drop the race condition that's coming in Ch 08.
  6. **Two `printf`s will happen** — usually on different cores, possibly interleaved on `stdout`.
  - Include a small **two-PCB diagram** (mermaid or ASCII) showing memory/state duplication at the moment of the second return.
  - Cite back to C1: *"Under the hood, `fork` is still the seven-step syscall from Ch 01; step 4's handler is just unusual in that it returns into two processes."*
- **Acceptance.** A student who has never written `fork()` can draw the two PCBs and predict that the return value differs.
- **Commit**: `docs(os-processes): add program-vs-process table and trace fork()'s dual return`

---

## C4 — Socket primer for `bind` / `listen` / `accept` (Ch 06)

- **Branch**: `docs/os-ipc-socket-primer`
- **File**: `docs/OS/06-ipc.md`
- **Problem.** The socket IPC example at L305 (`## Program: IPC using Socket`) dumps `socket() → bind() → listen() → accept() → recv()` on the reader with no preview. Students who have never touched sockets lose the thread at `listen(backlog)`. The current `## Socket` intro at L242 only explains *what a socket is*, not *how the four syscalls fit together*.
- **Target insertion point.** New subsection `## The Socket Dance: four syscalls, in order` inserted **between L304 (end of "Non-blocking recv and send") and L305 (start of the program)**. Alternatively fold it into the `## Socket` section at L242–286 — pick whichever keeps the "Program" section close to its primer.
- **Proposed content (~50–70 lines).**
  - **One sentence per syscall**, in the order they appear in the example, each with: (a) what it does at the kernel level, (b) what the kernel's socket data structure looks like after the call.
    - `socket()` — creates an unbound endpoint (PCB-adjacent `struct socket` with no address yet).
    - `bind(addr, port)` — glues the endpoint to an IP:port tuple so inbound packets can find it.
    - `listen(backlog)` — flips the socket into passive/server mode; kernel starts queuing pending connections up to `backlog` deep.
    - `accept()` — blocks until a connection reaches the queue, then returns a **new** socket fd for that connection (the listening socket stays live).
    - `recv() / send()` — the existing blocking-behaviour explainer at L286–304 already covers these; link back.
  - **One small diagram** (mermaid) of the listening socket + connection queue + per-connection fds.
  - **Callback** to Ch 01 C1: each of these is a syscall, each follows the seven-step trace.
- **Acceptance.** The program at L305 reads linearly after the primer. The first time a reader sees `accept() returns a new fd`, they understand *why*.
- **Commit**: `docs(os-ipc): add socket primer before the bind/listen/accept example`

---

## C5 — Worked Amdahl's Law example (Ch 07)

- **Branch**: `docs/os-threads-amdahl-worked`
- **File**: `docs/OS/07-threads.md`
- **Problem.** L473 states the Amdahl formula, then immediately asks: *"What is the maximum speedup we can gain when α = 30% and N = ∞?"* with no worked example in between. This is the canonical "theory → exercise with no demo" pattern flagged in `PEDAGOGY_AUDIT.md`.
- **Target insertion point.** Between the formula block (ends around L476) and the `{:.highlight-title}` "Ask yourself" block (L478–480).
- **Proposed content (~25–40 lines).**
  1. **One numeric walkthrough.** Pick α = 0.1 (10% serial) and N = 4, plug in, show arithmetic: `1 / (0.1 + 0.9/4) = 1 / 0.325 ≈ 3.08×` speedup. Contrast with the naïve expectation (4×) — a full cache-miss moment.
  2. **A sensitivity mini-table** — one column of α (1%, 5%, 10%, 25%, 50%), one column of speedup at N=∞ (the theoretical ceiling, = 1/α), one column at N=8 (realistic). Three rows is enough; readers can extend it mentally.
  3. **One-sentence takeaway** about the ceiling: even 5% serialisation caps you at 20× no matter how many cores you add. This is the "why your program doesn't get 100× faster on a 100-core server" moment.
  4. **Leave the existing "Ask yourself" block intact** — it now follows a demo instead of being the first encounter.
- **Acceptance.** A student can compute an Amdahl speedup by hand after reading the section.
- **Commit**: `docs(os-threads): add a worked Amdahl's Law example before the exercise`

---

## C6 — Peterson interleaving diagram + pitfall boxes (Ch 08)

- **Branch**: `docs/os-sync-peterson-trace-pitfalls`
- **File**: `docs/OS/08-synchronization.md`
- **Problem.** Two things in one PR (borderline — split if the diff grows past ~150 lines).
  1. `## Proof of Correctness` at L358 + `### Scenario 1` (L376) + `### Scenario 2` (L384) walk through Peterson's in prose. No state table showing `flag[0]`, `flag[1]`, `turn` evolving. This is the #1 confusion point in Ch 08 per `PEDAGOGY_AUDIT.md`.
  2. Three classic pitfalls are mentioned in passing but not surfaced as landmines: **`volatile` is not a synchronisation primitive** (buried in appendix L937), **`pthread_mutex_t` is not valid across `fork` unless in shared memory** (mentioned without a broken example), **returning a stack pointer from a `pthread_create` thread function** (`07-threads.md:247` — move or mirror the pitfall here since it's genuinely a sync concern).
- **Target insertion points.**
  1. **After L397** (end of Scenario 2 proof): insert an interleaving table showing three scenarios — both threads call `lock(0)` simultaneously; thread 0 tries while thread 1 is already in the CS; both exit cleanly — columns = `flag[0]`, `flag[1]`, `turn`, whose PC is where.
  2. **New H2 `## Common Pitfalls`** at the end of the main body, **before `# Final Note` at L745**. Three sub-sections, each with a callout-wrapped broken example + one-line fix:
     - `### volatile is not a lock` — code that "works" on -O0 and breaks on -O2.
     - `### Mutexes do not cross fork() by default` — parent holds lock → forks → child inherits a confused lock.
     - `### Never return stack pointers from a thread` — `char buf[32]; ... return buf;` classic.
- **Proposed content size.** Interleaving table ~30 lines, pitfalls ~60 lines. Keep it tight — each pitfall is a warning callout + minimal code + one-line fix, not an essay.
- **Acceptance.** After C6, the single rhetorical `?` that was fixed by `docs/os-sync-spurious-wakeup` is joined by three more named-and-taught landmines. A student reading the chapter cover-to-cover walks away knowing what *not* to write.
- **Commit**: `docs(os-sync): add Peterson interleaving table and common-pitfalls section`
- **If the diff balloons**: split into `docs(os-sync): add Peterson interleaving table` + `docs(os-sync): surface volatile/fork/pthread pitfalls`.

---

## P1 — Inline `<span style="color:…">` → theme callouts (Ch 01–08)

- **Branch**: `chore/os-spans-to-callouts`
- **Files**: `docs/OS/01-os-intro.md` through `docs/OS/08-synchronization.md`
- **Scope**. `rg 'style="color:' docs/OS/0[1-8]*.md | wc -l` returned **697 matches** at the time of writing. Most are `<span style="color:#f77729;"><b>word</b></span>` (amber emphasis) and `<span style="color:#f7007f;"><b>word</b></span>` (pink strong-emphasis). A smaller set wrap entire sentences in red for "careful" callouts — those should become `{:.warning}` or `{:.error}` blocks.
- **Approach.**
  1. **Two passes.** First pass: mechanical — single-word `<span>…<b>X</b></span>` → `**X**`. This is ~80% of the spans and can be done with a scripted regex. Second pass: judgment — sentence-wrapping spans that actually convey *caution* or *importance* become proper callout blocks (`{:.warning}`, `{:.important}`, `{:.info}`).
  2. **Accessibility gain**: colour is lost to screen readers; `<strong>` and callouts are not. This is the real motivation — stated in the commit body.
  3. **Do not touch semantics**. If a span was used for emphasis, it stays emphasis. If it was used as a pseudo-callout, it becomes a real callout.
- **Sanity check before commit.** `./serve.sh` and click every page 01–08; the page colour palette should look *quieter* (theme's default emphasis) but the information hierarchy should be intact.
- **Risk.** This is the biggest diff in the series (could be 500+ lines). The prof may push back on aesthetic changes. Mitigation: open one PR per chapter (8 PRs) rather than one mega-PR, so each is reviewable in a sitting.
- **Alternative scoping** if 8 PRs feels like too much churn: do it **one chapter at a time, ad-hoc**, bundled into each content PR (C1 already skipped this — follow the "new content uses callouts; old content gets migrated opportunistically" pattern).
- **Commit (per chapter)**: `chore(os-NN): migrate inline color spans to theme callouts`

---

## P2 — Correct code-fence language labels (Ch 01–08)

- **Branch**: `fix/os-code-fence-langs`
- **Files**: ch 01–08 (any file with ` ```cpp ` that contains C, or ` ```c ` that actually contains C++).
- **Scope**. Small. `rg -n '^```cpp' docs/OS/0[1-8]*.md` lists candidates; inspect each — if the block uses only `#include <stdio.h>`, `printf`, `fork`, `pipe`, `sem_t`, it's C. If it uses `std::`, `class`, `template`, it's C++.
- **Fix**. Flip the language tag. No other content changes.
- **Acceptance**. Rouge highlighting matches the code; the distinction matters because C++ keyword highlighting paints `new` / `delete` / `class` incorrectly in C blocks.
- **Commit**: `fix(os): correct cpp->c code-fence labels where C is shown`

---

## Suggested execution order

**Content first, polish last:**

```
C1 ✅ → C2 → C3 → C5 → C4 → C6 → P2 → P1
```

Why that order:
- **C2 → C3 → C5** lift the "no mental model" complaint across Ch 04, 05, 07 — the three chapters where a single diagram or worked example has the highest payoff-per-line.
- **C4** (Ch 06 IPC) is slotted fourth because the socket chapter depends less on novice scaffolding than on mechanical explanation; the primer is valuable but not urgent.
- **C6** goes after because Ch 08 is the longest chapter; save the biggest cognitive load for when the novice already has the Ch 01 C1 mental model locked in.
- **P2** is last-minute polish — trivial, hand it in as a palate-cleanser PR between larger ones.
- **P1** is last because it's invasive, aesthetic, and the prof may want to batch-review. Save political capital for it.

**Deferred (post-C6):**
- **S1** — `docs/OS/glossary.md`. ~40 recurring terms with back-links. Pitch only if C1–C6 have all merged and the prof signals appetite for cross-cutting additions.
- **S3** — standard "Before you start" + "Self-check" blocks per chapter. Same gate.

---

## Progress ledger

Mark ✅ here *and* in `AGENT.md §8.2` when each PR merges upstream. When all ✅: delete this file.

- [x] **C1** — `docs/os-intro-syscall-trace` · commit `56b7454` · **PR open, awaiting review**
- [ ] **C2** — `docs/os-design-unified-diagram`
- [ ] **C3** — `docs/os-processes-fork-trace`
- [ ] **C4** — `docs/os-ipc-socket-primer`
- [ ] **C5** — `docs/os-threads-amdahl-worked`
- [ ] **C6** — `docs/os-sync-peterson-trace-pitfalls`
- [ ] **P1** — `chore/os-spans-to-callouts` (per-chapter, 8 sub-PRs)
- [ ] **P2** — `fix/os-code-fence-langs`

---

*Line numbers verified against `upstream/main @ b151b9f` on 2026-04-19. Re-grep section headings before editing; upstream merges will shift line numbers by a few.*
