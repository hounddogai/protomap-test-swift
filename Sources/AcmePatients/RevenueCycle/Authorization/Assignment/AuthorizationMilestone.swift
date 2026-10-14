import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization milestone is in its life cycle.
    enum AuthorizationMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A authorization milestone as the authorization team keeps it.
    final class AuthorizationMilestone {
        var code: String
        var title: String
        var facility: String
        var category: String
        var retries: Int
        var ratio: Double
        var status: AuthorizationMilestoneStatus

        init(code: String, title: String, facility: String, category: String, retries: Int, ratio: Double, status: AuthorizationMilestoneStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.category = category
            self.retries = retries
            self.ratio = ratio
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

        func canMoveTo(_ next: AuthorizationMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AuthorizationMilestoneStatus.draining
            case .ready:
                return next == AuthorizationMilestoneStatus.draining || next == AuthorizationMilestoneStatus.stopped
            case .draining:
                return next == AuthorizationMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return ((Double(retries) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationMilestone {
            return AuthorizationMilestone(
                code: code,
                title: title,
                facility: facility,
                category: category,
                retries: retries,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a authorization milestone in status idle.
    static func newAuthorizationMilestone(_ code: String, title: String) -> AuthorizationMilestone {
        return AuthorizationMilestone(
            code: code,
            title: title,
            facility: "",
            category: "",
            retries: 0,
            ratio: 0.0,
            status: AuthorizationMilestoneStatus.idle
        )
    }
}
