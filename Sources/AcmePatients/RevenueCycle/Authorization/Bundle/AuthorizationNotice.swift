import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization notice is in its life cycle.
    enum AuthorizationNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A authorization notice. Its code is unique within a tenant.
    final class AuthorizationNotice {
        var code: String
        var label: String
        var cost: Double
        var specialty: String
        var retries: Int
        var updatedAt: Int
        var status: AuthorizationNoticeStatus

        init(code: String, label: String, cost: Double, specialty: String, retries: Int, updatedAt: Int, status: AuthorizationNoticeStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.specialty = specialty
            self.retries = retries
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AuthorizationNoticeStatus.running
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AuthorizationNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("authorization notice") \(code)"
        }

        func netLoad() -> Double {
            return (Double(retries) * cost * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationNotice {
            return AuthorizationNotice(
                code: code,
                label: label,
                cost: cost,
                specialty: specialty,
                retries: retries,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization notice in status new.
    static func newAuthorizationNotice(_ code: String, label: String) -> AuthorizationNotice {
        return AuthorizationNotice(
            code: code,
            label: label,
            cost: 0.0,
            specialty: "",
            retries: 0,
            updatedAt: 0,
            status: AuthorizationNoticeStatus.new
        )
    }
}
