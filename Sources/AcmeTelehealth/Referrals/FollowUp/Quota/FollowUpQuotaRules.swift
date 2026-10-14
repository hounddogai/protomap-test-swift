import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up quota must pass. Check returns its problems, or none.
    protocol FollowUpQuotaRule {
        func check(_ item: FollowUpQuota) -> [String]
    }

    final class FollowUpQuotaCodePrefixRule: FollowUpQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpQuotaCodeLengthRule: FollowUpQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpQuotaVersionRangeRule: FollowUpQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpQuota) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up quota.
    final class FollowUpQuotaValidator {
        var rules: [any FollowUpQuotaRule]

        init(rules: [any FollowUpQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpQuota]) -> [String: [String]] {
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

    static func defaultFollowUpQuotaValidator() -> FollowUpQuotaValidator {
        return FollowUpQuotaValidator(
            rules: [
                FollowUpQuotaCodePrefixRule(prefix: "OPS"),
                FollowUpQuotaCodeLengthRule(maxLength: 86400),
                FollowUpQuotaVersionRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
