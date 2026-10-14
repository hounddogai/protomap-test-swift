import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary budget is in its life cycle.
    enum FormularyBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A formulary budget. Its code is unique within a tenant.
    final class FormularyBudget {
        var code: String
        var name: String
        var title: String
        var amount: Double
        var encounterID: String
        var reviewer: String
        var maximum: Double
        var clinicianID: String
        var limit: Int
        var status: FormularyBudgetStatus

        init(code: String, name: String, title: String, amount: Double, encounterID: String, reviewer: String, maximum: Double, clinicianID: String, limit: Int, status: FormularyBudgetStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.amount = amount
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.maximum = maximum
            self.clinicianID = clinicianID
            self.limit = limit
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

        func canMoveTo(_ next: FormularyBudgetStatus) -> Bool {
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
                case .revoked:
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

        func moveTo(_ next: FormularyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("formulary budget") \(code)"
        }

        func projectedExposure() -> Double {
            return (amount * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> FormularyBudget {
            return FormularyBudget(
                code: code,
                name: name,
                title: title,
                amount: amount,
                encounterID: encounterID,
                reviewer: reviewer,
                maximum: maximum,
                clinicianID: clinicianID,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a formulary budget in status requested.
    static func newFormularyBudget(_ code: String, name: String) -> FormularyBudget {
        return FormularyBudget(
            code: code,
            name: name,
            title: "",
            amount: 0.0,
            encounterID: "",
            reviewer: "",
            maximum: 0.0,
            clinicianID: "",
            limit: 0,
            status: FormularyBudgetStatus.requested
        )
    }
}
