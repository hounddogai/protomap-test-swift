import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix assignment must pass. Check returns its problems, or none.
    protocol SkillMixAssignmentRule {
        func check(_ item: SkillMixAssignment) -> [String]
    }

    final class SkillMixAssignmentVisitMinutesRangeRule: SkillMixAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixAssignment) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixAssignmentRequiredReviewerRule: SkillMixAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixAssignment) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixAssignmentWardLengthRule: SkillMixAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixAssignment) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix assignment.
    final class SkillMixAssignmentValidator {
        var rules: [any SkillMixAssignmentRule]

        init(rules: [any SkillMixAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixAssignment]) -> [String: [String]] {
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

    static func defaultSkillMixAssignmentValidator() -> SkillMixAssignmentValidator {
        return SkillMixAssignmentValidator(
            rules: [
                SkillMixAssignmentVisitMinutesRangeRule(min: 32, max: 3600),
                SkillMixAssignmentRequiredReviewerRule(message: "skill mix assignment needs this field"),
                SkillMixAssignmentWardLengthRule(maxLength: 120),
            ]
        )
    }
}
