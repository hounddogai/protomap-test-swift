import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict goal group is in its life cycle.
    enum StrictGoalGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict goal group. Its code is unique within a tenant.
    final class StrictGoalGroup {
        var code: String
        var name: String
        var allergy: String
        var label: String
        var visible: Bool
        var score: Double
        var status: StrictGoalGroupStatus

        init(code: String, name: String, allergy: String, label: String, visible: Bool, score: Double, status: StrictGoalGroupStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.label = label
            self.visible = visible
            self.score = score
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

        func canMoveTo(_ next: StrictGoalGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictGoalGroupStatus.active || next == StrictGoalGroupStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StrictGoalGroupStatus.suspended || next == StrictGoalGroupStatus.closed
            case .suspended:
                return next == StrictGoalGroupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictGoalGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict goal group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> StrictGoalGroup {
            return StrictGoalGroup(
                code: code,
                name: name,
                allergy: allergy,
                label: label,
                visible: visible,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict goal group in status draft.
    static func newStrictGoalGroup(_ code: String, name: String) -> StrictGoalGroup {
        return StrictGoalGroup(
            code: code,
            name: name,
            allergy: "",
            label: "",
            visible: false,
            score: 0.0,
            status: StrictGoalGroupStatus.draft
        )
    }
}
