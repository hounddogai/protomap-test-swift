import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary program budget must pass. Check returns its problems, or none.
    protocol PrimaryProgramBudgetRule {
        func check(_ item: PrimaryProgramBudget) -> [String]
    }

    final class PrimaryProgramBudgetCodeLengthRule: PrimaryProgramBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryProgramBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryProgramBudgetPayerLengthRule: PrimaryProgramBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryProgramBudget) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryProgramBudgetWindowDaysRangeRule: PrimaryProgramBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryProgramBudget) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryProgramBudgetCodePrefixRule: PrimaryProgramBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryProgramBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryProgramBudgetAllowedCodeRule: PrimaryProgramBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryProgramBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class PrimaryProgramBudgetCeilingRangeRule: PrimaryProgramBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryProgramBudget) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary program budget.
    final class PrimaryProgramBudgetValidator {
        var rules: [any PrimaryProgramBudgetRule]

        init(rules: [any PrimaryProgramBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryProgramBudget) -> [String] {
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

        func requireValid(_ item: PrimaryProgramBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryProgramBudget]) -> [String: [String]] {
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

    static func defaultPrimaryProgramBudgetValidator() -> PrimaryProgramBudgetValidator {
        return PrimaryProgramBudgetValidator(
            rules: [
                PrimaryProgramBudgetCodeLengthRule(maxLength: 32),
                PrimaryProgramBudgetPayerLengthRule(maxLength: 80),
                PrimaryProgramBudgetWindowDaysRangeRule(min: 16, max: 120),
                PrimaryProgramBudgetCodePrefixRule(prefix: "ACM"),
                PrimaryProgramBudgetAllowedCodeRule(allowed: ["default", "default"]),
                PrimaryProgramBudgetCeilingRangeRule(min: 1.6, max: 1952.9),
            ]
        )
    }
}
