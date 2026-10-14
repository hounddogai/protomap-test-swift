import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task score is in its life cycle.
    enum TaskScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A task score as the task team keeps it.
    final class TaskScore {
        var code: String
        var name: String
        var revision: Int
        var discount: Double
        var facility: String
        var specialty: String
        var title: String
        var status: TaskScoreStatus

        init(code: String, name: String, revision: Int, discount: Double, facility: String, specialty: String, title: String, status: TaskScoreStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.discount = discount
            self.facility = facility
            self.specialty = specialty
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == TaskScoreStatus.revoked
            case .granted:
                return next == TaskScoreStatus.revoked || next == TaskScoreStatus.expired
            case .revoked:
                return next == TaskScoreStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return (Double(revision) * discount * 100).rounded() / 100
        }

        func copyValue() -> TaskScore {
            return TaskScore(
                code: code,
                name: name,
                revision: revision,
                discount: discount,
                facility: facility,
                specialty: specialty,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a task score in status requested.
    static func newTaskScore(_ code: String, name: String) -> TaskScore {
        return TaskScore(
            code: code,
            name: name,
            revision: 0,
            discount: 0.0,
            facility: "",
            specialty: "",
            title: "",
            status: TaskScoreStatus.requested
        )
    }
}
