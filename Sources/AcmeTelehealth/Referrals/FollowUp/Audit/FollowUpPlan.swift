import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up plan is in its life cycle.
    enum FollowUpPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A follow up plan. Its code is unique within a tenant.
    final class FollowUpPlan {
        var code: String
        var name: String
        var currency: String
        var attributes: [String: String]
        var allergy: String
        var active: Bool
        var amount: Double
        var locale: String
        var payer: String
        var status: FollowUpPlanStatus

        init(code: String, name: String, currency: String, attributes: [String: String], allergy: String, active: Bool, amount: Double, locale: String, payer: String, status: FollowUpPlanStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.attributes = attributes
            self.allergy = allergy
            self.active = active
            self.amount = amount
            self.locale = locale
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == FollowUpPlanStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FollowUpPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> FollowUpPlan {
            return FollowUpPlan(
                code: code,
                name: name,
                currency: currency,
                attributes: attributes,
                allergy: allergy,
                active: active,
                amount: amount,
                locale: locale,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a follow up plan in status requested.
    static func newFollowUpPlan(_ code: String, name: String) -> FollowUpPlan {
        return FollowUpPlan(
            code: code,
            name: name,
            currency: "",
            attributes: [:],
            allergy: "",
            active: false,
            amount: 0.0,
            locale: "",
            payer: "",
            status: FollowUpPlanStatus.requested
        )
    }
}
