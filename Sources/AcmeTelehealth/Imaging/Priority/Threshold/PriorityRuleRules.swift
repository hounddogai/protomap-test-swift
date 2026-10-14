import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority rule must pass. Check returns its problems, or none.
    protocol PriorityRuleRule {
        func check(_ item: PriorityRule) -> [String]
    }

    final class PriorityRuleCodeLengthRule: PriorityRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityRulePriorityRangeRule: PriorityRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityRule) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityRuleGraceDaysRangeRule: PriorityRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityRule) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority rule.
    final class PriorityRuleValidator {
        var rules: [any PriorityRuleRule]

        init(rules: [any PriorityRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityRule]) -> [String: [String]] {
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

    static func defaultPriorityRuleValidator() -> PriorityRuleValidator {
        return PriorityRuleValidator(
            rules: [
                PriorityRuleCodeLengthRule(maxLength: 32),
                PriorityRulePriorityRangeRule(min: 32, max: 1000),
                PriorityRuleGraceDaysRangeRule(min: 64, max: 120),
            ]
        )
    }
}
