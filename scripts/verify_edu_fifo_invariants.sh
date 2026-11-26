#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0
[[ "$(pwd -P)" == "$(git rev-parse --show-toplevel)" && "$(basename "$PWD")" == fpga_ai ]] || { echo 'Run from fpga_ai root' >&2; exit 1; }
base=experiments/edu_fifo
for p in experiments "$base" "$base/rtl" "$base/v2" "$base/v2/rtl" "$base/build" "$base/rtl/edu_fifo.vhd" "$base/v2/rtl/edu_fifo.vhd" research research/DECISION_LOG.md scripts scripts/verify_protected_digests.py; do
 [[ ! -L "$p" ]] || { echo "Symlink refused: $p" >&2; exit 1; }
done
python3 scripts/verify_protected_digests.py
python3 - <<'CHECK'
import hashlib
from pathlib import Path
for line in """    3dd6871c78b06d8c6574dfc3a7ae0fd1fa82e7f29621e7b0ac985926951703af  experiments/edu_fifo/rtl/edu_fifo.vhd
    f0a25d75872ba57174ba8b8cf67035d2ff81c0111dc8a1b704a86166eaf89c57  experiments/edu_fifo/v2/rtl/edu_fifo.vhd
    ff85b6725115af0ea9216341c1e6489f106fb034c5cf66a5b2f9128d2707ea77  experiments/edu_fifo/SPECIFICATION.md""".splitlines():
    digest,name=line.split()
    if hashlib.sha256(Path(name).read_bytes()).hexdigest()!=digest: raise SystemExit("Source mismatch: "+name)
CHECK
python3 - <<'PY'
from pathlib import Path
p=Path('research/DECISION_LOG.md'); s=p.read_text()
entry='''
## Invariant-strengthened formal verification (2026-11-26)

### D-047 - Preserve initial proof evidence
Owner: planner; user approved direction. Initial experiment: 3 complete proofs, 15 bounded, no reachable counterexamples. Induction reached maximum depth for the 15 cases; no timeout observed. Preserve original runner and logs.

### D-048 - Strengthen induction property
Owner: planner; delegated. Expose existing netlist state as verification-only ports; prove pointer bounds, equal occupancy and pointers, circular pointer/occupancy relation, and equality of occupied words. Unoccupied words are unconstrained. Prove conjunction from reset and by induction, never assume these invariants externally. Preserve observable property. This is a sufficient state relation for these architectures, not a general FIFO equivalence method.

### D-049 - Controlled proof pilot
Owner: planner; delegated. Repeat six configurations and three comparisons with original horizons and time limits. Audit state aliases against prior generated Verilog and JSON; fail closed on missing or unexpected widths. No source RTL changes. Classify incomplete induction as bounded only if observable bounded proof previously established or current strengthened bounded proof passes; strengthened-property failure is not automatically an observable defect. XC7 equivalence deferred.
'''
if '### D-047' in s:
    if entry.strip() not in s: raise SystemExit('Existing EQ-B decisions differ')
else:
    if '### D-046' not in s or any(f'### D-{i:03}' in s for i in (48,49)): raise SystemExit('Unexpected ledger state')
    with p.open('a') as f: f.write(entry)
    print('APPENDED D-047 through D-049')
PY
mkdir -p "$base/build"
run=$(mktemp -d "$base/build/equiv_invariants.XXXXXXXX")
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
    for p in [*sources.values(),base/"SPECIFICATION.md",Path("/workspace/scripts/verify_edu_fifo_invariants.sh")]:
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
def expose(path, version, w, d):
    obj=json.loads(path.read_text()); m=obj["modules"]["edu_fifo"]
    def bits(name, size):
        v=m["netnames"][name]["bits"]
        if len(v)!=size: raise ValueError(f"Unexpected width: {name}")
        return v
    def port(name, v):
        if name in m["ports"] or name in m["netnames"]: raise ValueError(name)
        m["ports"][name]={"direction":"output","bits":v}
        m["netnames"][name]={"hide_name":0,"bits":v,"attributes":{}}
    cw=d.bit_length(); aw=max(1,(d-1).bit_length())
    port("proof_count",bits("count",cw))
    for name in ("rd_ptr","wr_ptr"):
        port("proof_"+name,["0"] if d==1 else bits(name if version=="v1" else "g_mem_"+name,aw))
    if version=="v1":
        packed=bits("mem",w*d)
        words=[packed[(d-1-i)*w:(d-i)*w] for i in range(d)]
    else:
        words=[bits("g_d1_head" if d==1 else f"g_mem_mem[{i}]",w) for i in range(d)]
    for i,word in enumerate(words): port(f"proof_word_{i}",word)
    dst=path.with_name(path.stem+"_exposed.json");dst.write_text(json.dumps(obj))
    return dst

