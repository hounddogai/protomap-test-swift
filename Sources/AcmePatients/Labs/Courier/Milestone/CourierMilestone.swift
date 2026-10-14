import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier milestone is in its life cycle.
    enum CourierMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A courier milestone. Its code is unique within a tenant.
    final class CourierMilestone {
        var code: String
        var label: String
        var windowDays: Int
        var attempts: Int
        var channel: String
        var patientRef: String
        var status: CourierMilestoneStatus

        init(code: String, label: String, windowDays: Int, attempts: Int, channel: String, patientRef: String, status: CourierMilestoneStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.attempts = attempts
            self.channel = channel
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CourierMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((Double(windowDays) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> CourierMilestone {
            return CourierMilestone(
                code: code,
                label: label,
                windowDays: windowDays,
                attempts: attempts,
                channel: channel,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a courier milestone in status requested.
    static func newCourierMilestone(_ code: String, label: String) -> CourierMilestone {
        return CourierMilestone(
            code: code,
            label: label,
            windowDays: 0,
            attempts: 0,
            channel: "",
            patientRef: "",
            status: CourierMilestoneStatus.requested
        )
    }
}
