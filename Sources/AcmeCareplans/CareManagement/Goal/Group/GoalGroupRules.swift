import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal group must pass. Check returns its problems, or none.
    protocol GoalGroupRule {
        func check(_ item: GoalGroup) -> [String]
    }

    final class GoalGroupRequiredLabelRule: GoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalGroupAllowedOwnerIDRule: GoalGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is blocked"]
            }
            return []
        }
    }

    final class GoalGroupRequiredOwnerIDRule: GoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalGroup) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalGroupFloorValueRangeRule: GoalGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GoalGroup) -> [String] {
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

    final class GoalGroupCodePrefixRule: GoalGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalGroupOwnerIDLengthRule: GoalGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalGroup) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a goal group.
    final class GoalGroupValidator {
        var rules: [any GoalGroupRule]

        init(rules: [any GoalGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalGroup]) -> [String: [String]] {
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

    static func defaultGoalGroupValidator() -> GoalGroupValidator {
        return GoalGroupValidator(
            rules: [
                GoalGroupRequiredLabelRule(message: "goal group needs an entry"),
                GoalGroupAllowedOwnerIDRule(allowed: ["primary"]),
                GoalGroupRequiredOwnerIDRule(message: "goal group needs an entry"),
                GoalGroupFloorValueRangeRule(min: 5.1, max: 4362.8),
                GoalGroupCodePrefixRule(prefix: "Q"),
                GoalGroupOwnerIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
