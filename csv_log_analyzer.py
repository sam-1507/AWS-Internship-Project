#!/usr/bin/env python3
"""
Wrapper pointing to scripts/csv_log_analyzer.py
"""
import sys
import os

script_path = os.path.join(os.path.dirname(__file__), "scripts", "csv_log_analyzer.py")
if os.path.exists(script_path):
    with open(script_path, "r", encoding="utf-8") as f:
        code = compile(f.read(), script_path, 'exec')
        exec(code, globals())
else:
    print(f"Error: Could not locate scripts/csv_log_analyzer.py at {script_path}")
    sys.exit(1)
