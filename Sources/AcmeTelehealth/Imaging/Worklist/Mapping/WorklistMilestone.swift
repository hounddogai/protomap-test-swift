import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist milestone is in its life cycle.
    enum WorklistMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A worklist milestone as the worklist team keeps it.
    final class WorklistMilestone {
        var code: String
        var title: String
        var segment: String
        var notes: String
        var acuity: Int
        var graceDays: Int
        var timezone: String
        var revision: Int
        var maximum: Double
        var approved: Bool
        var status: WorklistMilestoneStatus

        init(code: String, title: String, segment: String, notes: String, acuity: Int, graceDays: Int, timezone: String, revision: Int, maximum: Double, approved: Bool, status: WorklistMilestoneStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.notes = notes
            self.acuity = acuity
            self.graceDays = graceDays
            self.timezone = timezone
            self.revision = revision
            self.maximum = maximum
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WorklistMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedLoad() -> Double {
            return ((maximum - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistMilestone {
            return WorklistMilestone(
                code: code,
                title: title,
                segment: segment,
                notes: notes,
                acuity: acuity,
                graceDays: graceDays,
                timezone: timezone,
                revision: revision,
                maximum: maximum,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a worklist milestone in status created.
    static func newWorklistMilestone(_ code: String, title: String) -> WorklistMilestone {
        return WorklistMilestone(
            code: code,
            title: title,
            segment: "",
            notes: "",
            acuity: 0,
            graceDays: 0,
            timezone: "",
            revision: 0,
            maximum: 0.0,
            approved: false,
            status: WorklistMilestoneStatus.created
        )
    }
}
