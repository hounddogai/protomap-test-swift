import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending task proposal is in its life cycle.
    enum PendingTaskProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending task proposal as the task team keeps it.
    final class PendingTaskProposal {
        var code: String
        var label: String
        var patientRef: String
        var pinned: Bool
        var description: String
        var copay: Double
        var status: PendingTaskProposalStatus

        init(code: String, label: String, patientRef: String, pinned: Bool, description: String, copay: Double, status: PendingTaskProposalStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.pinned = pinned
            self.description = description
            self.copay = copay
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

        func canMoveTo(_ next: PendingTaskProposalStatus) -> Bool {
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
                return next == PendingTaskProposalStatus.completed
            case .inProgress:
                return next == PendingTaskProposalStatus.cancelled
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

        func moveTo(_ next: PendingTaskProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending task proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> PendingTaskProposal {
            return PendingTaskProposal(
                code: code,
                label: label,
                patientRef: patientRef,
                pinned: pinned,
                description: description,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending task proposal in status planned.
    static func newPendingTaskProposal(_ code: String, label: String) -> PendingTaskProposal {
        return PendingTaskProposal(
            code: code,
            label: label,
            patientRef: "",
            pinned: false,
            description: "",
            copay: 0.0,
            status: PendingTaskProposalStatus.planned
        )
    }
}
