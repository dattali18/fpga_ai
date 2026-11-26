#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1 GIT_OPTIONAL_LOCKS=0
[[ "$(pwd -P)" == "$(git rev-parse --show-toplevel)" && "$(basename "$PWD")" == fpga_ai ]] || { echo 'Run from fpga_ai root' >&2; exit 1; }
base=experiments/edu_fifo
for p in experiments "$base" "$base/rtl" "$base/tb" "$base/build" "$base/golden.py" "$base/rtl/edu_fifo.vhd" "$base/tb/tb_edu_fifo.vhd" scripts scripts/verify_protected_digests.py; do
    [[ ! -L "$p" ]] || { echo "Symlink refused: $p" >&2; exit 1; }
done
python3 scripts/verify_protected_digests.py
mkdir -p "$base/build"
run=$(mktemp -d "$base/build/benchmark.XXXXXXXX")
echo "Results: $run"
git rev-parse HEAD > "$run/git_head.txt"
git status --short > "$run/git_status.txt"
docker image inspect fpga_ai-toolchain:m1-arm64 --format '{{.Id}}' > "$run/image_id.txt"
rc=0
docker run --rm --platform linux/arm64 -v "$PWD:/workspace" -w "/workspace/$run" fpga_ai-toolchain:m1-arm64 bash -euo pipefail -c '
export PYTHONDONTWRITEBYTECODE=1
mkdir -p tmp
export TMPDIR="$PWD/tmp"
ghdl --version > tools.txt
yosys -V >> tools.txt
python3 --version >> tools.txt
python3 - <<"PY"
import sys, hashlib
from pathlib import Path
sys.path.insert(0, "../..")
from golden import vectors, main
main()
configs = sorted({(32,d) for d in (1,4,8,16,32,64,128,256,3,15,31,63,127)} | {(w,32) for w in (8,16,32,64,128)} | {(1,1),(8,1),(8,3),(8,4),(16,5),(32,8)})
Path("vectors").mkdir()
with open("configs.tsv", "w") as f:
    for w,d in configs:
        rows = vectors(w,d)
        tag = f"w{w}_d{d}"
        Path(f"vectors/{tag}.txt").write_text("\n".join(rows)+"\n")
        f.write(f"{w}\t{d}\t{len(rows)}\n")
with open("source_sha256.txt","w") as f:
    for p in ("../../golden.py","../../rtl/edu_fifo.vhd","../../tb/tb_edu_fifo.vhd"):
        f.write(f"{hashlib.sha256(Path(p).read_bytes()).hexdigest()}  {p}\n")
PY
ghdl -a --std=08 ../../rtl/edu_fifo.vhd ../../tb/tb_edu_fifo.vhd
ghdl -e --std=08 tb_edu_fifo
python3 - <<"PY"
import csv, json, subprocess, time
from pathlib import Path

def execute(args, log, stdout=None):
    start=time.perf_counter()
    with open(log,"w") as err:
        if stdout:
            with open(stdout,"w") as out:
                result=subprocess.run(args,stdout=out,stderr=err)
        else:
            result=subprocess.run(args,stdout=err,stderr=subprocess.STDOUT)
    return result.returncode, round(time.perf_counter()-start,6)

def stats(path):
    data=json.loads(Path(path).read_text())
    return next(iter(data["modules"].values()))

fields="width depth storage_bits oracle_cycles simulation synthesis memory_view logic_view sim_seconds ghdl_seconds memory_seconds logic_seconds memory_cells memory_objects memory_bits logic_cells logic_wire_bits logic_mux_cells logic_dffe_cells logic_sdffe_cells".split()
failed=False
with open("benchmark.csv","w",newline="") as f, open("cell_types.csv","w",newline="") as c:
    writer=csv.DictWriter(f,fieldnames=fields);writer.writeheader()
    cells=csv.writer(c);cells.writerow(["width","depth","view","cell_type","count"])
    for line in Path("configs.tsv").read_text().splitlines():
        w,d,n=map(int,line.split());tag=f"w{w}_d{d}"
        row=dict(width=w,depth=d,storage_bits=w*d,oracle_cycles=n,simulation="NOT_RUN",synthesis="NOT_RUN",memory_view="NOT_RUN",logic_view="NOT_RUN")
        code,row["sim_seconds"]=execute(["ghdl","-r","--std=08","tb_edu_fifo",f"-gG_WIDTH={w}",f"-gG_DEPTH={d}",f"-gG_VECTOR_FILE=vectors/{tag}.txt","--assert-level=error"],f"sim_{tag}.log")
        row["simulation"]="FAIL" if code else "PASS"
        code,row["ghdl_seconds"]=execute(["ghdl","--synth","--std=08","--no-formal","--out=verilog",f"-gG_WIDTH={w}",f"-gG_DEPTH={d}","edu_fifo"],f"ghdl_{tag}.log",f"{tag}.v")
        row["synthesis"]="FAIL" if code else "PASS"
        if not code:
            prefix=f"read_verilog {tag}.v; hierarchy -check -top edu_fifo; proc; opt; "
            for view,passes in (("memory","memory -nomap; opt"),("logic","memory; opt")):
                # stat JSON is retained separately from full tool logs.
                name=f"{view}_{tag}.json"
                cmd=prefix+passes+f"; check -assert; tee -o {name} stat -json; write_json {view}_{tag}_netlist.json"
                code,row[f"{view}_seconds"]=execute(["yosys","-p",cmd],f"{view}_{tag}.log")
                row[f"{view}_view"]="FAIL" if code else "PASS"
                if not code:
                    try:
                        s=stats(name);types=s["num_cells_by_type"]
                        for k,v in sorted(types.items()): cells.writerow([w,d,view,k,v])
                        row[f"{view}_cells"]=s["num_cells"]
                        if view=="memory":
                            net=json.loads(Path(f"{view}_{tag}_netlist.json").read_text())["modules"]["edu_fifo"]
                            memories=[cell for cell in net["cells"].values() if cell["type"] in ("$mem", "$mem_v2")]
                            row.update(memory_objects=len(memories),memory_bits=sum(int(m["parameters"]["WIDTH"],2)*int(m["parameters"]["SIZE"],2) for m in memories))
                        else:
                            row.update(logic_wire_bits=s["num_wire_bits"],logic_mux_cells=types.get("$mux",0),logic_dffe_cells=types.get("$dffe",0),logic_sdffe_cells=types.get("$sdffe",0))
                    except (ValueError,KeyError,StopIteration,OSError) as e:
                        row[f"{view}_view"]="PARSE_FAIL";print(tag,view,e,flush=True)
        failed |= any(row[k]!="PASS" for k in ("simulation","synthesis","memory_view","logic_view"))
        writer.writerow(row);f.flush();c.flush()
        print(tag,*(row[k] for k in ("simulation","synthesis","memory_view","logic_view")),flush=True)
raise SystemExit(int(failed))
PY
' 2>&1 | tee "$run/benchmark.log" || rc=$?
python3 scripts/verify_protected_digests.py
exit "$rc"
