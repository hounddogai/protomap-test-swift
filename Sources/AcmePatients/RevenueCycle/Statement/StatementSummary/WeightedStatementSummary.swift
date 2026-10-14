import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted statement summary is in its life cycle.
    enum WeightedStatementSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a weighted statement summary and its current status.
    final class WeightedStatementSummary {
        var code: String
        var title: String
        var externalRef: String
        var timezone: String
        var threshold: Double
        var ward: String
        var status: WeightedStatementSummaryStatus

        init(code: String, title: String, externalRef: String, timezone: String, threshold: Double, ward: String, status: WeightedStatementSummaryStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.timezone = timezone
            self.threshold = threshold
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedStatementSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedStatementSummaryStatus.stopped
            case .warming:
                return next == WeightedStatementSummaryStatus.ready || next == WeightedStatementSummaryStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: WeightedStatementSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted statement summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> WeightedStatementSummary {
            return WeightedStatementSummary(
                code: code,
                title: title,
                externalRef: externalRef,
                timezone: timezone,
                threshold: threshold,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted statement summary in status idle.
    static func newWeightedStatementSummary(_ code: String, title: String) -> WeightedStatementSummary {
        return WeightedStatementSummary(
            code: code,
            title: title,
            externalRef: "",
            timezone: "",
            threshold: 0.0,
            ward: "",
            status: WeightedStatementSummaryStatus.idle
        )
    }
}
