import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task preference is in its life cycle.
    enum TaskPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A task preference as the task team keeps it.
    final class TaskPreference {
        var code: String
        var title: String
        var ward: String
        var specialty: String
        var revision: Int
        var batchSize: Int
        var source: String
        var externalRef: String
        var approved: Bool
        var graceDays: Int
        var status: TaskPreferenceStatus

        init(code: String, title: String, ward: String, specialty: String, revision: Int, batchSize: Int, source: String, externalRef: String, approved: Bool, graceDays: Int, status: TaskPreferenceStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.specialty = specialty
            self.revision = revision
            self.batchSize = batchSize
            self.source = source
            self.externalRef = externalRef
            self.approved = approved
            self.graceDays = graceDays
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

        func canMoveTo(_ next: TaskPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == TaskPreferenceStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TaskPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(graceDays) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> TaskPreference {
            return TaskPreference(
                code: code,
                title: title,
                ward: ward,
                specialty: specialty,
                revision: revision,
                batchSize: batchSize,
                source: source,
                externalRef: externalRef,
                approved: approved,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a task preference in status planned.
    static func newTaskPreference(_ code: String, title: String) -> TaskPreference {
        return TaskPreference(
            code: code,
            title: title,
            ward: "",
            specialty: "",
            revision: 0,
            batchSize: 0,
            source: "",
            externalRef: "",
            approved: false,
            graceDays: 0,
            status: TaskPreferenceStatus.planned
        )
    }
}
