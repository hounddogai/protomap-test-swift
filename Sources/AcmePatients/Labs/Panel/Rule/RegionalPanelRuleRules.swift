import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional panel rule must pass. Check returns its problems, or none.
    protocol RegionalPanelRuleRule {
        func check(_ item: RegionalPanelRule) -> [String]
    }

    final class RegionalPanelRuleCodePrefixRule: RegionalPanelRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalPanelRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalPanelRuleLimitRangeRule: RegionalPanelRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalPanelRule) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalPanelRuleRequiredCodeRule: RegionalPanelRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPanelRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalPanelRuleTitleLengthRule: RegionalPanelRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalPanelRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalPanelRuleRequiredFacilityRule: RegionalPanelRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalPanelRule) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional panel rule.
    final class RegionalPanelRuleValidator {
        var rules: [any RegionalPanelRuleRule]

        init(rules: [any RegionalPanelRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalPanelRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalPanelRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalPanelRule]) -> [String: [String]] {
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

    static func defaultRegionalPanelRuleValidator() -> RegionalPanelRuleValidator {
        return RegionalPanelRuleValidator(
            rules: [
                RegionalPanelRuleCodePrefixRule(prefix: "Q"),
                RegionalPanelRuleLimitRangeRule(min: 16, max: 1000),
                RegionalPanelRuleRequiredCodeRule(message: "regional panel rule needs this field"),
                RegionalPanelRuleTitleLengthRule(maxLength: 16),
                RegionalPanelRuleRequiredFacilityRule(message: "regional panel rule needs this field"),
            ]
        )
    }
}
