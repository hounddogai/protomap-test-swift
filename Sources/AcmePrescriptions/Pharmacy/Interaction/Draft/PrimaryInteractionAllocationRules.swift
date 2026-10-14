import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary interaction allocation must pass. Check returns its problems, or none.
    protocol PrimaryInteractionAllocationRule {
        func check(_ item: PrimaryInteractionAllocation) -> [String]
    }

    final class PrimaryInteractionAllocationCodePrefixRule: PrimaryInteractionAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryInteractionAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryInteractionAllocationCodeLengthRule: PrimaryInteractionAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInteractionAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryInteractionAllocationRequiredCodeRule: PrimaryInteractionAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInteractionAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInteractionAllocationWeightRangeRule: PrimaryInteractionAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInteractionAllocation) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary interaction allocation.
    final class PrimaryInteractionAllocationValidator {
        var rules: [any PrimaryInteractionAllocationRule]

        init(rules: [any PrimaryInteractionAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInteractionAllocation) -> [String] {
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

        func requireValid(_ item: PrimaryInteractionAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInteractionAllocation]) -> [String: [String]] {
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

    static func defaultPrimaryInteractionAllocationValidator() -> PrimaryInteractionAllocationValidator {
        return PrimaryInteractionAllocationValidator(
            rules: [
                PrimaryInteractionAllocationCodePrefixRule(prefix: "Q"),
                PrimaryInteractionAllocationCodeLengthRule(maxLength: 1000),
                PrimaryInteractionAllocationRequiredCodeRule(message: "primary interaction allocation needs a value"),
                PrimaryInteractionAllocationWeightRangeRule(min: 0.6, max: 2209.9),
            ]
        )
    }
}
