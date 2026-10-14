import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance cycle must pass. Check returns its problems, or none.
    protocol RemittanceCycleRule {
        func check(_ item: RemittanceCycle) -> [String]
    }

    final class RemittanceCycleCopayRangeRule: RemittanceCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceCycle) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceCycleCodePrefixRule: RemittanceCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceCycleAmountRangeRule: RemittanceCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceCycle) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance cycle.
    final class RemittanceCycleValidator {
        var rules: [any RemittanceCycleRule]

        init(rules: [any RemittanceCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceCycle]) -> [String: [String]] {
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

    static func defaultRemittanceCycleValidator() -> RemittanceCycleValidator {
        return RemittanceCycleValidator(
            rules: [
                RemittanceCycleCopayRangeRule(min: 8.5, max: 4869.1),
                RemittanceCycleCodePrefixRule(prefix: "ACM"),
                RemittanceCycleAmountRangeRule(min: 5.8, max: 1733.4),
            ]
        )
    }
}
