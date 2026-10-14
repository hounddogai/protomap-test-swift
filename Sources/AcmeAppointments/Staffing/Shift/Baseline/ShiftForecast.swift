import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift forecast is in its life cycle.
    enum ShiftForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One shift forecast, with what the planners need to act on it.
    final class ShiftForecast {
        var code: String
        var title: String
        var rate: Double
        var summary: String
        var minimum: Double
        var label: String
        var status: ShiftForecastStatus

        init(code: String, title: String, rate: Double, summary: String, minimum: Double, label: String, status: ShiftForecastStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.summary = summary
            self.minimum = minimum
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == ShiftForecastStatus.scheduled
            case .scheduled:
                return next == ShiftForecastStatus.inProgress || next == ShiftForecastStatus.cancelled
            case .inProgress:
                return next == ShiftForecastStatus.completed || next == ShiftForecastStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ShiftForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("shift forecast") \(code)"
        }

        func projectedVolume() -> Double {
            return (rate * minimum * 100).rounded() / 100
        }

        func copyValue() -> ShiftForecast {
            return ShiftForecast(
                code: code,
                title: title,
                rate: rate,
                summary: summary,
                minimum: minimum,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a shift forecast in status planned.
    static func newShiftForecast(_ code: String, title: String) -> ShiftForecast {
        return ShiftForecast(
            code: code,
            title: title,
            rate: 0.0,
            summary: "",
            minimum: 0.0,
            label: "",
            status: ShiftForecastStatus.planned
        )
    }
}
