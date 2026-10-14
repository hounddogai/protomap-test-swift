import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure allocation must pass. Check returns its problems, or none.
    protocol ClosureAllocationRule {
        func check(_ item: ClosureAllocation) -> [String]
    }

    final class ClosureAllocationRequiredLocaleRule: ClosureAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureAllocation) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureAllocationCodeLengthRule: ClosureAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureAllocationCeilingRangeRule: ClosureAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureAllocation) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureAllocationRequiredLabelRule: ClosureAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure allocation.
    final class ClosureAllocationValidator {
        var rules: [any ClosureAllocationRule]

        init(rules: [any ClosureAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureAllocation) -> [String] {
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

        func requireValid(_ item: ClosureAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureAllocation]) -> [String: [String]] {
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

    static func defaultClosureAllocationValidator() -> ClosureAllocationValidator {
        return ClosureAllocationValidator(
            rules: [
                ClosureAllocationRequiredLocaleRule(message: "closure allocation needs a value"),
                ClosureAllocationCodeLengthRule(maxLength: 16),
                ClosureAllocationCeilingRangeRule(min: 3.4, max: 555.0),
                ClosureAllocationRequiredLabelRule(message: "closure allocation needs an entry"),
            ]
        )
    }
}
