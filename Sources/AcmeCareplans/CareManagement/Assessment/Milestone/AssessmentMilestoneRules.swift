import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment milestone must pass. Check returns its problems, or none.
    protocol AssessmentMilestoneRule {
        func check(_ item: AssessmentMilestone) -> [String]
    }

    final class AssessmentMilestoneCodePrefixRule: AssessmentMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentMilestoneSpecialtyLengthRule: AssessmentMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentMilestone) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentMilestoneMarginRangeRule: AssessmentMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentMilestone) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentMilestoneRequiredDescriptionRule: AssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentMilestone) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentMilestoneAllowedLabelRule: AssessmentMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment milestone.
    final class AssessmentMilestoneValidator {
        var rules: [any AssessmentMilestoneRule]

        init(rules: [any AssessmentMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentMilestone) -> [String] {
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

        func requireValid(_ item: AssessmentMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentMilestone]) -> [String: [String]] {
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

    static func defaultAssessmentMilestoneValidator() -> AssessmentMilestoneValidator {
        return AssessmentMilestoneValidator(
            rules: [
                AssessmentMilestoneCodePrefixRule(prefix: "ACM"),
                AssessmentMilestoneSpecialtyLengthRule(maxLength: 16),
                AssessmentMilestoneMarginRangeRule(min: 5.3, max: 3846.6),
                AssessmentMilestoneRequiredDescriptionRule(message: "assessment milestone needs a value"),
                AssessmentMilestoneAllowedLabelRule(allowed: ["default", "lenient", "batched"]),
            ]
        )
    }
}
