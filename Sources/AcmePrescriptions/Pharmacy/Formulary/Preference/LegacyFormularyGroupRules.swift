import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy formulary group must pass. Check returns its problems, or none.
    protocol LegacyFormularyGroupRule {
        func check(_ item: LegacyFormularyGroup) -> [String]
    }

    final class LegacyFormularyGroupAttemptsRangeRule: LegacyFormularyGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyFormularyGroup) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyFormularyGroupPriorityRangeRule: LegacyFormularyGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyFormularyGroup) -> [String] {
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

    final class LegacyFormularyGroupRequiredCodeRule: LegacyFormularyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFormularyGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy formulary group.
    final class LegacyFormularyGroupValidator {
        var rules: [any LegacyFormularyGroupRule]

        init(rules: [any LegacyFormularyGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFormularyGroup) -> [String] {
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

        func requireValid(_ item: LegacyFormularyGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFormularyGroup]) -> [String: [String]] {
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

    static func defaultLegacyFormularyGroupValidator() -> LegacyFormularyGroupValidator {
        return LegacyFormularyGroupValidator(
            rules: [
                LegacyFormularyGroupAttemptsRangeRule(min: 32, max: 120),
                LegacyFormularyGroupPriorityRangeRule(min: 32, max: 120),
                LegacyFormularyGroupRequiredCodeRule(message: "legacy formulary group needs a value"),
            ]
        )
    }
}
