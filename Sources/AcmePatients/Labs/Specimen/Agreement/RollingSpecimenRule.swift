import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling specimen rule is in its life cycle.
    enum RollingSpecimenRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One rolling specimen rule, with what the planners need to act on it.
    final class RollingSpecimenRule {
        var code: String
        var name: String
        var payer: String
        var facility: String
        var limit: Int
        var contactEmail: String
        var currency: String
        var quantity: Int
        var graceDays: Int
        var phone: String
        var tags: [String]
        var status: RollingSpecimenRuleStatus

        init(code: String, name: String, payer: String, facility: String, limit: Int, contactEmail: String, currency: String, quantity: Int, graceDays: Int, phone: String, tags: [String], status: RollingSpecimenRuleStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.facility = facility
            self.limit = limit
            self.contactEmail = contactEmail
            self.currency = currency
            self.quantity = quantity
            self.graceDays = graceDays
            self.phone = phone
            self.tags = tags
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

        func canMoveTo(_ next: RollingSpecimenRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingSpecimenRuleStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingSpecimenRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling specimen rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling specimen rule") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return (Double(limit) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> RollingSpecimenRule {
            return RollingSpecimenRule(
                code: code,
                name: name,
                payer: payer,
                facility: facility,
                limit: limit,
                contactEmail: contactEmail,
                currency: currency,
                quantity: quantity,
                graceDays: graceDays,
                phone: phone,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling specimen rule in status draft.
    static func newRollingSpecimenRule(_ code: String, name: String) -> RollingSpecimenRule {
        return RollingSpecimenRule(
            code: code,
            name: name,
            payer: "",
            facility: "",
            limit: 0,
            contactEmail: "",
            currency: "",
            quantity: 0,
            graceDays: 0,
            phone: "",
            tags: [],
            status: RollingSpecimenRuleStatus.draft
        )
    }
}
