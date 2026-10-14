import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global assessment milestone must pass. Check returns its problems, or none.
    protocol GlobalAssessmentMilestoneRule {
        func check(_ item: GlobalAssessmentMilestone) -> [String]
    }

    final class GlobalAssessmentMilestoneRequiredTitleRule: GlobalAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAssessmentMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAssessmentMilestoneVersionRangeRule: GlobalAssessmentMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAssessmentMilestone) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalAssessmentMilestoneAllowedCodeRule: GlobalAssessmentMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalAssessmentMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class GlobalAssessmentMilestoneExternalRefLengthRule: GlobalAssessmentMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAssessmentMilestone) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAssessmentMilestoneRequiredExternalRefRule: GlobalAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAssessmentMilestone) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global assessment milestone.
    final class GlobalAssessmentMilestoneValidator {
        var rules: [any GlobalAssessmentMilestoneRule]

        init(rules: [any GlobalAssessmentMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAssessmentMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAssessmentMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAssessmentMilestone]) -> [String: [String]] {
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

    static func defaultGlobalAssessmentMilestoneValidator() -> GlobalAssessmentMilestoneValidator {
        return GlobalAssessmentMilestoneValidator(
            rules: [
                GlobalAssessmentMilestoneRequiredTitleRule(message: "global assessment milestone needs an entry"),
                GlobalAssessmentMilestoneVersionRangeRule(min: 64, max: 80),
                GlobalAssessmentMilestoneAllowedCodeRule(allowed: []),
                GlobalAssessmentMilestoneExternalRefLengthRule(maxLength: 80),
                GlobalAssessmentMilestoneRequiredExternalRefRule(
                    message: "global assessment milestone needs this field"
                ),
            ]
        )
    }
}
