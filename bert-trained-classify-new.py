from transformers import BertTokenizer, BertForSequenceClassification
import torch

MODEL_PATH = "./bert-privacy-law-model"

tokenizer = BertTokenizer.from_pretrained(MODEL_PATH)
model = BertForSequenceClassification.from_pretrained(MODEL_PATH)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

model.eval()  # set model to evaluation mode

import pandas as pd

input_csv = "test.csv"

df = pd.read_csv(input_csv)

# Combine title and body into one text field
def combine_text(row):
    title = row["title"] if pd.notna(row["title"]) else ""
    body = row["body"] if pd.notna(row["body"]) else ""
    return f"{title} {body}".strip()

df["text"] = df.apply(combine_text, axis=1)

MAX_LENGTH = 512  # adjust based on your fine-tuning

inputs = tokenizer(
    df["text"].tolist(),
    max_length=MAX_LENGTH,
    padding=True,
    truncation=True,
    return_tensors="pt"
)

batch_size = 4
predictions = []

with torch.no_grad():
    for start in range(0, len(df), batch_size):
        batch_texts = df["text"].iloc[start:start+batch_size].tolist()
        enc = tokenizer(
            batch_texts,
            truncation=True,
            padding=True,
            max_length=512,
            return_tensors="pt"
        ).to(device)

        outputs = model(**enc)
        preds = torch.argmax(outputs.logits, dim=-1)
        predictions.extend(preds.cpu().numpy())

df["predicted_label"] = predictions
df.to_csv("predictions.csv", index=False)
print(df.head())