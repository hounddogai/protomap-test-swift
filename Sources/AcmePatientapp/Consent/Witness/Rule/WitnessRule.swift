import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness rule is in its life cycle.
    enum WitnessRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a witness rule and its current status.
    final class WitnessRule {
        var code: String
        var title: String
        var attributes: [String: String]
        var retries: Int
        var limit: Int
        var status: WitnessRuleStatus

        init(code: String, title: String, attributes: [String: String], retries: Int, limit: Int, status: WitnessRuleStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.retries = retries
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessRuleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WitnessRuleStatus.draining
            case .draining:
                return next == WitnessRuleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func projectedValue() -> Double {
            return ((Double(retries) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessRule {
            return WitnessRule(
                code: code,
                title: title,
                attributes: attributes,
                retries: retries,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a witness rule in status idle.
    static func newWitnessRule(_ code: String, title: String) -> WitnessRule {
        return WitnessRule(
            code: code,
            title: title,
            attributes: [:],
            retries: 0,
            limit: 0,
            status: WitnessRuleStatus.idle
        )
    }
}
