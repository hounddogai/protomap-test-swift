import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up rule is in its life cycle.
    enum FollowUpRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One follow up rule, with what the planners need to act on it.
    final class FollowUpRule {
        var code: String
        var title: String
        var country: String
        var timezone: String
        var checksum: String
        var version: Int
        var archived: Bool
        var status: FollowUpRuleStatus

        init(code: String, title: String, country: String, timezone: String, checksum: String, version: Int, archived: Bool, status: FollowUpRuleStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.timezone = timezone
            self.checksum = checksum
            self.version = version
            self.archived = archived
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

        func canMoveTo(_ next: FollowUpRuleStatus) -> Bool {
            switch status {
            case .idle:
                return next == FollowUpRuleStatus.draining || next == FollowUpRuleStatus.stopped
            case .warming:
                return next == FollowUpRuleStatus.stopped
            case .ready:
                return next == FollowUpRuleStatus.stopped
            case .draining:
                return next == FollowUpRuleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> FollowUpRule {
            return FollowUpRule(
                code: code,
                title: title,
                country: country,
                timezone: timezone,
                checksum: checksum,
                version: version,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a follow up rule in status idle.
    static func newFollowUpRule(_ code: String, title: String) -> FollowUpRule {
        return FollowUpRule(
            code: code,
            title: title,
            country: "",
            timezone: "",
            checksum: "",
            version: 0,
            archived: false,
            status: FollowUpRuleStatus.idle
        )
    }
}
