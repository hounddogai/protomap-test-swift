import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal checkpoint is in its life cycle.
    enum GoalCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A goal checkpoint. Its code is unique within a tenant.
    final class GoalCheckpoint {
        var code: String
        var title: String
        var floorValue: Double
        var channel: String
        var specialty: String
        var status: GoalCheckpointStatus

        init(code: String, title: String, floorValue: Double, channel: String, specialty: String, status: GoalCheckpointStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.channel = channel
            self.specialty = specialty
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

        func canMoveTo(_ next: GoalCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == GoalCheckpointStatus.active || next == GoalCheckpointStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == GoalCheckpointStatus.suspended || next == GoalCheckpointStatus.closed
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

        func moveTo(_ next: GoalCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> GoalCheckpoint {
            return GoalCheckpoint(
                code: code,
                title: title,
                floorValue: floorValue,
                channel: channel,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a goal checkpoint in status draft.
    static func newGoalCheckpoint(_ code: String, title: String) -> GoalCheckpoint {
        return GoalCheckpoint(
            code: code,
            title: title,
            floorValue: 0.0,
            channel: "",
            specialty: "",
            status: GoalCheckpointStatus.draft
        )
    }
}
