import AcmePlatform
import Foundation

extension Consent {
    /// Where a language summary is in its life cycle.
    enum LanguageSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A language summary. Its code is unique within a tenant.
    final class LanguageSummary {
        var code: String
        var title: String
        var cost: Double
        var threshold: Double
        var bed: String
        var checksum: String
        var notes: String
        var channel: String
        var quantity: Int
        var status: LanguageSummaryStatus

        init(code: String, title: String, cost: Double, threshold: Double, bed: String, checksum: String, notes: String, channel: String, quantity: Int, status: LanguageSummaryStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.threshold = threshold
            self.bed = bed
            self.checksum = checksum
            self.notes = notes
            self.channel = channel
            self.quantity = quantity
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

        func canMoveTo(_ next: LanguageSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == LanguageSummaryStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LanguageSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language summary") \(code)"
        }

        func effectiveValue() -> Double {
            return ((threshold - cost) * 100).rounded() / 100
        }

        func copyValue() -> LanguageSummary {
            return LanguageSummary(
                code: code,
                title: title,
                cost: cost,
                threshold: threshold,
                bed: bed,
                checksum: checksum,
                notes: notes,
                channel: channel,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a language summary in status created.
    static func newLanguageSummary(_ code: String, title: String) -> LanguageSummary {
        return LanguageSummary(
            code: code,
            title: title,
            cost: 0.0,
            threshold: 0.0,
            bed: "",
            checksum: "",
            notes: "",
            channel: "",
            quantity: 0,
            status: LanguageSummaryStatus.created
        )
    }
}
