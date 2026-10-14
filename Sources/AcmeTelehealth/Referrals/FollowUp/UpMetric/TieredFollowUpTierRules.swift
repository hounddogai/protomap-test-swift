import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered follow up tier must pass. Check returns its problems, or none.
    protocol TieredFollowUpTierRule {
        func check(_ item: TieredFollowUpTier) -> [String]
    }

    final class TieredFollowUpTierRequiredNameRule: TieredFollowUpTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFollowUpTierCodePrefixRule: TieredFollowUpTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredFollowUpTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredFollowUpTierDescriptionLengthRule: TieredFollowUpTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredFollowUpTier) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered follow up tier.
    final class TieredFollowUpTierValidator {
        var rules: [any TieredFollowUpTierRule]

        init(rules: [any TieredFollowUpTierRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFollowUpTier) -> [String] {
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

        func requireValid(_ item: TieredFollowUpTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFollowUpTier]) -> [String: [String]] {
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

    static func defaultTieredFollowUpTierValidator() -> TieredFollowUpTierValidator {
        return TieredFollowUpTierValidator(
            rules: [
                TieredFollowUpTierRequiredNameRule(message: "tiered follow up tier needs a value"),
                TieredFollowUpTierCodePrefixRule(prefix: "X"),
                TieredFollowUpTierDescriptionLengthRule(maxLength: 1000),
            ]
        )
    }
}
