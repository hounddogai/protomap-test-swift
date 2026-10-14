import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped assessment schedule is in its life cycle.
    enum CappedAssessmentScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped assessment schedule, with what the planners need to act on it.
    final class CappedAssessmentSchedule {
        var code: String
        var label: String
        var floorValue: Double
        var tags: [String]
        var specialty: String
        var status: CappedAssessmentScheduleStatus

        init(code: String, label: String, floorValue: Double, tags: [String], specialty: String, status: CappedAssessmentScheduleStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.tags = tags
            self.specialty = specialty
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

        func canMoveTo(_ next: CappedAssessmentScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CappedAssessmentScheduleStatus.archived
            case .resolved:
                return next == CappedAssessmentScheduleStatus.reopened || next == CappedAssessmentScheduleStatus.archived
            case .reopened:
                return next == CappedAssessmentScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedAssessmentScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped assessment schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> CappedAssessmentSchedule {
            return CappedAssessmentSchedule(
                code: code,
                label: label,
                floorValue: floorValue,
                tags: tags,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped assessment schedule in status open.
    static func newCappedAssessmentSchedule(_ code: String, label: String) -> CappedAssessmentSchedule {
        return CappedAssessmentSchedule(
            code: code,
            label: label,
            floorValue: 0.0,
            tags: [],
            specialty: "",
            status: CappedAssessmentScheduleStatus.`open`
        )
    }
}
