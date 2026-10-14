import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global closure rule is in its life cycle.
    enum GlobalClosureRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global closure rule as the closure team keeps it.
    final class GlobalClosureRule {
        var code: String
        var name: String
        var attributes: [String: String]
        var description: String
        var version: Int
        var priority: Int
        var status: GlobalClosureRuleStatus

        init(code: String, name: String, attributes: [String: String], description: String, version: Int, priority: Int, status: GlobalClosureRuleStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.description = description
            self.version = version
            self.priority = priority
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

        func canMoveTo(_ next: GlobalClosureRuleStatus) -> Bool {
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
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: GlobalClosureRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global closure rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func effectiveVolume() -> Double {
            return (Double(version) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> GlobalClosureRule {
            return GlobalClosureRule(
                code: code,
                name: name,
                attributes: attributes,
                description: description,
                version: version,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global closure rule in status open.
    static func newGlobalClosureRule(_ code: String, name: String) -> GlobalClosureRule {
        return GlobalClosureRule(
            code: code,
            name: name,
            attributes: [:],
            description: "",
            version: 0,
            priority: 0,
            status: GlobalClosureRuleStatus.`open`
        )
    }
}
