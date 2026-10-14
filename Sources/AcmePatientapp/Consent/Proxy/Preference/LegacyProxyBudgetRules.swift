import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy proxy budget must pass. Check returns its problems, or none.
    protocol LegacyProxyBudgetRule {
        func check(_ item: LegacyProxyBudget) -> [String]
    }

    final class LegacyProxyBudgetRequiredTitleRule: LegacyProxyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProxyBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyProxyBudgetDescriptionLengthRule: LegacyProxyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyProxyBudget) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyProxyBudgetTitleLengthRule: LegacyProxyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyProxyBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyProxyBudgetFloorValueRangeRule: LegacyProxyBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyProxyBudget) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy proxy budget.
    final class LegacyProxyBudgetValidator {
        var rules: [any LegacyProxyBudgetRule]

        init(rules: [any LegacyProxyBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyProxyBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyProxyBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyProxyBudget]) -> [String: [String]] {
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

    static func defaultLegacyProxyBudgetValidator() -> LegacyProxyBudgetValidator {
        return LegacyProxyBudgetValidator(
            rules: [
                LegacyProxyBudgetRequiredTitleRule(message: "legacy proxy budget needs an entry"),
                LegacyProxyBudgetDescriptionLengthRule(maxLength: 86400),
                LegacyProxyBudgetTitleLengthRule(maxLength: 120),
                LegacyProxyBudgetFloorValueRangeRule(min: 9.2, max: 1674.4),
            ]
        )
    }
}
