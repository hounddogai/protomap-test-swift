import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal schedule is in its life cycle.
    enum GoalScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A goal schedule as the goal team keeps it.
    final class GoalSchedule {
        var code: String
        var name: String
        var score: Double
        var checksum: String
        var minimum: Double
        var startsAt: Int
        var cost: Double
        var encounterID: String
        var ceiling: Double
        var allergy: String
        var ownerID: String
        var status: GoalScheduleStatus

        init(code: String, name: String, score: Double, checksum: String, minimum: Double, startsAt: Int, cost: Double, encounterID: String, ceiling: Double, allergy: String, ownerID: String, status: GoalScheduleStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.checksum = checksum
            self.minimum = minimum
            self.startsAt = startsAt
            self.cost = cost
            self.encounterID = encounterID
            self.ceiling = ceiling
            self.allergy = allergy
            self.ownerID = ownerID
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

        func canMoveTo(_ next: GoalScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == GoalScheduleStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GoalScheduleStatus.completed
            case .completed:
                return next == GoalScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("goal schedule") \(code)"
        }

        func weightedValue() -> Double {
            return (score * minimum * 100).rounded() / 100
        }

        func copyValue() -> GoalSchedule {
            return GoalSchedule(
                code: code,
                name: name,
                score: score,
                checksum: checksum,
                minimum: minimum,
                startsAt: startsAt,
                cost: cost,
                encounterID: encounterID,
                ceiling: ceiling,
                allergy: allergy,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a goal schedule in status planned.
    static func newGoalSchedule(_ code: String, name: String) -> GoalSchedule {
        return GoalSchedule(
            code: code,
            name: name,
            score: 0.0,
            checksum: "",
            minimum: 0.0,
            startsAt: 0,
            cost: 0.0,
            encounterID: "",
            ceiling: 0.0,
            allergy: "",
            ownerID: "",
            status: GoalScheduleStatus.planned
        )
    }
}
