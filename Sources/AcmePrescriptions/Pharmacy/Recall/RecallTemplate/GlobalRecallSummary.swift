import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global recall summary is in its life cycle.
    enum GlobalRecallSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global recall summary and its current status.
    final class GlobalRecallSummary {
        var code: String
        var title: String
        var maximum: Double
        var summary: String
        var amount: Double
        var status: GlobalRecallSummaryStatus

        init(code: String, title: String, maximum: Double, summary: String, amount: Double, status: GlobalRecallSummaryStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.summary = summary
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalRecallSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == GlobalRecallSummaryStatus.running || next == GlobalRecallSummaryStatus.done
            case .running:
                return next == GlobalRecallSummaryStatus.done || next == GlobalRecallSummaryStatus.failed
            case .done:
                return next == GlobalRecallSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalRecallSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global recall summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global recall summary") \(code)"
        }

        func netTotal() -> Double {
            return (amount * maximum * 100).rounded() / 100
        }

        func copyValue() -> GlobalRecallSummary {
            return GlobalRecallSummary(
                code: code,
                title: title,
                maximum: maximum,
                summary: summary,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global recall summary in status new.
    static func newGlobalRecallSummary(_ code: String, title: String) -> GlobalRecallSummary {
        return GlobalRecallSummary(
            code: code,
            title: title,
            maximum: 0.0,
            summary: "",
            amount: 0.0,
            status: GlobalRecallSummaryStatus.new
        )
    }
}
