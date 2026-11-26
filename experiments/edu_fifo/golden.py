"""Independent queue-based oracle and deterministic stimulus generator."""
from collections import deque
from dataclasses import dataclass
from pathlib import Path
import argparse
import random

CONFIGS = ((1, 1), (8, 1), (8, 3), (8, 4), (16, 5), (32, 8))

@dataclass(frozen=True)
class Observation:
    ready: int
    valid: int
    data: int

class Fifo:
    def __init__(self, width: int, depth: int) -> None:
        if min(width, depth) < 1:
            raise ValueError('positive width and depth required')
        self.width = width
        self.depth = depth
        self.queue: deque[int] = deque()

    def step(self, rst: int, valid: int, data: int, ready: int) -> Observation:
        if not 0 <= data < 2**self.width:
            raise ValueError('word out of range')
        if rst:
            self.queue.clear()
            return Observation(0, 0, 0)
        readable = bool(self.queue)
        pop = readable and bool(ready)
        writable = len(self.queue) < self.depth or pop
        obs = Observation(int(writable), int(readable), self.queue[0] if readable else 0)
        if pop:
            self.queue.popleft()
        if valid and writable:
            self.queue.append(data)
        return obs


def vectors(width: int, depth: int, seed: int = 20261126) -> list[str]:
    rng = random.Random(seed + width * 1000 + depth)
    fifo = Fifo(width, depth)
    rows: list[str] = []
    pending: int | None = None
    def emit(rst: int, offer: bool, ready: int) -> None:
        nonlocal pending
        if rst:
            pending = None
        elif pending is None and offer:
            pending = rng.getrandbits(width)
        valid = int(pending is not None)
        data = pending if pending is not None else 0
        obs = fifo.step(rst, valid, data, ready)
        rows.append(f'{rst} {valid} {data:0{width}b} {ready} {obs.ready} {obs.valid} {obs.data:0{width}b}')
        if valid and obs.ready:
            pending = None
    emit(1, False, 0)
    emit(0, False, 1)
    for _ in range(depth + 4): emit(0, True, 0)
    for _ in range(3 * depth + 4): emit(0, True, 1)
    for _ in range(depth + 3): emit(0, False, 1)
    for _ in range(depth): emit(0, True, 0)
    emit(1, False, 1)
    emit(0, False, 1)
    for i in range(2000):
        emit(int(i % 197 == 196), rng.random() < 0.65, int(rng.random() < 0.55))
    for _ in range(depth + 3): emit(0, False, 1)
    assert not fifo.queue and pending is None
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    f = Fifo(8, 1)
    assert f.step(1, 1, 23, 1) == Observation(0, 0, 0)
    assert f.step(0, 1, 42, 1) == Observation(1, 0, 0)
    assert f.step(0, 1, 13, 0) == Observation(0, 1, 42)
    assert f.step(0, 1, 13, 1) == Observation(1, 1, 42)
    assert f.step(0, 0, 0, 1) == Observation(1, 1, 13)
    assert f.step(0, 0, 0, 1) == Observation(1, 0, 0)
    for width, depth in CONFIGS:
        rows = vectors(width, depth)
        if args.output is not None:
            args.output.mkdir(parents=True, exist_ok=True)
            (args.output / f'w{width}_d{depth}.txt').write_text('\n'.join(rows) + '\n')
        print(f'PASS: width={width} depth={depth}: {len(rows)} oracle cycles')

if __name__ == '__main__':
    main()
