import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted claim override must pass. Check returns its problems, or none.
    protocol WeightedClaimOverrideRule {
        func check(_ item: WeightedClaimOverride) -> [String]
    }

    final class WeightedClaimOverrideCodePrefixRule: WeightedClaimOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedClaimOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedClaimOverrideCountryLengthRule: WeightedClaimOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedClaimOverride) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedClaimOverrideAllowedCodeRule: WeightedClaimOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedClaimOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class WeightedClaimOverrideBatchSizeRangeRule: WeightedClaimOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedClaimOverride) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted claim override.
    final class WeightedClaimOverrideValidator {
        var rules: [any WeightedClaimOverrideRule]

        init(rules: [any WeightedClaimOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedClaimOverride) -> [String] {
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

        func requireValid(_ item: WeightedClaimOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedClaimOverride]) -> [String: [String]] {
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

    static func defaultWeightedClaimOverrideValidator() -> WeightedClaimOverrideValidator {
        return WeightedClaimOverrideValidator(
            rules: [
                WeightedClaimOverrideCodePrefixRule(prefix: "ACM"),
                WeightedClaimOverrideCountryLengthRule(maxLength: 16),
                WeightedClaimOverrideAllowedCodeRule(allowed: []),
                WeightedClaimOverrideBatchSizeRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
