import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy policy must pass. Check returns its problems, or none.
    protocol ProxyPolicyRule {
        func check(_ item: ProxyPolicy) -> [String]
    }

    final class ProxyPolicyRequiredLabelRule: ProxyPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyPolicyCodePrefixRule: ProxyPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyPolicyLocaleLengthRule: ProxyPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyPolicy) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyPolicyCodeLengthRule: ProxyPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyPolicySequenceRangeRule: ProxyPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyPolicy) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyPolicyVisibleGuardRule: ProxyPolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyPolicy) -> [String] {
            if item.visible && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy policy.
    final class ProxyPolicyValidator {
        var rules: [any ProxyPolicyRule]

        init(rules: [any ProxyPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyPolicy]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultProxyPolicyValidator() -> ProxyPolicyValidator {
        return ProxyPolicyValidator(
            rules: [
                ProxyPolicyRequiredLabelRule(message: "proxy policy needs a value"),
                ProxyPolicyCodePrefixRule(prefix: "Q"),
                ProxyPolicyLocaleLengthRule(maxLength: 64),
                ProxyPolicyCodeLengthRule(maxLength: 80),
                ProxyPolicySequenceRangeRule(min: 80, max: 86400),
                ProxyPolicyVisibleGuardRule(limit: 0.9),
            ]
        )
    }
}
