import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution tier must pass. Check returns its problems, or none.
    protocol SubstitutionTierRule {
        func check(_ item: SubstitutionTier) -> [String]
    }

    final class SubstitutionTierTitleLengthRule: SubstitutionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionTierAllergyLengthRule: SubstitutionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionTier) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionTierRequiredLabelRule: SubstitutionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a substitution tier.
    final class SubstitutionTierValidator {
        var rules: [any SubstitutionTierRule]

        init(rules: [any SubstitutionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionTier]) -> [String: [String]] {
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

    static func defaultSubstitutionTierValidator() -> SubstitutionTierValidator {
        return SubstitutionTierValidator(
            rules: [
                SubstitutionTierTitleLengthRule(maxLength: 255),
                SubstitutionTierAllergyLengthRule(maxLength: 16),
                SubstitutionTierRequiredLabelRule(message: "substitution tier needs an entry"),
            ]
        )
    }
}
