import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global goal assignment must pass. Check returns its problems, or none.
    protocol GlobalGoalAssignmentRule {
        func check(_ item: GlobalGoalAssignment) -> [String]
    }

    final class GlobalGoalAssignmentRequiredTitleRule: GlobalGoalAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalGoalAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalGoalAssignmentCodeLengthRule: GlobalGoalAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalGoalAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalGoalAssignmentRequiredTimezoneRule: GlobalGoalAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalGoalAssignment) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalGoalAssignmentLabelLengthRule: GlobalGoalAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalGoalAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalGoalAssignmentCapacityRangeRule: GlobalGoalAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalGoalAssignment) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global goal assignment.
    final class GlobalGoalAssignmentValidator {
        var rules: [any GlobalGoalAssignmentRule]

        init(rules: [any GlobalGoalAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalGoalAssignment) -> [String] {
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

        func requireValid(_ item: GlobalGoalAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalGoalAssignment]) -> [String: [String]] {
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

    static func defaultGlobalGoalAssignmentValidator() -> GlobalGoalAssignmentValidator {
        return GlobalGoalAssignmentValidator(
            rules: [
                GlobalGoalAssignmentRequiredTitleRule(message: "global goal assignment needs an entry"),
                GlobalGoalAssignmentCodeLengthRule(maxLength: 1000),
                GlobalGoalAssignmentRequiredTimezoneRule(message: "global goal assignment needs this field"),
                GlobalGoalAssignmentLabelLengthRule(maxLength: 64),
                GlobalGoalAssignmentCapacityRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
