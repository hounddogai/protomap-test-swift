import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy result forecast is in its life cycle.
    enum LegacyResultForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy result forecast as the result team keeps it.
    final class LegacyResultForecast {
        var code: String
        var title: String
        var ceiling: Double
        var rate: Double
        var payer: String
        var quantity: Int
        var status: LegacyResultForecastStatus

        init(code: String, title: String, ceiling: Double, rate: Double, payer: String, quantity: Int, status: LegacyResultForecastStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.rate = rate
            self.payer = payer
            self.quantity = quantity
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

        func canMoveTo(_ next: LegacyResultForecastStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LegacyResultForecastStatus.reopened || next == LegacyResultForecastStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyResultForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyResultForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy result forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy result forecast") \(code)"
        }

        func projectedTotal() -> Double {
            return ((rate - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LegacyResultForecast {
            return LegacyResultForecast(
                code: code,
                title: title,
                ceiling: ceiling,
                rate: rate,
                payer: payer,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy result forecast in status open.
    static func newLegacyResultForecast(_ code: String, title: String) -> LegacyResultForecast {
        return LegacyResultForecast(
            code: code,
            title: title,
            ceiling: 0.0,
            rate: 0.0,
            payer: "",
            quantity: 0,
            status: LegacyResultForecastStatus.`open`
        )
    }
}
