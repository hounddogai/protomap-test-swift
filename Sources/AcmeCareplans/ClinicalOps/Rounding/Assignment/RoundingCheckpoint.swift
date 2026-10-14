import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding checkpoint is in its life cycle.
    enum RoundingCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a rounding checkpoint and its current status.
    final class RoundingCheckpoint {
        var code: String
        var label: String
        var rate: Double
        var procedureCode: String
        var diagnosisCode: String
        var status: RoundingCheckpointStatus

        init(code: String, label: String, rate: Double, procedureCode: String, diagnosisCode: String, status: RoundingCheckpointStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.procedureCode = procedureCode
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: RoundingCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == RoundingCheckpointStatus.revoked || next == RoundingCheckpointStatus.expired
            case .granted:
                return next == RoundingCheckpointStatus.expired
            case .revoked:
                return next == RoundingCheckpointStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> RoundingCheckpoint {
            return RoundingCheckpoint(
                code: code,
                label: label,
                rate: rate,
                procedureCode: procedureCode,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rounding checkpoint in status requested.
    static func newRoundingCheckpoint(_ code: String, label: String) -> RoundingCheckpoint {
        return RoundingCheckpoint(
            code: code,
            label: label,
            rate: 0.0,
            procedureCode: "",
            diagnosisCode: "",
            status: RoundingCheckpointStatus.requested
        )
    }
}
