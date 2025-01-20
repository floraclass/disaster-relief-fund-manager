;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-already-approved (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-cause (err u106))

;; Data Maps
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

;; Variables
(define-data-var request-id-nonce uint u0)

;; Private Functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner))

;; Public Functions
(define-public (donate (cause (string-ascii 64)) (amount uint))
  (begin
    ;; Input validation
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (is-eq (len cause) u0)) err-invalid-cause)
    
    (let
      ((current-donation (default-to 
          u0 
          (map-get? donations {donor: tx-sender, cause: cause})))
       (cause-data (default-to 
          {total-funds: u0, disbursed: u0} 
          (map-get? causes cause))))
      
      ;; Transfer funds
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      
      ;; Update maps
      (map-set donations 
        {donor: tx-sender, cause: cause} 
        (+ current-donation amount))
      
      (map-set causes 
        cause 
        (merge cause-data 
          {total-funds: (+ (get total-funds cause-data) amount)}))
      
      (ok true))))

(define-public (disburse-funds (request-id uint))
  (match (map-get? fund-requests request-id)
    request 
      (let
        ((cause-data (default-to 
            {total-funds: u0, disbursed: u0} 
            (map-get? causes (get cause request))))
         (beneficiary-data (default-to 
            {verified: false, total-received: u0} 
            (map-get? beneficiaries (get beneficiary request)))))
        
        (asserts! (get approved request) err-unauthorized)
        (asserts! (>= (- (get total-funds cause-data) 
                        (get disbursed cause-data)) 
                     (get amount request))
                  err-insufficient-funds)
        
        (begin
          ;; Transfer funds
          (try! (as-contract 
            (stx-transfer? 
              (get amount request) 
              tx-sender 
              (get beneficiary request))))
          
          ;; Update cause data
          (map-set causes 
            (get cause request)
            (merge cause-data 
              {disbursed: (+ (get disbursed cause-data) 
                            (get amount request))}))
          
          ;; Update beneficiary data
          (map-set beneficiaries 
            (get beneficiary request)
            (merge beneficiary-data 
              {verified: true, 
               total-received: (+ (get total-received beneficiary-data) 
                                (get amount request))}))
          
          (ok true)))
      err-not-found))

(define-public (recover-stuck-funds (amount uint))
  (begin
    (asserts! (is-owner) err-owner-only)
    (try! (as-contract 
      (stx-transfer? amount tx-sender contract-owner)))
    (ok true)))

;; Read-only functions
(define-read-only (get-donation (donor principal) (cause (string-ascii 64)))
  (ok (default-to u0 (map-get? donations {donor: donor, cause: cause}))))

(define-read-only (get-cause-details (cause (string-ascii 64)))
  (ok (default-to {total-funds: u0, disbursed: u0} (map-get? causes cause))))

(define-read-only (get-fund-request (request-id uint))
  (match (map-get? fund-requests request-id)
    request (ok request)
    (err err-not-found)))

(define-read-only (get-beneficiary-details (beneficiary principal))
  (ok (default-to {verified: false, total-received: u0} 
    (map-get? beneficiaries beneficiary))))
