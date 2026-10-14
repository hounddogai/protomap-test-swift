import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance digest is in its life cycle.
    enum RemittanceDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A remittance digest. Its code is unique within a tenant.
    final class RemittanceDigest {
        var code: String
        var name: String
        var channel: String
        var timezone: String
        var source: String
        var durationMinutes: Int
        var status: RemittanceDigestStatus

        init(code: String, name: String, channel: String, timezone: String, source: String, durationMinutes: Int, status: RemittanceDigestStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.timezone = timezone
            self.source = source
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: RemittanceDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RemittanceDigestStatus.completed || next == RemittanceDigestStatus.cancelled
            case .completed:
                return next == RemittanceDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> RemittanceDigest {
            return RemittanceDigest(
                code: code,
                name: name,
                channel: channel,
                timezone: timezone,
                source: source,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a remittance digest in status planned.
    static func newRemittanceDigest(_ code: String, name: String) -> RemittanceDigest {
        return RemittanceDigest(
            code: code,
            name: name,
            channel: "",
            timezone: "",
            source: "",
            durationMinutes: 0,
            status: RemittanceDigestStatus.planned
        )
    }
}
