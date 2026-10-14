import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral quota must pass. Check returns its problems, or none.
    protocol ReferralQuotaRule {
        func check(_ item: ReferralQuota) -> [String]
    }

    final class ReferralQuotaAllowedChecksumRule: ReferralQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is missing"]
            }
            return []
        }
    }

    final class ReferralQuotaCodeLengthRule: ReferralQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralQuotaWardLengthRule: ReferralQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralQuota) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralQuotaRequiredWardRule: ReferralQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralQuota) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral quota.
    final class ReferralQuotaValidator {
        var rules: [any ReferralQuotaRule]

        init(rules: [any ReferralQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralQuota) -> [String] {
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

        func requireValid(_ item: ReferralQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralQuota]) -> [String: [String]] {
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

    static func defaultReferralQuotaValidator() -> ReferralQuotaValidator {
        return ReferralQuotaValidator(
            rules: [
                ReferralQuotaAllowedChecksumRule(allowed: []),
                ReferralQuotaCodeLengthRule(maxLength: 80),
                ReferralQuotaWardLengthRule(maxLength: 80),
                ReferralQuotaRequiredWardRule(message: "referral quota needs this field"),
            ]
        )
    }
}
