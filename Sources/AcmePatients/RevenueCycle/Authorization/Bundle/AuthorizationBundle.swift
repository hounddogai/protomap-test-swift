import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization bundle is in its life cycle.
    enum AuthorizationBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A authorization bundle. Its code is unique within a tenant.
    final class AuthorizationBundle {
        var code: String
        var title: String
        var approved: Bool
        var specialty: String
        var createdAt: Int
        var status: AuthorizationBundleStatus

        init(code: String, title: String, approved: Bool, specialty: String, createdAt: Int, status: AuthorizationBundleStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.specialty = specialty
            self.createdAt = createdAt
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

        func canMoveTo(_ next: AuthorizationBundleStatus) -> Bool {
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
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AuthorizationBundleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("authorization bundle") \(code)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> AuthorizationBundle {
            return AuthorizationBundle(
                code: code,
                title: title,
                approved: approved,
                specialty: specialty,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a authorization bundle in status draft.
    static func newAuthorizationBundle(_ code: String, title: String) -> AuthorizationBundle {
        return AuthorizationBundle(
            code: code,
            title: title,
            approved: false,
            specialty: "",
            createdAt: 0,
            status: AuthorizationBundleStatus.draft
        )
    }
}
