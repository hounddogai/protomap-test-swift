import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall budget must pass. Check returns its problems, or none.
    protocol RecallBudgetRule {
        func check(_ item: RecallBudget) -> [String]
    }

    final class RecallBudgetFloorValueRangeRule: RecallBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallBudget) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallBudgetCodeLengthRule: RecallBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallBudgetAllowedCodeRule: RecallBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class RecallBudgetExpiresAtRangeRule: RecallBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallBudget) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallBudgetNameLengthRule: RecallBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallBudgetRequiredLabelRule: RecallBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall budget.
    final class RecallBudgetValidator {
        var rules: [any RecallBudgetRule]

        init(rules: [any RecallBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallBudget) -> [String] {
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

        func requireValid(_ item: RecallBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallBudget]) -> [String: [String]] {
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

    static func defaultRecallBudgetValidator() -> RecallBudgetValidator {
        return RecallBudgetValidator(
            rules: [
                RecallBudgetFloorValueRangeRule(min: 4.1, max: 3700.5),
                RecallBudgetCodeLengthRule(maxLength: 32),
                RecallBudgetAllowedCodeRule(allowed: ["batched", "tiered"]),
                RecallBudgetExpiresAtRangeRule(min: 32, max: 80),
                RecallBudgetNameLengthRule(maxLength: 64),
                RecallBudgetRequiredLabelRule(message: "recall budget needs this field"),
            ]
        )
    }
}
