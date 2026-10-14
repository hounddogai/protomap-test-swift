import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding override must pass. Check returns its problems, or none.
    protocol RoundingOverrideRule {
        func check(_ item: RoundingOverride) -> [String]
    }

    final class RoundingOverrideRequiredCategoryRule: RoundingOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingOverride) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingOverrideEndsAtRangeRule: RoundingOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingOverride) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingOverrideCategoryLengthRule: RoundingOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingOverride) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding override.
    final class RoundingOverrideValidator {
        var rules: [any RoundingOverrideRule]

        init(rules: [any RoundingOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingOverride) -> [String] {
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

        func requireValid(_ item: RoundingOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingOverride]) -> [String: [String]] {
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

    static func defaultRoundingOverrideValidator() -> RoundingOverrideValidator {
        return RoundingOverrideValidator(
            rules: [
                RoundingOverrideRequiredCategoryRule(message: "rounding override needs an entry"),
                RoundingOverrideEndsAtRangeRule(min: 120, max: 1000),
                RoundingOverrideCategoryLengthRule(maxLength: 86400),
            ]
        )
    }
}
