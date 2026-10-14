import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default skill mix score must pass. Check returns its problems, or none.
    protocol DefaultSkillMixScoreRule {
        func check(_ item: DefaultSkillMixScore) -> [String]
    }

    final class DefaultSkillMixScoreDiscountRangeRule: DefaultSkillMixScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSkillMixScore) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultSkillMixScoreRequiredEncounterIDRule: DefaultSkillMixScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSkillMixScore) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSkillMixScoreCopayRangeRule: DefaultSkillMixScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSkillMixScore) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultSkillMixScoreAttemptsRangeRule: DefaultSkillMixScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSkillMixScore) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default skill mix score.
    final class DefaultSkillMixScoreValidator {
        var rules: [any DefaultSkillMixScoreRule]

        init(rules: [any DefaultSkillMixScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSkillMixScore) -> [String] {
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

        func requireValid(_ item: DefaultSkillMixScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSkillMixScore]) -> [String: [String]] {
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

    static func defaultDefaultSkillMixScoreValidator() -> DefaultSkillMixScoreValidator {
        return DefaultSkillMixScoreValidator(
            rules: [
                DefaultSkillMixScoreDiscountRangeRule(min: 9.2, max: 4918.9),
                DefaultSkillMixScoreRequiredEncounterIDRule(message: "default skill mix score needs a value"),
                DefaultSkillMixScoreCopayRangeRule(min: 5.6, max: 2434.9),
                DefaultSkillMixScoreAttemptsRangeRule(min: 64, max: 120),
            ]
        )
    }
}
