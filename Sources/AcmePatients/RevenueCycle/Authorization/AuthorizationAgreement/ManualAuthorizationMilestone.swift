import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual authorization milestone is in its life cycle.
    enum ManualAuthorizationMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual authorization milestone as the authorization team keeps it.
    final class ManualAuthorizationMilestone {
        var code: String
        var title: String
        var capacity: Int
        var updatedAt: Int
        var allergy: String
        var status: ManualAuthorizationMilestoneStatus

        init(code: String, title: String, capacity: Int, updatedAt: Int, allergy: String, status: ManualAuthorizationMilestoneStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.allergy = allergy
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

        func canMoveTo(_ next: ManualAuthorizationMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualAuthorizationMilestoneStatus.resolved || next == ManualAuthorizationMilestoneStatus.archived
            case .inReview:
                return next == ManualAuthorizationMilestoneStatus.resolved || next == ManualAuthorizationMilestoneStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualAuthorizationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual authorization milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(capacity) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualAuthorizationMilestone {
            return ManualAuthorizationMilestone(
                code: code,
                title: title,
                capacity: capacity,
                updatedAt: updatedAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual authorization milestone in status open.
    static func newManualAuthorizationMilestone(_ code: String, title: String) -> ManualAuthorizationMilestone {
        return ManualAuthorizationMilestone(
            code: code,
            title: title,
            capacity: 0,
            updatedAt: 0,
            allergy: "",
            status: ManualAuthorizationMilestoneStatus.`open`
        )
    }
}
