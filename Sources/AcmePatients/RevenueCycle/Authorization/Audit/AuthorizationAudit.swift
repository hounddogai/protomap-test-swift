import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization audit is in its life cycle.
    enum AuthorizationAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A authorization audit as the authorization team keeps it.
    final class AuthorizationAudit {
        var code: String
        var label: String
        var sequence: Int
        var tags: [String]
        var minimum: Double
        var status: AuthorizationAuditStatus

        init(code: String, label: String, sequence: Int, tags: [String], minimum: Double, status: AuthorizationAuditStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.tags = tags
            self.minimum = minimum
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

        func canMoveTo(_ next: AuthorizationAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == AuthorizationAuditStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AuthorizationAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((minimum + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationAudit {
            return AuthorizationAudit(
                code: code,
                label: label,
                sequence: sequence,
                tags: tags,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization audit in status created.
    static func newAuthorizationAudit(_ code: String, label: String) -> AuthorizationAudit {
        return AuthorizationAudit(
            code: code,
            label: label,
            sequence: 0,
            tags: [],
            minimum: 0.0,
            status: AuthorizationAuditStatus.created
        )
    }
}
