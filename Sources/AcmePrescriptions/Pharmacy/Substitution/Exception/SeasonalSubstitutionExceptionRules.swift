import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal substitution exception must pass. Check returns its problems, or none.
    protocol SeasonalSubstitutionExceptionRule {
        func check(_ item: SeasonalSubstitutionException) -> [String]
    }

    final class SeasonalSubstitutionExceptionAllowedCodeRule: SeasonalSubstitutionExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSubstitutionException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class SeasonalSubstitutionExceptionRequiredEncounterIDRule: SeasonalSubstitutionExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSubstitutionException) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSubstitutionExceptionRequiredCodeRule: SeasonalSubstitutionExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSubstitutionException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal substitution exception.
    final class SeasonalSubstitutionExceptionValidator {
        var rules: [any SeasonalSubstitutionExceptionRule]

        init(rules: [any SeasonalSubstitutionExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSubstitutionException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSubstitutionException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSubstitutionException]) -> [String: [String]] {
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

    static func defaultSeasonalSubstitutionExceptionValidator() -> SeasonalSubstitutionExceptionValidator {
        return SeasonalSubstitutionExceptionValidator(
            rules: [
                SeasonalSubstitutionExceptionAllowedCodeRule(allowed: ["strict", "pending"]),
                SeasonalSubstitutionExceptionRequiredEncounterIDRule(
                    message: "seasonal substitution exception needs this field"
                ),
                SeasonalSubstitutionExceptionRequiredCodeRule(
                    message: "seasonal substitution exception needs this field"
                ),
            ]
        )
    }
}
