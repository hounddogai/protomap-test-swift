import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement rollup must pass. Check returns its problems, or none.
    protocol StatementRollupRule {
        func check(_ item: StatementRollup) -> [String]
    }

    final class StatementRollupPriorityRangeRule: StatementRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementRollup) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementRollupRequiredTitleRule: StatementRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementRollupRequiredCodeRule: StatementRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementRollupRefillsRangeRule: StatementRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementRollup) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement rollup.
    final class StatementRollupValidator {
        var rules: [any StatementRollupRule]

        init(rules: [any StatementRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementRollup]) -> [String: [String]] {
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

    static func defaultStatementRollupValidator() -> StatementRollupValidator {
        return StatementRollupValidator(
            rules: [
                StatementRollupPriorityRangeRule(min: 1000, max: 86400),
                StatementRollupRequiredTitleRule(message: "statement rollup needs a value"),
                StatementRollupRequiredCodeRule(message: "statement rollup needs a value"),
                StatementRollupRefillsRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
