import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped follow up target is in its life cycle.
    enum CappedFollowUpTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped follow up target as the follow up team keeps it.
    final class CappedFollowUpTarget {
        var code: String
        var title: String
        var amount: Double
        var reviewer: String
        var rate: Double
        var timezone: String
        var channel: String
        var graceDays: Int
        var checksum: String
        var contactEmail: String
        var status: CappedFollowUpTargetStatus

        init(code: String, title: String, amount: Double, reviewer: String, rate: Double, timezone: String, channel: String, graceDays: Int, checksum: String, contactEmail: String, status: CappedFollowUpTargetStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.reviewer = reviewer
            self.rate = rate
            self.timezone = timezone
            self.channel = channel
            self.graceDays = graceDays
            self.checksum = checksum
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: CappedFollowUpTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CappedFollowUpTargetStatus.reopened
            case .resolved:
                return next == CappedFollowUpTargetStatus.archived
            case .reopened:
                return next == CappedFollowUpTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedFollowUpTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped follow up target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return (amount * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> CappedFollowUpTarget {
            return CappedFollowUpTarget(
                code: code,
                title: title,
                amount: amount,
                reviewer: reviewer,
                rate: rate,
                timezone: timezone,
                channel: channel,
                graceDays: graceDays,
                checksum: checksum,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped follow up target in status open.
    static func newCappedFollowUpTarget(_ code: String, title: String) -> CappedFollowUpTarget {
        return CappedFollowUpTarget(
            code: code,
            title: title,
            amount: 0.0,
            reviewer: "",
            rate: 0.0,
            timezone: "",
            channel: "",
            graceDays: 0,
            checksum: "",
            contactEmail: "",
            status: CappedFollowUpTargetStatus.`open`
        )
    }
}
