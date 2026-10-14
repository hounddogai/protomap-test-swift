import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix notice must pass. Check returns its problems, or none.
    protocol SkillMixNoticeRule {
        func check(_ item: SkillMixNotice) -> [String]
    }

    final class SkillMixNoticeRequiredTimezoneRule: SkillMixNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixNotice) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixNoticeRequiredCategoryRule: SkillMixNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixNotice) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixNoticeCodeLengthRule: SkillMixNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix notice.
    final class SkillMixNoticeValidator {
        var rules: [any SkillMixNoticeRule]

        init(rules: [any SkillMixNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixNotice]) -> [String: [String]] {
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

    static func defaultSkillMixNoticeValidator() -> SkillMixNoticeValidator {
        return SkillMixNoticeValidator(
            rules: [
                SkillMixNoticeRequiredTimezoneRule(message: "skill mix notice needs an entry"),
                SkillMixNoticeRequiredCategoryRule(message: "skill mix notice needs a value"),
                SkillMixNoticeCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
