import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient specimen reservation is in its life cycle.
    enum LenientSpecimenReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient specimen reservation, with what the planners need to act on it.
    final class LenientSpecimenReservation {
        var code: String
        var label: String
        var diagnosisCode: String
        var clinicianID: String
        var region: String
        var batchSize: Int
        var sequence: Int
        var amount: Double
        var status: LenientSpecimenReservationStatus

        init(code: String, label: String, diagnosisCode: String, clinicianID: String, region: String, batchSize: Int, sequence: Int, amount: Double, status: LenientSpecimenReservationStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.clinicianID = clinicianID
            self.region = region
            self.batchSize = batchSize
            self.sequence = sequence
            self.amount = amount
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

        func canMoveTo(_ next: LenientSpecimenReservationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == LenientSpecimenReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientSpecimenReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient specimen reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient specimen reservation") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(batchSize) + amount) * 100).rounded() / 100
        }

        func copyValue() -> LenientSpecimenReservation {
            return LenientSpecimenReservation(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                clinicianID: clinicianID,
                region: region,
                batchSize: batchSize,
                sequence: sequence,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient specimen reservation in status draft.
    static func newLenientSpecimenReservation(_ code: String, label: String) -> LenientSpecimenReservation {
        return LenientSpecimenReservation(
            code: code,
            label: label,
            diagnosisCode: "",
            clinicianID: "",
            region: "",
            batchSize: 0,
            sequence: 0,
            amount: 0.0,
            status: LenientSpecimenReservationStatus.draft
        )
    }
}
