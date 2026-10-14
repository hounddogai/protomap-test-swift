import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global slot adjustment is in its life cycle.
    enum GlobalSlotAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One global slot adjustment, with what the planners need to act on it.
    final class GlobalSlotAdjustment {
        var code: String
        var label: String
        var dosageMg: Double
        var summary: String
        var capacity: Int
        var threshold: Double
        var amount: Double
        var ownerID: String
        var active: Bool
        var reviewer: String
        var status: GlobalSlotAdjustmentStatus

        init(code: String, label: String, dosageMg: Double, summary: String, capacity: Int, threshold: Double, amount: Double, ownerID: String, active: Bool, reviewer: String, status: GlobalSlotAdjustmentStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.summary = summary
            self.capacity = capacity
            self.threshold = threshold
            self.amount = amount
            self.ownerID = ownerID
            self.active = active
            self.reviewer = reviewer
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

        func canMoveTo(_ next: GlobalSlotAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalSlotAdjustmentStatus.inProgress
            case .inProgress:
                return next == GlobalSlotAdjustmentStatus.completed || next == GlobalSlotAdjustmentStatus.cancelled
            case .completed:
                return next == GlobalSlotAdjustmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSlotAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global slot adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global slot adjustment") \(code)"
        }

        func weightedValue() -> Double {
            return ((amount + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSlotAdjustment {
            return GlobalSlotAdjustment(
                code: code,
                label: label,
                dosageMg: dosageMg,
                summary: summary,
                capacity: capacity,
                threshold: threshold,
                amount: amount,
                ownerID: ownerID,
                active: active,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global slot adjustment in status planned.
    static func newGlobalSlotAdjustment(_ code: String, label: String) -> GlobalSlotAdjustment {
        return GlobalSlotAdjustment(
            code: code,
            label: label,
            dosageMg: 0.0,
            summary: "",
            capacity: 0,
            threshold: 0.0,
            amount: 0.0,
            ownerID: "",
            active: false,
            reviewer: "",
            status: GlobalSlotAdjustmentStatus.planned
        )
    }
}
