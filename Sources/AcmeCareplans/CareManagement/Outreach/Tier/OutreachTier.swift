import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach tier is in its life cycle.
    enum OutreachTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A outreach tier as the outreach team keeps it.
    final class OutreachTier {
        var code: String
        var title: String
        var locale: String
        var currency: String
        var minimum: Double
        var durationMinutes: Int
        var contactEmail: String
        var tags: [String]
        var graceDays: Int
        var allergy: String
        var status: OutreachTierStatus

        init(code: String, title: String, locale: String, currency: String, minimum: Double, durationMinutes: Int, contactEmail: String, tags: [String], graceDays: Int, allergy: String, status: OutreachTierStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.currency = currency
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.tags = tags
            self.graceDays = graceDays
            self.allergy = allergy
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

        func canMoveTo(_ next: OutreachTierStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OutreachTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return (Double(graceDays) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> OutreachTier {
            return OutreachTier(
                code: code,
                title: title,
                locale: locale,
                currency: currency,
                minimum: minimum,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                tags: tags,
                graceDays: graceDays,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a outreach tier in status proposed.
    static func newOutreachTier(_ code: String, title: String) -> OutreachTier {
        return OutreachTier(
            code: code,
            title: title,
            locale: "",
            currency: "",
            minimum: 0.0,
            durationMinutes: 0,
            contactEmail: "",
            tags: [],
            graceDays: 0,
            allergy: "",
            status: OutreachTierStatus.proposed
        )
    }
}
