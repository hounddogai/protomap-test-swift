import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched task proposal is in its life cycle.
    enum BatchedTaskProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched task proposal as the task team keeps it.
    final class BatchedTaskProposal {
        var code: String
        var label: String
        var visible: Bool
        var timezone: String
        var phone: String
        var score: Double
        var status: BatchedTaskProposalStatus

        init(code: String, label: String, visible: Bool, timezone: String, phone: String, score: Double, status: BatchedTaskProposalStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.timezone = timezone
            self.phone = phone
            self.score = score
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

        func canMoveTo(_ next: BatchedTaskProposalStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedTaskProposalStatus.suspended
            case .pending:
                return next == BatchedTaskProposalStatus.active
            case .active:
                return next == BatchedTaskProposalStatus.suspended || next == BatchedTaskProposalStatus.closed
            case .suspended:
                return next == BatchedTaskProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedTaskProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched task proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> BatchedTaskProposal {
            return BatchedTaskProposal(
                code: code,
                label: label,
                visible: visible,
                timezone: timezone,
                phone: phone,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched task proposal in status draft.
    static func newBatchedTaskProposal(_ code: String, label: String) -> BatchedTaskProposal {
        return BatchedTaskProposal(
            code: code,
            label: label,
            visible: false,
            timezone: "",
            phone: "",
            score: 0.0,
            status: BatchedTaskProposalStatus.draft
        )
    }
}
