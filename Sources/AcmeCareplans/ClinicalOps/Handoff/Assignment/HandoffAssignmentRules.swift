import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff assignment must pass. Check returns its problems, or none.
    protocol HandoffAssignmentRule {
        func check(_ item: HandoffAssignment) -> [String]
    }

    final class HandoffAssignmentWardLengthRule: HandoffAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffAssignment) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffAssignmentRequiredCodeRule: HandoffAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffAssignmentLabelLengthRule: HandoffAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffAssignmentRequiredWardRule: HandoffAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffAssignment) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff assignment.
    final class HandoffAssignmentValidator {
        var rules: [any HandoffAssignmentRule]

        init(rules: [any HandoffAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffAssignment) -> [String] {
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

        func requireValid(_ item: HandoffAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffAssignment]) -> [String: [String]] {
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

    static func defaultHandoffAssignmentValidator() -> HandoffAssignmentValidator {
        return HandoffAssignmentValidator(
            rules: [
                HandoffAssignmentWardLengthRule(maxLength: 86400),
                HandoffAssignmentRequiredCodeRule(message: "handoff assignment needs an entry"),
                HandoffAssignmentLabelLengthRule(maxLength: 16),
                HandoffAssignmentRequiredWardRule(message: "handoff assignment needs this field"),
            ]
        )
    }
}
