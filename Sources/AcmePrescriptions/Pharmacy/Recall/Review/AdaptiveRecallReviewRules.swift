import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive recall review must pass. Check returns its problems, or none.
    protocol AdaptiveRecallReviewRule {
        func check(_ item: AdaptiveRecallReview) -> [String]
    }

    final class AdaptiveRecallReviewRequiredProcedureCodeRule: AdaptiveRecallReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRecallReview) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRecallReviewRequiredCodeRule: AdaptiveRecallReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRecallReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRecallReviewLabelLengthRule: AdaptiveRecallReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRecallReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive recall review.
    final class AdaptiveRecallReviewValidator {
        var rules: [any AdaptiveRecallReviewRule]

        init(rules: [any AdaptiveRecallReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRecallReview) -> [String] {
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

        func requireValid(_ item: AdaptiveRecallReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRecallReview]) -> [String: [String]] {
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

    static func defaultAdaptiveRecallReviewValidator() -> AdaptiveRecallReviewValidator {
        return AdaptiveRecallReviewValidator(
            rules: [
                AdaptiveRecallReviewRequiredProcedureCodeRule(message: "adaptive recall review needs a value"),
                AdaptiveRecallReviewRequiredCodeRule(message: "adaptive recall review needs an entry"),
                AdaptiveRecallReviewLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
