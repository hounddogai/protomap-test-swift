import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal template must pass. Check returns its problems, or none.
    protocol GoalTemplateRule {
        func check(_ item: GoalTemplate) -> [String]
    }

    final class GoalTemplateOwnerIDLengthRule: GoalTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalTemplate) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalTemplateCodeLengthRule: GoalTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalTemplateRequiredCodeRule: GoalTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal template.
    final class GoalTemplateValidator {
        var rules: [any GoalTemplateRule]

        init(rules: [any GoalTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalTemplate) -> [String] {
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

        func requireValid(_ item: GoalTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalTemplate]) -> [String: [String]] {
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

    static func defaultGoalTemplateValidator() -> GoalTemplateValidator {
        return GoalTemplateValidator(
            rules: [
                GoalTemplateOwnerIDLengthRule(maxLength: 64),
                GoalTemplateCodeLengthRule(maxLength: 255),
                GoalTemplateRequiredCodeRule(message: "goal template needs an entry"),
            ]
        )
    }
}
