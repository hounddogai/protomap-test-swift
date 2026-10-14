import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier policy must pass. Check returns its problems, or none.
    protocol CourierPolicyRule {
        func check(_ item: CourierPolicy) -> [String]
    }

    final class CourierPolicyRequiredNameRule: CourierPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierPolicyRequiredTitleRule: CourierPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierPolicyGraceDaysRangeRule: CourierPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierPolicy) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a courier policy.
    final class CourierPolicyValidator {
        var rules: [any CourierPolicyRule]

        init(rules: [any CourierPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierPolicy]) -> [String: [String]] {
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

    static func defaultCourierPolicyValidator() -> CourierPolicyValidator {
        return CourierPolicyValidator(
            rules: [
                CourierPolicyRequiredNameRule(message: "courier policy needs an entry"),
                CourierPolicyRequiredTitleRule(message: "courier policy needs this field"),
                CourierPolicyGraceDaysRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
