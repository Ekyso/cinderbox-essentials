# Cinderbox Essentials

Compiled mod packs for Cinderbox.

Each versioned release contains the exact `cinderbox-pack.zip` used by the matching Cinderbox build. Source code for unpublished mods is maintained separately and is not stored in this repository.

## Publishing

Run `scripts/import-pack.sh` with a verified Cinderbox Release pack. The script validates the archive, copies it into this repository, and advances `PACK_VERSION` only when the archive hash changes.

Review the resulting ZIP and `release.env`, then push them to `main`. GitHub Actions verifies the pinned hash and creates `pack-vN` as a prerelease.
