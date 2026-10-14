import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary consent form entry is in its life cycle.
    enum PrimaryConsentFormEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary consent form entry, with what the planners need to act on it.
    final class PrimaryConsentFormEntry {
        var code: String
        var name: String
        var bed: String
        var label: String
        var contactEmail: String
        var maximum: Double
        var discount: Double
        var limit: Int
        var visible: Bool
        var allergy: String
        var status: PrimaryConsentFormEntryStatus

        init(code: String, name: String, bed: String, label: String, contactEmail: String, maximum: Double, discount: Double, limit: Int, visible: Bool, allergy: String, status: PrimaryConsentFormEntryStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.label = label
            self.contactEmail = contactEmail
            self.maximum = maximum
            self.discount = discount
            self.limit = limit
            self.visible = visible
            self.allergy = allergy
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

        func canMoveTo(_ next: PrimaryConsentFormEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryConsentFormEntryStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryConsentFormEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary consent form entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return (maximum * discount * 100).rounded() / 100
        }

        func copyValue() -> PrimaryConsentFormEntry {
            return PrimaryConsentFormEntry(
                code: code,
                name: name,
                bed: bed,
                label: label,
                contactEmail: contactEmail,
                maximum: maximum,
                discount: discount,
                limit: limit,
                visible: visible,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary consent form entry in status requested.
    static func newPrimaryConsentFormEntry(_ code: String, name: String) -> PrimaryConsentFormEntry {
        return PrimaryConsentFormEntry(
            code: code,
            name: name,
            bed: "",
            label: "",
            contactEmail: "",
            maximum: 0.0,
            discount: 0.0,
            limit: 0,
            visible: false,
            allergy: "",
            status: PrimaryConsentFormEntryStatus.requested
        )
    }
}
