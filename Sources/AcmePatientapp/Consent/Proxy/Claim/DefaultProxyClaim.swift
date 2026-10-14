import AcmePlatform
import Foundation

extension Consent {
    /// Where a default proxy claim is in its life cycle.
    enum DefaultProxyClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default proxy claim. Its code is unique within a tenant.
    final class DefaultProxyClaim {
        var code: String
        var name: String
        var title: String
        var retries: Int
        var archived: Bool
        var currency: String
        var dosageMg: Double
        var graceDays: Int
        var amount: Double
        var encounterID: String
        var status: DefaultProxyClaimStatus

        init(code: String, name: String, title: String, retries: Int, archived: Bool, currency: String, dosageMg: Double, graceDays: Int, amount: Double, encounterID: String, status: DefaultProxyClaimStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.retries = retries
            self.archived = archived
            self.currency = currency
            self.dosageMg = dosageMg
            self.graceDays = graceDays
            self.amount = amount
            self.encounterID = encounterID
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

        func canMoveTo(_ next: DefaultProxyClaimStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultProxyClaimStatus.validated || next == DefaultProxyClaimStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DefaultProxyClaimStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultProxyClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default proxy claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return (Double(retries) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> DefaultProxyClaim {
            return DefaultProxyClaim(
                code: code,
                name: name,
                title: title,
                retries: retries,
                archived: archived,
                currency: currency,
                dosageMg: dosageMg,
                graceDays: graceDays,
                amount: amount,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default proxy claim in status created.
    static func newDefaultProxyClaim(_ code: String, name: String) -> DefaultProxyClaim {
        return DefaultProxyClaim(
            code: code,
            name: name,
            title: "",
            retries: 0,
            archived: false,
            currency: "",
            dosageMg: 0.0,
            graceDays: 0,
            amount: 0.0,
            encounterID: "",
            status: DefaultProxyClaimStatus.created
        )
    }
}
