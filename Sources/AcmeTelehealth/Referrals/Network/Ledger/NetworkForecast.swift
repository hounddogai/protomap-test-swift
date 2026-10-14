import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network forecast is in its life cycle.
    enum NetworkForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A network forecast as the network team keeps it.
    final class NetworkForecast {
        var code: String
        var title: String
        var attributes: [String: String]
        var dosageMg: Double
        var windowDays: Int
        var quantity: Int
        var maximum: Double
        var refills: Int
        var attempts: Int
        var status: NetworkForecastStatus

        init(code: String, title: String, attributes: [String: String], dosageMg: Double, windowDays: Int, quantity: Int, maximum: Double, refills: Int, attempts: Int, status: NetworkForecastStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.quantity = quantity
            self.maximum = maximum
            self.refills = refills
            self.attempts = attempts
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

        func canMoveTo(_ next: NetworkForecastStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == NetworkForecastStatus.active || next == NetworkForecastStatus.closed
            case .active:
                return next == NetworkForecastStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: NetworkForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("network forecast") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netLoad() -> Double {
            return ((maximum - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkForecast {
            return NetworkForecast(
                code: code,
                title: title,
                attributes: attributes,
                dosageMg: dosageMg,
                windowDays: windowDays,
                quantity: quantity,
                maximum: maximum,
                refills: refills,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a network forecast in status draft.
    static func newNetworkForecast(_ code: String, title: String) -> NetworkForecast {
        return NetworkForecast(
            code: code,
            title: title,
            attributes: [:],
            dosageMg: 0.0,
            windowDays: 0,
            quantity: 0,
            maximum: 0.0,
            refills: 0,
            attempts: 0,
            status: NetworkForecastStatus.draft
        )
    }
}
