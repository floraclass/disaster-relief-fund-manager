;; Disaster Relief Core Smart Contract
;; This contract implements core features for managing disaster relief funds:
;; - Well-organized data storage maps.
;; - Comprehensive read-only getter functions.
;; - Owner-only access control for critical functions.
;; - An emergency fund recovery mechanism.

;; --- Constants ---
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-invalid-cause (err u103))
(define-constant err-already-approved (err u104))

;; --- Data Storage Structure (Well-organized maps) ---

;; Map to track donations from specific donors to specific causes.
;; Key: { donor: principal, cause: (string-ascii 64) }
;; Value: uint (total amount donated)
(define-map donations
  { donor: principal, cause: (string-ascii 64) }
  uint
)

;; Map to track aggregated financial data for each relief cause.
;; Key: (string-ascii 64) (cause name)
;; Value: { total-funds: uint, disbursed: uint }
(define-map causes
  (string-ascii 64)
  { total-funds: uint, disbursed: uint }
)

;; Map to store details of fund requests made by beneficiaries.
;; Key: uint (unique request ID)
;; Value: { beneficiary: principal, cause: (string-ascii 64), amount: uint, approved: bool }
(define-map fund-requests
  uint
  { beneficiary: principal, cause: (string-ascii 64), amount: uint, approved: bool }
)

;; Map to track verification status and total funds received by beneficiaries.
;; Key: principal (beneficiary address)
;; Value: { verified: bool, total-received: uint }
(define-map beneficiaries
  principal
  { verified: bool, total-received: uint }
)

;; --- Variables ---
;; A nonce to generate unique request IDs for fund requests.
(define-data-var request-id-nonce uint u0)

;; --- Private Functions ---

;; @desc Checks if the transaction sender is the contract owner.
;; @returns bool - true if sender is owner, false otherwise.
(define-private (is-owner)
  (is-eq tx-sender contract-owner)
)

;; --- Public Functions (Demonstrating Access Control) ---

;; @desc Allows a donor to contribute STX funds to a specific cause.
;; This function demonstrates interaction with the 'donations' and 'causes' maps.
;; @param cause (string-ascii 64) - The cause to which funds are being donated.
;; @param amount uint - The amount of STX to donate.
;; @returns (response bool uint) - Ok(true) on success, or an error code.
(define-public (donate (cause (string-ascii 64)) (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (is-eq (len cause) u0)) err-invalid-cause)

    (let
      ((current-donation (default-to u0 (map-get? donations {donor: tx-sender, cause: cause})))
       (cause-data (default-to {total-funds: u0, disbursed: u0} (map-get? causes cause))))

      ;; Transfer funds from sender to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

      ;; Update donations map
      (map-set donations
        {donor: tx-sender, cause: cause}
        (+ current-donation amount))

      ;; Update causes map with new total funds
      (map-set causes
        cause
        (merge cause-data {total-funds: (+ (get total-funds cause-data) amount)}))
      (ok true)
    )
  )
)

;; @desc Allows the contract owner to approve a fund request.
;; This function demonstrates owner-only access control and interaction with 'fund-requests' map.
;; @param request-id uint - The ID of the fund request to approve.
;; @returns (response bool uint) - Ok(true) on success, or an error code.
(define-public (approve-fund-request (request-id uint))
  (begin
    (asserts! (is-owner) err-owner-only) ;; Access Control: Only owner can approve

    (match (map-get? fund-requests request-id)
      request
        (begin
          (asserts! (not (get approved request)) err-already-approved)
          ;; Update request approval status
          (map-set fund-requests
            request-id
            (merge request {approved: true}))
          (ok true))
      err-not-found
    )
  )
)

;; @desc Emergency Recovery: Allows the contract owner to recover stuck STX funds from the contract.
;; This function demonstrates owner-only access control.
;; @param amount uint - The amount of STX to recover.
;; @returns (response bool uint) - Ok(true) on success, or an error code.
(define-public (recover-stuck-funds (amount uint))
  (begin
    (asserts! (is-owner) err-owner-only) ;; Access Control: Only owner can recover funds
    (asserts! (> amount u0) err-invalid-amount)

    ;; Transfer funds from contract to contract owner
    (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
    (ok true)
  )
)

;; --- Read-only Functions (Comprehensive Getters) ---

;; @desc Retrieves the total donation amount by a specific donor for a given cause.
;; @param donor principal - The principal of the donor.
;; @param cause (string-ascii 64) - The cause string.
;; @returns (response uint uint) - Ok(amount) or Ok(u0) if not found.
(define-read-only (get-donation (donor principal) (cause (string-ascii 64)))
  (ok (default-to u0 (map-get? donations {donor: donor, cause: cause})))
)

;; @desc Retrieves the total funds collected and disbursed funds for a specific cause.
;; @param cause (string-ascii 64) - The cause string.
;; @returns (response { total-funds: uint, disbursed: uint } uint) - Ok(cause-details) or default values.
(define-read-only (get-cause-details (cause (string-ascii 64)))
  (ok (default-to {total-funds: u0, disbursed: u0} (map-get? causes cause)))
)

;; @desc Retrieves the details of a specific fund request by its ID.
;; @param request-id uint - The ID of the fund request.
;; @returns (response { beneficiary: principal, cause: (string-ascii 64), amount: uint, approved: bool } uint) - Ok(request-details) or err-not-found.
(define-read-only (get-fund-request (request-id uint))
  (match (map-get? fund-requests request-id)
    request (ok request)
    (err err-not-found))
)

;; @desc Retrieves the verification status and total funds received by a beneficiary.
;; @param beneficiary principal - The principal of the beneficiary.
;; @returns (response { verified: bool, total-received: uint } uint) - Ok(beneficiary-details) or default values.
(define-read-only (get-beneficiary-details (beneficiary principal))
  (ok (default-to {verified: false, total-received: u0}
     (map-get? beneficiaries beneficiary)))
)

;; @desc Retrieves the current value of the request ID nonce.
;; @returns (response uint uint) - Ok(nonce-value).
(define-read-only (get-request-id-nonce)
  (ok (var-get request-id-nonce))
)
