import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled float pool policy must pass. Check returns its problems, or none.
    protocol ScheduledFloatPoolPolicyRule {
        func check(_ item: ScheduledFloatPoolPolicy) -> [String]
    }

    final class ScheduledFloatPoolPolicyRequiredLabelRule: ScheduledFloatPoolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFloatPoolPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFloatPoolPolicyCopayRangeRule: ScheduledFloatPoolPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFloatPoolPolicy) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolPolicyCodeLengthRule: ScheduledFloatPoolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolPolicyRefillsRangeRule: ScheduledFloatPoolPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFloatPoolPolicy) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledFloatPoolPolicyAllowedCodeRule: ScheduledFloatPoolPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledFloatPoolPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolPolicyLabelLengthRule: ScheduledFloatPoolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled float pool policy.
    final class ScheduledFloatPoolPolicyValidator {
        var rules: [any ScheduledFloatPoolPolicyRule]

        init(rules: [any ScheduledFloatPoolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFloatPoolPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledFloatPoolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFloatPoolPolicy]) -> [String: [String]] {
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

    static func defaultScheduledFloatPoolPolicyValidator() -> ScheduledFloatPoolPolicyValidator {
        return ScheduledFloatPoolPolicyValidator(
            rules: [
                ScheduledFloatPoolPolicyRequiredLabelRule(message: "scheduled float pool policy needs an entry"),
                ScheduledFloatPoolPolicyCopayRangeRule(min: 6.3, max: 2071.1),
                ScheduledFloatPoolPolicyCodeLengthRule(maxLength: 120),
                ScheduledFloatPoolPolicyRefillsRangeRule(min: 32, max: 64),
                ScheduledFloatPoolPolicyAllowedCodeRule(allowed: ["rolling"]),
                ScheduledFloatPoolPolicyLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
