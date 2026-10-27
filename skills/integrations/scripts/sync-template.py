#!/usr/bin/env python3
"""Recurring metric -> record sync; Python 3 standard library only.

Usage: python3 sync-template.py --config cfg.json --state state.json
       [--apply] [--force] [--today YYYY-MM-DD]

Demo config: {"source_file": "source.json", "sink_dir": "records"}
Demo source: {"2026-10": 12}. Paths are relative to the working directory.
Periods default to calendar months; config "period": "day" selects dates.
Replace only compute() and Sink to adapt this skeleton to another sync.

Exit codes: 0 ok/no-op, 1 sink failed, 2 bad input, 3 locked by another run.
Missing state starts a new sync; unreadable or malformed input is an error.
Dry runs never save state or write the sink. A temporary state lock serializes
all runs. Locks older than one hour are reclaimed; keep runs below that limit.
State is saved atomically after successful sink operations. Providers should
also use a period idempotency key, covering a crash between create and save.
"""
import argparse
import datetime
import json
import math
import os
from pathlib import Path
import sys
import tempfile
import time


def load_json(path):
    try:
        with open(path) as handle:
            return json.load(handle)
    except (OSError, ValueError) as error:
        raise ValueError(f"cannot read {path}: {error}") from error


def save_json(path, data):
    """Stage beside the destination so replacement stays on one filesystem."""
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent,
                                         prefix=path.name + ".", delete=False) as handle:
            temporary = Path(handle.name)
            json.dump(data, handle, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


# REPLACE: compute -- derive the WHOLE current value from your source each run.
# Keep this signature; do not accumulate deltas from previous runs.
def compute(cfg, period, today):
    source = cfg.get("source_file")
    if not isinstance(source, str) or not source:
        raise ValueError("config requires source_file")
    values = load_json(source)
    value = values.get(period) if isinstance(values, dict) else None
    if (type(value) not in (int, float)
            or (isinstance(value, float) and not math.isfinite(value))):
        raise ValueError(f"{source}: expected a finite number for {period}")
    return value
# REPLACE: end compute.


# REPLACE: Sink -- implement create(period, value) -> id, read(id) -> value,
# update(id, value), and is_locked(id) -> bool for your destination.
# Construction and reads must not write. Use the period as an idempotency key.
class Sink:
    def __init__(self, cfg):
        self.directory = Path(cfg["sink_dir"])

    def record_path(self, target_id):
        if not target_id or Path(target_id).name != target_id or target_id in (".", ".."):
            raise ValueError("invalid target id")
        return self.directory / (target_id + ".json")

    def create(self, period, value):
        target_id = "rec-" + period
        path = self.record_path(target_id)
        self.directory.mkdir(parents=True, exist_ok=True)
        # Deterministic ids prevent duplicates after a create/save interruption.
        # Exclusive creation also refuses to overwrite an untracked locked record.
        with path.open("x") as handle:
            json.dump({"period": period, "value": value, "locked": False}, handle)
        return target_id

    def read(self, target_id):
        return load_json(self.record_path(target_id))["value"]

    def update(self, target_id, value):
        path = self.record_path(target_id)
        record = load_json(path)
        record["value"] = value
        path.write_text(json.dumps(record) + "\n")

    def is_locked(self, target_id):
        return bool(load_json(self.record_path(target_id)).get("locked", False))
# REPLACE: end Sink.


def acquire_lock(path):
    while True:
        try:
            return os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            try:
                stale = path.stat()
                age = time.time() - stale.st_mtime
            except FileNotFoundError:
                continue
            if age <= 3600:
                raise
            try:
                current = path.stat()
                if ((current.st_dev, current.st_ino, current.st_mtime)
                        != (stale.st_dev, stale.st_ino, stale.st_mtime)):
                    continue
                # A tiny window remains; runs must stay well under one hour.
                path.unlink()
            except FileNotFoundError:
                continue
            print(f"warning: removed stale lock {path}", file=sys.stderr)


def sync(cfg, state, state_path, today, apply, force):
    if state.get("last_run") == today.isoformat() and not force:
        print("already ran today; use --force")
        return 0
    period = today.isoformat() if cfg.get("period") == "day" else today.strftime("%Y-%m")
    value = compute(cfg, period, today)
    try:
        sink = Sink(cfg)
        target_id = state.get("targets", {}).get(period)
        if target_id:
            if sink.is_locked(target_id):
                print(f"locked {period} {target_id}; not updating")
                return 0
            old = sink.read(target_id)
            if old == value:
                print(f"unchanged {period}")
            elif apply:
                sink.update(target_id, value)
                print(f"updated {period} {target_id}: {old} -> {value}")
            else:
                print(f"would update {period} {target_id}: {old} -> {value}")
        elif apply:
            target_id = sink.create(period, value)
            print(f"created {period} {target_id}: {value}")
        else:
            print(f"would create {period}: {value}")
    except Exception as error:
        print(f"sink failed: {error}", file=sys.stderr)
        return 1
    if apply:
        state.setdefault("targets", {})[period] = target_id
        state["last_run"] = today.isoformat()
        save_json(state_path, state)
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--today", default=datetime.date.today().isoformat())
    args = parser.parse_args(argv)
    lock_path = Path(str(args.state) + ".lock")
    descriptor = None
    owned_lock = None
    try:
        cfg = load_json(args.config)
        if not isinstance(cfg, dict):
            raise ValueError(f"{args.config}: config must be an object with source_file and sink_dir")
        for key in ("source_file", "sink_dir"):
            if not isinstance(cfg.get(key), str) or not cfg[key]:
                raise ValueError(f"{args.config}: config requires non-empty string {key}")
        if cfg.get("period", "month") not in ("month", "day"):
            raise ValueError(f"{args.config}: period must be month or day")
        today = datetime.date.fromisoformat(args.today)
        try:
            descriptor = acquire_lock(lock_path)
        except FileExistsError:
            print(f"another run holds {lock_path}", file=sys.stderr)
            return 3
        try:
            owned_lock = os.fstat(descriptor)
        except OSError:
            print(f"could not record the lock's identity; left {lock_path} in place "
                  "(reclaimed after one hour)", file=sys.stderr)
            return 2
        try:
            with args.state.open() as handle:
                state = json.load(handle)
        except FileNotFoundError:
            state = {}
        except (OSError, ValueError) as error:
            raise ValueError(f"cannot read {args.state}: {error}") from error
        if (not isinstance(state, dict) or not isinstance(state.get("targets", {}), dict)
                or any(not isinstance(key, str) or not isinstance(value, str) or not value
                       for key, value in state.get("targets", {}).items())):
            raise ValueError(f"{args.state}: expected an object with targets mapping periods to ids")
        return sync(cfg, state, args.state, today, args.apply, args.force)
    except (OSError, ValueError) as error:
        print(f"bad input: {error}", file=sys.stderr)
        return 2
    finally:
        if descriptor is not None:
            os.close(descriptor)
        if owned_lock is not None:
            try:
                current = lock_path.stat()
                if (current.st_dev, current.st_ino) == (owned_lock.st_dev, owned_lock.st_ino):
                    lock_path.unlink()
            except FileNotFoundError:
                pass


if __name__ == "__main__":
    raise SystemExit(main())
