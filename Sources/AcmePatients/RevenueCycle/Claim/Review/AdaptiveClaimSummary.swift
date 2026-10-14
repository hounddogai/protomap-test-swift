import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive claim summary is in its life cycle.
    enum AdaptiveClaimSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive claim summary. Its code is unique within a tenant.
    final class AdaptiveClaimSummary {
        var code: String
        var title: String
        var summary: String
        var threshold: Double
        var clinicianID: String
        var status: AdaptiveClaimSummaryStatus

        init(code: String, title: String, summary: String, threshold: Double, clinicianID: String, status: AdaptiveClaimSummaryStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.threshold = threshold
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: AdaptiveClaimSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveClaimSummaryStatus.validated || next == AdaptiveClaimSummaryStatus.published
            case .validated:
                return next == AdaptiveClaimSummaryStatus.published || next == AdaptiveClaimSummaryStatus.retired
            case .published:
                return next == AdaptiveClaimSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveClaimSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive claim summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive claim summary") \(code)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> AdaptiveClaimSummary {
            return AdaptiveClaimSummary(
                code: code,
                title: title,
                summary: summary,
                threshold: threshold,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive claim summary in status created.
    static func newAdaptiveClaimSummary(_ code: String, title: String) -> AdaptiveClaimSummary {
        return AdaptiveClaimSummary(
            code: code,
            title: title,
            summary: "",
            threshold: 0.0,
            clinicianID: "",
            status: AdaptiveClaimSummaryStatus.created
        )
    }
}
