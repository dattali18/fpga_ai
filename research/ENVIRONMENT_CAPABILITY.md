---
title: "GCP environment capability and protected-file baseline"
sub-title: "EXP001 Milestone M0 read-only probe and SHA-256 manifest"
author: "Coding agent"
date: "2026-11-25"
---

# Environment Capability and Protected-File Baseline

Observed strictly via read-only commands on 2026-11-25 per [../context/DEVELOPMENT_ENVIRONMENTS.md](../context/DEVELOPMENT_ENVIRONMENTS.md). No packages were installed and no container daemons were invoked.

## 1. Host Summary

* **GCP Authoring Host (Observed)**: `Linux 6.12.114+ x86_64 GNU/Linux` (Ubuntu 24.04 container, `glibc 2.39`).
* **Local Execution Target (Scheduled 2026-11-26)**: MacBook Pro M5, 16 GiB RAM, running Linux `linux/arm64` via Docker.

## 2. Observed GCP Tool and Package Matrix

| Category | Observed `PRESENT` | Observed `ABSENT` or `BLOCKED` |
| :--- | :--- | :--- |
| **Shell and Utilities** | `bash 5.2.21`, `git 2.43.0`, `jq 1.7`, `sha256sum`, `tar`, `zip` | -- |
| **C/C++ Build** | `make 4.3`, `cmake 3.28.3`, `gcc 13.3.0`, `clang 18.1.3` | -- |
| **Python Runtime** | `python3 3.12.3` (stdlib + `PyYAML 6.0.1`), `pip3`, `uv 0.13.10` *(installs prohibited)* | `numpy`, `scipy`, `pytest`, `cocotb`, `cocotb-bus`, `cocotb-test`, `jsonschema` (`ABSENT`) |
| **Python Static Tools** | `python3 -m py_compile`, `ast` | `ruff`, `flake8`, `mypy`, `black` (`ABSENT`) |
| **Containers** | `/usr/bin/docker` CLI binary on `PATH` | Docker daemon/build/run (`BLOCKED` by GCP sandbox policy); `podman` (`ABSENT`) |
| **HDL Simulation / Synthesis** | *None* | `ghdl`, `nvc`, `iverilog`, `verilator`, `yosys`, `vivado`, `quartus` (`ABSENT`) |

### GCP vs. Local Verification Capability

* **Runnable on GCP**: Protected-file SHA-256 verification, YAML frontmatter/ASCII/link checks (`PyYAML`), shell syntax validation (`bash -n`), and Python 3.12 stdlib syntax/unit checks (`py_compile`, `unittest`).
* **Blocked on GCP (Requires M4 Local `linux/arm64` Docker)**: Container build, VHDL-2008 compilation/elaboration/simulation, `cocotb`/`pytest`/`numpy` co-simulation, and generic RTL synthesis.

## 3. Unverified Local ARM64 Toolchain Risks

Because no `linux/arm64` container can be built or probed on GCP, the following remain **unverified risks** to be empirically tested during M4 local execution:

1. **R-ENV-1 (GHDL ARM64 package and simulator backend)**: Exact Ubuntu/Debian `arm64` package availability and backend support (`llvm`, `gcc`, or `mcode`) plus VPI/VHPI compatibility with `cocotb` are unverified until tested on the M5 host.
2. **R-ENV-2 (Yosys VHDL-2008 synthesis frontend on ARM64)**: Availability and build/package path for a VHDL-2008 frontend (such as `ghdl-yosys-plugin` or an alternative open-source path) within 16 GiB RAM on `linux/arm64` is unverified.
3. **R-ENV-3 (`binary32` synthesis construct coverage)**: Whether standard VHDL-2008 floating-point packages or explicit IEEE-754 `binary32` RTL modules synthesize cleanly without black boxes in the target open-source toolchain is unverified and must not be assumed from simulation.

## 4. Protected Bootstrap File SHA-256 Baseline (35 Files)

Combined manifest SHA-256 (`find AGENTS.md START_PROMPT.md .agents context -type f | sort | xargs sha256sum | sha256sum`):
`2fc5ad8a16cb46f235b6b71762b8c3f82bde8ce4ba6303f3e0da7248c7a2bf58`

