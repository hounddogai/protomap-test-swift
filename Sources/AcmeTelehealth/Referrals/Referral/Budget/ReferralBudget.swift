import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral budget is in its life cycle.
    enum ReferralBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One referral budget, with what the planners need to act on it.
    final class ReferralBudget {
        var code: String
        var title: String
        var expiresAt: Int
        var quantity: Int
        var timezone: String
        var status: ReferralBudgetStatus

        init(code: String, title: String, expiresAt: Int, quantity: Int, timezone: String, status: ReferralBudgetStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.timezone = timezone
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

        func canMoveTo(_ next: ReferralBudgetStatus) -> Bool {
            switch status {
            case .created:
                return next == ReferralBudgetStatus.published
            case .validated:
                return next == ReferralBudgetStatus.published || next == ReferralBudgetStatus.retired
            case .published:
                return next == ReferralBudgetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("referral budget") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(expiresAt) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> ReferralBudget {
            return ReferralBudget(
                code: code,
                title: title,
                expiresAt: expiresAt,
                quantity: quantity,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a referral budget in status created.
    static func newReferralBudget(_ code: String, title: String) -> ReferralBudget {
        return ReferralBudget(
            code: code,
            title: title,
            expiresAt: 0,
            quantity: 0,
            timezone: "",
            status: ReferralBudgetStatus.created
        )
    }
}
