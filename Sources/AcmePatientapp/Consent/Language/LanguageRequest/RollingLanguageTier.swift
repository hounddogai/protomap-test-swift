import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling language tier is in its life cycle.
    enum RollingLanguageTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling language tier as the language team keeps it.
    final class RollingLanguageTier {
        var code: String
        var title: String
        var contactEmail: String
        var retries: Int
        var source: String
        var status: RollingLanguageTierStatus

        init(code: String, title: String, contactEmail: String, retries: Int, source: String, status: RollingLanguageTierStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.retries = retries
            self.source = source
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

        func canMoveTo(_ next: RollingLanguageTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RollingLanguageTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling language tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> RollingLanguageTier {
            return RollingLanguageTier(
                code: code,
                title: title,
                contactEmail: contactEmail,
                retries: retries,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling language tier in status open.
    static func newRollingLanguageTier(_ code: String, title: String) -> RollingLanguageTier {
        return RollingLanguageTier(
            code: code,
            title: title,
            contactEmail: "",
            retries: 0,
            source: "",
            status: RollingLanguageTierStatus.`open`
        )
    }
}
