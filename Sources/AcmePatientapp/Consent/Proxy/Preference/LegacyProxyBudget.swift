import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy proxy budget is in its life cycle.
    enum LegacyProxyBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One legacy proxy budget, with what the planners need to act on it.
    final class LegacyProxyBudget {
        var code: String
        var title: String
        var ceiling: Double
        var reviewer: String
        var floorValue: Double
        var description: String
        var status: LegacyProxyBudgetStatus

        init(code: String, title: String, ceiling: Double, reviewer: String, floorValue: Double, description: String, status: LegacyProxyBudgetStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.description = description
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

        func canMoveTo(_ next: LegacyProxyBudgetStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyProxyBudgetStatus.pending
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LegacyProxyBudgetStatus.closed
            case .suspended:
                return next == LegacyProxyBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyProxyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy proxy budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return ((floorValue + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LegacyProxyBudget {
            return LegacyProxyBudget(
                code: code,
                title: title,
                ceiling: ceiling,
                reviewer: reviewer,
                floorValue: floorValue,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy proxy budget in status draft.
    static func newLegacyProxyBudget(_ code: String, title: String) -> LegacyProxyBudget {
        return LegacyProxyBudget(
            code: code,
            title: title,
            ceiling: 0.0,
            reviewer: "",
            floorValue: 0.0,
            description: "",
            status: LegacyProxyBudgetStatus.draft
        )
    }
}
