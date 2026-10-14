import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation review must pass. Check returns its problems, or none.
    protocol RevocationReviewRule {
        func check(_ item: RevocationReview) -> [String]
    }

    final class RevocationReviewBudgetRangeRule: RevocationReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationReview) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationReviewRequiredDiagnosisCodeRule: RevocationReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationReview) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationReviewAllowedCodeRule: RevocationReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RevocationReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation review.
    final class RevocationReviewValidator {
        var rules: [any RevocationReviewRule]

        init(rules: [any RevocationReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationReview) -> [String] {
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

        func requireValid(_ item: RevocationReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationReview]) -> [String: [String]] {
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

    static func defaultRevocationReviewValidator() -> RevocationReviewValidator {
        return RevocationReviewValidator(
            rules: [
                RevocationReviewBudgetRangeRule(min: 6.3, max: 3407.0),
                RevocationReviewRequiredDiagnosisCodeRule(message: "revocation review needs this field"),
                RevocationReviewAllowedCodeRule(allowed: []),
            ]
        )
    }
}
