import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness reservation is in its life cycle.
    enum WitnessReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A witness reservation. Its code is unique within a tenant.
    final class WitnessReservation {
        var code: String
        var label: String
        var notes: String
        var ceiling: Double
        var discount: Double
        var priority: Int
        var ownerID: String
        var copay: Double
        var ratio: Double
        var status: WitnessReservationStatus

        init(code: String, label: String, notes: String, ceiling: Double, discount: Double, priority: Int, ownerID: String, copay: Double, ratio: Double, status: WitnessReservationStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.ceiling = ceiling
            self.discount = discount
            self.priority = priority
            self.ownerID = ownerID
            self.copay = copay
            self.ratio = ratio
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

        func canMoveTo(_ next: WitnessReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == WitnessReservationStatus.suspended || next == WitnessReservationStatus.closed
            case .pending:
                return next == WitnessReservationStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WitnessReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netExposure() -> Double {
            return (ratio * copay * 100).rounded() / 100
        }

        func copyValue() -> WitnessReservation {
            return WitnessReservation(
                code: code,
                label: label,
                notes: notes,
                ceiling: ceiling,
                discount: discount,
                priority: priority,
                ownerID: ownerID,
                copay: copay,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a witness reservation in status draft.
    static func newWitnessReservation(_ code: String, label: String) -> WitnessReservation {
        return WitnessReservation(
            code: code,
            label: label,
            notes: "",
            ceiling: 0.0,
            discount: 0.0,
            priority: 0,
            ownerID: "",
            copay: 0.0,
            ratio: 0.0,
            status: WitnessReservationStatus.draft
        )
    }
}
