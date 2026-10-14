import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness batch is in its life cycle.
    enum WitnessBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A witness batch. Its code is unique within a tenant.
    final class WitnessBatch {
        var code: String
        var label: String
        var batchSize: Int
        var contactEmail: String
        var version: Int
        var ceiling: Double
        var attempts: Int
        var source: String
        var phone: String
        var checksum: String
        var maximum: Double
        var status: WitnessBatchStatus

        init(code: String, label: String, batchSize: Int, contactEmail: String, version: Int, ceiling: Double, attempts: Int, source: String, phone: String, checksum: String, maximum: Double, status: WitnessBatchStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.version = version
            self.ceiling = ceiling
            self.attempts = attempts
            self.source = source
            self.phone = phone
            self.checksum = checksum
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessBatchStatus) -> Bool {
            switch status {
            case .idle:
                return next == WitnessBatchStatus.draining
            case .warming:
                return next == WitnessBatchStatus.draining || next == WitnessBatchStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return ((ceiling + maximum) * 100).rounded() / 100
        }

        func copyValue() -> WitnessBatch {
            return WitnessBatch(
                code: code,
                label: label,
                batchSize: batchSize,
                contactEmail: contactEmail,
                version: version,
                ceiling: ceiling,
                attempts: attempts,
                source: source,
                phone: phone,
                checksum: checksum,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a witness batch in status idle.
    static func newWitnessBatch(_ code: String, label: String) -> WitnessBatch {
        return WitnessBatch(
            code: code,
            label: label,
            batchSize: 0,
            contactEmail: "",
            version: 0,
            ceiling: 0.0,
            attempts: 0,
            source: "",
            phone: "",
            checksum: "",
            maximum: 0.0,
            status: WitnessBatchStatus.idle
        )
    }
}
