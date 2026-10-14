import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary acuity plan snapshot is in its life cycle.
    enum PrimaryAcuityPlanSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a primary acuity plan snapshot and its current status.
    final class PrimaryAcuityPlanSnapshot {
        var code: String
        var label: String
        var diagnosisCode: String
        var archived: Bool
        var patientRef: String
        var score: Double
        var status: PrimaryAcuityPlanSnapshotStatus

        init(code: String, label: String, diagnosisCode: String, archived: Bool, patientRef: String, score: Double, status: PrimaryAcuityPlanSnapshotStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.patientRef = patientRef
            self.score = score
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

        func canMoveTo(_ next: PrimaryAcuityPlanSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryAcuityPlanSnapshotStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PrimaryAcuityPlanSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary acuity plan snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary acuity plan snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PrimaryAcuityPlanSnapshot {
            return PrimaryAcuityPlanSnapshot(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                archived: archived,
                patientRef: patientRef,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary acuity plan snapshot in status requested.
    static func newPrimaryAcuityPlanSnapshot(_ code: String, label: String) -> PrimaryAcuityPlanSnapshot {
        return PrimaryAcuityPlanSnapshot(
            code: code,
            label: label,
            diagnosisCode: "",
            archived: false,
            patientRef: "",
            score: 0.0,
            status: PrimaryAcuityPlanSnapshotStatus.requested
        )
    }
}
