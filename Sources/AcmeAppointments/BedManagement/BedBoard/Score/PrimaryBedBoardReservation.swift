import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary bed board reservation is in its life cycle.
    enum PrimaryBedBoardReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary bed board reservation as the bed board team keeps it.
    final class PrimaryBedBoardReservation {
        var code: String
        var name: String
        var specialty: String
        var currency: String
        var attempts: Int
        var weight: Double
        var batchSize: Int
        var contactEmail: String
        var status: PrimaryBedBoardReservationStatus

        init(code: String, name: String, specialty: String, currency: String, attempts: Int, weight: Double, batchSize: Int, contactEmail: String, status: PrimaryBedBoardReservationStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.currency = currency
            self.attempts = attempts
            self.weight = weight
            self.batchSize = batchSize
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: PrimaryBedBoardReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryBedBoardReservationStatus.validated
            case .validated:
                return next == PrimaryBedBoardReservationStatus.published || next == PrimaryBedBoardReservationStatus.retired
            case .published:
                return next == PrimaryBedBoardReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryBedBoardReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary bed board reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return ((Double(attempts) + weight) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryBedBoardReservation {
            return PrimaryBedBoardReservation(
                code: code,
                name: name,
                specialty: specialty,
                currency: currency,
                attempts: attempts,
                weight: weight,
                batchSize: batchSize,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary bed board reservation in status created.
    static func newPrimaryBedBoardReservation(_ code: String, name: String) -> PrimaryBedBoardReservation {
        return PrimaryBedBoardReservation(
            code: code,
            name: name,
            specialty: "",
            currency: "",
            attempts: 0,
            weight: 0.0,
            batchSize: 0,
            contactEmail: "",
            status: PrimaryBedBoardReservationStatus.created
        )
    }
}
