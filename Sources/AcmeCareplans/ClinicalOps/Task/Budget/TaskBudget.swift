import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task budget is in its life cycle.
    enum TaskBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One task budget, with what the planners need to act on it.
    final class TaskBudget {
        var code: String
        var label: String
        var updatedAt: Int
        var checksum: String
        var discount: Double
        var sequence: Int
        var graceDays: Int
        var attributes: [String: String]
        var ownerID: String
        var notes: String
        var priority: Int
        var status: TaskBudgetStatus

        init(code: String, label: String, updatedAt: Int, checksum: String, discount: Double, sequence: Int, graceDays: Int, attributes: [String: String], ownerID: String, notes: String, priority: Int, status: TaskBudgetStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.checksum = checksum
            self.discount = discount
            self.sequence = sequence
            self.graceDays = graceDays
            self.attributes = attributes
            self.ownerID = ownerID
            self.notes = notes
            self.priority = priority
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

        func canMoveTo(_ next: TaskBudgetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == TaskBudgetStatus.completed || next == TaskBudgetStatus.cancelled
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

        func moveTo(_ next: TaskBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func weightedTotal() -> Double {
            return ((discount + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> TaskBudget {
            return TaskBudget(
                code: code,
                label: label,
                updatedAt: updatedAt,
                checksum: checksum,
                discount: discount,
                sequence: sequence,
                graceDays: graceDays,
                attributes: attributes,
                ownerID: ownerID,
                notes: notes,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task budget in status planned.
    static func newTaskBudget(_ code: String, label: String) -> TaskBudget {
        return TaskBudget(
            code: code,
            label: label,
            updatedAt: 0,
            checksum: "",
            discount: 0.0,
            sequence: 0,
            graceDays: 0,
            attributes: [:],
            ownerID: "",
            notes: "",
            priority: 0,
            status: TaskBudgetStatus.planned
        )
    }
}
