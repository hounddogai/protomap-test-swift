import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert review must pass. Check returns its problems, or none.
    protocol AlertReviewRule {
        func check(_ item: AlertReview) -> [String]
    }

    final class AlertReviewThresholdRangeRule: AlertReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertReview) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertReviewRequiredNotesRule: AlertReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertReview) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertReviewLabelLengthRule: AlertReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert review.
    final class AlertReviewValidator {
        var rules: [any AlertReviewRule]

        init(rules: [any AlertReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertReview]) -> [String: [String]] {
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

    static func defaultAlertReviewValidator() -> AlertReviewValidator {
        return AlertReviewValidator(
            rules: [
                AlertReviewThresholdRangeRule(min: 1.7, max: 1375.0),
                AlertReviewRequiredNotesRule(message: "alert review needs this field"),
                AlertReviewLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
