import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal priority budget is in its life cycle.
    enum SeasonalPriorityBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal priority budget as the priority team keeps it.
    final class SeasonalPriorityBudget {
        var code: String
        var label: String
        var maximum: Double
        var bed: String
        var phone: String
        var budget: Double
        var status: SeasonalPriorityBudgetStatus

        init(code: String, label: String, maximum: Double, bed: String, phone: String, budget: Double, status: SeasonalPriorityBudgetStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.bed = bed
            self.phone = phone
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalPriorityBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalPriorityBudgetStatus.running || next == SeasonalPriorityBudgetStatus.failed
            case .running:
                return next == SeasonalPriorityBudgetStatus.done || next == SeasonalPriorityBudgetStatus.failed
            case .done:
                return next == SeasonalPriorityBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalPriorityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal priority budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return (budget * maximum * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPriorityBudget {
            return SeasonalPriorityBudget(
                code: code,
                label: label,
                maximum: maximum,
                bed: bed,
                phone: phone,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal priority budget in status new.
    static func newSeasonalPriorityBudget(_ code: String, label: String) -> SeasonalPriorityBudget {
        return SeasonalPriorityBudget(
            code: code,
            label: label,
            maximum: 0.0,
            bed: "",
            phone: "",
            budget: 0.0,
            status: SeasonalPriorityBudgetStatus.new
        )
    }
}
