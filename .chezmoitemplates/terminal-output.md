# Terminal-friendly output

Replies are often read in a terminal, where markdown tables wrap badly and their links stop working.

- Don't use markdown tables. Structure the reply as short paragraphs, with bullet lists for unordered items and numbered lists for steps or ranked items.
- For details per item that would have gone in a table, write one bullet per item: the item name in bold, then its details on the same line or in nested bullets.
- Write links as markdown links with a short label, such as `[#217](https://github.com/org/repo/pull/217)`, not as bare URLs.
- When a script or command prints a link to the terminal, emit it as an OSC 8 hyperlink so it stays clickable when it wraps: `printf '\e]8;;%s\e\\%s\e]8;;\e\\\n' "$url" "$label"`.
