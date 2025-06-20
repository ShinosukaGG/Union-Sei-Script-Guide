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

CHAIN_ID="xion-testnet-2"
NODE="https://rpc.xion-testnet-2.burnt.com:443"
SENDER="wallet"
CONTRACT="xion1336jj8ertl8h7rdvnz4dh5rqahd09cy0x43guhsxx6xyrztx292qlzhdk9"
AMOUNT="155uxion"
FEES="1000uxion"

while true; do
  BAL=$(xiond q bank balances $(xiond keys show $SENDER -a --keyring-backend test) --node $NODE -o json | jq -r '.balances[0].amount')
  if [[ -z "$BAL" || "$BAL" -lt "${AMOUNT%uxion}" ]]; then
    echo "❌ Not enough balance. Current: $BAL"
    sleep 10
    continue
  fi

  echo "✅ Sending transaction..."

  xiond tx wasm execute $CONTRACT "{\"instruction_hex\":\"$(cat instruction.hex)\"}" \
    --from $SENDER \
    --gas auto --fees $FEES \
    --gas-adjustment 1.5 \
    --keyring-backend test \
    --chain-id $CHAIN_ID \
    --node $NODE \
    --broadcast-mode block \
    -y

  echo "⏱ Waiting 10 seconds before next try..."
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
