import AcmePlatform
import Foundation

extension Consent {
    /// Where a language rule is in its life cycle.
    enum LanguageRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A language rule. Its code is unique within a tenant.
    final class LanguageRule {
        var code: String
        var title: String
        var refills: Int
        var ceiling: Double
        var durationMinutes: Int
        var cost: Double
        var reviewer: String
        var contactEmail: String
        var ward: String
        var status: LanguageRuleStatus

        init(code: String, title: String, refills: Int, ceiling: Double, durationMinutes: Int, cost: Double, reviewer: String, contactEmail: String, ward: String, status: LanguageRuleStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.reviewer = reviewer
            self.contactEmail = contactEmail
            self.ward = ward
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

        func canMoveTo(_ next: LanguageRuleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LanguageRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return (ceiling * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> LanguageRule {
            return LanguageRule(
                code: code,
                title: title,
                refills: refills,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                cost: cost,
                reviewer: reviewer,
                contactEmail: contactEmail,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a language rule in status requested.
    static func newLanguageRule(_ code: String, title: String) -> LanguageRule {
        return LanguageRule(
            code: code,
            title: title,
            refills: 0,
            ceiling: 0.0,
            durationMinutes: 0,
            cost: 0.0,
            reviewer: "",
            contactEmail: "",
            ward: "",
            status: LanguageRuleStatus.requested
        )
    }
}
