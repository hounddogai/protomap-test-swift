import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction rule must pass. Check returns its problems, or none.
    protocol InteractionRuleRule {
        func check(_ item: InteractionRule) -> [String]
    }

    final class InteractionRuleWindowDaysRangeRule: InteractionRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionRule) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionRuleCodeLengthRule: InteractionRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionRuleFacilityLengthRule: InteractionRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionRule) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionRuleCodePrefixRule: InteractionRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction rule.
    final class InteractionRuleValidator {
        var rules: [any InteractionRuleRule]

        init(rules: [any InteractionRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionRule) -> [String] {
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

        func requireValid(_ item: InteractionRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionRule]) -> [String: [String]] {
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

    static func defaultInteractionRuleValidator() -> InteractionRuleValidator {
        return InteractionRuleValidator(
            rules: [
                InteractionRuleWindowDaysRangeRule(min: 80, max: 80),
                InteractionRuleCodeLengthRule(maxLength: 255),
                InteractionRuleFacilityLengthRule(maxLength: 3600),
                InteractionRuleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
