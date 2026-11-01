#!/usr/bin/env python3
"""Inspect a JSONL game journal without Godot; does not execute game rules."""
import argparse
import collections
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('journal', type=Path)
parser.add_argument('--sequence', type=int, help='Print decision candidates and post-action state at this sequence')
parser.add_argument('--house', help='Filter decision listing by house')
parser.add_argument('--last', type=int, default=12)
args = parser.parse_args()
actions = collections.Counter()
houses = collections.Counter()
recent = collections.deque(maxlen=args.last)
last = None
found = False
with args.journal.open(encoding='utf-8') as stream:
    for line in stream:
        record = json.loads(line)
        if record['kind'] == 'failure':
            print('FAILURE:', json.dumps(record.get('errors')))
        if record['kind'] != 'decision':
            continue
        last = record
        decision = record['decision']
        actions[decision['chosen']['type']] += 1
        houses[decision['house']] += 1
        if args.sequence == record['sequence']:
            print(json.dumps(record, indent=2))
            found = True
        if not args.house or decision['house'] == args.house:
            recent.append({k: record[k] for k in ('sequence', 'event')})
if args.sequence is not None:
    if not found:
        parser.error('Sequence not found')
else:
    print(json.dumps({'actions': actions, 'houses': houses, 'recent': list(recent),
                     'final_state': last['snapshot']['state'] if last else None}, indent=2))
