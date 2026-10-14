import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy budget must pass. Check returns its problems, or none.
    protocol LenientProxyBudgetRule {
        func check(_ item: LenientProxyBudget) -> [String]
    }

    final class LenientProxyBudgetLabelLengthRule: LenientProxyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxyBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProxyBudgetAllowedLabelRule: LenientProxyBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientProxyBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class LenientProxyBudgetLimitRangeRule: LenientProxyBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyBudget) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientProxyBudgetRequiredTimezoneRule: LenientProxyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyBudget) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient proxy budget.
    final class LenientProxyBudgetValidator {
        var rules: [any LenientProxyBudgetRule]

        init(rules: [any LenientProxyBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxyBudget) -> [String] {
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

        func requireValid(_ item: LenientProxyBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxyBudget]) -> [String: [String]] {
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

    static func defaultLenientProxyBudgetValidator() -> LenientProxyBudgetValidator {
        return LenientProxyBudgetValidator(
            rules: [
                LenientProxyBudgetLabelLengthRule(maxLength: 16),
                LenientProxyBudgetAllowedLabelRule(allowed: ["capped", "rolling"]),
                LenientProxyBudgetLimitRangeRule(min: 64, max: 120),
                LenientProxyBudgetRequiredTimezoneRule(message: "lenient proxy budget needs an entry"),
            ]
        )
    }
}
