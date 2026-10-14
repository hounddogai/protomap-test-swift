import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global assessment rule must pass. Check returns its problems, or none.
    protocol GlobalAssessmentRuleRule {
        func check(_ item: GlobalAssessmentRule) -> [String]
    }

    final class GlobalAssessmentRuleSequenceRangeRule: GlobalAssessmentRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAssessmentRule) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalAssessmentRuleRequiredCodeRule: GlobalAssessmentRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAssessmentRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAssessmentRuleDiscountRangeRule: GlobalAssessmentRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAssessmentRule) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global assessment rule.
    final class GlobalAssessmentRuleValidator {
        var rules: [any GlobalAssessmentRuleRule]

        init(rules: [any GlobalAssessmentRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAssessmentRule) -> [String] {
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

        func requireValid(_ item: GlobalAssessmentRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAssessmentRule]) -> [String: [String]] {
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

    static func defaultGlobalAssessmentRuleValidator() -> GlobalAssessmentRuleValidator {
        return GlobalAssessmentRuleValidator(
            rules: [
                GlobalAssessmentRuleSequenceRangeRule(min: 64, max: 64),
                GlobalAssessmentRuleRequiredCodeRule(message: "global assessment rule needs a value"),
                GlobalAssessmentRuleDiscountRangeRule(min: 8.0, max: 1564.8),
            ]
        )
    }
}
