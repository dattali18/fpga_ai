#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0
[[ "$(pwd -P)" == "$(git rev-parse --show-toplevel)" && "$(basename "$PWD")" == fpga_ai ]] || { echo 'Run from fpga_ai root' >&2; exit 1; }
base=experiments/edu_fifo
for p in experiments "$base" "$base/rtl" "$base/v2" "$base/v2/rtl" "$base/build" "$base/rtl/edu_fifo.vhd" "$base/v2/rtl/edu_fifo.vhd" research research/DECISION_LOG.md scripts scripts/verify_protected_digests.py; do
 [[ ! -L "$p" ]] || { echo "Symlink refused: $p" >&2; exit 1; }
done
python3 scripts/verify_protected_digests.py
python3 - <<'PY'
from pathlib import Path
p=Path('research/DECISION_LOG.md'); s=p.read_text()
entry='''
## Generic formal verification (2026-11-26)

### D-041 - Solver selection
Owner: planner; user approved direction. Use installed Yosys internal SAT; no new dependencies. External SMT solvers unavailable in probe. EQ4 deferred.

### D-042 - Observable equivalence
Owner: planner; delegated. Compare ready and valid exactly and valid read data only. Compare GHDL-generated Verilog before generic optimization (normalized for SAT) against generic synthesis and compare V1/V2. This does not independently prove VHDL translation correctness.

### D-043 - Invalid data masking
Owner: planner; delegated. Ignore read data only when both outputs are invalid; do not ignore valid mismatches. Binary-valued input model, no restrictions on subsequent request sequences. No unknown-cell skipping.

### D-044 - Reset semantics
Owner: planner; delegated. Harness forces reset during first modeled cycle via initialized armed flag; all subsequent resets arbitrary. Compare after first reset edge. No forced zero initialization of data storage.

### D-045 - Proof classification
Owner: planner; delegated. Run bounded SAT and independent combined base/induction proof. PROVEN requires explicit induction success; BOUNDED means bounded pass but no complete proof; FAILED requires reachable bounded counterexample; other failures INCONCLUSIVE. Keep logs and counterexamples; induction-step counterexamples alone are not reachable defects.

### D-046 - Progressive proof sweep
Owner: planner; delegated. Pilot widths/depths (1,1), (2,2), (2,3), (2,4), (8,3), (8,4). Bounded horizon 2D+8 cycles including reset; induction max 8 steps; SAT instance timeout 15 seconds, wall timeout 90 seconds per invocation. Larger configurations and XC7 mapping deferred. No RTL or oracle changes. Status: planned.
'''
if '### D-041' in s:
    if entry.strip() not in s: raise SystemExit('Existing formal decisions differ; review ledger')
else:
    if '### D-040' not in s or any(f'### D-{i:03}' in s for i in range(42,47)): raise SystemExit('Unexpected decision ledger state')
    with p.open('a') as f: f.write(entry)
    print('APPENDED D-041 through D-046')
