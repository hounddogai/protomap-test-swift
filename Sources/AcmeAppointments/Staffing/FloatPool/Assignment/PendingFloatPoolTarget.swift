import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending float pool target is in its life cycle.
    enum PendingFloatPoolTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending float pool target and its current status.
    final class PendingFloatPoolTarget {
        var code: String
        var name: String
        var retries: Int
        var durationMinutes: Int
        var reviewer: String
        var channel: String
        var summary: String
        var acuity: Int
        var discount: Double
        var endsAt: Int
        var status: PendingFloatPoolTargetStatus

        init(code: String, name: String, retries: Int, durationMinutes: Int, reviewer: String, channel: String, summary: String, acuity: Int, discount: Double, endsAt: Int, status: PendingFloatPoolTargetStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.durationMinutes = durationMinutes
            self.reviewer = reviewer
            self.channel = channel
            self.summary = summary
            self.acuity = acuity
            self.discount = discount
            self.endsAt = endsAt
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

        func canMoveTo(_ next: PendingFloatPoolTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingFloatPoolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending float pool target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending float pool target") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(durationMinutes) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingFloatPoolTarget {
            return PendingFloatPoolTarget(
                code: code,
                name: name,
                retries: retries,
                durationMinutes: durationMinutes,
                reviewer: reviewer,
                channel: channel,
                summary: summary,
                acuity: acuity,
                discount: discount,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending float pool target in status planned.
    static func newPendingFloatPoolTarget(_ code: String, name: String) -> PendingFloatPoolTarget {
        return PendingFloatPoolTarget(
            code: code,
            name: name,
            retries: 0,
            durationMinutes: 0,
            reviewer: "",
            channel: "",
            summary: "",
            acuity: 0,
            discount: 0.0,
            endsAt: 0,
            status: PendingFloatPoolTargetStatus.planned
        )
    }
}
