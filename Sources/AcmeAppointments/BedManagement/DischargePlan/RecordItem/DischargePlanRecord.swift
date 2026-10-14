import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan record is in its life cycle.
    enum DischargePlanRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a discharge plan record and its current status.
    final class DischargePlanRecord {
        var code: String
        var title: String
        var timezone: String
        var priority: Int
        var minimum: Double
        var version: Int
        var copay: Double
        var diagnosisCode: String
        var clinicianID: String
        var ward: String
        var notes: String
        var status: DischargePlanRecordStatus

        init(code: String, title: String, timezone: String, priority: Int, minimum: Double, version: Int, copay: Double, diagnosisCode: String, clinicianID: String, ward: String, notes: String, status: DischargePlanRecordStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.priority = priority
            self.minimum = minimum
            self.version = version
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.clinicianID = clinicianID
            self.ward = ward
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanRecordStatus) -> Bool {
            switch status {
            case .requested:
                return next == DischargePlanRecordStatus.revoked || next == DischargePlanRecordStatus.expired
            case .granted:
                return next == DischargePlanRecordStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DischargePlanRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("discharge plan record") \(code)"
        }

        func adjustedValue() -> Double {
            return ((minimum + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanRecord {
            return DischargePlanRecord(
                code: code,
                title: title,
                timezone: timezone,
                priority: priority,
                minimum: minimum,
                version: version,
                copay: copay,
                diagnosisCode: diagnosisCode,
                clinicianID: clinicianID,
                ward: ward,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a discharge plan record in status requested.
    static func newDischargePlanRecord(_ code: String, title: String) -> DischargePlanRecord {
        return DischargePlanRecord(
            code: code,
            title: title,
            timezone: "",
            priority: 0,
            minimum: 0.0,
            version: 0,
            copay: 0.0,
            diagnosisCode: "",
            clinicianID: "",
            ward: "",
            notes: "",
            status: DischargePlanRecordStatus.requested
        )
    }
}
