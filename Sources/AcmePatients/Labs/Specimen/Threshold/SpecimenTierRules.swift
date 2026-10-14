import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen tier must pass. Check returns its problems, or none.
    protocol SpecimenTierRule {
        func check(_ item: SpecimenTier) -> [String]
    }

    final class SpecimenTierArchivedGuardRule: SpecimenTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SpecimenTier) -> [String] {
            if item.archived && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SpecimenTierLabelLengthRule: SpecimenTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenTierBudgetRangeRule: SpecimenTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenTier) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenTierRequiredChannelRule: SpecimenTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenTier) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenTierCategoryLengthRule: SpecimenTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenTier) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen tier.
    final class SpecimenTierValidator {
        var rules: [any SpecimenTierRule]

        init(rules: [any SpecimenTierRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenTier]) -> [String: [String]] {
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

    static func defaultSpecimenTierValidator() -> SpecimenTierValidator {
        return SpecimenTierValidator(
            rules: [
                SpecimenTierArchivedGuardRule(limit: 64),
                SpecimenTierLabelLengthRule(maxLength: 86400),
                SpecimenTierBudgetRangeRule(min: 9.0, max: 3147.3),
                SpecimenTierRequiredChannelRule(message: "specimen tier needs this field"),
                SpecimenTierCategoryLengthRule(maxLength: 16),
            ]
        )
    }
}
