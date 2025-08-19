;; EcoThread Supply Chain Tracker Contract
;; Clarity v2
;; Tracks supply chain milestones for fashion items, ensuring transparency and verifiability.
;; Supports adding steps, verifying steps via oracles, querying history, and admin controls.
;; Each item has a sequence of steps, stored indexed for efficiency.

(define-constant ERR-NOT-AUTHORIZED u200)
(define-constant ERR-ITEM-NOT-FOUND u201)
(define-constant ERR-STEP-ALREADY-VERIFIED u202)
(define-constant ERR-INVALID-INDEX u203)
(define-constant ERR-PAUSED u204)
(define-constant ERR-ZERO-ADDRESS u205)
(define-constant ERR-INVALID-DESCRIPTION u206)
(define-constant ERR-MAX-STEPS-REACHED u207)
(define-constant ERR-NOT-ORACLE u208)

;; Contract metadata
(define-constant CONTRACT-NAME "EcoThread Supply Chain Tracker")
(define-constant MAX-STEPS-PER-ITEM u50) ;; Limit to prevent excessive storage

;; Admin and state
(define-data-var admin principal tx-sender)
(define-data-var paused bool false)
(define-data-var oracle principal tx-sender) ;; Single oracle for simplicity; can be updated

;; Maps for supply chain data
;; items: maps item-id to owner (for auth) and step count
(define-map items uint { owner: principal, step-count: uint })
;; steps: maps (item-id, step-index) to step details
(define-map steps { item-id: uint, index: uint } {
  timestamp: uint,
  actor: principal,
  description: (string-ascii 256),
  verified: bool,
  data: (optional (buff 1024)) ;; Optional binary data, e.g., certs or hashes
})

;; Private: is-admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Private: is-oracle
(define-private (is-oracle)
  (is-eq tx-sender (var-get oracle))
)

;; Private: ensure not paused
(define-private (ensure-not-paused)
  (asserts! (not (var-get paused)) (err ERR-PAUSED))
)

