import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding snapshot is in its life cycle.
    enum RoundingSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rounding snapshot, with what the planners need to act on it.
    final class RoundingSnapshot {
        var code: String
        var name: String
        var locale: String
        var diagnosisCode: String
        var endsAt: Int
        var patientRef: String
        var copay: Double
        var status: RoundingSnapshotStatus

        init(code: String, name: String, locale: String, diagnosisCode: String, endsAt: Int, patientRef: String, copay: Double, status: RoundingSnapshotStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.diagnosisCode = diagnosisCode
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingSnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == RoundingSnapshotStatus.published || next == RoundingSnapshotStatus.retired
            case .validated:
                return next == RoundingSnapshotStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RoundingSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return (copay * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> RoundingSnapshot {
            return RoundingSnapshot(
                code: code,
                name: name,
                locale: locale,
                diagnosisCode: diagnosisCode,
                endsAt: endsAt,
                patientRef: patientRef,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rounding snapshot in status created.
    static func newRoundingSnapshot(_ code: String, name: String) -> RoundingSnapshot {
        return RoundingSnapshot(
            code: code,
            name: name,
            locale: "",
            diagnosisCode: "",
            endsAt: 0,
            patientRef: "",
            copay: 0.0,
            status: RoundingSnapshotStatus.created
        )
    }
}
