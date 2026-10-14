import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive risk score forecast is in its life cycle.
    enum AdaptiveRiskScoreForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive risk score forecast as the risk score team keeps it.
    final class AdaptiveRiskScoreForecast {
        var code: String
        var name: String
        var attempts: Int
        var endsAt: Int
        var priority: Int
        var status: AdaptiveRiskScoreForecastStatus

        init(code: String, name: String, attempts: Int, endsAt: Int, priority: Int, status: AdaptiveRiskScoreForecastStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.endsAt = endsAt
            self.priority = priority
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

        func canMoveTo(_ next: AdaptiveRiskScoreForecastStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
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
                return next == AdaptiveRiskScoreForecastStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRiskScoreForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive risk score forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveExposure() -> Double {
            return ((Double(priority) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRiskScoreForecast {
            return AdaptiveRiskScoreForecast(
                code: code,
                name: name,
                attempts: attempts,
                endsAt: endsAt,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive risk score forecast in status draft.
    static func newAdaptiveRiskScoreForecast(_ code: String, name: String) -> AdaptiveRiskScoreForecast {
        return AdaptiveRiskScoreForecast(
            code: code,
            name: name,
            attempts: 0,
            endsAt: 0,
            priority: 0,
            status: AdaptiveRiskScoreForecastStatus.draft
        )
    }
}
