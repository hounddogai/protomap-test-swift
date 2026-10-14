import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment plan must pass. Check returns its problems, or none.
    protocol AssessmentPlanRule {
        func check(_ item: AssessmentPlan) -> [String]
    }

    final class AssessmentPlanScoreRangeRule: AssessmentPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentPlan) -> [String] {
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

    final class AssessmentPlanAllowedCodeRule: AssessmentPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class AssessmentPlanRequiredCodeRule: AssessmentPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentPlanCodeLengthRule: AssessmentPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentPlanCodePrefixRule: AssessmentPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentPlanTitleLengthRule: AssessmentPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment plan.
    final class AssessmentPlanValidator {
        var rules: [any AssessmentPlanRule]

        init(rules: [any AssessmentPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentPlan]) -> [String: [String]] {
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

    static func defaultAssessmentPlanValidator() -> AssessmentPlanValidator {
        return AssessmentPlanValidator(
            rules: [
                AssessmentPlanScoreRangeRule(min: 1.5, max: 3548.1),
                AssessmentPlanAllowedCodeRule(allowed: []),
                AssessmentPlanRequiredCodeRule(message: "assessment plan needs this field"),
                AssessmentPlanCodeLengthRule(maxLength: 64),
                AssessmentPlanCodePrefixRule(prefix: "Q"),
                AssessmentPlanTitleLengthRule(maxLength: 3600),
            ]
        )
    }
}
