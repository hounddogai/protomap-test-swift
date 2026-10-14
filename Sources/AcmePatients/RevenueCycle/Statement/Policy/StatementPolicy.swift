import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement policy is in its life cycle.
    enum StatementPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A statement policy. Its code is unique within a tenant.
    final class StatementPolicy {
        var code: String
        var title: String
        var amount: Double
        var cost: Double
        var timezone: String
        var visible: Bool
        var country: String
        var status: StatementPolicyStatus

        init(code: String, title: String, amount: Double, cost: Double, timezone: String, visible: Bool, country: String, status: StatementPolicyStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.cost = cost
            self.timezone = timezone
            self.visible = visible
            self.country = country
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

        func canMoveTo(_ next: StatementPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == StatementPolicyStatus.active
            case .pending:
                return next == StatementPolicyStatus.active
            case .active:
                return next == StatementPolicyStatus.closed
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

        func moveTo(_ next: StatementPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement policy") \(code)"
        }

        func projectedLoad() -> Double {
            return ((cost - amount) * 100).rounded() / 100
        }

        func copyValue() -> StatementPolicy {
            return StatementPolicy(
                code: code,
                title: title,
                amount: amount,
                cost: cost,
                timezone: timezone,
                visible: visible,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a statement policy in status draft.
    static func newStatementPolicy(_ code: String, title: String) -> StatementPolicy {
        return StatementPolicy(
            code: code,
            title: title,
            amount: 0.0,
            cost: 0.0,
            timezone: "",
            visible: false,
            country: "",
            status: StatementPolicyStatus.draft
        )
    }
}
