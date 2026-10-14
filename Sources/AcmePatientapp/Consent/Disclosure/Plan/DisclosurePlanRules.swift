import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure plan must pass. Check returns its problems, or none.
    protocol DisclosurePlanRule {
        func check(_ item: DisclosurePlan) -> [String]
    }

    final class DisclosurePlanTitleLengthRule: DisclosurePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosurePlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosurePlanLocaleLengthRule: DisclosurePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosurePlan) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosurePlanRequiredLocaleRule: DisclosurePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosurePlan) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosurePlanCurrencyLengthRule: DisclosurePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosurePlan) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosurePlanUpdatedAtRangeRule: DisclosurePlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosurePlan) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosurePlanCostRangeRule: DisclosurePlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosurePlan) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a disclosure plan.
    final class DisclosurePlanValidator {
        var rules: [any DisclosurePlanRule]

        init(rules: [any DisclosurePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosurePlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosurePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosurePlan]) -> [String: [String]] {
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

    static func defaultDisclosurePlanValidator() -> DisclosurePlanValidator {
        return DisclosurePlanValidator(
            rules: [
                DisclosurePlanTitleLengthRule(maxLength: 120),
                DisclosurePlanLocaleLengthRule(maxLength: 3600),
                DisclosurePlanRequiredLocaleRule(message: "disclosure plan needs this field"),
                DisclosurePlanCurrencyLengthRule(maxLength: 80),
                DisclosurePlanUpdatedAtRangeRule(min: 64, max: 255),
                DisclosurePlanCostRangeRule(min: 9.5, max: 2046.0),
            ]
        )
    }
}
