import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global shift allocation must pass. Check returns its problems, or none.
    protocol GlobalShiftAllocationRule {
        func check(_ item: GlobalShiftAllocation) -> [String]
    }

    final class GlobalShiftAllocationCodePrefixRule: GlobalShiftAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalShiftAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalShiftAllocationBudgetRangeRule: GlobalShiftAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalShiftAllocation) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalShiftAllocationRequiredCodeRule: GlobalShiftAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalShiftAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalShiftAllocationTitleLengthRule: GlobalShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftAllocationRequiredCategoryRule: GlobalShiftAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalShiftAllocation) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalShiftAllocationCodeLengthRule: GlobalShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global shift allocation.
    final class GlobalShiftAllocationValidator {
        var rules: [any GlobalShiftAllocationRule]

        init(rules: [any GlobalShiftAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalShiftAllocation) -> [String] {
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

        func requireValid(_ item: GlobalShiftAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalShiftAllocation]) -> [String: [String]] {
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

    static func defaultGlobalShiftAllocationValidator() -> GlobalShiftAllocationValidator {
        return GlobalShiftAllocationValidator(
            rules: [
                GlobalShiftAllocationCodePrefixRule(prefix: "REF"),
                GlobalShiftAllocationBudgetRangeRule(min: 5.7, max: 1511.4),
                GlobalShiftAllocationRequiredCodeRule(message: "global shift allocation needs an entry"),
                GlobalShiftAllocationTitleLengthRule(maxLength: 255),
                GlobalShiftAllocationRequiredCategoryRule(message: "global shift allocation needs a value"),
                GlobalShiftAllocationCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
