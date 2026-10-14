import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall summary is in its life cycle.
    enum RecallSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One recall summary, with what the planners need to act on it.
    final class RecallSummary {
        var code: String
        var title: String
        var reviewer: String
        var region: String
        var archived: Bool
        var externalRef: String
        var notes: String
        var amount: Double
        var status: RecallSummaryStatus

        init(code: String, title: String, reviewer: String, region: String, archived: Bool, externalRef: String, notes: String, amount: Double, status: RecallSummaryStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.region = region
            self.archived = archived
            self.externalRef = externalRef
            self.notes = notes
            self.amount = amount
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

        func canMoveTo(_ next: RecallSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RecallSummaryStatus.published || next == RecallSummaryStatus.retired
            case .published:
                return next == RecallSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RecallSummary {
            return RecallSummary(
                code: code,
                title: title,
                reviewer: reviewer,
                region: region,
                archived: archived,
                externalRef: externalRef,
                notes: notes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a recall summary in status created.
    static func newRecallSummary(_ code: String, title: String) -> RecallSummary {
        return RecallSummary(
            code: code,
            title: title,
            reviewer: "",
            region: "",
            archived: false,
            externalRef: "",
            notes: "",
            amount: 0.0,
            status: RecallSummaryStatus.created
        )
    }
}
