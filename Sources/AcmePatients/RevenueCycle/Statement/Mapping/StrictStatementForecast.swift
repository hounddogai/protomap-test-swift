import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict statement forecast is in its life cycle.
    enum StrictStatementForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict statement forecast as the statement team keeps it.
    final class StrictStatementForecast {
        var code: String
        var title: String
        var bed: String
        var country: String
        var summary: String
        var visitMinutes: Int
        var graceDays: Int
        var attempts: Int
        var rate: Double
        var status: StrictStatementForecastStatus

        init(code: String, title: String, bed: String, country: String, summary: String, visitMinutes: Int, graceDays: Int, attempts: Int, rate: Double, status: StrictStatementForecastStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.country = country
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.attempts = attempts
            self.rate = rate
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

        func canMoveTo(_ next: StrictStatementForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictStatementForecastStatus.inProgress
            case .scheduled:
                return next == StrictStatementForecastStatus.inProgress || next == StrictStatementForecastStatus.cancelled
            case .inProgress:
                return next == StrictStatementForecastStatus.cancelled
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

        func moveTo(_ next: StrictStatementForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict statement forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict statement forecast") \(code)"
        }

        func weightedExposure() -> Double {
            return ((rate - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictStatementForecast {
            return StrictStatementForecast(
                code: code,
                title: title,
                bed: bed,
                country: country,
                summary: summary,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                attempts: attempts,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a strict statement forecast in status planned.
    static func newStrictStatementForecast(_ code: String, title: String) -> StrictStatementForecast {
        return StrictStatementForecast(
            code: code,
            title: title,
            bed: "",
            country: "",
            summary: "",
            visitMinutes: 0,
            graceDays: 0,
            attempts: 0,
            rate: 0.0,
            status: StrictStatementForecastStatus.planned
        )
    }
}
