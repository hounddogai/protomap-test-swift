import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession reservation is in its life cycle.
    enum AccessionReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a accession reservation and its current status.
    final class AccessionReservation {
        var code: String
        var label: String
        var expiresAt: Int
        var capacity: Int
        var priority: Int
        var attempts: Int
        var pinned: Bool
        var visible: Bool
        var minimum: Double
        var quantity: Int
        var dosageMg: Double
        var status: AccessionReservationStatus

        init(code: String, label: String, expiresAt: Int, capacity: Int, priority: Int, attempts: Int, pinned: Bool, visible: Bool, minimum: Double, quantity: Int, dosageMg: Double, status: AccessionReservationStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.capacity = capacity
            self.priority = priority
            self.attempts = attempts
            self.pinned = pinned
            self.visible = visible
            self.minimum = minimum
            self.quantity = quantity
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AccessionReservationStatus.reopened
            case .resolved:
                return next == AccessionReservationStatus.reopened || next == AccessionReservationStatus.archived
            case .reopened:
                return next == AccessionReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("accession reservation") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(priority) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionReservation {
            return AccessionReservation(
                code: code,
                label: label,
                expiresAt: expiresAt,
                capacity: capacity,
                priority: priority,
                attempts: attempts,
                pinned: pinned,
                visible: visible,
                minimum: minimum,
                quantity: quantity,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a accession reservation in status open.
    static func newAccessionReservation(_ code: String, label: String) -> AccessionReservation {
        return AccessionReservation(
            code: code,
            label: label,
            expiresAt: 0,
            capacity: 0,
            priority: 0,
            attempts: 0,
            pinned: false,
            visible: false,
            minimum: 0.0,
            quantity: 0,
            dosageMg: 0.0,
            status: AccessionReservationStatus.`open`
        )
    }
}
