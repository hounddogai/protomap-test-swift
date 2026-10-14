import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift window is in its life cycle.
    enum ShiftWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A shift window as the shift team keeps it.
    final class ShiftWindow {
        var code: String
        var name: String
        var contactEmail: String
        var diagnosisCode: String
        var clinicianID: String
        var version: Int
        var amount: Double
        var archived: Bool
        var unit: String
        var windowDays: Int
        var status: ShiftWindowStatus

        init(code: String, name: String, contactEmail: String, diagnosisCode: String, clinicianID: String, version: Int, amount: Double, archived: Bool, unit: String, windowDays: Int, status: ShiftWindowStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.clinicianID = clinicianID
            self.version = version
            self.amount = amount
            self.archived = archived
            self.unit = unit
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ShiftWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ShiftWindowStatus.rejected || next == ShiftWindowStatus.withdrawn
            case .rejected:
                return next == ShiftWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("shift window") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(windowDays) + amount) * 100).rounded() / 100
        }

        func copyValue() -> ShiftWindow {
            return ShiftWindow(
                code: code,
                name: name,
                contactEmail: contactEmail,
                diagnosisCode: diagnosisCode,
                clinicianID: clinicianID,
                version: version,
                amount: amount,
                archived: archived,
                unit: unit,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a shift window in status proposed.
    static func newShiftWindow(_ code: String, name: String) -> ShiftWindow {
        return ShiftWindow(
            code: code,
            name: name,
            contactEmail: "",
            diagnosisCode: "",
            clinicianID: "",
            version: 0,
            amount: 0.0,
            archived: false,
            unit: "",
            windowDays: 0,
            status: ShiftWindowStatus.proposed
        )
    }
}
