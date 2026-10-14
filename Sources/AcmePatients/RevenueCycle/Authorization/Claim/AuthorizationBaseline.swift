import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization baseline is in its life cycle.
    enum AuthorizationBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A authorization baseline as the authorization team keeps it.
    final class AuthorizationBaseline {
        var code: String
        var label: String
        var updatedAt: Int
        var encounterID: String
        var visible: Bool
        var status: AuthorizationBaselineStatus

        init(code: String, label: String, updatedAt: Int, encounterID: String, visible: Bool, status: AuthorizationBaselineStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == AuthorizationBaselineStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AuthorizationBaselineStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AuthorizationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> AuthorizationBaseline {
            return AuthorizationBaseline(
                code: code,
                label: label,
                updatedAt: updatedAt,
                encounterID: encounterID,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization baseline in status planned.
    static func newAuthorizationBaseline(_ code: String, label: String) -> AuthorizationBaseline {
        return AuthorizationBaseline(
            code: code,
            label: label,
            updatedAt: 0,
            encounterID: "",
            visible: false,
            status: AuthorizationBaselineStatus.planned
        )
    }
}
