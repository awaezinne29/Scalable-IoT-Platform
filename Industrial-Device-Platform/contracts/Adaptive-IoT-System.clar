;; IoT Device Management Platform Smart Contract
;; A comprehensive decentralized platform for IoT device registration,
;; data monetization, access control, network management, and maintenance tracking.
;; Enables secure peer-to-peer IoT data transactions with built-in reputation system.

;; CONSTANTS - CONTRACT CONFIGURATION

(define-constant contract-deployer tx-sender)

;; ERROR CODES

(define-constant ERR-UNAUTHORIZED-ACCESS (err u1001))
(define-constant ERR-DEVICE-NOT-FOUND (err u1002))
(define-constant ERR-DEVICE-ALREADY-REGISTERED (err u1003))
(define-constant ERR-INVALID-INPUT-PARAMETERS (err u1004))
(define-constant ERR-INSUFFICIENT-PAYMENT-AMOUNT (err u1005))
(define-constant ERR-DEVICE-CURRENTLY-OFFLINE (err u1006))
(define-constant ERR-ACCESS-PERMISSION-DENIED (err u1007))
(define-constant ERR-DATA-RECORD-NOT-FOUND (err u1008))
(define-constant ERR-INVALID-TIMESTAMP-VALUE (err u1009))
(define-constant ERR-DEVICE-UNDER-MAINTENANCE (err u1010))
(define-constant ERR-SUBSCRIPTION-HAS-EXPIRED (err u1011))
(define-constant ERR-UNSUPPORTED-DEVICE-TYPE (err u1012))
(define-constant ERR-STRING-LENGTH-EXCEEDED (err u1013))
(define-constant ERR-INVALID-PRINCIPAL-ADDRESS (err u1014))
(define-constant ERR-INVALID-BUFFER-FORMAT (err u1015))

;; DEVICE STATUS DEFINITIONS

(define-constant device-status-active u1)
(define-constant device-status-inactive u2)
(define-constant device-status-maintenance u3)
(define-constant device-status-offline u4)

;; DEVICE TYPE CLASSIFICATIONS

(define-constant device-type-sensor u1)
(define-constant device-type-actuator u2)
(define-constant device-type-gateway u3)
(define-constant device-type-hybrid u4)

;; ACCESS PERMISSION LEVELS

(define-constant access-level-read u1)
(define-constant access-level-write u2)
(define-constant access-level-admin u3)

;; VALIDATION LIMITS

(define-constant max-metadata-characters u500)
(define-constant max-firmware-version-length u20)
(define-constant max-description-characters u300)
(define-constant max-data-type-length u50)
(define-constant max-maintenance-type-length u100)
(define-constant max-notes-characters u300)
(define-constant max-name-characters u100)
(define-constant max-location-characters u100)
(define-constant max-price-amount u1000000000)
(define-constant required-hash-length u32)
(define-constant max-sensor-reading 2147483647)
(define-constant min-sensor-reading -2147483648)

;; DATA STRUCTURES

;; Primary IoT Device Registry
(define-map iot-device-registry
  { device-identifier: (string-ascii 64) }
  {
    device-owner: principal,
    device-category: uint,
    operational-status: uint,
    physical-location: (string-ascii 100),
    device-metadata: (string-ascii 500),
    last-activity-timestamp: uint,
    firmware-version-info: (string-ascii 20),
    data-access-price: uint,
    control-access-price: uint,
    device-reputation-score: uint,
    cumulative-earnings: uint
  }
)

;; Device Data Storage Repository
(define-map device-data-repository
  { device-identifier: (string-ascii 64), data-timestamp: uint }
  {
    content-hash: (buff 32),
    data-classification: (string-ascii 50),
    sensor-reading-value: (optional int),
    data-payload-size: uint,
    integrity-verification-hash: (buff 32)
  }
)

;; Access Control Management
(define-map device-access-permissions
  { device-identifier: (string-ascii 64), authorized-user: principal }
  {
    permission-level: uint,
    access-expiration-time: uint,
    permission-grantor: principal,
    usage-counter: uint
  }
)

