import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge request must pass. Check returns its problems, or none.
    protocol ChargeRequestRule {
        func check(_ item: ChargeRequest) -> [String]
    }

    final class ChargeRequestCapacityRangeRule: ChargeRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeRequest) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeRequestAmountRangeRule: ChargeRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeRequest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeRequestCodePrefixRule: ChargeRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeRequestChannelLengthRule: ChargeRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeRequest) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge request.
    final class ChargeRequestValidator {
        var rules: [any ChargeRequestRule]

        init(rules: [any ChargeRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeRequest]) -> [String: [String]] {
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

    static func defaultChargeRequestValidator() -> ChargeRequestValidator {
        return ChargeRequestValidator(
            rules: [
                ChargeRequestCapacityRangeRule(min: 64, max: 120),
                ChargeRequestAmountRangeRule(min: 6.0, max: 1710.8),
                ChargeRequestCodePrefixRule(prefix: "X"),
                ChargeRequestChannelLengthRule(maxLength: 32),
            ]
        )
    }
}
