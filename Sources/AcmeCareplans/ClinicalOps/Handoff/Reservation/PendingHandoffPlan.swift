import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending handoff plan is in its life cycle.
    enum PendingHandoffPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending handoff plan as the handoff team keeps it.
    final class PendingHandoffPlan {
        var code: String
        var label: String
        var approved: Bool
        var weight: Double
        var updatedAt: Int
        var reviewer: String
        var title: String
        var amount: Double
        var priority: Int
        var status: PendingHandoffPlanStatus

        init(code: String, label: String, approved: Bool, weight: Double, updatedAt: Int, reviewer: String, title: String, amount: Double, priority: Int, status: PendingHandoffPlanStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.weight = weight
            self.updatedAt = updatedAt
            self.reviewer = reviewer
            self.title = title
            self.amount = amount
            self.priority = priority
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

        func canMoveTo(_ next: PendingHandoffPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingHandoffPlanStatus.active || next == PendingHandoffPlanStatus.closed
            case .pending:
                return next == PendingHandoffPlanStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PendingHandoffPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending handoff plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending handoff plan") \(code)"
        }

        func effectiveValue() -> Double {
            return ((amount - weight) * 100).rounded() / 100
        }

        func copyValue() -> PendingHandoffPlan {
            return PendingHandoffPlan(
                code: code,
                label: label,
                approved: approved,
                weight: weight,
                updatedAt: updatedAt,
                reviewer: reviewer,
                title: title,
                amount: amount,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending handoff plan in status draft.
    static func newPendingHandoffPlan(_ code: String, label: String) -> PendingHandoffPlan {
        return PendingHandoffPlan(
            code: code,
            label: label,
            approved: false,
            weight: 0.0,
            updatedAt: 0,
            reviewer: "",
            title: "",
            amount: 0.0,
            priority: 0,
            status: PendingHandoffPlanStatus.draft
        )
    }
}
