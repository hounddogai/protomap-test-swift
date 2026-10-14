import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default recall milestone is in its life cycle.
    enum DefaultRecallMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default recall milestone, with what the planners need to act on it.
    final class DefaultRecallMilestone {
        var code: String
        var title: String
        var refills: Int
        var quantity: Int
        var score: Double
        var status: DefaultRecallMilestoneStatus

        init(code: String, title: String, refills: Int, quantity: Int, score: Double, status: DefaultRecallMilestoneStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.quantity = quantity
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRecallMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultRecallMilestoneStatus.revoked || next == DefaultRecallMilestoneStatus.expired
            case .granted:
                return next == DefaultRecallMilestoneStatus.revoked || next == DefaultRecallMilestoneStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DefaultRecallMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default recall milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return (Double(refills) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRecallMilestone {
            return DefaultRecallMilestone(
                code: code,
                title: title,
                refills: refills,
                quantity: quantity,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default recall milestone in status requested.
    static func newDefaultRecallMilestone(_ code: String, title: String) -> DefaultRecallMilestone {
        return DefaultRecallMilestone(
            code: code,
            title: title,
            refills: 0,
            quantity: 0,
            score: 0.0,
            status: DefaultRecallMilestoneStatus.requested
        )
    }
}
