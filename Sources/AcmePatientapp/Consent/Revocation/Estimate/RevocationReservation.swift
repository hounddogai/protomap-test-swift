import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation reservation is in its life cycle.
    enum RevocationReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A revocation reservation as the revocation team keeps it.
    final class RevocationReservation {
        var code: String
        var label: String
        var allergy: String
        var endsAt: Int
        var diagnosisCode: String
        var batchSize: Int
        var patientRef: String
        var status: RevocationReservationStatus

        init(code: String, label: String, allergy: String, endsAt: Int, diagnosisCode: String, batchSize: Int, patientRef: String, status: RevocationReservationStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.endsAt = endsAt
            self.diagnosisCode = diagnosisCode
            self.batchSize = batchSize
            self.patientRef = patientRef
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

        func canMoveTo(_ next: RevocationReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == RevocationReservationStatus.validated || next == RevocationReservationStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RevocationReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("revocation reservation") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(batchSize) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationReservation {
            return RevocationReservation(
                code: code,
                label: label,
                allergy: allergy,
                endsAt: endsAt,
                diagnosisCode: diagnosisCode,
                batchSize: batchSize,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation reservation in status created.
    static func newRevocationReservation(_ code: String, label: String) -> RevocationReservation {
        return RevocationReservation(
            code: code,
            label: label,
            allergy: "",
            endsAt: 0,
            diagnosisCode: "",
            batchSize: 0,
            patientRef: "",
            status: RevocationReservationStatus.created
        )
    }
}
