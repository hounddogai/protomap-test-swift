import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization plan is in its life cycle.
    enum AuthorizationPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A authorization plan as the authorization team keeps it.
    final class AuthorizationPlan {
        var code: String
        var label: String
        var copay: Double
        var bed: String
        var threshold: Double
        var category: String
        var updatedAt: Int
        var description: String
        var payer: String
        var status: AuthorizationPlanStatus

        init(code: String, label: String, copay: Double, bed: String, threshold: Double, category: String, updatedAt: Int, description: String, payer: String, status: AuthorizationPlanStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.bed = bed
            self.threshold = threshold
            self.category = category
            self.updatedAt = updatedAt
            self.description = description
            self.payer = payer
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

        func canMoveTo(_ next: AuthorizationPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == AuthorizationPlanStatus.closed
            case .pending:
                return next == AuthorizationPlanStatus.suspended || next == AuthorizationPlanStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AuthorizationPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveExposure() -> Double {
            return ((copay - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationPlan {
            return AuthorizationPlan(
                code: code,
                label: label,
                copay: copay,
                bed: bed,
                threshold: threshold,
                category: category,
                updatedAt: updatedAt,
                description: description,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a authorization plan in status draft.
    static func newAuthorizationPlan(_ code: String, label: String) -> AuthorizationPlan {
        return AuthorizationPlan(
            code: code,
            label: label,
            copay: 0.0,
            bed: "",
            threshold: 0.0,
            category: "",
            updatedAt: 0,
            description: "",
            payer: "",
            status: AuthorizationPlanStatus.draft
        )
    }
}
