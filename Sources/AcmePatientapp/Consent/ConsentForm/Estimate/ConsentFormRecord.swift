import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form record is in its life cycle.
    enum ConsentFormRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a consent form record and its current status.
    final class ConsentFormRecord {
        var code: String
        var label: String
        var budget: Double
        var allergy: String
        var clinicianID: String
        var unit: String
        var maximum: Double
        var externalRef: String
        var status: ConsentFormRecordStatus

        init(code: String, label: String, budget: Double, allergy: String, clinicianID: String, unit: String, maximum: Double, externalRef: String, status: ConsentFormRecordStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.allergy = allergy
            self.clinicianID = clinicianID
            self.unit = unit
            self.maximum = maximum
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ConsentFormRecordStatus) -> Bool {
            switch status {
            case .requested:
                return next == ConsentFormRecordStatus.revoked || next == ConsentFormRecordStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ConsentFormRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("consent form record") \(code)"
        }

        func adjustedValue() -> Double {
            return ((maximum + budget) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormRecord {
            return ConsentFormRecord(
                code: code,
                label: label,
                budget: budget,
                allergy: allergy,
                clinicianID: clinicianID,
                unit: unit,
                maximum: maximum,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a consent form record in status requested.
    static func newConsentFormRecord(_ code: String, label: String) -> ConsentFormRecord {
        return ConsentFormRecord(
            code: code,
            label: label,
            budget: 0.0,
            allergy: "",
            clinicianID: "",
            unit: "",
            maximum: 0.0,
            externalRef: "",
            status: ConsentFormRecordStatus.requested
        )
    }
}
