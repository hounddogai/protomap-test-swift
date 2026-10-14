import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding schedule is in its life cycle.
    enum RoundingScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rounding schedule as the rounding team keeps it.
    final class RoundingSchedule {
        var code: String
        var title: String
        var batchSize: Int
        var visitMinutes: Int
        var score: Double
        var reviewer: String
        var status: RoundingScheduleStatus

        init(code: String, title: String, batchSize: Int, visitMinutes: Int, score: Double, reviewer: String, status: RoundingScheduleStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.visitMinutes = visitMinutes
            self.score = score
            self.reviewer = reviewer
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

        func canMoveTo(_ next: RoundingScheduleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RoundingScheduleStatus.completed || next == RoundingScheduleStatus.cancelled
            case .completed:
                return next == RoundingScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rounding schedule") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(visitMinutes) + score) * 100).rounded() / 100
        }

        func copyValue() -> RoundingSchedule {
            return RoundingSchedule(
                code: code,
                title: title,
                batchSize: batchSize,
                visitMinutes: visitMinutes,
                score: score,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rounding schedule in status planned.
    static func newRoundingSchedule(_ code: String, title: String) -> RoundingSchedule {
        return RoundingSchedule(
            code: code,
            title: title,
            batchSize: 0,
            visitMinutes: 0,
            score: 0.0,
            reviewer: "",
            status: RoundingScheduleStatus.planned
        )
    }
}
