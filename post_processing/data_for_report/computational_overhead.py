import time, sys, csv, os, subprocess

pid = int(sys.argv[1]) if len(sys.argv) > 1 else 0  # use 0 for the idle phase
phase = sys.argv[2] if len(sys.argv) > 2 else "test"
filename = f"overhead_{phase}_{time.strftime('%Y%m%d_%H%M%S')}.csv"
CLK = os.sysconf("SC_CLK_TCK")


def sys_ticks():
    with open("/proc/stat") as f:
        v = list(map(int, f.readline().split()[1:]))
    return sum(v), v[3] + v[4]  # total, idle+iowait


def proc_ticks():
    with open(f"/proc/{pid}/stat") as f:
        x = f.read().rsplit(")", 1)[1].split()
    return int(x[11]) + int(x[12])  # utime + stime


def proc_rss_mb():
    with open(f"/proc/{pid}/status") as f:
        for line in f:
            if line.startswith("VmRSS"):
                return int(line.split()[1]) / 1000
    return 0


def mem_used_pct():
    m = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, v = line.split(":")
            m[k] = int(v.split()[0])
    return 100 * (m["MemTotal"] - m["MemAvailable"]) / m["MemTotal"]


def temp_c():
    with open("/sys/class/thermal/thermal_zone0/temp") as f:
        return int(f.read()) / 1000


def throttled():
    try:
        return (
            subprocess.run(
                ["vcgencmd", "get_throttled"], capture_output=True, text=True
            )
            .stdout.strip()
            .split("=")[1]
        )
    except Exception:
        return "NA"


with open(filename, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(
        [
            "time",
            "elapsed_s",
            "sys_cpu_pct",
            "proc_cpu_pct",
            "proc_rss_mb",
            "mem_used_pct",
            "temp_c",
            "throttled",
        ]
    )
    start = t_prev = time.time()
    tot_prev, idle_prev = sys_ticks()
    p_prev = proc_ticks() if pid else 0
    print(f"Logging to {filename}, press Ctrl+C to stop")
    try:
        while True:
            time.sleep(1)
            now = time.time()
            tot, idle = sys_ticks()
            sys_cpu = 100 * (1 - (idle - idle_prev) / max(tot - tot_prev, 1))
            if pid:
                p = proc_ticks()
                proc_cpu = 100 * (p - p_prev) / CLK / (now - t_prev)
                rss = proc_rss_mb()
                p_prev = p
            else:
                proc_cpu, rss = "", ""
            w.writerow(
                [
                    f"{now:.3f}",
                    f"{now - start:.1f}",
                    f"{sys_cpu:.1f}",
                    f"{proc_cpu:.1f}" if pid else "",
                    f"{rss:.1f}" if pid else "",
                    f"{mem_used_pct():.1f}",
                    f"{temp_c():.1f}",
                    throttled(),
                ]
            )
            f.flush()
            tot_prev, idle_prev, t_prev = tot, idle, now
    except (KeyboardInterrupt, FileNotFoundError):
        print(f"Stopped. Saved {filename}")
