import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient recall milestone is in its life cycle.
    enum LenientRecallMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient recall milestone and its current status.
    final class LenientRecallMilestone {
        var code: String
        var label: String
        var graceDays: Int
        var visitMinutes: Int
        var rate: Double
        var status: LenientRecallMilestoneStatus

        init(code: String, label: String, graceDays: Int, visitMinutes: Int, rate: Double, status: LenientRecallMilestoneStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.visitMinutes = visitMinutes
            self.rate = rate
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

        func canMoveTo(_ next: LenientRecallMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientRecallMilestoneStatus.resolved
            case .inReview:
                return next == LenientRecallMilestoneStatus.reopened || next == LenientRecallMilestoneStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientRecallMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRecallMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient recall milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return (Double(graceDays) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> LenientRecallMilestone {
            return LenientRecallMilestone(
                code: code,
                label: label,
                graceDays: graceDays,
                visitMinutes: visitMinutes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient recall milestone in status open.
    static func newLenientRecallMilestone(_ code: String, label: String) -> LenientRecallMilestone {
        return LenientRecallMilestone(
            code: code,
            label: label,
            graceDays: 0,
            visitMinutes: 0,
            rate: 0.0,
            status: LenientRecallMilestoneStatus.`open`
        )
    }
}
