import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal bundle must pass. Check returns its problems, or none.
    protocol GoalBundleRule {
        func check(_ item: GoalBundle) -> [String]
    }

    final class GoalBundleRequiredCodeRule: GoalBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalBundleEndsAtRangeRule: GoalBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalBundle) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GoalBundleCodePrefixRule: GoalBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalBundleRequiredProcedureCodeRule: GoalBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalBundle) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalBundleCodeLengthRule: GoalBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalBundleRequiredRegionRule: GoalBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalBundle) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal bundle.
    final class GoalBundleValidator {
        var rules: [any GoalBundleRule]

        init(rules: [any GoalBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalBundle) -> [String] {
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

        func requireValid(_ item: GoalBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalBundle]) -> [String: [String]] {
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

    static func defaultGoalBundleValidator() -> GoalBundleValidator {
        return GoalBundleValidator(
            rules: [
                GoalBundleRequiredCodeRule(message: "goal bundle needs a value"),
                GoalBundleEndsAtRangeRule(min: 64, max: 80),
                GoalBundleCodePrefixRule(prefix: "REF"),
                GoalBundleRequiredProcedureCodeRule(message: "goal bundle needs an entry"),
                GoalBundleCodeLengthRule(maxLength: 64),
                GoalBundleRequiredRegionRule(message: "goal bundle needs a value"),
            ]
        )
    }
}
