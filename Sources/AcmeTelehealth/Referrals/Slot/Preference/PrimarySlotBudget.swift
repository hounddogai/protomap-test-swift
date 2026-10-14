import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary slot budget is in its life cycle.
    enum PrimarySlotBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary slot budget as the slot team keeps it.
    final class PrimarySlotBudget {
        var code: String
        var title: String
        var cost: Double
        var attempts: Int
        var label: String
        var visible: Bool
        var version: Int
        var score: Double
        var updatedAt: Int
        var timezone: String
        var status: PrimarySlotBudgetStatus

        init(code: String, title: String, cost: Double, attempts: Int, label: String, visible: Bool, version: Int, score: Double, updatedAt: Int, timezone: String, status: PrimarySlotBudgetStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.attempts = attempts
            self.label = label
            self.visible = visible
            self.version = version
            self.score = score
            self.updatedAt = updatedAt
            self.timezone = timezone
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

        func canMoveTo(_ next: PrimarySlotBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimarySlotBudgetStatus.inProgress || next == PrimarySlotBudgetStatus.completed
            case .scheduled:
                return next == PrimarySlotBudgetStatus.completed
            case .inProgress:
                return next == PrimarySlotBudgetStatus.cancelled
            case .completed:
                return next == PrimarySlotBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySlotBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary slot budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return ((cost + score) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySlotBudget {
            return PrimarySlotBudget(
                code: code,
                title: title,
                cost: cost,
                attempts: attempts,
                label: label,
                visible: visible,
                version: version,
                score: score,
                updatedAt: updatedAt,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary slot budget in status planned.
    static func newPrimarySlotBudget(_ code: String, title: String) -> PrimarySlotBudget {
        return PrimarySlotBudget(
            code: code,
            title: title,
            cost: 0.0,
            attempts: 0,
            label: "",
            visible: false,
            version: 0,
            score: 0.0,
            updatedAt: 0,
            timezone: "",
            status: PrimarySlotBudgetStatus.planned
        )
    }
}
