import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional credential tier must pass. Check returns its problems, or none.
    protocol RegionalCredentialTierRule {
        func check(_ item: RegionalCredentialTier) -> [String]
    }

    final class RegionalCredentialTierRequiredCodeRule: RegionalCredentialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCredentialTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCredentialTierAllowedSourceRule: RegionalCredentialTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalCredentialTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is missing"]
            }
            return []
        }
    }

    final class RegionalCredentialTierLocaleLengthRule: RegionalCredentialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCredentialTier) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCredentialTierCodeLengthRule: RegionalCredentialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCredentialTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCredentialTierCodePrefixRule: RegionalCredentialTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalCredentialTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalCredentialTierRequiredChannelRule: RegionalCredentialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCredentialTier) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional credential tier.
    final class RegionalCredentialTierValidator {
        var rules: [any RegionalCredentialTierRule]

        init(rules: [any RegionalCredentialTierRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCredentialTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCredentialTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCredentialTier]) -> [String: [String]] {
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

    static func defaultRegionalCredentialTierValidator() -> RegionalCredentialTierValidator {
        return RegionalCredentialTierValidator(
            rules: [
                RegionalCredentialTierRequiredCodeRule(message: "regional credential tier needs this field"),
                RegionalCredentialTierAllowedSourceRule(allowed: ["weighted", "global", "lenient"]),
                RegionalCredentialTierLocaleLengthRule(maxLength: 120),
                RegionalCredentialTierCodeLengthRule(maxLength: 32),
                RegionalCredentialTierCodePrefixRule(prefix: "Q"),
                RegionalCredentialTierRequiredChannelRule(message: "regional credential tier needs this field"),
            ]
        )
    }
}
