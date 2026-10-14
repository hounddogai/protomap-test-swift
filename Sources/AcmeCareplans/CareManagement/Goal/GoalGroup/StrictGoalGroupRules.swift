import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict goal group must pass. Check returns its problems, or none.
    protocol StrictGoalGroupRule {
        func check(_ item: StrictGoalGroup) -> [String]
    }

    final class StrictGoalGroupRequiredCodeRule: StrictGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictGoalGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictGoalGroupRequiredNameRule: StrictGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictGoalGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictGoalGroupVisibleGuardRule: StrictGoalGroupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StrictGoalGroup) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class StrictGoalGroupCodePrefixRule: StrictGoalGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictGoalGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictGoalGroupRequiredAllergyRule: StrictGoalGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictGoalGroup) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictGoalGroupScoreRangeRule: StrictGoalGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictGoalGroup) -> [String] {
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

    /// Runs every rule of a strict goal group.
    final class StrictGoalGroupValidator {
        var rules: [any StrictGoalGroupRule]

        init(rules: [any StrictGoalGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictGoalGroup) -> [String] {
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

        func requireValid(_ item: StrictGoalGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictGoalGroup]) -> [String: [String]] {
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

    static func defaultStrictGoalGroupValidator() -> StrictGoalGroupValidator {
        return StrictGoalGroupValidator(
            rules: [
                StrictGoalGroupRequiredCodeRule(message: "strict goal group needs a value"),
                StrictGoalGroupRequiredNameRule(message: "strict goal group needs an entry"),
                StrictGoalGroupVisibleGuardRule(limit: 1.4),
                StrictGoalGroupCodePrefixRule(prefix: "X"),
                StrictGoalGroupRequiredAllergyRule(message: "strict goal group needs an entry"),
                StrictGoalGroupScoreRangeRule(min: 1.2, max: 982.0),
            ]
        )
    }
}
