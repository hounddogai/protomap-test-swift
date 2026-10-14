import AcmePlatform
import Foundation

extension Labs {
    /// Where a default result budget is in its life cycle.
    enum DefaultResultBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One default result budget, with what the planners need to act on it.
    final class DefaultResultBudget {
        var code: String
        var label: String
        var threshold: Double
        var durationMinutes: Int
        var quantity: Int
        var ceiling: Double
        var capacity: Int
        var specialty: String
        var summary: String
        var title: String
        var windowDays: Int
        var status: DefaultResultBudgetStatus

        init(code: String, label: String, threshold: Double, durationMinutes: Int, quantity: Int, ceiling: Double, capacity: Int, specialty: String, summary: String, title: String, windowDays: Int, status: DefaultResultBudgetStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.ceiling = ceiling
            self.capacity = capacity
            self.specialty = specialty
            self.summary = summary
            self.title = title
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultResultBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == DefaultResultBudgetStatus.suspended
            case .active:
                return next == DefaultResultBudgetStatus.closed
            case .suspended:
                return next == DefaultResultBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultResultBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default result budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((threshold - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> DefaultResultBudget {
            return DefaultResultBudget(
                code: code,
                label: label,
                threshold: threshold,
                durationMinutes: durationMinutes,
                quantity: quantity,
                ceiling: ceiling,
                capacity: capacity,
                specialty: specialty,
                summary: summary,
                title: title,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default result budget in status draft.
    static func newDefaultResultBudget(_ code: String, label: String) -> DefaultResultBudget {
        return DefaultResultBudget(
            code: code,
            label: label,
            threshold: 0.0,
            durationMinutes: 0,
            quantity: 0,
            ceiling: 0.0,
            capacity: 0,
            specialty: "",
            summary: "",
            title: "",
            windowDays: 0,
            status: DefaultResultBudgetStatus.draft
        )
    }
}
