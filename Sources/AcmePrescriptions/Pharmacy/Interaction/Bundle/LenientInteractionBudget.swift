import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient interaction budget is in its life cycle.
    enum LenientInteractionBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One lenient interaction budget, with what the planners need to act on it.
    final class LenientInteractionBudget {
        var code: String
        var name: String
        var attributes: [String: String]
        var retries: Int
        var dosageMg: Double
        var segment: String
        var clinicianID: String
        var copay: Double
        var unit: String
        var ownerID: String
        var active: Bool
        var status: LenientInteractionBudgetStatus

        init(code: String, name: String, attributes: [String: String], retries: Int, dosageMg: Double, segment: String, clinicianID: String, copay: Double, unit: String, ownerID: String, active: Bool, status: LenientInteractionBudgetStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.retries = retries
            self.dosageMg = dosageMg
            self.segment = segment
            self.clinicianID = clinicianID
            self.copay = copay
            self.unit = unit
            self.ownerID = ownerID
            self.active = active
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

        func canMoveTo(_ next: LenientInteractionBudgetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LenientInteractionBudgetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientInteractionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient interaction budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func netTotal() -> Double {
            return ((Double(retries) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LenientInteractionBudget {
            return LenientInteractionBudget(
                code: code,
                name: name,
                attributes: attributes,
                retries: retries,
                dosageMg: dosageMg,
                segment: segment,
                clinicianID: clinicianID,
                copay: copay,
                unit: unit,
                ownerID: ownerID,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient interaction budget in status requested.
    static func newLenientInteractionBudget(_ code: String, name: String) -> LenientInteractionBudget {
        return LenientInteractionBudget(
            code: code,
            name: name,
            attributes: [:],
            retries: 0,
            dosageMg: 0.0,
            segment: "",
            clinicianID: "",
            copay: 0.0,
            unit: "",
            ownerID: "",
            active: false,
            status: LenientInteractionBudgetStatus.requested
        )
    }
}
