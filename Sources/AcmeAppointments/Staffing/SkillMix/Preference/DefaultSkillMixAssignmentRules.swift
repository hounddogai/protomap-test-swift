import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default skill mix assignment must pass. Check returns its problems, or none.
    protocol DefaultSkillMixAssignmentRule {
        func check(_ item: DefaultSkillMixAssignment) -> [String]
    }

    final class DefaultSkillMixAssignmentRequiredWardRule: DefaultSkillMixAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSkillMixAssignment) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSkillMixAssignmentRequiredNameRule: DefaultSkillMixAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSkillMixAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSkillMixAssignmentWardLengthRule: DefaultSkillMixAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSkillMixAssignment) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSkillMixAssignmentNameLengthRule: DefaultSkillMixAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSkillMixAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSkillMixAssignmentCodeLengthRule: DefaultSkillMixAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSkillMixAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default skill mix assignment.
    final class DefaultSkillMixAssignmentValidator {
        var rules: [any DefaultSkillMixAssignmentRule]

        init(rules: [any DefaultSkillMixAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSkillMixAssignment) -> [String] {
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

        func requireValid(_ item: DefaultSkillMixAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSkillMixAssignment]) -> [String: [String]] {
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

    static func defaultDefaultSkillMixAssignmentValidator() -> DefaultSkillMixAssignmentValidator {
        return DefaultSkillMixAssignmentValidator(
            rules: [
                DefaultSkillMixAssignmentRequiredWardRule(message: "default skill mix assignment needs an entry"),
                DefaultSkillMixAssignmentRequiredNameRule(message: "default skill mix assignment needs an entry"),
                DefaultSkillMixAssignmentWardLengthRule(maxLength: 32),
                DefaultSkillMixAssignmentNameLengthRule(maxLength: 3600),
                DefaultSkillMixAssignmentCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
