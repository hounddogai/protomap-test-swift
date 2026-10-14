import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global skill mix assignment must pass. Check returns its problems, or none.
    protocol GlobalSkillMixAssignmentRule {
        func check(_ item: GlobalSkillMixAssignment) -> [String]
    }

    final class GlobalSkillMixAssignmentRequiredUnitRule: GlobalSkillMixAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSkillMixAssignment) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSkillMixAssignmentArchivedGuardRule: GlobalSkillMixAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalSkillMixAssignment) -> [String] {
            if item.archived && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class GlobalSkillMixAssignmentCodeLengthRule: GlobalSkillMixAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSkillMixAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSkillMixAssignmentRequiredTitleRule: GlobalSkillMixAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSkillMixAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global skill mix assignment.
    final class GlobalSkillMixAssignmentValidator {
        var rules: [any GlobalSkillMixAssignmentRule]

        init(rules: [any GlobalSkillMixAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSkillMixAssignment) -> [String] {
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

        func requireValid(_ item: GlobalSkillMixAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSkillMixAssignment]) -> [String: [String]] {
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

    static func defaultGlobalSkillMixAssignmentValidator() -> GlobalSkillMixAssignmentValidator {
        return GlobalSkillMixAssignmentValidator(
            rules: [
                GlobalSkillMixAssignmentRequiredUnitRule(message: "global skill mix assignment needs this field"),
                GlobalSkillMixAssignmentArchivedGuardRule(limit: 64),
                GlobalSkillMixAssignmentCodeLengthRule(maxLength: 86400),
                GlobalSkillMixAssignmentRequiredTitleRule(message: "global skill mix assignment needs an entry"),
            ]
        )
    }
}
