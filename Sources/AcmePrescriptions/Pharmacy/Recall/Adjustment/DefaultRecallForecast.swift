import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default recall forecast is in its life cycle.
    enum DefaultRecallForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One default recall forecast, with what the planners need to act on it.
    final class DefaultRecallForecast {
        var code: String
        var title: String
        var quantity: Int
        var payer: String
        var floorValue: Double
        var currency: String
        var status: DefaultRecallForecastStatus

        init(code: String, title: String, quantity: Int, payer: String, floorValue: Double, currency: String, status: DefaultRecallForecastStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.payer = payer
            self.floorValue = floorValue
            self.currency = currency
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

        func canMoveTo(_ next: DefaultRecallForecastStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultRecallForecastStatus.retired
            case .validated:
                return next == DefaultRecallForecastStatus.published || next == DefaultRecallForecastStatus.retired
            case .published:
                return next == DefaultRecallForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRecallForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default recall forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default recall forecast") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(quantity) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRecallForecast {
            return DefaultRecallForecast(
                code: code,
                title: title,
                quantity: quantity,
                payer: payer,
                floorValue: floorValue,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default recall forecast in status created.
    static func newDefaultRecallForecast(_ code: String, title: String) -> DefaultRecallForecast {
        return DefaultRecallForecast(
            code: code,
            title: title,
            quantity: 0,
            payer: "",
            floorValue: 0.0,
            currency: "",
            status: DefaultRecallForecastStatus.created
        )
    }
}
