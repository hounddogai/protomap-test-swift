import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task rule is in its life cycle.
    enum TaskRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a task rule and its current status.
    final class TaskRule {
        var code: String
        var label: String
        var phone: String
        var reviewer: String
        var ceiling: Double
        var procedureCode: String
        var status: TaskRuleStatus

        init(code: String, label: String, phone: String, reviewer: String, ceiling: Double, procedureCode: String, status: TaskRuleStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.reviewer = reviewer
            self.ceiling = ceiling
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: TaskRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
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

        func moveTo(_ next: TaskRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("task rule") \(code)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> TaskRule {
            return TaskRule(
                code: code,
                label: label,
                phone: phone,
                reviewer: reviewer,
                ceiling: ceiling,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task rule in status open.
    static func newTaskRule(_ code: String, label: String) -> TaskRule {
        return TaskRule(
            code: code,
            label: label,
            phone: "",
            reviewer: "",
            ceiling: 0.0,
            procedureCode: "",
            status: TaskRuleStatus.`open`
        )
    }
}
