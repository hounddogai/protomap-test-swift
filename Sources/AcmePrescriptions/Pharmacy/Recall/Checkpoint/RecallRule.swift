import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall rule is in its life cycle.
    enum RecallRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A recall rule. Its code is unique within a tenant.
    final class RecallRule {
        var code: String
        var label: String
        var amount: Double
        var cost: Double
        var bed: String
        var notes: String
        var status: RecallRuleStatus

        init(code: String, label: String, amount: Double, cost: Double, bed: String, notes: String, status: RecallRuleStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.cost = cost
            self.bed = bed
            self.notes = notes
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

        func canMoveTo(_ next: RecallRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
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
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RecallRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (cost * amount * 100).rounded() / 100
        }

        func copyValue() -> RecallRule {
            return RecallRule(
                code: code,
                label: label,
                amount: amount,
                cost: cost,
                bed: bed,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a recall rule in status open.
    static func newRecallRule(_ code: String, label: String) -> RecallRule {
        return RecallRule(
            code: code,
            label: label,
            amount: 0.0,
            cost: 0.0,
            bed: "",
            notes: "",
            status: RecallRuleStatus.`open`
        )
    }
}
