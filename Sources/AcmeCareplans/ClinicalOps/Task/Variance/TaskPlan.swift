import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task plan is in its life cycle.
    enum TaskPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One task plan, with what the planners need to act on it.
    final class TaskPlan {
        var code: String
        var label: String
        var approved: Bool
        var priority: Int
        var durationMinutes: Int
        var sequence: Int
        var retries: Int
        var status: TaskPlanStatus

        init(code: String, label: String, approved: Bool, priority: Int, durationMinutes: Int, sequence: Int, retries: Int, status: TaskPlanStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.sequence = sequence
            self.retries = retries
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

        func canMoveTo(_ next: TaskPlanStatus) -> Bool {
            switch status {
            case .planned:
                return next == TaskPlanStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == TaskPlanStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(durationMinutes) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> TaskPlan {
            return TaskPlan(
                code: code,
                label: label,
                approved: approved,
                priority: priority,
                durationMinutes: durationMinutes,
                sequence: sequence,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task plan in status planned.
    static func newTaskPlan(_ code: String, label: String) -> TaskPlan {
        return TaskPlan(
            code: code,
            label: label,
            approved: false,
            priority: 0,
            durationMinutes: 0,
            sequence: 0,
            retries: 0,
            status: TaskPlanStatus.planned
        )
    }
}
