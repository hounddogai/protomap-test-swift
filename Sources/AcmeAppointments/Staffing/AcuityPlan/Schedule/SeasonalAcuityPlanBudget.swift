import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal acuity plan budget is in its life cycle.
    enum SeasonalAcuityPlanBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal acuity plan budget, with what the planners need to act on it.
    final class SeasonalAcuityPlanBudget {
        var code: String
        var name: String
        var acuity: Int
        var updatedAt: Int
        var threshold: Double
        var specialty: String
        var reviewer: String
        var status: SeasonalAcuityPlanBudgetStatus

        init(code: String, name: String, acuity: Int, updatedAt: Int, threshold: Double, specialty: String, reviewer: String, status: SeasonalAcuityPlanBudgetStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.specialty = specialty
            self.reviewer = reviewer
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

        func canMoveTo(_ next: SeasonalAcuityPlanBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SeasonalAcuityPlanBudgetStatus.resolved || next == SeasonalAcuityPlanBudgetStatus.archived
            case .inReview:
                return next == SeasonalAcuityPlanBudgetStatus.reopened
            case .resolved:
                return next == SeasonalAcuityPlanBudgetStatus.reopened
            case .reopened:
                return next == SeasonalAcuityPlanBudgetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalAcuityPlanBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal acuity plan budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return (Double(updatedAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAcuityPlanBudget {
            return SeasonalAcuityPlanBudget(
                code: code,
                name: name,
                acuity: acuity,
                updatedAt: updatedAt,
                threshold: threshold,
                specialty: specialty,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal acuity plan budget in status open.
    static func newSeasonalAcuityPlanBudget(_ code: String, name: String) -> SeasonalAcuityPlanBudget {
        return SeasonalAcuityPlanBudget(
            code: code,
            name: name,
            acuity: 0,
            updatedAt: 0,
            threshold: 0.0,
            specialty: "",
            reviewer: "",
            status: SeasonalAcuityPlanBudgetStatus.`open`
        )
    }
}
