import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default task proposal is in its life cycle.
    enum DefaultTaskProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One default task proposal, with what the planners need to act on it.
    final class DefaultTaskProposal {
        var code: String
        var label: String
        var ward: String
        var maximum: Double
        var visible: Bool
        var copay: Double
        var durationMinutes: Int
        var score: Double
        var threshold: Double
        var reviewer: String
        var status: DefaultTaskProposalStatus

        init(code: String, label: String, ward: String, maximum: Double, visible: Bool, copay: Double, durationMinutes: Int, score: Double, threshold: Double, reviewer: String, status: DefaultTaskProposalStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.maximum = maximum
            self.visible = visible
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.score = score
            self.threshold = threshold
            self.reviewer = reviewer
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

        func canMoveTo(_ next: DefaultTaskProposalStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultTaskProposalStatus.rejected || next == DefaultTaskProposalStatus.withdrawn
            case .approved:
                return next == DefaultTaskProposalStatus.rejected || next == DefaultTaskProposalStatus.withdrawn
            case .rejected:
                return next == DefaultTaskProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultTaskProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default task proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((copay + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultTaskProposal {
            return DefaultTaskProposal(
                code: code,
                label: label,
                ward: ward,
                maximum: maximum,
                visible: visible,
                copay: copay,
                durationMinutes: durationMinutes,
                score: score,
                threshold: threshold,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default task proposal in status proposed.
    static func newDefaultTaskProposal(_ code: String, label: String) -> DefaultTaskProposal {
        return DefaultTaskProposal(
            code: code,
            label: label,
            ward: "",
            maximum: 0.0,
            visible: false,
            copay: 0.0,
            durationMinutes: 0,
            score: 0.0,
            threshold: 0.0,
            reviewer: "",
            status: DefaultTaskProposalStatus.proposed
        )
    }
}
