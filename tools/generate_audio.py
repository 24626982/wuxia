"""Generate original, deterministic music and UI sound assets (stdlib only)."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
DEST = Path(__file__).resolve().parents[1] / "assets" / "audio"


def hz(note):
    return 440 * 2 ** ((note - 69) / 12)


def write(name, samples):
    with wave.open(str(DEST / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b"".join(struct.pack("<h", round(max(-1, min(1, x)) * 32767)) for x in samples))


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    duration = 32
    music = [0.0] * (RATE * duration)
    rng = random.Random(47)

    def note(start, pitch, length, gain, flute=False):
        frequency = hz(pitch)
        phase = rng.random() * math.tau
        for i in range(int(length * RATE)):
            t = i / RATE
            attack = min(1, t / (0.09 if flute else 0.006))
            release = min(1, (length - t) / 0.18)
            envelope = attack * release * math.exp(-t * (0.65 if flute else 3.0))
            angle = math.tau * frequency * t + phase
            if flute:
                angle += 0.018 * math.sin(math.tau * 4.5 * t)
                tone = math.sin(angle) + 0.12 * math.sin(2 * angle)
            else:
                tone = math.sin(angle) + 0.3 * math.sin(2 * angle) + 0.12 * math.sin(3 * angle)
            sample = tone * envelope * gain
            position = int(start * RATE) + i
            music[position % len(music)] += sample
            # Quiet echoes wrap around the loop for a continuous ambience.
            music[(position + int(0.375 * RATE)) % len(music)] += sample * 0.19
            music[(position + int(0.75 * RATE)) % len(music)] += sample * 0.08

    melody = [74, 77, 81, 79, 77, 74, 72, 69, 72, 74, 77, 79, 81, 77, 74, 72,
              74, 77, 79, 84, 81, 79, 77, 74, 72, 69, 72, 77, 74, 72, 69, 72]
    chords = [(50, 57, 62), (48, 55, 60), (53, 60, 65), (50, 57, 62)]
    for bar in range(16):
        chord = chords[(bar // 2) % 4]
        for beat in range(4):
            note(bar * 2 + beat * 0.5, chord[beat % 3] + 12, 1.8, 0.12)
        note(bar * 2, chord[0], 2.8, 0.13, flute=True)
        for beat in range(2):
            note(bar * 2 + beat, melody[bar * 2 + beat], 0.95, 0.17, flute=True)
    peak = max(abs(x) for x in music)
    write("wuxia_theme.wav", [x * 0.8 / peak for x in music])
    click = []
    for i in range(int(0.14 * RATE)):
        t = i / RATE
        envelope = min(1, t / 0.003) * math.exp(-t * 38) * min(1, (0.14 - t) / 0.025)
        click.append(0.55 * envelope * (math.sin(math.tau * 880 * t) + 0.24 * math.sin(math.tau * 1320 * t)))
    write("choice_click.wav", click)


if __name__ == "__main__":
    main()
