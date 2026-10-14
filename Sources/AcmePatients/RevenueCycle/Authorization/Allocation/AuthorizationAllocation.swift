import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization allocation is in its life cycle.
    enum AuthorizationAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One authorization allocation, with what the planners need to act on it.
    final class AuthorizationAllocation {
        var code: String
        var name: String
        var revision: Int
        var updatedAt: Int
        var notes: String
        var status: AuthorizationAllocationStatus

        init(code: String, name: String, revision: Int, updatedAt: Int, notes: String, status: AuthorizationAllocationStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.updatedAt = updatedAt
            self.notes = notes
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

        func canMoveTo(_ next: AuthorizationAllocationStatus) -> Bool {
            switch status {
            case .draft:
                return next == AuthorizationAllocationStatus.active || next == AuthorizationAllocationStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: AuthorizationAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((Double(updatedAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationAllocation {
            return AuthorizationAllocation(
                code: code,
                name: name,
                revision: revision,
                updatedAt: updatedAt,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a authorization allocation in status draft.
    static func newAuthorizationAllocation(_ code: String, name: String) -> AuthorizationAllocation {
        return AuthorizationAllocation(
            code: code,
            name: name,
            revision: 0,
            updatedAt: 0,
            notes: "",
            status: AuthorizationAllocationStatus.draft
        )
    }
}
