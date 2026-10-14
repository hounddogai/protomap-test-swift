import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score rollup is in its life cycle.
    enum RiskScoreRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One risk score rollup, with what the planners need to act on it.
    final class RiskScoreRollup {
        var code: String
        var name: String
        var weight: Double
        var currency: String
        var amount: Double
        var attempts: Int
        var acuity: Int
        var status: RiskScoreRollupStatus

        init(code: String, name: String, weight: Double, currency: String, amount: Double, attempts: Int, acuity: Int, status: RiskScoreRollupStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.currency = currency
            self.amount = amount
            self.attempts = attempts
            self.acuity = acuity
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

        func canMoveTo(_ next: RiskScoreRollupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RiskScoreRollupStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RiskScoreRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return (weight * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreRollup {
            return RiskScoreRollup(
                code: code,
                name: name,
                weight: weight,
                currency: currency,
                amount: amount,
                attempts: attempts,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a risk score rollup in status draft.
    static func newRiskScoreRollup(_ code: String, name: String) -> RiskScoreRollup {
        return RiskScoreRollup(
            code: code,
            name: name,
            weight: 0.0,
            currency: "",
            amount: 0.0,
            attempts: 0,
            acuity: 0,
            status: RiskScoreRollupStatus.draft
        )
    }
}
