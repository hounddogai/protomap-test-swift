import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered substitution window is in its life cycle.
    enum TieredSubstitutionWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered substitution window. Its code is unique within a tenant.
    final class TieredSubstitutionWindow {
        var code: String
        var name: String
        var attributes: [String: String]
        var label: String
        var procedureCode: String
        var clinicianID: String
        var amount: Double
        var segment: String
        var status: TieredSubstitutionWindowStatus

        init(code: String, name: String, attributes: [String: String], label: String, procedureCode: String, clinicianID: String, amount: Double, segment: String, status: TieredSubstitutionWindowStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.label = label
            self.procedureCode = procedureCode
            self.clinicianID = clinicianID
            self.amount = amount
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredSubstitutionWindowStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredSubstitutionWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredSubstitutionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered substitution window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
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

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> TieredSubstitutionWindow {
            return TieredSubstitutionWindow(
                code: code,
                name: name,
                attributes: attributes,
                label: label,
                procedureCode: procedureCode,
                clinicianID: clinicianID,
                amount: amount,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a tiered substitution window in status draft.
    static func newTieredSubstitutionWindow(_ code: String, name: String) -> TieredSubstitutionWindow {
        return TieredSubstitutionWindow(
            code: code,
            name: name,
            attributes: [:],
            label: "",
            procedureCode: "",
            clinicianID: "",
            amount: 0.0,
            segment: "",
            status: TieredSubstitutionWindowStatus.draft
        )
    }
}
