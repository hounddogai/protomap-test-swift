import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive overtime allocation must pass. Check returns its problems, or none.
    protocol AdaptiveOvertimeAllocationRule {
        func check(_ item: AdaptiveOvertimeAllocation) -> [String]
    }

    final class AdaptiveOvertimeAllocationCodePrefixRule: AdaptiveOvertimeAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveOvertimeAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeAllocationRequiredPhoneRule: AdaptiveOvertimeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOvertimeAllocation) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOvertimeAllocationCodeLengthRule: AdaptiveOvertimeAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOvertimeAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeAllocationCeilingRangeRule: AdaptiveOvertimeAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOvertimeAllocation) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive overtime allocation.
    final class AdaptiveOvertimeAllocationValidator {
        var rules: [any AdaptiveOvertimeAllocationRule]

        init(rules: [any AdaptiveOvertimeAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOvertimeAllocation) -> [String] {
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

        func requireValid(_ item: AdaptiveOvertimeAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOvertimeAllocation]) -> [String: [String]] {
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

    static func defaultAdaptiveOvertimeAllocationValidator() -> AdaptiveOvertimeAllocationValidator {
        return AdaptiveOvertimeAllocationValidator(
            rules: [
                AdaptiveOvertimeAllocationCodePrefixRule(prefix: "OPS"),
                AdaptiveOvertimeAllocationRequiredPhoneRule(message: "adaptive overtime allocation needs an entry"),
                AdaptiveOvertimeAllocationCodeLengthRule(maxLength: 1000),
                AdaptiveOvertimeAllocationCeilingRangeRule(min: 0.1, max: 4705.7),
            ]
        )
    }
}
