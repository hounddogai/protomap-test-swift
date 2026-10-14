import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score checkpoint is in its life cycle.
    enum RiskScoreCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One risk score checkpoint, with what the planners need to act on it.
    final class RiskScoreCheckpoint {
        var code: String
        var label: String
        var payer: String
        var description: String
        var ceiling: Double
        var revision: Int
        var patientRef: String
        var status: RiskScoreCheckpointStatus

        init(code: String, label: String, payer: String, description: String, ceiling: Double, revision: Int, patientRef: String, status: RiskScoreCheckpointStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.description = description
            self.ceiling = ceiling
            self.revision = revision
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == RiskScoreCheckpointStatus.draining
            case .warming:
                return next == RiskScoreCheckpointStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RiskScoreCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((ceiling + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreCheckpoint {
            return RiskScoreCheckpoint(
                code: code,
                label: label,
                payer: payer,
                description: description,
                ceiling: ceiling,
                revision: revision,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a risk score checkpoint in status idle.
    static func newRiskScoreCheckpoint(_ code: String, label: String) -> RiskScoreCheckpoint {
        return RiskScoreCheckpoint(
            code: code,
            label: label,
            payer: "",
            description: "",
            ceiling: 0.0,
            revision: 0,
            patientRef: "",
            status: RiskScoreCheckpointStatus.idle
        )
    }
}
