import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted worklist budget is in its life cycle.
    enum WeightedWorklistBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One weighted worklist budget, with what the planners need to act on it.
    final class WeightedWorklistBudget {
        var code: String
        var label: String
        var capacity: Int
        var timezone: String
        var bed: String
        var notes: String
        var amount: Double
        var status: WeightedWorklistBudgetStatus

        init(code: String, label: String, capacity: Int, timezone: String, bed: String, notes: String, amount: Double, status: WeightedWorklistBudgetStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.timezone = timezone
            self.bed = bed
            self.notes = notes
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedWorklistBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedWorklistBudgetStatus.reopened || next == WeightedWorklistBudgetStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedWorklistBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted worklist budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted worklist budget") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(capacity) + amount) * 100).rounded() / 100
        }

        func copyValue() -> WeightedWorklistBudget {
            return WeightedWorklistBudget(
                code: code,
                label: label,
                capacity: capacity,
                timezone: timezone,
                bed: bed,
                notes: notes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted worklist budget in status open.
    static func newWeightedWorklistBudget(_ code: String, label: String) -> WeightedWorklistBudget {
        return WeightedWorklistBudget(
            code: code,
            label: label,
            capacity: 0,
            timezone: "",
            bed: "",
            notes: "",
            amount: 0.0,
            status: WeightedWorklistBudgetStatus.`open`
        )
    }
}
