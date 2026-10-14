import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending outreach baseline is in its life cycle.
    enum PendingOutreachBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending outreach baseline as the outreach team keeps it.
    final class PendingOutreachBaseline {
        var code: String
        var label: String
        var sequence: Int
        var threshold: Double
        var ownerID: String
        var status: PendingOutreachBaselineStatus

        init(code: String, label: String, sequence: Int, threshold: Double, ownerID: String, status: PendingOutreachBaselineStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.threshold = threshold
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingOutreachBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PendingOutreachBaselineStatus.resolved || next == PendingOutreachBaselineStatus.reopened
            case .resolved:
                return next == PendingOutreachBaselineStatus.reopened
            case .reopened:
                return next == PendingOutreachBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingOutreachBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending outreach baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending outreach baseline") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingOutreachBaseline {
            return PendingOutreachBaseline(
                code: code,
                label: label,
                sequence: sequence,
                threshold: threshold,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending outreach baseline in status open.
    static func newPendingOutreachBaseline(_ code: String, label: String) -> PendingOutreachBaseline {
        return PendingOutreachBaseline(
            code: code,
            label: label,
            sequence: 0,
            threshold: 0.0,
            ownerID: "",
            status: PendingOutreachBaselineStatus.`open`
        )
    }
}
