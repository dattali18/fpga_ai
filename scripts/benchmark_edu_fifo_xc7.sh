#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0
[[ "$(pwd -P)" == "$(git rev-parse --show-toplevel)" && "$(basename "$PWD")" == fpga_ai ]] || { echo 'Run from fpga_ai root' >&2; exit 1; }
base=experiments/edu_fifo
for p in experiments "$base" "$base/rtl" "$base/v2" "$base/v2/rtl" "$base/build" "$base/rtl/edu_fifo.vhd" "$base/v2/rtl/edu_fifo.vhd" "$base/golden.py" "$base/tb" "$base/tb/tb_edu_fifo.vhd" research research/DECISION_LOG.md scripts scripts/verify_protected_digests.py; do
    [[ ! -L "$p" ]] || { echo "Symlink refused: $p" >&2; exit 1; }
done
python3 scripts/verify_protected_digests.py
python3 - <<'PY'
from pathlib import Path
p=Path('research/DECISION_LOG.md')
s=p.read_text()
entry='''
## FPGA-family mapping experiment (2026-11-26)

### D-034 - Reference architecture
Owner: planner; user approved mapping experiment. Select Xilinx Series 7 (xc7) as a reference family because installed Yosys exposes LUT, distributed RAM and block RAM mappings. Alternatives: iCE40, ECP5, UltraScale. No specific part or board selected. Evidence: local Yosys help probe. Physical timing and fit remain unknown.

### D-035 - Out-of-context mapping
Owner: planner; delegated. Use synth_xilinx -family xc7 -top edu_fifo -noiopad -noclkbuf for both versions. Exclude top-level I/O and clock buffer insertion to compare internal component resources. Retain check -assert. No RTL changes or retiming. Mapped primitives are estimates, not routed utilization.

### D-036 - Controlled mapping strategies
Owner: planner; user approved direction. Reuse all 22 paired configurations for both RTL versions. Compare default, -nobram, and -nobram -nolutram -nosrl (132 mappings). Record exact primitive types and counts, netlists, commands, wall times and failures. Keep distributed RAM and SRL primitives distinct from logic LUTs; do not equate primitive counts with occupied slices. No new functional simulation in this mapping-only run; existing oracle regression is prior evidence, not netlist equivalence. Continue individual failures and return nonzero if any fail.

### D-037 - Defer physical implementation
Owner: planner; delegated. No nextpnr executable was found in the local probe. Use existing Docker image, no installations. Defer part selection, placement, routing, timing closure and mapped functional equivalence. Raw evidence stays in ignored build directory; compact results to be archived after review. Status: planned; actual mapping pending.
'''
if '### D-034' in s:
    if entry.strip() not in s: raise SystemExit('Existing mapping decision entries differ; review ledger')
else:
    if '### D-033' not in s or any(f'### D-{i:03}' in s for i in range(35,38)): raise SystemExit('Unexpected decision ledger state')
    with p.open('a') as f: f.write(entry)
    print('APPENDED D-034 through D-037')
