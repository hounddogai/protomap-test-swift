import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal template is in its life cycle.
    enum GoalTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One goal template, with what the planners need to act on it.
    final class GoalTemplate {
        var code: String
        var title: String
        var clinicianID: String
        var windowDays: Int
        var ownerID: String
        var attempts: Int
        var pinned: Bool
        var ratio: Double
        var unit: String
        var status: GoalTemplateStatus

        init(code: String, title: String, clinicianID: String, windowDays: Int, ownerID: String, attempts: Int, pinned: Bool, ratio: Double, unit: String, status: GoalTemplateStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.windowDays = windowDays
            self.ownerID = ownerID
            self.attempts = attempts
            self.pinned = pinned
            self.ratio = ratio
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == GoalTemplateStatus.suspended || next == GoalTemplateStatus.closed
            case .pending:
                return next == GoalTemplateStatus.active || next == GoalTemplateStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: GoalTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("goal template") \(code)"
        }

        func effectiveTotal() -> Double {
            return (ratio * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> GoalTemplate {
            return GoalTemplate(
                code: code,
                title: title,
                clinicianID: clinicianID,
                windowDays: windowDays,
                ownerID: ownerID,
                attempts: attempts,
                pinned: pinned,
                ratio: ratio,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a goal template in status draft.
    static func newGoalTemplate(_ code: String, title: String) -> GoalTemplate {
        return GoalTemplate(
            code: code,
            title: title,
            clinicianID: "",
            windowDays: 0,
            ownerID: "",
            attempts: 0,
            pinned: false,
            ratio: 0.0,
            unit: "",
            status: GoalTemplateStatus.draft
        )
    }
}
