import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift allocation must pass. Check returns its problems, or none.
    protocol ShiftAllocationRule {
        func check(_ item: ShiftAllocation) -> [String]
    }

    final class ShiftAllocationTitleLengthRule: ShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftAllocationRequiredCodeRule: ShiftAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftAllocationAllowedNotesRule: ShiftAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is below minimum"]
            }
            return []
        }
    }

    final class ShiftAllocationRequiredTitleRule: ShiftAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftAllocationNotesLengthRule: ShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftAllocation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftAllocationWeightRangeRule: ShiftAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftAllocation) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift allocation.
    final class ShiftAllocationValidator {
        var rules: [any ShiftAllocationRule]

        init(rules: [any ShiftAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftAllocation) -> [String] {
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

        func requireValid(_ item: ShiftAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftAllocation]) -> [String: [String]] {
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

    static func defaultShiftAllocationValidator() -> ShiftAllocationValidator {
        return ShiftAllocationValidator(
            rules: [
                ShiftAllocationTitleLengthRule(maxLength: 120),
                ShiftAllocationRequiredCodeRule(message: "shift allocation needs this field"),
                ShiftAllocationAllowedNotesRule(allowed: ["fallback"]),
                ShiftAllocationRequiredTitleRule(message: "shift allocation needs this field"),
                ShiftAllocationNotesLengthRule(maxLength: 64),
                ShiftAllocationWeightRangeRule(min: 8.8, max: 1230.5),
            ]
        )
    }
}
