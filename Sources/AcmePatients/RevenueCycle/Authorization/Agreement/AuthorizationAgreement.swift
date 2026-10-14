import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization agreement is in its life cycle.
    enum AuthorizationAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a authorization agreement and its current status.
    final class AuthorizationAgreement {
        var code: String
        var name: String
        var windowDays: Int
        var archived: Bool
        var country: String
        var pinned: Bool
        var status: AuthorizationAgreementStatus

        init(code: String, name: String, windowDays: Int, archived: Bool, country: String, pinned: Bool, status: AuthorizationAgreementStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.archived = archived
            self.country = country
            self.pinned = pinned
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

        func canMoveTo(_ next: AuthorizationAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == AuthorizationAgreementStatus.active
            case .pending:
                return next == AuthorizationAgreementStatus.suspended
            case .active:
                return next == AuthorizationAgreementStatus.suspended
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

        func moveTo(_ next: AuthorizationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> AuthorizationAgreement {
            return AuthorizationAgreement(
                code: code,
                name: name,
                windowDays: windowDays,
                archived: archived,
                country: country,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a authorization agreement in status draft.
    static func newAuthorizationAgreement(_ code: String, name: String) -> AuthorizationAgreement {
        return AuthorizationAgreement(
            code: code,
            name: name,
            windowDays: 0,
            archived: false,
            country: "",
            pinned: false,
            status: AuthorizationAgreementStatus.draft
        )
    }
}
