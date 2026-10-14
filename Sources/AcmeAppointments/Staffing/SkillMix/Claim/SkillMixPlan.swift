import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix plan is in its life cycle.
    enum SkillMixPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One skill mix plan, with what the planners need to act on it.
    final class SkillMixPlan {
        var code: String
        var label: String
        var bed: String
        var country: String
        var phone: String
        var contactEmail: String
        var timezone: String
        var locale: String
        var archived: Bool
        var amount: Double
        var status: SkillMixPlanStatus

        init(code: String, label: String, bed: String, country: String, phone: String, contactEmail: String, timezone: String, locale: String, archived: Bool, amount: Double, status: SkillMixPlanStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.country = country
            self.phone = phone
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.locale = locale
            self.archived = archived
            self.amount = amount
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

        func canMoveTo(_ next: SkillMixPlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SkillMixPlanStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SkillMixPlanStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix plan") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> SkillMixPlan {
            return SkillMixPlan(
                code: code,
                label: label,
                bed: bed,
                country: country,
                phone: phone,
                contactEmail: contactEmail,
                timezone: timezone,
                locale: locale,
                archived: archived,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a skill mix plan in status proposed.
    static func newSkillMixPlan(_ code: String, label: String) -> SkillMixPlan {
        return SkillMixPlan(
            code: code,
            label: label,
            bed: "",
            country: "",
            phone: "",
            contactEmail: "",
            timezone: "",
            locale: "",
            archived: false,
            amount: 0.0,
            status: SkillMixPlanStatus.proposed
        )
    }
}
