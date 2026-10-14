import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot budget is in its life cycle.
    enum SlotBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One slot budget, with what the planners need to act on it.
    final class SlotBudget {
        var code: String
        var title: String
        var threshold: Double
        var priority: Int
        var createdAt: Int
        var currency: String
        var durationMinutes: Int
        var discount: Double
        var status: SlotBudgetStatus

        init(code: String, title: String, threshold: Double, priority: Int, createdAt: Int, currency: String, durationMinutes: Int, discount: Double, status: SlotBudgetStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.priority = priority
            self.createdAt = createdAt
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.discount = discount
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

        func canMoveTo(_ next: SlotBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == SlotBudgetStatus.scheduled
            case .scheduled:
                return next == SlotBudgetStatus.inProgress || next == SlotBudgetStatus.completed
            case .inProgress:
                return next == SlotBudgetStatus.completed || next == SlotBudgetStatus.cancelled
            case .completed:
                return next == SlotBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return (Double(durationMinutes) * discount * 100).rounded() / 100
        }

        func copyValue() -> SlotBudget {
            return SlotBudget(
                code: code,
                title: title,
                threshold: threshold,
                priority: priority,
                createdAt: createdAt,
                currency: currency,
                durationMinutes: durationMinutes,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a slot budget in status planned.
    static func newSlotBudget(_ code: String, title: String) -> SlotBudget {
        return SlotBudget(
            code: code,
            title: title,
            threshold: 0.0,
            priority: 0,
            createdAt: 0,
            currency: "",
            durationMinutes: 0,
            discount: 0.0,
            status: SlotBudgetStatus.planned
        )
    }
}
