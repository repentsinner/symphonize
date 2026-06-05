---
argument-hint: [bug, feature, or general feedback]
description: Submit feedback or report a bug to the symphonize project
---

## Responsibility

`/feedback` helps the user submit structured feedback to the
symphonize project. It interviews the user briefly, drafts a
GitHub issue, and opens it in the browser for review before
submission.

The issue targets `repentsinner/symphonize`, not the user's
project repo.

## Steps

1. **Classify.** Ask the user what kind of feedback:
   - **Bug** — something broken or unexpected
   - **Feature request** — something missing or desired
   - **General feedback** — workflow friction, documentation gaps,
     suggestions

2. **Gather context.** Based on the type:

   **Bug:**
   - What happened?
   - What did you expect to happen?
   - What command were you running? (`/discover`, `/plan`,
     `/roadmap`, `/next`, `/orchestrate`, `/review`)
   - Can you reproduce it?
   - What project type? (application, library, CLI, etc.)

   **Feature request:**
   - What problem would this solve?
   - What does your current workaround look like?
   - Which part of the pipeline does this affect?

   **General feedback:**
   - What's working well?
   - What's not working well?
   - What surprised you?

3. **Draft the issue.** Write a title and body using the
   appropriate template:

   **Bug:**
   ```markdown
   ## What happened
   <description>

   ## Expected behavior
   <description>

   ## Steps to reproduce
   1. Run `/symphonize:<command>`
   2. ...

   ## Context
   - Project type: <type>
   - Pipeline stage: <command>
   ```

   **Feature request:**
   ```markdown
   ## Problem
   <what's missing or painful>

   ## Proposed solution
   <what the user wants>

   ## Current workaround
   <how they cope today>

   ## Pipeline stage
   <which command(s) this affects>
   ```

   **General feedback:**
   ```markdown
   ## Feedback
   <description>

   ## Pipeline stage
   <which command(s) this relates to>
   ```

4. **Show the draft to the user.** Let them review and edit
   before submission.

5. **Open in browser.** Use `gh issue create --web` to open the
   issue form pre-filled in the user's browser:

   ```bash
   gh issue create \
     --repo repentsinner/symphonize \
     --title "<title>" \
     --body "<body>" \
     --label "<bug|enhancement|feedback>" \
     --web
   ```

   The `--web` flag opens the browser with the form pre-filled.
   The user reviews, edits if needed, and submits. No issue is
   created without the user clicking "Submit."

## What /feedback does NOT do

- Does not create issues without user review — `--web` always
  opens the browser first
- Does not include sensitive project details unless the user
  explicitly provides them
- Does not attach code, logs, or file contents automatically

The user's input is: $1
