import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered task summary is in its life cycle.
    enum TieredTaskSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a tiered task summary and its current status.
    final class TieredTaskSummary {
        var code: String
        var title: String
        var country: String
        var startsAt: Int
        var attempts: Int
        var cost: Double
        var status: TieredTaskSummaryStatus

        init(code: String, title: String, country: String, startsAt: Int, attempts: Int, cost: Double, status: TieredTaskSummaryStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.startsAt = startsAt
            self.attempts = attempts
            self.cost = cost
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

        func canMoveTo(_ next: TieredTaskSummaryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TieredTaskSummaryStatus.cancelled
            case .inProgress:
                return next == TieredTaskSummaryStatus.completed || next == TieredTaskSummaryStatus.cancelled
            case .completed:
                return next == TieredTaskSummaryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredTaskSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered task summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered task summary") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((cost + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TieredTaskSummary {
            return TieredTaskSummary(
                code: code,
                title: title,
                country: country,
                startsAt: startsAt,
                attempts: attempts,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered task summary in status planned.
    static func newTieredTaskSummary(_ code: String, title: String) -> TieredTaskSummary {
        return TieredTaskSummary(
            code: code,
            title: title,
            country: "",
            startsAt: 0,
            attempts: 0,
            cost: 0.0,
            status: TieredTaskSummaryStatus.planned
        )
    }
}
