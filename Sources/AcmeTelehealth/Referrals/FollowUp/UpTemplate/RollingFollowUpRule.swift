import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling follow up rule is in its life cycle.
    enum RollingFollowUpRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling follow up rule. Its code is unique within a tenant.
    final class RollingFollowUpRule {
        var code: String
        var name: String
        var margin: Double
        var contactEmail: String
        var quantity: Int
        var active: Bool
        var status: RollingFollowUpRuleStatus

        init(code: String, name: String, margin: Double, contactEmail: String, quantity: Int, active: Bool, status: RollingFollowUpRuleStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingFollowUpRuleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingFollowUpRuleStatus.rejected
            case .approved:
                return next == RollingFollowUpRuleStatus.rejected || next == RollingFollowUpRuleStatus.withdrawn
            case .rejected:
                return next == RollingFollowUpRuleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingFollowUpRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling follow up rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveExposure() -> Double {
            return (Double(quantity) * margin * 100).rounded() / 100
        }

        func copyValue() -> RollingFollowUpRule {
            return RollingFollowUpRule(
                code: code,
                name: name,
                margin: margin,
                contactEmail: contactEmail,
                quantity: quantity,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling follow up rule in status proposed.
    static func newRollingFollowUpRule(_ code: String, name: String) -> RollingFollowUpRule {
        return RollingFollowUpRule(
            code: code,
            name: name,
            margin: 0.0,
            contactEmail: "",
            quantity: 0,
            active: false,
            status: RollingFollowUpRuleStatus.proposed
        )
    }
}
