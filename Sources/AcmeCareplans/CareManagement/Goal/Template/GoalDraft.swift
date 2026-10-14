import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal draft is in its life cycle.
    enum GoalDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A goal draft. Its code is unique within a tenant.
    final class GoalDraft {
        var code: String
        var label: String
        var startsAt: Int
        var copay: Double
        var pinned: Bool
        var priority: Int
        var status: GoalDraftStatus

        init(code: String, label: String, startsAt: Int, copay: Double, pinned: Bool, priority: Int, status: GoalDraftStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.copay = copay
            self.pinned = pinned
            self.priority = priority
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

        func canMoveTo(_ next: GoalDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == GoalDraftStatus.validated || next == GoalDraftStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GoalDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("goal draft") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(priority) + copay) * 100).rounded() / 100
        }

        func copyValue() -> GoalDraft {
            return GoalDraft(
                code: code,
                label: label,
                startsAt: startsAt,
                copay: copay,
                pinned: pinned,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a goal draft in status created.
    static func newGoalDraft(_ code: String, label: String) -> GoalDraft {
        return GoalDraft(
            code: code,
            label: label,
            startsAt: 0,
            copay: 0.0,
            pinned: false,
            priority: 0,
            status: GoalDraftStatus.created
        )
    }
}
