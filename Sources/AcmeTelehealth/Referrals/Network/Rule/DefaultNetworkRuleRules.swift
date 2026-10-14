import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default network rule must pass. Check returns its problems, or none.
    protocol DefaultNetworkRuleRule {
        func check(_ item: DefaultNetworkRule) -> [String]
    }

    final class DefaultNetworkRuleCountryLengthRule: DefaultNetworkRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultNetworkRule) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultNetworkRuleSequenceRangeRule: DefaultNetworkRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultNetworkRule) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultNetworkRuleScoreRangeRule: DefaultNetworkRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultNetworkRule) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default network rule.
    final class DefaultNetworkRuleValidator {
        var rules: [any DefaultNetworkRuleRule]

        init(rules: [any DefaultNetworkRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultNetworkRule) -> [String] {
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

        func requireValid(_ item: DefaultNetworkRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultNetworkRule]) -> [String: [String]] {
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

    static func defaultDefaultNetworkRuleValidator() -> DefaultNetworkRuleValidator {
        return DefaultNetworkRuleValidator(
            rules: [
                DefaultNetworkRuleCountryLengthRule(maxLength: 64),
                DefaultNetworkRuleSequenceRangeRule(min: 16, max: 3600),
                DefaultNetworkRuleScoreRangeRule(min: 0.2, max: 1784.5),
            ]
        )
    }
}
