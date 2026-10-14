import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched cleaning cycle is in its life cycle.
    enum BatchedCleaningCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a batched cleaning cycle and its current status.
    final class BatchedCleaningCycle {
        var code: String
        var title: String
        var category: String
        var maximum: Double
        var priority: Int
        var pinned: Bool
        var currency: String
        var status: BatchedCleaningCycleStatus

        init(code: String, title: String, category: String, maximum: Double, priority: Int, pinned: Bool, currency: String, status: BatchedCleaningCycleStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.maximum = maximum
            self.priority = priority
            self.pinned = pinned
            self.currency = currency
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

        func canMoveTo(_ next: BatchedCleaningCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedCleaningCycleStatus.resolved
            case .inReview:
                return next == BatchedCleaningCycleStatus.archived
            case .resolved:
                return next == BatchedCleaningCycleStatus.reopened
            case .reopened:
                return next == BatchedCleaningCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCleaningCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched cleaning cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((Double(priority) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCleaningCycle {
            return BatchedCleaningCycle(
                code: code,
                title: title,
                category: category,
                maximum: maximum,
                priority: priority,
                pinned: pinned,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched cleaning cycle in status open.
    static func newBatchedCleaningCycle(_ code: String, title: String) -> BatchedCleaningCycle {
        return BatchedCleaningCycle(
            code: code,
            title: title,
            category: "",
            maximum: 0.0,
            priority: 0,
            pinned: false,
            currency: "",
            status: BatchedCleaningCycleStatus.`open`
        )
    }
}
