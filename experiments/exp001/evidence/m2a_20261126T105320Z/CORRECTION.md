---
title: "Correction - M2a evidence manifest"
sub-title: "M2A-DEFECT-001, run 20261126T105320Z"
author: "Claude Code (implementer)"
date: "2026-11-26"
---

# Correction - M2a evidence manifest (M2A-DEFECT-001)

Decision: D-066. `MANIFEST.sha256` in this folder is kept unchanged as raw
evidence. This file records the defect and gives fresh digests.

## Defect

`MANIFEST.sha256` does not describe the folder correctly:

- it has an entry for `MANIFEST.sha256.tmp`, a temporary file of the install script
  that does not exist in the folder;
- it lists `install_and_verify.log` twice, with two different digests
  (`9ac091ec...` and `31e58716...`);
- the log committed in `fe26c25` (30 lines, SHA-256 `d14e804d...`) matches neither
  entry. The script kept writing to the log after the commit (23 more lines: the
  staging list, the commit line and `OVERALL: PASS`).

Observation at 2026-11-26: the final log (53 lines) has SHA-256 `31e58716...`, the
second manifest entry. The first entry (`9ac091ec...`) matches no known state of the
log. All other manifest entries match their files.

## Root causes (planner's install script, not the reference or the results)

1. The manifest was computed while the `tee`'d log was still being written.
2. The file listing for the manifest included the script's own `.tmp` file.

The M2a results themselves (self-test, vector comparison, oracle digests) are not
affected: their files match the manifest.

## Lesson for all scripts

Write manifests last, after every log is closed, excluding the manifest itself and
temporary files.

## Fresh SHA-256 of every file in this folder (excluding this file)

Computed on 2026-11-26 with `shasum -a 256 *` before this file was written.
`install_and_verify.log` is committed as it is now (it only grew).

```text
31e587160ccfa2b1c2a329bfbbb6d64f45d460783632e5b03cac65602e98e962  install_and_verify.log
48585c3d76012aadd98da9df8b9a594608be159bdfd7c4465b37587e14d09a7c  MANIFEST.sha256
17cd57a8555b40df6bff97bf7fa4dc0895e24d3de2801d370de999d64df832f6  oracle_after.txt
17cd57a8555b40df6bff97bf7fa4dc0895e24d3de2801d370de999d64df832f6  oracle_before.txt
5695c81c06dbbae8fa3ba24ce3c65875ff9f652351ad38f7c86e4280dda77a6c  protected_before.txt
0194cf3fd77740464905484539823e6d71d0dae6d4c6621d9542589227feec03  provenance.txt
1bbf68871bfb48a49ac94fc3a6fb6019f2fe87a073ab613274952406ddb972e7  reference.log
52095121565db779faf05c956e35476a6a5034e955c0aa800f84b1b18f97eece  tool_versions.txt
3ae93a993b8aca28a5fd773f5c2f292167ae7d634e31f212b1b7408e3e2238a5  vector_comparison.txt
a952ecf6df6dbf4dc2373080dda5bdb7be885bedf728713679a06cbcdbee9a66  vector_sha256.txt
```
