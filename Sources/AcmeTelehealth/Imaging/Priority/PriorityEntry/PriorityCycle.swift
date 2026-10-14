import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority cycle is in its life cycle.
    enum PriorityCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A priority cycle as the priority team keeps it.
    final class PriorityCycle {
        var code: String
        var label: String
        var archived: Bool
        var unit: String
        var facility: String
        var amount: Double
        var status: PriorityCycleStatus

        init(code: String, label: String, archived: Bool, unit: String, facility: String, amount: Double, status: PriorityCycleStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.unit = unit
            self.facility = facility
            self.amount = amount
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

        func canMoveTo(_ next: PriorityCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == PriorityCycleStatus.inProgress
            case .scheduled:
                return next == PriorityCycleStatus.inProgress
            case .inProgress:
                return next == PriorityCycleStatus.cancelled
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

        func moveTo(_ next: PriorityCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> PriorityCycle {
            return PriorityCycle(
                code: code,
                label: label,
                archived: archived,
                unit: unit,
                facility: facility,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a priority cycle in status planned.
    static func newPriorityCycle(_ code: String, label: String) -> PriorityCycle {
        return PriorityCycle(
            code: code,
            label: label,
            archived: false,
            unit: "",
            facility: "",
            amount: 0.0,
            status: PriorityCycleStatus.planned
        )
    }
}
