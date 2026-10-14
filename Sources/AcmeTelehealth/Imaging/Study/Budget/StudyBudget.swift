import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study budget is in its life cycle.
    enum StudyBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a study budget and its current status.
    final class StudyBudget {
        var code: String
        var name: String
        var capacity: Int
        var unit: String
        var sequence: Int
        var ceiling: Double
        var margin: Double
        var status: StudyBudgetStatus

        init(code: String, name: String, capacity: Int, unit: String, sequence: Int, ceiling: Double, margin: Double, status: StudyBudgetStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.unit = unit
            self.sequence = sequence
            self.ceiling = ceiling
            self.margin = margin
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

        func canMoveTo(_ next: StudyBudgetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == StudyBudgetStatus.completed || next == StudyBudgetStatus.cancelled
            case .inProgress:
                return next == StudyBudgetStatus.completed || next == StudyBudgetStatus.cancelled
            case .completed:
                return next == StudyBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((ceiling + margin) * 100).rounded() / 100
        }

        func copyValue() -> StudyBudget {
            return StudyBudget(
                code: code,
                name: name,
                capacity: capacity,
                unit: unit,
                sequence: sequence,
                ceiling: ceiling,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a study budget in status planned.
    static func newStudyBudget(_ code: String, name: String) -> StudyBudget {
        return StudyBudget(
            code: code,
            name: name,
            capacity: 0,
            unit: "",
            sequence: 0,
            ceiling: 0.0,
            margin: 0.0,
            status: StudyBudgetStatus.planned
        )
    }
}
