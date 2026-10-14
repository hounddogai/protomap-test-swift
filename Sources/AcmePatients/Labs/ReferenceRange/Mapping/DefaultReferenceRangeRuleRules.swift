import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default reference range rule must pass. Check returns its problems, or none.
    protocol DefaultReferenceRangeRuleRule {
        func check(_ item: DefaultReferenceRangeRule) -> [String]
    }

    final class DefaultReferenceRangeRuleTitleLengthRule: DefaultReferenceRangeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferenceRangeRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReferenceRangeRuleRequiredCodeRule: DefaultReferenceRangeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReferenceRangeRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReferenceRangeRuleScoreRangeRule: DefaultReferenceRangeRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReferenceRangeRule) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultReferenceRangeRulePayerLengthRule: DefaultReferenceRangeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferenceRangeRule) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReferenceRangeRuleQuantityRangeRule: DefaultReferenceRangeRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReferenceRangeRule) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default reference range rule.
    final class DefaultReferenceRangeRuleValidator {
        var rules: [any DefaultReferenceRangeRuleRule]

        init(rules: [any DefaultReferenceRangeRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReferenceRangeRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultReferenceRangeRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReferenceRangeRule]) -> [String: [String]] {
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

    static func defaultDefaultReferenceRangeRuleValidator() -> DefaultReferenceRangeRuleValidator {
        return DefaultReferenceRangeRuleValidator(
            rules: [
                DefaultReferenceRangeRuleTitleLengthRule(maxLength: 120),
                DefaultReferenceRangeRuleRequiredCodeRule(message: "default reference range rule needs an entry"),
                DefaultReferenceRangeRuleScoreRangeRule(min: 3.7, max: 254.0),
                DefaultReferenceRangeRulePayerLengthRule(maxLength: 1000),
                DefaultReferenceRangeRuleQuantityRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
