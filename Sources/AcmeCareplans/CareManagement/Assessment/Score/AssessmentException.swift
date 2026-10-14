import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment exception is in its life cycle.
    enum AssessmentExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A assessment exception as the assessment team keeps it.
    final class AssessmentException {
        var code: String
        var label: String
        var segment: String
        var revision: Int
        var reviewer: String
        var budget: Double
        var ratio: Double
        var floorValue: Double
        var timezone: String
        var graceDays: Int
        var sequence: Int
        var status: AssessmentExceptionStatus

        init(code: String, label: String, segment: String, revision: Int, reviewer: String, budget: Double, ratio: Double, floorValue: Double, timezone: String, graceDays: Int, sequence: Int, status: AssessmentExceptionStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.revision = revision
            self.reviewer = reviewer
            self.budget = budget
            self.ratio = ratio
            self.floorValue = floorValue
            self.timezone = timezone
            self.graceDays = graceDays
            self.sequence = sequence
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

        func canMoveTo(_ next: AssessmentExceptionStatus) -> Bool {
            switch status {
            case .planned:
                return next == AssessmentExceptionStatus.scheduled
            case .scheduled:
                return next == AssessmentExceptionStatus.completed || next == AssessmentExceptionStatus.cancelled
            case .inProgress:
                return next == AssessmentExceptionStatus.completed || next == AssessmentExceptionStatus.cancelled
            case .completed:
                return next == AssessmentExceptionStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return ((floorValue - budget) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentException {
            return AssessmentException(
                code: code,
                label: label,
                segment: segment,
                revision: revision,
                reviewer: reviewer,
                budget: budget,
                ratio: ratio,
                floorValue: floorValue,
                timezone: timezone,
                graceDays: graceDays,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a assessment exception in status planned.
    static func newAssessmentException(_ code: String, label: String) -> AssessmentException {
        return AssessmentException(
            code: code,
            label: label,
            segment: "",
            revision: 0,
            reviewer: "",
            budget: 0.0,
            ratio: 0.0,
            floorValue: 0.0,
            timezone: "",
            graceDays: 0,
            sequence: 0,
            status: AssessmentExceptionStatus.planned
        )
    }
}
