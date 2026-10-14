import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional charge rule must pass. Check returns its problems, or none.
    protocol RegionalChargeRuleRule {
        func check(_ item: RegionalChargeRule) -> [String]
    }

    final class RegionalChargeRuleTitleLengthRule: RegionalChargeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalChargeRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalChargeRuleCategoryLengthRule: RegionalChargeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalChargeRule) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalChargeRuleRequiredCodeRule: RegionalChargeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalChargeRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalChargeRuleCodePrefixRule: RegionalChargeRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalChargeRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional charge rule.
    final class RegionalChargeRuleValidator {
        var rules: [any RegionalChargeRuleRule]

        init(rules: [any RegionalChargeRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalChargeRule) -> [String] {
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

        func requireValid(_ item: RegionalChargeRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalChargeRule]) -> [String: [String]] {
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

    static func defaultRegionalChargeRuleValidator() -> RegionalChargeRuleValidator {
        return RegionalChargeRuleValidator(
            rules: [
                RegionalChargeRuleTitleLengthRule(maxLength: 86400),
                RegionalChargeRuleCategoryLengthRule(maxLength: 64),
                RegionalChargeRuleRequiredCodeRule(message: "regional charge rule needs a value"),
                RegionalChargeRuleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
