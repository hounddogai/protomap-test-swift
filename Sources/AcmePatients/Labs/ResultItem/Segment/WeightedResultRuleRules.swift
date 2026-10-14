import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted result rule must pass. Check returns its problems, or none.
    protocol WeightedResultRuleRule {
        func check(_ item: WeightedResultRule) -> [String]
    }

    final class WeightedResultRuleAllowedNameRule: WeightedResultRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedResultRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class WeightedResultRuleCodePrefixRule: WeightedResultRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedResultRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedResultRuleRateRangeRule: WeightedResultRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedResultRule) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedResultRuleTitleLengthRule: WeightedResultRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedResultRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedResultRuleStartsAtRangeRule: WeightedResultRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedResultRule) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedResultRuleRequiredTitleRule: WeightedResultRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedResultRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted result rule.
    final class WeightedResultRuleValidator {
        var rules: [any WeightedResultRuleRule]

        init(rules: [any WeightedResultRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedResultRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedResultRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedResultRule]) -> [String: [String]] {
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

    static func defaultWeightedResultRuleValidator() -> WeightedResultRuleValidator {
        return WeightedResultRuleValidator(
            rules: [
                WeightedResultRuleAllowedNameRule(allowed: ["batched", "lenient", "primary"]),
                WeightedResultRuleCodePrefixRule(prefix: "Q"),
                WeightedResultRuleRateRangeRule(min: 9.5, max: 847.6),
                WeightedResultRuleTitleLengthRule(maxLength: 1000),
                WeightedResultRuleStartsAtRangeRule(min: 16, max: 32),
                WeightedResultRuleRequiredTitleRule(message: "weighted result rule needs a value"),
            ]
        )
    }
}
