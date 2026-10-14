import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift reservation is in its life cycle.
    enum ShiftReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A shift reservation as the shift team keeps it.
    final class ShiftReservation {
        var code: String
        var label: String
        var diagnosisCode: String
        var durationMinutes: Int
        var description: String
        var copay: Double
        var attributes: [String: String]
        var capacity: Int
        var patientRef: String
        var approved: Bool
        var status: ShiftReservationStatus

        init(code: String, label: String, diagnosisCode: String, durationMinutes: Int, description: String, copay: Double, attributes: [String: String], capacity: Int, patientRef: String, approved: Bool, status: ShiftReservationStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.durationMinutes = durationMinutes
            self.description = description
            self.copay = copay
            self.attributes = attributes
            self.capacity = capacity
            self.patientRef = patientRef
            self.approved = approved
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

        func canMoveTo(_ next: ShiftReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ShiftReservationStatus.approved || next == ShiftReservationStatus.rejected
            case .approved:
                return next == ShiftReservationStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return ((copay + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftReservation {
            return ShiftReservation(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                durationMinutes: durationMinutes,
                description: description,
                copay: copay,
                attributes: attributes,
                capacity: capacity,
                patientRef: patientRef,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a shift reservation in status proposed.
    static func newShiftReservation(_ code: String, label: String) -> ShiftReservation {
        return ShiftReservation(
            code: code,
            label: label,
            diagnosisCode: "",
            durationMinutes: 0,
            description: "",
            copay: 0.0,
            attributes: [:],
            capacity: 0,
            patientRef: "",
            approved: false,
            status: ShiftReservationStatus.proposed
        )
    }
}
