# 🌉 Xion → Sei IBC Transfer Script Setup (with Union Contract)

This guide helps you fully configure and run a script to send IBC messages from **Xion Testnet** to **Sei Testnet** using Union’s CosmWasm contract.

---

## 🚀 Initial Setup

```bash
sudo apt update && sudo apt install -y wget curl git nano tar jq
```

---

## 🛠 Install Go (≥ v1.22)

```bash
wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version
```

---

## 🧪 Install Xion CLI

```bash
git clone https://github.com/burnt-labs/xion
cd xion
make install
xiond version
```

---

## 🔐 Set Up Wallet

```bash
# Create a new wallet (or restore with your mnemonic)
xiond keys add wallet --keyring-backend test
# OR
# xiond keys add wallet --recover --keyring-backend test

# Check address & balance
xiond keys show wallet -a --keyring-backend test
xiond q bank balances $(xiond keys show wallet -a --keyring-backend test) --node https://rpc.xion-testnet-2.burnt.com:443
```

---

## 🧾 Create IBC Instruction File

```bash
nano instruction.hex
```

Paste the correct `0x...` **hex instruction** string from Union dashboard or manually constructed. Save with `Ctrl + O`, then exit with `Ctrl + X`.

---

## 📜 Create the Script File

```bash
nano xion-to-sei.sh
```

Paste this:

```bash
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

```

Make it executable:

```bash
chmod +x xion-to-sei.sh
```

---

## 🚀 Run the Script

```bash
./xion-to-sei.sh
```

---

## 🧠 Notes

- The `instruction.hex` file must contain a valid Union instruction (starting with `0x`).
- Script uses `xion-testnet-2` and correct Union contract for sending from Xion to Sei.
- You can edit `AMOUNT`, `FEES`, or `sleep` duration as needed.
- Make sure the source wallet has enough `uxion` balance to cover multiple sends.

---

## ✅ Useful Commands

Check balance:

```bash
xiond q bank balances $(xiond keys show wallet -a --keyring-backend test) --node https://rpc.xion-testnet-2.burnt.com:443
```

Reopen script for editing:

```bash
nano xion-to-sei.sh
```

Reopen instruction:

```bash
nano instruction.hex
```

Terminate script:

```bash
Ctrl + C
```

---

`If any error/feedback dm me @Shinosuka_eth on Telegram, Twitter or Discord`
