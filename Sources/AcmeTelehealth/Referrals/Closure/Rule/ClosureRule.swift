import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure rule is in its life cycle.
    enum ClosureRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A closure rule. Its code is unique within a tenant.
    final class ClosureRule {
        var code: String
        var label: String
        var channel: String
        var amount: Double
        var updatedAt: Int
        var encounterID: String
        var status: ClosureRuleStatus

        init(code: String, label: String, channel: String, amount: Double, updatedAt: Int, encounterID: String, status: ClosureRuleStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.amount = amount
            self.updatedAt = updatedAt
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ClosureRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ClosureRuleStatus.active || next == ClosureRuleStatus.suspended
            case .active:
                return next == ClosureRuleStatus.closed
            case .suspended:
                return next == ClosureRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("closure rule") \(code)"
        }

        func netTotal() -> Double {
            return (amount * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ClosureRule {
            return ClosureRule(
                code: code,
                label: label,
                channel: channel,
                amount: amount,
                updatedAt: updatedAt,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a closure rule in status draft.
    static func newClosureRule(_ code: String, label: String) -> ClosureRule {
        return ClosureRule(
            code: code,
            label: label,
            channel: "",
            amount: 0.0,
            updatedAt: 0,
            encounterID: "",
            status: ClosureRuleStatus.draft
        )
    }
}
