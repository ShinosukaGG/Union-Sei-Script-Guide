#!/bin/bash

# === CONFIG ===
CHAIN_ID="xion-testnet-2"
NODE="https://rpc.xion-testnet-2.burnt.com:443"
SENDER="wallet"
CONTRACT="xion1336jj8ertl8h7rdvnz4dh5rqahd09cy0x43guhsxx6xyrztx292qlzhdk9"
AMOUNT="155uxion"
FEES="700uxion"

# === LOOP START ===
while true; do
  # Get sender address
  ADDR=$(xiond keys show $SENDER -a --keyring-backend test)
  
  # Check balance
  BAL=$(xiond q bank balances "$ADDR" --node $NODE -o json | jq -r '.balances[] | select(.denom=="uxion") | .amount')
  if [[ -z "$BAL" || "$BAL" -lt "${AMOUNT%uxion}" ]]; then
    echo "❌ Not enough balance. Current: ${BAL:-0} uxion"
    sleep 10
    continue
  fi

  # Generate salt and timeout
  SALT="0x$(openssl rand -hex 32)"
  NOW_NS=$(date +%s%N)
  TIMEOUT_TS=$((NOW_NS + 600000000000))  # +10 minutes in ns

  # Check instruction file
  if [[ ! -f instruction.hex ]]; then
    echo "❌ instruction.hex file not found!"
    exit 1
  fi

  # Prepare instruction
  RAW_HEX=$(tr -d '\n\r ' < instruction.hex)
  INSTRUCTION_HEX="0x${RAW_HEX#0x}"

  # Send transaction
  echo "📤 Sending IBC transaction to Sei..."
  xiond tx wasm execute $CONTRACT \
    '{"send":{"channel_id":6,"timeout_height":"0","timeout_timestamp":"'"$TIMEOUT_TS"'","salt":"'"$SALT"'","instruction":"'"$INSTRUCTION_HEX"'"}}' \
    --from $SENDER \
    --amount $AMOUNT \
    --gas auto \
    --gas-adjustment 1.3 \
    --fees $FEES \
    --keyring-backend test \
    --node $NODE \
    --chain-id $CHAIN_ID \
    -y

  echo "✅ Tx sent. Next Tx in 10s..."
  sleep 10
done

