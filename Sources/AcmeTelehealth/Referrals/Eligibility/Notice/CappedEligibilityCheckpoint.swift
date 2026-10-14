import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped eligibility checkpoint is in its life cycle.
    enum CappedEligibilityCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped eligibility checkpoint. Its code is unique within a tenant.
    final class CappedEligibilityCheckpoint {
        var code: String
        var title: String
        var amount: Double
        var procedureCode: String
        var batchSize: Int
        var status: CappedEligibilityCheckpointStatus

        init(code: String, title: String, amount: Double, procedureCode: String, batchSize: Int, status: CappedEligibilityCheckpointStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.procedureCode = procedureCode
            self.batchSize = batchSize
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

        func canMoveTo(_ next: CappedEligibilityCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedEligibilityCheckpointStatus.scheduled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CappedEligibilityCheckpointStatus.completed || next == CappedEligibilityCheckpointStatus.cancelled
            case .completed:
                return next == CappedEligibilityCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedEligibilityCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped eligibility checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((amount + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> CappedEligibilityCheckpoint {
            return CappedEligibilityCheckpoint(
                code: code,
                title: title,
                amount: amount,
                procedureCode: procedureCode,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped eligibility checkpoint in status planned.
    static func newCappedEligibilityCheckpoint(_ code: String, title: String) -> CappedEligibilityCheckpoint {
        return CappedEligibilityCheckpoint(
            code: code,
            title: title,
            amount: 0.0,
            procedureCode: "",
            batchSize: 0,
            status: CappedEligibilityCheckpointStatus.planned
        )
    }
}
