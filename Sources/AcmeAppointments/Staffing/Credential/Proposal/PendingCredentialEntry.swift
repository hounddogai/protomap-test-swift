import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending credential entry is in its life cycle.
    enum PendingCredentialEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a pending credential entry and its current status.
    final class PendingCredentialEntry {
        var code: String
        var label: String
        var durationMinutes: Int
        var facility: String
        var phone: String
        var clinicianID: String
        var dosageMg: Double
        var currency: String
        var category: String
        var status: PendingCredentialEntryStatus

        init(code: String, label: String, durationMinutes: Int, facility: String, phone: String, clinicianID: String, dosageMg: Double, currency: String, category: String, status: PendingCredentialEntryStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.phone = phone
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.currency = currency
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingCredentialEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PendingCredentialEntryStatus.published || next == PendingCredentialEntryStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingCredentialEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending credential entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> PendingCredentialEntry {
            return PendingCredentialEntry(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                facility: facility,
                phone: phone,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                currency: currency,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending credential entry in status created.
    static func newPendingCredentialEntry(_ code: String, label: String) -> PendingCredentialEntry {
        return PendingCredentialEntry(
            code: code,
            label: label,
            durationMinutes: 0,
            facility: "",
            phone: "",
            clinicianID: "",
            dosageMg: 0.0,
            currency: "",
            category: "",
            status: PendingCredentialEntryStatus.created
        )
    }
}
