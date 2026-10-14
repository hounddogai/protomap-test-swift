import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen reservation is in its life cycle.
    enum SpecimenReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A specimen reservation. Its code is unique within a tenant.
    final class SpecimenReservation {
        var code: String
        var title: String
        var diagnosisCode: String
        var currency: String
        var startsAt: Int
        var name: String
        var threshold: Double
        var capacity: Int
        var phone: String
        var status: SpecimenReservationStatus

        init(code: String, title: String, diagnosisCode: String, currency: String, startsAt: Int, name: String, threshold: Double, capacity: Int, phone: String, status: SpecimenReservationStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.currency = currency
            self.startsAt = startsAt
            self.name = name
            self.threshold = threshold
            self.capacity = capacity
            self.phone = phone
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

        func canMoveTo(_ next: SpecimenReservationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SpecimenReservationStatus.retired
            case .published:
                return next == SpecimenReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return ((Double(capacity) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenReservation {
            return SpecimenReservation(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                currency: currency,
                startsAt: startsAt,
                name: name,
                threshold: threshold,
                capacity: capacity,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a specimen reservation in status created.
    static func newSpecimenReservation(_ code: String, title: String) -> SpecimenReservation {
        return SpecimenReservation(
            code: code,
            title: title,
            diagnosisCode: "",
            currency: "",
            startsAt: 0,
            name: "",
            threshold: 0.0,
            capacity: 0,
            phone: "",
            status: SpecimenReservationStatus.created
        )
    }
}
