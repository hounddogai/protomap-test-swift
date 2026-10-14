import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive isolation review must pass. Check returns its problems, or none.
    protocol AdaptiveIsolationReviewRule {
        func check(_ item: AdaptiveIsolationReview) -> [String]
    }

    final class AdaptiveIsolationReviewCodePrefixRule: AdaptiveIsolationReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveIsolationReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveIsolationReviewRequiredPatientRefRule: AdaptiveIsolationReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveIsolationReview) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveIsolationReviewBudgetRangeRule: AdaptiveIsolationReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveIsolationReview) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive isolation review.
    final class AdaptiveIsolationReviewValidator {
        var rules: [any AdaptiveIsolationReviewRule]

        init(rules: [any AdaptiveIsolationReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveIsolationReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveIsolationReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveIsolationReview]) -> [String: [String]] {
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

    static func defaultAdaptiveIsolationReviewValidator() -> AdaptiveIsolationReviewValidator {
        return AdaptiveIsolationReviewValidator(
            rules: [
                AdaptiveIsolationReviewCodePrefixRule(prefix: "X"),
                AdaptiveIsolationReviewRequiredPatientRefRule(message: "adaptive isolation review needs a value"),
                AdaptiveIsolationReviewBudgetRangeRule(min: 2.2, max: 4858.3),
            ]
        )
    }
}
