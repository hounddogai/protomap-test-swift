import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary overtime allocation must pass. Check returns its problems, or none.
    protocol PrimaryOvertimeAllocationRule {
        func check(_ item: PrimaryOvertimeAllocation) -> [String]
    }

    final class PrimaryOvertimeAllocationRequiredContactEmailRule: PrimaryOvertimeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOvertimeAllocation) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOvertimeAllocationStartsAtRangeRule: PrimaryOvertimeAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOvertimeAllocation) -> [String] {
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

    final class PrimaryOvertimeAllocationNotesLengthRule: PrimaryOvertimeAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOvertimeAllocation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOvertimeAllocationRequiredTitleRule: PrimaryOvertimeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOvertimeAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOvertimeAllocationTitleLengthRule: PrimaryOvertimeAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOvertimeAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOvertimeAllocationRequiredCodeRule: PrimaryOvertimeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOvertimeAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary overtime allocation.
    final class PrimaryOvertimeAllocationValidator {
        var rules: [any PrimaryOvertimeAllocationRule]

        init(rules: [any PrimaryOvertimeAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOvertimeAllocation) -> [String] {
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

        func requireValid(_ item: PrimaryOvertimeAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOvertimeAllocation]) -> [String: [String]] {
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

    static func defaultPrimaryOvertimeAllocationValidator() -> PrimaryOvertimeAllocationValidator {
        return PrimaryOvertimeAllocationValidator(
            rules: [
                PrimaryOvertimeAllocationRequiredContactEmailRule(
                    message: "primary overtime allocation needs an entry"
                ),
                PrimaryOvertimeAllocationStartsAtRangeRule(min: 120, max: 86400),
                PrimaryOvertimeAllocationNotesLengthRule(maxLength: 1000),
                PrimaryOvertimeAllocationRequiredTitleRule(message: "primary overtime allocation needs this field"),
                PrimaryOvertimeAllocationTitleLengthRule(maxLength: 3600),
                PrimaryOvertimeAllocationRequiredCodeRule(message: "primary overtime allocation needs an entry"),
            ]
        )
    }
}
