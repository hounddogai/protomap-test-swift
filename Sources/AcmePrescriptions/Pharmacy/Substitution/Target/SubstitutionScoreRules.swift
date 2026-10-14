import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution score must pass. Check returns its problems, or none.
    protocol SubstitutionScoreRule {
        func check(_ item: SubstitutionScore) -> [String]
    }

    final class SubstitutionScoreRequiredPatientRefRule: SubstitutionScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionScore) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionScoreAllowedCodeRule: SubstitutionScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class SubstitutionScoreEndsAtRangeRule: SubstitutionScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionScore) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionScoreRequiredCodeRule: SubstitutionScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionScoreAmountRangeRule: SubstitutionScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionScore) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution score.
    final class SubstitutionScoreValidator {
        var rules: [any SubstitutionScoreRule]

        init(rules: [any SubstitutionScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionScore) -> [String] {
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

        func requireValid(_ item: SubstitutionScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionScore]) -> [String: [String]] {
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

    static func defaultSubstitutionScoreValidator() -> SubstitutionScoreValidator {
        return SubstitutionScoreValidator(
            rules: [
                SubstitutionScoreRequiredPatientRefRule(message: "substitution score needs this field"),
                SubstitutionScoreAllowedCodeRule(allowed: ["regional", "primary", "fallback"]),
                SubstitutionScoreEndsAtRangeRule(min: 16, max: 80),
                SubstitutionScoreRequiredCodeRule(message: "substitution score needs a value"),
                SubstitutionScoreAmountRangeRule(min: 8.8, max: 4870.4),
            ]
        )
    }
}
