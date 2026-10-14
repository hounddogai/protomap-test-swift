import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive denial forecast is in its life cycle.
    enum AdaptiveDenialForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive denial forecast as the denial team keeps it.
    final class AdaptiveDenialForecast {
        var code: String
        var label: String
        var currency: String
        var durationMinutes: Int
        var locale: String
        var status: AdaptiveDenialForecastStatus

        init(code: String, label: String, currency: String, durationMinutes: Int, locale: String, status: AdaptiveDenialForecastStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveDenialForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveDenialForecastStatus.rejected || next == AdaptiveDenialForecastStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveDenialForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive denial forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> AdaptiveDenialForecast {
            return AdaptiveDenialForecast(
                code: code,
                label: label,
                currency: currency,
                durationMinutes: durationMinutes,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive denial forecast in status proposed.
    static func newAdaptiveDenialForecast(_ code: String, label: String) -> AdaptiveDenialForecast {
        return AdaptiveDenialForecast(
            code: code,
            label: label,
            currency: "",
            durationMinutes: 0,
            locale: "",
            status: AdaptiveDenialForecastStatus.proposed
        )
    }
}
