import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness quota is in its life cycle.
    enum WitnessQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A witness quota. Its code is unique within a tenant.
    final class WitnessQuota {
        var code: String
        var name: String
        var description: String
        var amount: Double
        var category: String
        var payer: String
        var source: String
        var status: WitnessQuotaStatus

        init(code: String, name: String, description: String, amount: Double, category: String, payer: String, source: String, status: WitnessQuotaStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.amount = amount
            self.category = category
            self.payer = payer
            self.source = source
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

        func canMoveTo(_ next: WitnessQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WitnessQuotaStatus.approved || next == WitnessQuotaStatus.rejected
            case .approved:
                return next == WitnessQuotaStatus.rejected
            case .rejected:
                return next == WitnessQuotaStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> WitnessQuota {
            return WitnessQuota(
                code: code,
                name: name,
                description: description,
                amount: amount,
                category: category,
                payer: payer,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a witness quota in status proposed.
    static func newWitnessQuota(_ code: String, name: String) -> WitnessQuota {
        return WitnessQuota(
            code: code,
            name: name,
            description: "",
            amount: 0.0,
            category: "",
            payer: "",
            source: "",
            status: WitnessQuotaStatus.proposed
        )
    }
}
