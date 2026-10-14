import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization digest is in its life cycle.
    enum AuthorizationDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A authorization digest as the authorization team keeps it.
    final class AuthorizationDigest {
        var code: String
        var name: String
        var specialty: String
        var procedureCode: String
        var amount: Double
        var status: AuthorizationDigestStatus

        init(code: String, name: String, specialty: String, procedureCode: String, amount: Double, status: AuthorizationDigestStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AuthorizationDigestStatus.stopped
            case .ready:
                return next == AuthorizationDigestStatus.draining || next == AuthorizationDigestStatus.stopped
            case .draining:
                return next == AuthorizationDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AuthorizationDigest {
            return AuthorizationDigest(
                code: code,
                name: name,
                specialty: specialty,
                procedureCode: procedureCode,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a authorization digest in status idle.
    static func newAuthorizationDigest(_ code: String, name: String) -> AuthorizationDigest {
        return AuthorizationDigest(
            code: code,
            name: name,
            specialty: "",
            procedureCode: "",
            amount: 0.0,
            status: AuthorizationDigestStatus.idle
        )
    }
}
