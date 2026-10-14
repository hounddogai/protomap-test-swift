import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback statement assignment is in its life cycle.
    enum FallbackStatementAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback statement assignment as the statement team keeps it.
    final class FallbackStatementAssignment {
        var code: String
        var title: String
        var discount: Double
        var windowDays: Int
        var reviewer: String
        var cost: Double
        var amount: Double
        var createdAt: Int
        var description: String
        var endsAt: Int
        var status: FallbackStatementAssignmentStatus

        init(code: String, title: String, discount: Double, windowDays: Int, reviewer: String, cost: Double, amount: Double, createdAt: Int, description: String, endsAt: Int, status: FallbackStatementAssignmentStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.windowDays = windowDays
            self.reviewer = reviewer
            self.cost = cost
            self.amount = amount
            self.createdAt = createdAt
            self.description = description
            self.endsAt = endsAt
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

        func canMoveTo(_ next: FallbackStatementAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackStatementAssignmentStatus.completed
            case .scheduled:
                return next == FallbackStatementAssignmentStatus.completed || next == FallbackStatementAssignmentStatus.cancelled
            case .inProgress:
                return next == FallbackStatementAssignmentStatus.cancelled
            case .completed:
                return next == FallbackStatementAssignmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackStatementAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback statement assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return (cost * discount * 100).rounded() / 100
        }

        func copyValue() -> FallbackStatementAssignment {
            return FallbackStatementAssignment(
                code: code,
                title: title,
                discount: discount,
                windowDays: windowDays,
                reviewer: reviewer,
                cost: cost,
                amount: amount,
                createdAt: createdAt,
                description: description,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback statement assignment in status planned.
    static func newFallbackStatementAssignment(_ code: String, title: String) -> FallbackStatementAssignment {
        return FallbackStatementAssignment(
            code: code,
            title: title,
            discount: 0.0,
            windowDays: 0,
            reviewer: "",
            cost: 0.0,
            amount: 0.0,
            createdAt: 0,
            description: "",
            endsAt: 0,
            status: FallbackStatementAssignmentStatus.planned
        )
    }
}
