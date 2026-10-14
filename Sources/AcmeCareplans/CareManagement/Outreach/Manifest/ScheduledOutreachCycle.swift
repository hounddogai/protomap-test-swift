import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled outreach cycle is in its life cycle.
    enum ScheduledOutreachCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One scheduled outreach cycle, with what the planners need to act on it.
    final class ScheduledOutreachCycle {
        var code: String
        var label: String
        var tags: [String]
        var ceiling: Double
        var channel: String
        var status: ScheduledOutreachCycleStatus

        init(code: String, label: String, tags: [String], ceiling: Double, channel: String, status: ScheduledOutreachCycleStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.ceiling = ceiling
            self.channel = channel
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

        func canMoveTo(_ next: ScheduledOutreachCycleStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledOutreachCycleStatus.granted || next == ScheduledOutreachCycleStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ScheduledOutreachCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledOutreachCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled outreach cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> ScheduledOutreachCycle {
            return ScheduledOutreachCycle(
                code: code,
                label: label,
                tags: tags,
                ceiling: ceiling,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled outreach cycle in status requested.
    static func newScheduledOutreachCycle(_ code: String, label: String) -> ScheduledOutreachCycle {
        return ScheduledOutreachCycle(
            code: code,
            label: label,
            tags: [],
            ceiling: 0.0,
            channel: "",
            status: ScheduledOutreachCycleStatus.requested
        )
    }
}
