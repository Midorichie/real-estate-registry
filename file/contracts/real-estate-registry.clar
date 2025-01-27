;; Title Registry Smart Contract
;; Version: 1.0.0

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPERTY-EXISTS (err u101))
(define-constant ERR-PROPERTY-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PROPERTY-DATA (err u103))
(define-constant ERR-INVALID-PROPERTY-ID (err u104))
(define-constant ERR-INVALID-PROPERTY-DETAILS (err u105))

;; Data Variables
(define-map properties
    { property-id: (string-utf8 36) }
    {
        owner: principal,
        registration-date: uint,
        property-details: (string-utf8 256),
        status: (string-utf8 20)
    }
)

(define-map property-history
    { property-id: (string-utf8 36), transaction-id: uint }
    {
        previous-owner: principal,
        new-owner: principal,
        transaction-date: uint,
        transaction-type: (string-utf8 20)
    }
)

;; Private Functions
(define-private (validate-property-id (property-id (string-utf8 36)))
    (let
        ((len (len property-id)))
        (and
            (>= len u1)  ;; Must not be empty
            (<= len u36) ;; Must not exceed max length
            (is-eq (index-of property-id u"P") (some u0))  ;; Must start with 'P'
        )
    )
)

(define-private (validate-property-details (property-details (string-utf8 256)))
    (let
        ((len (len property-details)))
        (and
            (>= len u10)  ;; Must be at least 10 characters
            (<= len u256) ;; Must not exceed max length
            (is-some (index-of property-details u","))  ;; Must contain comma separator
        )
    )
)

;; Public Functions
(define-public (register-property 
    (property-id (string-utf8 36))
    (property-details (string-utf8 256)))
    (let
        ((existing-property (map-get? properties {property-id: property-id})))
        (if (not (validate-property-id property-id))
            ERR-INVALID-PROPERTY-ID
            (if (not (validate-property-details property-details))
                ERR-INVALID-PROPERTY-DETAILS
                (if (is-some existing-property)
                    ERR-PROPERTY-EXISTS
                    (begin
                        (map-set properties
                            {property-id: property-id}
                            {
                                owner: tx-sender,
                                registration-date: block-height,
                                property-details: property-details,
                                status: u"active"
                            })
                        (ok true)))))))

;; Getter Functions
(define-read-only (get-property-details (property-id (string-utf8 36)))
    (if (validate-property-id property-id)
        (map-get? properties {property-id: property-id})
        none))

(define-read-only (get-property-history 
    (property-id (string-utf8 36))
    (transaction-id uint))
    (if (validate-property-id property-id)
        (map-get? property-history 
            {
                property-id: property-id,
                transaction-id: transaction-id
            })
        none))
