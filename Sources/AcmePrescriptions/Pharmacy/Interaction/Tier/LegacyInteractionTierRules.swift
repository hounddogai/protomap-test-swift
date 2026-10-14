import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy interaction tier must pass. Check returns its problems, or none.
    protocol LegacyInteractionTierRule {
        func check(_ item: LegacyInteractionTier) -> [String]
    }

    final class LegacyInteractionTierTimezoneLengthRule: LegacyInteractionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionTier) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInteractionTierRequiredPhoneRule: LegacyInteractionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionTier) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionTierRequiredCodeRule: LegacyInteractionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionTierNameLengthRule: LegacyInteractionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInteractionTierAllowedNameRule: LegacyInteractionTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyInteractionTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class LegacyInteractionTierCodeLengthRule: LegacyInteractionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy interaction tier.
    final class LegacyInteractionTierValidator {
        var rules: [any LegacyInteractionTierRule]

        init(rules: [any LegacyInteractionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInteractionTier) -> [String] {
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

        func requireValid(_ item: LegacyInteractionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInteractionTier]) -> [String: [String]] {
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

    static func defaultLegacyInteractionTierValidator() -> LegacyInteractionTierValidator {
        return LegacyInteractionTierValidator(
            rules: [
                LegacyInteractionTierTimezoneLengthRule(maxLength: 80),
                LegacyInteractionTierRequiredPhoneRule(message: "legacy interaction tier needs an entry"),
                LegacyInteractionTierRequiredCodeRule(message: "legacy interaction tier needs this field"),
                LegacyInteractionTierNameLengthRule(maxLength: 80),
                LegacyInteractionTierAllowedNameRule(allowed: []),
                LegacyInteractionTierCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
