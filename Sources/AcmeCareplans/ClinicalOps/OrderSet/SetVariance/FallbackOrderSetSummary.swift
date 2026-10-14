import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback order set summary is in its life cycle.
    enum FallbackOrderSetSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback order set summary as the order set team keeps it.
    final class FallbackOrderSetSummary {
        var code: String
        var title: String
        var clinicianID: String
        var checksum: String
        var archived: Bool
        var amount: Double
        var status: FallbackOrderSetSummaryStatus

        init(code: String, title: String, clinicianID: String, checksum: String, archived: Bool, amount: Double, status: FallbackOrderSetSummaryStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.archived = archived
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

        func canMoveTo(_ next: FallbackOrderSetSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackOrderSetSummaryStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FallbackOrderSetSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackOrderSetSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback order set summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> FallbackOrderSetSummary {
            return FallbackOrderSetSummary(
                code: code,
                title: title,
                clinicianID: clinicianID,
                checksum: checksum,
                archived: archived,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback order set summary in status created.
    static func newFallbackOrderSetSummary(_ code: String, title: String) -> FallbackOrderSetSummary {
        return FallbackOrderSetSummary(
            code: code,
            title: title,
            clinicianID: "",
            checksum: "",
            archived: false,
            amount: 0.0,
            status: FallbackOrderSetSummaryStatus.created
        )
    }
}
