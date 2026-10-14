import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal estimate is in its life cycle.
    enum GoalEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One goal estimate, with what the planners need to act on it.
    final class GoalEstimate {
        var code: String
        var title: String
        var graceDays: Int
        var encounterID: String
        var ownerID: String
        var visible: Bool
        var status: GoalEstimateStatus

        init(code: String, title: String, graceDays: Int, encounterID: String, ownerID: String, visible: Bool, status: GoalEstimateStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.visible = visible
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

        func canMoveTo(_ next: GoalEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GoalEstimateStatus.inProgress || next == GoalEstimateStatus.completed
            case .inProgress:
                return next == GoalEstimateStatus.completed || next == GoalEstimateStatus.cancelled
            case .completed:
                return next == GoalEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> GoalEstimate {
            return GoalEstimate(
                code: code,
                title: title,
                graceDays: graceDays,
                encounterID: encounterID,
                ownerID: ownerID,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a goal estimate in status planned.
    static func newGoalEstimate(_ code: String, title: String) -> GoalEstimate {
        return GoalEstimate(
            code: code,
            title: title,
            graceDays: 0,
            encounterID: "",
            ownerID: "",
            visible: false,
            status: GoalEstimateStatus.planned
        )
    }
}
