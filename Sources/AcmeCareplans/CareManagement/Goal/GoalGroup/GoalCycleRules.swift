import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal cycle must pass. Check returns its problems, or none.
    protocol GoalCycleRule {
        func check(_ item: GoalCycle) -> [String]
    }

    final class GoalCycleCodeLengthRule: GoalCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalCycleExternalRefLengthRule: GoalCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalCycle) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalCycleNameLengthRule: GoalCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalCycleRequiredCodeRule: GoalCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalCycleRatioRangeRule: GoalCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalCycle) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalCycleCodePrefixRule: GoalCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal cycle.
    final class GoalCycleValidator {
        var rules: [any GoalCycleRule]

        init(rules: [any GoalCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalCycle]) -> [String: [String]] {
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

    static func defaultGoalCycleValidator() -> GoalCycleValidator {
        return GoalCycleValidator(
            rules: [
                GoalCycleCodeLengthRule(maxLength: 120),
                GoalCycleExternalRefLengthRule(maxLength: 3600),
                GoalCycleNameLengthRule(maxLength: 255),
                GoalCycleRequiredCodeRule(message: "goal cycle needs a value"),
                GoalCycleRatioRangeRule(min: 4.5, max: 4079.7),
                GoalCycleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
