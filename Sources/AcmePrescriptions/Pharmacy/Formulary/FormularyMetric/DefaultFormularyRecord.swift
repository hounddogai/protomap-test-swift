import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default formulary record is in its life cycle.
    enum DefaultFormularyRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default formulary record as the formulary team keeps it.
    final class DefaultFormularyRecord {
        var code: String
        var name: String
        var ownerID: String
        var summary: String
        var patientRef: String
        var expiresAt: Int
        var label: String
        var unit: String
        var clinicianID: String
        var status: DefaultFormularyRecordStatus

        init(code: String, name: String, ownerID: String, summary: String, patientRef: String, expiresAt: Int, label: String, unit: String, clinicianID: String, status: DefaultFormularyRecordStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.summary = summary
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.label = label
            self.unit = unit
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultFormularyRecordStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DefaultFormularyRecordStatus.done || next == DefaultFormularyRecordStatus.failed
            case .done:
                return next == DefaultFormularyRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultFormularyRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default formulary record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> DefaultFormularyRecord {
            return DefaultFormularyRecord(
                code: code,
                name: name,
                ownerID: ownerID,
                summary: summary,
                patientRef: patientRef,
                expiresAt: expiresAt,
                label: label,
                unit: unit,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a default formulary record in status new.
    static func newDefaultFormularyRecord(_ code: String, name: String) -> DefaultFormularyRecord {
        return DefaultFormularyRecord(
            code: code,
            name: name,
            ownerID: "",
            summary: "",
            patientRef: "",
            expiresAt: 0,
            label: "",
            unit: "",
            clinicianID: "",
            status: DefaultFormularyRecordStatus.new
        )
    }
}
