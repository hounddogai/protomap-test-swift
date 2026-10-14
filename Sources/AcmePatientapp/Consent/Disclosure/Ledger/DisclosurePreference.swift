import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure preference is in its life cycle.
    enum DisclosurePreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A disclosure preference as the disclosure team keeps it.
    final class DisclosurePreference {
        var code: String
        var name: String
        var procedureCode: String
        var allergy: String
        var ward: String
        var amount: Double
        var status: DisclosurePreferenceStatus

        init(code: String, name: String, procedureCode: String, allergy: String, ward: String, amount: Double, status: DisclosurePreferenceStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.allergy = allergy
            self.ward = ward
            self.amount = amount
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

        func canMoveTo(_ next: DisclosurePreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DisclosurePreferenceStatus.rejected || next == DisclosurePreferenceStatus.withdrawn
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

        func moveTo(_ next: DisclosurePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("disclosure preference") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> DisclosurePreference {
            return DisclosurePreference(
                code: code,
                name: name,
                procedureCode: procedureCode,
                allergy: allergy,
                ward: ward,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a disclosure preference in status proposed.
    static func newDisclosurePreference(_ code: String, name: String) -> DisclosurePreference {
        return DisclosurePreference(
            code: code,
            name: name,
            procedureCode: "",
            allergy: "",
            ward: "",
            amount: 0.0,
            status: DisclosurePreferenceStatus.proposed
        )
    }
}
