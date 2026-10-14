import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up tier must pass. Check returns its problems, or none.
    protocol FollowUpTierRule {
        func check(_ item: FollowUpTier) -> [String]
    }

    final class FollowUpTierCodeLengthRule: FollowUpTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpTierRequiredChecksumRule: FollowUpTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpTier) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpTierChecksumLengthRule: FollowUpTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpTier) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up tier.
    final class FollowUpTierValidator {
        var rules: [any FollowUpTierRule]

        init(rules: [any FollowUpTierRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpTier) -> [String] {
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

        func requireValid(_ item: FollowUpTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpTier]) -> [String: [String]] {
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

    static func defaultFollowUpTierValidator() -> FollowUpTierValidator {
        return FollowUpTierValidator(
            rules: [
                FollowUpTierCodeLengthRule(maxLength: 64),
                FollowUpTierRequiredChecksumRule(message: "follow up tier needs a value"),
                FollowUpTierChecksumLengthRule(maxLength: 3600),
            ]
        )
    }
}
