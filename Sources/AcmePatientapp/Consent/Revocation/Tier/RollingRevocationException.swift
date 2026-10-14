import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling revocation exception is in its life cycle.
    enum RollingRevocationExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling revocation exception. Its code is unique within a tenant.
    final class RollingRevocationException {
        var code: String
        var label: String
        var locale: String
        var windowDays: Int
        var archived: Bool
        var amount: Double
        var score: Double
        var contactEmail: String
        var tags: [String]
        var visible: Bool
        var status: RollingRevocationExceptionStatus

        init(code: String, label: String, locale: String, windowDays: Int, archived: Bool, amount: Double, score: Double, contactEmail: String, tags: [String], visible: Bool, status: RollingRevocationExceptionStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.windowDays = windowDays
            self.archived = archived
            self.amount = amount
            self.score = score
            self.contactEmail = contactEmail
            self.tags = tags
            self.visible = visible
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

        func canMoveTo(_ next: RollingRevocationExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
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

        func moveTo(_ next: RollingRevocationExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling revocation exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((amount - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingRevocationException {
            return RollingRevocationException(
                code: code,
                label: label,
                locale: locale,
                windowDays: windowDays,
                archived: archived,
                amount: amount,
                score: score,
                contactEmail: contactEmail,
                tags: tags,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling revocation exception in status requested.
    static func newRollingRevocationException(_ code: String, label: String) -> RollingRevocationException {
        return RollingRevocationException(
            code: code,
            label: label,
            locale: "",
            windowDays: 0,
            archived: false,
            amount: 0.0,
            score: 0.0,
            contactEmail: "",
            tags: [],
            visible: false,
            status: RollingRevocationExceptionStatus.requested
        )
    }
}
