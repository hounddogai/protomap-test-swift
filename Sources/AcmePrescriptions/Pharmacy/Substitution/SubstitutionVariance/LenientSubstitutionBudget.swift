import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient substitution budget is in its life cycle.
    enum LenientSubstitutionBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient substitution budget as the substitution team keeps it.
    final class LenientSubstitutionBudget {
        var code: String
        var name: String
        var currency: String
        var attempts: Int
        var category: String
        var facility: String
        var payer: String
        var specialty: String
        var status: LenientSubstitutionBudgetStatus

        init(code: String, name: String, currency: String, attempts: Int, category: String, facility: String, payer: String, specialty: String, status: LenientSubstitutionBudgetStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.attempts = attempts
            self.category = category
            self.facility = facility
            self.payer = payer
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

        func canMoveTo(_ next: LenientSubstitutionBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientSubstitutionBudgetStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientSubstitutionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient substitution budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient substitution budget") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> LenientSubstitutionBudget {
            return LenientSubstitutionBudget(
                code: code,
                name: name,
                currency: currency,
                attempts: attempts,
                category: category,
                facility: facility,
                payer: payer,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a lenient substitution budget in status proposed.
    static func newLenientSubstitutionBudget(_ code: String, name: String) -> LenientSubstitutionBudget {
        return LenientSubstitutionBudget(
            code: code,
            name: name,
            currency: "",
            attempts: 0,
            category: "",
            facility: "",
            payer: "",
            specialty: "",
            status: LenientSubstitutionBudgetStatus.proposed
        )
    }
}
