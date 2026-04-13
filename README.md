# discourse-guest-comment-delay

Discourse plugin scaffold that delays anonymous visibility of recent replies.

## Goal

- First post is always visible.
- Logged-in users always see all replies.
- Anonymous users only see replies whose `created_at` is older than the effective delay.
- Effective delay comes from a global site setting with nullable category override semantics:
  - `nil` = inherit global
  - `0` = disable restriction for this category
  - `>0` = override global delay in minutes

## Notes

This repository is a standalone plugin project scaffold. Full integration tests require mounting it inside a real Discourse checkout under `plugins/`.
