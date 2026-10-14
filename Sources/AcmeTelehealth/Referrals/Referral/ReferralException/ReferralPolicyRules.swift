import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral policy must pass. Check returns its problems, or none.
    protocol ReferralPolicyRule {
        func check(_ item: ReferralPolicy) -> [String]
    }

    final class ReferralPolicyBatchSizeRangeRule: ReferralPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralPolicy) -> [String] {
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

    final class ReferralPolicyPayerLengthRule: ReferralPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralPolicy) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralPolicyWeightRangeRule: ReferralPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralPolicy) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralPolicyRequiredPayerRule: ReferralPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralPolicy) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralPolicyCodePrefixRule: ReferralPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral policy.
    final class ReferralPolicyValidator {
        var rules: [any ReferralPolicyRule]

        init(rules: [any ReferralPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralPolicy]) -> [String: [String]] {
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

    static func defaultReferralPolicyValidator() -> ReferralPolicyValidator {
        return ReferralPolicyValidator(
            rules: [
                ReferralPolicyBatchSizeRangeRule(min: 32, max: 3600),
                ReferralPolicyPayerLengthRule(maxLength: 1000),
                ReferralPolicyWeightRangeRule(min: 6.1, max: 4432.9),
                ReferralPolicyRequiredPayerRule(message: "referral policy needs this field"),
                ReferralPolicyCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
