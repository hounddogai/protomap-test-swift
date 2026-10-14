import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling care protocol override is in its life cycle.
    enum RollingCareProtocolOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling care protocol override as the care protocol team keeps it.
    final class RollingCareProtocolOverride {
        var code: String
        var title: String
        var country: String
        var attempts: Int
        var budget: Double
        var status: RollingCareProtocolOverrideStatus

        init(code: String, title: String, country: String, attempts: Int, budget: Double, status: RollingCareProtocolOverrideStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.attempts = attempts
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingCareProtocolOverrideStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingCareProtocolOverrideStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareProtocolOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling care protocol override") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(attempts) - budget) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareProtocolOverride {
            return RollingCareProtocolOverride(
                code: code,
                title: title,
                country: country,
                attempts: attempts,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling care protocol override in status created.
    static func newRollingCareProtocolOverride(_ code: String, title: String) -> RollingCareProtocolOverride {
        return RollingCareProtocolOverride(
            code: code,
            title: title,
            country: "",
            attempts: 0,
            budget: 0.0,
            status: RollingCareProtocolOverrideStatus.created
        )
    }
}
