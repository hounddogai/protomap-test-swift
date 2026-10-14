import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending goal review must pass. Check returns its problems, or none.
    protocol PendingGoalReviewRule {
        func check(_ item: PendingGoalReview) -> [String]
    }

    final class PendingGoalReviewLabelLengthRule: PendingGoalReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingGoalReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingGoalReviewRequiredCodeRule: PendingGoalReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingGoalReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingGoalReviewAllergyLengthRule: PendingGoalReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingGoalReview) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingGoalReviewRequiredLabelRule: PendingGoalReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingGoalReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingGoalReviewCodePrefixRule: PendingGoalReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingGoalReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending goal review.
    final class PendingGoalReviewValidator {
        var rules: [any PendingGoalReviewRule]

        init(rules: [any PendingGoalReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingGoalReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingGoalReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingGoalReview]) -> [String: [String]] {
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

    static func defaultPendingGoalReviewValidator() -> PendingGoalReviewValidator {
        return PendingGoalReviewValidator(
            rules: [
                PendingGoalReviewLabelLengthRule(maxLength: 120),
                PendingGoalReviewRequiredCodeRule(message: "pending goal review needs an entry"),
                PendingGoalReviewAllergyLengthRule(maxLength: 64),
                PendingGoalReviewRequiredLabelRule(message: "pending goal review needs a value"),
                PendingGoalReviewCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
