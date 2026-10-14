import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift assignment must pass. Check returns its problems, or none.
    protocol ShiftAssignmentRule {
        func check(_ item: ShiftAssignment) -> [String]
    }

    final class ShiftAssignmentCodeLengthRule: ShiftAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftAssignmentTitleLengthRule: ShiftAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftAssignmentAllowedOwnerIDRule: ShiftAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is out of range"]
            }
            return []
        }
    }

    final class ShiftAssignmentRequiredTitleRule: ShiftAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftAssignmentWeightRangeRule: ShiftAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftAssignment) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift assignment.
    final class ShiftAssignmentValidator {
        var rules: [any ShiftAssignmentRule]

        init(rules: [any ShiftAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftAssignment) -> [String] {
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

        func requireValid(_ item: ShiftAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftAssignment]) -> [String: [String]] {
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

    static func defaultShiftAssignmentValidator() -> ShiftAssignmentValidator {
        return ShiftAssignmentValidator(
            rules: [
                ShiftAssignmentCodeLengthRule(maxLength: 255),
                ShiftAssignmentTitleLengthRule(maxLength: 1000),
                ShiftAssignmentAllowedOwnerIDRule(allowed: ["default", "capped"]),
                ShiftAssignmentRequiredTitleRule(message: "shift assignment needs a value"),
                ShiftAssignmentWeightRangeRule(min: 6.6, max: 3032.4),
            ]
        )
    }
}
