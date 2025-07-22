;; Digital Savings Vault Contract
;; Help users save by locking funds with savings goals and maturity dates

;; Error codes
(define-constant err-not-account-holder (err u200))
(define-constant err-savings-still-locked (err u201))
(define-constant err-insufficient-deposit (err u202))
(define-constant err-invalid-maturity-date (err u203))
(define-constant err-vault-not-found (err u204))

;; Contract variables
(define-data-var bank-manager principal tx-sender)

;; Savings vault structure
(define-map savings-vaults 
  { vault-id: uint }
  {
    account-holder: principal,
    savings-goal: (string-ascii 100),
    deposit-amount: uint,
    maturity-block: uint,
    interest-rate: uint,
    created-at: uint
  }
)

;; Global vault counter
(define-data-var next-vault-id uint u1)

;; Get next available vault ID
(define-private (get-next-vault-id)
  (let ((current-id (var-get next-vault-id)))
    (var-set next-vault-id (+ current-id u1))
    current-id
  )
)

;; Open a new savings vault
(define-public (open-savings-vault (savings-goal (string-ascii 100)) (deposit-amount uint) (months-to-maturity uint))
  (let (
    (vault-id (get-next-vault-id))
    (maturity-block (+ block-height (* months-to-maturity u144))) ;; ~144 blocks per day * 30 days
    (interest-rate u5) ;; 5% annual interest (simplified)
  )
    (asserts! (> deposit-amount u1000000) err-insufficient-deposit) ;; Minimum 1 STX
    (asserts! (> months-to-maturity u0) err-invalid-maturity-date)
    
    ;; Transfer deposit to vault
    (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))
    
    ;; Create savings vault
    (map-set savings-vaults 
      { vault-id: vault-id }
      {
        account-holder: tx-sender,
        savings-goal: savings-goal,
        deposit-amount: deposit-amount,
        maturity-block: maturity-block,
        interest-rate: interest-rate,
        created-at: block-height
      }
    )
    
    (ok { vault-id: vault-id, maturity-block: maturity-block })
  )
)

;; Calculate matured savings with interest
(define-private (calculate-matured-amount (principal-amount uint) (interest-rate uint) (blocks-held uint))
  (let (
    (annual-blocks u52560) ;; Approximate blocks per year
    (interest-multiplier (/ (* interest-rate blocks-held) annual-blocks))
    (interest-amount (/ (* principal-amount interest-multiplier) u100))
  )
    (+ principal-amount interest-amount)
  )
)

;; Withdraw matured savings
(define-public (withdraw-savings (vault-id uint))
  (let (
    (vault-data (unwrap! (map-get? savings-vaults { vault-id: vault-id }) err-vault-not-found))
    (account-holder (get account-holder vault-data))
    (deposit-amount (get deposit-amount vault-data))
    (maturity-block (get maturity-block vault-data))
    (interest-rate (get interest-rate vault-data))
    (created-at (get created-at vault-data))
    (blocks-held (- block-height created-at))
    (final-amount (calculate-matured-amount deposit-amount interest-rate blocks-held))
  )
    ;; Verify account holder
    (asserts! (is-eq tx-sender account-holder) err-not-account-holder)
    
    ;; Check if savings have matured
    (asserts! (>= block-height maturity-block) err-savings-still-locked)
    
    ;; Transfer matured savings
    (try! (as-contract (stx-transfer? final-amount tx-sender account-holder)))
    
    ;; Close vault
    (map-delete savings-vaults { vault-id: vault-id })
    
    (ok { withdrawn-amount: final-amount, interest-earned: (- final-amount deposit-amount) })
  )
)

;; Check savings vault status
(define-read-only (get-vault-status (vault-id uint))
  (match (map-get? savings-vaults { vault-id: vault-id })
    vault-data 
    (let (
      (deposit-amount (get deposit-amount vault-data))
      (maturity-block (get maturity-block vault-data))
      (interest-rate (get interest-rate vault-data))
      (created-at (get created-at vault-data))
      (blocks-held (- block-height created-at))
      (is-mature (>= block-height maturity-block))
      (projected-amount (calculate-matured-amount deposit-amount interest-rate blocks-held))
    )
      (ok {
        vault-info: vault-data,
        is-mature: is-mature,
        blocks-until-maturity: (if is-mature u0 (- maturity-block block-height)),
        projected-amount: projected-amount
      })
    )
    err-vault-not-found
  )
)

;; Get all vault info
(define-read-only (get-vault-details (vault-id uint))
  (map-get? savings-vaults { vault-id: vault-id })
)

;; Emergency vault closure (with penalty)
(define-public (emergency-close-vault (vault-id uint))
  (let (
    (vault-data (unwrap! (map-get? savings-vaults { vault-id: vault-id }) err-vault-not-found))
    (account-holder (get account-holder vault-data))
    (deposit-amount (get deposit-amount vault-data))
    (penalty-amount (/ deposit-amount u10)) ;; 10% penalty
    (withdrawal-amount (- deposit-amount penalty-amount))
  )
    ;; Verify account holder
    (asserts! (is-eq tx-sender account-holder) err-not-account-holder)
    
    ;; Transfer amount minus penalty
    (try! (as-contract (stx-transfer? withdrawal-amount tx-sender account-holder)))
    
    ;; Close vault
    (map-delete savings-vaults { vault-id: vault-id })
    
    (ok { withdrawn-amount: withdrawal-amount, penalty-paid: penalty-amount })
  )
)