import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense reservation is in its life cycle.
    enum DispenseReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A dispense reservation as the dispense team keeps it.
    final class DispenseReservation {
        var code: String
        var label: String
        var patientRef: String
        var quantity: Int
        var unit: String
        var ward: String
        var priority: Int
        var discount: Double
        var channel: String
        var status: DispenseReservationStatus

        init(code: String, label: String, patientRef: String, quantity: Int, unit: String, ward: String, priority: Int, discount: Double, channel: String, status: DispenseReservationStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.quantity = quantity
            self.unit = unit
            self.ward = ward
            self.priority = priority
            self.discount = discount
            self.channel = channel
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

        func canMoveTo(_ next: DispenseReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == DispenseReservationStatus.active || next == DispenseReservationStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DispenseReservationStatus.suspended
            case .suspended:
                return next == DispenseReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((Double(priority) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseReservation {
            return DispenseReservation(
                code: code,
                label: label,
                patientRef: patientRef,
                quantity: quantity,
                unit: unit,
                ward: ward,
                priority: priority,
                discount: discount,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a dispense reservation in status draft.
    static func newDispenseReservation(_ code: String, label: String) -> DispenseReservation {
        return DispenseReservation(
            code: code,
            label: label,
            patientRef: "",
            quantity: 0,
            unit: "",
            ward: "",
            priority: 0,
            discount: 0.0,
            channel: "",
            status: DispenseReservationStatus.draft
        )
    }
}
