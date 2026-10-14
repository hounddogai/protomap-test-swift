import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual language claim must pass. Check returns its problems, or none.
    protocol ManualLanguageClaimRule {
        func check(_ item: ManualLanguageClaim) -> [String]
    }

    final class ManualLanguageClaimTimezoneLengthRule: ManualLanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualLanguageClaim) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualLanguageClaimRequiredCodeRule: ManualLanguageClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualLanguageClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualLanguageClaimRequiredChecksumRule: ManualLanguageClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualLanguageClaim) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual language claim.
    final class ManualLanguageClaimValidator {
        var rules: [any ManualLanguageClaimRule]

        init(rules: [any ManualLanguageClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualLanguageClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualLanguageClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualLanguageClaim]) -> [String: [String]] {
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

    static func defaultManualLanguageClaimValidator() -> ManualLanguageClaimValidator {
        return ManualLanguageClaimValidator(
            rules: [
                ManualLanguageClaimTimezoneLengthRule(maxLength: 3600),
                ManualLanguageClaimRequiredCodeRule(message: "manual language claim needs an entry"),
                ManualLanguageClaimRequiredChecksumRule(message: "manual language claim needs an entry"),
            ]
        )
    }
}
