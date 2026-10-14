import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary outreach review must pass. Check returns its problems, or none.
    protocol PrimaryOutreachReviewRule {
        func check(_ item: PrimaryOutreachReview) -> [String]
    }

    final class PrimaryOutreachReviewLabelLengthRule: PrimaryOutreachReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachReviewDescriptionLengthRule: PrimaryOutreachReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachReviewRequiredCodeRule: PrimaryOutreachReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachReviewRequiredLabelRule: PrimaryOutreachReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOutreachReviewUpdatedAtRangeRule: PrimaryOutreachReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOutreachReview) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryOutreachReviewTitleLengthRule: PrimaryOutreachReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary outreach review.
    final class PrimaryOutreachReviewValidator {
        var rules: [any PrimaryOutreachReviewRule]

        init(rules: [any PrimaryOutreachReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOutreachReview) -> [String] {
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

        func requireValid(_ item: PrimaryOutreachReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOutreachReview]) -> [String: [String]] {
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

    static func defaultPrimaryOutreachReviewValidator() -> PrimaryOutreachReviewValidator {
        return PrimaryOutreachReviewValidator(
            rules: [
                PrimaryOutreachReviewLabelLengthRule(maxLength: 86400),
                PrimaryOutreachReviewDescriptionLengthRule(maxLength: 32),
                PrimaryOutreachReviewRequiredCodeRule(message: "primary outreach review needs this field"),
                PrimaryOutreachReviewRequiredLabelRule(message: "primary outreach review needs this field"),
                PrimaryOutreachReviewUpdatedAtRangeRule(min: 16, max: 3600),
                PrimaryOutreachReviewTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
