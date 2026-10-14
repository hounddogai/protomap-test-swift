import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling care gap review is in its life cycle.
    enum RollingCareGapReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling care gap review as the care gap team keeps it.
    final class RollingCareGapReview {
        var code: String
        var title: String
        var priority: Int
        var bed: String
        var approved: Bool
        var capacity: Int
        var tags: [String]
        var channel: String
        var acuity: Int
        var sequence: Int
        var status: RollingCareGapReviewStatus

        init(code: String, title: String, priority: Int, bed: String, approved: Bool, capacity: Int, tags: [String], channel: String, acuity: Int, sequence: Int, status: RollingCareGapReviewStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.bed = bed
            self.approved = approved
            self.capacity = capacity
            self.tags = tags
            self.channel = channel
            self.acuity = acuity
            self.sequence = sequence
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

        func canMoveTo(_ next: RollingCareGapReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingCareGapReviewStatus.reopened
            case .inReview:
                return next == RollingCareGapReviewStatus.reopened || next == RollingCareGapReviewStatus.archived
            case .resolved:
                return next == RollingCareGapReviewStatus.reopened
            case .reopened:
                return next == RollingCareGapReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareGapReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care gap review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return (Double(capacity) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareGapReview {
            return RollingCareGapReview(
                code: code,
                title: title,
                priority: priority,
                bed: bed,
                approved: approved,
                capacity: capacity,
                tags: tags,
                channel: channel,
                acuity: acuity,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling care gap review in status open.
    static func newRollingCareGapReview(_ code: String, title: String) -> RollingCareGapReview {
        return RollingCareGapReview(
            code: code,
            title: title,
            priority: 0,
            bed: "",
            approved: false,
            capacity: 0,
            tags: [],
            channel: "",
            acuity: 0,
            sequence: 0,
            status: RollingCareGapReviewStatus.`open`
        )
    }
}
