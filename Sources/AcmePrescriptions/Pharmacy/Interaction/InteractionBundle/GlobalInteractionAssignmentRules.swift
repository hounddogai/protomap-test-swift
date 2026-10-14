import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global interaction assignment must pass. Check returns its problems, or none.
    protocol GlobalInteractionAssignmentRule {
        func check(_ item: GlobalInteractionAssignment) -> [String]
    }

    final class GlobalInteractionAssignmentCodeLengthRule: GlobalInteractionAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalInteractionAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalInteractionAssignmentRequiredTitleRule: GlobalInteractionAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalInteractionAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalInteractionAssignmentPinnedGuardRule: GlobalInteractionAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalInteractionAssignment) -> [String] {
            if item.pinned && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a global interaction assignment.
    final class GlobalInteractionAssignmentValidator {
        var rules: [any GlobalInteractionAssignmentRule]

        init(rules: [any GlobalInteractionAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalInteractionAssignment) -> [String] {
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

        func requireValid(_ item: GlobalInteractionAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalInteractionAssignment]) -> [String: [String]] {
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

    static func defaultGlobalInteractionAssignmentValidator() -> GlobalInteractionAssignmentValidator {
        return GlobalInteractionAssignmentValidator(
            rules: [
                GlobalInteractionAssignmentCodeLengthRule(maxLength: 32),
                GlobalInteractionAssignmentRequiredTitleRule(message: "global interaction assignment needs an entry"),
                GlobalInteractionAssignmentPinnedGuardRule(limit: 1000),
            ]
        )
    }
}
