import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback overtime policy must pass. Check returns its problems, or none.
    protocol FallbackOvertimePolicyRule {
        func check(_ item: FallbackOvertimePolicy) -> [String]
    }

    final class FallbackOvertimePolicyBudgetRangeRule: FallbackOvertimePolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOvertimePolicy) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackOvertimePolicyRequiredChannelRule: FallbackOvertimePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOvertimePolicy) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOvertimePolicyChannelLengthRule: FallbackOvertimePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOvertimePolicy) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackOvertimePolicyCodeLengthRule: FallbackOvertimePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOvertimePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackOvertimePolicyCategoryLengthRule: FallbackOvertimePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOvertimePolicy) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback overtime policy.
    final class FallbackOvertimePolicyValidator {
        var rules: [any FallbackOvertimePolicyRule]

        init(rules: [any FallbackOvertimePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOvertimePolicy) -> [String] {
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

        func requireValid(_ item: FallbackOvertimePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOvertimePolicy]) -> [String: [String]] {
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

    static func defaultFallbackOvertimePolicyValidator() -> FallbackOvertimePolicyValidator {
        return FallbackOvertimePolicyValidator(
            rules: [
                FallbackOvertimePolicyBudgetRangeRule(min: 3.0, max: 2597.8),
                FallbackOvertimePolicyRequiredChannelRule(message: "fallback overtime policy needs a value"),
                FallbackOvertimePolicyChannelLengthRule(maxLength: 86400),
                FallbackOvertimePolicyCodeLengthRule(maxLength: 1000),
                FallbackOvertimePolicyCategoryLengthRule(maxLength: 86400),
            ]
        )
    }
}
