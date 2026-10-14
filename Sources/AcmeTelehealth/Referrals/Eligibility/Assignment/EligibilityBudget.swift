import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility budget is in its life cycle.
    enum EligibilityBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One eligibility budget, with what the planners need to act on it.
    final class EligibilityBudget {
        var code: String
        var name: String
        var weight: Double
        var ceiling: Double
        var ownerID: String
        var graceDays: Int
        var status: EligibilityBudgetStatus

        init(code: String, name: String, weight: Double, ceiling: Double, ownerID: String, graceDays: Int, status: EligibilityBudgetStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.graceDays = graceDays
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

        func canMoveTo(_ next: EligibilityBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == EligibilityBudgetStatus.inProgress || next == EligibilityBudgetStatus.cancelled
            case .scheduled:
                return next == EligibilityBudgetStatus.completed || next == EligibilityBudgetStatus.cancelled
            case .inProgress:
                return next == EligibilityBudgetStatus.cancelled
            case .completed:
                return next == EligibilityBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("eligibility budget") \(code)"
        }

        func adjustedExposure() -> Double {
            return (ceiling * weight * 100).rounded() / 100
        }

        func copyValue() -> EligibilityBudget {
            return EligibilityBudget(
                code: code,
                name: name,
                weight: weight,
                ceiling: ceiling,
                ownerID: ownerID,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility budget in status planned.
    static func newEligibilityBudget(_ code: String, name: String) -> EligibilityBudget {
        return EligibilityBudget(
            code: code,
            name: name,
            weight: 0.0,
            ceiling: 0.0,
            ownerID: "",
            graceDays: 0,
            status: EligibilityBudgetStatus.planned
        )
    }
}
