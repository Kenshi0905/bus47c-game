"""Build original beta cues from oscillators and deterministic filtered noise.

No audio from the linked commercial preview or tutorial is copied. The tutorial
informs the arrangement: space, close detail, silence and a shared creature motif.
Run with Python and numpy. Outputs PCM16 WAV at 44.1 kHz.
"""
from pathlib import Path
import json
import math
import wave
import numpy as np

RATE = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game/assets/audio"
REPORT = ROOT / "work/audio08/original-cue-report.json"
RNG = np.random.default_rng(470803)


def noise(n, low=25, high=2000, slope=0.55):
    frequencies = np.fft.rfftfreq(n, 1 / RATE)
    spectrum = np.fft.rfft(RNG.normal(0, 1, n))
    gain = np.maximum(frequencies, 1) ** -slope
    gain *= (1 - np.exp(-(frequencies / low) ** 4)) * np.exp(-(frequencies / high) ** 4)
    output = np.fft.irfft(spectrum * gain, n=n)
    return output / max(np.std(output), 1e-8)


def fade(signal, attack, release):
    output = signal.copy()
    a = min(int(attack * RATE), len(output) // 2)
    r = min(int(release * RATE), len(output) // 2)
    output[:a] *= np.sin(np.linspace(0, math.pi / 2, a)) ** 2
    output[-r:] *= np.cos(np.linspace(0, math.pi / 2, r)) ** 2
    return output


def echo(signal, taps):
    output = signal.copy()
    for seconds, gain in taps:
        shift = int(seconds * RATE)
        if 0 < shift < len(signal):
            output[shift:] += signal[:-shift] * gain
    return output


def write(name, signal, peak_limit, loop=False, description=""):
    # Retain relative cue dynamics. Only reduce a signal that exceeds its ceiling.
    signal = np.asarray(signal, dtype=np.float64)
    signal -= np.mean(signal, axis=0)
    maximum = float(np.max(np.abs(signal)))
    if maximum > peak_limit:
        signal *= peak_limit / maximum
    encoded = np.round(np.clip(signal, -0.99, 0.99) * 32767).astype("<i2")
    with wave.open(str(OUT / (name + ".wav")), "wb") as output:
        output.setnchannels(1 if signal.ndim == 1 else signal.shape[1])
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(encoded.tobytes())
    return {
        "file": name + ".wav", "seconds": len(signal) / RATE,
        "channels": 1 if signal.ndim == 1 else signal.shape[1], "loop": loop,
        "peak_dbfs": round(20 * np.log10(max(np.max(np.abs(signal)), 1e-9)), 2),
        "rms_dbfs": round(20 * np.log10(max(np.sqrt(np.mean(signal ** 2)), 1e-9)), 2),
        "description": description,
    }


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    reports = []
    # Seamless 24 s bed. Noise and every modulation are periodic at loop length.
    duration = 24
    n = RATE * duration
    t = np.arange(n) / RATE
    mist = noise(n, 90, 1800, 0.7)
    distant = noise(n, 28, 220, 0.8)
    pulse = 0.62 + 0.22 * np.sin(2 * math.pi * t / duration)
    phase = 2 * math.pi * (43 * t + 0.075 * np.sin(2 * math.pi * t / duration))
    tone = np.sin(phase) * 0.023 + np.sin(2 * math.pi * 61 * t) * 0.011
    left = mist * 0.025 * pulse + distant * 0.018 + tone
    right = np.roll(mist, int(RATE * 0.083)) * 0.024 * (1.1 - pulse * 0.2) + distant * 0.017 + tone * 0.94
    bed = np.column_stack((left, right))
    # Tiny circular endpoint correction eliminates a sample discontinuity.
    seam = bed[-1] - bed[0]
    bed -= np.linspace(0, 1, n)[:, None] * seam[None, :]
    reports.append(write("beta_path_bed", bed, 0.29, True, "Wide, low wind and a distant beating drone. Loop with a 2 s game-side fade."))

    duration = 7.2
    n = int(RATE * duration)
    t = np.arange(n) / RATE
    swell = np.sin(math.pi * np.clip(t / duration, 0, 1)) ** 1.8
    fibers = noise(n, 150, 1600, 0.35) * 0.045
    pressure = np.sin(2 * math.pi * (39 * t + 0.9 * t * t)) * 0.065
    tremor = np.sin(2 * math.pi * 87.5 * t + 0.9 * np.sin(2 * math.pi * 0.4 * t)) * 0.025
    tension = fade((fibers + pressure + tremor) * swell, 0.3, 1.2)
    tension = echo(tension, [(0.21, 0.17), (0.53, 0.1)])
    reports.append(write("beta_tension", tension, 0.44, False, "Restrained pressure swell that releases into quiet, not an automatic scare."))

    duration = 3.6
    n = int(RATE * duration)
    t = np.arange(n) / RATE
    low = np.sin(2 * math.pi * (71 * t - 5.5 * t * t)) * np.exp(-t * 1.6) * 0.31
    texture = noise(n, 80, 1400, 0.65) * np.exp(-t * 2.6) * 0.11
    death = echo(fade(low + texture, 0.008, 0.8), [(0.19, 0.22), (0.43, 0.15), (0.87, 0.09)])
    reports.append(write("beta_death", fade(death, 0.005, 0.65), 0.56, False, "Descending low impact with a short hollow tail, leaving the failure menu quiet."))

    duration = 1.1
    n = int(RATE * duration)
    t = np.arange(n) / RATE
    impact = noise(n, 45, 3200, 0.25) * np.exp(-t * 9) * 0.22
    scrape = noise(n, 480, 2300, 0.15) * np.exp(-np.maximum(t - 0.08, 0) * 5) * 0.07
    body = np.sin(2 * math.pi * (98 * t - 23 * t * t)) * np.exp(-t * 5) * 0.25
    scare = echo(fade(impact + scrape + body, 0.004, 0.35), [(0.055, 0.15), (0.16, 0.13)])
    reports.append(write("beta_scare", fade(scare, 0.004, 0.25), 0.68, False, "Brief textured attack with low weight, band limited to avoid a piercing screech."))

    duration = 0.9
    n = int(RATE * duration)
    t = np.arange(n) / RATE
    motion = noise(n, 120, 2200, 0.4) * 0.095 * np.sin(math.pi * t / duration) ** 0.8
    dip = np.sin(2 * math.pi * (180 * t - 72 * t * t)) * 0.06
    clicks = np.zeros(n)
    # Two small dry ticks then a longer scrape identify the watcher.
    for seconds, amount in [(0.07, 0.1), (0.18, 0.08), (0.48, 0.14)]:
        start = int(seconds * RATE)
        length = min(int(RATE * 0.13), n - start)
        click_t = np.arange(length) / RATE
        clicks[start:start + length] += noise(length, 300, 1700, 0.3) * np.exp(-click_t * 45) * amount
    reports.append(write("beta_tree_zip", fade(motion + dip + clicks, 0.025, 0.25), 0.49, False, "Mono rush and two-short-one-long wooden motif for positional tree movement."))

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(reports, indent=2))


if __name__ == "__main__":
    main()
