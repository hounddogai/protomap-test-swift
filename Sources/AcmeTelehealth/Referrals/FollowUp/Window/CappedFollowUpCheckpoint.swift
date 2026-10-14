import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped follow up checkpoint is in its life cycle.
    enum CappedFollowUpCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped follow up checkpoint and its current status.
    final class CappedFollowUpCheckpoint {
        var code: String
        var title: String
        var ceiling: Double
        var channel: String
        var timezone: String
        var score: Double
        var status: CappedFollowUpCheckpointStatus

        init(code: String, title: String, ceiling: Double, channel: String, timezone: String, score: Double, status: CappedFollowUpCheckpointStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.channel = channel
            self.timezone = timezone
            self.score = score
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

        func canMoveTo(_ next: CappedFollowUpCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedFollowUpCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped follow up checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return (score * ceiling * 100).rounded() / 100
        }

        func copyValue() -> CappedFollowUpCheckpoint {
            return CappedFollowUpCheckpoint(
                code: code,
                title: title,
                ceiling: ceiling,
                channel: channel,
                timezone: timezone,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped follow up checkpoint in status proposed.
    static func newCappedFollowUpCheckpoint(_ code: String, title: String) -> CappedFollowUpCheckpoint {
        return CappedFollowUpCheckpoint(
            code: code,
            title: title,
            ceiling: 0.0,
            channel: "",
            timezone: "",
            score: 0.0,
            status: CappedFollowUpCheckpointStatus.proposed
        )
    }
}
