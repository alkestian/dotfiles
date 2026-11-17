---
name: pr-message
description: Write and post PR messages on the user's behalf, with the `🤖 [C.A.M]` prefix, the Claude-assisted footer and the user's tone. Use when the user says "reply to X's comment", "respond on the PR", "draft replies", "answer the review", "post that comment", or asks to post a review comment, review body or conversation comment. Also the one place the review-pr skill gets its comment text from.
---

# PR message

One voice for everything Claude posts on a PR for the user: replies to reviewers, inline review comments, review bodies and conversation comments. Other skills (review-pr) supply the content and call this one for the wording and posting.

## Rules

1. **Prefix.** Every message starts with `🤖 [C.A.M] ` (one space after). No exceptions, including thread replies and replies that only link to another reply.
2. **Footer.** Standalone messages (a review body, a PR conversation comment) end with `<sub>🤖 Claude Assisted Message · Cam reviewed</sub>` after a blank line. It spells out what the `C.A.M` in the prefix stands for, so keep "Claude Assisted Message" in full and do not add "C.A.M =". The user asked for the message, so it counts as Cam reviewed. Inline comments and thread replies get the prefix only. No other marker, and none on the in-session report.
3. **Explicit approval, always.** Never submit anything to GitHub (reply, comment, inline comment, review body, approval, changes-requested, or a pending review) without the user's explicit approval of that specific text. Show drafts in chat first (inline comments as file:line plus body), then wait. An earlier instruction such as "approve it" or "reply to that" asks for a draft; it is not approval of text the user has not seen. Approval is the user saying to post the shown draft, or giving edited text. Silence, a related question or approval of a different message is not approval. When unsure, ask. Never post unasked.
   - **Post edited text exactly.** The user's quote is the whole message, not a patch to the draft: drop anything they left out and add nothing of mine other than the prefix and footer. If it is unclear whether a quote is the whole message or one part, ask before posting. After posting, fetch the comment and compare it to the approved text.
4. **Review state.** Never resolve a thread, and never submit an approval or a changes-requested review unless the user says so for that PR, in addition to rule 3. Without that, post approved inline comments as a pending review, or as a comment-only review if the user asked to post them.
5. **Draft with Haiku.** Dispatch one Agent (`subagent_type: general-purpose`, `model: haiku`) for all drafts in a batch. Give it, per message: what it answers or flags (the comment being replied to, or file:line and the claim), the evidence checked, what was decided or changed (with the short SHA), the kind of message, and the Tone and Kinds rules below verbatim. It returns text only. Then check every claim in the text against the evidence, strip what it does not support, add the prefix and footer, run the lint below, and show it in chat. Skip the agent when the user supplies the wording.
6. **Push first.** If a reply says a fix is done, push the commit before posting and cite the short SHA.
7. **Verify claims.** State only what was checked. Numbers read off a graph are "about". Do not promise follow-ups (such as "will confirm after deploy") unless the user says to. Do not mention other repos needing updates unless the PR could break them.

## Tone

A guideline, not a rule: adapt it to the message, and follow the user's wording if they ask for something different.

- 1 to 3 sentences, plain and conversational. Lead with the answer or the point, with the reason attached: "Good point, ...", "Agreed on ...".
- No "Thanks for the review", "Great catch", sign-offs or filler. A short "Thanks, agreed on X" is fine when it carries the answer.
- Say what changed and where (commit SHA), or what was decided and why. Prefer "I think" and "we" to "you should"; use "we" for team decisions ("Think we should keep X for now").
- Identifiers in backticks. Ticket keys as links. No customer data, tokens or secrets.
- No em or en dashes, bullets, bold, headings or severity tags.
- When `ledger:writing` is available, follow its guidelines and run its lint (`lint.sh`) on the text before showing it.

## Kinds

- **Reply to a thread or comment.** As above. Answer the question first.
- **Inline review comment.** On the relevant line, never folded into one summary comment. Prefix minor points with `nit:` and say when non-blocking. When unverified, say what you do and don't know and ask, with the evidence you checked ("I'm not super familiar, but are these…?"). When the fix is known, offer it as an option, and use a GitHub `suggestion` block for a one-line fix.
- **Review body.** One to three sentences: what the PR does, then the verdict ("Makes sense to me", "Looks good"). Name any non-blocking points. When approving against a ticket, say briefly how the PR meets its criteria.
- **Conversation comment.** Start with `@login` for the person answered, since nobody else gets notified.

## Several reviewers, same point

Answer the first one in full and post it. Then reply to the others with one line that links to it, as in `Good point, updated the doc command now (<sha>). Have also addressed the scaling point [here](<comment url>).` Do not repeat the content.

## Mechanics (gh)

Write each message to a temp file outside the repo, then:

- **PR conversation comment** (also the way to answer a review body, which has no thread): `gh api repos/OWNER/REPO/issues/N/comments -F body=@msg.txt --jq .html_url`.
- **Inline review thread reply**: `gh api repos/OWNER/REPO/pulls/N/comments/COMMENT_ID/replies -F body=@msg.txt --jq .html_url`. No `@` mention needed.
- **Review with inline comments**: `gh api repos/OWNER/REPO/pulls/N/reviews --input review.json`, where the JSON has `commit_id` (the head sha reviewed), `body`, `comments` (`path`, `line`, `side`, `body`) and, only when allowed by rule 4, `event` (`APPROVE`, `COMMENT`). Omit `event` to leave it pending.
- **Review with no inline comments**: `gh pr review N --approve|--comment -b "$(cat msg.txt)"`. Check the head sha has not moved since the review first.

Find human comments, skipping bots:

```
gh api repos/OWNER/REPO/pulls/N/reviews --jq '.[]|select(.user.type!="Bot")|{id,user:.user.login,state,body}'
gh api repos/OWNER/REPO/pulls/N/comments --jq '.[]|select(.user.type!="Bot")|{id,user:.user.login,path,line,body}'
gh api repos/OWNER/REPO/issues/N/comments --jq '.[]|select(.user.type!="Bot")|{id,user:.user.login,body}'
```

Post messages that others link to first, capture the returned `html_url`, then post the dependent ones. After posting, report each URL to the user.
