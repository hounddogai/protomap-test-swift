import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched eligibility audit is in its life cycle.
    enum BatchedEligibilityAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched eligibility audit as the eligibility team keeps it.
    final class BatchedEligibilityAudit {
        var code: String
        var label: String
        var rate: Double
        var dosageMg: Double
        var capacity: Int
        var name: String
        var refills: Int
        var pinned: Bool
        var status: BatchedEligibilityAuditStatus

        init(code: String, label: String, rate: Double, dosageMg: Double, capacity: Int, name: String, refills: Int, pinned: Bool, status: BatchedEligibilityAuditStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.name = name
            self.refills = refills
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedEligibilityAuditStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == BatchedEligibilityAuditStatus.inProgress || next == BatchedEligibilityAuditStatus.cancelled
            case .inProgress:
                return next == BatchedEligibilityAuditStatus.completed || next == BatchedEligibilityAuditStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BatchedEligibilityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched eligibility audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedExposure() -> Double {
            return (Double(refills) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> BatchedEligibilityAudit {
            return BatchedEligibilityAudit(
                code: code,
                label: label,
                rate: rate,
                dosageMg: dosageMg,
                capacity: capacity,
                name: name,
                refills: refills,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched eligibility audit in status planned.
    static func newBatchedEligibilityAudit(_ code: String, label: String) -> BatchedEligibilityAudit {
        return BatchedEligibilityAudit(
            code: code,
            label: label,
            rate: 0.0,
            dosageMg: 0.0,
            capacity: 0,
            name: "",
            refills: 0,
            pinned: false,
            status: BatchedEligibilityAuditStatus.planned
        )
    }
}
