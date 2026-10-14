import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted care protocol policy must pass. Check returns its problems, or none.
    protocol WeightedCareProtocolPolicyRule {
        func check(_ item: WeightedCareProtocolPolicy) -> [String]
    }

    final class WeightedCareProtocolPolicyNameLengthRule: WeightedCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCareProtocolPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCareProtocolPolicyCreatedAtRangeRule: WeightedCareProtocolPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareProtocolPolicy) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedCareProtocolPolicyRequiredCountryRule: WeightedCareProtocolPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCareProtocolPolicy) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCareProtocolPolicyCodeLengthRule: WeightedCareProtocolPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCareProtocolPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCareProtocolPolicyGraceDaysRangeRule: WeightedCareProtocolPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCareProtocolPolicy) -> [String] {
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

    /// Runs every rule of a weighted care protocol policy.
    final class WeightedCareProtocolPolicyValidator {
        var rules: [any WeightedCareProtocolPolicyRule]

        init(rules: [any WeightedCareProtocolPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCareProtocolPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedCareProtocolPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCareProtocolPolicy]) -> [String: [String]] {
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

    static func defaultWeightedCareProtocolPolicyValidator() -> WeightedCareProtocolPolicyValidator {
        return WeightedCareProtocolPolicyValidator(
            rules: [
                WeightedCareProtocolPolicyNameLengthRule(maxLength: 120),
                WeightedCareProtocolPolicyCreatedAtRangeRule(min: 64, max: 255),
                WeightedCareProtocolPolicyRequiredCountryRule(message: "weighted care protocol policy needs an entry"),
                WeightedCareProtocolPolicyCodeLengthRule(maxLength: 32),
                WeightedCareProtocolPolicyGraceDaysRangeRule(min: 16, max: 120),
            ]
        )
    }
}
