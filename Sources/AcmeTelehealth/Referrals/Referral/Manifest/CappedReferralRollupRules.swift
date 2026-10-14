import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped referral rollup must pass. Check returns its problems, or none.
    protocol CappedReferralRollupRule {
        func check(_ item: CappedReferralRollup) -> [String]
    }

    final class CappedReferralRollupCodePrefixRule: CappedReferralRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedReferralRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedReferralRollupRequiredCodeRule: CappedReferralRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferralRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReferralRollupCodeLengthRule: CappedReferralRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferralRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReferralRollupTagsLimitRule: CappedReferralRollupRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CappedReferralRollup) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class CappedReferralRollupDescriptionLengthRule: CappedReferralRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferralRollup) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReferralRollupRequiredDescriptionRule: CappedReferralRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferralRollup) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped referral rollup.
    final class CappedReferralRollupValidator {
        var rules: [any CappedReferralRollupRule]

        init(rules: [any CappedReferralRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReferralRollup) -> [String] {
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

        func requireValid(_ item: CappedReferralRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReferralRollup]) -> [String: [String]] {
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

    static func defaultCappedReferralRollupValidator() -> CappedReferralRollupValidator {
        return CappedReferralRollupValidator(
            rules: [
                CappedReferralRollupCodePrefixRule(prefix: "REF"),
                CappedReferralRollupRequiredCodeRule(message: "capped referral rollup needs an entry"),
                CappedReferralRollupCodeLengthRule(maxLength: 3600),
                CappedReferralRollupTagsLimitRule(maxCount: 1000, banned: ["regional", "weighted", "regional"]),
                CappedReferralRollupDescriptionLengthRule(maxLength: 120),
                CappedReferralRollupRequiredDescriptionRule(message: "capped referral rollup needs an entry"),
            ]
        )
    }
}
