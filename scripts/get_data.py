"""Download the three datasets used by HUSH into DATA_DIR (default ~/data, outside the repo).

    python scripts/get_data.py            # all
    python scripts/get_data.py mnist shd  # some

MNIST   : torchvision mirror.
SHD     : Spiking Heidelberg Digits, HDF5 from zenkelab.org (Cramer et al., TNNLS 2020).
N-MNIST : via tonic (Orchard et al. 2015).
"""

import gzip
import os
import shutil
import sys
import urllib.request
from pathlib import Path

DATA_DIR = Path(os.environ.get("DATA_DIR", Path.home() / "data"))


def get_mnist():
    import torchvision
    for train in (True, False):
        torchvision.datasets.MNIST(DATA_DIR, train=train, download=True)
    print("MNIST ok")


def get_shd():
    d = DATA_DIR / "shd"
    d.mkdir(parents=True, exist_ok=True)
    for split in ("train", "test"):
        h5 = d / f"shd_{split}.h5"
        if h5.exists():
            continue
        gz = d / f"shd_{split}.h5.gz"
        url = f"https://zenkelab.org/datasets/shd_{split}.h5.gz"
        print("downloading", url)
        urllib.request.urlretrieve(url, gz)
        with gzip.open(gz, "rb") as fi, open(h5, "wb") as fo:
            shutil.copyfileobj(fi, fo)
        gz.unlink()
    print("SHD ok")


def get_nmnist():
    import tonic
    for train in (True, False):
        tonic.datasets.NMNIST(save_to=str(DATA_DIR), train=train)
    print("N-MNIST ok")


if __name__ == "__main__":
    which = sys.argv[1:] or ["mnist", "shd", "nmnist"]
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    for name in which:
        {"mnist": get_mnist, "shd": get_shd, "nmnist": get_nmnist}[name]()
