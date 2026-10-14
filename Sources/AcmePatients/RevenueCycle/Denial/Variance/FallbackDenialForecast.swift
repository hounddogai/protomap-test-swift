import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback denial forecast is in its life cycle.
    enum FallbackDenialForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One fallback denial forecast, with what the planners need to act on it.
    final class FallbackDenialForecast {
        var code: String
        var name: String
        var ratio: Double
        var title: String
        var region: String
        var graceDays: Int
        var maximum: Double
        var threshold: Double
        var channel: String
        var attributes: [String: String]
        var expiresAt: Int
        var status: FallbackDenialForecastStatus

        init(code: String, name: String, ratio: Double, title: String, region: String, graceDays: Int, maximum: Double, threshold: Double, channel: String, attributes: [String: String], expiresAt: Int, status: FallbackDenialForecastStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.title = title
            self.region = region
            self.graceDays = graceDays
            self.maximum = maximum
            self.threshold = threshold
            self.channel = channel
            self.attributes = attributes
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: FallbackDenialForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FallbackDenialForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDenialForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback denial forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func weightedExposure() -> Double {
            return ((threshold - ratio) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDenialForecast {
            return FallbackDenialForecast(
                code: code,
                name: name,
                ratio: ratio,
                title: title,
                region: region,
                graceDays: graceDays,
                maximum: maximum,
                threshold: threshold,
                channel: channel,
                attributes: attributes,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback denial forecast in status proposed.
    static func newFallbackDenialForecast(_ code: String, name: String) -> FallbackDenialForecast {
        return FallbackDenialForecast(
            code: code,
            name: name,
            ratio: 0.0,
            title: "",
            region: "",
            graceDays: 0,
            maximum: 0.0,
            threshold: 0.0,
            channel: "",
            attributes: [:],
            expiresAt: 0,
            status: FallbackDenialForecastStatus.proposed
        )
    }
}
