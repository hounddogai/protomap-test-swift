import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall assignment must pass. Check returns its problems, or none.
    protocol RecallAssignmentRule {
        func check(_ item: RecallAssignment) -> [String]
    }

    final class RecallAssignmentRequiredLabelRule: RecallAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallAssignmentRequiredOwnerIDRule: RecallAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallAssignment) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallAssignmentRequiredCodeRule: RecallAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallAssignmentPayerLengthRule: RecallAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallAssignment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallAssignmentStartsAtRangeRule: RecallAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallAssignment) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a recall assignment.
    final class RecallAssignmentValidator {
        var rules: [any RecallAssignmentRule]

        init(rules: [any RecallAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallAssignment) -> [String] {
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

        func requireValid(_ item: RecallAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallAssignment]) -> [String: [String]] {
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

    static func defaultRecallAssignmentValidator() -> RecallAssignmentValidator {
        return RecallAssignmentValidator(
            rules: [
                RecallAssignmentRequiredLabelRule(message: "recall assignment needs a value"),
                RecallAssignmentRequiredOwnerIDRule(message: "recall assignment needs this field"),
                RecallAssignmentRequiredCodeRule(message: "recall assignment needs a value"),
                RecallAssignmentPayerLengthRule(maxLength: 1000),
                RecallAssignmentStartsAtRangeRule(min: 16, max: 120),
            ]
        )
    }
}
