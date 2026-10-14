import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending claim budget is in its life cycle.
    enum PendingClaimBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending claim budget. Its code is unique within a tenant.
    final class PendingClaimBudget {
        var code: String
        var name: String
        var revision: Int
        var title: String
        var margin: Double
        var status: PendingClaimBudgetStatus

        init(code: String, name: String, revision: Int, title: String, margin: Double, status: PendingClaimBudgetStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.title = title
            self.margin = margin
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

        func canMoveTo(_ next: PendingClaimBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PendingClaimBudgetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingClaimBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending claim budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return ((Double(revision) + margin) * 100).rounded() / 100
        }

        func copyValue() -> PendingClaimBudget {
            return PendingClaimBudget(
                code: code,
                name: name,
                revision: revision,
                title: title,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending claim budget in status proposed.
    static func newPendingClaimBudget(_ code: String, name: String) -> PendingClaimBudget {
        return PendingClaimBudget(
            code: code,
            name: name,
            revision: 0,
            title: "",
            margin: 0.0,
            status: PendingClaimBudgetStatus.proposed
        )
    }
}
