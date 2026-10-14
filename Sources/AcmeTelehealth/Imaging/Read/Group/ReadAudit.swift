import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read audit is in its life cycle.
    enum ReadAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A read audit as the read team keeps it.
    final class ReadAudit {
        var code: String
        var label: String
        var expiresAt: Int
        var encounterID: String
        var quantity: Int
        var title: String
        var maximum: Double
        var pinned: Bool
        var attempts: Int
        var status: ReadAuditStatus

        init(code: String, label: String, expiresAt: Int, encounterID: String, quantity: Int, title: String, maximum: Double, pinned: Bool, attempts: Int, status: ReadAuditStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.encounterID = encounterID
            self.quantity = quantity
            self.title = title
            self.maximum = maximum
            self.pinned = pinned
            self.attempts = attempts
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

        func canMoveTo(_ next: ReadAuditStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReadAuditStatus.ready || next == ReadAuditStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
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

        func moveTo(_ next: ReadAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("read audit") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ReadAudit {
            return ReadAudit(
                code: code,
                label: label,
                expiresAt: expiresAt,
                encounterID: encounterID,
                quantity: quantity,
                title: title,
                maximum: maximum,
                pinned: pinned,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read audit in status idle.
    static func newReadAudit(_ code: String, label: String) -> ReadAudit {
        return ReadAudit(
            code: code,
            label: label,
            expiresAt: 0,
            encounterID: "",
            quantity: 0,
            title: "",
            maximum: 0.0,
            pinned: false,
            attempts: 0,
            status: ReadAuditStatus.idle
        )
    }
}
