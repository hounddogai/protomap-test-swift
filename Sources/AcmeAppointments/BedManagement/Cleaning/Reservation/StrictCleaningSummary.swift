import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict cleaning summary is in its life cycle.
    enum StrictCleaningSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict cleaning summary as the cleaning team keeps it.
    final class StrictCleaningSummary {
        var code: String
        var name: String
        var clinicianID: String
        var rate: Double
        var summary: String
        var reviewer: String
        var sequence: Int
        var channel: String
        var status: StrictCleaningSummaryStatus

        init(code: String, name: String, clinicianID: String, rate: Double, summary: String, reviewer: String, sequence: Int, channel: String, status: StrictCleaningSummaryStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.rate = rate
            self.summary = summary
            self.reviewer = reviewer
            self.sequence = sequence
            self.channel = channel
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

        func canMoveTo(_ next: StrictCleaningSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictCleaningSummaryStatus.published
            case .validated:
                return next == StrictCleaningSummaryStatus.published || next == StrictCleaningSummaryStatus.retired
            case .published:
                return next == StrictCleaningSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCleaningSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict cleaning summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict cleaning summary") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) + rate) * 100).rounded() / 100
        }

        func copyValue() -> StrictCleaningSummary {
            return StrictCleaningSummary(
                code: code,
                name: name,
                clinicianID: clinicianID,
                rate: rate,
                summary: summary,
                reviewer: reviewer,
                sequence: sequence,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict cleaning summary in status created.
    static func newStrictCleaningSummary(_ code: String, name: String) -> StrictCleaningSummary {
        return StrictCleaningSummary(
            code: code,
            name: name,
            clinicianID: "",
            rate: 0.0,
            summary: "",
            reviewer: "",
            sequence: 0,
            channel: "",
            status: StrictCleaningSummaryStatus.created
        )
    }
}
