import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped shift exception is in its life cycle.
    enum CappedShiftExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped shift exception as the shift team keeps it.
    final class CappedShiftException {
        var code: String
        var name: String
        var label: String
        var clinicianID: String
        var notes: String
        var attempts: Int
        var timezone: String
        var status: CappedShiftExceptionStatus

        init(code: String, name: String, label: String, clinicianID: String, notes: String, attempts: Int, timezone: String, status: CappedShiftExceptionStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.clinicianID = clinicianID
            self.notes = notes
            self.attempts = attempts
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedShiftExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedShiftExceptionStatus.approved || next == CappedShiftExceptionStatus.withdrawn
            case .approved:
                return next == CappedShiftExceptionStatus.withdrawn
            case .rejected:
                return next == CappedShiftExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedShiftExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped shift exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> CappedShiftException {
            return CappedShiftException(
                code: code,
                name: name,
                label: label,
                clinicianID: clinicianID,
                notes: notes,
                attempts: attempts,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped shift exception in status proposed.
    static func newCappedShiftException(_ code: String, name: String) -> CappedShiftException {
        return CappedShiftException(
            code: code,
            name: name,
            label: "",
            clinicianID: "",
            notes: "",
            attempts: 0,
            timezone: "",
            status: CappedShiftExceptionStatus.proposed
        )
    }
}