;; Device Network Collections
(define-map device-network-registry
  { network-identifier: (string-ascii 64) }
  {
    network-administrator: principal,
    network-display-name: (string-ascii 100),
    network-description: (string-ascii 300),
    member-device-count: uint,
    public-access-enabled: bool,
    network-membership-fee: uint
  }
)

;; Network Membership Tracking
(define-map network-membership-records
  { network-identifier: (string-ascii 64), device-identifier: (string-ascii 64) }
  {
    membership-start-time: uint,
    member-role-level: uint,
    contribution-score: uint
  }
)

;; Data Access Subscriptions
(define-map data-access-subscriptions
  { subscriber-address: principal, device-identifier: (string-ascii 64) }
  {
    subscription-plan-type: uint,
    subscription-start-time: uint,
    subscription-end-time: uint,
    payment-amount: uint,
    data-request-count: uint
  }
)

;; Maintenance History Tracking
(define-map device-maintenance-log
  { device-identifier: (string-ascii 64), maintenance-record-id: uint }
  {
    maintenance-scheduler: principal,
    scheduled-start-time: uint,
    actual-completion-time: (optional uint),
    maintenance-category: (string-ascii 100),
    maintenance-notes: (string-ascii 300),
    maintenance-cost: uint
  }
)

;; CONTRACT STATE VARIABLES

(define-data-var registered-device-count uint u0)
(define-data-var active-network-count uint u0)
(define-data-var platform-commission-rate uint u250) ;; 2.5% in basis points
(define-data-var maintenance-record-counter uint u0)
(define-data-var contract-operations-paused bool false)

;; INPUT VALIDATION FUNCTIONS

(define-private (validate-string-input (input-string (string-ascii 500)) (maximum-length uint))
  (and (> (len input-string) u0) (<= (len input-string) maximum-length))
)

(define-private (validate-buffer-format (input-buffer (buff 32)) (expected-length uint))
  (is-eq (len input-buffer) expected-length)
)

(define-private (validate-price-amount (price-value uint))
  (<= price-value max-price-amount)
)

