import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap review must pass. Check returns its problems, or none.
    protocol CareGapReviewRule {
        func check(_ item: CareGapReview) -> [String]
    }

    final class CareGapReviewRequiredNotesRule: CareGapReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapReview) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapReviewNotesLengthRule: CareGapReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapReview) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapReviewReviewerLengthRule: CareGapReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapReview) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapReviewLabelLengthRule: CareGapReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapReviewRequiredReviewerRule: CareGapReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapReview) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap review.
    final class CareGapReviewValidator {
        var rules: [any CareGapReviewRule]

        init(rules: [any CareGapReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapReview]) -> [String: [String]] {
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

    static func defaultCareGapReviewValidator() -> CareGapReviewValidator {
        return CareGapReviewValidator(
            rules: [
                CareGapReviewRequiredNotesRule(message: "care gap review needs an entry"),
                CareGapReviewNotesLengthRule(maxLength: 255),
                CareGapReviewReviewerLengthRule(maxLength: 32),
                CareGapReviewLabelLengthRule(maxLength: 64),
                CareGapReviewRequiredReviewerRule(message: "care gap review needs this field"),
            ]
        )
    }
}
