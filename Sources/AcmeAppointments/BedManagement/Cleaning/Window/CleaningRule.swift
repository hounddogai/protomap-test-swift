import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning rule is in its life cycle.
    enum CleaningRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A cleaning rule. Its code is unique within a tenant.
    final class CleaningRule {
        var code: String
        var name: String
        var phone: String
        var locale: String
        var expiresAt: Int
        var channel: String
        var discount: Double
        var tags: [String]
        var visitMinutes: Int
        var status: CleaningRuleStatus

        init(code: String, name: String, phone: String, locale: String, expiresAt: Int, channel: String, discount: Double, tags: [String], visitMinutes: Int, status: CleaningRuleStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.locale = locale
            self.expiresAt = expiresAt
            self.channel = channel
            self.discount = discount
            self.tags = tags
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: CleaningRuleStatus) -> Bool {
            switch status {
            case .requested:
                return next == CleaningRuleStatus.expired
            case .granted:
                switch next {
                case .revoked:
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

        func moveTo(_ next: CleaningRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("cleaning rule") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return ((discount - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningRule {
            return CleaningRule(
                code: code,
                name: name,
                phone: phone,
                locale: locale,
                expiresAt: expiresAt,
                channel: channel,
                discount: discount,
                tags: tags,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a cleaning rule in status requested.
    static func newCleaningRule(_ code: String, name: String) -> CleaningRule {
        return CleaningRule(
            code: code,
            name: name,
            phone: "",
            locale: "",
            expiresAt: 0,
            channel: "",
            discount: 0.0,
            tags: [],
            visitMinutes: 0,
            status: CleaningRuleStatus.requested
        )
    }
}
