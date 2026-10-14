import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task assignment is in its life cycle.
    enum TaskAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a task assignment and its current status.
    final class TaskAssignment {
        var code: String
        var name: String
        var createdAt: Int
        var version: Int
        var encounterID: String
        var acuity: Int
        var approved: Bool
        var label: String
        var discount: Double
        var status: TaskAssignmentStatus

        init(code: String, name: String, createdAt: Int, version: Int, encounterID: String, acuity: Int, approved: Bool, label: String, discount: Double, status: TaskAssignmentStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.version = version
            self.encounterID = encounterID
            self.acuity = acuity
            self.approved = approved
            self.label = label
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == TaskAssignmentStatus.published
            case .published:
                return next == TaskAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("task assignment") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(createdAt) + discount) * 100).rounded() / 100
        }

        func copyValue() -> TaskAssignment {
            return TaskAssignment(
                code: code,
                name: name,
                createdAt: createdAt,
                version: version,
                encounterID: encounterID,
                acuity: acuity,
                approved: approved,
                label: label,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a task assignment in status created.
    static func newTaskAssignment(_ code: String, name: String) -> TaskAssignment {
        return TaskAssignment(
            code: code,
            name: name,
            createdAt: 0,
            version: 0,
            encounterID: "",
            acuity: 0,
            approved: false,
            label: "",
            discount: 0.0,
            status: TaskAssignmentStatus.created
        )
    }
}
