import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority forecast is in its life cycle.
    enum PriorityForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A priority forecast. Its code is unique within a tenant.
    final class PriorityForecast {
        var code: String
        var title: String
        var attributes: [String: String]
        var channel: String
        var visitMinutes: Int
        var unit: String
        var status: PriorityForecastStatus

        init(code: String, title: String, attributes: [String: String], channel: String, visitMinutes: Int, unit: String, status: PriorityForecastStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.channel = channel
            self.visitMinutes = visitMinutes
            self.unit = unit
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

        func canMoveTo(_ next: PriorityForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PriorityForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> PriorityForecast {
            return PriorityForecast(
                code: code,
                title: title,
                attributes: attributes,
                channel: channel,
                visitMinutes: visitMinutes,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a priority forecast in status created.
    static func newPriorityForecast(_ code: String, title: String) -> PriorityForecast {
        return PriorityForecast(
            code: code,
            title: title,
            attributes: [:],
            channel: "",
            visitMinutes: 0,
            unit: "",
            status: PriorityForecastStatus.created
        )
    }
}
