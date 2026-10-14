import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback worklist review must pass. Check returns its problems, or none.
    protocol FallbackWorklistReviewRule {
        func check(_ item: FallbackWorklistReview) -> [String]
    }

    final class FallbackWorklistReviewRequiredNameRule: FallbackWorklistReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistReviewCodeLengthRule: FallbackWorklistReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistReviewRequiredNotesRule: FallbackWorklistReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistReview) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackWorklistReviewPatientRefLengthRule: FallbackWorklistReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistReview) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistReviewNotesLengthRule: FallbackWorklistReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistReview) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistReviewRefillsRangeRule: FallbackWorklistReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackWorklistReview) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback worklist review.
    final class FallbackWorklistReviewValidator {
        var rules: [any FallbackWorklistReviewRule]

        init(rules: [any FallbackWorklistReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackWorklistReview) -> [String] {
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

        func requireValid(_ item: FallbackWorklistReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackWorklistReview]) -> [String: [String]] {
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

    static func defaultFallbackWorklistReviewValidator() -> FallbackWorklistReviewValidator {
        return FallbackWorklistReviewValidator(
            rules: [
                FallbackWorklistReviewRequiredNameRule(message: "fallback worklist review needs a value"),
                FallbackWorklistReviewCodeLengthRule(maxLength: 255),
                FallbackWorklistReviewRequiredNotesRule(message: "fallback worklist review needs a value"),
                FallbackWorklistReviewPatientRefLengthRule(maxLength: 120),
                FallbackWorklistReviewNotesLengthRule(maxLength: 32),
                FallbackWorklistReviewRefillsRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
