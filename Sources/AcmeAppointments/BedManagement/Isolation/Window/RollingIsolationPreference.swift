import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling isolation preference is in its life cycle.
    enum RollingIsolationPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling isolation preference and its current status.
    final class RollingIsolationPreference {
        var code: String
        var name: String
        var cost: Double
        var ceiling: Double
        var locale: String
        var limit: Int
        var priority: Int
        var graceDays: Int
        var payer: String
        var attempts: Int
        var budget: Double
        var status: RollingIsolationPreferenceStatus

        init(code: String, name: String, cost: Double, ceiling: Double, locale: String, limit: Int, priority: Int, graceDays: Int, payer: String, attempts: Int, budget: Double, status: RollingIsolationPreferenceStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.ceiling = ceiling
            self.locale = locale
            self.limit = limit
            self.priority = priority
            self.graceDays = graceDays
            self.payer = payer
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

        func canMoveTo(_ next: RollingIsolationPreferenceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RollingIsolationPreferenceStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingIsolationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling isolation preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return (Double(graceDays) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RollingIsolationPreference {
            return RollingIsolationPreference(
                code: code,
                name: name,
                cost: cost,
                ceiling: ceiling,
                locale: locale,
                limit: limit,
                priority: priority,
                graceDays: graceDays,
                payer: payer,
                attempts: attempts,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling isolation preference in status created.
    static func newRollingIsolationPreference(_ code: String, name: String) -> RollingIsolationPreference {
        return RollingIsolationPreference(
            code: code,
            name: name,
            cost: 0.0,
            ceiling: 0.0,
            locale: "",
            limit: 0,
            priority: 0,
            graceDays: 0,
            payer: "",
            attempts: 0,
            budget: 0.0,
            status: RollingIsolationPreferenceStatus.created
        )
    }
}
