import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback language claim must pass. Check returns its problems, or none.
    protocol FallbackLanguageClaimRule {
        func check(_ item: FallbackLanguageClaim) -> [String]
    }

    final class FallbackLanguageClaimLabelLengthRule: FallbackLanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackLanguageClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackLanguageClaimAllowedCodeRule: FallbackLanguageClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackLanguageClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class FallbackLanguageClaimCodeLengthRule: FallbackLanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackLanguageClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback language claim.
    final class FallbackLanguageClaimValidator {
        var rules: [any FallbackLanguageClaimRule]

        init(rules: [any FallbackLanguageClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackLanguageClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackLanguageClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackLanguageClaim]) -> [String: [String]] {
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

    static func defaultFallbackLanguageClaimValidator() -> FallbackLanguageClaimValidator {
        return FallbackLanguageClaimValidator(
            rules: [
                FallbackLanguageClaimLabelLengthRule(maxLength: 120),
                FallbackLanguageClaimAllowedCodeRule(allowed: ["manual"]),
                FallbackLanguageClaimCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