(define-private (validate-principal-address (user-address principal))
  (not (is-eq user-address 'SP000000000000000000002Q6VF78))
)

(define-private (validate-metadata-content (metadata-string (string-ascii 500)))
  (validate-string-input metadata-string max-metadata-characters)
)

(define-private (validate-firmware-version (version-string (string-ascii 20)))
  (validate-string-input version-string max-firmware-version-length)
)

(define-private (validate-description-text (description-string (string-ascii 300)))
  (validate-string-input description-string max-description-characters)
)

(define-private (validate-data-type-specification (data-type-string (string-ascii 50)))
  (validate-string-input data-type-string max-data-type-length)
)

(define-private (validate-maintenance-type (maintenance-type-string (string-ascii 100)))
  (validate-string-input maintenance-type-string max-maintenance-type-length)
)

(define-private (validate-notes-content (notes-string (string-ascii 300)))
  (validate-string-input notes-string max-notes-characters)
)

(define-private (validate-name-field (name-string (string-ascii 100)))
  (validate-string-input name-string max-name-characters)
)

(define-private (validate-location-data (location-string (string-ascii 100)))
  (validate-string-input location-string max-location-characters)
)

(define-private (validate-hash-integrity (hash-buffer (buff 32)))
  (validate-buffer-format hash-buffer required-hash-length)
)

(define-private (validate-sensor-reading (reading-value (optional int)))
  (match reading-value
    actual-value (and (>= actual-value min-sensor-reading) (<= actual-value max-sensor-reading))
    true ;; None value is always valid
  )
)

;; AUTHORIZATION & VALIDATION HELPERS

(define-private (is-contract-administrator (user-address principal))
  (is-eq user-address contract-deployer)
)

(define-private (is-device-owner-verified (device-identifier (string-ascii 64)) (user-address principal))
  (match (map-get? iot-device-registry { device-identifier: device-identifier })
    device-record (is-eq (get device-owner device-record) user-address)
    false
  )
)

(define-private (device-registration-exists (device-identifier (string-ascii 64)))
  (is-some (map-get? iot-device-registry { device-identifier: device-identifier }))
)

(define-private (is-supported-device-type (device-category uint))
  (and (>= device-category device-type-sensor) (<= device-category device-type-hybrid))
)

(define-private (is-valid-operational-status (status-value uint))
  (and (>= status-value device-status-active) (<= status-value device-status-offline))
)

(define-private (verify-device-access-permission (device-identifier (string-ascii 64)) (user-address principal) (required-permission-level uint))
  (match (map-get? device-access-permissions { device-identifier: device-identifier, authorized-user: user-address })
    access-record (and 
      (>= (get permission-level access-record) required-permission-level)
      (> (get access-expiration-time access-record) block-height)
    )
    (is-device-owner-verified device-identifier user-address)
  )
)

(define-private (calculate-platform-commission (transaction-amount uint))
  (/ (* transaction-amount (var-get platform-commission-rate)) u10000)
)

(define-private (update-device-earnings-record (device-identifier (string-ascii 64)) (earnings-amount uint))
  (match (map-get? iot-device-registry { device-identifier: device-identifier })
    device-record 
    (begin
      (map-set iot-device-registry 
        { device-identifier: device-identifier }
        (merge device-record { 
          cumulative-earnings: (+ (get cumulative-earnings device-record) earnings-amount)
        })
      )
      true
    )
    false
  )
)

(define-private (verify-subscription-validity (subscriber-address principal) (device-identifier (string-ascii 64)))
  (match (map-get? data-access-subscriptions { subscriber-address: subscriber-address, device-identifier: device-identifier })
    subscription-record (> (get subscription-end-time subscription-record) block-height)
    false
  )
)

;; DEVICE MANAGEMENT FUNCTIONS

;; Register new IoT device in the platform
(define-public (register-iot-device 
  (device-identifier (string-ascii 64))
  (device-category uint)
  (physical-location (string-ascii 100))
  (device-metadata (string-ascii 500))
  (firmware-version-info (string-ascii 20))
  (data-access-price uint)
  (control-access-price uint)
)
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (device-registration-exists device-identifier)) ERR-DEVICE-ALREADY-REGISTERED)
    (asserts! (is-supported-device-type device-category) ERR-UNSUPPORTED-DEVICE-TYPE)
    (asserts! (> (len device-identifier) u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-location-data physical-location) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-metadata-content device-metadata) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-firmware-version firmware-version-info) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-price-amount data-access-price) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-price-amount control-access-price) ERR-INVALID-INPUT-PARAMETERS)
    
    (map-set iot-device-registry
      { device-identifier: device-identifier }
      {
        device-owner: tx-sender,
        device-category: device-category,
        operational-status: device-status-active,
        physical-location: physical-location,
        device-metadata: device-metadata,
        last-activity-timestamp: block-height,
        firmware-version-info: firmware-version-info,
        data-access-price: data-access-price,
        control-access-price: control-access-price,
        device-reputation-score: u100,
        cumulative-earnings: u0
      }
    )
    
    (var-set registered-device-count (+ (var-get registered-device-count) u1))
    (ok device-identifier)
  )
)

