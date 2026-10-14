import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary slot budget must pass. Check returns its problems, or none.
    protocol PrimarySlotBudgetRule {
        func check(_ item: PrimarySlotBudget) -> [String]
    }

    final class PrimarySlotBudgetVisibleGuardRule: PrimarySlotBudgetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimarySlotBudget) -> [String] {
            if item.visible && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PrimarySlotBudgetLabelLengthRule: PrimarySlotBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySlotBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySlotBudgetAttemptsRangeRule: PrimarySlotBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySlotBudget) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimarySlotBudgetScoreRangeRule: PrimarySlotBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySlotBudget) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary slot budget.
    final class PrimarySlotBudgetValidator {
        var rules: [any PrimarySlotBudgetRule]

        init(rules: [any PrimarySlotBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySlotBudget) -> [String] {
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

        func requireValid(_ item: PrimarySlotBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySlotBudget]) -> [String: [String]] {
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

    static func defaultPrimarySlotBudgetValidator() -> PrimarySlotBudgetValidator {
        return PrimarySlotBudgetValidator(
            rules: [
                PrimarySlotBudgetVisibleGuardRule(limit: 1.4),
                PrimarySlotBudgetLabelLengthRule(maxLength: 86400),
                PrimarySlotBudgetAttemptsRangeRule(min: 16, max: 255),
                PrimarySlotBudgetScoreRangeRule(min: 0.2, max: 2718.6),
            ]
        )
    }
}
