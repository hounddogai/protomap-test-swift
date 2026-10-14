import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default goal policy is in its life cycle.
    enum DefaultGoalPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One default goal policy, with what the planners need to act on it.
    final class DefaultGoalPolicy {
        var code: String
        var name: String
        var active: Bool
        var graceDays: Int
        var ward: String
        var cost: Double
        var status: DefaultGoalPolicyStatus

        init(code: String, name: String, active: Bool, graceDays: Int, ward: String, cost: Double, status: DefaultGoalPolicyStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.graceDays = graceDays
            self.ward = ward
            self.cost = cost
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

        func canMoveTo(_ next: DefaultGoalPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultGoalPolicyStatus.inReview || next == DefaultGoalPolicyStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DefaultGoalPolicyStatus.reopened || next == DefaultGoalPolicyStatus.archived
            case .reopened:
                return next == DefaultGoalPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultGoalPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default goal policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(graceDays) + cost) * 100).rounded() / 100
        }

        func copyValue() -> DefaultGoalPolicy {
            return DefaultGoalPolicy(
                code: code,
                name: name,
                active: active,
                graceDays: graceDays,
                ward: ward,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default goal policy in status open.
    static func newDefaultGoalPolicy(_ code: String, name: String) -> DefaultGoalPolicy {
        return DefaultGoalPolicy(
            code: code,
            name: name,
            active: false,
            graceDays: 0,
            ward: "",
            cost: 0.0,
            status: DefaultGoalPolicyStatus.`open`
        )
    }
}
