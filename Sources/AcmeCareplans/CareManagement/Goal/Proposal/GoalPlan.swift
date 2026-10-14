import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal plan is in its life cycle.
    enum GoalPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A goal plan. Its code is unique within a tenant.
    final class GoalPlan {
        var code: String
        var name: String
        var capacity: Int
        var reviewer: String
        var visitMinutes: Int
        var status: GoalPlanStatus

        init(code: String, name: String, capacity: Int, reviewer: String, visitMinutes: Int, status: GoalPlanStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.reviewer = reviewer
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: GoalPlanStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == GoalPlanStatus.withdrawn
            case .rejected:
                return next == GoalPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("goal plan") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(capacity) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> GoalPlan {
            return GoalPlan(
                code: code,
                name: name,
                capacity: capacity,
                reviewer: reviewer,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a goal plan in status proposed.
    static func newGoalPlan(_ code: String, name: String) -> GoalPlan {
        return GoalPlan(
            code: code,
            name: name,
            capacity: 0,
            reviewer: "",
            visitMinutes: 0,
            status: GoalPlanStatus.proposed
        )
    }
}
