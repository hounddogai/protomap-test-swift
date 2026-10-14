import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range summary is in its life cycle.
    enum ReferenceRangeSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One reference range summary, with what the planners need to act on it.
    final class ReferenceRangeSummary {
        var code: String
        var label: String
        var acuity: Int
        var budget: Double
        var batchSize: Int
        var clinicianID: String
        var ceiling: Double
        var summary: String
        var margin: Double
        var graceDays: Int
        var pinned: Bool
        var status: ReferenceRangeSummaryStatus

        init(code: String, label: String, acuity: Int, budget: Double, batchSize: Int, clinicianID: String, ceiling: Double, summary: String, margin: Double, graceDays: Int, pinned: Bool, status: ReferenceRangeSummaryStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.budget = budget
            self.batchSize = batchSize
            self.clinicianID = clinicianID
            self.ceiling = ceiling
            self.summary = summary
            self.margin = margin
            self.graceDays = graceDays
            self.pinned = pinned
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

        func canMoveTo(_ next: ReferenceRangeSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReferenceRangeSummaryStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReferenceRangeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return (Double(acuity) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeSummary {
            return ReferenceRangeSummary(
                code: code,
                label: label,
                acuity: acuity,
                budget: budget,
                batchSize: batchSize,
                clinicianID: clinicianID,
                ceiling: ceiling,
                summary: summary,
                margin: margin,
                graceDays: graceDays,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a reference range summary in status idle.
    static func newReferenceRangeSummary(_ code: String, label: String) -> ReferenceRangeSummary {
        return ReferenceRangeSummary(
            code: code,
            label: label,
            acuity: 0,
            budget: 0.0,
            batchSize: 0,
            clinicianID: "",
            ceiling: 0.0,
            summary: "",
            margin: 0.0,
            graceDays: 0,
            pinned: false,
            status: ReferenceRangeSummaryStatus.idle
        )
    }
}
