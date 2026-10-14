import AcmePlatform
import Foundation

extension Labs {
    /// Where a default reference range rule is in its life cycle.
    enum DefaultReferenceRangeRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default reference range rule and its current status.
    final class DefaultReferenceRangeRule {
        var code: String
        var title: String
        var country: String
        var score: Double
        var payer: String
        var quantity: Int
        var contactEmail: String
        var status: DefaultReferenceRangeRuleStatus

        init(code: String, title: String, country: String, score: Double, payer: String, quantity: Int, contactEmail: String, status: DefaultReferenceRangeRuleStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.score = score
            self.payer = payer
            self.quantity = quantity
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultReferenceRangeRuleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultReferenceRangeRuleStatus.rejected || next == DefaultReferenceRangeRuleStatus.withdrawn
            case .rejected:
                return next == DefaultReferenceRangeRuleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReferenceRangeRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default reference range rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default reference range rule") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(quantity) * score * 100).rounded() / 100
        }

        func copyValue() -> DefaultReferenceRangeRule {
            return DefaultReferenceRangeRule(
                code: code,
                title: title,
                country: country,
                score: score,
                payer: payer,
                quantity: quantity,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default reference range rule in status proposed.
    static func newDefaultReferenceRangeRule(_ code: String, title: String) -> DefaultReferenceRangeRule {
        return DefaultReferenceRangeRule(
            code: code,
            title: title,
            country: "",
            score: 0.0,
            payer: "",
            quantity: 0,
            contactEmail: "",
            status: DefaultReferenceRangeRuleStatus.proposed
        )
    }
}
