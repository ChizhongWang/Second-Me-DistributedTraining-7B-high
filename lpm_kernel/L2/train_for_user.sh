#!/bin/bash

# Initialize variables
LEARNING_RATE="2e-4"
NUM_TRAIN_EPOCHS="3"
CONCURRENCY_THREADS="2"
DATA_SYNTHESIS_MODE="high"
NUM_GPUS="auto"  # 默认自动检测GPU数量
HALF=False

# Process parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --lr) LEARNING_RATE="$2"; shift ;;
        --epochs) NUM_TRAIN_EPOCHS="$2"; shift ;;
        --threads) CONCURRENCY_THREADS="$2"; shift ;;
        --mode) DATA_SYNTHESIS_MODE="$2"; shift ;;
        --gpus) NUM_GPUS="$2"; shift ;;  # 可以手动指定GPU数量，或使用"auto"自动检测
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# 自动检测可用的GPU数量
if [ "$NUM_GPUS" = "auto" ]; then
    # 使用nvidia-smi检测可用GPU数量
    if command -v nvidia-smi &> /dev/null; then
        AVAILABLE_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
        echo "Automatically detected $AVAILABLE_GPUS available GPU(s)"
        NUM_GPUS=$AVAILABLE_GPUS
    else
        echo "nvidia-smi not found, assuming no GPUs available"
        NUM_GPUS=0
    fi
fi

# 确保NUM_GPUS是一个数字
if ! [[ "$NUM_GPUS" =~ ^[0-9]+$ ]]; then
    echo "Invalid GPU count: $NUM_GPUS. Setting to 1."
    NUM_GPUS=1
fi

# Log the parameters being used
echo "Using training parameters:"
echo "  Learning rate: $LEARNING_RATE"
echo "  Number of epochs: $NUM_TRAIN_EPOCHS"
echo "  Concurrency threads: $CONCURRENCY_THREADS"
echo "  Data synthesis mode: $DATA_SYNTHESIS_MODE"
echo "  Number of GPUs: $NUM_GPUS"

# If concurrency threads are set, configure related environment variables
if [ "$CONCURRENCY_THREADS" != "1" ]; then
  export OMP_NUM_THREADS=$CONCURRENCY_THREADS
  export MKL_NUM_THREADS=$CONCURRENCY_THREADS
  export NUMEXPR_NUM_THREADS=$CONCURRENCY_THREADS
  echo "Set thread environment variables to $CONCURRENCY_THREADS"
fi

# Add BF16 option based on the platform
if [ "$PLATFORM" != "apple" ]; then
  HALF=True
fi

# 根据GPU数量决定使用单卡还是多卡训练
if [ "$NUM_GPUS" -gt "1" ]; then
  echo "Using distributed training with $NUM_GPUS GPUs"
  # 使用torchrun进行多卡训练
  torchrun --nproc_per_node=$NUM_GPUS lpm_kernel/L2/train.py \
    --seed 42 \
    --model_name_or_path "${MODEL_BASE_PATH}" \
    --user_name "${USER_NAME}" \
    --dataset_name "resources/L2/data/merged.json" \
    --chat_template_format "chatml" \
    --add_special_tokens False \
    --append_concat_token False \
    --max_seq_length 512 \
    --num_train_epochs $NUM_TRAIN_EPOCHS \
    --save_total_limit 2 \
    --logging_steps 20 \
    --log_level "info" \
    --logging_strategy "steps" \
    --save_strategy "steps" \
    --save_steps 5 \
    --push_to_hub False \
    --bf16 $HALF \
    --packing False \
    --learning_rate $LEARNING_RATE \
    --lr_scheduler_type "cosine" \
    --weight_decay 1e-4 \
    --max_grad_norm 0.3 \
    --output_dir "${MODEL_PERSONAL_DIR}" \
    --per_device_train_batch_size 2 \
    --gradient_accumulation_steps $CONCURRENCY_THREADS \
    --gradient_checkpointing True \
    --use_reentrant True \
    --use_peft_lora True \
    --lora_r 8 \
    --lora_alpha 16 \
    --lora_dropout 0.1 \
    --lora_target_modules "all-linear" \
    --use_4bit_quantization False \
    --use_nested_quant False \
    --bnb_4bit_compute_dtype "bfloat16" \
    --is_cot False \
    --ddp_find_unused_parameters False
elif [ "$NUM_GPUS" -eq "1" ]; then
  # 单卡训练
  echo "Using single GPU training"
  # Execute training script with parameters from environment variables
  python lpm_kernel/L2/train.py \
    --seed 42 \
    --model_name_or_path "${MODEL_BASE_PATH}" \
    --user_name "${USER_NAME}" \
    --dataset_name "resources/L2/data/merged.json" \
    --chat_template_format "chatml" \
    --add_special_tokens False \
    --append_concat_token False \
    --max_seq_length 512 \
    --num_train_epochs $NUM_TRAIN_EPOCHS \
    --save_total_limit 2 \
    --logging_steps 20 \
    --log_level "info" \
    --logging_strategy "steps" \
    --save_strategy "steps" \
    --save_steps 5 \
    --push_to_hub False \
    --bf16 $HALF \
    --packing False \
    --learning_rate $LEARNING_RATE \
    --lr_scheduler_type "cosine" \
    --weight_decay 1e-4 \
    --max_grad_norm 0.3 \
    --output_dir "${MODEL_PERSONAL_DIR}" \
    --per_device_train_batch_size 2 \
    --gradient_accumulation_steps $CONCURRENCY_THREADS \
    --gradient_checkpointing True \
    --use_reentrant True \
    --use_peft_lora True \
    --lora_r 8 \
    --lora_alpha 16 \
    --lora_dropout 0.1 \
    --lora_target_modules "all-linear" \
    --use_4bit_quantization False \
    --use_nested_quant False \
    --bnb_4bit_compute_dtype "bfloat16" \
    --is_cot False
else
  # 无GPU或GPU数量为0，使用CPU训练
  echo "No GPUs detected, using CPU for training"
  python lpm_kernel/L2/train.py \
    --seed 42 \
    --model_name_or_path "${MODEL_BASE_PATH}" \
    --user_name "${USER_NAME}" \
    --dataset_name "resources/L2/data/merged.json" \
    --chat_template_format "chatml" \
    --add_special_tokens False \
    --append_concat_token False \
    --max_seq_length 512 \
    --num_train_epochs $NUM_TRAIN_EPOCHS \
    --save_total_limit 2 \
    --logging_steps 20 \
    --log_level "info" \
    --logging_strategy "steps" \
    --save_strategy "steps" \
    --save_steps 5 \
    --push_to_hub False \
    --bf16 False \
    --packing False \
    --learning_rate $LEARNING_RATE \
    --lr_scheduler_type "cosine" \
    --weight_decay 1e-4 \
    --max_grad_norm 0.3 \
    --output_dir "${MODEL_PERSONAL_DIR}" \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps $CONCURRENCY_THREADS \
    --gradient_checkpointing True \
    --use_reentrant True \
    --use_peft_lora True \
    --lora_r 8 \
    --lora_alpha 16 \
    --lora_dropout 0.1 \
    --lora_target_modules "all-linear" \
    --use_4bit_quantization False \
    --use_nested_quant False \
    --bnb_4bit_compute_dtype "float32" \
    --is_cot False
fi
