import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up bundle is in its life cycle.
    enum FollowUpBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One follow up bundle, with what the planners need to act on it.
    final class FollowUpBundle {
        var code: String
        var label: String
        var capacity: Int
        var threshold: Double
        var weight: Double
        var contactEmail: String
        var visitMinutes: Int
        var status: FollowUpBundleStatus

        init(code: String, label: String, capacity: Int, threshold: Double, weight: Double, contactEmail: String, visitMinutes: Int, status: FollowUpBundleStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.threshold = threshold
            self.weight = weight
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpBundleStatus) -> Bool {
            switch status {
            case .planned:
                return next == FollowUpBundleStatus.scheduled
            case .scheduled:
                return next == FollowUpBundleStatus.inProgress || next == FollowUpBundleStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FollowUpBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("follow up bundle") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(capacity) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpBundle {
            return FollowUpBundle(
                code: code,
                label: label,
                capacity: capacity,
                threshold: threshold,
                weight: weight,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up bundle in status planned.
    static func newFollowUpBundle(_ code: String, label: String) -> FollowUpBundle {
        return FollowUpBundle(
            code: code,
            label: label,
            capacity: 0,
            threshold: 0.0,
            weight: 0.0,
            contactEmail: "",
            visitMinutes: 0,
            status: FollowUpBundleStatus.planned
        )
    }
}
