# Radar Config (`radar_config.json`)

`files/radar.py` builds the `pupradar_capture` command from `radar_config.json`, which sits in `fc_version_3-0/`, one level above `files/`. Editing this file changes the radar settings without touching any Python.

## Template

```json
{
    "binary": "~/Drone_Integration_Program/SDR_main-main/linux/build-arm64/pupradar_capture",
    "firmware": "~/Drone_Integration_Program/SDR_main-main/linux/firmware/SDR_USB_FW.hex",
    "output_dir": "~/SDR-data/1609_intergration",
    "use_sudo": true,
    "settle_time": 5,
    "buffer_time": 1,
    "capture": {
        "duration": 1,
        "fc_low": 24.00e9,
        "fc_high": 26.00e9,
        "sweep_time": 1,
        "samp_num": 1,
        "rx": 4
    },
    "flush": {
        "duration": 1,
        "fc_low": 24.00e9,
        "fc_high": 26.00e9,
        "sweep_time": 1,
        "samp_num": 1,
        "rx": 4
    }
}
```

## Keys

| Key | Type | Used for |
|---|---|---|
| `binary` | string | Path to the `pupradar_capture` executable. `~` is allowed. |
| `firmware` | string | Passed as `--firmware`. |
| `output_dir` | string | Folder that `--out` files are written to. Created if it doesn't exist. |
| `use_sudo` | `true` / `false` | Adds `sudo` in front of the command. Optional: if left out, it counts as `false`. |
| `settle_time` | number | Seconds to wait after the flush finishes before starting the capture. |
| `buffer_time` | number | Seconds after a capture finishes before another capture can be requested. |
| `capture` | object | Settings used for the capture run. |
| `flush` | object | Settings used for the flush run before each capture. |

The `capture` and `flush` objects each need these keys:

| Key | Command-line flag |
|---|---|
| `duration` | `--duration` |
| `fc_low` | `--fc-low` |
| `fc_high` | `--fc-high` |
| `sweep_time` | `--sweep-time` |
| `samp_num` | `--samp-num` |
| `rx` | `--rx` |

Every key except `use_sudo` is required. If one is missing or misspelled, `Radar` fails with a `KeyError` naming that key. Extra keys are ignored.

## Output file names

- A capture writes to `<output_dir>/<capture_count>_time_<runtime>`. Any `.` in the runtime is replaced with `_`, so capture 3 at runtime `12.5` becomes `3_time_12_5`.
- The flush always writes to `<output_dir>/flush`.

## JSON syntax rules

- **Use double quotes only.** `"binary"` works, but `'binary'` doesn't.
- **Don't put a comma after the last item** in a `{}` or `[]`.
- **Use lowercase `true`, `false` and `null`**, not Python's `True`, `False` or `None`.
- **Comments aren't allowed** (`//` or `#`). If you need a note, add a key such as `"_note": "..."`; it will be ignored.
- **Write numbers without quotes.** `24.00e9`, `1` and `0.5` are fine. Leading zeros like `01` aren't allowed.

## Numbers vs strings

Numbers are converted with `str()` before being passed to the program:

| In the JSON | What the program receives |
|---|---|
| `"fc_low": 24.00e9` | `--fc-low 24000000000.0` |
| `"fc_low": "24.00e9"` | `--fc-low 24.00e9` |

Both forms work with `radar.py`. Use the string form if you want the program to receive the value exactly as you typed it.

## Checking the file

From `fc_version_3-0/`, run:

```bash
python3 -m json.tool radar_config.json
```

This prints the parsed config if it's valid. Otherwise it gives the line and column of the syntax error.
