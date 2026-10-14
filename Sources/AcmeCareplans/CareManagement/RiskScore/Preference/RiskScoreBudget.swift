import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score budget is in its life cycle.
    enum RiskScoreBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A risk score budget. Its code is unique within a tenant.
    final class RiskScoreBudget {
        var code: String
        var name: String
        var attempts: Int
        var graceDays: Int
        var patientRef: String
        var status: RiskScoreBudgetStatus

        init(code: String, name: String, attempts: Int, graceDays: Int, patientRef: String, status: RiskScoreBudgetStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.graceDays = graceDays
            self.patientRef = patientRef
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

        func canMoveTo(_ next: RiskScoreBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == RiskScoreBudgetStatus.scheduled || next == RiskScoreBudgetStatus.cancelled
            case .scheduled:
                return next == RiskScoreBudgetStatus.inProgress || next == RiskScoreBudgetStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RiskScoreBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("risk score budget") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(attempts) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreBudget {
            return RiskScoreBudget(
                code: code,
                name: name,
                attempts: attempts,
                graceDays: graceDays,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a risk score budget in status planned.
    static func newRiskScoreBudget(_ code: String, name: String) -> RiskScoreBudget {
        return RiskScoreBudget(
            code: code,
            name: name,
            attempts: 0,
            graceDays: 0,
            patientRef: "",
            status: RiskScoreBudgetStatus.planned
        )
    }
}
