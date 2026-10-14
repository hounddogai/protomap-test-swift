import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal record is in its life cycle.
    enum GoalRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a goal record and its current status.
    final class GoalRecord {
        var code: String
        var title: String
        var summary: String
        var segment: String
        var threshold: Double
        var patientRef: String
        var status: GoalRecordStatus

        init(code: String, title: String, summary: String, segment: String, threshold: Double, patientRef: String, status: GoalRecordStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.segment = segment
            self.threshold = threshold
            self.patientRef = patientRef
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

        func canMoveTo(_ next: GoalRecordStatus) -> Bool {
            switch status {
            case .planned:
                return next == GoalRecordStatus.inProgress
            case .scheduled:
                return next == GoalRecordStatus.inProgress || next == GoalRecordStatus.completed
            case .inProgress:
                return next == GoalRecordStatus.completed || next == GoalRecordStatus.cancelled
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

        func moveTo(_ next: GoalRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("goal record") \(code)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> GoalRecord {
            return GoalRecord(
                code: code,
                title: title,
                summary: summary,
                segment: segment,
                threshold: threshold,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a goal record in status planned.
    static func newGoalRecord(_ code: String, title: String) -> GoalRecord {
        return GoalRecord(
            code: code,
            title: title,
            summary: "",
            segment: "",
            threshold: 0.0,
            patientRef: "",
            status: GoalRecordStatus.planned
        )
    }
}