```text
29bf5406c6015e0f55b79eff66d16e47c0e9c08f41e961c5dd57371fda0f492b  AGENTS.md
1bcbd589a23cdb05f55fc5fbfb7df2f20bc66c3749fef38c2bccd676ccbddc3d  .agents/rules/agent_permissions_and_scope.md
643a1b99b22ebecb2b8fb49c54d511a0954a5212933fb0e0d6896c776929f23a  .agents/rules/code_ownership.md
ad231d72694f71cde2e0d78585bbcfe95cc81fe8a08288d3c56020373c0ced85  .agents/rules/markdown_document_metadata_header.md
b9fb80b26c8994c39bf3f451541105e4961b92f969dd22267211e414a625003f  .agents/rules/plan_and_approval_workflow.md
fa6d87646cd19cf964779a8d0a8b19b9776dc65885912d1a33eca839ac86d142  .agents/rules/research_integrity.md
c1b7a358b50f4fcadc7524529c64f807eea050c39578a443484d7462a4a68bcf  .agents/rules/system_environments_and_deployment_workflow.md
df0a92dd34464646181a2338ad039141baea87195ad365cbf1933c0cd6c29322  .agents/rules/verification.md
fe84f5155e86e6862dd178aa8905926c92c40ee1f84bebed921661a741c85971  .agents/rules/vhdl_engineering.md
d584520b1c5cbe5167d2ff2a6111ce86f8b2e37c1b6fba47a4c18d04295d81dd  .agents/skills/changelog-logging/SKILL.md
867c11e10377a878768b8e6fba1d9a119e43eddbaebf54ef97abbff1a7b4c627  .agents/skills/claim-tracing/SKILL.md
2cb2482a232937e3a6dfc24b9ac4a1ca02cdac3f67f664abc058258d787d011d  .agents/skills/daily-notes/SKILL.md
7479389034ba1311d9eb87cd29865060a2cc5c391302912080e2023752821017  .agents/skills/fpga_benchmarking/SKILL.md
6b82b4f25bb60f4635a13373b1322586d8930da6db59884531e5587194eb90f1  .agents/skills/fpga_docker_environment/SKILL.md
44d0558fd5845a52f1913b4b56463aa5319b33403e6332663ecf6275bef18d13  .agents/skills/fpga_synthesis/SKILL.md
06bd044d282630188397b1e744c5443645a270116eb3c4f8deb3c1cd16a1297f  .agents/skills/long-term-learning/SKILL.md
47f859089708c002abeb26a6eef104875e2873346db099cca15f6f0109a4a5ea  .agents/skills/release_validation/SKILL.md
d13b8f35b492056c181bd96249a89a61ba403ebce88f43aca5c808d77bb6f7ee  .agents/skills/rtl_verification/SKILL.md
69dc140b6ba709f9245be26fab90d9dc2f6b44d02615067d3a8d19e9d87781ee  .agents/skills/safe-editing/SKILL.md
115ae8693477528cfec33924841d80cdf1128f9175cf6a1345bf62babbb0d8ea  .agents/skills/session-resume/SKILL.md
2bf87846bff93dd8c19599d7f45b24efed65a8b1b1d435da3933d6ca635880b2  .agents/skills/specification_review/SKILL.md
91144004038638320eb644f10f22a2b3ddba96e4f39c3217e27a0066bf7d8f00  .agents/skills/todo-tracking/SKILL.md
c4cfe54897100919d1dd2579d762f3174a3440894e2d2eeb5d7dd2518206e3cc  .agents/skills/vhdl_development/SKILL.md
e3fb5ddfc61e13434594230919ae9449438d5b626d37c7128ed1a85d454d4f6d  .agents/workflows/implement_milestone.md
d889b4cb135d8153379d6739c3ceddd3074b86d31a5503c2459b29bba5eacd11  .agents/workflows/review_milestone.md
37193c3f2268a2316f32ac0050e9d4dd2452e147728d4c8da75eeeffdeecf397  context/DEVELOPMENT_ENVIRONMENTS.md
86334a11014b53ce89b0c5bc34d19e8c5a11ba27d1966cad8952da88156f00a3  context/experiments/exp001/ACCEPTANCE_CRITERIA.md
ed9f374a58cc2fe7acff4e380bc6f4bb0bbe66b9328a278cff95d45d6338a0c1  context/experiments/exp001/IMPLEMENTATION_PLAN.md
ae0db214d1f62980ce793436b084b8ee1dc3536b257e6e090b0e452311914463  context/experiments/exp001/REQUIREMENTS.md
e61ec3fdf8dbafd17ea745e4179cd701104bcb957be0664ee56836a9c9841b21  context/PROJECT_DECISIONS.md
e90514dd9be0d5a91a7442c7c5f8f5e37a81f101e5de235d55565ee228cc05ea  context/PROJECT_VISION.md
8a28720063a10899660180a65b5b750517d859e23fabc577304eddd7feb8ef44  context/RESEARCH_METHODOLOGY.md
aa449e064fa29aebbad32cc91d3abcbf5f1ed5158479360db96d8c393a1ffe69  context/REUSE_MANIFEST.md
29a2a3ce18d27f2e7fcb3e01e6d0270dad89786d98a16d446f7a716c85e12b86  context/STATUS.md
5b49092da8fb3384a384c9c29ce2884ae6330f1f53e87e5e1897e2aca57f80f2  START_PROMPT.md
```
