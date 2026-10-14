import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization entry is in its life cycle.
    enum AuthorizationEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a authorization entry and its current status.
    final class AuthorizationEntry {
        var code: String
        var name: String
        var threshold: Double
        var approved: Bool
        var facility: String
        var status: AuthorizationEntryStatus

        init(code: String, name: String, threshold: Double, approved: Bool, facility: String, status: AuthorizationEntryStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.approved = approved
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AuthorizationEntryStatus.approved || next == AuthorizationEntryStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AuthorizationEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> AuthorizationEntry {
            return AuthorizationEntry(
                code: code,
                name: name,
                threshold: threshold,
                approved: approved,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a authorization entry in status proposed.
    static func newAuthorizationEntry(_ code: String, name: String) -> AuthorizationEntry {
        return AuthorizationEntry(
            code: code,
            name: name,
            threshold: 0.0,
            approved: false,
            facility: "",
            status: AuthorizationEntryStatus.proposed
        )
    }
}
