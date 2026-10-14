import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority policy must pass. Check returns its problems, or none.
    protocol PriorityPolicyRule {
        func check(_ item: PriorityPolicy) -> [String]
    }

    final class PriorityPolicyScoreRangeRule: PriorityPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityPolicy) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PriorityPolicyLabelLengthRule: PriorityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityPolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityPolicyRequiredBedRule: PriorityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityPolicy) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority policy.
    final class PriorityPolicyValidator {
        var rules: [any PriorityPolicyRule]

        init(rules: [any PriorityPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityPolicy]) -> [String: [String]] {
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

    static func defaultPriorityPolicyValidator() -> PriorityPolicyValidator {
        return PriorityPolicyValidator(
            rules: [
                PriorityPolicyScoreRangeRule(min: 3.9, max: 3247.7),
                PriorityPolicyLabelLengthRule(maxLength: 80),
                PriorityPolicyRequiredBedRule(message: "priority policy needs an entry"),
            ]
        )
    }
}
