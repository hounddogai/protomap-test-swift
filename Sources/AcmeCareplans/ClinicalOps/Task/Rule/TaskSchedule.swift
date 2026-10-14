import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task schedule is in its life cycle.
    enum TaskScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One task schedule, with what the planners need to act on it.
    final class TaskSchedule {
        var code: String
        var name: String
        var minimum: Double
        var attributes: [String: String]
        var notes: String
        var status: TaskScheduleStatus

        init(code: String, name: String, minimum: Double, attributes: [String: String], notes: String, status: TaskScheduleStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.attributes = attributes
            self.notes = notes
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

        func canMoveTo(_ next: TaskScheduleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TaskScheduleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> TaskSchedule {
            return TaskSchedule(
                code: code,
                name: name,
                minimum: minimum,
                attributes: attributes,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a task schedule in status draft.
    static func newTaskSchedule(_ code: String, name: String) -> TaskSchedule {
        return TaskSchedule(
            code: code,
            name: name,
            minimum: 0.0,
            attributes: [:],
            notes: "",
            status: TaskScheduleStatus.draft
        )
    }
}
