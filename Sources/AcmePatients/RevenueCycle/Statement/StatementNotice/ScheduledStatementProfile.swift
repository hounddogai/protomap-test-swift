import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled statement profile is in its life cycle.
    enum ScheduledStatementProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled statement profile as the statement team keeps it.
    final class ScheduledStatementProfile {
        var code: String
        var name: String
        var rate: Double
        var channel: String
        var label: String
        var endsAt: Int
        var ceiling: Double
        var status: ScheduledStatementProfileStatus

        init(code: String, name: String, rate: Double, channel: String, label: String, endsAt: Int, ceiling: Double, status: ScheduledStatementProfileStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.channel = channel
            self.label = label
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledStatementProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledStatementProfileStatus.resolved || next == ScheduledStatementProfileStatus.reopened
            case .inReview:
                return next == ScheduledStatementProfileStatus.resolved
            case .resolved:
                return next == ScheduledStatementProfileStatus.reopened
            case .reopened:
                return next == ScheduledStatementProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledStatementProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled statement profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled statement profile") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((ceiling - rate) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledStatementProfile {
            return ScheduledStatementProfile(
                code: code,
                name: name,
                rate: rate,
                channel: channel,
                label: label,
                endsAt: endsAt,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled statement profile in status open.
    static func newScheduledStatementProfile(_ code: String, name: String) -> ScheduledStatementProfile {
        return ScheduledStatementProfile(
            code: code,
            name: name,
            rate: 0.0,
            channel: "",
            label: "",
            endsAt: 0,
            ceiling: 0.0,
            status: ScheduledStatementProfileStatus.`open`
        )
    }
}
