# Release Checklist

This document outlines the standard procedure for performing a new release of Zigsteroids.

## Pre-Release Steps

1.  **Review Staged Changes**: Run `git diff --cached` to review all staged changes and understand what is being released.
2.  **Write Release Notes**: Prepend a user-facing summary of changes to `RELEASE.md` under a new version heading. Summaries should be 2-5 bullet points, written in language an end user would understand.
3.  **Bump Version Numbers**: Increment the version in:
    - `build.zig.zon` (`.version` field)
4.  **Commit**: Stage all changes (`git add`) and commit with a descriptive message (e.g., `0.3.1 release`).

## Release Steps

5.  **Tag the Release**: Create a git tag matching the version (e.g., `git tag v0.3.1`).
6.  **Push the Tag**: Push the tag to the remote (e.g., `git push origin v0.3.1`).
7.  **Push the Commit**: Push the branch to the remote if not already done (e.g., `git push origin zig-0.15`).

## Post-Release Steps

8.  **Verify**: Confirm the tag and commit appear on the remote repository.
9.  **Communicate**: Inform stakeholders of the new release and its changes.
