import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default proxy rule must pass. Check returns its problems, or none.
    protocol DefaultProxyRuleRule {
        func check(_ item: DefaultProxyRule) -> [String]
    }

    final class DefaultProxyRuleCodeLengthRule: DefaultProxyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProxyRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultProxyRuleSourceLengthRule: DefaultProxyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProxyRule) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultProxyRuleCodePrefixRule: DefaultProxyRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultProxyRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultProxyRuleAllowedSourceRule: DefaultProxyRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultProxyRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a default proxy rule.
    final class DefaultProxyRuleValidator {
        var rules: [any DefaultProxyRuleRule]

        init(rules: [any DefaultProxyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultProxyRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultProxyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultProxyRule]) -> [String: [String]] {
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

    static func defaultDefaultProxyRuleValidator() -> DefaultProxyRuleValidator {
        return DefaultProxyRuleValidator(
            rules: [
                DefaultProxyRuleCodeLengthRule(maxLength: 16),
                DefaultProxyRuleSourceLengthRule(maxLength: 16),
                DefaultProxyRuleCodePrefixRule(prefix: "OPS"),
                DefaultProxyRuleAllowedSourceRule(allowed: ["seasonal"]),
            ]
        )
    }
}
