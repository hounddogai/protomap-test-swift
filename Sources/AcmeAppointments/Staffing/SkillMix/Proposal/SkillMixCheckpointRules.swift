import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix checkpoint must pass. Check returns its problems, or none.
    protocol SkillMixCheckpointRule {
        func check(_ item: SkillMixCheckpoint) -> [String]
    }

    final class SkillMixCheckpointRequiredCodeRule: SkillMixCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixCheckpointAllowedReviewerRule: SkillMixCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is expired"]
            }
            return []
        }
    }

    final class SkillMixCheckpointDurationMinutesRangeRule: SkillMixCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixCheckpoint) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix checkpoint.
    final class SkillMixCheckpointValidator {
        var rules: [any SkillMixCheckpointRule]

        init(rules: [any SkillMixCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixCheckpoint]) -> [String: [String]] {
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

    static func defaultSkillMixCheckpointValidator() -> SkillMixCheckpointValidator {
        return SkillMixCheckpointValidator(
            rules: [
                SkillMixCheckpointRequiredCodeRule(message: "skill mix checkpoint needs this field"),
                SkillMixCheckpointAllowedReviewerRule(allowed: ["default"]),
                SkillMixCheckpointDurationMinutesRangeRule(min: 16, max: 32),
            ]
        )
    }
}
