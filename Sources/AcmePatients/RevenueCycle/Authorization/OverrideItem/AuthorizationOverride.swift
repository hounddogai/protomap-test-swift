import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization override is in its life cycle.
    enum AuthorizationOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One authorization override, with what the planners need to act on it.
    final class AuthorizationOverride {
        var code: String
        var title: String
        var specialty: String
        var amount: Double
        var approved: Bool
        var budget: Double
        var status: AuthorizationOverrideStatus

        init(code: String, title: String, specialty: String, amount: Double, approved: Bool, budget: Double, status: AuthorizationOverrideStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.amount = amount
            self.approved = approved
            self.budget = budget
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

        func canMoveTo(_ next: AuthorizationOverrideStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AuthorizationOverrideStatus.completed
            case .inProgress:
                return next == AuthorizationOverrideStatus.completed || next == AuthorizationOverrideStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AuthorizationOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("authorization override") \(code)"
        }

        func projectedLoad() -> Double {
            return (budget * amount * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationOverride {
            return AuthorizationOverride(
                code: code,
                title: title,
                specialty: specialty,
                amount: amount,
                approved: approved,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a authorization override in status planned.
    static func newAuthorizationOverride(_ code: String, title: String) -> AuthorizationOverride {
        return AuthorizationOverride(
            code: code,
            title: title,
            specialty: "",
            amount: 0.0,
            approved: false,
            budget: 0.0,
            status: AuthorizationOverrideStatus.planned
        )
    }
}