;; Update existing device configuration
(define-public (update-device-configuration
  (device-identifier (string-ascii 64))
  (physical-location (optional (string-ascii 100)))
  (device-metadata (optional (string-ascii 500)))
  (firmware-version-info (optional (string-ascii 20)))
  (data-access-price (optional uint))
  (control-access-price (optional uint))
)
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner-verified device-identifier tx-sender) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Validate optional parameters when provided
    (match physical-location 
      location-value (asserts! (validate-location-data location-value) ERR-STRING-LENGTH-EXCEEDED)
      true)
    (match device-metadata 
      metadata-value (asserts! (validate-metadata-content metadata-value) ERR-STRING-LENGTH-EXCEEDED)
      true)
    (match firmware-version-info 
      version-value (asserts! (validate-firmware-version version-value) ERR-STRING-LENGTH-EXCEEDED)
      true)
    (match data-access-price 
      price-value (asserts! (validate-price-amount price-value) ERR-INVALID-INPUT-PARAMETERS)
      true)
    (match control-access-price 
      price-value (asserts! (validate-price-amount price-value) ERR-INVALID-INPUT-PARAMETERS)
      true)
    
    (match (map-get? iot-device-registry { device-identifier: device-identifier })
      device-record
      (begin
        (map-set iot-device-registry
          { device-identifier: device-identifier }
          (merge device-record {
            physical-location: (default-to (get physical-location device-record) physical-location),
            device-metadata: (default-to (get device-metadata device-record) device-metadata),
            firmware-version-info: (default-to (get firmware-version-info device-record) firmware-version-info),
            data-access-price: (default-to (get data-access-price device-record) data-access-price),
            control-access-price: (default-to (get control-access-price device-record) control-access-price),
            last-activity-timestamp: block-height
          })
        )
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; Modify device operational status
(define-public (modify-device-operational-status (device-identifier (string-ascii 64)) (new-operational-status uint))
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner-verified device-identifier tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-operational-status new-operational-status) ERR-INVALID-INPUT-PARAMETERS)
    
    (match (map-get? iot-device-registry { device-identifier: device-identifier })
      device-record
      (begin
        (map-set iot-device-registry
          { device-identifier: device-identifier }
          (merge device-record {
            operational-status: new-operational-status,
            last-activity-timestamp: block-height
          })
        )
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; DATA MANAGEMENT FUNCTIONS

;; Store new device data record
(define-public (store-device-data-record
  (device-identifier (string-ascii 64))
  (content-hash (buff 32))
  (data-classification (string-ascii 50))
  (sensor-reading-value (optional int))
  (data-payload-size uint)
  (integrity-verification-hash (buff 32))
)
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (verify-device-access-permission device-identifier tx-sender access-level-write) ERR-ACCESS-PERMISSION-DENIED)
    (asserts! (> data-payload-size u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-hash-integrity content-hash) ERR-INVALID-BUFFER-FORMAT)
    (asserts! (validate-data-type-specification data-classification) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-sensor-reading sensor-reading-value) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-hash-integrity integrity-verification-hash) ERR-INVALID-BUFFER-FORMAT)
    
    ;; Verify device is operational
    (let ((device-record (unwrap! (map-get? iot-device-registry { device-identifier: device-identifier }) ERR-DEVICE-NOT-FOUND)))
      (asserts! (is-eq (get operational-status device-record) device-status-active) ERR-DEVICE-CURRENTLY-OFFLINE)
      
      (map-set device-data-repository
        { device-identifier: device-identifier, data-timestamp: block-height }
        {
          content-hash: content-hash,
          data-classification: data-classification,
          sensor-reading-value: sensor-reading-value,
          data-payload-size: data-payload-size,
          integrity-verification-hash: integrity-verification-hash
        }
      )
      
      ;; Update device activity timestamp
      (map-set iot-device-registry
        { device-identifier: device-identifier }
        (merge device-record { last-activity-timestamp: block-height })
      )
      
      (ok block-height)
    )
  )
)

;; Purchase data access subscription
(define-public (purchase-data-access-subscription (device-identifier (string-ascii 64)) (subscription-duration uint))
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (> subscription-duration u0) ERR-INVALID-INPUT-PARAMETERS)
    
    (match (map-get? iot-device-registry { device-identifier: device-identifier })
      device-record
      (let (
        (total-subscription-cost (* (get data-access-price device-record) subscription-duration))
        (platform-commission (calculate-platform-commission total-subscription-cost))
        (device-owner-payment (- total-subscription-cost platform-commission))
      )
        (asserts! (>= (stx-get-balance tx-sender) total-subscription-cost) ERR-INSUFFICIENT-PAYMENT-AMOUNT)
        
        ;; Transfer payment to device owner
        (try! (stx-transfer? device-owner-payment tx-sender (get device-owner device-record)))
        
        ;; Transfer platform commission to contract administrator
        (try! (stx-transfer? platform-commission tx-sender contract-deployer))
        
        ;; Grant data access permission
        (map-set device-access-permissions
          { device-identifier: device-identifier, authorized-user: tx-sender }
          {
            permission-level: access-level-read,
            access-expiration-time: (+ block-height subscription-duration),
            permission-grantor: (get device-owner device-record),
            usage-counter: u0
          }
        )
        
        ;; Update device earnings record
        (update-device-earnings-record device-identifier device-owner-payment)
        
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; ACCESS CONTROL FUNCTIONS

;; Grant device access permissions
(define-public (grant-device-access-permission
  (device-identifier (string-ascii 64))
  (authorized-user principal)
  (permission-level uint)
  (access-duration uint)
)
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner-verified device-identifier tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (and (>= permission-level access-level-read) (<= permission-level access-level-admin)) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (> access-duration u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-principal-address authorized-user) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (map-set device-access-permissions
      { device-identifier: device-identifier, authorized-user: authorized-user }
      {
        permission-level: permission-level,
        access-expiration-time: (+ block-height access-duration),
        permission-grantor: tx-sender,
        usage-counter: u0
      }
    )
    
    (ok true)
  )
)

;; Revoke device access permissions
(define-public (revoke-device-access-permission (device-identifier (string-ascii 64)) (authorized-user principal))
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner-verified device-identifier tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-principal-address authorized-user) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (map-delete device-access-permissions { device-identifier: device-identifier, authorized-user: authorized-user })
    (ok true)
  )
)

