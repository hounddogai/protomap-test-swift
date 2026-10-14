import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled care protocol forecast is in its life cycle.
    enum ScheduledCareProtocolForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled care protocol forecast as the care protocol team keeps it.
    final class ScheduledCareProtocolForecast {
        var code: String
        var name: String
        var durationMinutes: Int
        var ratio: Double
        var attributes: [String: String]
        var status: ScheduledCareProtocolForecastStatus

        init(code: String, name: String, durationMinutes: Int, ratio: Double, attributes: [String: String], status: ScheduledCareProtocolForecastStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.attributes = attributes
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

        func canMoveTo(_ next: ScheduledCareProtocolForecastStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledCareProtocolForecastStatus.published
            case .validated:
                return next == ScheduledCareProtocolForecastStatus.published || next == ScheduledCareProtocolForecastStatus.retired
            case .published:
                return next == ScheduledCareProtocolForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareProtocolForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func weightedValue() -> Double {
            return (Double(durationMinutes) * ratio * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCareProtocolForecast {
            return ScheduledCareProtocolForecast(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                ratio: ratio,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled care protocol forecast in status created.
    static func newScheduledCareProtocolForecast(_ code: String, name: String) -> ScheduledCareProtocolForecast {
        return ScheduledCareProtocolForecast(
            code: code,
            name: name,
            durationMinutes: 0,
            ratio: 0.0,
            attributes: [:],
            status: ScheduledCareProtocolForecastStatus.created
        )
    }
}