def harness(w,d):
    cw=d.bit_length(); aw=max(1,(d-1).bit_length())
    declarations=[]; instances=[]
    for tag,module in [("a","gold"),("b","gate")]:
        declarations += [f"wire [{cw-1}:0] {tag}count;",f"wire [{aw-1}:0] {tag}rp, {tag}wp;"]
        declarations += [f"wire [{w-1}:0] {tag}word{i};" for i in range(d)]
        ports=[f".proof_count({tag}count)",f".proof_rd_ptr({tag}rp)",f".proof_wr_ptr({tag}wp)"]+[f".proof_word_{i}({tag}word{i})" for i in range(d)]
        instances.append(f"{module} {tag}(.clk(clk), .rst(reset), .wr_valid(wr_valid), .wr_ready({tag}w), .wr_data(wr_data), .rd_valid({tag}v), .rd_ready(rd_ready), .rd_data({tag}d), "+", ".join(ports)+");")
    terms=[f"acount <= {d}", "acount == bcount", "arp == brp", "awp == bwp",f"arp < {d}",f"awp < {d}"]
    # Enumerated circular relation avoids arithmetic truncation and modulo cells.
    for r in range(d):
        for c in range(d+1):
            terms.append(f"(!(arp == {r} && acount == {c}) || awp == {(r+c)%d})")
    for i in range(d):
        occupied=" || ".join(f"(arp == {r} && acount > {(i-r)%d})" for r in range(d))
        terms.append(f"(!({occupied}) || aword{i} == bword{i})")
    return f"""module compare_fifo(input clk, rst, wr_valid, rd_ready,
 input [{w-1}:0] wr_data, output ok, output observable_ok);
 reg armed = 1\x27b0;
 always @(posedge clk) armed <= 1\x27b1;
 wire reset = rst | !armed;
 wire aw, av, bw, bv;
 wire [{w-1}:0] ad, bd;
 {chr(10).join(declarations)}
 {chr(10).join(instances)}
 assign observable_ok = !armed || ((aw == bw) && (av == bv) && (!av || (ad == bd)));
 assign ok = !armed || (observable_ok && ({" && ".join(terms)}));
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
                    expose(folder/f"{name}.json",version,w,d)
            prepared[version]=not code
        for label,va,na,vb,nb in [("EQ1","v1","reference","v1","optimized"),("EQ2","v2","reference","v2","optimized"),("EQ3","v1","reference","v2","reference")]:
            folder=root/label;folder.mkdir(); horizon=2*d+8
            row=dict(width=w,depth=d,comparison=label,horizon=horizon,bounded="NOT_RUN",induction="NOT_RUN",status="INCONCLUSIVE",reason="preparation failure")
            if prepared[va] and prepared[vb]:
                (folder/"harness.v").write_text(harness(w,d))
                prefix=(f"read_json ../{va}/{na}_exposed.json; rename edu_fifo gold; read_json ../{vb}/{nb}_exposed.json; rename edu_fifo gate; read_verilog harness.v; hierarchy -check -top compare_fifo; proc; flatten; opt_clean; check -assert; select -module compare_fifo; ")
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
                    row.update(bounded="FAIL",status="INCONCLUSIVE",reason="reachable strengthened-property counterexample; inspect observable_ok")
                else: row.update(bounded="INCONCLUSIVE",reason="bounded proof not established; inspect log")
            writer.writerow(row);f.flush();print(w,d,label,row["status"],flush=True)
            failed |= row["status"] in ("FAILED","INCONCLUSIVE")
raise SystemExit(int(failed))
PY
' 2>&1 | tee "$run/equivalence.log" || rc=$?
python3 scripts/verify_protected_digests.py
exit "$rc"
