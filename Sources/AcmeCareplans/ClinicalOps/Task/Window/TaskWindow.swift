import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task window is in its life cycle.
    enum TaskWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A task window as the task team keeps it.
    final class TaskWindow {
        var code: String
        var name: String
        var procedureCode: String
        var budget: Double
        var archived: Bool
        var capacity: Int
        var acuity: Int
        var diagnosisCode: String
        var quantity: Int
        var status: TaskWindowStatus

        init(code: String, name: String, procedureCode: String, budget: Double, archived: Bool, capacity: Int, acuity: Int, diagnosisCode: String, quantity: Int, status: TaskWindowStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.budget = budget
            self.archived = archived
            self.capacity = capacity
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
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

        func canMoveTo(_ next: TaskWindowStatus) -> Bool {
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
                return next == TaskWindowStatus.rejected
            case .rejected:
                return next == TaskWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((Double(acuity) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> TaskWindow {
            return TaskWindow(
                code: code,
                name: name,
                procedureCode: procedureCode,
                budget: budget,
                archived: archived,
                capacity: capacity,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a task window in status proposed.
    static func newTaskWindow(_ code: String, name: String) -> TaskWindow {
        return TaskWindow(
            code: code,
            name: name,
            procedureCode: "",
            budget: 0.0,
            archived: false,
            capacity: 0,
            acuity: 0,
            diagnosisCode: "",
            quantity: 0,
            status: TaskWindowStatus.proposed
        )
    }
}
