import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist checkpoint is in its life cycle.
    enum WorklistCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A worklist checkpoint. Its code is unique within a tenant.
    final class WorklistCheckpoint {
        var code: String
        var label: String
        var priority: Int
        var specialty: String
        var currency: String
        var phone: String
        var status: WorklistCheckpointStatus

        init(code: String, label: String, priority: Int, specialty: String, currency: String, phone: String, status: WorklistCheckpointStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.specialty = specialty
            self.currency = currency
            self.phone = phone
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

        func canMoveTo(_ next: WorklistCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WorklistCheckpointStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> WorklistCheckpoint {
            return WorklistCheckpoint(
                code: code,
                label: label,
                priority: priority,
                specialty: specialty,
                currency: currency,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a worklist checkpoint in status proposed.
    static func newWorklistCheckpoint(_ code: String, label: String) -> WorklistCheckpoint {
        return WorklistCheckpoint(
            code: code,
            label: label,
            priority: 0,
            specialty: "",
            currency: "",
            phone: "",
            status: WorklistCheckpointStatus.proposed
        )
    }
}
