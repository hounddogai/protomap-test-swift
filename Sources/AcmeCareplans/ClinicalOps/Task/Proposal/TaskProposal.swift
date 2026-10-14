import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task proposal is in its life cycle.
    enum TaskProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A task proposal as the task team keeps it.
    final class TaskProposal {
        var code: String
        var title: String
        var name: String
        var retries: Int
        var timezone: String
        var margin: Double
        var facility: String
        var updatedAt: Int
        var description: String
        var specialty: String
        var channel: String
        var status: TaskProposalStatus

        init(code: String, title: String, name: String, retries: Int, timezone: String, margin: Double, facility: String, updatedAt: Int, description: String, specialty: String, channel: String, status: TaskProposalStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.retries = retries
            self.timezone = timezone
            self.margin = margin
            self.facility = facility
            self.updatedAt = updatedAt
            self.description = description
            self.specialty = specialty
            self.channel = channel
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

        func canMoveTo(_ next: TaskProposalStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TaskProposalStatus.completed || next == TaskProposalStatus.cancelled
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

        func moveTo(_ next: TaskProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return (Double(updatedAt) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> TaskProposal {
            return TaskProposal(
                code: code,
                title: title,
                name: name,
                retries: retries,
                timezone: timezone,
                margin: margin,
                facility: facility,
                updatedAt: updatedAt,
                description: description,
                specialty: specialty,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a task proposal in status planned.
    static func newTaskProposal(_ code: String, title: String) -> TaskProposal {
        return TaskProposal(
            code: code,
            title: title,
            name: "",
            retries: 0,
            timezone: "",
            margin: 0.0,
            facility: "",
            updatedAt: 0,
            description: "",
            specialty: "",
            channel: "",
            status: TaskProposalStatus.planned
        )
    }
}
