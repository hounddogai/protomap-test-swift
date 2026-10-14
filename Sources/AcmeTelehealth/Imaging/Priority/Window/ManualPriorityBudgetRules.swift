import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual priority budget must pass. Check returns its problems, or none.
    protocol ManualPriorityBudgetRule {
        func check(_ item: ManualPriorityBudget) -> [String]
    }

    final class ManualPriorityBudgetAllowedRegionRule: ManualPriorityBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualPriorityBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is too long"]
            }
            return []
        }
    }

    final class ManualPriorityBudgetRequiredCodeRule: ManualPriorityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualPriorityBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualPriorityBudgetVisitMinutesRangeRule: ManualPriorityBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualPriorityBudget) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualPriorityBudgetTitleLengthRule: ManualPriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualPriorityBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualPriorityBudgetReviewerLengthRule: ManualPriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualPriorityBudget) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualPriorityBudgetRegionLengthRule: ManualPriorityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualPriorityBudget) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual priority budget.
    final class ManualPriorityBudgetValidator {
        var rules: [any ManualPriorityBudgetRule]

        init(rules: [any ManualPriorityBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualPriorityBudget) -> [String] {
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

        func requireValid(_ item: ManualPriorityBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualPriorityBudget]) -> [String: [String]] {
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

    static func defaultManualPriorityBudgetValidator() -> ManualPriorityBudgetValidator {
        return ManualPriorityBudgetValidator(
            rules: [
                ManualPriorityBudgetAllowedRegionRule(allowed: ["legacy", "rolling", "manual"]),
                ManualPriorityBudgetRequiredCodeRule(message: "manual priority budget needs this field"),
                ManualPriorityBudgetVisitMinutesRangeRule(min: 255, max: 3600),
                ManualPriorityBudgetTitleLengthRule(maxLength: 3600),
                ManualPriorityBudgetReviewerLengthRule(maxLength: 16),
                ManualPriorityBudgetRegionLengthRule(maxLength: 1000),
            ]
        )
    }
}
