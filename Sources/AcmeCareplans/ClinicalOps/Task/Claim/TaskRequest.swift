import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task request is in its life cycle.
    enum TaskRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One task request, with what the planners need to act on it.
    final class TaskRequest {
        var code: String
        var name: String
        var quantity: Int
        var segment: String
        var label: String
        var graceDays: Int
        var notes: String
        var cost: Double
        var maximum: Double
        var bed: String
        var status: TaskRequestStatus

        init(code: String, name: String, quantity: Int, segment: String, label: String, graceDays: Int, notes: String, cost: Double, maximum: Double, bed: String, status: TaskRequestStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.segment = segment
            self.label = label
            self.graceDays = graceDays
            self.notes = notes
            self.cost = cost
            self.maximum = maximum
            self.bed = bed
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

        func canMoveTo(_ next: TaskRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == TaskRequestStatus.active
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
                return next == TaskRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("task request") \(code)"
        }

        func projectedVolume() -> Double {
            return ((maximum - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> TaskRequest {
            return TaskRequest(
                code: code,
                name: name,
                quantity: quantity,
                segment: segment,
                label: label,
                graceDays: graceDays,
                notes: notes,
                cost: cost,
                maximum: maximum,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a task request in status draft.
    static func newTaskRequest(_ code: String, name: String) -> TaskRequest {
        return TaskRequest(
            code: code,
            name: name,
            quantity: 0,
            segment: "",
            label: "",
            graceDays: 0,
            notes: "",
            cost: 0.0,
            maximum: 0.0,
            bed: "",
            status: TaskRequestStatus.draft
        )
    }
}