;; NETWORK MANAGEMENT FUNCTIONS

;; Create new device network
(define-public (create-device-network
  (network-identifier (string-ascii 64))
  (network-display-name (string-ascii 100))
  (network-description (string-ascii 300))
  (public-access-enabled bool)
  (network-membership-fee uint)
)
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-none (map-get? device-network-registry { network-identifier: network-identifier })) ERR-DEVICE-ALREADY-REGISTERED)
    (asserts! (> (len network-identifier) u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-name-field network-display-name) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-description-text network-description) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-price-amount network-membership-fee) ERR-INVALID-INPUT-PARAMETERS)
    
    (map-set device-network-registry
      { network-identifier: network-identifier }
      {
        network-administrator: tx-sender,
        network-display-name: network-display-name,
        network-description: network-description,
        member-device-count: u0,
        public-access-enabled: public-access-enabled,
        network-membership-fee: network-membership-fee
      }
    )
    
    (var-set active-network-count (+ (var-get active-network-count) u1))
    (ok network-identifier)
  )
)

;; Join device to network
(define-public (join-device-to-network (network-identifier (string-ascii 64)) (device-identifier (string-ascii 64)))
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner-verified device-identifier tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> (len network-identifier) u0) ERR-INVALID-INPUT-PARAMETERS)
    
    (match (map-get? device-network-registry { network-identifier: network-identifier })
      network-record
      (begin
        ;; Verify network access permissions
        (asserts! (or (get public-access-enabled network-record) (is-eq tx-sender (get network-administrator network-record))) ERR-ACCESS-PERMISSION-DENIED)
        
        ;; Process membership fee if required
        (if (> (get network-membership-fee network-record) u0)
          (try! (stx-transfer? (get network-membership-fee network-record) tx-sender (get network-administrator network-record)))
          true
        )
        
        ;; Add device to network membership
        (map-set network-membership-records
          { network-identifier: network-identifier, device-identifier: device-identifier }
          {
            membership-start-time: block-height,
            member-role-level: u1,
            contribution-score: u0
          }
        )
        
        ;; Update network member count
        (map-set device-network-registry
          { network-identifier: network-identifier }
          (merge network-record { member-device-count: (+ (get member-device-count network-record) u1) })
        )
        
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)

;; MAINTENANCE MANAGEMENT FUNCTIONS

;; Schedule device maintenance
(define-public (schedule-device-maintenance
  (device-identifier (string-ascii 64))
  (scheduled-start-time uint)
  (maintenance-category (string-ascii 100))
  (maintenance-notes (string-ascii 300))
  (estimated-maintenance-cost uint)
)
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner-verified device-identifier tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> scheduled-start-time block-height) ERR-INVALID-TIMESTAMP-VALUE)
    (asserts! (validate-maintenance-type maintenance-category) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-notes-content maintenance-notes) ERR-STRING-LENGTH-EXCEEDED)
    (asserts! (validate-price-amount estimated-maintenance-cost) ERR-INVALID-INPUT-PARAMETERS)
    
    (let ((maintenance-record-id (+ (var-get maintenance-record-counter) u1)))
      (map-set device-maintenance-log
        { device-identifier: device-identifier, maintenance-record-id: maintenance-record-id }
        {
          maintenance-scheduler: tx-sender,
          scheduled-start-time: scheduled-start-time,
          actual-completion-time: none,
          maintenance-category: maintenance-category,
          maintenance-notes: maintenance-notes,
          maintenance-cost: estimated-maintenance-cost
        }
      )
      
      (var-set maintenance-record-counter maintenance-record-id)
      (ok maintenance-record-id)
    )
  )
)