PY
mkdir -p "$base/build"
run=$(mktemp -d "$base/build/xc7.XXXXXXXX")
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
from collections import Counter
from pathlib import Path
base=Path("/workspace/experiments/edu_fifo")
configs=sorted({(32,d) for d in (1,4,8,16,32,64,128,256,3,15,31,63,127)} | {(w,32) for w in (8,16,32,64,128)} | {(1,1),(8,1),(8,3),(8,4),(16,5),(32,8)})
assert len(configs)==22
sources={"v1":base/"rtl/edu_fifo.vhd","v2":base/"v2/rtl/edu_fifo.vhd"}
strategies={"default":[],"no_bram":["-nobram"],"logic_only":["-nobram","-nolutram","-nosrl"]}
Path("configs.tsv").write_text("".join(f"{w}\t{d}\n" for w,d in configs))
with open("source_sha256.txt","w") as f:
    for p in [*sources.values(),base/"golden.py",base/"tb/tb_edu_fifo.vhd",Path("/workspace/scripts/benchmark_edu_fifo_xc7.sh")]:
        relative=p.relative_to(Path("/workspace"))
        f.write(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {relative}\n")
def execute(args, cwd, log, out=None):
    start=time.perf_counter()
    with (cwd/log).open("w") as err:
        if out:
            with (cwd/out).open("w") as f: r=subprocess.run(args,cwd=cwd,stdout=f,stderr=err)
        else: r=subprocess.run(args,cwd=cwd,stdout=err,stderr=subprocess.STDOUT)
    return r.returncode,round(time.perf_counter()-start,6)
fields="version width depth storage_bits strategy ghdl_status mapping_status ghdl_seconds mapping_seconds total_cells logic_lut_cells ff_cells distributed_ram_cells bram18_cells bram36_cells srl_cells carry4_cells muxf_cells other_cells".split()
failed=False
with open("benchmark.csv","w",newline="") as f,open("cell_types.csv","w",newline="") as c,open("commands.jsonl","w") as commands:
    writer=csv.DictWriter(f,fieldnames=fields,lineterminator="\n"); writer.writeheader()
    cells=csv.writer(c,lineterminator="\n"); cells.writerow(["version","width","depth","strategy","cell_type","count"])
    for version,src in sources.items():
        for w,d in configs:
            folder=Path(version)/f"w{w}_d{d}";folder.mkdir(parents=True)
            args=["ghdl","-a","--std=08",str(src)]
            commands.write(json.dumps({"cwd":str(folder),"argv":args})+"\n");commands.flush()
            code,seconds=execute(args,folder,"ghdl_analyze.log")
            if not code:
                args=["ghdl","--synth","--std=08","--no-formal","--out=verilog",f"-gG_WIDTH={w}",f"-gG_DEPTH={d}","edu_fifo"]
                commands.write(json.dumps({"cwd":str(folder),"argv":args})+"\n");commands.flush()
                code,synth_seconds=execute(args,folder,"ghdl.log","edu_fifo.v")
                seconds=round(seconds+synth_seconds,6)
            for strategy,opts in strategies.items():
                row=dict(version=version,width=w,depth=d,storage_bits=w*d,strategy=strategy,ghdl_status="FAIL" if code else "PASS",mapping_status="NOT_RUN",ghdl_seconds=seconds)
                if not code:
                    name=f"{strategy}.json"
                    cmd="read_verilog edu_fifo.v; synth_xilinx -family xc7 -top edu_fifo -noiopad -noclkbuf " + " ".join(opts) + f"; check -assert; stat -tech xilinx; write_json {name}"
                    args=["yosys","-p",cmd];commands.write(json.dumps({"cwd":str(folder),"argv":args})+"\n");commands.flush()
                    status,row["mapping_seconds"]=execute(args,folder,f"{strategy}.log")
                    row["mapping_status"]="FAIL" if status else "PASS"
                    if not status:
                        try:
                            top=json.loads((folder/name).read_text())["modules"]["edu_fifo"]
                            types=Counter(x["type"] for x in top["cells"].values())
                            if any(t.startswith("$") for t in types): raise ValueError("Unmapped internal cells remain")
                            groups={"logic_lut_cells":lambda t:t in {f"LUT{i}" for i in range(1,7)}|{"LUT6_2"},"ff_cells":lambda t:t.startswith("FD"),"distributed_ram_cells":lambda t:t.startswith("RAM") and not t.startswith("RAMB"),"bram18_cells":lambda t:t.startswith("RAMB18"),"bram36_cells":lambda t:t.startswith("RAMB36"),"srl_cells":lambda t:t.startswith("SRL"),"carry4_cells":lambda t:t=="CARRY4","muxf_cells":lambda t:t.startswith("MUXF")}
                            row["total_cells"]=sum(types.values())
                            for k,pred in groups.items(): row[k]=sum(n for t,n in types.items() if pred(t))
                            row["other_cells"]=row["total_cells"]-sum(row[k] for k in groups)
                            for t,n in sorted(types.items()): cells.writerow([version,w,d,strategy,t,n])
                        except (ValueError,KeyError,OSError,TypeError) as e:
                            row["mapping_status"]="PARSE_FAIL";print(folder,strategy,e,flush=True)
                failed |= row["mapping_status"]!="PASS"
                writer.writerow(row);f.flush();c.flush()
                print(version,w,d,strategy,row["mapping_status"],flush=True)
raise SystemExit(int(failed))
PY
' 2>&1 | tee "$run/benchmark.log" || rc=$?
python3 scripts/verify_protected_digests.py
exit "$rc"
