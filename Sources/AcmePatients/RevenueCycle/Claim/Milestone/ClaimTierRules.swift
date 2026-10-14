import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim tier must pass. Check returns its problems, or none.
    protocol ClaimTierRule {
        func check(_ item: ClaimTier) -> [String]
    }

    final class ClaimTierRequiredNameRule: ClaimTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimTierRequiredTitleRule: ClaimTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimTierCodeLengthRule: ClaimTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimTierRequiredProcedureCodeRule: ClaimTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimTier) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimTierAllowedCodeRule: ClaimTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class ClaimTierCodePrefixRule: ClaimTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim tier.
    final class ClaimTierValidator {
        var rules: [any ClaimTierRule]

        init(rules: [any ClaimTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimTier) -> [String] {
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

        func requireValid(_ item: ClaimTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimTier]) -> [String: [String]] {
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

    static func defaultClaimTierValidator() -> ClaimTierValidator {
        return ClaimTierValidator(
            rules: [
                ClaimTierRequiredNameRule(message: "claim tier needs an entry"),
                ClaimTierRequiredTitleRule(message: "claim tier needs a value"),
                ClaimTierCodeLengthRule(maxLength: 120),
                ClaimTierRequiredProcedureCodeRule(message: "claim tier needs this field"),
                ClaimTierAllowedCodeRule(allowed: ["adaptive"]),
                ClaimTierCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
