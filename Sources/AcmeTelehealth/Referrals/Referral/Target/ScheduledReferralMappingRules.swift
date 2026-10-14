import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled referral mapping must pass. Check returns its problems, or none.
    protocol ScheduledReferralMappingRule {
        func check(_ item: ScheduledReferralMapping) -> [String]
    }

    final class ScheduledReferralMappingRequiredCodeRule: ScheduledReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferralMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReferralMappingSummaryLengthRule: ScheduledReferralMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledReferralMapping) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledReferralMappingCodePrefixRule: ScheduledReferralMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledReferralMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledReferralMappingRequiredTitleRule: ScheduledReferralMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferralMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled referral mapping.
    final class ScheduledReferralMappingValidator {
        var rules: [any ScheduledReferralMappingRule]

        init(rules: [any ScheduledReferralMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledReferralMapping) -> [String] {
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

        func requireValid(_ item: ScheduledReferralMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledReferralMapping]) -> [String: [String]] {
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

    static func defaultScheduledReferralMappingValidator() -> ScheduledReferralMappingValidator {
        return ScheduledReferralMappingValidator(
            rules: [
                ScheduledReferralMappingRequiredCodeRule(message: "scheduled referral mapping needs an entry"),
                ScheduledReferralMappingSummaryLengthRule(maxLength: 86400),
                ScheduledReferralMappingCodePrefixRule(prefix: "Q"),
                ScheduledReferralMappingRequiredTitleRule(message: "scheduled referral mapping needs this field"),
            ]
        )
    }
}
