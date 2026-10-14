import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered referral digest must pass. Check returns its problems, or none.
    protocol TieredReferralDigestRule {
        func check(_ item: TieredReferralDigest) -> [String]
    }

    final class TieredReferralDigestTitleLengthRule: TieredReferralDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralDigestRevisionRangeRule: TieredReferralDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReferralDigest) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredReferralDigestCodePrefixRule: TieredReferralDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredReferralDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredReferralDigestRequiredCodeRule: TieredReferralDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferralDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferralDigestClinicianIDLengthRule: TieredReferralDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralDigest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered referral digest.
    final class TieredReferralDigestValidator {
        var rules: [any TieredReferralDigestRule]

        init(rules: [any TieredReferralDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferralDigest) -> [String] {
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

        func requireValid(_ item: TieredReferralDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferralDigest]) -> [String: [String]] {
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

    static func defaultTieredReferralDigestValidator() -> TieredReferralDigestValidator {
        return TieredReferralDigestValidator(
            rules: [
                TieredReferralDigestTitleLengthRule(maxLength: 255),
                TieredReferralDigestRevisionRangeRule(min: 32, max: 3600),
                TieredReferralDigestCodePrefixRule(prefix: "Q"),
                TieredReferralDigestRequiredCodeRule(message: "tiered referral digest needs a value"),
                TieredReferralDigestClinicianIDLengthRule(maxLength: 120),
            ]
        )
    }
}
