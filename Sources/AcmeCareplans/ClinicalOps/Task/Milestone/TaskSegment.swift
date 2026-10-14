import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task segment is in its life cycle.
    enum TaskSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A task segment. Its code is unique within a tenant.
    final class TaskSegment {
        var code: String
        var name: String
        var description: String
        var facility: String
        var timezone: String
        var maximum: Double
        var status: TaskSegmentStatus

        init(code: String, name: String, description: String, facility: String, timezone: String, maximum: Double, status: TaskSegmentStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.facility = facility
            self.timezone = timezone
            self.maximum = maximum
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

        func canMoveTo(_ next: TaskSegmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == TaskSegmentStatus.scheduled || next == TaskSegmentStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
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
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TaskSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("task segment") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> TaskSegment {
            return TaskSegment(
                code: code,
                name: name,
                description: description,
                facility: facility,
                timezone: timezone,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a task segment in status planned.
    static func newTaskSegment(_ code: String, name: String) -> TaskSegment {
        return TaskSegment(
            code: code,
            name: name,
            description: "",
            facility: "",
            timezone: "",
            maximum: 0.0,
            status: TaskSegmentStatus.planned
        )
    }
}