;; Complete scheduled maintenance
(define-public (complete-device-maintenance
  (device-identifier (string-ascii 64))
  (maintenance-record-id uint)
  (final-maintenance-cost uint)
)
  (begin
    (asserts! (not (var-get contract-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-device-owner-verified device-identifier tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-price-amount final-maintenance-cost) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (> maintenance-record-id u0) ERR-INVALID-INPUT-PARAMETERS)
    
    (match (map-get? device-maintenance-log { device-identifier: device-identifier, maintenance-record-id: maintenance-record-id })
      maintenance-record
      (begin
        (asserts! (is-none (get actual-completion-time maintenance-record)) ERR-INVALID-INPUT-PARAMETERS)
        
        (map-set device-maintenance-log
          { device-identifier: device-identifier, maintenance-record-id: maintenance-record-id }
          (merge maintenance-record {
            actual-completion-time: (some block-height),
            maintenance-cost: final-maintenance-cost
          })
        )
        
        ;; Restore device to active status
        (try! (modify-device-operational-status device-identifier device-status-active))
        
        (ok true)
      )
      ERR-DATA-RECORD-NOT-FOUND
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get device information
(define-read-only (get-device-information (device-identifier (string-ascii 64)))
  (map-get? iot-device-registry { device-identifier: device-identifier })
)

;; Get device data record
(define-read-only (get-device-data-record (device-identifier (string-ascii 64)) (data-timestamp uint))
  (map-get? device-data-repository { device-identifier: device-identifier, data-timestamp: data-timestamp })
)

;; Check device access permissions
(define-read-only (check-device-access-permissions (device-identifier (string-ascii 64)) (authorized-user principal))
  (map-get? device-access-permissions { device-identifier: device-identifier, authorized-user: authorized-user })
)

;; Get network information
(define-read-only (get-network-information (network-identifier (string-ascii 64)))
  (map-get? device-network-registry { network-identifier: network-identifier })
)

;; Get maintenance record
(define-read-only (get-maintenance-record (device-identifier (string-ascii 64)) (maintenance-record-id uint))
  (map-get? device-maintenance-log { device-identifier: device-identifier, maintenance-record-id: maintenance-record-id })
)

;; Get contract statistics
(define-read-only (get-platform-statistics)
  {
    registered-device-count: (var-get registered-device-count),
    active-network-count: (var-get active-network-count),
    platform-commission-rate: (var-get platform-commission-rate),
    contract-operations-paused: (var-get contract-operations-paused)
  }
)

;; ADMINISTRATIVE FUNCTIONS

;; Toggle contract operations pause state
(define-public (toggle-contract-operations-pause)
  (begin
    (asserts! (is-contract-administrator tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (var-set contract-operations-paused (not (var-get contract-operations-paused)))
    (ok (var-get contract-operations-paused))
  )
)

;; Update platform commission rate
(define-public (update-platform-commission-rate (new-commission-rate uint))
  (begin
    (asserts! (is-contract-administrator tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= new-commission-rate u1000) ERR-INVALID-INPUT-PARAMETERS) ;; Maximum 10%
    (var-set platform-commission-rate new-commission-rate)
    (ok new-commission-rate)
  )
)

;; Emergency device status update (administrator only)
(define-public (emergency-device-status-update (device-identifier (string-ascii 64)) (new-operational-status uint))
  (begin
    (asserts! (is-contract-administrator tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (device-registration-exists device-identifier) ERR-DEVICE-NOT-FOUND)
    (asserts! (is-valid-operational-status new-operational-status) ERR-INVALID-INPUT-PARAMETERS)
    
    (match (map-get? iot-device-registry { device-identifier: device-identifier })
      device-record
      (begin
        (map-set iot-device-registry
          { device-identifier: device-identifier }
          (merge device-record {
            operational-status: new-operational-status,
            last-activity-timestamp: block-height
          })
        )
        (ok true)
      )
      ERR-DEVICE-NOT-FOUND
    )
  )
)