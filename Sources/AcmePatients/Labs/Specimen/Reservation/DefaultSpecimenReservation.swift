import AcmePlatform
import Foundation

extension Labs {
    /// Where a default specimen reservation is in its life cycle.
    enum DefaultSpecimenReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default specimen reservation as the specimen team keeps it.
    final class DefaultSpecimenReservation {
        var code: String
        var label: String
        var locale: String
        var clinicianID: String
        var ratio: Double
        var ward: String
        var durationMinutes: Int
        var status: DefaultSpecimenReservationStatus

        init(code: String, label: String, locale: String, clinicianID: String, ratio: Double, ward: String, durationMinutes: Int, status: DefaultSpecimenReservationStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.ward = ward
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: DefaultSpecimenReservationStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultSpecimenReservationStatus.stopped
            case .warming:
                return next == DefaultSpecimenReservationStatus.ready || next == DefaultSpecimenReservationStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultSpecimenReservationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSpecimenReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default specimen reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default specimen reservation") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(durationMinutes) * ratio * 100).rounded() / 100
        }

        func copyValue() -> DefaultSpecimenReservation {
            return DefaultSpecimenReservation(
                code: code,
                label: label,
                locale: locale,
                clinicianID: clinicianID,
                ratio: ratio,
                ward: ward,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default specimen reservation in status idle.
    static func newDefaultSpecimenReservation(_ code: String, label: String) -> DefaultSpecimenReservation {
        return DefaultSpecimenReservation(
            code: code,
            label: label,
            locale: "",
            clinicianID: "",
            ratio: 0.0,
            ward: "",
            durationMinutes: 0,
            status: DefaultSpecimenReservationStatus.idle
        )
    }
}
