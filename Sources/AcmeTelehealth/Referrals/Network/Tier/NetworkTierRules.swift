import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network tier must pass. Check returns its problems, or none.
    protocol NetworkTierRule {
        func check(_ item: NetworkTier) -> [String]
    }

    final class NetworkTierCodePrefixRule: NetworkTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class NetworkTierBudgetRangeRule: NetworkTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkTier) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkTierCodeLengthRule: NetworkTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkTierPayerLengthRule: NetworkTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkTier) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network tier.
    final class NetworkTierValidator {
        var rules: [any NetworkTierRule]

        init(rules: [any NetworkTierRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkTier) -> [String] {
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

        func requireValid(_ item: NetworkTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkTier]) -> [String: [String]] {
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

    static func defaultNetworkTierValidator() -> NetworkTierValidator {
        return NetworkTierValidator(
            rules: [
                NetworkTierCodePrefixRule(prefix: "Q"),
                NetworkTierBudgetRangeRule(min: 4.7, max: 3995.1),
                NetworkTierCodeLengthRule(maxLength: 120),
                NetworkTierPayerLengthRule(maxLength: 1000),
            ]
        )
    }
}
