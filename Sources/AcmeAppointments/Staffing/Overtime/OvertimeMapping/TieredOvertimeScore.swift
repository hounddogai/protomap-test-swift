import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered overtime score is in its life cycle.
    enum TieredOvertimeScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered overtime score as the overtime team keeps it.
    final class TieredOvertimeScore {
        var code: String
        var label: String
        var limit: Int
        var floorValue: Double
        var score: Double
        var retries: Int
        var channel: String
        var durationMinutes: Int
        var status: TieredOvertimeScoreStatus

        init(code: String, label: String, limit: Int, floorValue: Double, score: Double, retries: Int, channel: String, durationMinutes: Int, status: TieredOvertimeScoreStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.floorValue = floorValue
            self.score = score
            self.retries = retries
            self.channel = channel
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

        func canMoveTo(_ next: TieredOvertimeScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == TieredOvertimeScoreStatus.cancelled
            case .inProgress:
                return next == TieredOvertimeScoreStatus.completed
            case .completed:
                return next == TieredOvertimeScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredOvertimeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered overtime score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return ((Double(retries) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredOvertimeScore {
            return TieredOvertimeScore(
                code: code,
                label: label,
                limit: limit,
                floorValue: floorValue,
                score: score,
                retries: retries,
                channel: channel,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a tiered overtime score in status planned.
    static func newTieredOvertimeScore(_ code: String, label: String) -> TieredOvertimeScore {
        return TieredOvertimeScore(
            code: code,
            label: label,
            limit: 0,
            floorValue: 0.0,
            score: 0.0,
            retries: 0,
            channel: "",
            durationMinutes: 0,
            status: TieredOvertimeScoreStatus.planned
        )
    }
}
