import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization request is in its life cycle.
    enum AuthorizationRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A authorization request. Its code is unique within a tenant.
    final class AuthorizationRequest {
        var code: String
        var label: String
        var visitMinutes: Int
        var margin: Double
        var weight: Double
        var status: AuthorizationRequestStatus

        init(code: String, label: String, visitMinutes: Int, margin: Double, weight: Double, status: AuthorizationRequestStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.margin = margin
            self.weight = weight
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

        func canMoveTo(_ next: AuthorizationRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AuthorizationRequestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return (margin * weight * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationRequest {
            return AuthorizationRequest(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                margin: margin,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization request in status created.
    static func newAuthorizationRequest(_ code: String, label: String) -> AuthorizationRequest {
        return AuthorizationRequest(
            code: code,
            label: label,
            visitMinutes: 0,
            margin: 0.0,
            weight: 0.0,
            status: AuthorizationRequestStatus.created
        )
    }
}
