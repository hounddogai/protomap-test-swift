import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization segment is in its life cycle.
    enum AuthorizationSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a authorization segment and its current status.
    final class AuthorizationSegment {
        var code: String
        var name: String
        var expiresAt: Int
        var pinned: Bool
        var payer: String
        var locale: String
        var facility: String
        var status: AuthorizationSegmentStatus

        init(code: String, name: String, expiresAt: Int, pinned: Bool, payer: String, locale: String, facility: String, status: AuthorizationSegmentStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.pinned = pinned
            self.payer = payer
            self.locale = locale
            self.facility = facility
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

        func canMoveTo(_ next: AuthorizationSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == AuthorizationSegmentStatus.active || next == AuthorizationSegmentStatus.suspended
            case .pending:
                switch next {
                case .active:
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

        func moveTo(_ next: AuthorizationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("authorization segment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> AuthorizationSegment {
            return AuthorizationSegment(
                code: code,
                name: name,
                expiresAt: expiresAt,
                pinned: pinned,
                payer: payer,
                locale: locale,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a authorization segment in status draft.
    static func newAuthorizationSegment(_ code: String, name: String) -> AuthorizationSegment {
        return AuthorizationSegment(
            code: code,
            name: name,
            expiresAt: 0,
            pinned: false,
            payer: "",
            locale: "",
            facility: "",
            status: AuthorizationSegmentStatus.draft
        )
    }
}