;; Private: is-item-owner (item-id uint)
(define-private (is-item-owner (item-id uint))
  (match (map-get? items item-id)
    some-item (is-eq tx-sender (get owner some-item))
    false
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (is-eq new-admin 'SP000000000000000000002Q6VF78)) (err ERR-ZERO-ADDRESS))
    (var-set admin new-admin)
    (ok true)
  )
)

;; Set oracle
(define-public (set-oracle (new-oracle principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (is-eq new-oracle 'SP000000000000000000002Q6VF78)) (err ERR-ZERO-ADDRESS))
    (var-set oracle new-oracle)
    (ok true)
  )
)

;; Pause/unpause contract
(define-public (set-paused (pause bool))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set paused pause)
    (ok pause)
  )
)

;; Initialize supply chain for a new item
;; Called by item owner or admin, e.g., when minting NFT
(define-public (init-supply-chain (item-id uint) (owner principal))
  (begin
    (ensure-not-paused)
    (asserts! (or (is-admin) (is-eq tx-sender owner)) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-none (map-get? items item-id)) (err ERR-ITEM-NOT-FOUND)) ;; Already exists? No, invert for init
    (asserts! (not (is-eq owner 'SP000000000000000000002Q6VF78)) (err ERR-ZERO-ADDRESS))
    (map-set items item-id { owner: owner, step-count: u0 })
    (print { event: "init-supply-chain", item-id: item-id, owner: owner })
    (ok true)
  )
)

;; Add a new step to the supply chain
;; Only item owner can add unverified steps
(define-public (add-step (item-id uint) (description (string-ascii 256)) (data (optional (buff 1024))))
  (begin
    (ensure-not-paused)
    (asserts! (is-item-owner item-id) (err ERR-NOT-AUTHORIZED))
    (asserts! (> (len description) u0) (err ERR-INVALID-DESCRIPTION))
    (match (map-get? items item-id)
      some-item
        (let ((current-count (get step-count some-item)))
          (asserts! (< current-count MAX-STEPS-PER-ITEM) (err ERR-MAX-STEPS-REACHED))
          (let ((new-index current-count))
            (map-set steps { item-id: item-id, index: new-index } {
              timestamp: block-height,
              actor: tx-sender,
              description: description,
              verified: false,
              data: data
            })
            (map-set items item-id { owner: (get owner some-item), step-count: (+ current-count u1) })
            (print { event: "add-step", item-id: item-id, index: new-index, description: description })
            (ok new-index)
          )
        )
      (err ERR-ITEM-NOT-FOUND)
    )
  )
)

;; Verify a step via oracle
;; Oracle marks a step as verified
(define-public (verify-step (item-id uint) (index uint))
  (begin
    (ensure-not-paused)
    (asserts! (is-oracle) (err ERR-NOT-ORACLE))
    (match (map-get? items item-id)
      some-item
        (begin
          (asserts! (< index (get step-count some-item)) (err ERR-INVALID-INDEX))
          (match (map-get? steps { item-id: item-id, index: index })
            some-step
              (begin
                (asserts! (not (get verified some-step)) (err ERR-STEP-ALREADY-VERIFIED))
                (map-set steps { item-id: item-id, index: index } {
                  timestamp: (get timestamp some-step),
                  actor: (get actor some-step),
                  description: (get description some-step),
                  verified: true,
                  data: (get data some-step)
                })
                (print { event: "verify-step", item-id: item-id, index: index })
                (ok true)
              )
            (err ERR-INVALID-INDEX)
          )
        )
      (err ERR-ITEM-NOT-FOUND)
    )
  )
)

;; Transfer item ownership (e.g., when NFT transfers)
(define-public (transfer-ownership (item-id uint) (new-owner principal))
  (begin
    (ensure-not-paused)
    (asserts! (is-item-owner item-id) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (is-eq new-owner 'SP000000000000000000002Q6VF78)) (err ERR-ZERO-ADDRESS))
    (match (map-get? items item-id)
      some-item
        (begin
          (map-set items item-id { owner: new-owner, step-count: (get step-count some-item) })
          (print { event: "transfer-ownership", item-id: item-id, new-owner: new-owner })
          (ok true)
        )
      (err ERR-ITEM-NOT-FOUND)
    )
  )
)

;; Read-only: get item info
(define-read-only (get-item-info (item-id uint))
  (ok (map-get? items item-id))
)

;; Read-only: get step count
(define-read-only (get-step-count (item-id uint))
  (match (map-get? items item-id)
    some-item (ok (get step-count some-item))
    (err ERR-ITEM-NOT-FOUND)
  )
)

;; Read-only: get specific step
(define-read-only (get-step (item-id uint) (index uint))
  (match (map-get? items item-id)
    some-item
      (begin
        (asserts! (< index (get step-count some-item)) (err ERR-INVALID-INDEX))
        (ok (map-get? steps { item-id: item-id, index: index }))
      )
    (err ERR-ITEM-NOT-FOUND)
  )
)

;; Read-only: get all steps (but since no lists, user queries by index)
;; For completeness, could add a function to check if fully verified
(define-read-only (is-fully-verified (item-id uint))
  (match (map-get? items item-id)
    some-item
      (let ((count (get step-count some-item)))
        (if (is-eq count u0)
          (ok false)
          (fold check-verified-steps (list-from-u0-to count) { item-id: item-id, verified: true })
        )
      )
    (err ERR-ITEM-NOT-FOUND)
  )
)

;; Private fold helper to check if all steps verified
(define-private (check-verified-steps (index uint) (acc { item-id: uint, verified: bool }))
  (if (not (get verified acc))
    acc
    (match (map-get? steps { item-id: (get item-id acc), index: index })
      some-step { item-id: (get item-id acc), verified: (get verified some-step) }
      acc ;; If missing, but shouldn't happen
    )
  )
)

;; Helper to create list from 0 to n-1 (but Clarity lists max 1024, fine for max 50)
(define-private (list-from-u0-to (n uint))
  (fold append-index (unwrap-panic (range u0 n)) (list ))
)

(define-private (append-index (i uint) (lst (list 50 uint)))
  (unwrap-panic (as-max-len? (append lst i) u50))
)

;; Read-only: get admin
(define-read-only (get-admin)
  (ok (var-get admin))
)

;; Read-only: get oracle
(define-read-only (get-oracle)
  (ok (var-get oracle))
)

;; Read-only: is paused
(define-read-only (is-paused)
  (ok (var-get paused))
)