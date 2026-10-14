import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority tier must pass. Check returns its problems, or none.
    protocol PriorityTierRule {
        func check(_ item: PriorityTier) -> [String]
    }

    final class PriorityTierRequiredCodeRule: PriorityTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityTierCategoryLengthRule: PriorityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityTier) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityTierAcuityRangeRule: PriorityTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityTier) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityTierCodeLengthRule: PriorityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority tier.
    final class PriorityTierValidator {
        var rules: [any PriorityTierRule]

        init(rules: [any PriorityTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityTier) -> [String] {
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

        func requireValid(_ item: PriorityTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityTier]) -> [String: [String]] {
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

    static func defaultPriorityTierValidator() -> PriorityTierValidator {
        return PriorityTierValidator(
            rules: [
                PriorityTierRequiredCodeRule(message: "priority tier needs this field"),
                PriorityTierCategoryLengthRule(maxLength: 64),
                PriorityTierAcuityRangeRule(min: 255, max: 3600),
                PriorityTierCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
