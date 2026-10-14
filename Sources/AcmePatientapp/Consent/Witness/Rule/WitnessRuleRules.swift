import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness rule must pass. Check returns its problems, or none.
    protocol WitnessRuleRule {
        func check(_ item: WitnessRule) -> [String]
    }

    final class WitnessRuleRetriesRangeRule: WitnessRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessRule) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessRuleCodePrefixRule: WitnessRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessRuleLimitRangeRule: WitnessRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessRule) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessRuleRequiredCodeRule: WitnessRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessRuleCodeLengthRule: WitnessRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessRuleTitleLengthRule: WitnessRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness rule.
    final class WitnessRuleValidator {
        var rules: [any WitnessRuleRule]

        init(rules: [any WitnessRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessRule]) -> [String: [String]] {
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

    static func defaultWitnessRuleValidator() -> WitnessRuleValidator {
        return WitnessRuleValidator(
            rules: [
                WitnessRuleRetriesRangeRule(min: 64, max: 86400),
                WitnessRuleCodePrefixRule(prefix: "ACM"),
                WitnessRuleLimitRangeRule(min: 64, max: 255),
                WitnessRuleRequiredCodeRule(message: "witness rule needs this field"),
                WitnessRuleCodeLengthRule(maxLength: 16),
                WitnessRuleTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
