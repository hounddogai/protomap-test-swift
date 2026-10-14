import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral digest must pass. Check returns its problems, or none.
    protocol ReferralDigestRule {
        func check(_ item: ReferralDigest) -> [String]
    }

    final class ReferralDigestRateRangeRule: ReferralDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralDigest) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralDigestCodeLengthRule: ReferralDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralDigestDosageMgRangeRule: ReferralDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralDigest) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralDigestAllowedExternalRefRule: ReferralDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a referral digest.
    final class ReferralDigestValidator {
        var rules: [any ReferralDigestRule]

        init(rules: [any ReferralDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralDigest]) -> [String: [String]] {
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

    static func defaultReferralDigestValidator() -> ReferralDigestValidator {
        return ReferralDigestValidator(
            rules: [
                ReferralDigestRateRangeRule(min: 4.2, max: 2890.1),
                ReferralDigestCodeLengthRule(maxLength: 32),
                ReferralDigestDosageMgRangeRule(min: 8.9, max: 1583.5),
                ReferralDigestAllowedExternalRefRule(allowed: ["weighted", "regional"]),
            ]
        )
    }
}
