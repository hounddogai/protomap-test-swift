import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal assignment must pass. Check returns its problems, or none.
    protocol GoalAssignmentRule {
        func check(_ item: GoalAssignment) -> [String]
    }

    final class GoalAssignmentChecksumLengthRule: GoalAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalAssignment) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalAssignmentCodePrefixRule: GoalAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GoalAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GoalAssignmentRequiredChecksumRule: GoalAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAssignment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalAssignmentRequiredCodeRule: GoalAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal assignment.
    final class GoalAssignmentValidator {
        var rules: [any GoalAssignmentRule]

        init(rules: [any GoalAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GoalAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalAssignment]) -> [String: [String]] {
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

    static func defaultGoalAssignmentValidator() -> GoalAssignmentValidator {
        return GoalAssignmentValidator(
            rules: [
                GoalAssignmentChecksumLengthRule(maxLength: 16),
                GoalAssignmentCodePrefixRule(prefix: "REF"),
                GoalAssignmentRequiredChecksumRule(message: "goal assignment needs an entry"),
                GoalAssignmentRequiredCodeRule(message: "goal assignment needs an entry"),
            ]
        )
    }
}
