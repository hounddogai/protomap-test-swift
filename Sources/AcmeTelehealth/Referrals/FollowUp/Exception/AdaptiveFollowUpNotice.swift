import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive follow up notice is in its life cycle.
    enum AdaptiveFollowUpNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive follow up notice, with what the planners need to act on it.
    final class AdaptiveFollowUpNotice {
        var code: String
        var label: String
        var windowDays: Int
        var tags: [String]
        var priority: Int
        var timezone: String
        var minimum: Double
        var status: AdaptiveFollowUpNoticeStatus

        init(code: String, label: String, windowDays: Int, tags: [String], priority: Int, timezone: String, minimum: Double, status: AdaptiveFollowUpNoticeStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.tags = tags
            self.priority = priority
            self.timezone = timezone
            self.minimum = minimum
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

        func canMoveTo(_ next: AdaptiveFollowUpNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveFollowUpNoticeStatus.reopened
            case .inReview:
                return next == AdaptiveFollowUpNoticeStatus.resolved || next == AdaptiveFollowUpNoticeStatus.archived
            case .resolved:
                return next == AdaptiveFollowUpNoticeStatus.reopened
            case .reopened:
                return next == AdaptiveFollowUpNoticeStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveFollowUpNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive follow up notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive follow up notice") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((Double(priority) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFollowUpNotice {
            return AdaptiveFollowUpNotice(
                code: code,
                label: label,
                windowDays: windowDays,
                tags: tags,
                priority: priority,
                timezone: timezone,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive follow up notice in status open.
    static func newAdaptiveFollowUpNotice(_ code: String, label: String) -> AdaptiveFollowUpNotice {
        return AdaptiveFollowUpNotice(
            code: code,
            label: label,
            windowDays: 0,
            tags: [],
            priority: 0,
            timezone: "",
            minimum: 0.0,
            status: AdaptiveFollowUpNoticeStatus.`open`
        )
    }
}
