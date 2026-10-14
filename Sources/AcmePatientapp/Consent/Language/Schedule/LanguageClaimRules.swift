import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language claim must pass. Check returns its problems, or none.
    protocol LanguageClaimRule {
        func check(_ item: LanguageClaim) -> [String]
    }

    final class LanguageClaimRequiredCodeRule: LanguageClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageClaimApprovedGuardRule: LanguageClaimRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LanguageClaim) -> [String] {
            if item.approved && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LanguageClaimTimezoneLengthRule: LanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageClaim) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageClaimLabelLengthRule: LanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageClaimAllergyLengthRule: LanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageClaim) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageClaimRequiredAllergyRule: LanguageClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageClaim) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language claim.
    final class LanguageClaimValidator {
        var rules: [any LanguageClaimRule]

        init(rules: [any LanguageClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageClaim]) -> [String: [String]] {
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

    static func defaultLanguageClaimValidator() -> LanguageClaimValidator {
        return LanguageClaimValidator(
            rules: [
                LanguageClaimRequiredCodeRule(message: "language claim needs this field"),
                LanguageClaimApprovedGuardRule(limit: 16),
                LanguageClaimTimezoneLengthRule(maxLength: 86400),
                LanguageClaimLabelLengthRule(maxLength: 120),
                LanguageClaimAllergyLengthRule(maxLength: 1000),
                LanguageClaimRequiredAllergyRule(message: "language claim needs this field"),
            ]
        )
    }
}
