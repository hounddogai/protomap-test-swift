import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted overtime ledger is in its life cycle.
    enum WeightedOvertimeLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a weighted overtime ledger and its current status.
    final class WeightedOvertimeLedger {
        var code: String
        var label: String
        var graceDays: Int
        var sequence: Int
        var category: String
        var discount: Double
        var status: WeightedOvertimeLedgerStatus

        init(code: String, label: String, graceDays: Int, sequence: Int, category: String, discount: Double, status: WeightedOvertimeLedgerStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.sequence = sequence
            self.category = category
            self.discount = discount
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

        func canMoveTo(_ next: WeightedOvertimeLedgerStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedOvertimeLedgerStatus.inProgress || next == WeightedOvertimeLedgerStatus.completed
            case .scheduled:
                return next == WeightedOvertimeLedgerStatus.completed || next == WeightedOvertimeLedgerStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == WeightedOvertimeLedgerStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedOvertimeLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted overtime ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return (discount * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOvertimeLedger {
            return WeightedOvertimeLedger(
                code: code,
                label: label,
                graceDays: graceDays,
                sequence: sequence,
                category: category,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted overtime ledger in status planned.
    static func newWeightedOvertimeLedger(_ code: String, label: String) -> WeightedOvertimeLedger {
        return WeightedOvertimeLedger(
            code: code,
            label: label,
            graceDays: 0,
            sequence: 0,
            category: "",
            discount: 0.0,
            status: WeightedOvertimeLedgerStatus.planned
        )
    }
}
