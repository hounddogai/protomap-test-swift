import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization mapping is in its life cycle.
    enum AuthorizationMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One authorization mapping, with what the planners need to act on it.
    final class AuthorizationMapping {
        var code: String
        var label: String
        var region: String
        var startsAt: Int
        var expiresAt: Int
        var status: AuthorizationMappingStatus

        init(code: String, label: String, region: String, startsAt: Int, expiresAt: Int, status: AuthorizationMappingStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.startsAt = startsAt
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: AuthorizationMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == AuthorizationMappingStatus.pending || next == AuthorizationMappingStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AuthorizationMappingStatus.suspended || next == AuthorizationMappingStatus.closed
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

        func moveTo(_ next: AuthorizationMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("authorization mapping") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(expiresAt) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationMapping {
            return AuthorizationMapping(
                code: code,
                label: label,
                region: region,
                startsAt: startsAt,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a authorization mapping in status draft.
    static func newAuthorizationMapping(_ code: String, label: String) -> AuthorizationMapping {
        return AuthorizationMapping(
            code: code,
            label: label,
            region: "",
            startsAt: 0,
            expiresAt: 0,
            status: AuthorizationMappingStatus.draft
        )
    }
}
