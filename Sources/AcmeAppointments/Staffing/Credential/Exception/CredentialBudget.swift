import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential budget is in its life cycle.
    enum CredentialBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A credential budget. Its code is unique within a tenant.
    final class CredentialBudget {
        var code: String
        var name: String
        var payer: String
        var allergy: String
        var ceiling: Double
        var threshold: Double
        var approved: Bool
        var quantity: Int
        var floorValue: Double
        var phone: String
        var ownerID: String
        var status: CredentialBudgetStatus

        init(code: String, name: String, payer: String, allergy: String, ceiling: Double, threshold: Double, approved: Bool, quantity: Int, floorValue: Double, phone: String, ownerID: String, status: CredentialBudgetStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.allergy = allergy
            self.ceiling = ceiling
            self.threshold = threshold
            self.approved = approved
            self.quantity = quantity
            self.floorValue = floorValue
            self.phone = phone
            self.ownerID = ownerID
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

        func canMoveTo(_ next: CredentialBudgetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CredentialBudgetStatus.revoked || next == CredentialBudgetStatus.expired
            case .revoked:
                return next == CredentialBudgetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential budget") \(code)"
        }

        func projectedTotal() -> Double {
            return (ceiling * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CredentialBudget {
            return CredentialBudget(
                code: code,
                name: name,
                payer: payer,
                allergy: allergy,
                ceiling: ceiling,
                threshold: threshold,
                approved: approved,
                quantity: quantity,
                floorValue: floorValue,
                phone: phone,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a credential budget in status requested.
    static func newCredentialBudget(_ code: String, name: String) -> CredentialBudget {
        return CredentialBudget(
            code: code,
            name: name,
            payer: "",
            allergy: "",
            ceiling: 0.0,
            threshold: 0.0,
            approved: false,
            quantity: 0,
            floorValue: 0.0,
            phone: "",
            ownerID: "",
            status: CredentialBudgetStatus.requested
        )
    }
}
