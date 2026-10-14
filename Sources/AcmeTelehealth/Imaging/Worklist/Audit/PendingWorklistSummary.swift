import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending worklist summary is in its life cycle.
    enum PendingWorklistSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending worklist summary. Its code is unique within a tenant.
    final class PendingWorklistSummary {
        var code: String
        var label: String
        var reviewer: String
        var summary: String
        var sequence: Int
        var description: String
        var status: PendingWorklistSummaryStatus

        init(code: String, label: String, reviewer: String, summary: String, sequence: Int, description: String, status: PendingWorklistSummaryStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.summary = summary
            self.sequence = sequence
            self.description = description
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

        func canMoveTo(_ next: PendingWorklistSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PendingWorklistSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingWorklistSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending worklist summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> PendingWorklistSummary {
            return PendingWorklistSummary(
                code: code,
                label: label,
                reviewer: reviewer,
                summary: summary,
                sequence: sequence,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending worklist summary in status new.
    static func newPendingWorklistSummary(_ code: String, label: String) -> PendingWorklistSummary {
        return PendingWorklistSummary(
            code: code,
            label: label,
            reviewer: "",
            summary: "",
            sequence: 0,
            description: "",
            status: PendingWorklistSummaryStatus.new
        )
    }
}
