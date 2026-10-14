import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global care protocol assignment must pass. Check returns its problems, or none.
    protocol GlobalCareProtocolAssignmentRule {
        func check(_ item: GlobalCareProtocolAssignment) -> [String]
    }

    final class GlobalCareProtocolAssignmentRequiredCodeRule: GlobalCareProtocolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareProtocolAssignmentRequiredNotesRule: GlobalCareProtocolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolAssignment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareProtocolAssignmentAttemptsRangeRule: GlobalCareProtocolAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareProtocolAssignment) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolAssignmentTitleLengthRule: GlobalCareProtocolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareProtocolAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global care protocol assignment.
    final class GlobalCareProtocolAssignmentValidator {
        var rules: [any GlobalCareProtocolAssignmentRule]

        init(rules: [any GlobalCareProtocolAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareProtocolAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCareProtocolAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareProtocolAssignment]) -> [String: [String]] {
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

    static func defaultGlobalCareProtocolAssignmentValidator() -> GlobalCareProtocolAssignmentValidator {
        return GlobalCareProtocolAssignmentValidator(
            rules: [
                GlobalCareProtocolAssignmentRequiredCodeRule(
                    message: "global care protocol assignment needs an entry"
                ),
                GlobalCareProtocolAssignmentRequiredNotesRule(
                    message: "global care protocol assignment needs an entry"
                ),
                GlobalCareProtocolAssignmentAttemptsRangeRule(min: 3600, max: 3600),
                GlobalCareProtocolAssignmentTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
