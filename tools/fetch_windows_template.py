"""Fetch only Windows x64 templates from the official pinned Godot TPZ.

Uses HTTP byte ranges so the other platforms (over 1 GB) are not downloaded.
ZipFile checks each extracted member's CRC. HTTPS supplies transport integrity.
"""
import argparse
import hashlib
import io
import json
import pathlib
import urllib.request
import zipfile

VERSION = "4.7.2-stable"
URL = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}/Godot_v{VERSION}_export_templates.tpz"


class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        self.url = url
        self.position = 0
        request = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "Bus47C-build"})
        with urllib.request.urlopen(request, timeout=90) as response:
            self.size = int(response.headers["Content-Length"])
        self.transferred = 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.size + offset
        if self.position < 0:
            raise ValueError("Negative archive offset")
        return self.position

    def read(self, count=-1):
        count = min(self.size - self.position, count if count >= 0 else self.size)
        if count <= 0:
            return b""
        if count > 150_000_000:
            raise ValueError("Refusing an unexpectedly large template member")
        end = self.position + count - 1
        request = urllib.request.Request(self.url, headers={
            "User-Agent": "Bus47C-build", "Range": f"bytes={self.position}-{end}"})
        with urllib.request.urlopen(request, timeout=120) as response:
            expected = f"bytes {self.position}-{end}/{self.size}"
            if response.status != 206 or response.headers.get("Content-Range") != expected:
                raise RuntimeError("The host did not honour the requested byte range; full download was not attempted")
            data = response.read(count + 1)
        if len(data) != count:
            raise RuntimeError("Incomplete archive range")
        self.position += count
        self.transferred += count
        return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", default="work/export-templates/4.7.2.stable")
    args = parser.parse_args()
    destination = pathlib.Path(args.destination).resolve()
    destination.mkdir(parents=True, exist_ok=True)
    report = {"version": VERSION, "source": URL, "files": {}}
    remote = RemoteZip(URL)
    with zipfile.ZipFile(remote) as archive:
        for basename in ["windows_release_x86_64.exe", "windows_debug_x86_64.exe"]:
            entry = archive.getinfo("templates/" + basename)
            content = archive.read(entry)
            if not content.startswith(b"MZ"):
                raise RuntimeError("Template was not a Windows executable")
            (destination / basename).write_bytes(content)
            report["files"][basename] = {"sha256": hashlib.sha256(content).hexdigest(), "bytes": len(content), "zip_crc32": f"{entry.CRC:08x}"}
            print(f"Fetched {basename}: {len(content):,} bytes")
    report["downloaded_bytes"] = remote.transferred
    (destination / "template-source.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Downloaded {remote.transferred:,} archive bytes instead of {remote.size:,}")


if __name__ == "__main__":
    main()
