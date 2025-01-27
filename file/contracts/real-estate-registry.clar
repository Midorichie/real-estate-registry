;; Title Registry Smart Contract
;; Version: 2.0.0

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPERTY-EXISTS (err u101))
(define-constant ERR-PROPERTY-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PROPERTY-DATA (err u103))
(define-constant ERR-INVALID-PROPERTY-ID (err u104))
(define-constant ERR-INVALID-PROPERTY-DETAILS (err u105))
(define-constant ERR-NOT-OWNER (err u106))
(define-constant ERR-INVALID-PRICE (err u107))
(define-constant ERR-PROPERTY-NOT-FOR-SALE (err u108))
(define-constant ERR-INVALID-STRING-LENGTH (err u109))

;; Data Variables
(define-map properties
    { property-id: (string-utf8 36) }
    {
        owner: principal,
        registration-date: uint,
        property-details: (string-utf8 256),
        status: (string-utf8 20),
        price: uint,
        last-modified: uint
    }
)

(define-map property-history
    { property-id: (string-utf8 36), transaction-id: uint }
    {
        previous-owner: principal,
        new-owner: principal,
        transaction-date: uint,
        transaction-type: (string-utf8 20),
        price: uint
    }
)

(define-map owner-properties
    { owner: principal }
    { count: uint }
)

;; Private Functions
(define-private (check-string-length (str (string-utf8 256)) (min uint) (max uint))
    (let ((len (len str)))
        (and 
            (>= len min)
            (<= len max))))

(define-private (safe-string (input (string-utf8 256)))
    (match (as-max-len? input u256)
        success success
        u""))

(define-private (validate-property-id (property-id (string-utf8 36)))
    (let ((safe-id (unwrap! (as-max-len? property-id u36) false)))
        (if (and
                (>= (len safe-id) u1)
                (<= (len safe-id) u36)
                (is-eq (index-of safe-id u"P") (some u0)))
            true
            false)))

(define-private (validate-property-details (property-details (string-utf8 256)))
    (let ((safe-details (unwrap! (as-max-len? property-details u256) false)))
        (if (and
                (>= (len safe-details) u10)
                (<= (len safe-details) u256)
                (is-some (index-of safe-details u",")))
            true
            false)))

(define-private (increment-owner-properties (owner principal))
    (let ((current-count (default-to { count: u0 } (map-get? owner-properties { owner: owner }))))
        (map-set owner-properties
            { owner: owner }
            { count: (+ (get count current-count) u1) })))

(define-private (decrement-owner-properties (owner principal))
    (let ((current-count (default-to { count: u0 } (map-get? owner-properties { owner: owner }))))
        (map-set owner-properties
            { owner: owner }
            { count: (- (get count current-count) u1) })))

;; Public Functions
(define-public (register-property
    (property-id (string-utf8 36))
    (property-details (string-utf8 256)))
    (let 
        ((safe-id (unwrap! (as-max-len? property-id u36) ERR-INVALID-PROPERTY-ID))
         (safe-details (unwrap! (as-max-len? property-details u256) ERR-INVALID-PROPERTY-DETAILS))
         (existing-property (map-get? properties {property-id: safe-id})))
        (if (not (validate-property-id safe-id))
            ERR-INVALID-PROPERTY-ID
            (if (not (validate-property-details safe-details))
                ERR-INVALID-PROPERTY-DETAILS
                (if (is-some existing-property)
                    ERR-PROPERTY-EXISTS
                    (begin
                        (map-set properties
                            {property-id: safe-id}
                            {
                                owner: tx-sender,
                                registration-date: block-height,
                                property-details: safe-details,
                                status: u"active",
                                price: u0,
                                last-modified: block-height
                            })
                        (increment-owner-properties tx-sender)
                        (ok true)))))))

(define-public (list-property-for-sale
    (property-id (string-utf8 36))
    (price uint))
    (let 
        ((safe-id (unwrap! (as-max-len? property-id u36) ERR-INVALID-PROPERTY-ID))
         (property (map-get? properties {property-id: safe-id})))
        (if (not (validate-property-id safe-id))
            ERR-INVALID-PROPERTY-ID
            (if (is-none property)
                ERR-PROPERTY-NOT-FOUND
                (if (not (is-eq (get owner (unwrap-panic property)) tx-sender))
                    ERR-NOT-OWNER
                    (if (<= price u0)
                        ERR-INVALID-PRICE
                        (begin
                            (map-set properties
                                {property-id: safe-id}
                                (merge (unwrap-panic property)
                                    {
                                        status: u"for-sale",
                                        price: price,
                                        last-modified: block-height
                                    }))
                            (ok true))))))))

(define-public (buy-property
    (property-id (string-utf8 36)))
    (let 
        ((safe-id (unwrap! (as-max-len? property-id u36) ERR-INVALID-PROPERTY-ID))
         (property (map-get? properties {property-id: safe-id})))
        (if (not (validate-property-id safe-id))
            ERR-INVALID-PROPERTY-ID
            (if (is-none property)
                ERR-PROPERTY-NOT-FOUND
                (let ((prop (unwrap-panic property)))
                    (if (not (is-eq (get status prop) u"for-sale"))
                        ERR-PROPERTY-NOT-FOR-SALE
                        (begin
                            (map-set properties
                                {property-id: safe-id}
                                {
                                    owner: tx-sender,
                                    registration-date: (get registration-date prop),
                                    property-details: (get property-details prop),
                                    status: u"active",
                                    price: u0,
                                    last-modified: block-height
                                })
                            (decrement-owner-properties (get owner prop))
                            (increment-owner-properties tx-sender)
                            (map-set property-history
                                {
                                    property-id: safe-id,
                                    transaction-id: block-height
                                }
                                {
                                    previous-owner: (get owner prop),
                                    new-owner: tx-sender,
                                    transaction-date: block-height,
                                    transaction-type: u"sale",
                                    price: (get price prop)
                                })
                            (ok true))))))))

;; Getter Functions
(define-read-only (get-property-details (property-id (string-utf8 36)))
    (let ((safe-id (unwrap! (as-max-len? property-id u36) none)))
        (if (validate-property-id safe-id)
            (map-get? properties {property-id: safe-id})
            none)))

(define-read-only (get-property-history
    (property-id (string-utf8 36))
    (transaction-id uint))
    (let ((safe-id (unwrap! (as-max-len? property-id u36) none)))
        (if (validate-property-id safe-id)
            (map-get? property-history
                {
                    property-id: safe-id,
                    transaction-id: transaction-id
                })
            none)))

(define-read-only (get-owner-property-count (owner principal))
    (default-to { count: u0 } (map-get? owner-properties { owner: owner })))
