"""Speaks lines with AI4Bharat's Indic Parler-TTS (runs on this computer, no internet after the download).

    python parler_voice.py lines.json out_dir

lines.json: [{"id": "x", "text": "...", "speaker": "Rohit", "style": "worried, slightly fast"}, ...]
Writes out_dir/<id>.wav (mono). Lines already spoken are skipped.
"""

import json
import pathlib
import sys

import soundfile as sf
import torch
from parler_tts import ParlerTTSForConditionalGeneration
from transformers import AutoTokenizer

MODEL = "ai4bharat/indic-parler-tts"


def describe(speaker, style):
    return (f"{speaker}'s voice is clear and natural, {style}, with a very close recording that has no background "
            f"noise.")


def main(lines_file, out_dir):
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    lines = json.loads(pathlib.Path(lines_file).read_text(encoding="utf-8"))
    todo = [l for l in lines if not (out / f"{l['id']}.wav").exists()]
    if not todo:
        return
    torch.set_num_threads(max(1, torch.get_num_threads()))
    model = ParlerTTSForConditionalGeneration.from_pretrained(MODEL).eval()
    tok = AutoTokenizer.from_pretrained(MODEL)
    dtok = AutoTokenizer.from_pretrained(model.config.text_encoder._name_or_path)
    for i, l in enumerate(todo):
        d = dtok(describe(l["speaker"], l["style"]), return_tensors="pt")
        p = tok(l["text"], return_tensors="pt")
        with torch.inference_mode():
            audio = model.generate(input_ids=d.input_ids, attention_mask=d.attention_mask,
                                   prompt_input_ids=p.input_ids, prompt_attention_mask=p.attention_mask)
        sf.write(out / f"{l['id']}.wav", audio.cpu().numpy().squeeze(), model.config.sampling_rate)
        print(f"{i + 1}/{len(todo)} {l['id']}", flush=True)


if __name__ == "__main__":
    main(*sys.argv[1:3])
