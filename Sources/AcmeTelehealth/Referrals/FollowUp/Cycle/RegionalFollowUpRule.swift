import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional follow up rule is in its life cycle.
    enum RegionalFollowUpRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional follow up rule. Its code is unique within a tenant.
    final class RegionalFollowUpRule {
        var code: String
        var name: String
        var cost: Double
        var ratio: Double
        var currency: String
        var endsAt: Int
        var phone: String
        var payer: String
        var status: RegionalFollowUpRuleStatus

        init(code: String, name: String, cost: Double, ratio: Double, currency: String, endsAt: Int, phone: String, payer: String, status: RegionalFollowUpRuleStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.ratio = ratio
            self.currency = currency
            self.endsAt = endsAt
            self.phone = phone
            self.payer = payer
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

        func canMoveTo(_ next: RegionalFollowUpRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RegionalFollowUpRuleStatus.published || next == RegionalFollowUpRuleStatus.retired
            case .published:
                return next == RegionalFollowUpRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalFollowUpRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional follow up rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional follow up rule") \(code)"
        }

        func projectedLoad() -> Double {
            return ((cost + ratio) * 100).rounded() / 100
        }

        func copyValue() -> RegionalFollowUpRule {
            return RegionalFollowUpRule(
                code: code,
                name: name,
                cost: cost,
                ratio: ratio,
                currency: currency,
                endsAt: endsAt,
                phone: phone,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional follow up rule in status created.
    static func newRegionalFollowUpRule(_ code: String, name: String) -> RegionalFollowUpRule {
        return RegionalFollowUpRule(
            code: code,
            name: name,
            cost: 0.0,
            ratio: 0.0,
            currency: "",
            endsAt: 0,
            phone: "",
            payer: "",
            status: RegionalFollowUpRuleStatus.created
        )
    }
}
