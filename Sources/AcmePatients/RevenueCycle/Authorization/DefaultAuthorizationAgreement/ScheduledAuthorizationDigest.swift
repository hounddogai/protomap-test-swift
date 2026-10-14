import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled authorization digest is in its life cycle.
    enum ScheduledAuthorizationDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled authorization digest as the authorization team keeps it.
    final class ScheduledAuthorizationDigest {
        var code: String
        var title: String
        var description: String
        var priority: Int
        var amount: Double
        var segment: String
        var source: String
        var unit: String
        var channel: String
        var active: Bool
        var status: ScheduledAuthorizationDigestStatus

        init(code: String, title: String, description: String, priority: Int, amount: Double, segment: String, source: String, unit: String, channel: String, active: Bool, status: ScheduledAuthorizationDigestStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.priority = priority
            self.amount = amount
            self.segment = segment
            self.source = source
            self.unit = unit
            self.channel = channel
            self.active = active
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

        func canMoveTo(_ next: ScheduledAuthorizationDigestStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledAuthorizationDigestStatus.pending || next == ScheduledAuthorizationDigestStatus.active
            case .pending:
                return next == ScheduledAuthorizationDigestStatus.closed
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

        func moveTo(_ next: ScheduledAuthorizationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled authorization digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled authorization digest") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(priority) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAuthorizationDigest {
            return ScheduledAuthorizationDigest(
                code: code,
                title: title,
                description: description,
                priority: priority,
                amount: amount,
                segment: segment,
                source: source,
                unit: unit,
                channel: channel,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled authorization digest in status draft.
    static func newScheduledAuthorizationDigest(_ code: String, title: String) -> ScheduledAuthorizationDigest {
        return ScheduledAuthorizationDigest(
            code: code,
            title: title,
            description: "",
            priority: 0,
            amount: 0.0,
            segment: "",
            source: "",
            unit: "",
            channel: "",
            active: false,
            status: ScheduledAuthorizationDigestStatus.draft
        )
    }
}
