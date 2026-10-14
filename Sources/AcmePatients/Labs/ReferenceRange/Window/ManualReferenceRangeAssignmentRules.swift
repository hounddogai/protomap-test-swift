import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual reference range assignment must pass. Check returns its problems, or none.
    protocol ManualReferenceRangeAssignmentRule {
        func check(_ item: ManualReferenceRangeAssignment) -> [String]
    }

    final class ManualReferenceRangeAssignmentContactEmailLengthRule: ManualReferenceRangeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReferenceRangeAssignment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReferenceRangeAssignmentRequiredCurrencyRule: ManualReferenceRangeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferenceRangeAssignment) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReferenceRangeAssignmentAllowedCodeRule: ManualReferenceRangeAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualReferenceRangeAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class ManualReferenceRangeAssignmentCodeLengthRule: ManualReferenceRangeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualReferenceRangeAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualReferenceRangeAssignmentStartsAtRangeRule: ManualReferenceRangeAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReferenceRangeAssignment) -> [String] {
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

    /// Runs every rule of a manual reference range assignment.
    final class ManualReferenceRangeAssignmentValidator {
        var rules: [any ManualReferenceRangeAssignmentRule]

        init(rules: [any ManualReferenceRangeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReferenceRangeAssignment) -> [String] {
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

        func requireValid(_ item: ManualReferenceRangeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReferenceRangeAssignment]) -> [String: [String]] {
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

    static func defaultManualReferenceRangeAssignmentValidator() -> ManualReferenceRangeAssignmentValidator {
        return ManualReferenceRangeAssignmentValidator(
            rules: [
                ManualReferenceRangeAssignmentContactEmailLengthRule(maxLength: 80),
                ManualReferenceRangeAssignmentRequiredCurrencyRule(
                    message: "manual reference range assignment needs a value"
                ),
                ManualReferenceRangeAssignmentAllowedCodeRule(allowed: ["capped"]),
                ManualReferenceRangeAssignmentCodeLengthRule(maxLength: 120),
                ManualReferenceRangeAssignmentStartsAtRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
