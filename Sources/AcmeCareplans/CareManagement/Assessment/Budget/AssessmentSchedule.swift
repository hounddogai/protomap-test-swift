import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment schedule is in its life cycle.
    enum AssessmentScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a assessment schedule and its current status.
    final class AssessmentSchedule {
        var code: String
        var title: String
        var visible: Bool
        var notes: String
        var endsAt: Int
        var active: Bool
        var externalRef: String
        var priority: Int
        var acuity: Int
        var status: AssessmentScheduleStatus

        init(code: String, title: String, visible: Bool, notes: String, endsAt: Int, active: Bool, externalRef: String, priority: Int, acuity: Int, status: AssessmentScheduleStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.notes = notes
            self.endsAt = endsAt
            self.active = active
            self.externalRef = externalRef
            self.priority = priority
            self.acuity = acuity
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

        func canMoveTo(_ next: AssessmentScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AssessmentScheduleStatus.reopened || next == AssessmentScheduleStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AssessmentScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return (Double(acuity) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentSchedule {
            return AssessmentSchedule(
                code: code,
                title: title,
                visible: visible,
                notes: notes,
                endsAt: endsAt,
                active: active,
                externalRef: externalRef,
                priority: priority,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment schedule in status open.
    static func newAssessmentSchedule(_ code: String, title: String) -> AssessmentSchedule {
        return AssessmentSchedule(
            code: code,
            title: title,
            visible: false,
            notes: "",
            endsAt: 0,
            active: false,
            externalRef: "",
            priority: 0,
            acuity: 0,
            status: AssessmentScheduleStatus.`open`
        )
    }
}
