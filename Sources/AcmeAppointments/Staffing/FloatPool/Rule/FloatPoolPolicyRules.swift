import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool policy must pass. Check returns its problems, or none.
    protocol FloatPoolPolicyRule {
        func check(_ item: FloatPoolPolicy) -> [String]
    }

    final class FloatPoolPolicyRequiredLabelRule: FloatPoolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolPolicyRequiredCodeRule: FloatPoolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolPolicyMarginRangeRule: FloatPoolPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolPolicy) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool policy.
    final class FloatPoolPolicyValidator {
        var rules: [any FloatPoolPolicyRule]

        init(rules: [any FloatPoolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolPolicy]) -> [String: [String]] {
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

    static func defaultFloatPoolPolicyValidator() -> FloatPoolPolicyValidator {
        return FloatPoolPolicyValidator(
            rules: [
                FloatPoolPolicyRequiredLabelRule(message: "float pool policy needs a value"),
                FloatPoolPolicyRequiredCodeRule(message: "float pool policy needs an entry"),
                FloatPoolPolicyMarginRangeRule(min: 9.1, max: 2066.0),
            ]
        )
    }
}
