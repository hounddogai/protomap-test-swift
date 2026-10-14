import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal adjustment must pass. Check returns its problems, or none.
    protocol GoalAdjustmentRule {
        func check(_ item: GoalAdjustment) -> [String]
    }

    final class GoalAdjustmentRequiredCodeRule: GoalAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalAdjustmentAllowedRegionRule: GoalAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is duplicated"]
            }
            return []
        }
    }

    final class GoalAdjustmentCodeLengthRule: GoalAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalAdjustmentRequiredRegionRule: GoalAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAdjustment) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal adjustment.
    final class GoalAdjustmentValidator {
        var rules: [any GoalAdjustmentRule]

        init(rules: [any GoalAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalAdjustment) -> [String] {
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

        func requireValid(_ item: GoalAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalAdjustment]) -> [String: [String]] {
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

    static func defaultGoalAdjustmentValidator() -> GoalAdjustmentValidator {
        return GoalAdjustmentValidator(
            rules: [
                GoalAdjustmentRequiredCodeRule(message: "goal adjustment needs this field"),
                GoalAdjustmentAllowedRegionRule(allowed: []),
                GoalAdjustmentCodeLengthRule(maxLength: 120),
                GoalAdjustmentRequiredRegionRule(message: "goal adjustment needs a value"),
            ]
        )
    }
}
