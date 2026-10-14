import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense budget must pass. Check returns its problems, or none.
    protocol DispenseBudgetRule {
        func check(_ item: DispenseBudget) -> [String]
    }

    final class DispenseBudgetAllowedCodeRule: DispenseBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class DispenseBudgetCodeLengthRule: DispenseBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseBudgetNotesLengthRule: DispenseBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseBudget) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseBudgetBatchSizeRangeRule: DispenseBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseBudget) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseBudgetGraceDaysRangeRule: DispenseBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseBudget) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense budget.
    final class DispenseBudgetValidator {
        var rules: [any DispenseBudgetRule]

        init(rules: [any DispenseBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseBudget]) -> [String: [String]] {
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

    static func defaultDispenseBudgetValidator() -> DispenseBudgetValidator {
        return DispenseBudgetValidator(
            rules: [
                DispenseBudgetAllowedCodeRule(allowed: ["default"]),
                DispenseBudgetCodeLengthRule(maxLength: 255),
                DispenseBudgetNotesLengthRule(maxLength: 120),
                DispenseBudgetBatchSizeRangeRule(min: 64, max: 80),
                DispenseBudgetGraceDaysRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
