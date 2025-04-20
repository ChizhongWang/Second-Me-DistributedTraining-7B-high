from typing import Optional
import numpy as np
import time
from lpm_kernel.api.dto.user_llm_config_dto import (
    UserLLMConfigDTO,
)
from lpm_kernel.configs.logging import get_train_process_logger
logger = get_train_process_logger()
import requests

def openai_strategy(user_llm_config: Optional[UserLLMConfigDTO], chunked_texts):
    max_retries = 5
    retry_delay = 2  # 初始重试延迟（秒）
    
    for attempt in range(max_retries):
        try:
            headers = {
                "Authorization": f"Bearer {user_llm_config.embedding_api_key}",
                "Content-Type": "application/json",
            }

            data = {"input": chunked_texts, "model": user_llm_config.embedding_model_name}

            logger.info(f"Getting embedding for chunks, total chunks: {len(chunked_texts)}")

            response = requests.post(
                f"{user_llm_config.embedding_endpoint}/embeddings", headers=headers, json=data
            )
            response.raise_for_status()
            result = response.json()

            # Extract embedding vectors
            embeddings = [item["embedding"] for item in result["data"]]
            embeddings_array = np.array(embeddings)

            return embeddings_array

        except requests.exceptions.RequestException as e:
            current_delay = retry_delay * (2 ** attempt)  # 指数退避策略
            
            # 检查是否是最后一次尝试
            if attempt == max_retries - 1:
                logger.error(f"Failed to get embeddings after {max_retries} attempts: {str(e)}")
                raise Exception(f"Failed to get embeddings after {max_retries} attempts: {str(e)}")
            
            # 所有错误都重试，因为在网络不稳定的情况下，认证错误也可能是临时问题
            logger.warning(f"Attempt {attempt+1}/{max_retries} failed: {str(e)}. Retrying in {current_delay} seconds...")
            time.sleep(current_delay)
