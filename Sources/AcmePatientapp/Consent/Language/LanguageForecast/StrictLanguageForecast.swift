import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict language forecast is in its life cycle.
    enum StrictLanguageForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a strict language forecast and its current status.
    final class StrictLanguageForecast {
        var code: String
        var title: String
        var maximum: Double
        var acuity: Int
        var cost: Double
        var status: StrictLanguageForecastStatus

        init(code: String, title: String, maximum: Double, acuity: Int, cost: Double, status: StrictLanguageForecastStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.acuity = acuity
            self.cost = cost
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

        func canMoveTo(_ next: StrictLanguageForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StrictLanguageForecastStatus.rejected || next == StrictLanguageForecastStatus.withdrawn
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

        func moveTo(_ next: StrictLanguageForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict language forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict language forecast") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(acuity) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> StrictLanguageForecast {
            return StrictLanguageForecast(
                code: code,
                title: title,
                maximum: maximum,
                acuity: acuity,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict language forecast in status proposed.
    static func newStrictLanguageForecast(_ code: String, title: String) -> StrictLanguageForecast {
        return StrictLanguageForecast(
            code: code,
            title: title,
            maximum: 0.0,
            acuity: 0,
            cost: 0.0,
            status: StrictLanguageForecastStatus.proposed
        )
    }
}
