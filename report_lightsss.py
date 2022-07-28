import sys

interval_map = [0, 1, 2, 3, 4, 5, 10, 15, 20, 30, 40, 50, 60]

def load_time(filename):
    data = dict([(key, []) for key in interval_map])
    index = 0
    with open(filename, "r") as f:
        interval = None
        hosttime = None
        for line in f:
            if "Host time spent:" in line:
                interval = interval_map[index]
                assert(interval is not None and hosttime is None)
                hosttime = int(line.split(":")[1].replace(",", "").replace("ms", "").strip())
                data[interval].append(hosttime)
                index = (index + 1) % len(interval_map)
                interval = None
                hosttime = None
    return data

def dump_to_csv(data, filename):
    keys = data.keys()
    with open(filename, "w") as f:
        for key in sorted(keys):
            hosttime = ",".join(map(str, data[key]))
            average_time=0
            average_time = sum(data[key]) / len(data[key])
            f.write(f"{key},{average_time:.2f}\n")
            # for t in data[key]:
            #     print(f"{key}S,{t}")

if __name__ == "__main__":
    data = load_time("single_core.log")
    dump_to_csv(data, "single_core.csv")
    data = load_time("dual_core.log")
    dump_to_csv(data, "dual_core.csv")

