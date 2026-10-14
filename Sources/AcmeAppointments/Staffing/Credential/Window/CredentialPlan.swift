import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential plan is in its life cycle.
    enum CredentialPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One credential plan, with what the planners need to act on it.
    final class CredentialPlan {
        var code: String
        var label: String
        var title: String
        var approved: Bool
        var pinned: Bool
        var description: String
        var amount: Double
        var status: CredentialPlanStatus

        init(code: String, label: String, title: String, approved: Bool, pinned: Bool, description: String, amount: Double, status: CredentialPlanStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.approved = approved
            self.pinned = pinned
            self.description = description
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialPlanStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CredentialPlanStatus.active || next == CredentialPlanStatus.suspended
            case .active:
                return next == CredentialPlanStatus.suspended
            case .suspended:
                return next == CredentialPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CredentialPlan {
            return CredentialPlan(
                code: code,
                label: label,
                title: title,
                approved: approved,
                pinned: pinned,
                description: description,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a credential plan in status draft.
    static func newCredentialPlan(_ code: String, label: String) -> CredentialPlan {
        return CredentialPlan(
            code: code,
            label: label,
            title: "",
            approved: false,
            pinned: false,
            description: "",
            amount: 0.0,
            status: CredentialPlanStatus.draft
        )
    }
}
