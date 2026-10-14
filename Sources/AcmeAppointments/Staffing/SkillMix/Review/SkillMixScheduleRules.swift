import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix schedule must pass. Check returns its problems, or none.
    protocol SkillMixScheduleRule {
        func check(_ item: SkillMixSchedule) -> [String]
    }

    final class SkillMixScheduleRequiredProcedureCodeRule: SkillMixScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixSchedule) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixScheduleAllowedCodeRule: SkillMixScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class SkillMixScheduleCodePrefixRule: SkillMixScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixScheduleCategoryLengthRule: SkillMixScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixSchedule) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixScheduleCodeLengthRule: SkillMixScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix schedule.
    final class SkillMixScheduleValidator {
        var rules: [any SkillMixScheduleRule]

        init(rules: [any SkillMixScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixSchedule]) -> [String: [String]] {
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

    static func defaultSkillMixScheduleValidator() -> SkillMixScheduleValidator {
        return SkillMixScheduleValidator(
            rules: [
                SkillMixScheduleRequiredProcedureCodeRule(message: "skill mix schedule needs a value"),
                SkillMixScheduleAllowedCodeRule(allowed: ["adaptive", "fallback", "primary"]),
                SkillMixScheduleCodePrefixRule(prefix: "X"),
                SkillMixScheduleCategoryLengthRule(maxLength: 120),
                SkillMixScheduleCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
