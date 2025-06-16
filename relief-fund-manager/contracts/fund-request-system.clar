;; FUND REQUEST SUBMISSION SYSTEM

;; Enables beneficiaries to submit fund requests for disaster relief with 
;; detailed documentation. Integrates with existing disbursement system(relief-fund-manager-tests.clar) and
;; maintains the same error handling and data structure patterns.

;; Constants (from the original contract)
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-already-approved (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-cause (err u106))

;; Additional error constants for this feature
(define-constant err-request-exists (err u107))
(define-constant err-invalid-documentation (err u108))
(define-constant err-request-limit-exceeded (err u109))

;; Data Maps (from the original contract)
(define-map donations 
  { donor: principal, cause: (string-ascii 64) } 
  uint)
(define-map causes 
  (string-ascii 64) 
  { total-funds: uint, disbursed: uint })
(define-map fund-requests 
  uint 
  { beneficiary: principal, cause: (string-ascii 64), amount: uint, approved: bool })
(define-map beneficiaries 
  principal 
  { verified: bool, total-received: uint })

;; Additional data map for this feature
(define-map beneficiary-request-count principal uint)

;; Variables (from the original contract)
(define-data-var request-id-nonce uint u0)

;; Private Functions (from the original contract)
(define-private (is-owner)
  (is-eq tx-sender contract-owner))

;; Public function to submit fund requests
(define-public (request-fund (cause (string-ascii 64)) (amount uint) (details (string-ascii 256)))
  (let
    ((current-request-id (var-get request-id-nonce))
     (new-request-id (+ current-request-id u1))
     (beneficiary-request-count-current (default-to u0 (map-get? beneficiary-request-count tx-sender)))
     (cause-data (default-to {total-funds: u0, disbursed: u0} (map-get? causes cause))))
    
    ;; Input validation following your pattern
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (is-eq (len cause) u0)) err-invalid-cause)
    (asserts! (not (is-eq (len details) u0)) err-invalid-documentation)
    
    ;; Business logic validation
    (asserts! (> (get total-funds cause-data) u0) err-not-found)
    (asserts! (< beneficiary-request-count-current u5) err-request-limit-exceeded)
    
    ;; Create fund request entry
    (map-set fund-requests 
      new-request-id
      {
        beneficiary: tx-sender,
        cause: cause,
        amount: amount,
        approved: false
      })
    
    ;; Update beneficiary request count
    (map-set beneficiary-request-count 
      tx-sender 
      (+ beneficiary-request-count-current u1))
    
    ;; Increment request ID nonce
    (var-set request-id-nonce new-request-id)
    
    (ok new-request-id)))

;; Public function to approve requests (owner only)
(define-public (approve-request (request-id uint))
  (begin
    (asserts! (is-owner) err-owner-only)
    
    (match (map-get? fund-requests request-id)
      request
        (begin
          (asserts! (not (get approved request)) err-already-approved)
          
          ;; Update request approval status
          (map-set fund-requests
            request-id
            (merge request {approved: true}))
          
          (ok true))
      err-not-found)))

;; Read-only function to get beneficiary request count
(define-read-only (get-beneficiary-request-count (beneficiary principal))
  (ok (default-to u0 (map-get? beneficiary-request-count beneficiary))))

;; Read-only function to check available funds for a cause
(define-read-only (get-available-funds (cause (string-ascii 64)))
  (let ((cause-data (default-to {total-funds: u0, disbursed: u0} (map-get? causes cause))))
    (ok (- (get total-funds cause-data) (get disbursed cause-data)))))