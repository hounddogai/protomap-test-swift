import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict overtime summary is in its life cycle.
    enum StrictOvertimeSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One strict overtime summary, with what the planners need to act on it.
    final class StrictOvertimeSummary {
        var code: String
        var label: String
        var refills: Int
        var sequence: Int
        var ratio: Double
        var threshold: Double
        var visible: Bool
        var amount: Double
        var diagnosisCode: String
        var title: String
        var status: StrictOvertimeSummaryStatus

        init(code: String, label: String, refills: Int, sequence: Int, ratio: Double, threshold: Double, visible: Bool, amount: Double, diagnosisCode: String, title: String, status: StrictOvertimeSummaryStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.sequence = sequence
            self.ratio = ratio
            self.threshold = threshold
            self.visible = visible
            self.amount = amount
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictOvertimeSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictOvertimeSummaryStatus.expired
            case .granted:
                return next == StrictOvertimeSummaryStatus.expired
            case .revoked:
                return next == StrictOvertimeSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictOvertimeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict overtime summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict overtime summary") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(refills) + amount) * 100).rounded() / 100
        }

        func copyValue() -> StrictOvertimeSummary {
            return StrictOvertimeSummary(
                code: code,
                label: label,
                refills: refills,
                sequence: sequence,
                ratio: ratio,
                threshold: threshold,
                visible: visible,
                amount: amount,
                diagnosisCode: diagnosisCode,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict overtime summary in status requested.
    static func newStrictOvertimeSummary(_ code: String, label: String) -> StrictOvertimeSummary {
        return StrictOvertimeSummary(
            code: code,
            label: label,
            refills: 0,
            sequence: 0,
            ratio: 0.0,
            threshold: 0.0,
            visible: false,
            amount: 0.0,
            diagnosisCode: "",
            title: "",
            status: StrictOvertimeSummaryStatus.requested
        )
    }
}
