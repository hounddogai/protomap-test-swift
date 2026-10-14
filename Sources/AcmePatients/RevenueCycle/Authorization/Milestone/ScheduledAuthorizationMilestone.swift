import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled authorization milestone is in its life cycle.
    enum ScheduledAuthorizationMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled authorization milestone as the authorization team keeps it.
    final class ScheduledAuthorizationMilestone {
        var code: String
        var name: String
        var reviewer: String
        var expiresAt: Int
        var tags: [String]
        var retries: Int
        var margin: Double
        var contactEmail: String
        var status: ScheduledAuthorizationMilestoneStatus

        init(code: String, name: String, reviewer: String, expiresAt: Int, tags: [String], retries: Int, margin: Double, contactEmail: String, status: ScheduledAuthorizationMilestoneStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.expiresAt = expiresAt
            self.tags = tags
            self.retries = retries
            self.margin = margin
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ScheduledAuthorizationMilestoneStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledAuthorizationMilestoneStatus.queued || next == ScheduledAuthorizationMilestoneStatus.running
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledAuthorizationMilestoneStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledAuthorizationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled authorization milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((margin - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAuthorizationMilestone {
            return ScheduledAuthorizationMilestone(
                code: code,
                name: name,
                reviewer: reviewer,
                expiresAt: expiresAt,
                tags: tags,
                retries: retries,
                margin: margin,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled authorization milestone in status new.
    static func newScheduledAuthorizationMilestone(_ code: String, name: String) -> ScheduledAuthorizationMilestone {
        return ScheduledAuthorizationMilestone(
            code: code,
            name: name,
            reviewer: "",
            expiresAt: 0,
            tags: [],
            retries: 0,
            margin: 0.0,
            contactEmail: "",
            status: ScheduledAuthorizationMilestoneStatus.new
        )
    }
}
