# new

Records one decision. Run the steps in order. When the request already answers a step, use that answer and move on.

## Topic

One sentence naming the decision, from the invocation or the request. Ask for it only if neither gives one.

## Discussion

A conversation, not a form. Find out:

- the problem, and what forces a decision now
- the cost of not deciding
- the options considered, and why each one loses
- constraints: deadlines, compliance, team skills, contracts already in place

Ask for everything missing in one message. If only one option is given, the two-option check will fail later, so ask now what else was considered, even if dismissed quickly (doing nothing, keeping the current approach, a managed service, building it in-house).

## Recon

Keep it light:

- `ARCHITECTURE.md`: the components and flows the decision touches.
- Existing records: titles, decisions and `terms` that overlap. If an Accepted record already decides this, say so and offer `supersede` or a `related` link instead of a second record on the same question.
- Three to seven source files the decision touches (search for the components, endpoints or settings named). Cite only paths that exist. If the code contradicts what the user said, raise it.

## Worth-an-ADR check

Apply the rule in SKILL.md before drafting. If it fails, push back and ask before going further.

## Draft

- **Number:** the highest number in the register plus one, counting records in other formats. Keep the register's zero padding, four digits by default.
- **Filename and frontmatter:** [template.md](template.md). Status Draft, or Proposed if the user says it is ready for review.
- **`authors`:** `git config user.name`, unless the user names others. If it returns nothing, leave the list empty and say so.
- **`date`:** today.
- **Context:** the problem, the forces and constraints, with cited paths and ADRs. A superseding record says what changed since the old decision and links to it; it does not restate it.
- **Options considered:** every option, the chosen one included, each argued fairly with why it was chosen or rejected. Add a comparison table when there are three or more options with trade-offs on several axes.
- **Decision:** one declarative paragraph, starting "We will".
- **Consequences:** positive and negative. Known gaps only when delivery is staged.
- **References:** related ADRs, source files, external documents.
- **Terms:** each term the decision introduces or redefines, with a one-sentence definition. Skip ordinary words and terms already defined the same way elsewhere; keep redefinitions.

If the request says the decision is already taken and should be recorded as accepted, finish `new`, then run `accept` in the same session.

## Combined review

One message with: the filename and title, the status, the full draft, the terms, the worth-an-ADR result, and the results of the checks before save (SKILL.md). Ask for approval or edits. After an edit, show only what changed. With pre-approval (SKILL.md), skip the wait and list the choices taken.

## Save

Write the record. Add its row to the index, creating the index if missing ([template.md](template.md)). Report as SKILL.md says.
