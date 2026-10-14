import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority rule is in its life cycle.
    enum PriorityRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a priority rule and its current status.
    final class PriorityRule {
        var code: String
        var label: String
        var dosageMg: Double
        var attempts: Int
        var graceDays: Int
        var segment: String
        var priority: Int
        var bed: String
        var discount: Double
        var procedureCode: String
        var status: PriorityRuleStatus

        init(code: String, label: String, dosageMg: Double, attempts: Int, graceDays: Int, segment: String, priority: Int, bed: String, discount: Double, procedureCode: String, status: PriorityRuleStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.attempts = attempts
            self.graceDays = graceDays
            self.segment = segment
            self.priority = priority
            self.bed = bed
            self.discount = discount
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

        func canMoveTo(_ next: PriorityRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
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
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PriorityRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveLoad() -> Double {
            return (Double(attempts) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> PriorityRule {
            return PriorityRule(
                code: code,
                label: label,
                dosageMg: dosageMg,
                attempts: attempts,
                graceDays: graceDays,
                segment: segment,
                priority: priority,
                bed: bed,
                discount: discount,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a priority rule in status open.
    static func newPriorityRule(_ code: String, label: String) -> PriorityRule {
        return PriorityRule(
            code: code,
            label: label,
            dosageMg: 0.0,
            attempts: 0,
            graceDays: 0,
            segment: "",
            priority: 0,
            bed: "",
            discount: 0.0,
            procedureCode: "",
            status: PriorityRuleStatus.`open`
        )
    }
}
