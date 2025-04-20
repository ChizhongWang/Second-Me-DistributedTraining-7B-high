# This script will install tiktoken for accurate token counting in LLM prompt control.
# For OpenAI GPT models, tiktoken is the official tokenizer.
# If you use other LLMs, you can switch to HuggingFace/transformers tokenizer similarly.

# 安装 tiktoken
# pip install tiktoken

import tiktoken

def count_tokens(text, model_name="gpt-3.5-turbo"):
    enc = tiktoken.encoding_for_model(model_name)
    return len(enc.encode(text))
