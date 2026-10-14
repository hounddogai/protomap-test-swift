import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral variance must pass. Check returns its problems, or none.
    protocol WeightedReferralVarianceRule {
        func check(_ item: WeightedReferralVariance) -> [String]
    }

    final class WeightedReferralVarianceAllowedCodeRule: WeightedReferralVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedReferralVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class WeightedReferralVarianceCodePrefixRule: WeightedReferralVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedReferralVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedReferralVarianceRequiredCodeRule: WeightedReferralVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralVarianceNameLengthRule: WeightedReferralVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReferralVarianceCopayRangeRule: WeightedReferralVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferralVariance) -> [String] {
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

    /// Runs every rule of a weighted referral variance.
    final class WeightedReferralVarianceValidator {
        var rules: [any WeightedReferralVarianceRule]

        init(rules: [any WeightedReferralVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedReferralVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralVariance]) -> [String: [String]] {
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

    static func defaultWeightedReferralVarianceValidator() -> WeightedReferralVarianceValidator {
        return WeightedReferralVarianceValidator(
            rules: [
                WeightedReferralVarianceAllowedCodeRule(allowed: ["regional", "manual", "legacy"]),
                WeightedReferralVarianceCodePrefixRule(prefix: "OPS"),
                WeightedReferralVarianceRequiredCodeRule(message: "weighted referral variance needs an entry"),
                WeightedReferralVarianceNameLengthRule(maxLength: 80),
                WeightedReferralVarianceCopayRangeRule(min: 0.4, max: 2135.6),
            ]
        )
    }
}
