import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal entry is in its life cycle.
    enum GoalEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A goal entry as the goal team keeps it.
    final class GoalEntry {
        var code: String
        var title: String
        var windowDays: Int
        var visible: Bool
        var copay: Double
        var facility: String
        var batchSize: Int
        var encounterID: String
        var status: GoalEntryStatus

        init(code: String, title: String, windowDays: Int, visible: Bool, copay: Double, facility: String, batchSize: Int, encounterID: String, status: GoalEntryStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.visible = visible
            self.copay = copay
            self.facility = facility
            self.batchSize = batchSize
            self.encounterID = encounterID
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

        func canMoveTo(_ next: GoalEntryStatus) -> Bool {
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
                return next == GoalEntryStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == GoalEntryStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return (Double(batchSize) * copay * 100).rounded() / 100
        }

        func copyValue() -> GoalEntry {
            return GoalEntry(
                code: code,
                title: title,
                windowDays: windowDays,
                visible: visible,
                copay: copay,
                facility: facility,
                batchSize: batchSize,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a goal entry in status open.
    static func newGoalEntry(_ code: String, title: String) -> GoalEntry {
        return GoalEntry(
            code: code,
            title: title,
            windowDays: 0,
            visible: false,
            copay: 0.0,
            facility: "",
            batchSize: 0,
            encounterID: "",
            status: GoalEntryStatus.`open`
        )
    }
}