PY
mkdir -p "$base/build"
run=$(mktemp -d "$base/build/equiv.XXXXXXXX")
echo "Results: $run"
git rev-parse HEAD > "$run/git_head.txt"
git status --short > "$run/git_status.txt"
image_id=$(docker image inspect fpga_ai-toolchain:m1-arm64 --format '{{.Id}}')
printf '%s\n' "$image_id" > "$run/image_id.txt"
rc=0
docker run --rm --platform linux/arm64 -v "$PWD:/workspace:ro" -v "$PWD/$run:/results:rw" -w /results "$image_id" bash -euo pipefail -c '
mkdir -p tmp
export TMPDIR="$PWD/tmp" PYTHONDONTWRITEBYTECODE=1
ghdl --version > tools.txt
yosys -V >> tools.txt
python3 --version >> tools.txt
python3 - <<"PY"
import csv, hashlib, json, subprocess, time
from pathlib import Path
base=Path("/workspace/experiments/edu_fifo")
sources={"v1":base/"rtl/edu_fifo.vhd","v2":base/"v2/rtl/edu_fifo.vhd"}
configs=[(1,1),(2,2),(2,3),(2,4),(8,3),(8,4)]
Path("configs.tsv").write_text("".join(f"{w}\t{d}\n" for w,d in configs))
with open("source_sha256.txt","w") as f:
    for p in [*sources.values(),base/"SPECIFICATION.md",Path("/workspace/scripts/verify_edu_fifo_equivalence.sh")]:
        relative=p.relative_to(Path("/workspace"))
        f.write(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {relative}\n")
def run(args,cwd,log,out=None,timeout=90):
    start=time.monotonic(); cwd=Path(cwd)
    with open("commands.jsonl","a") as f: f.write(json.dumps(dict(cwd=str(cwd),args=args))+"\n")
    with (cwd/log).open("w") as err:
        try:
            if out:
                with (cwd/out).open("w") as stream: r=subprocess.run(args,cwd=cwd,stdout=stream,stderr=err,timeout=timeout)
            else: r=subprocess.run(args,cwd=cwd,stdout=err,stderr=subprocess.STDOUT,timeout=timeout)
            code=r.returncode
        except subprocess.TimeoutExpired:
            err.write("\nWALL TIMEOUT\n"); code=124
    return code,round(time.monotonic()-start,3)
# Same external binary inputs; force one synchronous reset edge before comparison.
def harness(w):
    return f"""module compare_fifo(input clk, rst, wr_valid, rd_ready,
 input [{w-1}:0] wr_data, output ok);
 reg armed = 1\x27b0;
 always @(posedge clk) armed <= 1\x27b1;
 wire reset = rst | !armed;
 wire aw, av, bw, bv;
 wire [{w-1}:0] ad, bd;
 gold a(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(aw), .wr_data(wr_data), .rd_valid(av), .rd_ready(rd_ready), .rd_data(ad));
 gate b(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready(bw), .wr_data(wr_data), .rd_valid(bv), .rd_ready(rd_ready), .rd_data(bd));
 assign ok = !armed || ((aw == bw) && (av == bv) && (!av || (ad == bd)));
endmodule
"""
fields="width depth comparison horizon bounded induction status bounded_seconds induction_seconds reason".split()
failed=False
with open("equivalence.csv","w",newline="") as f:
    writer=csv.DictWriter(f,fieldnames=fields);writer.writeheader()
    for w,d in configs:
        root=Path(f"w{w}_d{d}");root.mkdir()
        prepared={}
        for version,src in sources.items():
            folder=root/version;folder.mkdir()
            code,_=run(["ghdl","-a","--std=08",str(src)],folder,"analysis.log")
            if not code: code,_=run(["ghdl","--synth","--std=08","--no-formal","--out=verilog",f"-gG_WIDTH={w}",f"-gG_DEPTH={d}","edu_fifo"],folder,"ghdl.log","raw.v")
            if not code:
                # Keep a minimally normalized reference and an independently optimized candidate.
                for name,passes in [("reference","proc; memory_map; opt_clean"),("optimized","synth -top edu_fifo; opt")]:
                    code,_=run(["yosys","-Q","-T","-p",f"read_verilog raw.v; hierarchy -check -top edu_fifo; {passes}; check -assert; write_json {name}.json"],folder,f"{name}.log")
                    if code: break
            prepared[version]=not code
        for label,va,na,vb,nb in [("EQ1","v1","reference","v1","optimized"),("EQ2","v2","reference","v2","optimized"),("EQ3","v1","reference","v2","reference")]:
            folder=root/label;folder.mkdir(); horizon=2*d+8
            row=dict(width=w,depth=d,comparison=label,horizon=horizon,bounded="NOT_RUN",induction="NOT_RUN",status="INCONCLUSIVE",reason="preparation failure")
            if prepared[va] and prepared[vb]:
                (folder/"harness.v").write_text(harness(w))
                prefix=(f"read_json ../{va}/{na}.json; rename edu_fifo gold; read_json ../{vb}/{nb}.json; rename edu_fifo gate; read_verilog harness.v; hierarchy -check -top compare_fifo; proc; flatten; opt_clean; check -assert; select -module compare_fifo; ")
                # Validate startup and demonstrate that a false property is rejected.
                sanity_ok=True
                for tag,expr,should_pass in [
                    ("armed_initial", "-seq 1 -prove armed 0", True),
                    ("armed_active", "-seq 2 -prove armed 1 -prove-skip 1", True),
                    ("negative_control", "-seq 2 -prove armed 0", False),
                ]:
                    cmd=prefix+"sat "+expr+" -show armed -timeout 15 -verify -dump_vcd "+tag+".vcd"
                    result,_=run(["yosys","-Q","-T","-p",cmd],folder,tag+".log")
                    audit=(folder/(tag+".log")).read_text()
                    valid=(result==0 and "no model found: SUCCESS" in audit) if should_pass else (result==1 and ("model found: FAIL" in audit or "Called with -verify and proof did fail!" in audit) and (folder/(tag+".vcd")).is_file())
                    if not valid or "contains processes" in audit:
                        sanity_ok=False
                if not sanity_ok:
                    row.update(reason="harness activation or negative control failed")
                    writer.writerow(row);f.flush();print(w,d,label,row["status"],flush=True)
                    failed=True
                    continue
                common=" -prove ok 1 -show-inputs -show-outputs -show-regs -show armed -timeout 15 -verify"
                bounded=prefix+f"sat -seq {horizon}"+common+" -dump_vcd bounded_counterexample.vcd"
                code,row["bounded_seconds"]=run(["yosys","-Q","-T","-p",bounded],folder,"bounded.log")
                text=(folder/"bounded.log").read_text()
                if code==0 and "no model found: SUCCESS" in text:
                    row.update(bounded="PASS",status="BOUNDED",reason="bounded proof passed")
                    cmd=prefix+"sat -seq 1 -tempinduct -maxsteps 8"+common+" -dump_vcd induction_trace.vcd"
                    code,row["induction_seconds"]=run(["yosys","-Q","-T","-p",cmd],folder,"induction.log")
                    text=(folder/"induction.log").read_text()
                    if code==0 and "Induction step proven: SUCCESS" in text:
                        row.update(induction="PASS",status="PROVEN",reason="combined base and induction proof")
                    else: row.update(induction="INCONCLUSIVE",reason="induction not established; inspect log")
                elif code==1 and ("model found: FAIL" in text or "Called with -verify and proof did fail!" in text) and (folder/"bounded_counterexample.vcd").is_file():
                    row.update(bounded="FAIL",status="FAILED",reason="reachable bounded counterexample")
                else: row.update(bounded="INCONCLUSIVE",reason="bounded proof not established; inspect log")
            writer.writerow(row);f.flush();print(w,d,label,row["status"],flush=True)
            failed |= row["status"] in ("FAILED","INCONCLUSIVE")
raise SystemExit(int(failed))
PY
' 2>&1 | tee "$run/equivalence.log" || rc=$?
python3 scripts/verify_protected_digests.py
exit "$rc"
