import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling task budget is in its life cycle.
    enum RollingTaskBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling task budget as the task team keeps it.
    final class RollingTaskBudget {
        var code: String
        var name: String
        var budget: Double
        var cost: Double
        var label: String
        var country: String
        var createdAt: Int
        var status: RollingTaskBudgetStatus

        init(code: String, name: String, budget: Double, cost: Double, label: String, country: String, createdAt: Int, status: RollingTaskBudgetStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.cost = cost
            self.label = label
            self.country = country
            self.createdAt = createdAt
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

        func canMoveTo(_ next: RollingTaskBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RollingTaskBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingTaskBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling task budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("rolling task budget") \(code)"
        }

        func adjustedValue() -> Double {
            return ((cost - budget) * 100).rounded() / 100
        }

        func copyValue() -> RollingTaskBudget {
            return RollingTaskBudget(
                code: code,
                name: name,
                budget: budget,
                cost: cost,
                label: label,
                country: country,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling task budget in status draft.
    static func newRollingTaskBudget(_ code: String, name: String) -> RollingTaskBudget {
        return RollingTaskBudget(
            code: code,
            name: name,
            budget: 0.0,
            cost: 0.0,
            label: "",
            country: "",
            createdAt: 0,
            status: RollingTaskBudgetStatus.draft
        )
    }
}
