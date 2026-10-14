import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict courier policy must pass. Check returns its problems, or none.
    protocol StrictCourierPolicyRule {
        func check(_ item: StrictCourierPolicy) -> [String]
    }

    final class StrictCourierPolicyRequiredLocaleRule: StrictCourierPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCourierPolicy) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCourierPolicyCodeLengthRule: StrictCourierPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCourierPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCourierPolicyRetriesRangeRule: StrictCourierPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCourierPolicy) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictCourierPolicyDurationMinutesRangeRule: StrictCourierPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCourierPolicy) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictCourierPolicyRequiredChannelRule: StrictCourierPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCourierPolicy) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCourierPolicyDiscountRangeRule: StrictCourierPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCourierPolicy) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict courier policy.
    final class StrictCourierPolicyValidator {
        var rules: [any StrictCourierPolicyRule]

        init(rules: [any StrictCourierPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCourierPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCourierPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCourierPolicy]) -> [String: [String]] {
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

    static func defaultStrictCourierPolicyValidator() -> StrictCourierPolicyValidator {
        return StrictCourierPolicyValidator(
            rules: [
                StrictCourierPolicyRequiredLocaleRule(message: "strict courier policy needs this field"),
                StrictCourierPolicyCodeLengthRule(maxLength: 86400),
                StrictCourierPolicyRetriesRangeRule(min: 255, max: 1000),
                StrictCourierPolicyDurationMinutesRangeRule(min: 32, max: 86400),
                StrictCourierPolicyRequiredChannelRule(message: "strict courier policy needs this field"),
                StrictCourierPolicyDiscountRangeRule(min: 2.3, max: 4054.6),
            ]
        )
    }
}
