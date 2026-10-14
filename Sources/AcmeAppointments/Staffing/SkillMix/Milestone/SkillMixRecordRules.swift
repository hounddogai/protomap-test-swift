import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix record must pass. Check returns its problems, or none.
    protocol SkillMixRecordRule {
        func check(_ item: SkillMixRecord) -> [String]
    }

    final class SkillMixRecordRequiredTitleRule: SkillMixRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixRecordRetriesRangeRule: SkillMixRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixRecord) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixRecordRequiredBedRule: SkillMixRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixRecord) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixRecordRequiredCodeRule: SkillMixRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixRecordAllowedCodeRule: SkillMixRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix record.
    final class SkillMixRecordValidator {
        var rules: [any SkillMixRecordRule]

        init(rules: [any SkillMixRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixRecord]) -> [String: [String]] {
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

    static func defaultSkillMixRecordValidator() -> SkillMixRecordValidator {
        return SkillMixRecordValidator(
            rules: [
                SkillMixRecordRequiredTitleRule(message: "skill mix record needs a value"),
                SkillMixRecordRetriesRangeRule(min: 16, max: 1000),
                SkillMixRecordRequiredBedRule(message: "skill mix record needs this field"),
                SkillMixRecordRequiredCodeRule(message: "skill mix record needs a value"),
                SkillMixRecordAllowedCodeRule(allowed: []),
            ]
        )
    }
}
