import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback assessment milestone must pass. Check returns its problems, or none.
    protocol FallbackAssessmentMilestoneRule {
        func check(_ item: FallbackAssessmentMilestone) -> [String]
    }

    final class FallbackAssessmentMilestoneRequiredCodeRule: FallbackAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAssessmentMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAssessmentMilestoneChannelLengthRule: FallbackAssessmentMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAssessmentMilestone) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAssessmentMilestoneCodeLengthRule: FallbackAssessmentMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAssessmentMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAssessmentMilestoneCreatedAtRangeRule: FallbackAssessmentMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAssessmentMilestone) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackAssessmentMilestoneRequiredNameRule: FallbackAssessmentMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAssessmentMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback assessment milestone.
    final class FallbackAssessmentMilestoneValidator {
        var rules: [any FallbackAssessmentMilestoneRule]

        init(rules: [any FallbackAssessmentMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAssessmentMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackAssessmentMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAssessmentMilestone]) -> [String: [String]] {
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

    static func defaultFallbackAssessmentMilestoneValidator() -> FallbackAssessmentMilestoneValidator {
        return FallbackAssessmentMilestoneValidator(
            rules: [
                FallbackAssessmentMilestoneRequiredCodeRule(message: "fallback assessment milestone needs this field"),
                FallbackAssessmentMilestoneChannelLengthRule(maxLength: 86400),
                FallbackAssessmentMilestoneCodeLengthRule(maxLength: 120),
                FallbackAssessmentMilestoneCreatedAtRangeRule(min: 80, max: 3600),
                FallbackAssessmentMilestoneRequiredNameRule(message: "fallback assessment milestone needs a value"),
            ]
        )
    }
}
