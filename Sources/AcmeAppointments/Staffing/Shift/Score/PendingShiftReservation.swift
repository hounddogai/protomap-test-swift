import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending shift reservation is in its life cycle.
    enum PendingShiftReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending shift reservation. Its code is unique within a tenant.
    final class PendingShiftReservation {
        var code: String
        var label: String
        var visible: Bool
        var notes: String
        var contactEmail: String
        var score: Double
        var status: PendingShiftReservationStatus

        init(code: String, label: String, visible: Bool, notes: String, contactEmail: String, score: Double, status: PendingShiftReservationStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.notes = notes
            self.contactEmail = contactEmail
            self.score = score
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

        func canMoveTo(_ next: PendingShiftReservationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PendingShiftReservationStatus.active
            case .active:
                return next == PendingShiftReservationStatus.suspended
            case .suspended:
                return next == PendingShiftReservationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingShiftReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending shift reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PendingShiftReservation {
            return PendingShiftReservation(
                code: code,
                label: label,
                visible: visible,
                notes: notes,
                contactEmail: contactEmail,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending shift reservation in status draft.
    static func newPendingShiftReservation(_ code: String, label: String) -> PendingShiftReservation {
        return PendingShiftReservation(
            code: code,
            label: label,
            visible: false,
            notes: "",
            contactEmail: "",
            score: 0.0,
            status: PendingShiftReservationStatus.draft
        )
    }
}
