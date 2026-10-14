import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default referral agreement must pass. Check returns its problems, or none.
    protocol DefaultReferralAgreementRule {
        func check(_ item: DefaultReferralAgreement) -> [String]
    }

    final class DefaultReferralAgreementSummaryLengthRule: DefaultReferralAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferralAgreement) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReferralAgreementScoreRangeRule: DefaultReferralAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReferralAgreement) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultReferralAgreementCodePrefixRule: DefaultReferralAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultReferralAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultReferralAgreementCodeLengthRule: DefaultReferralAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferralAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReferralAgreementNameLengthRule: DefaultReferralAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferralAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultReferralAgreementTimezoneLengthRule: DefaultReferralAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReferralAgreement) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default referral agreement.
    final class DefaultReferralAgreementValidator {
        var rules: [any DefaultReferralAgreementRule]

        init(rules: [any DefaultReferralAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReferralAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultReferralAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReferralAgreement]) -> [String: [String]] {
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

    static func defaultDefaultReferralAgreementValidator() -> DefaultReferralAgreementValidator {
        return DefaultReferralAgreementValidator(
            rules: [
                DefaultReferralAgreementSummaryLengthRule(maxLength: 16),
                DefaultReferralAgreementScoreRangeRule(min: 2.9, max: 1381.4),
                DefaultReferralAgreementCodePrefixRule(prefix: "X"),
                DefaultReferralAgreementCodeLengthRule(maxLength: 16),
                DefaultReferralAgreementNameLengthRule(maxLength: 1000),
                DefaultReferralAgreementTimezoneLengthRule(maxLength: 86400),
            ]
        )
    }
}
