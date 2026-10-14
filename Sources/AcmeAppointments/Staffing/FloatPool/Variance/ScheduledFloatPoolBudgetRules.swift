import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled float pool budget must pass. Check returns its problems, or none.
    protocol ScheduledFloatPoolBudgetRule {
        func check(_ item: ScheduledFloatPoolBudget) -> [String]
    }

    final class ScheduledFloatPoolBudgetTitleLengthRule: ScheduledFloatPoolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolBudgetRequiredRegionRule: ScheduledFloatPoolBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFloatPoolBudget) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFloatPoolBudgetCodeLengthRule: ScheduledFloatPoolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolBudgetAllowedCategoryRule: ScheduledFloatPoolBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledFloatPoolBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is stale"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolBudgetCodePrefixRule: ScheduledFloatPoolBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledFloatPoolBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolBudgetCategoryLengthRule: ScheduledFloatPoolBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolBudget) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled float pool budget.
    final class ScheduledFloatPoolBudgetValidator {
        var rules: [any ScheduledFloatPoolBudgetRule]

        init(rules: [any ScheduledFloatPoolBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFloatPoolBudget) -> [String] {
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

        func requireValid(_ item: ScheduledFloatPoolBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFloatPoolBudget]) -> [String: [String]] {
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

    static func defaultScheduledFloatPoolBudgetValidator() -> ScheduledFloatPoolBudgetValidator {
        return ScheduledFloatPoolBudgetValidator(
            rules: [
                ScheduledFloatPoolBudgetTitleLengthRule(maxLength: 80),
                ScheduledFloatPoolBudgetRequiredRegionRule(message: "scheduled float pool budget needs this field"),
                ScheduledFloatPoolBudgetCodeLengthRule(maxLength: 3600),
                ScheduledFloatPoolBudgetAllowedCategoryRule(allowed: ["global"]),
                ScheduledFloatPoolBudgetCodePrefixRule(prefix: "ACM"),
                ScheduledFloatPoolBudgetCategoryLengthRule(maxLength: 86400),
            ]
        )
    }
}
