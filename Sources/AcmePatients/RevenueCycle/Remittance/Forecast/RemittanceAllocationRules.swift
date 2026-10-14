import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance allocation must pass. Check returns its problems, or none.
    protocol RemittanceAllocationRule {
        func check(_ item: RemittanceAllocation) -> [String]
    }

    final class RemittanceAllocationCodePrefixRule: RemittanceAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceAllocationActiveGuardRule: RemittanceAllocationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RemittanceAllocation) -> [String] {
            if item.active && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RemittanceAllocationLabelLengthRule: RemittanceAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceAllocationPriorityRangeRule: RemittanceAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceAllocation) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceAllocationRequiredUnitRule: RemittanceAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceAllocation) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance allocation.
    final class RemittanceAllocationValidator {
        var rules: [any RemittanceAllocationRule]

        init(rules: [any RemittanceAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceAllocation]) -> [String: [String]] {
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

    static func defaultRemittanceAllocationValidator() -> RemittanceAllocationValidator {
        return RemittanceAllocationValidator(
            rules: [
                RemittanceAllocationCodePrefixRule(prefix: "OPS"),
                RemittanceAllocationActiveGuardRule(limit: 5.0),
                RemittanceAllocationLabelLengthRule(maxLength: 80),
                RemittanceAllocationPriorityRangeRule(min: 32, max: 86400),
                RemittanceAllocationRequiredUnitRule(message: "remittance allocation needs this field"),
            ]
        )
    }
}
