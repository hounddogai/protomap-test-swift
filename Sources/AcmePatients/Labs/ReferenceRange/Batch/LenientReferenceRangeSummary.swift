import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient reference range summary is in its life cycle.
    enum LenientReferenceRangeSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient reference range summary. Its code is unique within a tenant.
    final class LenientReferenceRangeSummary {
        var code: String
        var label: String
        var endsAt: Int
        var channel: String
        var limit: Int
        var ceiling: Double
        var margin: Double
        var dosageMg: Double
        var minimum: Double
        var budget: Double
        var clinicianID: String
        var status: LenientReferenceRangeSummaryStatus

        init(code: String, label: String, endsAt: Int, channel: String, limit: Int, ceiling: Double, margin: Double, dosageMg: Double, minimum: Double, budget: Double, clinicianID: String, status: LenientReferenceRangeSummaryStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.channel = channel
            self.limit = limit
            self.ceiling = ceiling
            self.margin = margin
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.budget = budget
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: LenientReferenceRangeSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientReferenceRangeSummaryStatus.warming
            case .warming:
                return next == LenientReferenceRangeSummaryStatus.draining || next == LenientReferenceRangeSummaryStatus.stopped
            case .ready:
                return next == LenientReferenceRangeSummaryStatus.stopped
            case .draining:
                return next == LenientReferenceRangeSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReferenceRangeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient reference range summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveExposure() -> Double {
            return (margin * budget * 100).rounded() / 100
        }

        func copyValue() -> LenientReferenceRangeSummary {
            return LenientReferenceRangeSummary(
                code: code,
                label: label,
                endsAt: endsAt,
                channel: channel,
                limit: limit,
                ceiling: ceiling,
                margin: margin,
                dosageMg: dosageMg,
                minimum: minimum,
                budget: budget,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a lenient reference range summary in status idle.
    static func newLenientReferenceRangeSummary(_ code: String, label: String) -> LenientReferenceRangeSummary {
        return LenientReferenceRangeSummary(
            code: code,
            label: label,
            endsAt: 0,
            channel: "",
            limit: 0,
            ceiling: 0.0,
            margin: 0.0,
            dosageMg: 0.0,
            minimum: 0.0,
            budget: 0.0,
            clinicianID: "",
            status: LenientReferenceRangeSummaryStatus.idle
        )
    }
}
