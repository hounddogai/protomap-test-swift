import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict formulary allocation must pass. Check returns its problems, or none.
    protocol StrictFormularyAllocationRule {
        func check(_ item: StrictFormularyAllocation) -> [String]
    }

    final class StrictFormularyAllocationRequiredCodeRule: StrictFormularyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictFormularyAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictFormularyAllocationGraceDaysRangeRule: StrictFormularyAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFormularyAllocation) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictFormularyAllocationCodePrefixRule: StrictFormularyAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictFormularyAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict formulary allocation.
    final class StrictFormularyAllocationValidator {
        var rules: [any StrictFormularyAllocationRule]

        init(rules: [any StrictFormularyAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictFormularyAllocation) -> [String] {
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

        func requireValid(_ item: StrictFormularyAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictFormularyAllocation]) -> [String: [String]] {
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

    static func defaultStrictFormularyAllocationValidator() -> StrictFormularyAllocationValidator {
        return StrictFormularyAllocationValidator(
            rules: [
                StrictFormularyAllocationRequiredCodeRule(message: "strict formulary allocation needs an entry"),
                StrictFormularyAllocationGraceDaysRangeRule(min: 120, max: 86400),
                StrictFormularyAllocationCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
