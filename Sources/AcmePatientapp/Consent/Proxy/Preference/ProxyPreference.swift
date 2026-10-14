import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy preference is in its life cycle.
    enum ProxyPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One proxy preference, with what the planners need to act on it.
    final class ProxyPreference {
        var code: String
        var title: String
        var description: String
        var currency: String
        var ceiling: Double
        var tags: [String]
        var name: String
        var status: ProxyPreferenceStatus

        init(code: String, title: String, description: String, currency: String, ceiling: Double, tags: [String], name: String, status: ProxyPreferenceStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.currency = currency
            self.ceiling = ceiling
            self.tags = tags
            self.name = name
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

        func canMoveTo(_ next: ProxyPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProxyPreferenceStatus.reopened || next == ProxyPreferenceStatus.archived
            case .inReview:
                switch next {
                case .resolved, .reopened:
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

        func moveTo(_ next: ProxyPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> ProxyPreference {
            return ProxyPreference(
                code: code,
                title: title,
                description: description,
                currency: currency,
                ceiling: ceiling,
                tags: tags,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy preference in status open.
    static func newProxyPreference(_ code: String, title: String) -> ProxyPreference {
        return ProxyPreference(
            code: code,
            title: title,
            description: "",
            currency: "",
            ceiling: 0.0,
            tags: [],
            name: "",
            status: ProxyPreferenceStatus.`open`
        )
    }
}
