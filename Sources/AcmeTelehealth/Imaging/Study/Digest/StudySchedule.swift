import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study schedule is in its life cycle.
    enum StudyScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A study schedule as the study team keeps it.
    final class StudySchedule {
        var code: String
        var name: String
        var reviewer: String
        var patientRef: String
        var durationMinutes: Int
        var capacity: Int
        var status: StudyScheduleStatus

        init(code: String, name: String, reviewer: String, patientRef: String, durationMinutes: Int, capacity: Int, status: StudyScheduleStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.durationMinutes = durationMinutes
            self.capacity = capacity
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

        func canMoveTo(_ next: StudyScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StudyScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return (Double(capacity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> StudySchedule {
            return StudySchedule(
                code: code,
                name: name,
                reviewer: reviewer,
                patientRef: patientRef,
                durationMinutes: durationMinutes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study schedule in status open.
    static func newStudySchedule(_ code: String, name: String) -> StudySchedule {
        return StudySchedule(
            code: code,
            name: name,
            reviewer: "",
            patientRef: "",
            durationMinutes: 0,
            capacity: 0,
            status: StudyScheduleStatus.`open`
        )
    }
}
