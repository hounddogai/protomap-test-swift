import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional care protocol rule must pass. Check returns its problems, or none.
    protocol RegionalCareProtocolRuleRule {
        func check(_ item: RegionalCareProtocolRule) -> [String]
    }

    final class RegionalCareProtocolRuleRequiredCodeRule: RegionalCareProtocolRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareProtocolRuleLabelLengthRule: RegionalCareProtocolRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolRulePriorityRangeRule: RegionalCareProtocolRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCareProtocolRule) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalCareProtocolRuleCodePrefixRule: RegionalCareProtocolRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalCareProtocolRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolRuleAllowedCodeRule: RegionalCareProtocolRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalCareProtocolRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a regional care protocol rule.
    final class RegionalCareProtocolRuleValidator {
        var rules: [any RegionalCareProtocolRuleRule]

        init(rules: [any RegionalCareProtocolRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareProtocolRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCareProtocolRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareProtocolRule]) -> [String: [String]] {
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

    static func defaultRegionalCareProtocolRuleValidator() -> RegionalCareProtocolRuleValidator {
        return RegionalCareProtocolRuleValidator(
            rules: [
                RegionalCareProtocolRuleRequiredCodeRule(message: "regional care protocol rule needs an entry"),
                RegionalCareProtocolRuleLabelLengthRule(maxLength: 120),
                RegionalCareProtocolRulePriorityRangeRule(min: 3600, max: 86400),
                RegionalCareProtocolRuleCodePrefixRule(prefix: "OPS"),
                RegionalCareProtocolRuleAllowedCodeRule(allowed: []),
            ]
        )
    }
}
