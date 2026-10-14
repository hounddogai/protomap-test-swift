import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential policy is in its life cycle.
    enum CredentialPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A credential policy as the credential team keeps it.
    final class CredentialPolicy {
        var code: String
        var title: String
        var limit: Int
        var minimum: Double
        var unit: String
        var status: CredentialPolicyStatus

        init(code: String, title: String, limit: Int, minimum: Double, unit: String, status: CredentialPolicyStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.minimum = minimum
            self.unit = unit
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

        func canMoveTo(_ next: CredentialPolicyStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CredentialPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential policy") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(limit) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> CredentialPolicy {
            return CredentialPolicy(
                code: code,
                title: title,
                limit: limit,
                minimum: minimum,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a credential policy in status created.
    static func newCredentialPolicy(_ code: String, title: String) -> CredentialPolicy {
        return CredentialPolicy(
            code: code,
            title: title,
            limit: 0,
            minimum: 0.0,
            unit: "",
            status: CredentialPolicyStatus.created
        )
    }
}
