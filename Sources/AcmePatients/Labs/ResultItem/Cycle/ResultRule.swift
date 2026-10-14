import AcmePlatform
import Foundation

extension Labs {
    /// Where a result rule is in its life cycle.
    enum ResultRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One result rule, with what the planners need to act on it.
    final class ResultRule {
        var code: String
        var label: String
        var locale: String
        var title: String
        var attributes: [String: String]
        var payer: String
        var acuity: Int
        var status: ResultRuleStatus

        init(code: String, label: String, locale: String, title: String, attributes: [String: String], payer: String, acuity: Int, status: ResultRuleStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.title = title
            self.attributes = attributes
            self.payer = payer
            self.acuity = acuity
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

        func canMoveTo(_ next: ResultRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ResultRuleStatus.reopened || next == ResultRuleStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ResultRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> ResultRule {
            return ResultRule(
                code: code,
                label: label,
                locale: locale,
                title: title,
                attributes: attributes,
                payer: payer,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a result rule in status open.
    static func newResultRule(_ code: String, label: String) -> ResultRule {
        return ResultRule(
            code: code,
            label: label,
            locale: "",
            title: "",
            attributes: [:],
            payer: "",
            acuity: 0,
            status: ResultRuleStatus.`open`
        )
    }
}
