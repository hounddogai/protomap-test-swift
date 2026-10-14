import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict worklist allocation must pass. Check returns its problems, or none.
    protocol StrictWorklistAllocationRule {
        func check(_ item: StrictWorklistAllocation) -> [String]
    }

    final class StrictWorklistAllocationCodePrefixRule: StrictWorklistAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictWorklistAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictWorklistAllocationCodeLengthRule: StrictWorklistAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWorklistAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWorklistAllocationAmountRangeRule: StrictWorklistAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWorklistAllocation) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictWorklistAllocationRequiredCodeRule: StrictWorklistAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWorklistAllocationRequiredNameRule: StrictWorklistAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWorklistAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict worklist allocation.
    final class StrictWorklistAllocationValidator {
        var rules: [any StrictWorklistAllocationRule]

        init(rules: [any StrictWorklistAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWorklistAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictWorklistAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWorklistAllocation]) -> [String: [String]] {
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

    static func defaultStrictWorklistAllocationValidator() -> StrictWorklistAllocationValidator {
        return StrictWorklistAllocationValidator(
            rules: [
                StrictWorklistAllocationCodePrefixRule(prefix: "Q"),
                StrictWorklistAllocationCodeLengthRule(maxLength: 255),
                StrictWorklistAllocationAmountRangeRule(min: 1.3, max: 1342.7),
                StrictWorklistAllocationRequiredCodeRule(message: "strict worklist allocation needs a value"),
                StrictWorklistAllocationRequiredNameRule(message: "strict worklist allocation needs a value"),
            ]
        )
    }
}
