import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched follow up plan is in its life cycle.
    enum BatchedFollowUpPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched follow up plan. Its code is unique within a tenant.
    final class BatchedFollowUpPlan {
        var code: String
        var title: String
        var name: String
        var bed: String
        var expiresAt: Int
        var status: BatchedFollowUpPlanStatus

        init(code: String, title: String, name: String, bed: String, expiresAt: Int, status: BatchedFollowUpPlanStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.bed = bed
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: BatchedFollowUpPlanStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == BatchedFollowUpPlanStatus.closed
            case .active:
                return next == BatchedFollowUpPlanStatus.closed
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

        func moveTo(_ next: BatchedFollowUpPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched follow up plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> BatchedFollowUpPlan {
            return BatchedFollowUpPlan(
                code: code,
                title: title,
                name: name,
                bed: bed,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched follow up plan in status draft.
    static func newBatchedFollowUpPlan(_ code: String, title: String) -> BatchedFollowUpPlan {
        return BatchedFollowUpPlan(
            code: code,
            title: title,
            name: "",
            bed: "",
            expiresAt: 0,
            status: BatchedFollowUpPlanStatus.draft
        )
    }
}
