import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task record is in its life cycle.
    enum TaskRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A task record as the task team keeps it.
    final class TaskRecord {
        var code: String
        var label: String
        var name: String
        var batchSize: Int
        var reviewer: String
        var ceiling: Double
        var contactEmail: String
        var phone: String
        var approved: Bool
        var segment: String
        var procedureCode: String
        var status: TaskRecordStatus

        init(code: String, label: String, name: String, batchSize: Int, reviewer: String, ceiling: Double, contactEmail: String, phone: String, approved: Bool, segment: String, procedureCode: String, status: TaskRecordStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.batchSize = batchSize
            self.reviewer = reviewer
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.phone = phone
            self.approved = approved
            self.segment = segment
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: TaskRecordStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TaskRecordStatus.active
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TaskRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return (ceiling * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> TaskRecord {
            return TaskRecord(
                code: code,
                label: label,
                name: name,
                batchSize: batchSize,
                reviewer: reviewer,
                ceiling: ceiling,
                contactEmail: contactEmail,
                phone: phone,
                approved: approved,
                segment: segment,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a task record in status draft.
    static func newTaskRecord(_ code: String, label: String) -> TaskRecord {
        return TaskRecord(
            code: code,
            label: label,
            name: "",
            batchSize: 0,
            reviewer: "",
            ceiling: 0.0,
            contactEmail: "",
            phone: "",
            approved: false,
            segment: "",
            procedureCode: "",
            status: TaskRecordStatus.draft
        )
    }
}
