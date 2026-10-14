import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy order set entry is in its life cycle.
    enum LegacyOrderSetEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy order set entry. Its code is unique within a tenant.
    final class LegacyOrderSetEntry {
        var code: String
        var label: String
        var phone: String
        var ratio: Double
        var title: String
        var patientRef: String
        var description: String
        var retries: Int
        var refills: Int
        var bed: String
        var specialty: String
        var status: LegacyOrderSetEntryStatus

        init(code: String, label: String, phone: String, ratio: Double, title: String, patientRef: String, description: String, retries: Int, refills: Int, bed: String, specialty: String, status: LegacyOrderSetEntryStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.ratio = ratio
            self.title = title
            self.patientRef = patientRef
            self.description = description
            self.retries = retries
            self.refills = refills
            self.bed = bed
            self.specialty = specialty
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

        func canMoveTo(_ next: LegacyOrderSetEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyOrderSetEntryStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LegacyOrderSetEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyOrderSetEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy order set entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy order set entry") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((ratio - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyOrderSetEntry {
            return LegacyOrderSetEntry(
                code: code,
                label: label,
                phone: phone,
                ratio: ratio,
                title: title,
                patientRef: patientRef,
                description: description,
                retries: retries,
                refills: refills,
                bed: bed,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy order set entry in status proposed.
    static func newLegacyOrderSetEntry(_ code: String, label: String) -> LegacyOrderSetEntry {
        return LegacyOrderSetEntry(
            code: code,
            label: label,
            phone: "",
            ratio: 0.0,
            title: "",
            patientRef: "",
            description: "",
            retries: 0,
            refills: 0,
            bed: "",
            specialty: "",
            status: LegacyOrderSetEntryStatus.proposed
        )
    }
}
