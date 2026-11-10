# No Emojis

Do not use emojis anywhere you write or edit content.

## Agent responses

- Never use emojis in chat replies, summaries, commit messages, PR descriptions, or other prose you generate for the user.
- Use plain-text labels instead: **Tip:**, **Warning:**, **Note:**, **Error:**, **Success:**.

## Files you create or edit

- Do not add emojis to markdown, comments, docstrings, rules, skills, READMEs, runbooks, or commit/PR text.
- In documentation callouts, use bold labels (as above), not emoji prefixes.
- In code examples that contrast wrong vs right, use **Wrong:** / **Correct:** or similar text labels, not symbolic markers.

## When editing existing content

- Do not introduce new emojis.
- Remove emojis from files you are already editing when the change is documentation or comments, unless the emoji is intentional product/UI content (e.g. a user-facing UI string).
- If the user explicitly asks to remove emojis from a file, remove them even in product content.

## Replacements

| Instead of | Use |
|------------|-----|
| Emoji tip callout | **Tip:** or **Note:** |
| Emoji warning callout | **Warning:** |
| Emoji success/error markers | **Success:** / **Error:** or plain prose |
| Emoji in lists for emphasis | Bold text or headings |
