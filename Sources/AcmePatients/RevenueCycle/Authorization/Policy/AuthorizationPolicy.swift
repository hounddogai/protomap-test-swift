import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization policy is in its life cycle.
    enum AuthorizationPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One authorization policy, with what the planners need to act on it.
    final class AuthorizationPolicy {
        var code: String
        var name: String
        var unit: String
        var acuity: Int
        var clinicianID: String
        var ownerID: String
        var limit: Int
        var attributes: [String: String]
        var updatedAt: Int
        var attempts: Int
        var retries: Int
        var status: AuthorizationPolicyStatus

        init(code: String, name: String, unit: String, acuity: Int, clinicianID: String, ownerID: String, limit: Int, attributes: [String: String], updatedAt: Int, attempts: Int, retries: Int, status: AuthorizationPolicyStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.ownerID = ownerID
            self.limit = limit
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AuthorizationPolicyStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AuthorizationPolicyStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AuthorizationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func adjustedValue() -> Double {
            return ((Double(updatedAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationPolicy {
            return AuthorizationPolicy(
                code: code,
                name: name,
                unit: unit,
                acuity: acuity,
                clinicianID: clinicianID,
                ownerID: ownerID,
                limit: limit,
                attributes: attributes,
                updatedAt: updatedAt,
                attempts: attempts,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a authorization policy in status open.
    static func newAuthorizationPolicy(_ code: String, name: String) -> AuthorizationPolicy {
        return AuthorizationPolicy(
            code: code,
            name: name,
            unit: "",
            acuity: 0,
            clinicianID: "",
            ownerID: "",
            limit: 0,
            attributes: [:],
            updatedAt: 0,
            attempts: 0,
            retries: 0,
            status: AuthorizationPolicyStatus.`open`
        )
    }
}
