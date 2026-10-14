import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential rule is in its life cycle.
    enum CredentialRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential rule as the credential team keeps it.
    final class CredentialRule {
        var code: String
        var title: String
        var revision: Int
        var contactEmail: String
        var rate: Double
        var locale: String
        var attributes: [String: String]
        var phone: String
        var region: String
        var status: CredentialRuleStatus

        init(code: String, title: String, revision: Int, contactEmail: String, rate: Double, locale: String, attributes: [String: String], phone: String, region: String, status: CredentialRuleStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.contactEmail = contactEmail
            self.rate = rate
            self.locale = locale
            self.attributes = attributes
            self.phone = phone
            self.region = region
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

        func canMoveTo(_ next: CredentialRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CredentialRuleStatus.inReview || next == CredentialRuleStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
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
                return next == CredentialRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func weightedTotal() -> Double {
            return ((rate + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialRule {
            return CredentialRule(
                code: code,
                title: title,
                revision: revision,
                contactEmail: contactEmail,
                rate: rate,
                locale: locale,
                attributes: attributes,
                phone: phone,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a credential rule in status open.
    static func newCredentialRule(_ code: String, title: String) -> CredentialRule {
        return CredentialRule(
            code: code,
            title: title,
            revision: 0,
            contactEmail: "",
            rate: 0.0,
            locale: "",
            attributes: [:],
            phone: "",
            region: "",
            status: CredentialRuleStatus.`open`
        )
    }
}
