import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched interaction budget is in its life cycle.
    enum BatchedInteractionBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One batched interaction budget, with what the planners need to act on it.
    final class BatchedInteractionBudget {
        var code: String
        var title: String
        var revision: Int
        var archived: Bool
        var source: String
        var status: BatchedInteractionBudgetStatus

        init(code: String, title: String, revision: Int, archived: Bool, source: String, status: BatchedInteractionBudgetStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.archived = archived
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedInteractionBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedInteractionBudgetStatus.scheduled || next == BatchedInteractionBudgetStatus.inProgress
            case .scheduled:
                return next == BatchedInteractionBudgetStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == BatchedInteractionBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedInteractionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched interaction budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> BatchedInteractionBudget {
            return BatchedInteractionBudget(
                code: code,
                title: title,
                revision: revision,
                archived: archived,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched interaction budget in status planned.
    static func newBatchedInteractionBudget(_ code: String, title: String) -> BatchedInteractionBudget {
        return BatchedInteractionBudget(
            code: code,
            title: title,
            revision: 0,
            archived: false,
            source: "",
            status: BatchedInteractionBudgetStatus.planned
        )
    }
}
