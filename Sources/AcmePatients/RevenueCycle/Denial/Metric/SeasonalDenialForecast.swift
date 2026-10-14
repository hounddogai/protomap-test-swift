import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal denial forecast is in its life cycle.
    enum SeasonalDenialForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a seasonal denial forecast and its current status.
    final class SeasonalDenialForecast {
        var code: String
        var label: String
        var graceDays: Int
        var reviewer: String
        var budget: Double
        var externalRef: String
        var phone: String
        var status: SeasonalDenialForecastStatus

        init(code: String, label: String, graceDays: Int, reviewer: String, budget: Double, externalRef: String, phone: String, status: SeasonalDenialForecastStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.budget = budget
            self.externalRef = externalRef
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalDenialForecastStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SeasonalDenialForecastStatus.revoked || next == SeasonalDenialForecastStatus.expired
            case .revoked:
                return next == SeasonalDenialForecastStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalDenialForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal denial forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((budget - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalDenialForecast {
            return SeasonalDenialForecast(
                code: code,
                label: label,
                graceDays: graceDays,
                reviewer: reviewer,
                budget: budget,
                externalRef: externalRef,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal denial forecast in status requested.
    static func newSeasonalDenialForecast(_ code: String, label: String) -> SeasonalDenialForecast {
        return SeasonalDenialForecast(
            code: code,
            label: label,
            graceDays: 0,
            reviewer: "",
            budget: 0.0,
            externalRef: "",
            phone: "",
            status: SeasonalDenialForecastStatus.requested
        )
    }
}
