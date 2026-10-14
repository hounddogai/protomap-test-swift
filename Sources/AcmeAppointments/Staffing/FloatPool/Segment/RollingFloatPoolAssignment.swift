import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling float pool assignment is in its life cycle.
    enum RollingFloatPoolAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rolling float pool assignment and its current status.
    final class RollingFloatPoolAssignment {
        var code: String
        var label: String
        var channel: String
        var approved: Bool
        var attempts: Int
        var phone: String
        var status: RollingFloatPoolAssignmentStatus

        init(code: String, label: String, channel: String, approved: Bool, attempts: Int, phone: String, status: RollingFloatPoolAssignmentStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.approved = approved
            self.attempts = attempts
            self.phone = phone
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

        func canMoveTo(_ next: RollingFloatPoolAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingFloatPoolAssignmentStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingFloatPoolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling float pool assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling float pool assignment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> RollingFloatPoolAssignment {
            return RollingFloatPoolAssignment(
                code: code,
                label: label,
                channel: channel,
                approved: approved,
                attempts: attempts,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling float pool assignment in status proposed.
    static func newRollingFloatPoolAssignment(_ code: String, label: String) -> RollingFloatPoolAssignment {
        return RollingFloatPoolAssignment(
            code: code,
            label: label,
            channel: "",
            approved: false,
            attempts: 0,
            phone: "",
            status: RollingFloatPoolAssignmentStatus.proposed
        )
    }
}
