import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary reference range schedule is in its life cycle.
    enum PrimaryReferenceRangeScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a primary reference range schedule and its current status.
    final class PrimaryReferenceRangeSchedule {
        var code: String
        var title: String
        var score: Double
        var batchSize: Int
        var channel: String
        var description: String
        var status: PrimaryReferenceRangeScheduleStatus

        init(code: String, title: String, score: Double, batchSize: Int, channel: String, description: String, status: PrimaryReferenceRangeScheduleStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.batchSize = batchSize
            self.channel = channel
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryReferenceRangeScheduleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PrimaryReferenceRangeScheduleStatus.running || next == PrimaryReferenceRangeScheduleStatus.failed
            case .running:
                return next == PrimaryReferenceRangeScheduleStatus.done || next == PrimaryReferenceRangeScheduleStatus.failed
            case .done:
                return next == PrimaryReferenceRangeScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryReferenceRangeScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary reference range schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary reference range schedule") \(code)"
        }

        func projectedExposure() -> Double {
            return ((score + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryReferenceRangeSchedule {
            return PrimaryReferenceRangeSchedule(
                code: code,
                title: title,
                score: score,
                batchSize: batchSize,
                channel: channel,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary reference range schedule in status new.
    static func newPrimaryReferenceRangeSchedule(_ code: String, title: String) -> PrimaryReferenceRangeSchedule {
        return PrimaryReferenceRangeSchedule(
            code: code,
            title: title,
            score: 0.0,
            batchSize: 0,
            channel: "",
            description: "",
            status: PrimaryReferenceRangeScheduleStatus.new
        )
    }
}
