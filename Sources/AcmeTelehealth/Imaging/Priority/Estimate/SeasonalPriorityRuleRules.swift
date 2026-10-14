import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal priority rule must pass. Check returns its problems, or none.
    protocol SeasonalPriorityRuleRule {
        func check(_ item: SeasonalPriorityRule) -> [String]
    }

    final class SeasonalPriorityRuleMaximumRangeRule: SeasonalPriorityRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalPriorityRule) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalPriorityRuleGraceDaysRangeRule: SeasonalPriorityRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalPriorityRule) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalPriorityRuleLabelLengthRule: SeasonalPriorityRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPriorityRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal priority rule.
    final class SeasonalPriorityRuleValidator {
        var rules: [any SeasonalPriorityRuleRule]

        init(rules: [any SeasonalPriorityRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalPriorityRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalPriorityRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalPriorityRule]) -> [String: [String]] {
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

    static func defaultSeasonalPriorityRuleValidator() -> SeasonalPriorityRuleValidator {
        return SeasonalPriorityRuleValidator(
            rules: [
                SeasonalPriorityRuleMaximumRangeRule(min: 3.0, max: 1223.7),
                SeasonalPriorityRuleGraceDaysRangeRule(min: 64, max: 86400),
                SeasonalPriorityRuleLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
