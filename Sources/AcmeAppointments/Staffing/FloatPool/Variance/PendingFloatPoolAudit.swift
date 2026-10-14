import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending float pool audit is in its life cycle.
    enum PendingFloatPoolAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a pending float pool audit and its current status.
    final class PendingFloatPoolAudit {
        var code: String
        var label: String
        var phone: String
        var minimum: Double
        var updatedAt: Int
        var specialty: String
        var pinned: Bool
        var ratio: Double
        var status: PendingFloatPoolAuditStatus

        init(code: String, label: String, phone: String, minimum: Double, updatedAt: Int, specialty: String, pinned: Bool, ratio: Double, status: PendingFloatPoolAuditStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.minimum = minimum
            self.updatedAt = updatedAt
            self.specialty = specialty
            self.pinned = pinned
            self.ratio = ratio
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

        func canMoveTo(_ next: PendingFloatPoolAuditStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingFloatPoolAuditStatus.ready
            case .warming:
                return next == PendingFloatPoolAuditStatus.ready || next == PendingFloatPoolAuditStatus.stopped
            case .ready:
                return next == PendingFloatPoolAuditStatus.draining || next == PendingFloatPoolAuditStatus.stopped
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

        func moveTo(_ next: PendingFloatPoolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending float pool audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return (ratio * minimum * 100).rounded() / 100
        }

        func copyValue() -> PendingFloatPoolAudit {
            return PendingFloatPoolAudit(
                code: code,
                label: label,
                phone: phone,
                minimum: minimum,
                updatedAt: updatedAt,
                specialty: specialty,
                pinned: pinned,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending float pool audit in status idle.
    static func newPendingFloatPoolAudit(_ code: String, label: String) -> PendingFloatPoolAudit {
        return PendingFloatPoolAudit(
            code: code,
            label: label,
            phone: "",
            minimum: 0.0,
            updatedAt: 0,
            specialty: "",
            pinned: false,
            ratio: 0.0,
            status: PendingFloatPoolAuditStatus.idle
        )
    }
}
