### 📘 `README.md` for the Digital Savings Vault Smart Contract

````markdown
# Digital Savings Vault Smart Contract

A Clarity-based smart contract that encourages long-term savings by allowing users to create time-locked vaults with customizable savings goals, interest rates, and maturity periods.

---

## 🔐 Features

- **Vault Creation**: Users can open savings vaults with specified goals, deposits, and maturity periods.
- **Interest Accrual**: Earn 5% annual interest (simplified) on locked savings.
- **Maturity-Based Withdrawal**: Funds can only be withdrawn after vault maturity for full interest.
- **Emergency Closure**: Users can withdraw early with a 10% penalty.
- **Vault Status Tracking**: Real-time info on vault maturity, projected value, and interest earned.

---

## 🧠 Key Concepts

- **Vault ID**: Uniquely generated using a combination of the user's principal hash and vault count.
- **Interest Calculation**: Based on block height difference and a fixed annual block estimate (~52,560 blocks).
- **Maturity Period**: Defined in months; each month approximated as 4,320 blocks (~30 days × 144 blocks/day).
- **Penalty Logic**: 10% deduction on early withdrawal from the deposited principal.

---

## 📜 Contract Functions

### Public Functions
- `open-savings-vault`  
  Opens a new vault with user-defined goal, deposit, and duration.

- `withdraw-savings`  
  Withdraws matured savings plus interest after the maturity block is reached.

- `emergency-close-vault`  
  Closes vault before maturity with a 10% penalty on the principal.

### Read-only Functions
- `get-saver-vault-count`  
  Returns the number of vaults created by a given principal.

- `get-vault-status`  
  Returns real-time data about a vault's maturity, projected interest, and time left.

- `get-vault-details`  
  Retrieves stored vault metadata directly from the map.

---

## ❗ Error Codes

| Code | Meaning                      |
|------|------------------------------|
| 200  | Caller is not the account holder |
| 201  | Vault is still locked (not matured) |
| 202  | Deposit amount is too small (min: 1 STX) |
| 203  | Maturity duration must be > 0 |
| 204  | Vault not found              |

---

## 🏁 Getting Started

Deploy the contract to a Clarity-enabled blockchain (e.g., Stacks Testnet). Use a Clarity-compatible wallet (like Hiro) to interact with the contract functions.

Example `open-savings-vault` call:
```lisp
(open-savings-vault "Vacation Fund" u2000000 u6)
````

