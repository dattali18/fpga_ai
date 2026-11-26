def next_state(q: int, d: int, reset: bool, enable: bool) -> int:
    if not (0 <= q <= 255 and 0 <= d <= 255):
        raise ValueError("8-bit values required")
    return 0 if reset else d if enable else q

if __name__ == "__main__":
    assert next_state(7, 42, True, True) == 0
    assert next_state(7, 42, False, False) == 7
    assert next_state(7, 42, False, True) == 42
    print("PASS: reference self-check")
