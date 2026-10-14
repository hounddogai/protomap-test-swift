import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global task schedule is in its life cycle.
    enum GlobalTaskScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global task schedule, with what the planners need to act on it.
    final class GlobalTaskSchedule {
        var code: String
        var label: String
        var channel: String
        var expiresAt: Int
        var active: Bool
        var approved: Bool
        var timezone: String
        var status: GlobalTaskScheduleStatus

        init(code: String, label: String, channel: String, expiresAt: Int, active: Bool, approved: Bool, timezone: String, status: GlobalTaskScheduleStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.expiresAt = expiresAt
            self.active = active
            self.approved = approved
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalTaskScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == GlobalTaskScheduleStatus.draining || next == GlobalTaskScheduleStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalTaskScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global task schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> GlobalTaskSchedule {
            return GlobalTaskSchedule(
                code: code,
                label: label,
                channel: channel,
                expiresAt: expiresAt,
                active: active,
                approved: approved,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global task schedule in status idle.
    static func newGlobalTaskSchedule(_ code: String, label: String) -> GlobalTaskSchedule {
        return GlobalTaskSchedule(
            code: code,
            label: label,
            channel: "",
            expiresAt: 0,
            active: false,
            approved: false,
            timezone: "",
            status: GlobalTaskScheduleStatus.idle
        )
    }
}
