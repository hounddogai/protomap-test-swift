import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel checkpoint is in its life cycle.
    enum PanelCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a panel checkpoint and its current status.
    final class PanelCheckpoint {
        var code: String
        var label: String
        var retries: Int
        var score: Double
        var weight: Double
        var externalRef: String
        var approved: Bool
        var status: PanelCheckpointStatus

        init(code: String, label: String, retries: Int, score: Double, weight: Double, externalRef: String, approved: Bool, status: PanelCheckpointStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.score = score
            self.weight = weight
            self.externalRef = externalRef
            self.approved = approved
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

        func canMoveTo(_ next: PanelCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PanelCheckpointStatus.approved || next == PanelCheckpointStatus.rejected
            case .approved:
                return next == PanelCheckpointStatus.rejected
            case .rejected:
                return next == PanelCheckpointStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return ((score - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PanelCheckpoint {
            return PanelCheckpoint(
                code: code,
                label: label,
                retries: retries,
                score: score,
                weight: weight,
                externalRef: externalRef,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel checkpoint in status proposed.
    static func newPanelCheckpoint(_ code: String, label: String) -> PanelCheckpoint {
        return PanelCheckpoint(
            code: code,
            label: label,
            retries: 0,
            score: 0.0,
            weight: 0.0,
            externalRef: "",
            approved: false,
            status: PanelCheckpointStatus.proposed
        )
    }
}
