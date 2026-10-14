import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility policy is in its life cycle.
    enum EligibilityPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One eligibility policy, with what the planners need to act on it.
    final class EligibilityPolicy {
        var code: String
        var name: String
        var attributes: [String: String]
        var expiresAt: Int
        var threshold: Double
        var ownerID: String
        var updatedAt: Int
        var status: EligibilityPolicyStatus

        init(code: String, name: String, attributes: [String: String], expiresAt: Int, threshold: Double, ownerID: String, updatedAt: Int, status: EligibilityPolicyStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.threshold = threshold
            self.ownerID = ownerID
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: EligibilityPolicyStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: EligibilityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
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

        func effectiveTotal() -> Double {
            return (Double(updatedAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> EligibilityPolicy {
            return EligibilityPolicy(
                code: code,
                name: name,
                attributes: attributes,
                expiresAt: expiresAt,
                threshold: threshold,
                ownerID: ownerID,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility policy in status draft.
    static func newEligibilityPolicy(_ code: String, name: String) -> EligibilityPolicy {
        return EligibilityPolicy(
            code: code,
            name: name,
            attributes: [:],
            expiresAt: 0,
            threshold: 0.0,
            ownerID: "",
            updatedAt: 0,
            status: EligibilityPolicyStatus.draft
        )
    }
}
