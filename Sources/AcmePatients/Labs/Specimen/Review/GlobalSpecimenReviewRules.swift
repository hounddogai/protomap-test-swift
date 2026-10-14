import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global specimen review must pass. Check returns its problems, or none.
    protocol GlobalSpecimenReviewRule {
        func check(_ item: GlobalSpecimenReview) -> [String]
    }

    final class GlobalSpecimenReviewSummaryLengthRule: GlobalSpecimenReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSpecimenReview) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSpecimenReviewRequiredNotesRule: GlobalSpecimenReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenReview) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenReviewRequiredNameRule: GlobalSpecimenReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenReviewNameLengthRule: GlobalSpecimenReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSpecimenReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global specimen review.
    final class GlobalSpecimenReviewValidator {
        var rules: [any GlobalSpecimenReviewRule]

        init(rules: [any GlobalSpecimenReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSpecimenReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSpecimenReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSpecimenReview]) -> [String: [String]] {
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

    static func defaultGlobalSpecimenReviewValidator() -> GlobalSpecimenReviewValidator {
        return GlobalSpecimenReviewValidator(
            rules: [
                GlobalSpecimenReviewSummaryLengthRule(maxLength: 1000),
                GlobalSpecimenReviewRequiredNotesRule(message: "global specimen review needs a value"),
                GlobalSpecimenReviewRequiredNameRule(message: "global specimen review needs an entry"),
                GlobalSpecimenReviewNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
