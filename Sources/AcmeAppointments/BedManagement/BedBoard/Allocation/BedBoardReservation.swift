import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board reservation is in its life cycle.
    enum BedBoardReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a bed board reservation and its current status.
    final class BedBoardReservation {
        var code: String
        var label: String
        var amount: Double
        var description: String
        var externalRef: String
        var bed: String
        var status: BedBoardReservationStatus

        init(code: String, label: String, amount: Double, description: String, externalRef: String, bed: String, status: BedBoardReservationStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.description = description
            self.externalRef = externalRef
            self.bed = bed
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

        func canMoveTo(_ next: BedBoardReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == BedBoardReservationStatus.published || next == BedBoardReservationStatus.retired
            case .validated:
                return next == BedBoardReservationStatus.retired
            case .published:
                return next == BedBoardReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> BedBoardReservation {
            return BedBoardReservation(
                code: code,
                label: label,
                amount: amount,
                description: description,
                externalRef: externalRef,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a bed board reservation in status created.
    static func newBedBoardReservation(_ code: String, label: String) -> BedBoardReservation {
        return BedBoardReservation(
            code: code,
            label: label,
            amount: 0.0,
            description: "",
            externalRef: "",
            bed: "",
            status: BedBoardReservationStatus.created
        )
    }
}
